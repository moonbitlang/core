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
  let hash = @tls_util.sha1(combined_bytes)

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
priv enum Utf8State {
  Complete
  NeedOne
  NeedTwo
  NeedThree
  AfterE0
  AfterED
  AfterF0
  AfterF4
}

///|
/// Validate a chunk starting in the state left by the preceding chunk.
fn verify_utf8(
  data : BytesView,
  state~ : Utf8State,
) -> Utf8State raise InvalidUtf8 {
  for i = 0, state = state; i < data.length(); {
    let next = match (state, data.unsafe_get(i)) {
      (Complete, 0x00..<=0x7f) => Complete
      (Complete, 0xc2..<=0xdf) => NeedOne
      (Complete, 0xe0) => AfterE0
      (Complete, 0xe1..<=0xec | 0xee..<=0xef) => NeedTwo
      (Complete, 0xed) => AfterED
      (Complete, 0xf0) => AfterF0
      (Complete, 0xf1..<=0xf3) => NeedThree
      (Complete, 0xf4) => AfterF4
      (NeedOne, 0x80..<=0xbf) => Complete
      (NeedTwo, 0x80..<=0xbf) => NeedOne
      (NeedThree, 0x80..<=0xbf) => NeedTwo
      (AfterE0, 0xa0..<=0xbf) | (AfterED, 0x80..<=0x9f) => NeedOne
      (AfterF0, 0x90..<=0xbf) | (AfterF4, 0x80..<=0x8f) => NeedTwo
      _ => raise InvalidUtf8(i)
    }
    continue i + 1, next
  } nobreak {
    state
  }
}
