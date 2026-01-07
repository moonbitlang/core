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
/// Reinterpret the byte sequence as Bytes.
///
/// Notice that this will make the `Bytes` object to be a view of the original
/// byte sequence, so any modification to the original byte sequence will be
/// reflected in the `Bytes` object.
#internal(unsafe, "Creating mutable Bytes")
#doc(hidden)
pub fn FixedArray::unsafe_reinterpret_as_bytes(
  self : FixedArray[Byte],
) -> Bytes = "%identity"

///|
/// Creates a new byte sequence of the specified length, where each byte is
/// initialized using a function that maps indices to bytes.
///
/// Parameters:
///
/// * `length` : The length of the byte sequence to create. If `length` is less than or
/// equal to 0, returns an empty byte sequence.
/// * `value` : A function that takes an index (from 0 to `length - 1`) and
/// returns a byte for that position.
///
/// Returns a new byte sequence containing the bytes produced by applying the
/// value function to each index.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = Bytes::makei(3, i => (i + 65).to_byte())
///   assert_eq(bytes, b"ABC")
/// }
/// ```
pub fn Bytes::makei(length : Int, value : (Int) -> Byte raise?) -> Bytes raise? {
  if length <= 0 {
    return []
  }
  let arr = FixedArray::make(length, value(0))
  for i in 1..<length {
    arr[i] = value(i)
  }
  FixedArray::unsafe_reinterpret_as_bytes(arr)
}

///|
/// TODO: support local primitive declaration
#owned(bytes)
fn unsafe_sub_string(
  bytes : Bytes,
  byte_offset : Int,
  byte_length : Int,
) -> String = "$moonbit.unsafe_bytes_sub_string"

///|
/// Return an unchecked string, containing the subsequence of `self` that starts at
/// `offset` and has length `length`. Both `offset` and `length`
/// are indexed by byte.
///
/// Note this function does not validate the encoding of the byte sequence,
/// it simply copy the bytes into a new String.
pub fn Bytes::to_unchecked_string(
  self : Bytes,
  offset? : Int = 0,
  length? : Int,
) -> String {
  let len = self.length()
  let length = if length is Some(l) { l } else { len - offset }
  guard offset >= 0 && length >= 0 && offset + length <= len
  unsafe_sub_string(self, offset, length)
}

///|
/// Copies characters from a string to a byte sequence in UTF-16LE encoding. Each
/// character is converted into two bytes, with the lower byte stored first.
///
/// Parameters:
///
/// * `self` : The destination byte array to copy the characters into.
/// * `bytes_offset` : The starting position in the destination array where bytes
/// will be written.
/// * `str` : The source string containing the characters to copy.
/// * `str_offset` : The starting position in the source string from which
/// characters will be read.
/// * `length` : The number of characters to copy.
///
/// Throws a runtime error if:
///
/// * `length` is negative
/// * `bytes_offset` is negative
/// * `str_offset` is negative
/// * The range `[bytes_offset, bytes_offset + length * 2)` exceeds the length of
/// the destination array
/// * The range `[str_offset, str_offset + length)` exceeds the length of the
/// source string
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = FixedArray::make(6, b'\x00')
///   bytes.blit_from_string(0, "ABC", 0, 3)
///   @json.inspect(bytes, content=[65, 0, 66, 0, 67, 0]) // 'A'
///   bytes.blit_from_string(0, "你好啊", 0, 3)
///   @json.inspect(bytes, content=[96, 79, 125, 89, 74, 85]) // '你好啊'
///   bytes.blit_from_string(0, "😈", 0, 2)
///   @json.inspect(bytes, content=[61, 216, 8, 222, 74, 85]) // '😈'
/// }
/// ```
pub fn FixedArray::blit_from_string(
  self : FixedArray[Byte],
  bytes_offset : Int,
  str : String,
  str_offset : Int,
  length : Int,
) -> Unit {
  let s1 = bytes_offset
  let s2 = str_offset
  let e1 = bytes_offset + length * 2 - 1
  let e2 = str_offset + length - 1
  let len1 = self.length()
  let len2 = str.length()
  guard length >= 0 && s1 >= 0 && e1 < len1 && s2 >= 0 && e2 < len2
  let end_str_offset = str_offset + length
  for i = str_offset, j = bytes_offset; i < end_str_offset; i = i + 1, j = j + 2 {
    let c = str.unsafe_charcode_at(i).reinterpret_as_uint()
    self[j] = (c & 0xff).to_byte()
    self[j + 1] = (c >> 8).to_byte()
  }
}

