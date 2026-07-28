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
trait Leb128 {
  fn output(Self, Buffer) -> Unit
}

///|
pub impl Leb128 for Int with fn output(self, buffer) {
  // A 32-bit LEB128 value needs at most 5 bytes. Reserving them before
  // caching `data` makes every unsafe write below stay within the buffer.
  buffer.grow_if_necessary(buffer.len + 5)
  let data = buffer.data
  let mut len = buffer.len
  for value = self {
    let byte = value & 0x7f // Get the low 7 bits
    let next_value = value >> 7 // Arithmetic right shift
    let sign_bit_set = (byte & 0x40) != 0
    let need_more = if value >= 0 {
      next_value != 0 || sign_bit_set
    } else {
      next_value != -1 || !sign_bit_set
    }
    if need_more {
      data.unsafe_set(len, (byte | 0x80).to_byte())
      len += 1
      continue next_value
    } else {
      data.unsafe_set(len, byte.to_byte())
      len += 1
      break
    }
  }
  buffer.len = len
}

///|
pub impl Leb128 for Int64 with fn output(self, buffer) {
  // A 64-bit LEB128 value needs at most 10 bytes. Reserving them before
  // caching `data` makes every unsafe write below stay within the buffer.
  buffer.grow_if_necessary(buffer.len + 10)
  let data = buffer.data
  let mut len = buffer.len
  for value = self {
    let byte = value & 0x7f // Get the low 7 bits
    let next_value = value >> 7 // Arithmetic right shift
    let sign_bit_set = (byte & 0x40) != 0
    let need_more = if value >= 0 {
      next_value != 0 || sign_bit_set
    } else {
      next_value != -1 || !sign_bit_set
    }
    if need_more {
      data.unsafe_set(len, (byte | 0x80).to_byte())
      len += 1
      continue next_value
    } else {
      data.unsafe_set(len, byte.to_byte())
      len += 1
      break
    }
  }
  buffer.len = len
}

///|
/// Encode a value as signed LEB128 and append it to the buffer.
///
/// This works for types implementing `Leb128`, currently including `Int` and
/// `Int64`.
///
/// Parameters:
///
/// - `buffer`: destination buffer.
/// - `value`: value to encode.
///
/// Example:
///
/// ```mbt check
/// test {
///   let buf = Buffer()
///   buf.write_leb128(127)
///   inspect(buf.contents().length() > 0, content="true")
/// }
/// ```
pub fn[A : Leb128] Buffer::write_leb128(buffer : Buffer, value : A) -> Unit {
  value.output(buffer)
}
