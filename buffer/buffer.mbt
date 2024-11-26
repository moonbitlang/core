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
/// Return a new string contains the data in buffer.
/// 
/// @alert deprecated "Use `Buffer::to_unchecked_string` instead"
pub fn to_string(self : T) -> String {
  self.to_unchecked_string()
}

///|
/// Return a new unchecked string contains the data in buffer.
/// Note this function does not validate the encoding of the byte sequence, 
/// it simply copy the bytes into a new String.
pub fn to_unchecked_string(self : T, offset? : Int, length? : Int) -> String {
  let offset = match offset {
    None => 0
    Some(x) => x
  }
  let length = match length {
    None => self.len
    Some(x) => x
  }
  Bytes::from_fixedarray(self.data).to_unchecked_string(offset~, length~)
}

///|
/// Create a buffer with initial capacity (in bytes).
pub fn T::new(size_hint~ : Int = 0) -> T {
  let initial = if size_hint < 1 { 1 } else { size_hint }
  let data = FixedArray::make(initial, Byte::default())
  { data, len: 0, initial_data: data }
}

///|
pub fn T::from_bytes(bytes : Bytes) -> T {
  let buf = T::new(size_hint=bytes.length())
  buf.write_bytes(bytes)
  buf
}

///|
pub fn T::from_array(arr : Array[Byte]) -> T {
  let buf = T::new(size_hint=arr.length())
  for byte in arr {
    buf.write_byte(byte)
  }
  buf
}

///|
/// Write a string into buffer.
pub fn write_string(self : T, value : String) -> Unit {
  self.grow_if_necessary(self.len + value.length() * 2)
  self.data.blit_from_string(self.len, value, 0, value.length())
  self.len += value.length() * 2
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
/// Write a sub-string into buffer.
/// @alert deprecated "Use `Buffer::write_substring` instead"
pub fn write_sub_string(
  self : T,
  value : String,
  start : Int,
  len : Int
) -> Unit {
  self.write_substring(value, start, len)
}

///|
/// Write a char into buffer as UTF16LE.
pub fn write_char(self : T, value : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.data.set_utf16le_char(self.len, value)
  self.len += inc
}

///|
/// Write a char into buffer as UTF16BE.
pub fn write_utf16be_char(self : T, value : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.data.set_utf16be_char(self.len, value)
  self.len += inc
}

///|
/// Write a char into buffer as UTF8.
pub fn write_utf8_char(self : T, value : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.data.set_utf8_char(self.len, value)
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
pub fn blit(self : T, srcoff : Int, dst : T, dstoff : Int, len : Int) -> Unit {
  Bytes::blit(self.to_bytes(), srcoff, dst.to_bytes(), dstoff, len)
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
pub fn to_array(self : T) -> Array[Byte] {
  self.to_bytes().to_array()
}

///|
pub fn op_set(self : T, index : Int, value : Byte) -> Unit {
  let len = self.length()
  guard index >= 0 && index < len
  self.data[index] = value
}

///|
pub fn op_get(self : T, index : Int) -> Byte {
  let len = self.length()
  guard index >= 0 && index < len
  self.data[index]
}

///|
pub impl Show for T with output(self, logger) {
  logger.write_string(self.to_unchecked_string(offset=0, length=self.len))
}
