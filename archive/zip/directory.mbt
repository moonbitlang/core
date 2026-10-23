// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Resource bounds for metadata-only directory reads. These bound encoded
/// directory bytes and retained entry count, never declared payload sizes.
/// Defaults permit any directory byte size and at most 2^31 - 1 entries;
/// callers should select bounds appropriate to their metadata memory budget.
#valtype
struct DirectoryLimits {
  max_directory_bytes : UInt64
  max_entries : UInt64
}

///|
/// Construct directory bounds. A zero ceiling permits only an empty resource.
pub fn DirectoryLimits::DirectoryLimits(
  max_directory_bytes~ : UInt64 = 0xffff_ffff_ffff_ffffUL,
  max_entries~ : UInt64 = 0x7fff_ffffUL,
) -> DirectoryLimits {
  { max_directory_bytes, max_entries, }
}

///|
/// A directory listing in central-directory order, including duplicate names.
/// Owns metadata only. A successful listing does not validate local headers,
/// decompress payloads, or verify their CRC-32 values.
struct Directory {
  entries : Array[DirectoryEntry]
  comment : Bytes
  central_offset : UInt64
}

///|
/// Entries in central-directory order. This view cannot modify the listing.
pub fn Directory::entries(self : Directory) -> ArrayView[DirectoryEntry] {
  self.entries
}

///|
/// The archive comment, owned independently of supplied read buffers.
pub fn Directory::comment(self : Directory) -> BytesView {
  self.comment
}

///|
/// Metadata declared by a central-directory entry, without its payload.
/// Sizes remain 64-bit even when the payload cannot fit in a MoonBit Bytes.
/// Unknown compression methods and encrypted payloads can still be listed.
struct DirectoryEntry {
  name : String
  compressed_size : UInt64
  uncompressed_size : UInt64
  local_offset : UInt64
  method_id : Int32
  flags : Int32
  crc : UInt32
  creator_system : Int32
  external_attributes : UInt32
  dos_date : Int32
  dos_time : Int32
}

///|
/// The entry name, decoded using the same UTF-8 policy as `read`.
pub fn DirectoryEntry::name(self : DirectoryEntry) -> String {
  self.name
}

///|
/// The declared compressed payload size, excluding headers and descriptors.
pub fn DirectoryEntry::compressed_size(self : DirectoryEntry) -> UInt64 {
  self.compressed_size
}

///|
/// The declared uncompressed size; listing never allocates this many bytes.
pub fn DirectoryEntry::uncompressed_size(self : DirectoryEntry) -> UInt64 {
  self.uncompressed_size
}

///|
/// The ZIP compression method number, including methods this library cannot decode.
pub fn DirectoryEntry::method_id(self : DirectoryEntry) -> Int32 {
  self.method_id
}

///|
/// The declared CRC-32. Directory reading does not verify payload integrity.
pub fn DirectoryEntry::crc32(self : DirectoryEntry) -> UInt32 {
  self.crc
}

///|
/// Whether the name or DOS/Unix file attributes identify a directory.
pub fn DirectoryEntry::is_directory(self : DirectoryEntry) -> Bool {
  self.name.has_suffix("/") ||
  (self.external_attributes & 0x10U) != 0 ||
  (
    (self.creator_system == 3 || self.creator_system == 19) &&
    ((self.external_attributes >> 16) & 0xf000U) == 0x4000U
  )
}

///|
/// Whether the entry's general-purpose flag declares payload encryption.
/// This does not imply support for decrypting it or for encrypted directories.
pub fn DirectoryEntry::is_encrypted(self : DirectoryEntry) -> Bool {
  (self.flags & FLAG_ENCRYPTED) != 0
}

///|
/// The host-system identifier from the entry's version-made-by field.
pub fn DirectoryEntry::creator_system(self : DirectoryEntry) -> Int32 {
  self.creator_system
}

