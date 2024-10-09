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

struct StringBuilder {
  mut bytes : Bytes
  mut len : Int
}

pub fn StringBuilder::new(~size_hint : Int = 0) -> StringBuilder {
  let initial = if size_hint < 1 { 1 } else { size_hint }
  let bytes = Bytes::new(initial)
  { bytes, len: 0 }
}

fn StringBuilder::grow_if_necessary(
  self : StringBuilder,
  required : Int
) -> Unit {
  // TODO: get rid of mut
  let mut enough_space = self.bytes.length()
  if enough_space <= 0 {
    enough_space = 1
  }
  // double the enough_space until it larger than required
  while enough_space < required {
    enough_space = enough_space * 2
  }
  if enough_space != self.bytes.length() {
    self.bytes = Bytes::new(enough_space)..blit(0, self.bytes, 0, self.len)
  }
}

pub fn StringBuilder::write_string(self : StringBuilder, str : String) -> Unit {
  self.grow_if_necessary(self.len + str.length() * 2)
  self.bytes.blit_from_string(self.len, str, 0, str.length())
  self.len += str.length() * 2
}

pub fn StringBuilder::write_char(self : StringBuilder, ch : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.bytes.set_utf16_char(self.len, ch)
  self.len += inc
}

pub fn StringBuilder::write_sub_string(
  self : StringBuilder,
  str : String,
  start : Int,
  len : Int
) -> Unit {
  guard start >= 0 && len >= 0 && start + len <= str.length()
  self.grow_if_necessary(self.len + len * 2)
  self.bytes.blit_from_string(self.len, str, start, len)
  self.len += len * 2
}

pub fn StringBuilder::to_string(self : StringBuilder) -> String {
  self.bytes.sub_string(0, self.len)
}
