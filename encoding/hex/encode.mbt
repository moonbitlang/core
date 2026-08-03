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
const HEX_DIGITS : Bytes = b"0123456789abcdef"

///|
/// Returns the length of a hexadecimal encoding of `n` source bytes.
///
/// Each byte is encoded as two lowercase hexadecimal characters.
pub fn encoded_len(n : Int) -> Int {
  n * 2
}

///|
/// Encodes bytes as a lowercase hexadecimal string.
///
/// The returned string has length `encoded_len(bytes.length())`.
pub fn encode(bytes : BytesView) -> String {
  let builder = StringBuilder(size_hint=encoded_len(bytes.length()))
  for byte in bytes {
    let n = byte.to_int()
    builder.write_char(HEX_DIGITS[(n >> 4) & 0x0F].to_char())
    builder.write_char(HEX_DIGITS[n & 0x0F].to_char())
  }
  builder.to_string()
}