///|
/// TODO: specific copy
fn unsafe_from_bytes(bytes : Bytes) -> FixedArray[Byte] = "%identity"

///|
/// Copy `length` chars from byte sequence `src`, starting at `src_offset`,
/// into byte sequence `self`, starting at `bytes_offset`.
pub fn FixedArray::blit_from_bytes(
  self : FixedArray[Byte],
  bytes_offset : Int,
  src : Bytes,
  src_offset : Int,
  length : Int,
) -> Unit {
  let s1 = bytes_offset
  let s2 = src_offset
  let e1 = bytes_offset + length - 1
  let e2 = src_offset + length - 1
  let len1 = self.length()
  let len2 = src.length()
  guard length >= 0 && s1 >= 0 && e1 < len1 && s2 >= 0 && e2 < len2
  FixedArray::unsafe_blit(
    self,
    bytes_offset,
    unsafe_from_bytes(src),
    src_offset,
    length,
  )
}

///|
/// Copy bytes from a BytesView into a fixed array of bytes.
///
/// Parameters:
///
/// * `self` : The destination fixed array of bytes.
/// * `bytes_offset` : The starting position in the destination array where bytes will be copied.
/// * `src` : The source View to copy from.
///
/// Throws a panic if:
/// * `bytes_offset` is negative
/// * The destination array is too small to hold all bytes from the source View
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = FixedArray::make(4, b'\x00')
///   let view = b"\x01\x02\x03"[1:]
///   arr.blit_from_bytesview(1, view)
///   inspect(arr, content="[b'\\x00', b'\\x02', b'\\x03', b'\\x00']")
/// }
/// ```
pub fn FixedArray::blit_from_bytesview(
  self : FixedArray[Byte],
  bytes_offset : Int,
  src : BytesView,
) -> Unit {
  FixedArray::blit_from_bytes(
    self,
    bytes_offset,
    src.bytes(),
    src.start(),
    src.len(),
  )
}

///|
/// Encodes a Unicode character into UTF-8 bytes and writes them into a fixed
/// array of bytes at the specified offset.
///
/// Parameters:
///
/// * `array` : The fixed array of bytes to write into.
/// * `offset` : The starting position in the array where the encoded bytes will
/// be written.
/// * `char` : The Unicode character to be encoded.
///
/// Returns the number of bytes written (1 to 4 bytes depending on the
/// character's code point).
///
/// Throws a panic if:
///
/// * The character's code point is greater than 0x10FFFF.
/// ```mbt check
/// test {
///   let buf = FixedArray::make(4, b'\x00')
///   let written = buf.set_utf8_char(0, '€') // Euro symbol (U+20AC)
///   inspect(written, content="3") // UTF-8 encoding takes 3 bytes
///   inspect(buf[0], content="b'\\xE2'")
///   inspect(buf[1], content="b'\\x82'")
///   inspect(buf[2], content="b'\\xAC'")
/// }
/// ```
pub fn FixedArray::set_utf8_char(
  self : FixedArray[Byte],
  offset : Int,
  value : Char,
) -> Int {
  let code = value.to_uint()
  match code {
    _..<0x80 => {
      self[offset] = ((code & 0x7F) | 0x00).to_byte()
      1
    }
    _..<0x0800 => {
      self[offset] = (((code >> 6) & 0x1F) | 0xC0).to_byte()
      self[offset + 1] = ((code & 0x3F) | 0x80).to_byte()
      2
    }
    _..<0x010000 => {
      self[offset] = (((code >> 12) & 0x0F) | 0xE0).to_byte()
      self[offset + 1] = (((code >> 6) & 0x3F) | 0x80).to_byte()
      self[offset + 2] = ((code & 0x3F) | 0x80).to_byte()
      3
    }
    _..<0x110000 => {
      self[offset] = (((code >> 18) & 0x07) | 0xF0).to_byte()
      self[offset + 1] = (((code >> 12) & 0x3F) | 0x80).to_byte()
      self[offset + 2] = (((code >> 6) & 0x3F) | 0x80).to_byte()
      self[offset + 3] = ((code & 0x3F) | 0x80).to_byte()
      4
    }
    _ => abort("Char out of range")
  }
}

