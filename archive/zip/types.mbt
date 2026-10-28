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
/// The ZIP compression methods this package can read and write.
pub(all) enum Compression {
  Store
  Deflate
} derive(Eq, @debug.Debug)

///|
fn Compression::code(compression : Compression) -> Int32 {
  match compression {
    Store => 0
    Deflate => 8
  }
}

///|
/// Resource bounds applied to a bounded read. Every field is a ceiling in
/// bytes (or, for `max_entries`, a count); `ReadLimits()` imposes no
/// limits beyond the in-memory Int32 capacity. `max_package_bytes` also bounds
/// the complete source retained for byte-preserving rewrites.
#valtype
pub struct ReadLimits {
  max_package_bytes : Int32
  max_entries : Int32
  max_entry_uncompressed_bytes : Int32
  max_total_uncompressed_bytes : Int32
}

///|
/// Construct resource bounds. Omitted ceilings default to the largest `Int`.
/// Each supplied ceiling must be non-negative; `read_all` raises `InvalidArgument`
/// for a negative one and rejects an exceeded ceiling before accepting the
/// corresponding resource.
pub fn ReadLimits::ReadLimits(
  max_package_bytes~ : Int32 = 0x7fff_ffff,
  max_entries~ : Int32 = 0x7fff_ffff,
  max_entry_uncompressed_bytes~ : Int32 = 0x7fff_ffff,
  max_total_uncompressed_bytes~ : Int32 = 0x7fff_ffff,
) -> ReadLimits {
  {
    max_package_bytes,
    max_entries,
    max_entry_uncompressed_bytes,
    max_total_uncompressed_bytes,
  }
}

///|
/// Views of source records used to reuse an unchanged entry's encoded payload
/// and metadata. Central-directory offsets may be patched when writing.
priv struct SourceRecord {
  local_record : BytesView
  central_record : BytesView
  central_zip64_offset_position : Int32?
}

///|
/// A single archive entry: its decoded payload plus the metadata the central
/// directory carried for it. Entries produced by `read_all` retain their source
/// records for byte-preserving rewrites; entries built with `Archive::add` do not.
struct Entry {
  name : String
  data : Bytes
  compression : Compression
  crc32 : UInt32
  dos_date : Int32
  dos_time : Int32
  creator_system : Int32
  external_attributes : UInt32
  data_descriptor : Bool
  compressed_size : Int32
  source : SourceRecord?
  origin_local_offset : Int32?
}

///|
/// The entry name decoded as UTF-8.
pub fn Entry::name(self : Entry) -> String {
  self.name
}

///|
/// A read-only view of the decompressed payload.
pub fn Entry::data(self : Entry) -> BytesView {
  self.data
}

///|
/// The compression method used for this entry.
pub fn Entry::compression(self : Entry) -> Compression {
  self.compression
}

///|
/// The entry's stored CRC-32: the central-directory value for entries read from
/// an archive, or computed at `add` time for entries created in memory.
pub fn Entry::crc32(self : Entry) -> UInt32 {
  self.crc32
}

///|
/// Packed DOS modification date; zero for newly added entries.
pub fn Entry::dos_date(self : Entry) -> Int32 {
  self.dos_date
}

///|
/// Packed DOS modification time; zero for newly added entries.
pub fn Entry::dos_time(self : Entry) -> Int32 {
  self.dos_time
}

///|
/// ZIP host-system identifier; zero (DOS) for newly added entries.
pub fn Entry::creator_system(self : Entry) -> Int32 {
  self.creator_system
}

///|
/// File attributes interpreted by `creator_system`; zero for newly added entries.
pub fn Entry::external_attributes(self : Entry) -> UInt32 {
  self.external_attributes
}

///|
/// Raw end-of-archive records captured from a read so a byte-preserving write
/// can re-emit the trailer (with patched counts/sizes/offsets) instead of
/// regenerating it.
priv struct TrailerTemplate {
  classic_end_record : BytesView
  zip64_end_record : BytesView?
  zip64_locator : BytesView?
}

///|
/// An in-memory ZIP archive: an ordered list of entries plus an archive
/// comment. Reading a ZIP materializes this; writing serializes it back.
struct Archive {
  entries : Array[Entry]
  mut comment : Bytes
  mut trailer : TrailerTemplate?
  mut original : Bytes?
}

///|
/// Create an empty archive.
pub fn Archive::Archive() -> Archive {
  { entries: [], comment: b"", trailer: None, original: None, }
}

///|
/// Append a new entry, retaining its payload as `Bytes`. The default method is
/// `Deflate`; pass `Store` to keep the payload verbatim. Serialization chooses
/// the local-header and descriptor layout; use `Writer` for chunked input.
pub fn Archive::add(
  self : Archive,
  name : String,
  data : BytesView,
  compression~ : Compression = Deflate,
) -> Unit {
  let data = data.to_owned()
  self.original = None
  self.entries.push({
    name,
    data,
    compression,
    data_descriptor: false,
    crc32: @checksum.crc32(data),
    dos_date: 0,
    dos_time: 0,
    creator_system: 0,
    external_attributes: 0,
    compressed_size: data.length(),
    source: None,
    origin_local_offset: None,
  })
}

///|
/// Replace the first entry named `name`, retaining its method, position, DOS
/// date/time, creator system and external attributes. CRC is recomputed and raw
/// records are discarded for re-encoding. Returns false if the name is absent.
pub fn Archive::replace(
  self : Archive,
  name : StringView,
  data : BytesView,
) -> Bool {
  guard self.entries.search_by(entry => entry.name()[:] == name) is Some(index) else {
    return false
  }
  self.original = None
  let entry = self.entries[index]
  let data = data.to_owned()
  self.entries[index] = {
    ..entry,
    data,
    crc32: @checksum.crc32(data),
    compressed_size: data.length(),
    source: None,
  }
  true
}

///|
/// Remove the entry named `name`. Returns `false` when no such entry exists.
pub fn Archive::remove(self : Archive, name : StringView) -> Bool {
  guard self.entries.search_by(entry => entry.name()[:] == name) is Some(index) else {
    return false
  }
  self.original = None
  ignore(self.entries.remove(index))
  true
}

///|
/// A read-only view of an entry payload, or `None` when absent.
pub fn Archive::get(self : Archive, name : StringView) -> BytesView? {
  guard self.entries.search_by(entry => entry.name()[:] == name) is Some(index) else {
    return None
  }
  Some(self.entries[index].data())
}

///|
/// The archive's entry list in order.
pub fn Archive::entries(self : Archive) -> ArrayView[Entry] {
  self.entries
}

///|
/// The archive-level comment bytes (empty when none).
pub fn Archive::comment(self : Archive) -> BytesView {
  self.comment
}

///|
/// Replace the archive-level comment. Long comments (over 65535 bytes) are
/// rejected at write time. Changing the comment invalidates a retained
/// end-record template, so a later byte-preserving write regenerates the
/// trailer with the new comment.
pub fn Archive::set_comment(self : Archive, comment : BytesView) -> Unit {
  self.original = None
  self.comment = comment.to_owned()
  self.trailer = None
}

///|
/// Returns an independently mutable snapshot of this archive. The clone shares
/// entry payloads and source storage but owns a
/// fresh entries array, so `add`/`replace`/`remove` on either side never
/// affects the other.
pub fn Archive::clone(self : Archive) -> Archive {
  {
    entries: self.entries.copy(),
    comment: self.comment,
    trailer: self.trailer,
    original: self.original,
  }
}