///|
/// Original external file attributes, interpreted according to `creator_system`.
pub fn DirectoryEntry::external_attributes(self : DirectoryEntry) -> UInt32 {
  self.external_attributes
}

///|
/// Original packed DOS modification date (year/month/day); no timezone is stored.
pub fn DirectoryEntry::dos_date(self : DirectoryEntry) -> Int32 {
  self.dos_date
}

///|
/// Original packed DOS modification time (hour/minute/two-second units).
pub fn DirectoryEntry::dos_time(self : DirectoryEntry) -> Int32 {
  self.dos_time
}

///|
/// One bounded request into the same immutable archive supplied to the reader.
/// The offset is absolute; the length describes a single in-memory buffer.
struct ReadRange {
  offset : UInt64
  length : Int32
}

///|
/// Absolute byte offset from the start of the archive.
pub fn ReadRange::offset(self : ReadRange) -> UInt64 {
  self.offset
}

///|
/// Exact byte count to supply on the next call, at most 65,557 bytes.
pub fn ReadRange::length(self : ReadRange) -> Int32 {
  self.length
}

///|
/// The next range to read, or a completed, independently owned metadata listing.
pub(all) enum DirectoryStep {
  NeedRead(ReadRange)
  Done(Directory)
}

///|
/// Shared wire parser output. Only the in-memory reader retains source records
/// and patch positions; the directory reader keeps the owned entry metadata.
priv struct ParsedDirectoryRecord {
  entry : DirectoryEntry
  name_len : Int32
  central_zip64_offset_position : Int32?
}

///|
fn parse_directory_record(
  reader : Cursor,
) -> ParsedDirectoryRecord raise ZipError {
  guard reader.read_u32_raw() == CENTRAL_HEADER_SIG else {
    raise ZipError(InvalidSignature, "zip: invalid central directory signature")
  }
  let version_made_by = reader.read_u16()
  ignore(reader.read_u16())
  let flags = reader.read_u16()
  let method_id = reader.read_u16()
  let dos_time = reader.read_u16()
  let dos_date = reader.read_u16()
  let crc = reader.read_u32_raw()
  let comp_size_raw = reader.read_u32_raw()
  let uncomp_size_raw = reader.read_u32_raw()
  let name_len = reader.read_u16()
  let extra_len = reader.read_u16()
  let comment_len = reader.read_u16()
  let disk = reader.read_u16()
  ignore(reader.read_u16())
  let external_attributes = reader.read_u32_raw()
  let local_offset_raw = reader.read_u32_raw()
  let name_bytes = reader.read_bytes(name_len)
  let extra_bytes = reader.read_bytes(extra_len)
  let name = decode_name(name_bytes)
  reader.skip(comment_len)
  guard disk == 0 || disk == 0xffff else {
    raise ZipError(
      UnsupportedFeature,
      "zip: multi-disk archives are not supported",
    )
  }
  let need_uncomp = uncomp_size_raw == MAX_U32
  let need_comp = comp_size_raw == MAX_U32
  let need_offset = local_offset_raw == MAX_U32
  let (zip_uncomp, zip_comp, zip_offset, offset_position) = read_zip64_extra(
    extra_bytes,
    need_uncomp,
    need_comp,
    need_offset,
    need_disk=disk == 0xffff,
  )
  {
    entry: {
      name,
      compressed_size: resolve_zip64_field(need_comp, zip_comp, comp_size_raw),
      uncompressed_size: resolve_zip64_field(
        need_uncomp, zip_uncomp, uncomp_size_raw,
      ),
      local_offset: resolve_zip64_field(
        need_offset, zip_offset, local_offset_raw,
      ),
      method_id,
      flags,
      crc,
      creator_system: version_made_by >> 8,
      external_attributes,
      dos_date,
      dos_time,
    },
    name_len,
    central_zip64_offset_position: offset_position.map(position => {
      46 + name_len + position
    }),
  }
}
