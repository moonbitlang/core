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
/// Extensible buffer.
///
/// It provides accumulative concatenation of bytes in linear time.
/// The capacity of buffer will automatically expand as necessary.
///
/// Note: StringBuilder is recommended for string concatenation in favor of
/// Buffer, since it is optimized for all targets.
/// # Usage
///
/// ```mbt
///   let buf = @buffer.new(size_hint=100)
///   buf.write_string("Tes")
///   buf.write_char('t')
///   inspect(
///     buf.contents(), 
///     content=(
///       #|b"\x54\x00\x65\x00\x73\x00\x74\x00"
///     ),
///   )
/// ```
struct Buffer {
  mut data : FixedArray[Byte]
  mut len : Int
  initial_data : FixedArray[Byte]
}

///|
/// Expand the buffer size if capacity smaller than required space.
fn grow_if_necessary(self : Buffer, required : Int) -> Unit {
  let start = if self.data.length() <= 0 { 1 } else { self.data.length() }
  let enough_space = for space = start {
    if space >= required {
      break space
    }
    continue space * 2
  }
  if enough_space != self.data.length() {
    let new_data = FixedArray::make(enough_space, Byte::default())
    new_data.unsafe_blit(0, self.data, 0, self.len)
    self.data = new_data
  }
}

///|
/// Returns the number of bytes currently stored in the buffer.
///
/// Parameters:
///
/// * `buffer`: The buffer to get the length from.
///
/// Returns the length of the buffer in bytes.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_string("Test")
///   inspect(buf.length(), content="8") // each char takes 2 bytes in UTF-16
/// ```
pub fn length(self : Buffer) -> Int {
  self.len
}

///|
/// Returns whether the buffer is empty.
///
/// Parameters:
///
/// * `buffer` : The buffer to check.
///
/// Returns `true` if the buffer is empty (i.e., contains no bytes), `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   inspect(buf.is_empty(), content="true")
///   buf.write_string("test")
///   inspect(buf.is_empty(), content="false")
/// ```
pub fn is_empty(self : Buffer) -> Bool {
  self.len == 0
}

///|
/// Returns a copy of the buffer's content as a sequence of bytes.
///
/// Parameters:
///
/// * `buffer` : The buffer to read from.
///
/// Returns a `Bytes` object containing all bytes written to the buffer.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_string("Test")
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\x54\x00\x65\x00\x73\x00\x74\x00"
///     ),
///   )
/// ```
pub fn contents(self : Buffer) -> Bytes {
  @bytes.from_fixedarray(self.data, len=self.len)
}

///|
/// Creates a new extensible buffer with specified initial capacity. If the
/// initial capacity is less than 1, the buffer will be initialized with capacity
/// 1.
///
/// Parameters:
///
/// * `size_hint` : Initial capacity of the buffer in bytes. Defaults to 0.
///
/// Returns a new buffer of type `Buffer`.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new(size_hint=10)
///   inspect(buf.length(), content="0")
///   buf.write_string("test")
///   inspect(buf.length(), content="8")
/// ```
pub fn new(size_hint? : Int = 0) -> Buffer {
  let initial = if size_hint < 1 { 1 } else { size_hint }
  let data = FixedArray::make(initial, Byte::default())
  { data, len: 0, initial_data: data }
}

///|
/// Create a buffer from a bytes.
pub fn from_bytes(bytes : Bytes) -> Buffer {
  let val_len = bytes.length()
  let buf = new(size_hint=val_len)
  // inline write_bytes, skip grow_if_necessary check
  // SAFETY: known bytes size
  buf.data.blit_from_bytes(0, bytes, 0, val_len)
  buf.len = val_len
  buf
}

///|
/// Create a buffer from an array.
pub fn from_array(arr : Array[Byte]) -> Buffer {
  let buf = new(size_hint=arr.length())
  for byte in arr {
    // inline write_byte, skip grow_if_necessary check
    // SAFETY: known array size
    buf.data[buf.len] = byte
    buf.len += 1
  }
  buf
}

