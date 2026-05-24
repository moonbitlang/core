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
/// * `size_hint` : An optional initial capacity hint for the internal buffer,
/// in UTF-16 code units. Defaults to 8. Use 0 to request an empty initial
/// buffer. `size_hint` may be ignored on some platforms, JS for example.
///
/// Returns a new `StringBuilder` instance.
///
#alias(new)
pub fn StringBuilder::StringBuilder(size_hint? : Int = 8) -> StringBuilder {
  guard size_hint >= 0 else { abort("size_hint must be non-negative") }
  let data : FixedArray[UInt16] = FixedArray::make(size_hint, 0)
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
  // Double the capacity until it can hold the required length.
  let initial = current_len.max(1)
  let enough_space = for enough_space = initial; enough_space < required; {
    continue enough_space * 2
  } nobreak {
    enough_space
  }
  let new_data = FixedArray::make(enough_space, UInt16::default())
  new_data.unsafe_blit(0, self.data, 0, self.len)
  self.data = new_data
}

///|
fn FixedArray::unsafe_blit_from_string(
  self : FixedArray[UInt16],
  dst_offset : Int,
  str : String,
  str_offset : Int,
  len : Int,
) -> Unit {
  let end_str_offset = str_offset + len
  for i = str_offset, j = dst_offset; i < end_str_offset; i = i + 1, j = j + 1 {
    self[j] = str.unsafe_get(i)
  }
}

///|
/// Writes a string to the StringBuilder.
pub impl Logger for StringBuilder with fn write_string(self, str) {
  let str_len = str.length()
  self.grow_if_necessary(self.len + str_len)
  self.data.unsafe_blit_from_string(self.len, str, 0, str_len)
  self.len += str_len
}

///|
/// Writes a character to the StringBuilder.
pub impl Logger for StringBuilder with fn write_char(self, ch) {
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
///   let sb = StringBuilder()
///   sb.write_view("Hello, world!"[:5])
///   assert_eq(sb.to_string(), "Hello")
/// }
/// ```
pub impl Logger for StringBuilder with fn write_view(
  self : StringBuilder,
  str : StringView,
) -> Unit {
  let str_len = str.length()
  self.grow_if_necessary(self.len + str_len)
  self.data.unsafe_blit_from_string(
    self.len,
    str.data(),
    str.start_offset(),
    str_len,
  )
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
#doc(hidden)
pub fn StringBuilder::write_end(self : StringBuilder) -> String {
  self.to_string()
}

///|
pub impl Show for StringBuilder with fn to_string(self) {
  StringBuilder::to_string(self)
}

///|
/// Resets the string builder to an empty state.
pub fn StringBuilder::reset(self : StringBuilder) -> Unit {
  self.data = FixedArray::make(self.data.length(), UInt16::default())
  self.len = 0
}
