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
  output(Self, Buffer) -> Unit
}

///|
pub impl Leb128 for Int with output(self, buffer) {
  for value = self, shift = 0 {
    let byte = value & 0x7f // Get the low 7 bits
    let next_value = value >> 7 // Arithmetic right shift
    let sign_bit_set = (byte & 0x40) != 0
    let need_more = if value >= 0 {
      next_value != 0 || sign_bit_set
    } else {
      next_value != -1 || !sign_bit_set
    }
    if need_more {
      buffer.write_byte((byte | 0x80).to_byte())
      continue next_value, shift + 7
    } else {
      buffer.write_byte(byte.to_byte())
      break
    }
  } where {
    invariant: shift >= 0,
    invariant: shift % 7 == 0,
    invariant: value == self >> shift,
    reasoning: (
      #|Each iteration shifts the remaining value right by 7 bits,
      #|so `value` tracks the unencoded suffix and converges to 0 or -1.
    ),
  }
}

///|
pub impl Leb128 for Int64 with output(self, buffer) {
  for value = self, shift = 0 {
    let byte = value & 0x7f // Get the low 7 bits
    let next_value = value >> 7 // Arithmetic right shift
    let sign_bit_set = (byte & 0x40) != 0
    let need_more = if value >= 0 {
      next_value != 0 || sign_bit_set
    } else {
      next_value != -1 || !sign_bit_set
    }
    if need_more {
      buffer.write_byte((byte | 0x80).to_byte())
      continue next_value, shift + 7
    } else {
      buffer.write_byte(byte.to_byte())
      break
    }
  } where {
    invariant: shift >= 0,
    invariant: shift % 7 == 0,
    invariant: value == self >> shift,
    reasoning: (
      #|Each iteration shifts the remaining value right by 7 bits,
      #|so `value` tracks the unencoded suffix and converges to 0 or -1.
    ),
  }
}

///|
pub fn[A : Leb128] Buffer::write_leb128(buffer : Buffer, value : A) -> Unit {
  value.output(buffer)
}
