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

///|
/// Create byte sequence from String.
pub fn Bytes::of_string(str : String) -> Bytes {
  Bytes::new(str.length() * 2)..blit_from_string(0, str, 0, str.length())
}

///|
/// TODO: support local primitive declaration
fn unsafe_sub_string(
  bytes : Bytes,
  byte_offset : Int,
  byte_length : Int
) -> String = "$moonbit.unsafe_bytes_sub_string"

///|
/// Return a new unchecked string, containing the subsequence of `self` that
/// starts at `byte_offset` and has length `byte_length`.
/// 
/// @alert deprecated "Use `to_unchecked_string` instead"
pub fn sub_string(self : Bytes, byte_offset : Int, byte_length : Int) -> String {
  self.to_unchecked_string(offset=byte_offset, length=byte_length)
}

///|
/// Create a new unchecked string from byte sequence.
/// 
/// @alert deprecated "Use `to_unchecked_string` instead"
pub fn to_string(self : Bytes) -> String {
  self.to_unchecked_string(offset=0, length=self.length())
}

///|
/// Return an unchecked string, containing the subsequence of `self` that starts at 
/// `offset` and has length `length`. Both `offset` and `length` 
/// are indexed by byte.
/// 
/// Note this function does not validate the encoding of the byte sequence, 
/// it simply copy the bytes into a new String.
pub fn to_unchecked_string(
  self : Bytes,
  offset~ : Int = 0,
  length~ : Int = self.length() - offset
) -> String {
  let len = self.length()
  guard offset >= 0 && length >= 0 && offset + length <= len
  unsafe_sub_string(self, offset, length)
}

///|
/// Copy `length` chars from string `str`, starting at `str_offset`,
/// into byte sequence `self`, starting at `bytes_offset`.
pub fn blit_from_string(
  self : Bytes,
  bytes_offset : Int,
  str : String,
  str_offset : Int,
  length : Int
) -> Unit {
  let s1 = bytes_offset
  let s2 = str_offset
  let e1 = bytes_offset + length - 1
  let e2 = str_offset + length - 1
  let len1 = self.length()
  let len2 = str.length()
  guard length >= 0 && s1 >= 0 && e1 < len1 && s2 >= 0 && e2 < len2
  let end_str_offset = str_offset + length
  for i = str_offset, j = bytes_offset; i < end_str_offset; i = i + 1, j = j + 2 {
    let c = str[i].to_uint()
    self[j] = (c & 0xff).to_byte()
    self[j + 1] = (c >> 8).to_byte()
  }
}

///|
/// Copy `length` chars from string `str`, starting at `str_offset`,
/// into byte sequence `self`, starting at `bytes_offset`.
pub fn blit_from_string(
  self : FixedArray[Byte],
  bytes_offset : Int,
  str : String,
  str_offset : Int,
  length : Int
) -> Unit {
  let s1 = bytes_offset
  let s2 = str_offset
  let e1 = bytes_offset + length - 1
  let e2 = str_offset + length - 1
  let len1 = self.length()
  let len2 = str.length()
  guard length >= 0 && s1 >= 0 && e1 < len1 && s2 >= 0 && e2 < len2
  let end_str_offset = str_offset + length
  for i = str_offset, j = bytes_offset; i < end_str_offset; i = i + 1, j = j + 2 {
    let c = str[i].to_uint()
    self[j] = (c & 0xff).to_byte()
    self[j + 1] = (c >> 8).to_byte()
  }
}

///|
/// Copy `length` chars from byte sequence `src`, starting at `src_offset`,
/// into byte sequence `self`, starting at `bytes_offset`.
pub fn blit_from_bytes(
  self : FixedArray[Byte],
  bytes_offset : Int,
  src : Bytes,
  src_offset : Int,
  length : Int
) -> Unit {
  let s1 = bytes_offset
  let s2 = src_offset
  let e1 = bytes_offset + length - 1
  let e2 = src_offset + length - 1
  let len1 = self.length()
  let len2 = src.length()
  guard length >= 0 && s1 >= 0 && e1 < len1 && s2 >= 0 && e2 < len2
  let end_src_offset = src_offset + length
  for i = src_offset, j = bytes_offset; i < end_src_offset; i = i + 1, j = j + 1 {
    self[j] = src[i]
  }
}

