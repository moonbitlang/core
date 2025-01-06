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
struct StringBuilder {
  mut data : FixedArray[Byte]
  mut len : Int
}

///|
pub fn StringBuilder::new(size_hint~ : Int = 0) -> StringBuilder {
  let initial = if size_hint < 1 { 1 } else { size_hint }
  let data = FixedArray::make(initial, Byte::default())
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
pub fn StringBuilder::write_string(self : StringBuilder, str : String) -> Unit {
  self.grow_if_necessary(self.len + str.length() * 2)
  self.data.blit_from_string(self.len, str, 0, str.length())
  self.len += str.length() * 2
}

///|
pub fn StringBuilder::write_char(self : StringBuilder, ch : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.data.set_utf16le_char(self.len, ch)
  self.len += inc
}

///|
pub fn StringBuilder::write_substring(
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
pub fn reset(self : StringBuilder) -> Unit {
  self.len = 0
}
