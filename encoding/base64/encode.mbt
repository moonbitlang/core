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
/// The URL- and filename-safe alphabet of RFC 4648 §5.
const BASE64_URL : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

///|
/// Encodes a byte array into a Base64 string (RFC 4648).
///
/// When `padding` is true, the output is padded with `=` to a multiple of 4.
/// When `url_safe` is true, the URL- and filename-safe alphabet (RFC 4648 §5)
/// is used, writing `-` and `_` in place of `+` and `/`.
#cfg(not(any(target="native", target="wasm")))
pub fn encode(
  bytes : BytesView,
  padding~ : Bool = true,
  url_safe~ : Bool = false,
) -> String {
  encode_scalar(bytes, padding~, url_safe~)
}

///|
/// Encodes a byte array into a Base64 string (RFC 4648).
///
/// When `padding` is true, the output is padded with `=` to a multiple of 4.
/// When `url_safe` is true, the URL- and filename-safe alphabet (RFC 4648 §5)
/// is used, writing `-` and `_` in place of `+` and `/`.
#cfg(any(target="native", target="wasm"))
pub fn encode(
  bytes : BytesView,
  padding~ : Bool = true,
  url_safe~ : Bool = false,
) -> String {
  encode_v128(bytes, padding, url_safe)
}

///|
/// Retained on every backend: the linear-memory backends reach it only from
/// the differential tests, but it is the implementation everywhere else.
fn encode_scalar(
  bytes : BytesView,
  padding~ : Bool = true,
  url_safe~ : Bool = false,
) -> String {
  let alphabet = if url_safe { BASE64_URL } else { BASE64_STD }
  let full_groups = bytes.length() / 3
  let remainder = bytes.length() % 3
  let mut capacity = full_groups * 4
  if remainder != 0 {
    capacity += if padding is true { 4 } else { remainder + 1 }
  }
  let builder = StringBuilder(capacity~)
  for remaining = bytes {
    match remaining {
      [b0, b1, b2, .. rest] => {
        let n = (b0.to_int() << 16) | (b1.to_int() << 8) | b2.to_int()
        builder.write_char(alphabet[(n >> 18) & 0x3F].to_char())
        builder.write_char(alphabet[(n >> 12) & 0x3F].to_char())
        builder.write_char(alphabet[(n >> 6) & 0x3F].to_char())
        builder.write_char(alphabet[n & 0x3F].to_char())
        continue rest
      }
      [b0, b1] => {
        let n = (b0.to_int() << 16) | (b1.to_int() << 8)
        builder.write_char(alphabet[(n >> 18) & 0x3F].to_char())
        builder.write_char(alphabet[(n >> 12) & 0x3F].to_char())
        builder.write_char(alphabet[(n >> 6) & 0x3F].to_char())
        if padding is true {
          builder.write_char('=')
        }
        break
      }
      [b0] => {
        let n = b0.to_int() << 16
        builder.write_char(alphabet[(n >> 18) & 0x3F].to_char())
        builder.write_char(alphabet[(n >> 12) & 0x3F].to_char())
        if padding is true {
          builder <+ "=="
        }
        break
      }
      [] => break
    }
  }
  builder.to_string()
}
