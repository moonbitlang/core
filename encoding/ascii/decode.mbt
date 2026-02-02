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
pub suberror Malformed {
  Malformed(BytesView)
}

///|
/// Decodes an ASCII byte array into a string.
///
/// Raises `Malformed` if any byte is outside the ASCII range.
pub fn decode(bytes : BytesView) -> String raise Malformed {
  let t : FixedArray[Byte] = FixedArray::make(bytes.length() * 2, 0)
  let tlen = loop (0, bytes) {
    (tlen, []) => tlen
    (tlen, [0..=0x7F as b, .. rest]) => {
      t.unsafe_set(tlen, b)
      continue (tlen + 2, rest)
    }
    (_, _ as bytes) => raise Malformed(bytes)
  }
  t.unsafe_reinterpret_as_bytes().to_unchecked_string(offset=0, length=tlen)
}

///|
/// Decodes ASCII bytes into a string, replacing non-ASCII bytes with U+FFFD.
pub fn decode_lossy(bytes : BytesView) -> String {
  let t : FixedArray[Byte] = FixedArray::make(bytes.length() * 2, 0)
  let tlen = loop (0, bytes) {
    (tlen, []) => tlen
    (tlen, [0..=0x7F as b, .. rest]) => {
      t.unsafe_set(tlen, b)
      continue (tlen + 2, rest)
    }
    (tlen, [_, .. rest]) => {
      t.unsafe_set(tlen, 0xFD)
      t.unsafe_set(tlen + 1, 0xFF)
      continue (tlen + 2, rest)
    }
  }
  t.unsafe_reinterpret_as_bytes().to_unchecked_string(offset=0, length=tlen)
}
