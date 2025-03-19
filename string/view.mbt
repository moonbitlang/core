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
/// alert deprecated "use @string.View instead"
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
/// A `@string.View` represents a view of a String that maintains proper Unicode
/// character boundaries. It allows safe access to a substring while handling 
/// multi-byte characters correctly.
pub typealias View = StringView

///|
fn len(self : View) -> Int {
  self.end - self.start
}

///|
/// Creates a `View` into a `String`.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// let view1 = str.view()
/// inspect!(view1, content=
///  "Hello🤣🤣🤣"
///)
/// let start = str.index_of_nth_char(1).unwrap()
/// let end = str.index_of_nth_char(6).unwrap() // the second emoji
/// let view2 = str.view(start~, end~)
/// inspect!(view2, content=
///  "ello🤣"
///)
/// ```
pub fn String::view(
  self : String,
  start~ : Int = 0,
  end~ : Int = self.length()
) -> View {
  guard start >= 0 && start <= end && end <= self.length() else {
    abort("Invalid index for View")
  }
  { str: self, start, end }
}

///|
/// Creates a new `View` from an existing `View`.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// let start = str.index_of_nth_char(1).unwrap()
/// let end = str.index_of_nth_char(7).unwrap() // the third emoji in str
/// let view = str.view(start~, end~)
/// inspect!(view, content=
///   "ello🤣🤣"
/// )
/// let start = view.index_of_nth_char(1).unwrap()
/// let end = view.index_of_nth_char(5).unwrap() // the second emoji in view
/// let view2 = view.view(start~, end~)
/// inspect!(view2, content=
///   "llo🤣"
/// )
/// ```
pub fn View::view(
  self : View,
  start~ : Int = 0,
  end~ : Int = self.len()
) -> View {
  guard start >= 0 && start <= end && end <= self.len() else {
    abort("Invalid index for View")
  }
  { str: self.str, start: self.start + start, end: self.start + end }
}

///|
/// Returns the UTF-16 index of the i-th (zero-indexed) Unicode character of
/// the view. If i is negative, it returns the index of the (n + i)-th character
/// where n is the total number of Unicode characters in the view.
pub fn View::index_of_nth_char(self : View, i : Int) -> Int? {
  if self.str.index_of_nth_char(i, start=self.start, end=self.end)
    is Some(index) {
    Some(index - self.start)
  } else {
    None
  }
}

///|
pub fn View::codepoint_at(self : View, index : Int) -> Char {
  guard index >= 0 && index < self.len() else { abort("Index out of bounds") }
  self.str.unsafe_codepoint_at(self.start + index)
}

///|
pub fn View::charcode_at(self : View, index : Int) -> Int {
  guard index >= 0 && index < self.len() else { abort("Index out of bounds") }
  self.str.unsafe_charcode_at(self.start + index)
}

///| 
/// Returns the number of Unicode characters in this view.
/// 
/// Note this has O(n) complexity where n is the length of the code points in 
/// the view.
pub fn View::codepoint_length(self : View) -> Int {
  self.str.codepoint_length(start=self.start, end=self.end)
}

///|
/// Test if the length of the view is equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn length_eq(self : View, len : Int) -> Bool {
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
pub fn length_ge(self : View, len : Int) -> Bool {
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
pub fn View::op_get(self : View, index : Int) -> Char {
  guard index >= 0 else {
    abort("Index out of bounds: cannot access negative index")
  }
  let mut utf16_offset = self.start
  let mut char_count = 0
  let code_unit_length = self.str.length()
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
/// inspect!(view.rev_get(0), content="🤣")
/// inspect!(view.rev_get(4), content="e")
/// ```
pub fn rev_get(self : View, index : Int) -> Char {
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
pub impl Show for View with output(self, logger) {
  let substr = self.str.substring(start=self.start, end=self.end)
  String::output(substr, logger)
}

///|
/// Returns a new String containing a copy of the characters in this view.
/// 
/// # Examples
/// 
/// ```
/// let str = "Hello World"
/// let view = str[0:5]  // "Hello"
/// inspect!(view.to_string(), content="Hello")
/// ```
pub impl Show for StringView with to_string(self) {
  self.str.substring(start=self.start, end=self.end)
}

///|
/// Returns an iterator over the Unicode characters in the string view.
pub fn View::iter(self : View) -> Iter[Char] {
  Iter::new(fn(yield_) {
    for index = self.start; index < self.end; index = index + 1 {
      let c1 = self.str.unsafe_charcode_at(index)
      if is_leading_surrogate(c1) && index + 1 < self.end {
        let c2 = self.str.unsafe_charcode_at(index + 1)
        if is_trailing_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index + 2
        }
      }
      guard yield_(Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}
