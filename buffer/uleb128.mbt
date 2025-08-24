// Copyright 2025 International Digital Economy Academy
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
trait Unsigned {
  output_uleb128(Self, Buffer) -> Unit
}

///|
pub impl Unsigned for Int with output_uleb128(self, buffer) {
  for value = self {
    if value < 128 {
      // Single byte: no continuation bit (0xxxxxxx)
      buffer.write_byte(value.to_byte())
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      buffer.write_byte(((value % 128) | 128).to_byte())
      continue value / 128
    }
  }
}

///|
pub impl Unsigned for UInt with output_uleb128(self, buffer) {
  for value = self {
    if value < 128 {
      // Single byte: no continuation bit (0xxxxxxx)
      buffer.write_byte(value.to_byte())
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      buffer.write_byte(((value % 128) | 128).to_byte())
      continue value / 128
    }
  }
}

///|
pub impl Unsigned for Int64 with output_uleb128(self, buffer) {
  for value = self {
    if value < 128 {
      // Single byte: no continuation bit (0xxxxxxx)
      buffer.write_byte(value.to_byte())
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      buffer.write_byte(((value % 128) | 128).to_byte())
      continue value / 128
    }
  }
}

///|
pub impl Unsigned for UInt64 with output_uleb128(self, buffer) {
  for value = self {
    if value < 128 {
      // Single byte: no continuation bit (0xxxxxxx)
      buffer.write_byte(value.to_byte())
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      buffer.write_byte(((value % 128) | 128).to_byte())
      continue value / 128
    }
  }
}

///|
/// Writes an unsigned integer to the buffer using ULEB128 (Unsigned Little Endian Base 128) encoding.
/// 
/// ULEB128 is a variable-length encoding that uses the most significant bit of each byte 
/// as a continuation flag. Each byte encodes 7 bits of the value, with the MSB indicating
/// whether more bytes follow (1) or if this is the final byte (0).
///
/// # Parameters
/// - `buffer`: The buffer to write to
/// - `value`: The unsigned integer value to encode
///
/// # Example
/// ```moonbit
/// let buf = @buffer.new()
/// buf.write_uleb128(300)  // Writes: 0xAC 0x02
/// ```
pub fn[A : Unsigned] Buffer::write_uleb128(buffer : Buffer, value : A) -> Unit {
  value.output_uleb128(buffer)
}
