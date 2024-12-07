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
/// Return a new string contains the data in buffer.
/// 
/// @alert deprecated "Use `Buffer::contents` to read the contents of the buffer"
pub fn to_string(self : T) -> String {
  self.contents().to_unchecked_string(offset=0, length=self.len)
}

///|
/// Return a new unchecked string contains the data in buffer.
/// Note this function does not validate the encoding of the byte sequence, 
/// it simply copy the bytes into a new String.
/// 
/// @alert deprecated "Use `Buffer::contents` to read the contents of the buffer"
pub fn to_unchecked_string(self : T) -> String {
  self.contents().to_unchecked_string(offset=0, length=self.len)
}

///|
/// Write a sub-string into buffer.
/// @alert deprecated "Use `Buffer::write_substring` instead"
pub fn write_sub_string(
  self : T,
  value : String,
  start : Int,
  len : Int
) -> Unit {
  self.write_substring(value, start, len)
}
