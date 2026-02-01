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
const BASE64_STD : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

///|
/// Encodes a byte array into a Base64 string (RFC 4648).
///
/// When `padding` is true, the output is padded with `=` to a multiple of 4.
pub fn encode(bytes : BytesView, padding? : Bool = true) -> String {
  let full_groups = bytes.length() / 3
  let remainder = bytes.length() % 3
  let mut size_hint = full_groups * 4
  if remainder != 0 {
    size_hint += if padding is true { 4 } else { remainder + 1 }
  }
  let builder = StringBuilder::new(size_hint~)
  loop bytes {
    [b0, b1, b2, .. rest] => {
      let n = (b0.to_int() << 16) | (b1.to_int() << 8) | b2.to_int()
      builder
      ..write_char(BASE64_STD[(n >> 18) & 0x3F].to_char())
      ..write_char(BASE64_STD[(n >> 12) & 0x3F].to_char())
      ..write_char(BASE64_STD[(n >> 6) & 0x3F].to_char())
      ..write_char(BASE64_STD[n & 0x3F].to_char())
      continue rest
    }
    [b0, b1] => {
      let n = (b0.to_int() << 16) | (b1.to_int() << 8)
      builder
      ..write_char(BASE64_STD[(n >> 18) & 0x3F].to_char())
      ..write_char(BASE64_STD[(n >> 12) & 0x3F].to_char())
      ..write_char(BASE64_STD[(n >> 6) & 0x3F].to_char())
      if padding is true {
        builder.write_char('=')
      }
    }
    [b0] => {
      let n = b0.to_int() << 16
      builder
      ..write_char(BASE64_STD[(n >> 18) & 0x3F].to_char())
      ..write_char(BASE64_STD[(n >> 12) & 0x3F].to_char())
      if padding is true {
        builder.write_string("==")
      }
    }
    [] => ()
  }
  builder.to_string()
}
