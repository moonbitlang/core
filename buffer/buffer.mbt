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
  self.data.blit_from_bytes(self.len, value |> uint64_to_bytes, 0, 8)
  self.len += 8
}

///|
/// Write an Int64 into buffer.
pub fn write_int64(self : T, value : Int64) -> Unit {
  self.grow_if_necessary(self.len + 16)
  self.data.blit_from_bytes(self.len, value |> int64_to_bytes, 0, 8)
  self.len += 8
}

///|
/// Write an UInt into buffer.
pub fn write_uint(self : T, value : UInt) -> Unit {
  self.grow_if_necessary(self.len + 8)
  self.data.blit_from_bytes(self.len, value |> uint_to_bytes, 0, 4)
  self.len += 4
}

///|
/// Write an Int into buffer.
pub fn write_int(self : T, value : Int) -> Unit {
  self.grow_if_necessary(self.len + 8)
  self.data.blit_from_bytes(self.len, value |> int_to_bytes, 0, 4)
  self.len += 4
}

///|
/// Write a Double into buffer.
pub fn write_double(self : T, value : Double) -> Unit {
  self.grow_if_necessary(self.len + 16)
  self.data.blit_from_bytes(self.len, value |> double_to_bytes, 0, 8)
  self.len += 8
}

///|
/// Write a Float into buffer.
pub fn write_float(self : T, value : Float) -> Unit {
  self.grow_if_necessary(self.len + 8)
  self.data.blit_from_bytes(self.len, value |> float_to_bytes, 0, 4)
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

///| Convert an UInt64 into a 8 bytes long Bytes.
/// 
/// # Example
/// 
/// ```
/// uint64_number |> uint64_to_bytes
/// ```
pub fn uint64_to_bytes(i : UInt64) -> Bytes {
  let byte1 = i.to_byte()
  let byte2 = (i >> 8).to_byte()
  let byte3 = (i >> 16).to_byte()
  let byte4 = (i >> 24).to_byte()
  let byte5 = (i >> 32).to_byte()
  let byte6 = (i >> 40).to_byte()
  let byte7 = (i >> 48).to_byte()
  let byte8 = (i >> 56).to_byte()
  [byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8]
  |> Bytes::from_fixedarray
}

///| Convert a 8 bytes long Bytes into an UInt64 **without** a length check.
/// This function does not check the input so take the risk at your own.
/// 
/// # Example
/// 
/// ```
/// b"\x11\x45\x14\x19\x19\x81\x00\x00" |> bytes_to_uint64
/// ```
pub fn bytes_to_uint64(bs : Bytes) -> UInt64 {
  let uint64_1 = bs[0] |> Byte::to_uint |> UInt::to_uint64
  let uint64_2 = (bs[1] |> Byte::to_uint |> UInt::to_uint64) << 8
  let uint64_3 = (bs[2] |> Byte::to_uint |> UInt::to_uint64) << 16
  let uint64_4 = (bs[3] |> Byte::to_uint |> UInt::to_uint64) << 24
  let uint64_5 = (bs[4] |> Byte::to_uint |> UInt::to_uint64) << 32
  let uint64_6 = (bs[5] |> Byte::to_uint |> UInt::to_uint64) << 40
  let uint64_7 = (bs[6] |> Byte::to_uint |> UInt::to_uint64) << 48
  let uint64_8 = (bs[7] |> Byte::to_uint |> UInt::to_uint64) << 56
  uint64_1 +
  uint64_2 +
  uint64_3 +
  uint64_4 +
  uint64_5 +
  uint64_6 +
  uint64_7 +
  uint64_8
}

///| Convert an UInt into a 4 bytes long Bytes.
/// 
/// # Example
/// 
/// ```
/// uint_number |> uint_to_bytes
/// ```
pub fn uint_to_bytes(i : UInt) -> Bytes {
  let byte1 = i.to_byte()
  let byte2 = (i >> 8).to_byte()
  let byte3 = (i >> 16).to_byte()
  let byte4 = (i >> 24).to_byte()
  [byte1, byte2, byte3, byte4] |> Bytes::from_fixedarray
}

///| Convert a 4 bytes long Bytes into an UInt **without** a length check.
/// This function does not check the input so take the risk at your own.
/// 
/// # Example
/// 
/// ```
/// b"\x11\x45\x14\x00" |> bytes_to_uint
/// ```
pub fn bytes_to_uint(bs : Bytes) -> UInt {
  let uint64_1 = bs[0].to_uint()
  let uint64_2 = bs[1].to_uint() << 8
  let uint64_3 = bs[2].to_uint() << 16
  let uint64_4 = bs[3].to_uint() << 24
  uint64_1 + uint64_2 + uint64_3 + uint64_4
}

///| Convert a Double into a 8 bytes long Bytes
/// 
/// # Example
/// 
/// ```
/// double_number |> double_to_bytes
/// ```
pub fn double_to_bytes(f : Double) -> Bytes {
  f |> Double::reinterpret_as_uint64 |> uint64_to_bytes
}

///| Convert a 8 bytes long Bytes into an Double **without** a length check.
/// This function does not check the input so take the risk at your own.
/// 
/// # Example
/// 
/// ```
/// b"\x11\x45\x14\x19\x19\x81\x00\x00" |> bytes_to_double_raw
/// ```
pub fn bytes_to_double(bs : Bytes) -> Double {
  bs |> bytes_to_uint64 |> UInt64::reinterpret_as_double
}

///| Convert a Float into a 4 bytes long Bytes
/// 
/// # Example
/// 
/// ```
/// float_number |> float_to_bytes
/// ```
pub fn float_to_bytes(f : Float) -> Bytes {
  f |> Float::reinterpret_as_uint |> uint_to_bytes
}

///| Convert a 4 bytes long Bytes into an Float **without** a length check.
/// This function does not check the input so take the risk at your own.
/// 
/// # Example
/// 
/// ```
/// b"\x11\x45\x14\x00" |> bytes_to_float_raw
/// ```
pub fn bytes_to_float(bs : Bytes) -> Float {
  bs |> bytes_to_uint |> UInt::reinterpret_as_float
}

///| Convert an Int into a 4 bytes long Bytes.
/// 
/// # Example
/// 
/// ```
/// int_number |> int_to_bytes
/// ```
pub fn int_to_bytes(i : Int) -> Bytes {
  i |> Int::reinterpret_as_uint |> uint_to_bytes
}

///| Convert a 4 bytes long Bytes into an Int **without** a length check.
/// This function does not check the input so take the risk at your own.
/// 
/// # Example
/// 
/// ```
/// b"\x11\x45\x14\x00" |> bytes_to_int_raw
/// ```
pub fn bytes_to_int(bs : Bytes) -> Int {
  bs |> bytes_to_uint |> UInt::reinterpret_as_int
}

///| Convert an Int64 into a 8 bytes long Bytes.
/// 
/// # Example
/// 
/// ```
/// int64_number |> int64_to_bytes
/// ```
pub fn int64_to_bytes(i : Int64) -> Bytes {
  i |> Int64::reinterpret_as_uint64 |> uint64_to_bytes
}

///| Convert a 8 bytes long Bytes into an Int64 **without** a length check.
/// This function does not check the input so take the risk at your own.
/// 
/// # Example
/// 
/// ```
/// b"\x11\x45\x14\x19\x19\x81\x00\x00" |> bytes_to_int64_raw
/// ```
pub fn bytes_to_int64(bs : Bytes) -> Int64 {
  bs |> bytes_to_uint64 |> UInt64::reinterpret_as_int64
}

///|
pub impl Show for T with output(self, logger) {
  logger.write_string(self.contents().to_unchecked_string())
}