///|
/// Create a buffer from an iterator.
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
/// Writes a UTF-16LE encoded string into the buffer. The buffer will
/// automatically grow if needed to accommodate the string.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `string` : The string to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_string("Test")
///   // Each UTF-16 char takes 2 bytes in little-endian format
///   // 'T' -> [0x54, 0x00]
///   // 'e' -> [0x65, 0x00]
///   // 's' -> [0x73, 0x00]
///   // 't' -> [0x74, 0x00]
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\x54\x00\x65\x00\x73\x00\x74\x00"
///     ),
///   )
/// ```
pub impl Logger for Buffer with write_string(self, value) {
  self.grow_if_necessary(self.len + value.length() * 2)
  self.data.blit_from_string(self.len, value, 0, value.length())
  self.len += value.length() * 2
}

///|
/// Writes an unsigned 64-bit integer into the buffer in big-endian format (most
/// significant byte first).
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The unsigned 64-bit integer to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_uint64_be(0xAABBCCDD11223344)
///   // Bytes are written in big-endian order
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\xaa\xbb\xcc\xdd\x11\x22\x33\x44"
///     ),
///   )
/// ```
pub fn write_uint64_be(self : Buffer, value : UInt64) -> Unit {
  self.write_byte((value >> 56).to_byte())
  self.write_byte((value >> 48).to_byte())
  self.write_byte((value >> 40).to_byte())
  self.write_byte((value >> 32).to_byte())
  self.write_byte((value >> 24).to_byte())
  self.write_byte((value >> 16).to_byte())
  self.write_byte((value >> 8).to_byte())
  self.write_byte(value.to_byte())
}

///|
/// Writes an unsigned 64-bit integer to the buffer in little-endian byte order.
/// Each byte is written sequentially from least significant to most significant.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The UInt64 value to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_uint64_le(0x0123456789ABCDEF)
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\xef\xcd\xab\x89\x67\x45\x23\x01"
///     ),
///   )
/// ```
pub fn write_uint64_le(self : Buffer, value : UInt64) -> Unit {
  self.write_byte(value.to_byte())
  self.write_byte((value >> 8).to_byte())
  self.write_byte((value >> 16).to_byte())
  self.write_byte((value >> 24).to_byte())
  self.write_byte((value >> 32).to_byte())
  self.write_byte((value >> 40).to_byte())
  self.write_byte((value >> 48).to_byte())
  self.write_byte((value >> 56).to_byte())
}

///|
/// Writes a 64-bit integer into the buffer in big-endian format, where the most
/// significant byte is written first.
///
/// Parameters:
///
/// * `buffer` : The buffer to write into.
/// * `value` : The 64-bit integer to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_int64_be(0x0102030405060708L)
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\x01\x02\x03\x04\x05\x06\x07\x08"
///     ),
///   )
/// ```
pub fn write_int64_be(self : Buffer, value : Int64) -> Unit {
  self.write_uint64_be(value.reinterpret_as_uint64())
}

///|
/// Writes a 64-bit signed integer to the buffer in little-endian byte order.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The 64-bit signed integer to write.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_int64_le(-1L)
///   inspect(
///     buf.contents(), 
///     content=(
///       #|b"\xff\xff\xff\xff\xff\xff\xff\xff"
///     ),
///   )
/// ```
pub fn write_int64_le(self : Buffer, value : Int64) -> Unit {
  self.write_uint64_le(value.reinterpret_as_uint64())
}

///|
/// Writes a 32-bit unsigned integer into the buffer in big-endian format (most
/// significant byte first).
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The unsigned integer value to write.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_uint_be(0x12345678)
///   inspect(buf.contents(), content="b\"\\x12\\x34\\x56\\x78\"")
/// ```
pub fn write_uint_be(self : Buffer, value : UInt) -> Unit {
  self.write_byte((value >> 24).to_byte())
  self.write_byte((value >> 16).to_byte())
  self.write_byte((value >> 8).to_byte())
  self.write_byte(value.to_byte())
}

///|
/// Writes a 32-bit unsigned integer into the buffer in little-endian format. The
/// integer is split into 4 bytes and written in order from least significant to
/// most significant byte.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : A 32-bit unsigned integer to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_uint_le(0x12345678)
///   inspect(buf.contents(), content="b\"\\x78\\x56\\x34\\x12\"")
/// ```
pub fn write_uint_le(self : Buffer, value : UInt) -> Unit {
  self.write_byte(value.to_byte())
  self.write_byte((value >> 8).to_byte())
  self.write_byte((value >> 16).to_byte())
  self.write_byte((value >> 24).to_byte())
}

