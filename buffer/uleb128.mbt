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
fn Buffer::write_uleb128_uint(self : Buffer, value : UInt) -> Unit {
  self.grow_if_necessary(self.len + 5)
  let data = self.data
  let mut len = self.len
  for value = value {
    if value < 128U {
      // Single byte: no continuation bit (0xxxxxxx)
      data.unsafe_set(len, value.to_byte())
      len = len + 1
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      data.unsafe_set(len, ((value & 127U) | 128U).to_byte())
      len = len + 1
      continue value >> 7
    }
  }
  self.len = len
}

///|
fn Buffer::write_uleb128_uint64(self : Buffer, value : UInt64) -> Unit {
  self.grow_if_necessary(self.len + 10)
  let data = self.data
  let mut len = self.len
  for value = value {
    if value < 128UL {
      // Single byte: no continuation bit (0xxxxxxx)
      data.unsafe_set(len, value.to_byte())
      len = len + 1
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      data.unsafe_set(len, ((value & 127UL) | 128UL).to_byte())
      len = len + 1
      continue value >> 7
    }
  }
  self.len = len
}

///|
pub impl Leb128 for UInt with fn output(self, buffer) {
  buffer.write_uleb128_uint(self)
}

///|
pub impl Leb128 for UInt64 with fn output(self, buffer) {
  buffer.write_uleb128_uint64(self)
}
