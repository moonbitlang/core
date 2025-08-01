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
/// Reinterpret the byte sequence as Bytes.
///
/// Notice that this will make the `Bytes` object to be a view of the original
/// byte sequence, so any modification to the original byte sequence will be
/// reflected in the `Bytes` object.
#internal(unsafe, "Creating mutable Bytes")
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
/// ```moonbit
///   let bytes = Bytes::makei(3, (i) => { (i + 65).to_byte() })
///   assert_eq(bytes, b"ABC")
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
  offset~ : Int = 0,
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
/// ```moonbit
///   let bytes = FixedArray::make(6, b'\x00')
///   bytes.blit_from_string(0, "ABC", 0, 3)
///   @json.inspect(bytes, content=[65,0,66,0,67,0]) // 'A'
///   bytes.blit_from_string(0, "你好啊", 0, 3)
///   @json.inspect(bytes, content=[96,79,125,89,74,85]) // '你好啊'
///   bytes.blit_from_string(0, "😈", 0, 2)
///   @json.inspect(bytes, content=[61,216,8,222,74,85]) // '😈'
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
/// ```moonbit
///   let buf = FixedArray::make(4, b'\x00')
///   let written = buf.set_utf8_char(0, '€') // Euro symbol (U+20AC)
///   inspect(written, content="3") // UTF-8 encoding takes 3 bytes
///   inspect(buf[0], content="b'\\xE2'")
///   inspect(buf[1], content="b'\\x82'")
///   inspect(buf[2], content="b'\\xAC'")
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
/// ```moonbit
///   let bytes1 = b"\x01\x02\x03"
///   let bytes2 = b"\x01\x02\x03"
///   let bytes3 = b"\x01\x02\x04"
///   inspect(bytes1 == bytes2, content="true")
///   inspect(bytes1 == bytes3, content="false")
/// ```
pub impl Eq for Bytes with op_equal(self : Bytes, other : Bytes) -> Bool {
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
/// Compares two byte sequences lexicographically. First compares the lengths of
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
/// ```moonbit
///   let a = b"\x01\x02\x03"
///   let b = b"\x01\x02\x04"
///   inspect(a.compare(b), content="-1") // a < b
///   inspect(b.compare(a), content="1") // b > a
///   inspect(a.compare(a), content="0") // a = a
///
///   let a = b"\x01\x02"
///   let b = b"\x01\x02\x03"
///   inspect(a.compare(b), content="-1") // shorter sequence is less
///   inspect(b.compare(a), content="1") // longer sequence is greater
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
