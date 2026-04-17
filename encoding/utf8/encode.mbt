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
/// Encodes a string into a UTF-8 byte array.
/// 
/// Panics if the string contains an invalid surrogate pair.
pub fn encode(str : StringView, bom? : Bool = false) -> Bytes {
  let length = str.length()
  let utf8_length = for i = 0, utf8_length = 0; i < length; {
    let code = str.unsafe_get(i)
    if code < 0x80 {
      continue i + 1, utf8_length + 1
    } else if code < 0x800 {
      continue i + 1, utf8_length + 2
    } else if code.is_leading_surrogate() &&
      i + 1 < length &&
      str.unsafe_get(i + 1).is_trailing_surrogate() {
      continue i + 2, utf8_length + 4
    } else if code.is_surrogate() {
      abort("invalid surrogate pair")
    } else {
      continue i + 1, utf8_length + 3
    }
  } nobreak {
    if bom {
      3 + utf8_length
    } else {
      utf8_length
    }
  }

  let arr = FixedArray::make(utf8_length, b'\x00')
  for i = 0, offset = (if bom {
          arr[0] = UTF8_BOM_0
          arr[1] = UTF8_BOM_1
          arr[2] = UTF8_BOM_2
          3
        } else {
          0
        }); i < length; {
    let code_unit = str.unsafe_get(i)
    let code = code_unit.to_int()
    if code < 0x80 {
      arr[offset] = code.to_byte()
      continue i + 1, offset + 1
    } else if code < 0x800 {
      arr[offset] = (0xC0 + (code >> 6)).to_byte()
      arr[offset + 1] = (0x80 + (code & 0x3F)).to_byte()
      continue i + 1, offset + 2
    } else if code_unit.is_leading_surrogate() && i + 1 < length {
      let trailing = str.unsafe_get(i + 1)
      if trailing.is_trailing_surrogate() {
        let code = ((code - 0xD800) << 10) +
          (trailing.to_int() - 0xDC00) +
          0x10000
        arr[offset] = (0xF0 + (code >> 18)).to_byte()
        arr[offset + 1] = (0x80 + ((code >> 12) & 0x3F)).to_byte()
        arr[offset + 2] = (0x80 + ((code >> 6) & 0x3F)).to_byte()
        arr[offset + 3] = (0x80 + (code & 0x3F)).to_byte()
        continue i + 2, offset + 4
      } else {
        abort("invalid surrogate pair")
      }
    } else if code_unit.is_surrogate() {
      abort("invalid surrogate pair")
    } else {
      arr[offset] = (0xE0 + (code >> 12)).to_byte()
      arr[offset + 1] = (0x80 + ((code >> 6) & 0x3F)).to_byte()
      arr[offset + 2] = (0x80 + (code & 0x3F)).to_byte()
      continue i + 1, offset + 3
    }
  }
  arr.unsafe_reinterpret_as_bytes()
}
