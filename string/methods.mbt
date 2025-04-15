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
/// Returns the offset (charcode index) of the first occurrence of the given
/// substring. If the substring is not found, it returns None.
pub fn View::find(self : View, str : View) -> Int? {
  let len = self.len()
  let sub_len = str.len()
  // Handle empty substring case
  guard sub_len > 0 else { return Some(0) }
  // If substring is longer than string, it can't be found
  guard sub_len <= len else { return None }
  let max_idx = len - sub_len
  let first = str.unsafe_charcode_at(0)
  let mut i = 0
  while i <= max_idx {
    // find first character
    while i < len && self.unsafe_charcode_at(i) != first {
      i += 1
    }
    // check the rest
    if i <= max_idx {
      for j in 1..<sub_len {
        if self.unsafe_charcode_at(i + j) != str.unsafe_charcode_at(j) {
          break
        }
      } else {
        // the substring is found
        return Some(i)
      }
    }
    i += 1
  }
  None
}

///|
/// Returns the offset of the first occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn String::find(self : String, str : View) -> Int? {
  self.view().find(str)
}

///|
test "find" {
  // todo: remove .view() when new version is released
  inspect!("hello".find("o".view()), content="Some(4)")
  inspect!("hello".find("l".view()), content="Some(2)")
  inspect!("hello".find("hello".view()), content="Some(0)")
  inspect!("hello".find("h".view()), content="Some(0)")
  inspect!("hello".find("".view()), content="Some(0)")
  inspect!("hello".find("world".view()), content="None")
  inspect!("".find("".view()), content="Some(0)")
  inspect!("".find("a".view()), content="None")
  inspect!("hello hello".find("hello".view()), content="Some(0)")
  inspect!("aaa".find("aa".view()), content="Some(0)")
  inspect!("😀😀".find("😀".view()), content="Some(0)")
}

///|
/// Returns the offset of the last occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn View::rev_find(self : View, str : View) -> Int? {
  let len = self.len()
  let sub_len = str.len()
  guard sub_len > 0 else { return Some(len) }
  guard sub_len <= len else { return None }
  let min_idx = sub_len - 1
  let last = str.unsafe_charcode_at(sub_len - 1)
  let mut i = len - 1
  while i >= min_idx {
    while i >= 0 && self.unsafe_charcode_at(i) != last {
      i -= 1
    }
    if i >= min_idx {
      for j in 1..<sub_len {
        if self.unsafe_charcode_at(i - j) !=
          str.unsafe_charcode_at(sub_len - 1 - j) {
          break
        }
      } else {
        return Some(i - sub_len + 1)
      }
    }
    i -= 1
  }
  None
}

///|
/// Returns the offset (charcode index) of the last occurrence of the given
/// substring. If the substring is not found, it returns None.
pub fn String::rev_find(self : String, str : View) -> Int? {
  self.view().rev_find(str)
}

///|
test "rev_find" {
  // todo: remove .view() when new version is released
  inspect!("hello".rev_find("o".view()), content="Some(4)")
  inspect!("hello".rev_find("l".view()), content="Some(3)")
  inspect!("hello".rev_find("hello".view()), content="Some(0)")
  inspect!("hello".rev_find("h".view()), content="Some(0)")
  inspect!("hello".rev_find("".view()), content="Some(5)")
  inspect!("hello".rev_find("world".view()), content="None")
  inspect!("".rev_find("".view()), content="Some(0)")
  inspect!("".rev_find("a".view()), content="None")
  inspect!("hello hello".rev_find("hello".view()), content="Some(6)")
  inspect!("aaa".rev_find("aa".view()), content="Some(1)")
  inspect!("😀😀".rev_find("😀".view()), content="Some(2)")
}

///| 
/// Returns true if the given substring is suffix of this string.
pub fn View::has_suffix(self : View, str : View) -> Bool {
  self.rev_find(str) is Some(i) && i == self.len() - str.len()
}

///|
/// Returns true if the given substring is suffix of this string.
pub fn String::has_suffix(self : String, str : View) -> Bool {
  self.view().has_suffix(str)
}

///|
test "has_suffix" {
  // todo: remove .view() when new version is released
  inspect!("hello".has_suffix("lo".view()), content="true")
  inspect!("hello".has_suffix("hello".view()), content="true")
  inspect!("hello".has_suffix("".view()), content="true")
  inspect!("hello".has_suffix("world".view()), content="false")
  inspect!("hello".has_suffix("hel".view()), content="false")
  inspect!("".has_suffix("".view()), content="true")
  inspect!("".has_suffix("a".view()), content="false")
  inspect!("hello world".has_suffix("world".view()), content="true")
  inspect!("😀😀".has_suffix("😀".view()), content="true")
  inspect!("😀😀".has_suffix("😀😀".view()), content="true")
}

///|
/// Returns true if this string starts with the given substring.
pub fn View::has_prefix(self : View, str : View) -> Bool {
  self.find(str) is Some(i) && i == 0
}

///|
/// Returns true if this string starts with the given substring.
pub fn String::has_prefix(self : String, str : View) -> Bool {
  self.view().has_prefix(str)
}

///|
test "has_prefix" {
  // todo: remove .view() when new version is released
  inspect!("hello".has_prefix("h".view()), content="true")
  inspect!("hello".has_prefix("he".view()), content="true")
  inspect!("hello".has_prefix("".view()), content="true")
  inspect!("hello".has_prefix("world".view()), content="false")
  inspect!("hello".has_prefix("lo".view()), content="false")
  inspect!("".has_prefix("".view()), content="true")
  inspect!("".has_prefix("a".view()), content="false")
  inspect!("😀hello".has_prefix("😀".view()), content="true")
  inspect!("😀😃hello".has_prefix("😀😃".view()), content="true")
  inspect!("😀hello".has_prefix("😃".view()), content="false")
  inspect!("hello😀".has_prefix("😀".view()), content="false")
}
