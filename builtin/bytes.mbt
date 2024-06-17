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

fn unsafe_sub_string(
  self : Bytes,
  byte_offset : Int,
  byte_length : Int
) -> String = "$moonbit.unsafe_bytes_sub_string"

/// Create a new String from byte sequence.
pub fn to_string(self : Bytes) -> String {
  self.sub_string(0, self.length())
}

/// Create byte sequence from String.
pub fn Bytes::of_string(str : String) -> Bytes {
  let bytes = Bytes::make(str.length() * 2)
  bytes.blit_from_string(0, str, 0, str.length())
  bytes
}

/// Return a new String, containing the subsequence of `self` that
/// starts at `byte_offset` and has length `byte_length`.
pub fn sub_string(self : Bytes, byte_offset : Int, byte_length : Int) -> String {
  if byte_length < 0 || byte_offset < 0 || byte_offset + byte_length > self.length() {
    abort("sub_string out of bound")
  } else {
    unsafe_sub_string(self, byte_offset, byte_length)
  }
}

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
  if length < 0 || s1 < 0 || e1 >= len1 || s2 < 0 || e2 >= len2 {
    abort("blit_from_string out of bounds")
  } else {
    let end_str_offset = str_offset + length
    for i = str_offset, j = bytes_offset
        i < end_str_offset
        i = i + 1, j = j + 2 {
      let c = str[i].to_int()
      self[j] = c.land(0xff).to_byte()
      self[j + 1] = c.lsr(8).to_byte()
    }
  }
}

/// Return a new Bytes that contains the same byte sequence.
pub fn copy(self : Bytes) -> Bytes {
  let dst = Bytes::make(self.length())
  blit(dst, 0, self, 0, self.length())
  dst
}

/// Fill utf8 encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
pub fn set_utf8_char(self : Bytes, offset : Int, value : Char) -> Int {
  let code = value.to_int()
  if code < 0x80 {
    self[offset] = code.land(0x7F).lor(0x00).to_byte()
    1
  } else if code < 0x0800 {
    self[offset] = code.lsr(6).land(0x1F).lor(0xC0).to_byte()
    self[offset + 1] = code.land(0x3F).lor(0x80).to_byte()
    2
  } else if code < 0x010000 {
    self[offset] = code.lsr(12).land(0x0F).lor(0xE0).to_byte()
    self[offset + 1] = code.lsr(6).land(0x3F).lor(0x80).to_byte()
    self[offset + 2] = code.land(0x3F).lor(0x80).to_byte()
    3
  } else if code < 0x110000 {
    self[offset] = code.lsr(18).land(0x07).lor(0xF0).to_byte()
    self[offset + 1] = code.lsr(12).land(0x3F).lor(0x80).to_byte()
    self[offset + 2] = code.lsr(6).land(0x3F).lor(0x80).to_byte()
    self[offset + 3] = code.land(0x3F).lor(0x80).to_byte()
    4
  } else {
    abort("Char out of range")
  }
}

/// Fill utf16 encoded char `value` into byte sequence `self`, starting at `offset`.
/// It return the length of bytes has been written.
pub fn set_utf16_char(self : Bytes, offset : Int, value : Char) -> Int {
  let code = value.to_int()
  if code < 0x10000 {
    self[offset] = code.land(0xFF).to_byte()
    self[offset + 1] = code.lsr(8).to_byte()
    2
  } else {
    let hi = code - 0x10000
    let lo = hi.lsr(10).lor(0xD800)
    let hi = hi.land(0x3FF).lor(0xDC00)
    self[offset] = lo.land(0xFF).to_byte()
    self[offset + 1] = lo.lsr(8).to_byte()
    self[offset + 2] = hi.land(0xFF).to_byte()
    self[offset + 3] = hi.lsr(8).to_byte()
    4
  }
}
