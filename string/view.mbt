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
/// let start_offset = str.offset_of_nth_char(1).unwrap()
/// let end_offset = str.offset_of_nth_char(6).unwrap() // the second emoji
/// let view2 = str.view(start_offset~, end_offset~)
/// inspect!(view2, content=
///  "ello🤣"
///)
/// ```
pub fn String::view(
  self : String,
  start_offset~ : Int = 0,
  end_offset~ : Int = self.length()
) -> View {
  guard start_offset >= 0 &&
    start_offset <= end_offset &&
    end_offset <= self.length() else {
    abort("Invalid index for View")
  }
  { str: self, start: start_offset, end: end_offset }
}

///|
/// Returns the UTF-16 index of the i-th (zero-indexed) Unicode character of
/// the view. If i is negative, it returns the index of the (n + i)-th character
/// where n is the total number of Unicode characters in the view.
pub fn View::offset_of_nth_char(self : View, i : Int) -> Int? {
  if self.str.offset_of_nth_char(
      i,
      start_offset=self.start,
      end_offset=self.end,
    )
    is Some(index) {
    Some(index - self.start)
  } else {
    None
  }
}

///|
pub fn View::char_at(self : View, index : Int) -> Char {
  guard index >= 0 && index < self.len() else { abort("Index out of bounds") }
  self.str.unsafe_char_at(self.start + index)
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
pub fn View::char_length(self : View) -> Int {
  self.str.char_length(start_offset=self.start, end_offset=self.end)
}

///|
/// Test if the length of the view is equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn View::char_length_eq(self : View, len : Int) -> Bool {
  self.str.char_length_eq(len, start_offset=self.start, end_offset=self.end)
}

///|
/// Test if the length of the view is greater than or equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn View::char_length_ge(self : View, len : Int) -> Bool {
  self.str.char_length_ge(len, start_offset=self.start, end_offset=self.end)
}

///|
pub impl Show for View with output(self, logger) {
  self.str.unsafe_output_substring(logger, start=self.start, end=self.end)
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
    for index in self.start..<self.end {
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

///|
/// Returns an iterator over the Unicode characters in the string view in reverse order.
pub fn View::rev_iter(self : View) -> Iter[Char] {
  Iter::new(fn(yield_) {
    for index = self.end - 1; index >= self.start; index = index - 1 {
      let c1 = self.str.unsafe_charcode_at(index)
      if is_trailing_surrogate(c1) && index - 1 >= 0 {
        let c2 = self.str.unsafe_charcode_at(index - 1)
        if is_leading_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c2, c1)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index - 2
        }
      }
      guard yield_(Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}
