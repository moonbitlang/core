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
/// Apply XOR mask to payload data
fn mask_payload(
  data : FixedArray[Byte],
  mask : BytesView,
  offset~ : Int32,
  len~ : Int32,
  mask_offset~ : Int32 = 0,
) -> Unit {
  for i = 0; i < len; i = i + 1 {
    data[offset + i] = data[offset + i] ^ mask[(mask_offset + i) % 4]
  }
}

///|
const MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

///|
/// Generate WebSocket accept key from client key using SHA-1 and base64
#warnings("-unused_error_type")
fn generate_accept_key(client_key : String) -> String raise {
  // WebSocket magic string as defined in RFC 6455
  let combined = client_key + MAGIC
  let combined_bytes = @utf8.encode(combined)

  // Use the crypto library for proper SHA-1 hashing
  let hash = @tls.sha1(combined_bytes)

  // Use our base64 encoding function for now
  @base64.encode(hash)
}

///|
/// Raised by `verify_utf8` with the offset of the offending byte.
#derive(@debug.Debug)
priv suberror InvalidUtf8 {
  InvalidUtf8(Int32)
}

///|
/// Incrementally validate UTF-8 (RFC 3629), rejecting overlong forms,
/// surrogates and code points above U+10FFFF.
///
/// `remaining` is the state left by the previous chunk, and the new state is
/// returned. `0` means the input ends on a character boundary, `1..=3` means
/// that many continuation bytes (`80..BF`) are still expected, and `4..=7`
/// means the next byte is the first continuation byte of a character whose
/// lead byte restricts it:
///
/// - `4`: after `E0`, `A0..BF` follows, then 1 more
/// - `5`: after `ED`, `80..9F` follows, then 1 more
/// - `6`: after `F0`, `90..BF` follows, then 2 more
/// - `7`: after `F4`, `80..8F` follows, then 2 more
fn verify_utf8(data : BytesView, remaining~ : Int32) -> Int32 raise InvalidUtf8 {
  for i = 0, state = remaining; i < data.length(); {
    let next = match (state, data.unsafe_get(i)) {
      (0, 0x00..<=0x7f) => 0
      (0, 0xc2..<=0xdf) => 1
      (0, 0xe0) => 4
      (0, 0xe1..<=0xec | 0xee..<=0xef) => 2
      (0, 0xed) => 5
      (0, 0xf0) => 6
      (0, 0xf1..<=0xf3) => 3
      (0, 0xf4) => 7
      (1..<=3, 0x80..<=0xbf) => state - 1
      (4, 0xa0..<=0xbf) | (5, 0x80..<=0x9f) => 1
      (6, 0x90..<=0xbf) | (7, 0x80..<=0x8f) => 2
      _ => raise InvalidUtf8(i)
    }
    continue i + 1, next
  } nobreak {
    state
  }
}
