// Copyright 2024 International Digital Economy Academy
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

///| Extensible buffer.
/// @alert deprecated "Use type `T` instead"
pub(all) typealias Buffer = T

///|
/// Extensible buffer.
///
/// It provides accumulative concatenation of bytes in linear time.
/// The capacity of buffer will automatically expand as necessary.
///
/// Note: StringBuilder is recommended for string concatenation in favor of
/// Buffer, since it is optimized for all targets.
/// # Usage
///
/// ```
/// let buf = @buffer.new(size_hint=100)
/// buf.write_string("Tes")
/// buf.write_char('t')
/// assert_eq!(buf.to_unchecked_string(), "Test")
/// ```
struct T {
  mut data : FixedArray[Byte]
  mut len : Int
  initial_data : FixedArray[Byte]
}

///|
/// Expand the buffer size if capacity smaller than required space.
fn grow_if_necessary(self : T, required : Int) -> Unit {
  // TODO: get rid of mut
  let mut enough_space = self.data.length()
  if enough_space <= 0 {
    enough_space = 1
  }
  // double the enough_space until it larger than required
  while enough_space < required {
    enough_space = enough_space * 2
  }
  if enough_space != self.data.length() {
    self.data = FixedArray::make(enough_space, Byte::default())..unsafe_blit(
      0,
      self.data,
      0,
      self.len,
    )
  }
}

///|
/// Return the given buffer's length in bytes.
pub fn length(self : T) -> Int {
  self.len
}

///|
/// Return whether the given buffer is empty.
pub fn is_empty(self : T) -> Bool {
  self.len == 0
}

///|
/// Return the contents of the buffer as a Bytes.
pub fn contents(self : T) -> Bytes {
  Bytes::from_fixedarray(self.data, len=self.len)
}

///|
/// Create a buffer with initial capacity (in bytes).
pub fn T::new(size_hint~ : Int = 0) -> T {
  let initial = if size_hint < 1 { 1 } else { size_hint }
  let data = FixedArray::make(initial, Byte::default())
  { data, len: 0, initial_data: data }
}

///|
/// Write a string into buffer.
pub fn write_string(self : T, value : String) -> Unit {
  self.grow_if_necessary(self.len + value.length() * 2)
  self.data.blit_from_string(self.len, value, 0, value.length())
  self.len += value.length() * 2
}

///|
/// Write an UInt64 into buffer.
pub fn write_uint64(self : T, value : UInt64) -> Unit {
  self.grow_if_necessary(self.len + 16)
  self.data.blit_from_bytes(self.len, value |> UInt64::to_bytes, 0, 8)
  self.len += 8
}

///|
/// Write an Int64 into buffer.
pub fn write_int64(self : T, value : Int64) -> Unit {
  self.grow_if_necessary(self.len + 16)
  self.data.blit_from_bytes(self.len, value |> Int64::to_bytes, 0, 8)
  self.len += 8
}

///|
/// Write an UInt into buffer.
pub fn write_uint(self : T, value : UInt) -> Unit {
  self.grow_if_necessary(self.len + 8)
  self.data.blit_from_bytes(self.len, value |> UInt::to_bytes, 0, 4)
  self.len += 4
}

///|
/// Write an Int into buffer.
pub fn write_int(self : T, value : Int) -> Unit {
  self.grow_if_necessary(self.len + 8)
  self.data.blit_from_bytes(self.len, value |> Int::to_bytes, 0, 4)
  self.len += 4
}

///|
/// Write a Double into buffer.
pub fn write_double(self : T, value : Double) -> Unit {
  self.grow_if_necessary(self.len + 16)
  self.data.blit_from_bytes(self.len, value |> Double::to_bytes, 0, 8)
  self.len += 8
}

///|
/// Write a Float into buffer.
pub fn write_float(self : T, value : Float) -> Unit {
  self.grow_if_necessary(self.len + 8)
  self.data.blit_from_bytes(self.len, value |> Float::to_bytes, 0, 4)
  self.len += 4
}

///|
pub fn write_object(self : T, value : Show) -> Unit {
  self.write_string(value.to_string())
}

///|
pub fn write_bytes(self : T, value : Bytes) -> Unit {
  let val_len = value.length()
  self.grow_if_necessary(self.len + val_len)
  self.data.blit_from_bytes(self.len, value, 0, val_len)
  self.len += val_len
}

///|
/// Write a sub-string into buffer.
pub fn write_substring(
  self : T,
  value : String,
  start : Int,
  len : Int
) -> Unit {
  guard start >= 0 && len >= 0 && start + len <= value.length()
  self.grow_if_necessary(self.len + len * 2)
  self.data.blit_from_string(self.len, value, start, len)
  self.len += len * 2
}

///|
/// Write a char into buffer.
pub fn write_char(self : T, value : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.data.set_utf16le_char(self.len, value)
  self.len += inc
}

///|
/// Write a byte into buffer.
pub fn write_byte(self : T, value : Byte) -> Unit {
  self.grow_if_necessary(self.len + 1)
  self.data[self.len] = value
  self.len += 1
}

///|
pub fn reset(self : T) -> Unit {
  self.data = self.initial_data
  self.len = 0
}

///|
pub fn to_bytes(self : T) -> Bytes {
  Bytes::from_fixedarray(self.data, len=self.len)
}

///|
pub impl Show for T with output(self, logger) {
  logger.write_string(self.contents().to_unchecked_string())
}
