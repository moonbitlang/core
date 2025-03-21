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
pub fn index_at(
  self : String,
  offset_by : Int,
  start~ : StringIndex = 0
) -> StringIndex? {
  self.index_at_(offset_by, start~)
}

///|
#deprecated("StringIndex is deprecated, use String::index_of_nth_char instead")
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
  if self.offset_of_nth_char(offset_by, start_offset=start._) is Some(index) {
    Some(index)
  } else if offset_by == self.codepoint_length(start_offset=start._) {
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
      } else if self.offset_of_nth_char(-offset_by, end_offset=end._)
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
#deprecated("use str.view(start = str.index_of_nth_char(i).unwrap(), end = str.index_of_nth_char(j).unwrap()) to replace str[i:j]")
pub fn String::op_as_view(self : String, start~ : Int = 0, end? : Int) -> View {
  let str_len = self.length()
  let start = if start >= 0 {
    index_at_(self, start, start=0).unwrap()._
  } else {
    index_at_rev_(self, -start, end=str_len).unwrap()._
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        index_at_(self, end, start=0).unwrap()._
      } else {
        index_at_rev_(self, -end, end=str_len).unwrap()._
      }
    None => str_len
  }
  guard start >= 0 && start <= end && end <= str_len else {
    abort("Invalid index for View")
  }
  { str: self, start, end }
}

///|
#deprecated("use view.view(start = view.index_of_nth_char(i).unwrap(), end = view.index_of_nth_char(j).unwrap()) to replace view[i:j]")
pub fn View::op_as_view(self : View, start~ : Int = 0, end? : Int) -> View {
  let start = if start >= 0 {
    index_at_(self.str, start, start=self.start).unwrap()._
  } else {
    index_at_rev_(self.str, -start, end=self.end).unwrap()._
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        index_at_(self.str, end, start=self.start).unwrap()._
      } else {
        index_at_rev_(self.str, -end, end=self.end).unwrap()._
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
#deprecated("use View::char_length instead")
pub fn View::length(self : View) -> Int {
  self.char_length()
}

///|
#deprecated("use View::char_length_eq instead")
pub fn length_eq(self : View, len : Int) -> Bool {
  self.char_length_eq(len)
}

///|
#deprecated("use View::char_length_ge instead")
pub fn length_ge(self : View, len : Int) -> Bool {
  self.char_length_ge(len)
}

///|
/// Returns the character at the given index from the end of the string.
///
/// # Examples
///
/// ```moonbit
/// let s = "Hello🤣🤣🤣"
/// inspect!(s.rev_get(0), content="🤣")
/// inspect!(s.rev_get(4), content="l")
/// ```
///
/// # Panics
///
/// @alert unsafe "Panics if the index is out of bounds."
#deprecated("use String::rev_iter().nth(index).unwrap() instead")
pub fn String::rev_get(self : String, index : Int) -> Char {
  guard index >= 0
  self.nth_char(-index - 1)
}

///|
/// Test if the length of the string is equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
#deprecated("use String::char_length_eq instead")
pub fn String::length_eq(self : String, len : Int) -> Bool {
  self.char_length_eq(len)
}

///|
/// Test if the length of the string is greater than or equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
#deprecated("use String::char_length_ge instead")
pub fn String::length_ge(self : String, len : Int) -> Bool {
  self.char_length_ge(len)
}

///|
/// Return the character at the given index.
/// 
/// The time complexity is O(n) where n is the given index, as it needs to scan
/// through the UTF-16 code units to find the nth Unicode character.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// let view = str[1:6]
/// inspect!(view[0], content="e")
/// inspect!(view[4], content="🤣")
/// ```
#deprecated("use View::iter().nth(index).unwrap() instead")
pub fn View::op_get(self : View, index : Int) -> Char {
  guard index >= 0
  self.str.nth_char(index, start_offset=self.start, end_offset=self.end)
}

///|
/// Returns the character at the given index from the end of the view.
/// 
/// The time complexity is O(n) where n is the given index, as it needs to scan
/// through the UTF-16 code units to find the nth Unicode character.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// let view = str[1:6]
/// inspect!(view.rev_get(0), content="🤣")
/// inspect!(view.rev_get(4), content="e")
/// ```
#deprecated("use View::rev_iter().nth(index).unwrap() instead")
pub fn rev_get(self : View, index : Int) -> Char {
  guard index >= 0
  self.str.nth_char(-index - 1, start_offset=self.start, end_offset=self.end)
}

///|
fn String::nth_char(
  self : String,
  i : Int,
  start_offset~ : Int = 0,
  end_offset~ : Int = self.length()
) -> Char {
  if self.offset_of_nth_char(i, start_offset~, end_offset~) is Some(index) {
    self.unsafe_char_at(index)
  } else {
    abort("index out of bounds")
  }
}
