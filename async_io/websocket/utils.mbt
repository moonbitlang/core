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
fn verify_utf8(data : BytesView, remaining~ : Int32) -> Int32 raise {
  for i = 0, remaining = remaining; i < data.length(); {
    match (remaining, data.unsafe_get(i)) {
      (0, 0..<0x80) => continue i + 1, 0
      (0, 0xc0..<0xe0) => continue i + 1, 1
      (0, 0xe0..<0xf0) => continue i + 1, 2
      (0, 0xf0..<0xf8) => continue i + 1, 3
      (0, _) => {
        ignore(@utf8.decode(data[i:i + 1]))
        panic()
      }
      (remaining, 0x80..<0xc0) => continue i + 1, remaining - 1
      (_, byte) => {
        ignore(@utf8.decode([0xc0, byte]))
        panic()
      }
    }
  } nobreak {
    remaining
  }
}
