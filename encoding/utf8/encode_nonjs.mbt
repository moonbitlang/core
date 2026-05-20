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
const UTF8_BOM_0 : Byte = b'\xEF'

///|
const UTF8_BOM_1 : Byte = b'\xBB'

///|
const UTF8_BOM_2 : Byte = b'\xBF'

///|
#borrow(src)
#intrinsic("%utf8.len_from_utf16")
fn utf8_len_from_utf16(src : String, src_offset : Int, src_length : Int) -> Int {
  let end = src_offset + src_length
  for index = src_offset, len = 0; index < end; {
    let code = src.unsafe_get(index)
    let code_int = code.to_int()
    if code_int < 0x80 {
      continue index + 1, len + 1
    } else if code_int < 0x800 {
      continue index + 1, len + 2
    } else if code.is_leading_surrogate() || code.is_trailing_surrogate() {
      continue index + 1, len + 2
    } else {
      continue index + 1, len + 3
    }
  } nobreak {
    len
  }
}

///|
#borrow(src, dst)
#intrinsic("%utf8.encode_from_utf16")
fn utf8_encode_from_utf16(
  src : String,
  src_offset : Int,
  src_length : Int,
  dst : FixedArray[Byte],
  dst_offset : Int,
) -> Int {
  let end = src_offset + src_length
  for index = src_offset, written = 0; index < end; {
    let unit = src.unsafe_get(index)
    let code = unit.to_int()
    if code < 0x80 {
      dst.unsafe_set(dst_offset + written, code.to_byte())
      continue index + 1, written + 1
    }
    if code < 0x800 {
      dst.unsafe_set(dst_offset + written, (0xC0 | (code >> 6)).to_byte())
      dst.unsafe_set(dst_offset + written + 1, (0x80 | (code & 0x3F)).to_byte())
      continue index + 1, written + 2
    }
    if unit.is_leading_surrogate() {
      if index + 1 < end {
        let trail = src.unsafe_get(index + 1)
        if trail.is_trailing_surrogate() {
          let scalar = ((code - 0xD800) << 10) +
            (trail.to_int() - 0xDC00) +
            0x10000
          dst.unsafe_set(
            dst_offset + written,
            (0xF0 | (scalar >> 18)).to_byte(),
          )
          dst.unsafe_set(
            dst_offset + written + 1,
            (0x80 | ((scalar >> 12) & 0x3F)).to_byte(),
          )
          dst.unsafe_set(
            dst_offset + written + 2,
            (0x80 | ((scalar >> 6) & 0x3F)).to_byte(),
          )
          dst.unsafe_set(
            dst_offset + written + 3,
            (0x80 | (scalar & 0x3F)).to_byte(),
          )
          continue index + 2, written + 4
        }
      }
      break -(index - src_offset + 1)
    }
    if unit.is_trailing_surrogate() {
      break -(index - src_offset + 1)
    }
    dst.unsafe_set(dst_offset + written, (0xE0 | (code >> 12)).to_byte())
    dst.unsafe_set(
      dst_offset + written + 1,
      (0x80 | ((code >> 6) & 0x3F)).to_byte(),
    )
    dst.unsafe_set(dst_offset + written + 2, (0x80 | (code & 0x3F)).to_byte())
    continue index + 1, written + 3
  } nobreak {
    written
  }
}

///|
/// Encodes a string into a UTF-8 byte array.
///
/// Panics if the string contains an invalid surrogate pair.
pub fn encode(str : StringView, bom? : Bool = false) -> Bytes {
  let src = str.data()
  let src_offset = str.start_offset()
  let src_length = str.length()
  let utf8_length = utf8_len_from_utf16(src, src_offset, src_length)
  let bom_length = if bom { 3 } else { 0 }
  let arr = FixedArray::make(utf8_length + bom_length, b'\x00')
  if bom {
    arr[0] = UTF8_BOM_0
    arr[1] = UTF8_BOM_1
    arr[2] = UTF8_BOM_2
  }
  match utf8_encode_from_utf16(src, src_offset, src_length, arr, bom_length) {
    written if written >= 0 => arr.unsafe_reinterpret_as_bytes()
    _ => abort("invalid surrogate pair")
  }
}
