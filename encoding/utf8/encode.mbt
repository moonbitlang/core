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
const U_BOM : Char = '\u{FEFF}'

///|
/// Encodes a string into a UTF-8 byte array.
/// 
/// Panics if the string contains any invalid char (out of 0..=10FFFF)
pub fn encode(str : @string.View, bom? : Bool = false) -> Bytes {
  let buffer = @buffer.new(size_hint=str.length() * 4)
  if bom is true {
    buffer.write_char_utf8(U_BOM)
  }
  buffer.write_string_utf8(str)
  buffer.to_bytes()
}
