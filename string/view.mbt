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
/// A `StringView` represents a view of a String that maintains proper Unicode
/// character boundaries. It allows safe access to a substring while handling 
/// multi-byte characters correctly.
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

///|
/// A `StringIndex` represents an unicode-aware position within a string.
///
/// This type is intentionally opaque - it is recommended to use the 
/// `str.index_at(offset_by: Int) -> StringIndex` method to construct a 
/// `StringIndex`.
type StringIndex Int derive(Show, Eq)

///|
/// Returns a `StringIndex` representing the position after skipping `offset_by` 
/// Unicode characters. If the string has `n` Unicode characters, the returned 
/// index will be `Some` if `0 <= offset_by <= n`, otherwise `None`.
///
/// # Examples
/// 
/// ```
/// let str = "🤣🤣🤣"
/// guard let Some(offset) = str.index_at(1)                // Skip 1 character
/// inspect!(offset, content="StringIndex(2)")              // Points to second emoji
/// 
/// guard let Some(offset) = str.index_at(start=offset, 1)  // Skip 2 characters
/// inspect!(offset, content="StringIndex(4)")              // Points to third emoji
///
/// let offset = str.index_at(4)                            // Skip 4 characters
/// inspect!(offset, content="None")                        // Beyond end of string
/// ```
pub fn index_at(
  self : String,
  offset_by : Int,
  start~ : StringIndex = 0
) -> StringIndex? {
  let str_len = self.length()
  let mut utf16_offset = start._
  let mut char_count = 0
  while utf16_offset < str_len && char_count < offset_by {
    let c1 = self[utf16_offset]
    // check if this is a surrogate pair
    if is_leading_surrogate(c1) && utf16_offset + 1 < str_len {
      let c2 = self[utf16_offset + 1]
      if is_trailing_surrogate(c2) {
        utf16_offset = utf16_offset + 2
        char_count = char_count + 1
        continue
      } else {
        abort("invalid surrogate pair")
      }
    }
    // single utf-16 code unit
    utf16_offset = utf16_offset + 1
    char_count = char_count + 1
  }
  // Return None if:
  // 1. We couldn't reach the requested character offset
  // 2. The resulting offset is beyond the end of the string
  if char_count < offset_by || utf16_offset > str_len {
    None
  } else {
    Some(utf16_offset)
  }
}

///| 
/// Returns the number of Unicode characters in this view.
/// 
/// Note this has O(n) complexity where n is the length of the code points in 
/// the view.
pub fn length(self : StringView) -> Int {
  let mut len = 0
  for index = self.start; index < self.end; index = index + 1 {
    let c1 = self.str[index]
    if is_leading_surrogate(c1) && index + 1 < self.end {
      let c2 = self.str[index + 1]
      if is_trailing_surrogate(c2) {
        len = len + 1
        continue index + 2
      } else {
        abort("invalid surrogate pair")
      }
    }
    len = len + 1
  }
  len
}

///|
/// Creates a `StringView` into a `String`.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// guard let Some(start) = str.index_at(1)
/// guard let Some(end) = str.index_at(6)
/// let view = str[start:end]
/// inspect!(view, content=
///  #|"ello🤣"
///)
/// ```
pub fn op_as_view(
  self : String,
  start~ : StringIndex = 0,
  end? : StringIndex
) -> StringView {
  let str_len = self.length()
  let start = start._
  let end = match end {
    Some(e) => e._
    None => str_len
  }
  guard start >= 0 && start <= end && end <= str_len else {
    abort("Invalid index for StringView")
  }
  { str: self, start, end }
}

///|
/// Creates a new `StringView` from an existing `StringView`.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// guard let Some(start) = str.index_at(1)
/// guard let Some(end) = str.index_at(7)
/// let view = str[start:end]
/// let view2 = view[1:5]
/// inspect!(view2, content=
///   #|"llo🤣"
/// )
/// ```
pub fn op_as_view(
  self : StringView,
  start~ : Int = 0,
  end? : Int
) -> StringView {
  match end {
    Some(end) => {
      guard start <= end else { abort("Invalid index for StringView") }
      guard let Some(start) = index_at(self.str, start, start=self.start)
      // TODO: provide index_at_rev or index_at2 to avoid repeatedly iterate the string
      guard let Some(end) = index_at(self.str, end, start=self.start)
      guard start._ <= self.end && end._ <= self.end else {
        abort("Invalid index for StringView")
      }
      { str: self.str, start: start._, end: end._ }
    }
    None => {
      guard let Some(start) = index_at(self.str, start, start=self.start)
      guard start._ <= self.end else { abort("Invalid index for StringView") }
      { str: self.str, start: start._, end: self.end }
    }
  }
}

///|
/// Return the character at the given index.
/// 
/// This method has O(n) complexity.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// guard let Some(start) = str.index_at(1)
/// guard let Some(end) = str.index_at(6)
/// let view = str[start:end]
/// inspect!(view[0], content="'e'")
/// inspect!(view[4], content="'🤣'")
/// ```
pub fn op_get(self : StringView, index : Int) -> Char {
  guard index >= 0 else {
    abort("Index out of bounds: cannot access negative index")
  }
  let mut utf16_offset = self.start
  let mut char_count = 0
  while char_count < index && utf16_offset < self.end {
    let c1 = self.str[utf16_offset]
    if is_leading_surrogate(c1) && utf16_offset + 1 < self.str.length() {
      let c2 = self.str[utf16_offset + 1]
      if is_trailing_surrogate(c2) {
        utf16_offset = utf16_offset + 2
        char_count = char_count + 1
        continue
      } else {
        abort("invalid surrogate pair")
      }
    }
    utf16_offset = utf16_offset + 1
    char_count = char_count + 1
  }
  guard char_count == index && utf16_offset < self.end else {
    abort("Index out of bounds: cannot access index \{index}")
  }
  let c1 = self.str[utf16_offset]
  if is_leading_surrogate(c1) {
    let c2 = self.str[utf16_offset + 1]
    if is_trailing_surrogate(c2) {
      code_point_of_surrogate_pair(c1, c2)
    } else {
      abort("invalid surrogate pair")
    }
  } else {
    c1
  }
}

///|
pub impl Show for StringView with output(self, logger) {
  let substr = self.str.substring(start=self.start, end=self.end)
  String::output(substr, logger)
}
