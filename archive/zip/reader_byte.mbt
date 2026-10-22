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
/// Byte-level primitives and shared ZIP format constants: the little-endian
/// cursor, fixed-width field readers, the end-of-central scan, and
/// cancellation-aware owned copies.

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
fn Cursor::read_u8(self : Cursor) -> Int32 raise ZipError {
  if self.pos < 0 || self.pos >= self.bytes.length() {
    raise ZipError(Truncated, "zip: truncated header")
  }
  let value = self.bytes[self.pos].to_int()
  self.pos = self.pos + 1
  value
}

///|
fn Cursor::read_u16(self : Cursor) -> Int32 raise ZipError {
  let b0 = self.read_u8()
  let b1 = self.read_u8()
  b0 | (b1 << 8)
}

///|
fn Cursor::read_u32_raw(self : Cursor) -> UInt32 raise ZipError {
  let b0 = self.read_u8()
  let b1 = self.read_u8()
  let b2 = self.read_u8()
  let b3 = self.read_u8()
  b0.reinterpret_as_uint() |
  (b1.reinterpret_as_uint() << 8) |
  (b2.reinterpret_as_uint() << 16) |
  (b3.reinterpret_as_uint() << 24)
}

///|
fn Cursor::read_u64_raw(self : Cursor) -> UInt64 raise ZipError {
  let lo = self.read_u32_raw()
  let hi = self.read_u32_raw()
  (UInt64::extend_uint(hi) << 32) | UInt64::extend_uint(lo)
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
fn read_u16_le_at(bytes : BytesView, offset : Int32) -> Int32 raise ZipError {
  if offset < 0 || 2 > bytes.length() - offset {
    raise ZipError(Truncated, "zip: truncated field")
  }
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  b0 | (b1 << 8)
}

///|
fn read_u32_le_at_raw(
  bytes : BytesView,
  offset : Int32,
) -> UInt32 raise ZipError {
  if offset < 0 || 4 > bytes.length() - offset {
    raise ZipError(Truncated, "zip: truncated field")
  }
  bytes[offset].to_uint() |
  (bytes[offset + 1].to_uint() << 8) |
  (bytes[offset + 2].to_uint() << 16) |
  (bytes[offset + 3].to_uint() << 24)
}

///|
fn read_u64_le_at(bytes : BytesView, offset : Int32) -> UInt64 raise ZipError {
  if offset < 0 || 8 > bytes.length() - offset {
    raise ZipError(Truncated, "zip: truncated field")
  }
  let mut result : UInt64 = 0
  for i in 0..<8 {
    let b = bytes[offset + i].to_uint()
    result = result | (UInt64::extend_uint(b) << (i * 8))
  }
  result
}

///|
/// Locate the end-of-central-directory record by scanning the conventional
/// last (65535 + 22) bytes for the signature whose comment length reaches the
/// end of the input. Returns its offset, or `None`.
fn find_end_of_central(bytes : BytesView) -> Int32? raise ZipError {
  let len = bytes.length()
  if len < 22 {
    return None
  }
  let max_scan = 22 + 0xFFFF
  let min_offset = (len - max_scan).max(0)
  for i in (len - 22)>=..min_offset {
    if read_u32_le_at_raw(bytes, i) == END_OF_CENTRAL_SIG &&
      read_u16_le_at(bytes, i + 20) == len - i - 22 {
      return Some(i)
    }
  } nobreak {
    None
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
