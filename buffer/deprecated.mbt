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
/// Return a new string contains the data in buffer.
///
/// @alert deprecated "Use `Buffer::contents` to read the contents of the buffer"
/// @coverage.skip
pub fn to_string(self : T) -> String {
  self.contents().to_unchecked_string(offset=0, length=self.len)
}

///|
/// Return a new unchecked string contains the data in buffer.
/// Note this function does not validate the encoding of the byte sequence,
/// it simply copy the bytes into a new String.
///
/// @alert deprecated "Use `Buffer::contents` to read the contents of the buffer"
/// @coverage.skip
pub fn to_unchecked_string(self : T) -> String {
  self.contents().to_unchecked_string(offset=0, length=self.len)
}

///|
/// Write a substring from a given string into the buffer. This is a deprecated
/// function, use `write_substring` instead.
///
/// Parameters:
///
/// * `self` : The buffer to write into.
/// * `string` : The source string from which to extract the substring.
/// * `offset` : The starting position in the source string (inclusive).
/// * `length` : The number of characters to write from the starting position.
///
/// @alert deprecated "Use `Buffer::write_substring` instead"
/// @coverage.skip
pub fn write_sub_string(
  self : T,
  value : String,
  start : Int,
  len : Int
) -> Unit {
  self.write_substring(value, start, len)
}
