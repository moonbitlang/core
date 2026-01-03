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
/// Create a buffer from an internal iterator.
#warnings("-deprecated")
#deprecated("Use `Buffer::from_iterator()` with an external iterator.")
pub fn from_iter(iter : Iter[Byte]) -> Buffer {
  let buf = new()
  let mut capacity = buf.data.length()
  for byte in iter {
    // inline write_byte and grow_if_necessary
    // only call grow_if_necessary when necessary
    if buf.len == capacity {
      buf.grow_if_necessary(capacity + 1)
      capacity = buf.data.length()
    }
    buf.data[buf.len] = byte
    buf.len += 1
  }
  buf
}

///|
/// Writes bytes from an internal iterator to the buffer.
#warnings("-deprecated")
#deprecated("Use `Buffer::write_iterator()` with an external iterator.")
pub fn Buffer::write_iter(self : Buffer, iter : Iter[Byte]) -> Unit {
  for byte in iter {
    self.write_byte(byte)
  }
}
