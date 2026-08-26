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
/// Encodes bytes as a lowercase hexadecimal string.
///
/// The returned string has length `2 * bytes.length()`.
#cfg(not(any(target="native", target="wasm")))
pub fn encode(bytes : BytesView) -> String {
  encode_scalar(bytes)
}

///|
/// Encodes bytes as a lowercase hexadecimal string.
///
/// The returned string has length `2 * bytes.length()`.
#cfg(any(target="native", target="wasm"))
pub fn encode(bytes : BytesView) -> String {
  encode_v128(bytes)
}

///|
/// Retained on every backend: the linear-memory backends reach it only from
/// the differential tests, but it is the implementation everywhere else.
fn encode_scalar(bytes : BytesView) -> String {
  // size_hint is measured in bytes, and each of the 2n output code units
  // occupies two bytes in the builder's UTF-16 buffer
  let builder = StringBuilder(size_hint=4 * bytes.length())
  for byte in bytes {
    let n = byte.to_int()
    builder.write_char(HEX_DIGITS[(n >> 4) & 0x0F].to_char())
    builder.write_char(HEX_DIGITS[n & 0x0F].to_char())
  }
  builder.to_string()
}