///|
/// Fill UTF16LE encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
///
/// This function will panic if the `value` is out of range.
pub fn FixedArray::set_utf16le_char(
  self : FixedArray[Byte],
  offset : Int,
  value : Char,
) -> Int {
  let code = value.to_uint()
  if code < 0x10000 {
    self[offset] = (code & 0xFF).to_byte()
    self[offset + 1] = (code >> 8).to_byte()
    2
  } else if code < 0x110000 {
    let hi = code - 0x10000
    let lo = (hi >> 10) | 0xD800
    let hi = (hi & 0x3FF) | 0xDC00
    self[offset] = (lo & 0xFF).to_byte()
    self[offset + 1] = (lo >> 8).to_byte()
    self[offset + 2] = (hi & 0xFF).to_byte()
    self[offset + 3] = (hi >> 8).to_byte()
    4
  } else {
    abort("Char out of range")
  }
}

///|
/// Fill UTF16BE encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
///
/// This function will panic if the `value` is out of range.
pub fn FixedArray::set_utf16be_char(
  self : FixedArray[Byte],
  offset : Int,
  value : Char,
) -> Int {
  let code = value.to_uint()
  if code < 0x10000 {
    self[offset] = (code >> 8).to_byte()
    self[offset + 1] = (code & 0xFF).to_byte()
    2
  } else if code < 0x110000 {
    let hi = code - 0x10000
    let lo = (hi >> 10) | 0xD800
    let hi = (hi & 0x3FF) | 0xDC00
    self[offset] = (lo >> 8).to_byte()
    self[offset + 1] = (lo & 0xFF).to_byte()
    self[offset + 2] = (hi >> 8).to_byte()
    self[offset + 3] = (hi & 0xFF).to_byte()
    4
  } else {
    abort("Char out of range")
  }
}

///|
/// Compares two byte sequences for equality. Returns true only if both sequences
/// have the same length and contain identical bytes in the same order.
///
/// Parameters:
///
/// * `self` : The first byte sequence to compare.
/// * `other` : The second byte sequence to compare.
///
/// Returns `true` if the byte sequences are equal, `false` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes1 = b"\x01\x02\x03"
///   let bytes2 = b"\x01\x02\x03"
///   let bytes3 = b"\x01\x02\x04"
///   inspect(bytes1 == bytes2, content="true")
///   inspect(bytes1 == bytes3, content="false")
/// }
/// ```
pub impl Eq for Bytes with equal(self : Bytes, other : Bytes) -> Bool {
  if self.length() != other.length() {
    false
  } else {
    let len = self.length()
    for i in 0..<len {
      if self[i] != other[i] {
        break false
      }
    } else {
      true
    }
  }
}

///|
/// Compares two byte sequences based on shortlex order. First compares the lengths of
/// the sequences, then compares bytes pairwise until a difference is found or
/// all bytes have been compared.
///
/// Parameters:
///
/// * `self` : The first byte sequence to compare.
/// * `other` : The second byte sequence to compare.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```mbt check
/// test {
///   let a = b"\x01\x02\x03"
///   let b = b"\x01\x02\x04"
///   inspect(a.compare(b), content="-1") // a < b
///   inspect(b.compare(a), content="1") // b > a
///   inspect(a.compare(a), content="0") // a = a
///   let a = b"\x01\x02"
///   let b = b"\x01\x02\x03"
///   inspect(a.compare(b), content="-1") // shorter sequence is less
///   inspect(b.compare(a), content="1") // longer sequence is greater
/// }
/// ```
pub impl Compare for Bytes with compare(self, other) {
  let self_len = self.length()
  let other_len = other.length()
  let cmp = self_len.compare(other_len)
  if cmp != 0 {
    return cmp
  }
  for i in 0..<self_len {
    let b1 = self.unsafe_get(i)
    let b2 = other.unsafe_get(i)
    let cmp = b1.compare(b2)
    if cmp != 0 {
      break cmp
    }
  } else {
    0
  }
}

///|
/// Creates a new bytes sequence from a byte array.
///
/// Parameters:
///
/// * `array` : An array of bytes to be converted.
///
/// Returns a new bytes sequence containing the same bytes as the input array.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = [b'h', b'i']
///   let bytes = Bytes::from_array(arr)
///   inspect(
///     bytes,
///     content=(
///       #|b"hi"
///     ),
///   )
/// }
///
/// test {
///   let arr : FixedArray[Byte] = [b'h', b'e', b'l', b'l', b'o']
///   let bytes = Bytes::from_array(arr)
///   inspect(
///     bytes,
///     content=(
///       #|b"hello"
///     ),
///   )
/// }
/// ```
// TODO: marked as intrinsic, inline if it is constant
#alias(of, deprecated)
pub fn Bytes::from_array(arr : ArrayView[Byte]) -> Bytes {
  Bytes::makei(arr.length(), i => arr[i])
}

