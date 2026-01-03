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
/// Encodes a string into a UTF-16 byte array.
/// 
/// Assuming the string is valid.
pub fn encode(
  str : StringView,
  bom? : Bool = false,
  endianness? : Endian = Little,
) -> Bytes {
  if endianness is Little {
    if bom is true {
      let arr = FixedArray::make(str.length() * 2 + 2, b'\x00')
      arr[0] = 0xFF
      arr[1] = 0xFE
      arr.blit_from_string(2, str.data(), str.start_offset(), str.length())
      arr.unsafe_reinterpret_as_bytes()
    } else {
      let arr = FixedArray::make(str.length() * 2, b'\x00')
      arr.blit_from_string(0, str.data(), str.start_offset(), str.length())
      arr.unsafe_reinterpret_as_bytes()
    }
  } else if bom is true {
    let arr = FixedArray::make(str.length() * 2 + 2, b'\x00')
    arr[0] = 0xFE
    arr[1] = 0xFF
    for i in 0..<str.length() {
      let code_unit = str.code_unit_at(i)
      arr[2 + i * 2] = (code_unit >> 8).to_byte()
      arr[2 + i * 2 + 1] = (code_unit & 0xFF).to_byte()
    }
    arr.unsafe_reinterpret_as_bytes()
  } else {
    let arr = FixedArray::make(str.length() * 2, b'\x00')
    for i in 0..<str.length() {
      let code_unit = str.code_unit_at(i)
      arr[i * 2] = (code_unit >> 8).to_byte()
      arr[i * 2 + 1] = (code_unit & 0xFF).to_byte()
    }
    arr.unsafe_reinterpret_as_bytes()
  }
}
