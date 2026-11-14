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
const LOCAL_HEADER_SIG : UInt32 = 0x04034b50

///|
const CENTRAL_HEADER_SIG : UInt32 = 0x02014b50

///|
const DIRECTORY_SIGNATURE_SIG : UInt32 = 0x05054b50

///|
const END_OF_CENTRAL_SIG : UInt32 = 0x06054b50

///|
const DATA_DESCRIPTOR_SIG : UInt32 = 0x08074b50

///|
const ZIP64_EOCD_SIG : UInt32 = 0x06064b50

///|
const ZIP64_LOCATOR_SIG : UInt32 = 0x07064b50

///|
const FLAG_DATA_DESCRIPTOR : Int32 = 0x0008

///|
const FLAG_UTF8 : Int32 = 0x0800

///|
const FLAG_ENCRYPTED : Int32 = 0x0001

///|
const FLAG_DEFLATE_STRENGTH : Int32 = 0x0006

///|
const ZIP64_EXTRA_ID : Int32 = 0x0001

///|
const MAX_U32 : UInt32 = 0xFFFFFFFF

///|
/// Byte-level primitives and shared ZIP format constants: the field cursor
/// for variable-length data, the end-of-central scan, and cancellation-aware
/// owned copies. Fixed-layout records are matched with byte patterns.

///|
priv struct Cursor {
  bytes : BytesView
  mut pos : Int32
}

///|
/// Own a bounded response independently of a caller's reusable read buffer.
/// BytesView::to_owned may share a complete backing buffer, so copy explicitly.
fn copy_zip_input(input : BytesView) -> Bytes {
  let copy = FixedArray::make(input.length(), b'\x00')
  copy.blit_from_bytesview(0, input)
  owned_zip_buffer_to_bytes(copy)
}

///|
fn Cursor::Cursor(bytes : BytesView, pos : Int32) -> Cursor {
  { bytes, pos, }
}

///|
fn Cursor::read_bytes(self : Cursor, len : Int32) -> BytesView raise ZipError {
  if len < 0 || self.pos < 0 || len > self.bytes.length() - self.pos {
    raise ZipError(Truncated, "zip: truncated field")
  }
  let start = self.pos
  self.pos = self.pos + len
  self.bytes[start:self.pos]
}

///|
fn Cursor::skip(self : Cursor, len : Int32) -> Unit raise ZipError {
  ignore(self.read_bytes(len))
}

///|
/// A classic end-of-central-directory record, at `offset` in the scanned input.
priv struct EndRecord {
  offset : Int32
  disk : UInt32
  central_disk : UInt32
  disk_entries : Int32
  entries : Int32
  central_size : UInt32
  central_offset : UInt32
  comment : BytesView
}

///|
/// Locate the end-of-central-directory record by scanning the conventional
/// last (65535 + 22) bytes for the signature whose comment length reaches the
/// end of the input. Returns the parsed record, or `None`.
fn find_end_of_central(bytes : BytesView) -> EndRecord? {
  let len = bytes.length()
  let min_offset = (len - (22 + 0xFFFF)).max(0)
  for i in (len - 22)>=..min_offset {
    if bytes[i:] is [u32le(END_OF_CENTRAL_SIG), ..] &&
      end_record_at(bytes, i) is Some(record) {
      return Some(record)
    }
  } nobreak {
    None
  }
}

///|
/// The end record at `offset`, if its comment reaches the end of `bytes`.
fn end_record_at(bytes : BytesView, offset : Int32) -> EndRecord? {
  guard bytes[offset:]
    is [
      u32le(END_OF_CENTRAL_SIG),
      u16le(disk),
      u16le(central_disk),
      u16le(disk_entries),
      u16le(entries),
      u32le(central_size),
      u32le(central_offset),
      u16le(comment_len),
      .. comment,
    ] &&
    comment.length() == comment_len.reinterpret_as_int() else {
    return None
  }
  Some({
    offset,
    disk,
    central_disk,
    disk_entries: disk_entries.reinterpret_as_int(),
    entries: entries.reinterpret_as_int(),
    central_size,
    central_offset,
    comment,
  })
}

///|
/// Whether ZIP64 records stand in for this record's directory fields, given
/// the record's absolute offset in the archive.
///
/// ZIP64 records lie between the directory and this record, so a directory
/// that ends right here has none, and 0xFFFF in its counts is an ordinary
/// count: a classic archive may hold exactly 65535 entries. ZIP64 records may
/// also be present when every classic field fits.
fn EndRecord::has_zip64(self : EndRecord, absolute_offset : UInt64) -> Bool {
  self.central_size == MAX_U32 ||
  self.central_offset == MAX_U32 ||
  self.central_offset.to_uint64() + self.central_size.to_uint64() !=
  absolute_offset
}

///|
/// The error for a fixed-size record whose layout did not match: a record
/// that starts with some other signature is `InvalidSignature`, anything else
/// is too short to hold the record.
fn record_error(
  record : BytesView,
  signature : UInt32,
  message : String,
) -> ZipError {
  if record is [u32le(found), ..] && found != signature {
    ZipError(InvalidSignature, message)
  } else {
    ZipError(Truncated, "zip: truncated header")
  }
}

///|
fn decode_name(bytes : BytesView) -> String raise ZipError {
  @encoding/utf8.decode(bytes) catch {
    _ => raise ZipError(InvalidUtf8, "zip: entry name is not UTF-8")
  }
}

///|
fn ensure_flags_supported(flags : Int32) -> Unit raise ZipError {
  if (flags & FLAG_ENCRYPTED) != 0 {
    raise ZipError(
      UnsupportedFeature,
      "zip: encrypted entries are not supported",
    )
  }
  let supported = FLAG_DATA_DESCRIPTOR | FLAG_UTF8 | FLAG_DEFLATE_STRENGTH
  let unsupported = flags & supported.lnot()
  if unsupported != 0 {
    raise ZipError(
      UnsupportedFeature,
      "zip: unsupported entry flags: 0x\{unsupported.to_string(radix=16)}",
    )
  }
}

///|
fn method_from_code(method_id : Int32) -> Compression raise ZipError {
  match method_id {
    0 => Store
    8 => Deflate
    _ =>
      raise ZipError(
        UnsupportedCompression(method_id),
        "zip: unsupported compression method \{method_id}",
      )
  }
}

///|
/// Copies `bytes` into owned storage, polling `cancelled` every 64 KiB so a
/// large source record cannot hide behind a monolithic runtime copy.
fn copy_cancellable(
  bytes : BytesView,
  cancelled : () -> Bool,
) -> Bytes raise ZipError {
  check_cancelled(cancelled)
  let output : FixedArray[Byte] = FixedArray::make(bytes.length(), b'\x00')
  for offset = 0
      offset < bytes.length()
      offset = offset + (bytes.length() - offset).min(0x10000) {
    check_cancelled(cancelled)
    let end = offset + (bytes.length() - offset).min(0x10000)
    output.blit_from_bytesview(offset, bytes[offset:end])
  }
  check_cancelled(cancelled)
  owned_zip_buffer_to_bytes(output)
}