///|
/// Writes a 32-bit integer to the buffer in big-endian format. Big-endian means
/// the most significant byte is written first.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The 32-bit integer to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_int_be(0x12345678)
///   inspect(buf.contents(), content="b\"\\x12\\x34\\x56\\x78\"")
/// ```
pub fn write_int_be(self : Buffer, value : Int) -> Unit {
  self.write_uint_be(value.reinterpret_as_uint())
}

///|
/// Writes a 32-bit integer into the buffer in little-endian format. The integer
/// is first reinterpreted as an unsigned integer, then written as 4 bytes where
/// the least significant byte is written first.
///
/// Parameters:
///
/// * `buffer` : The buffer to write into.
/// * `value` : The integer value to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_int_le(-1)
///   inspect(buf.contents(), content="b\"\\xff\\xff\\xff\\xff\"")
/// ```
pub fn write_int_le(self : Buffer, value : Int) -> Unit {
  self.write_uint_le(value.reinterpret_as_uint())
}

///|
/// Writes an IEEE 754 double-precision floating-point number into the buffer in
/// big-endian format (most significant byte first).
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The double-precision floating-point number to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_double_be(1.0)
///   inspect(buf.contents(), content="b\"\\x3f\\xf0\\x00\\x00\\x00\\x00\\x00\\x00\"")
/// ```
pub fn write_double_be(self : Buffer, value : Double) -> Unit {
  self.write_uint64_be(value.reinterpret_as_uint64())
}

///|
/// Writes a double-precision floating-point number into the buffer in
/// little-endian format.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The double-precision floating-point number to write.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_double_le(3.14)
///   inspect(
///     buf.contents(),
///     content="b\"\\x1f\\x85\\xeb\\x51\\xb8\\x1e\\x09\\x40\"",
///   )
/// ```
pub fn write_double_le(self : Buffer, value : Double) -> Unit {
  self.write_uint64_le(value.reinterpret_as_uint64())
}

///|
/// Writes a 32-bit floating-point number to the buffer in big-endian byte order.
/// The float value is first reinterpreted as a 32-bit unsigned integer before
/// writing.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The floating-point number to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_float_be(3.14)
///   // In big-endian format, 3.14 is represented as [0x40, 0x48, 0xF5, 0xC3]
///   inspect(buf.contents(), content="b\"\\x40\\x48\\xf5\\xc3\"")
/// ```
pub fn write_float_be(self : Buffer, value : Float) -> Unit {
  self.write_uint_be(value.reinterpret_as_uint())
}

///|
/// Writes a Float value into the buffer in little-endian format. The float value
/// is converted to its binary representation and written as four bytes.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The Float value to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_float_le(3.14)
///   // The bytes are written in little-endian format
///   inspect(buf.contents(), content="b\"\\xc3\\xf5\\x48\\x40\"")
/// ```
pub fn write_float_le(self : Buffer, value : Float) -> Unit {
  self.write_uint_le(value.reinterpret_as_uint())
}

///|
/// Writes a string representation of any value that implements the `Show` trait
/// into the buffer.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : Any value that implements the `Show` trait. The value will be
/// converted to a string using its `to_string` method before being written to
/// the buffer.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_object(42)
///   inspect(buf.contents().to_unchecked_string(), content="42")
/// ```
pub fn write_object(self : Buffer, value : &Show) -> Unit {
  self.write_string(value.to_string())
}

///|
/// Writes a sequence of bytes into the buffer.
///
/// Parameters:
///
/// * `buffer` : An extensible buffer to write into.
/// * `bytes` : The sequence of bytes to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_bytes(b"Test")
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\x54\x65\x73\x74"
///     ),
///   )
/// ```
pub fn write_bytes(self : Buffer, value : Bytes) -> Unit {
  let val_len = value.length()
  self.grow_if_necessary(self.len + val_len)
  self.data.blit_from_bytes(self.len, value, 0, val_len)
  self.len += val_len
}

///|
/// Writes a sequence of bytes from a @bytes.View into the buffer.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `value` : The View containing the bytes to write.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   let view = b"Test"[1:3]
///   buf.write_bytesview(view)
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\x65\x73"
///     ),
///   )
/// ```
pub fn write_bytesview(self : Buffer, value : @bytes.View) -> Unit {
  let val_len = value.length()
  self.grow_if_necessary(self.len + val_len)
  self.data.blit_from_bytes(
    self.len,
    value.data(),
    value.start_offset(),
    value.length(),
  )
  self.len += val_len
}

