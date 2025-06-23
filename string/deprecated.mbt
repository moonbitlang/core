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
pub fn String::concat(self : Array[String], separator~ : String = "") -> String {
  concat(self, separator~)
}

///|
type StringIndex Int derive(Show, Eq)

///|
#deprecated("StringIndex is deprecated, use String::index_of_nth_char instead")
#coverage.skip
pub fn index_at(
  self : String,
  offset_by : Int,
  start~ : StringIndex = 0
) -> StringIndex? {
  self.index_at_(offset_by, start~)
}

///|
#deprecated("StringIndex is deprecated, use String::index_of_nth_char instead")
#coverage.skip
pub fn index_at_rev(
  self : String,
  offset_by : Int,
  end? : StringIndex
) -> StringIndex? {
  self.index_at_rev_(offset_by, end?)
}

///|
fn index_at_(
  self : String,
  offset_by : Int,
  start~ : StringIndex = 0
) -> StringIndex? {
  if self.offset_of_nth_char(offset_by, start_offset=start.inner())
    is Some(index) {
    Some(index)
  } else if offset_by == self.char_length(start_offset=start.inner()) {
    Some(self.length())
  } else {
    None
  }
}

///|
fn index_at_rev_(
  self : String,
  offset_by : Int,
  end? : StringIndex
) -> StringIndex? {
  match end {
    Some(end) =>
      if offset_by == 0 {
        Some(end)
      } else if self.offset_of_nth_char(-offset_by, end_offset=end.inner())
        is Some(index) {
        Some(index)
      } else {
        None
      }
    None =>
      if offset_by == 0 {
        Some(self.length())
      } else if self.offset_of_nth_char(-offset_by) is Some(index) {
        Some(index)
      } else {
        None
      }
  }
}

///|
#deprecated("use str.charcodes(start = str.offset_of_nth_char(i).unwrap(), end = str.offset_of_nth_char(j).unwrap()) to replace str[i:j]")
#coverage.skip
pub fn String::op_as_view(self : String, start~ : Int = 0, end? : Int) -> View {
  let str_len = self.length()
  let start = if start >= 0 {
    self.index_at_(start, start=0).unwrap().inner()
  } else {
    self.index_at_rev_(-start, end=str_len).unwrap().inner()
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        self.index_at_(end, start=0).unwrap().inner()
      } else {
        self.index_at_rev_(-end, end=str_len).unwrap().inner()
      }
    None => str_len
  }
  guard start >= 0 && start <= end && end <= str_len else {
    abort("Invalid index for View")
  }
  { str: self, start, end }
}

///|
#deprecated("use view.charcodes(start = view.offset_of_nth_char(i).unwrap(), end = view.offset_of_nth_char(j).unwrap()) to replace view[i:j]")
#coverage.skip
pub fn View::op_as_view(self : View, start~ : Int = 0, end? : Int) -> View {
  let start = if start >= 0 {
    self.str.index_at_(start, start=self.start).unwrap().inner()
  } else {
    self.str.index_at_rev_(-start, end=self.end).unwrap().inner()
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        self.str.index_at_(end, start=self.start).unwrap().inner()
      } else {
        self.str.index_at_rev_(-end, end=self.end).unwrap().inner()
      }
    None => self.end
  }
  guard start >= self.start &&
    start <= self.end &&
    end >= self.start &&
    end <= self.end &&
    start <= end else {
    abort("Invalid index for View")
  }
  { str: self.str, start, end }
}

///|
#deprecated("Use `Array::join` instead.")
pub fn concat(strings : Array[String], separator~ : String = "") -> String {
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
pub fn index_of(self : String, str : String, from~ : Int = 0) -> Int {
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
/// Returns true if this string starts with a sub string.
#deprecated("Use `s.has_prefix(str)` instead.")
pub fn starts_with(self : String, str : String) -> Bool {
  self.has_prefix(str.view())
}

///|
/// Returns true if this string ends with a sub string.
#deprecated("Use `s.has_suffix(str)` instead.")
pub fn ends_with(self : String, str : String) -> Bool {
  self.has_suffix(str.view())
}

///| 
/// A `StringView` represents a view of a String that maintains proper Unicode
/// character boundaries. It allows safe access to a substring while handling 
/// multi-byte characters correctly.
#deprecated("use @string.View instead")
#builtin.valtype
struct StringView {
  // # Fields
  //
  // - `str`: The source String being viewed
  // - `start`: Starting UTF-16 code unit index into the string
  // - `end`: Ending UTF-16 code unit index into the string (not included)
  //
  // `len` is not included because it will make the operation of `op_as_view`
  // has complexity O(n) where n is the length of the code points in the view.
  str : String
  start : Int
  end : Int
}
