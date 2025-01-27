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
  let str_len = self.charcode_length()
  guard start._ >= 0 && start._ <= str_len else { abort("Invalid start index") }
  let mut utf16_offset = start._
  let mut char_count = 0
  while utf16_offset < str_len && char_count < offset_by {
    let c1 = self.unsafe_charcode_at(utf16_offset)
    // check if this is a surrogate pair
    if is_leading_surrogate(c1) && utf16_offset + 1 < str_len {
      let c2 = self.unsafe_charcode_at(utf16_offset + 1)
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
/// Returns a `StringIndex` representing the position before skipping `offset_by` 
/// Unicode characters from the end of the string.
/// 
/// # Example
/// 
/// ```
/// let str = "🤣🤣🤣"
/// guard let Some(offset) = str.index_at_rev(0)
/// inspect!(offset, content="StringIndex(6)")
/// guard let Some(offset) = str.index_at_rev(1)
/// inspect!(offset, content="StringIndex(4)")
/// guard let Some(offset) = str.index_at_rev(2, end = offset)
/// inspect!(offset, content="StringIndex(0)")
/// let offset = str.index_at_rev(4)
/// inspect!(offset, content="None")
/// ```
pub fn index_at_rev(
  self : String,
  offset_by : Int,
  end? : StringIndex
) -> StringIndex? {
  let str_len = self.charcode_length()
  let end = match end {
    None => str_len
    Some(end) => {
      guard end._ >= 0 && end._ <= str_len else { abort("Invalid end index") }
      end._
    }
  }
  let mut utf16_offset = end
  let mut char_count = 0
  // Iterating backwards from the end of the string. [utf16_offset] always 
  // points to the last skipped character.
  while utf16_offset > 0 && char_count < offset_by {
    let c1 = self.unsafe_charcode_at(utf16_offset - 1)
    if is_trailing_surrogate(c1) && utf16_offset - 2 >= 0 {
      let c2 = self.unsafe_charcode_at(utf16_offset - 2)
      if is_leading_surrogate(c2) {
        utf16_offset = utf16_offset - 2
        char_count = char_count + 1
        continue
      }
    }
    utf16_offset = utf16_offset - 1
    char_count = char_count + 1
  }
  if char_count < offset_by || utf16_offset < 0 {
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
pub fn StringView::length(self : StringView) -> Int {
  let mut len = 0
  for index = self.start; index < self.end; index = index + 1 {
    let c1 = self.str.unsafe_charcode_at(index)
    if is_leading_surrogate(c1) && index + 1 < self.end {
      let c2 = self.str.unsafe_charcode_at(index + 1)
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
/// Test if the length of the view is equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn length_eq(self : StringView, len : Int) -> Bool {
  for index = self.start, self_len = 0
      index < self.end && self_len < len
      index = index + 1, self_len = self_len + 1 {
    let c1 = self.str.unsafe_charcode_at(index)
    if is_leading_surrogate(c1) && index + 1 < self.end {
      let c2 = self.str.unsafe_charcode_at(index + 1)
      if is_trailing_surrogate(c2) {
        continue index + 2, self_len + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    self_len == len && index == self.end
  }
}

///|
/// Test if the length of the view is greater than or equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn length_ge(self : StringView, len : Int) -> Bool {
  for index = self.start, self_len = 0
      index < self.end && self_len < len
      index = index + 1, self_len = self_len + 1 {
    let c1 = self.str.unsafe_charcode_at(index)
    if is_leading_surrogate(c1) && index + 1 < self.end {
      let c2 = self.str.unsafe_charcode_at(index + 1)
      if is_trailing_surrogate(c2) {
        continue index + 2, self_len + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    self_len >= len
  }
}

///|
/// Creates a `StringView` into a `String`.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// let view = str[1:6]
/// inspect!(view, content=
///  #|"ello🤣"
///)
/// ```
pub fn String::op_as_view(
  self : String,
  start~ : Int = 0,
  end? : Int
) -> StringView {
  let str_len = self.charcode_length()
  let start = if start >= 0 {
    guard let Some(start_offset) = index_at(self, start, start=0) else {
      _ => abort("Invalid start index")
    }
    start_offset._
  } else {
    guard let Some(start_offset) = index_at_rev(self, -start, end=str_len) else {
      _ => abort("Invalid start index")
    }
    start_offset._
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        guard let Some(end_offset) = index_at(self, end, start=0) else {
          _ => abort("Invalid end index")
        }
        end_offset._
      } else {
        guard let Some(end_offset) = index_at_rev(self, -end, end=str_len) else {
          _ => abort("Invalid end index")
        }
        end_offset._
      }
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
/// let view = str[1:7]
/// let view2 = view[1:5]
/// inspect!(view2, content=
///   #|"llo🤣"
/// )
/// ```
pub fn StringView::op_as_view(
  self : StringView,
  start~ : Int = 0,
  end? : Int
) -> StringView {
  let start = if start >= 0 {
    guard let Some(start_offset) = index_at(self.str, start, start=self.start) else {
      _ => abort("Invalid start index")
    }
    start_offset._
  } else {
    guard let Some(start_offset) = index_at_rev(self.str, -start, end=self.end) else {
      _ => abort("Invalid start index")
    }
    start_offset._
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        guard let Some(end_offset) = index_at(self.str, end, start=self.start) else {
          _ => abort("Invalid end index")
        }
        end_offset._
      } else {
        guard let Some(end_offset) = index_at_rev(self.str, -end, end=self.end) else {
          _ => abort("Invalid end index")
        }
        end_offset._
      }
    None => self.end
  }
  guard start >= self.start &&
    start <= self.end &&
    end >= self.start &&
    end <= self.end &&
    start <= end else {
    abort("Invalid index for StringView")
  }
  { str: self.str, start, end }
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
/// inspect!(view[0], content="'e'")
/// inspect!(view[4], content="'🤣'")
/// ```
pub fn StringView::op_get(self : StringView, index : Int) -> Char {
  guard index >= 0 else {
    abort("Index out of bounds: cannot access negative index")
  }
  let mut utf16_offset = self.start
  let mut char_count = 0
  let code_unit_length = self.str.charcode_length()
  while char_count < index && utf16_offset < self.end {
    let c1 = self.str.unsafe_charcode_at(utf16_offset)
    if is_leading_surrogate(c1) && utf16_offset + 1 < code_unit_length {
      let c2 = self.str.unsafe_charcode_at(utf16_offset + 1)
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
  let c1 = self.str.unsafe_charcode_at(utf16_offset)
  if is_leading_surrogate(c1) {
    let c2 = self.str.unsafe_charcode_at(utf16_offset + 1)
    if is_trailing_surrogate(c2) {
      code_point_of_surrogate_pair(c1, c2)
    } else {
      abort("invalid surrogate pair")
    }
  } else {
    Char::from_int(c1)
  }
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
/// inspect!(view.rev_get(0), content="'🤣'")
/// inspect!(view.rev_get(4), content="'e'")
/// ```
pub fn rev_get(self : StringView, index : Int) -> Char {
  guard index >= 0 else {
    abort("Index out of bounds: cannot access negative index")
  }
  let mut utf16_offset = self.end - 1
  let mut char_count = 0
  while char_count < index && utf16_offset >= self.start {
    let c1 = self.str.unsafe_charcode_at(utf16_offset)
    if is_trailing_surrogate(c1) && utf16_offset - 1 >= self.start {
      let c2 = self.str.unsafe_charcode_at(utf16_offset - 1)
      if is_leading_surrogate(c2) {
        utf16_offset = utf16_offset - 2
        char_count = char_count + 1
        continue
      } else {
        abort("invalid surrogate pair")
      }
    }
    utf16_offset = utf16_offset - 1
    char_count = char_count + 1
  }
  guard char_count == index && utf16_offset >= self.start else {
    abort("Index out of bounds: cannot access index \{index} in reverse")
  }
  let c1 = self.str.unsafe_charcode_at(utf16_offset)
  if is_trailing_surrogate(c1) {
    let c2 = self.str.unsafe_charcode_at(utf16_offset - 1)
    if is_leading_surrogate(c2) {
      code_point_of_surrogate_pair(c2, c1)
    } else {
      abort("invalid surrogate pair")
    }
  } else {
    Char::from_int(c1)
  }
}

///|
pub impl Show for StringView with output(self, logger) {
  let substr = self.str.substring(start=self.start, end=self.end)
  String::output(substr, logger)
}

///|
/// Returns an iterator over the Unicode characters in the string view.
pub fn StringView::iter(self : StringView) -> Iter[Char] {
  Iter::new(fn(yield_) {
    for index = self.start; index < self.end; index = index + 1 {
      let c1 = self.str.unsafe_charcode_at(index)
      if is_leading_surrogate(c1) && index + 1 < self.end {
        let c2 = self.str.unsafe_charcode_at(index + 1)
        if is_trailing_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard let IterContinue = yield_(c) else { x => break x }
          continue index + 2
        }
      }
      guard let IterContinue = yield_(Char::from_int(c1)) else { x => break x }

    } else {
      IterContinue
    }
  })
}