///|
/// Write a char into buffer as UTF8.
pub fn Buffer::write_char_utf8(buf : Self, value : Char) -> Unit {
  let code = value.to_uint()
  match code {
    _..<0x80 => {
      buf.grow_if_necessary(buf.len + 1)
      buf.data[buf.len] = ((code & 0x7F) | 0x00).to_byte()
      buf.len += 1
    }
    _..<0x0800 => {
      buf.grow_if_necessary(buf.len + 2)
      buf.data[buf.len] = (((code >> 6) & 0x1F) | 0xC0).to_byte()
      buf.data[buf.len + 1] = ((code & 0x3F) | 0x80).to_byte()
      buf.len += 2
    }
    _..<0x010000 => {
      buf.grow_if_necessary(buf.len + 3)
      buf.data[buf.len] = (((code >> 12) & 0x0F) | 0xE0).to_byte()
      buf.data[buf.len + 1] = (((code >> 6) & 0x3F) | 0x80).to_byte()
      buf.data[buf.len + 2] = ((code & 0x3F) | 0x80).to_byte()
      buf.len += 3
    }
    _..<0x110000 => {
      buf.grow_if_necessary(buf.len + 4)
      buf.data[buf.len] = (((code >> 18) & 0x07) | 0xF0).to_byte()
      buf.data[buf.len + 1] = (((code >> 12) & 0x3F) | 0x80).to_byte()
      buf.data[buf.len + 2] = (((code >> 6) & 0x3F) | 0x80).to_byte()
      buf.data[buf.len + 3] = ((code & 0x3F) | 0x80).to_byte()
      buf.len += 4
    }
    _ => abort("Char out of range")
  }
}

///|
/// Write a char into buffer as UTF16LE.
pub fn Buffer::write_char_utf16le(buf : Self, value : Char) -> Unit {
  let code = value.to_uint()
  if code < 0x10000 {
    buf.grow_if_necessary(buf.len + 2)
    buf.data[buf.len + 0] = (code & 0xFF).to_byte()
    buf.data[buf.len + 1] = (code >> 8).to_byte()
    buf.len += 2
  } else if code < 0x110000 {
    let hi = code - 0x10000
    let lo = (hi >> 10) | 0xD800
    let hi = (hi & 0x3FF) | 0xDC00
    buf.grow_if_necessary(buf.len + 4)
    buf.data[buf.len + 0] = (lo & 0xFF).to_byte()
    buf.data[buf.len + 1] = (lo >> 8).to_byte()
    buf.data[buf.len + 2] = (hi & 0xFF).to_byte()
    buf.data[buf.len + 3] = (hi >> 8).to_byte()
    buf.len += 4
  } else {
    abort("Char out of range")
  }
}

///|
/// Write a char into buffer as UTF16BE.
pub fn Buffer::write_char_utf16be(buf : Self, value : Char) -> Unit {
  let code = value.to_uint()
  if code < 0x10000 {
    buf.grow_if_necessary(buf.len + 2)
    buf.data[buf.len + 0] = (code >> 8).to_byte()
    buf.data[buf.len + 1] = (code & 0xFF).to_byte()
    buf.len += 2
  } else if code < 0x110000 {
    buf.grow_if_necessary(buf.len + 4)
    let hi = code - 0x10000
    let lo = (hi >> 10) | 0xD800
    let hi = (hi & 0x3FF) | 0xDC00
    buf.data[buf.len + 0] = (lo >> 8).to_byte()
    buf.data[buf.len + 1] = (lo & 0xFF).to_byte()
    buf.data[buf.len + 2] = (hi >> 8).to_byte()
    buf.data[buf.len + 3] = (hi & 0xFF).to_byte()
    buf.len += 4
  } else {
    abort("Char out of range")
  }
}

///|
pub fn Buffer::write_string_utf8(buf : Self, string : @string.View) -> Unit {
  for ch in string {
    buf.write_char_utf8(ch)
  }
}

///|
#alias(write_stringview, deprecated="use write_string_utf16le instead")
pub fn Buffer::write_string_utf16le(buf : Self, string : @string.View) -> Unit {
  let len = string.length()
  buf.grow_if_necessary(buf.len + len * 2)
  for i = 0, j = buf.len; i < len; i = i + 1, j = j + 2 {
    let c = string.unsafe_charcode_at(i).reinterpret_as_uint()
    buf.data[j] = (c & 0xff).to_byte()
    buf.data[j + 1] = (c >> 8).to_byte()
  }
  buf.len += len * 2
}