///|
/// Return a new Bytes that contains the same byte sequence.
pub fn copy(self : Bytes) -> Bytes {
  Bytes::new(self.length())..blit(0, self, 0, self.length())
}

///|
/// Fill UTF8 encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
/// @alert deprecated "The type Bytes is about to be changed to be immutable. Use `FixedArray[Byte]` or `Buffer` instead."
pub fn set_utf8_char(self : Bytes, offset : Int, value : Char) -> Int {
  let code = value.to_uint()
  if code < 0x80 {
    self[offset] = ((code & 0x7F) | 0x00).to_byte()
    1
  } else if code < 0x0800 {
    self[offset] = (((code >> 6) & 0x1F) | 0xC0).to_byte()
    self[offset + 1] = ((code & 0x3F) | 0x80).to_byte()
    2
  } else if code < 0x010000 {
    self[offset] = (((code >> 12) & 0x0F) | 0xE0).to_byte()
    self[offset + 1] = (((code >> 6) & 0x3F) | 0x80).to_byte()
    self[offset + 2] = ((code & 0x3F) | 0x80).to_byte()
    3
  } else if code < 0x110000 {
    self[offset] = (((code >> 18) & 0x07) | 0xF0).to_byte()
    self[offset + 1] = (((code >> 12) & 0x3F) | 0x80).to_byte()
    self[offset + 2] = (((code >> 6) & 0x3F) | 0x80).to_byte()
    self[offset + 3] = ((code & 0x3F) | 0x80).to_byte()
    4
  } else {
    abort("Char out of range")
  }
}

///|
/// Fill UTF8 encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
pub fn set_utf8_char(
  self : FixedArray[Byte],
  offset : Int,
  value : Char
) -> Int {
  let code = value.to_uint()
  if code < 0x80 {
    self[offset] = ((code & 0x7F) | 0x00).to_byte()
    1
  } else if code < 0x0800 {
    self[offset] = (((code >> 6) & 0x1F) | 0xC0).to_byte()
    self[offset + 1] = ((code & 0x3F) | 0x80).to_byte()
    2
  } else if code < 0x010000 {
    self[offset] = (((code >> 12) & 0x0F) | 0xE0).to_byte()
    self[offset + 1] = (((code >> 6) & 0x3F) | 0x80).to_byte()
    self[offset + 2] = ((code & 0x3F) | 0x80).to_byte()
    3
  } else if code < 0x110000 {
    self[offset] = (((code >> 18) & 0x07) | 0xF0).to_byte()
    self[offset + 1] = (((code >> 12) & 0x3F) | 0x80).to_byte()
    self[offset + 2] = (((code >> 6) & 0x3F) | 0x80).to_byte()
    self[offset + 3] = ((code & 0x3F) | 0x80).to_byte()
    4
  } else {
    abort("Char out of range")
  }
}

///|
/// Fill UTF16 encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
/// @alert unsafe "Panic if the [value] is out of range"
pub fn set_utf16_char(self : Bytes, offset : Int, value : Char) -> Int {
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
/// Fill utf16 encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
/// @alert unsafe "Panic if the [value] is out of range"
/// @alert deprecated "Use `set_utf16le_char` instead"
pub fn set_utf16_char(
  self : FixedArray[Byte],
  offset : Int,
  value : Char
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
/// Fill UTF16LE encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
/// @alert unsafe "Panic if the [value] is out of range"
pub fn set_utf16le_char(
  self : FixedArray[Byte],
  offset : Int,
  value : Char
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
/// @alert unsafe "Panic if the [value] is out of range"
pub fn set_utf16be_char(
  self : FixedArray[Byte],
  offset : Int,
  value : Char
) -> Int {
  let code = value.to_uint()
  if code < 0x10000 {
    self[offset] = (code >> 0xFF).to_byte()
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
pub fn op_equal(self : Bytes, other : Bytes) -> Bool {
  if self.length() != other.length() {
    false
  } else {
    let len = self.length()
    for i = 0; i < len; i = i + 1 {
      if self[i] != other[i] {
        break false
      }
    } else {
      true
    }
  }
}