///|
/// Creates a new bytes sequence from a fixed-size array of bytes with an
/// optional length parameter.
///
/// Parameters:
///
/// * `array` : A fixed-size array of bytes to be converted into a bytes
/// sequence.
/// * `length` : (Optional) The length of the resulting bytes sequence. If not
/// provided, uses the full length of the input array.
///
/// Returns a new bytes sequence containing the bytes from the input array. If a
/// length is specified, only includes up to that many bytes.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr : FixedArray[Byte] = [b'h', b'e', b'l', b'l', b'o']
///   let bytes = Bytes::from_array(arr[0:3])
///   inspect(
///     bytes,
///     content=(
///       #|b"hel"
///     ),
///   )
/// }
/// ```
/// 
/// Panics if the length is invalid
#deprecated("Use Bytes::from_array instead")
pub fn Bytes::from_fixedarray(arr : FixedArray[Byte], len? : Int) -> Bytes {
  let len = match len {
    None => arr.length()
    Some(x) => {
      guard 0 <= x && x <= arr.length()
      x
    }
  }
  let result = unsafe_to_fixedarray(UninitializedArray::make(len))
  arr.blit_to(result, len~)
  result.unsafe_reinterpret_as_bytes()
}

///|
/// Converts a bytes sequence into a fixed-size array of bytes. If an optional
/// length is provided, the resulting array will have exactly that length,
/// otherwise it will match the length of the input bytes.
///
/// Parameters:
///
/// * `self` : The bytes sequence to convert.
/// * `len` : Optional. The desired length of the output array. If specified, the
/// resulting array will have this length. If not specified, the length of the
/// input bytes sequence will be used.
///
/// Returns a fixed-size array containing the bytes from the input sequence.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = b"hello"
///   let arr = bytes.to_fixedarray()
///   inspect(arr, content="[b'\\x68', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
///   let arr2 = bytes[:3].to_fixedarray()
///   inspect(arr2, content="[b'\\x68', b'\\x65', b'\\x6C']")
/// }
/// ```
/// 
/// Panics if the length is invalid
#label_migration(len, fill=false)
pub fn Bytes::to_fixedarray(self : Bytes, len? : Int) -> FixedArray[Byte] {
  let len = match len {
    None => self.length()
    Some(x) => {
      guard 0 <= x && x <= self.length()
      x
    }
  }
  let arr = unsafe_to_fixedarray(UninitializedArray::make(len))
  arr.blit_from_bytes(0, self, 0, len)
  arr
}

///|
pub fn BytesView::to_fixedarray(self : BytesView) -> FixedArray[Byte] {
  let len = self.length()
  let arr = unsafe_to_fixedarray(UninitializedArray::make(len))
  arr.blit_from_bytes(0, self.data(), self.start_offset(), len)
  arr
}

///|
/// Creates a new bytes sequence from an iterator of bytes.
///
/// Parameters:
///
/// * `iterator` : An iterator that yields bytes.
///
/// Returns a new bytes sequence containing all the bytes from the iterator.
///
/// Example:
///
/// ```mbt check
/// test {
///   let iter = Iter::singleton(b'h')
///   let bytes = Bytes::from_iter(iter)
///   inspect(
///     bytes,
///     content=(
///       #|b"h"
///     ),
///   )
/// }
/// ```
#alias(from_iterator, deprecated)
pub fn Bytes::from_iter(iter : Iter[Byte]) -> Bytes {
  Bytes::from_array(iter.collect())
}

///|
/// Converts a bytes sequence into an array of bytes.
///
/// Parameters:
///
/// * `bytes` : A sequence of bytes to be converted into an array.
///
/// Returns an array containing the same bytes as the input sequence.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = b"hello"
///   let arr = bytes.to_array()
///   inspect(arr, content="[b'\\x68', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
/// }
/// ```
pub fn Bytes::to_array(self : Bytes) -> Array[Byte] {
  let len = self.length()
  let rv = Array::make(len, b'0')
  for i in 0..<len {
    rv[i] = self[i]
  }
  rv
}

///|
pub fn BytesView::to_array(self : BytesView) -> Array[Byte] {
  let len = self.length()
  let rv = Array::make(len, b'0')
  for i in 0..<len {
    rv[i] = self[i]
  }
  rv
}

