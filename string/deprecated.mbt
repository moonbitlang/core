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
#deprecated("Use `@string.concat` instead")
pub fn String::concat(self : Array[String], separator? : String = "") -> String {
  concat(self, separator~)
}

///|
#deprecated("Use `Array::join` instead.")
pub fn concat(strings : Array[String], separator? : String = "") -> String {
  match strings {
    [] => ""
    [hd, .. tl] => {
      let mut size_hint = hd.length()
      for s in tl {
        size_hint += s.length() + separator.length()
      }
      size_hint = size_hint << 1
      let buf = StringBuilder::new(size_hint~)
      buf.write_string(hd)
      if separator == "" {
        for s in tl {
          buf.write_string(s)
        }
      } else {
        for s in tl {
          buf.write_string(separator)
          buf.write_string(s)
        }
      }
      buf.to_string()
    }
  }
}

///|
#deprecated("Use `s.find(substr)` instead. If the optional argument `from` is not 0, take view from the string first. Please do not use an invalid `from` argument.")
pub fn index_of(self : String, str : String, from? : Int = 0) -> Int {
  if from <= 0 {
    if self.find(str.view()) is Some(idx) {
      idx
    } else {
      -1
    }
  } else if from > self.length() {
    if str.length() == 0 {
      self.length()
    } else {
      -1
    }
  } else if self.view(start_offset=from).find(str.view()) is Some(idx) {
    idx + from
  } else {
    -1
  }
}

///|
/// Returns the last index of the sub string.
#deprecated("Use `s.rev_find(substr)` instead. If the optional argument `from` is not 0, take view from the string first. Please do not use an invalid `from` argument.")
pub fn last_index_of(self : String, str : String, from? : Int) -> Int {
  let from = if from is Some(f) { f } else { self.length() }
  if from >= self.length() {
    if self.rev_find(str.view()) is Some(idx) {
      idx
    } else {
      -1
    }
  } else if from < 0 {
    if str.length() == 0 {
      self.length()
    } else {
      -1
    }
  } else if self.view(end_offset=from).rev_find(str.view()) is Some(idx) {
    idx
  } else {
    -1
  }
}

///|
/// Returns the charcode(code unit) at the given index.
/// 
/// This method has O(1) complexity.
#deprecated("Use `s[i]` instead")
pub fn View::charcode_at(self : View, index : Int) -> Int {
  guard index >= 0 && index < self.length() else {
    abort("Index out of bounds")
  }
  self.str().unsafe_charcode_at(self.start() + index)
}

///|
#deprecated("Use `s.get_char(i).unwrap()` instead")
pub fn View::char_at(self : View, index : Int) -> Char {
  self.get_char(index).unwrap()
}

///|
#deprecated("Use `s.get_char(i).unwrap()` instead")
pub fn String::char_at(self : String, offset : Int) -> Char {
  match self.get_char(offset) {
    Some(c) => c
    None => '�'
  }
}
