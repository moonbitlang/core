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
struct StringBuilder {
  mut data : FixedArray[Byte]
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
pub fn StringBuilder::new(size_hint~ : Int = 0) -> StringBuilder {
  let initial = if size_hint < 1 { 1 } else { size_hint }
  let data : FixedArray[Byte] = FixedArray::make(initial, 0)
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
  required : Int
) -> Unit {
  let current_len = self.data.length()
  if required <= current_len {
    return
  }
  // current_len is at least 1
  let mut enough_space = current_len
  // double the enough_space until it larger than required
  while enough_space < required {
    enough_space = enough_space * 2
  }
  self.data = FixedArray::make(enough_space, Byte::default())..unsafe_blit(
    0,
    self.data,
    0,
    self.len,
  )
}

///|
/// Writes a string to the StringBuilder.
pub impl Logger for StringBuilder with write_string(self, str) {
  self.grow_if_necessary(self.len + str.length() * 2)
  self.data.blit_from_string(self.len, str, 0, str.length())
  self.len += str.length() * 2
}

///|
/// Writes a character to the StringBuilder.
pub impl Logger for StringBuilder with write_char(self, ch) {
  self.grow_if_necessary(self.len + 4)
  let inc = self.data.set_utf16le_char(self.len, ch)
  self.len += inc
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
/// ```moonbit
/// test "write_substring" {
///   let sb = StringBuilder::new()
///   sb.write_substring("Hello, world!", 0, 5)
///   assert_eq!(sb.to_string(), "Hello")
/// }
/// ```
pub impl Logger for StringBuilder with write_substring(
  self : StringBuilder,
  str : String,
  start : Int,
  len : Int
) -> Unit {
  guard start >= 0 && len >= 0 && start + len <= str.length()
  self.grow_if_necessary(self.len + len * 2)
  self.data.blit_from_string(self.len, str, start, len)
  self.len += len * 2
}

///| 
/// Returns the current content of the StringBuilder as a string.
pub fn StringBuilder::to_string(self : StringBuilder) -> String {
  self.data.unsafe_to_bytes().to_unchecked_string(offset=0, length=self.len)
}

///|
/// TODO: improve perf
pub impl Show for StringBuilder with output(self, logger) {
  logger.write_string(
    self.data.unsafe_to_bytes().to_unchecked_string(offset=0, length=self.len),
  )
}

///| 
/// Resets the string builder to an empty state.
pub fn StringBuilder::reset(self : StringBuilder) -> Unit {
  self.len = 0
}