///|
/// Creates an iterator over the bytes in the sequence.
///
/// Parameters:
///
/// * `bytes` : A byte sequence to iterate over.
///
/// Returns an iterator that yields each byte in the sequence in order.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = Bytes::from_array([b'h', b'i'])
///   let mut sum = 0
///   bytes.iter().each(b => sum = sum + b.to_int())
///   inspect(sum, content="209") // ASCII values: 'h'(104) + 'i'(105) = 209
/// }
/// ```
#alias(iterator, deprecated)
pub fn Bytes::iter(self : Bytes) -> Iter[Byte] {
  let mut i = 0
  let len = self.length()
  Iter::new(fn() {
    guard i < len else { None }
    let c = self.unsafe_get(i)
    i += 1
    Some(c)
  })
}

///|
/// Creates an iterator that yields tuples of index and byte,
/// indices start from 0.
/// 
/// Example:
///
/// ```mbt check
/// test {
///   let buf = StringBuilder::new(size_hint=5)
///   let keys = []
///   let it = b"abcde".iter2()
///   while it.next() is Some((i, x)) {
///     buf.write_string(x.to_string())
///     keys.push(i)
///   }
///   inspect(buf, content="b'\\x61'b'\\x62'b'\\x63'b'\\x64'b'\\x65'")
///   inspect(keys, content="[0, 1, 2, 3, 4]")
/// }
/// ```
#alias(iterator2, deprecated)
pub fn Bytes::iter2(self : Bytes) -> Iter2[Int, Byte] {
  let mut i = 0
  let len = self.length()
  Iter::new(fn() {
    guard i < len else { None }
    let result = (i, self.unsafe_get(i))
    i += 1
    Some(result)
  })
}

///|
/// Creates a new empty bytes sequence.
///
/// Returns an empty bytes sequence.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = Bytes::default()
///   inspect(bytes, content="b\"\"")
///   inspect(bytes.length(), content="0")
/// }
/// ```
pub impl Default for Bytes with default() {
  b""
}

///|
/// Retrieves a byte from the view at the specified index.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte.
///
/// Returns the byte at the specified index, or None if the index is out of bounds.
///
/// Example:
/// 
/// ```mbt check
/// test {
///   let bytes = b"\x01\x02\x03"
///   let byte = bytes.get(1)
///   inspect(byte, content="Some(b'\\x02')")
///   let bytes = b"\x01\x02\x03"
///   let byte = bytes.get(3)
///   inspect(byte, content="None")
/// }
/// ```
pub fn Bytes::get(self : Bytes, index : Int) -> Byte? {
  guard index >= 0 && index < self.length() else { None }
  Some(self[index])
}

///|
fn unsafe_to_fixedarray(array : UninitializedArray[Byte]) -> FixedArray[Byte] = "%identity"

///|
/// Concatenates two bytes sequences.
///
/// Parameters:
///
/// * `self` : The first bytes sequence.
/// * `other` : The second bytes sequence.
/// TODO: marked as intrinsic, inline if it is constant
pub impl Add for Bytes with add(self : Bytes, other : Bytes) -> Bytes {
  let len_self = self.length()
  let len_other = other.length()
  let rv : FixedArray[Byte] = FixedArray::make(len_self + len_other, 0)
  for i in 0..<len_self {
    rv[i] = self[i]
  }
  for i in 0..<len_other {
    rv[len_self + i] = other[i]
  }
  unsafe_to_bytes(rv)
}

///|
pub impl Hash for Bytes with hash_combine(self, hasher) {
  hasher.combine(self[:])
}

///|
/// Returns a new `Bytes` consisting of `self` repeated `count` times.
///
/// If `count <= 0` or `self` is empty, an empty `Bytes` is returned. When
/// `count == 1`, `self` is returned directly without allocation.
///
/// This implementation performs a single allocation sized exactly to the
/// result and fills it using an exponential copy (doubling) strategy so the
/// number of blit operations is O(log count).
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(
///     b"ab".repeat(3),
///     content=(
///       #|b"ababab"
///     ),
///   )
///   inspect(
///     b"xyz".repeat(0),
///     content=(
///       #|b""
///     ),
///   )
/// }
/// ```
pub fn Bytes::repeat(self : Self, count : Int) -> Bytes {
  if count <= 0 || self.length() == 0 {
    return []
  }
  if count == 1 {
    return self
  }
  let len = self.length()
  let total = len * count
  // (Optional) detect overflow: if multiplication wrapped (best-effort)
  guard total / count == len
  let arr = FixedArray::make(total, (0 : Byte))
  arr.blit_from_bytes(0, self, 0, len)
  let mut filled = len
  while filled < total {
    let remaining = total - filled
    let copy_len = if filled < remaining { filled } else { remaining }
    let src = unsafe_to_bytes(arr)
    arr.blit_from_bytes(filled, src, 0, copy_len)
    filled = filled + copy_len
  }
  unsafe_to_bytes(arr)
}
