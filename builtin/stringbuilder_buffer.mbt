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
struct StringBuilder {
  mut data : FixedArray[UInt16]
  mut len : Int
}

///|
/// Creates a new string builder with an optional initial capacity hint.
///
/// Parameters:
///
/// * `size_hint` : An optional initial capacity hint for the internal buffer. If
/// less than 1, a minimum capacity of 1 is used. Defaults to 0. It is the size of bytes, 
/// not the size of characters. `size_hint` may be ignored on some platforms, JS for example.
///
/// Returns a new `StringBuilder` instance with the specified initial capacity.
///
pub fn StringBuilder::new(size_hint? : Int = 0) -> StringBuilder {
  let initial = if size_hint < 1 { 1 } else { (size_hint + 1) / 2 }
  let data : FixedArray[UInt16] = FixedArray::make(initial, 0)
  { data, len: 0 }
}

///|
/// Return whether the given buffer is empty.
pub fn StringBuilder::is_empty(self : StringBuilder) -> Bool {
  self.len == 0
}

///|
fn StringBuilder::grow_if_necessary(
  self : StringBuilder,
  required : Int,
) -> Unit {
  let current_len = self.data.length()
  if required <= current_len {
    return
  }
  // current_len is at least 1
  // double the enough_space until it larger than required
  let enough_space = for enough_space = current_len; enough_space < required; {
    continue enough_space * 2
  } nobreak {
    enough_space
  }
  let new_data = FixedArray::make(enough_space, UInt16::default())
  new_data.unsafe_blit(0, self.data, 0, self.len)
  self.data = new_data
}

///|
/// Writes a string to the StringBuilder.
pub impl Logger for StringBuilder with write_string(self, str) {
  let str_len = str.length()
  self.grow_if_necessary(self.len + str_len)
  // TODO: add an intrinsic to copy UTF-16 code units from String directly.
  for i in 0..<str_len {
    self.data[self.len + i] = str.unsafe_get(i)
  }
  self.len += str_len
}

///|
/// Writes a character to the StringBuilder.
pub impl Logger for StringBuilder with write_char(self, ch) {
  let code = ch.to_uint()
  if code <= 0xFFFFU {
    self.grow_if_necessary(self.len + 1)
    self.data[self.len] = code.to_uint16()
    self.len += 1
  } else if code <= 0x10FFFFU {
    self.grow_if_necessary(self.len + 2)
    let code = code - 0x10000U
    self.data[self.len] = (0xD800U + (code >> 10)).to_uint16()
    self.data[self.len + 1] = (0xDC00U + code.land(0x3FFU)).to_uint16()
    self.len += 2
  } else {
    abort("invalid code point")
  }
}

///|
/// Writes a part of the given string to the StringBuilder.
/// 
/// Parameters:
///
/// * `self` : The StringBuilder to write to.
/// * `str` : The given string.
/// * `start` : The start index of the substring to write.
/// * `len` : The length of the substring to write.
///
/// Example:
///
/// ```mbt check
/// test {
///   let sb = StringBuilder::new()
///   sb.write_view("Hello, world!"[:5])
///   assert_eq(sb.to_string(), "Hello")
/// }
/// ```
pub impl Logger for StringBuilder with write_view(
  self : StringBuilder,
  str : StringView,
) -> Unit {
  let str_len = str.length()
  self.grow_if_necessary(self.len + str_len)
  // TODO: add an intrinsic to copy UTF-16 code units from StringView directly.
  for i in 0..<str_len {
    self.data[self.len + i] = str.unsafe_get(i)
  }
  self.len += str_len
}

///|
/// Returns the current content of the StringBuilder as a string.
pub fn StringBuilder::to_string(self : StringBuilder) -> String {
  if self.len == self.data.length() {
    unsafe_fixedarray_uint16_to_string(self.data)
  } else {
    let data = FixedArray::make(self.len, UInt16::default())
    data.unsafe_blit(0, self.data, 0, self.len)
    unsafe_fixedarray_uint16_to_string(data)
  }
}

///|
/// TODO: improve perf
pub impl Show for StringBuilder with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Resets the string builder to an empty state.
pub fn StringBuilder::reset(self : StringBuilder) -> Unit {
  self.len = 0
}