///|
pub fn Buffer::write_string_utf16be(buf : Self, string : @string.View) -> Unit {
  let len = string.length()
  buf.grow_if_necessary(buf.len + len * 2)
  for i = 0, j = buf.len; i < len; i = i + 1, j = j + 2 {
    let c = string.unsafe_charcode_at(i).reinterpret_as_uint()
    buf.data[j + 1] = (c & 0xff).to_byte()
    buf.data[j] = (c >> 8).to_byte()
  }
  buf.len += len * 2
}

///|
/// Parameters:
///
/// * `self` : The buffer to write to.
/// * `str` : The source string from which the substring will be taken.
/// * `offset` : The starting position in the source string (inclusive). Must be
/// non-negative.
/// * `count` : The number of characters to write. Must be non-negative and
/// `offset + count` must not exceed the length of the source string.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_substring("Hello, World!", 0, 5)
///   inspect(
///     buf.contents(),
///     content=(
///       #|b"\x48\x00\x65\x00\x6c\x00\x6c\x00\x6f\x00"
///     ),
///   )
/// ```
pub impl Logger for Buffer with write_substring(
  self : Buffer,
  value : String,
  start : Int,
  len : Int,
) -> Unit {
  guard start >= 0 && len >= 0 && start + len <= value.length()
  self.grow_if_necessary(self.len + len * 2)
  self.data.blit_from_string(self.len, value, start, len)
  self.len += len * 2
}

///|
/// Writes a UTF-16LE encoded character into the buffer. Automatically grows the
/// buffer if necessary.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `char` : The character to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_char('A')
///   inspect(
///     buf.contents(), 
///     content=(
///       #|b"\x41\x00"
///     ),
///   )
/// ```
pub impl Logger for Buffer with write_char(self : Buffer, value : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.data.set_utf16le_char(self.len, value)
  self.len += inc
}

///|
/// Writes a single byte to the end of the buffer. The buffer will automatically
/// grow if necessary to accommodate the new byte.
///
/// Parameters:
///
/// * `buffer` : The buffer to write to.
/// * `byte` : The byte value to be written.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_byte(b'\x41')
///   inspect(buf.contents(), content="b\"\\x41\"")
/// ```
pub fn write_byte(self : Buffer, value : Byte) -> Unit {
  self.grow_if_necessary(self.len + 1)
  self.data[self.len] = value
  self.len += 1
}

///|
/// Writes bytes from an iterator to the buffer. 
///
/// Parameters:
///
/// * `self` : The buffer to write to.
/// * `iter` : An iterator yielding bytes to write.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   let bytes = b"Hello"
///   buf.write_iter(bytes.iter())
///   inspect(
///     buf.contents(), 
///     content=(
///       #|b"\x48\x65\x6c\x6c\x6f"
///     ),
///   )
/// ```
pub fn write_iter(self : Buffer, iter : Iter[Byte]) -> Unit {
  for byte in iter {
    self.write_byte(byte)
  }
}

///|
/// Resets the buffer to its initial state by restoring its initial capacity and
/// clearing its contents.
///
/// Parameters:
///
/// * `self` : The buffer to be reset.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new(size_hint=4)
///   buf.write_string("Test")
///   buf.reset()
///   inspect(buf.length(), content="0")
///   inspect(buf.is_empty(), content="true")
/// ```
pub fn reset(self : Buffer) -> Unit {
  self.data = self.initial_data
  self.len = 0
}

///|
/// Returns a copy of the buffer's contents as a `Bytes` object. The returned
/// bytes will have the same length as the buffer.
///
/// Parameters:
///
/// * `buffer` : The buffer whose contents will be converted to bytes.
///
/// Returns a `Bytes` object containing a copy of the buffer's contents.
///
/// Example:
///
/// ```moonbit
///   let buf = @buffer.new()
///   buf.write_string("Test")
///   let bytes = buf.to_bytes()
///   inspect(bytes.length(), content="8")
/// ```
pub fn to_bytes(self : Buffer) -> Bytes {
  @bytes.from_fixedarray(self.data, len=self.len)
}

///|
pub impl Show for Buffer with output(self, logger) {
  logger.write_string(self.contents().to_unchecked_string())
}
