// Copyright 2025 International Digital Economy Academy
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
pub fn encode(str : StringView, bom? : Bool = false) -> Bytes {
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
}
