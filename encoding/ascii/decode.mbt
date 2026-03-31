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
/// Error type `Malformed`.
pub suberror Malformed {
  Malformed(BytesView)
}

///|
fn unsafe_fixedarray_uint16_to_string(buffer : FixedArray[UInt16]) -> String = "%string.unsafe_from_uint16_fixedarray"

///|
fn finish_string(buffer : FixedArray[UInt16], len : Int) -> String {
  if len == buffer.length() {
    unsafe_fixedarray_uint16_to_string(buffer)
  } else {
    let data = FixedArray::make(len, UInt16::default())
    data.unsafe_blit(0, buffer, 0, len)
    unsafe_fixedarray_uint16_to_string(data)
  }
}

///|
/// Decodes an ASCII byte array into a string.
///
/// Raises `Malformed` if any byte is outside the ASCII range.
pub fn decode(bytes : BytesView) -> String raise Malformed {
  let t : FixedArray[UInt16] = FixedArray::make(bytes.length(), 0)
  let tlen = for tlen = 0, bs = bytes {
    match (tlen, bs) {
      (tlen, []) => break tlen
      (tlen, [0..=0x7F as b, .. rest]) => {
        t.unsafe_set(tlen, b.to_uint16())
        continue tlen + 1, rest
      }
      (_, _ as bytes) => raise Malformed(bytes)
    }
  }
  finish_string(t, tlen)
}

///|
/// Decodes ASCII bytes into a string, replacing non-ASCII bytes with U+FFFD.
pub fn decode_lossy(bytes : BytesView) -> String {
  let t : FixedArray[UInt16] = FixedArray::make(bytes.length(), 0)
  let tlen = for tlen = 0, bs = bytes {
    match (tlen, bs) {
      (tlen, []) => break tlen
      (tlen, [0..=0x7F as b, .. rest]) => {
        t.unsafe_set(tlen, b.to_uint16())
        continue tlen + 1, rest
      }
      (tlen, [_, .. rest]) => {
        t.unsafe_set(tlen, 0xFFFD)
        continue tlen + 1, rest
      }
    }
  }
  finish_string(t, tlen)
}
