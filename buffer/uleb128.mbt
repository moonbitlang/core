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
pub impl Leb128 for UInt with fn output(self, buffer) {
  // A 32-bit LEB128 value needs at most 5 bytes. Reserving them before
  // caching `data` makes every unsafe write below stay within the buffer.
  let required = buffer.len + 5
  if required > buffer.data.length() || required < buffer.len {
    buffer.grow(required)
  }
  let data = buffer.data
  let mut len = buffer.len
  for value = self {
    if value < 128U {
      // Single byte: no continuation bit (0xxxxxxx)
      data.unsafe_set(len, value.to_byte())
      len += 1
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      data.unsafe_set(len, ((value & 127U) | 128U).to_byte())
      len += 1
      continue value >> 7
    }
  }
  buffer.len = len
}

///|
pub impl Leb128 for UInt64 with fn output(self, buffer) {
  // A 64-bit LEB128 value needs at most 10 bytes. Reserving them before
  // caching `data` makes every unsafe write below stay within the buffer.
  let required = buffer.len + 10
  if required > buffer.data.length() || required < buffer.len {
    buffer.grow(required)
  }
  let data = buffer.data
  let mut len = buffer.len
  for value = self {
    if value < 128UL {
      // Single byte: no continuation bit (0xxxxxxx)
      data.unsafe_set(len, value.to_byte())
      len += 1
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      data.unsafe_set(len, ((value & 127UL) | 128UL).to_byte())
      len += 1
      continue value >> 7
    }
  }
  buffer.len = len
}
