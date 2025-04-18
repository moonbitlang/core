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
/// Returns a new view of the view with the given start and end offsets.
pub fn View::view(
  self : View,
  start_offset~ : Int = 0,
  end_offset~ : Int = self.len()
) -> View {
  guard start_offset >= 0 &&
    start_offset <= end_offset &&
    end_offset <= self.len() else {
    abort("Invalid index for View")
  }
  {
    str: self.str,
    start: self.start + start_offset,
    end: self.start + end_offset,
  }
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
/// Returns the Unicode character at the given index.
/// 
/// This method has O(n) complexity.
pub fn View::char_at(self : View, index : Int) -> Char {
  guard index >= 0 && index < self.len() else { abort("Index out of bounds") }
  self.str.unsafe_char_at(self.start + index)
}

///|
/// Returns the charcode(code unit) at the given index.
/// 
/// This method has O(1) complexity.
pub fn View::charcode_at(self : View, index : Int) -> Int {
  guard index >= 0 && index < self.len() else { abort("Index out of bounds") }
  self.str.unsafe_charcode_at(self.start + index)
}

///|
/// Returns the charcode(code unit) at the given index without checking if the
/// index is within bounds.
/// 
/// This method has O(1) complexity.
pub fn View::unsafe_charcode_at(self : View, index : Int) -> Int {
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
pub fn View::iter2(self : View) -> Iter2[Int, Char] {
  Iter2::new(fn(yield_) {
    let len = self.len()
    for index = 0, n = 0; index < len; index = index + 1, n = n + 1 {
      let c1 = self.str.unsafe_charcode_at(self.start + index)
      if is_leading_surrogate(c1) && index + 1 < len {
        let c2 = self.str.unsafe_charcode_at(self.start + index + 1)
        if is_trailing_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(n, c) is IterContinue else { break IterEnd }
          continue index + 2, n + 1
        }
      }
      guard yield_(n, Char::from_int(c1)) is IterContinue else { break IterEnd }

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

///|
/// Compares two views for equality. Returns true only if both views
/// have the same length and contain identical characters in the same order.
pub impl Eq for View with op_equal(self, other) {
  let len = self.len()
  guard len == other.len() else { return false }
  if physical_equal(self.str, other.str) && self.start == other.start {
    return true
  }
  for i in 0..<len {
    guard self.str.unsafe_charcode_at(self.start + i) ==
      other.str.unsafe_charcode_at(other.start + i) else {
      return false
    }

  }
  true
}

///|
/// Views are ordered lexicographically by their charcodes(code unit). This 
/// orders Unicode characters based on their positions in the code charts. This is
/// not necessarily the same as "alphabetical" order, which varies by language
/// and locale.
pub impl Compare for View with compare(self, other) {
  let self_len = self.len()
  let other_len = other.len()
  let cmp = self_len.compare(other_len)
  guard cmp == 0 else { return cmp }
  if physical_equal(self.str, other.str) && self.start == other.start {
    return 0
  }
  for i in 0..<self_len {
    let cmp = self.str
      .unsafe_charcode_at(self.start + i)
      .compare(other.str.unsafe_charcode_at(other.start + i))
    guard cmp == 0 else { return cmp }

  }
  0
}

///|
/// The empty view of a string
pub impl Default for View with default() {
  // todo: remove .view() in new version
  "".view()
}

///|
/// Convert char array to string view.
pub fn View::from_array(chars : Array[Char]) -> View {
  // todo: remove .view() in new version
  String::from_array(chars).view()
}

///|
/// Convert char iterator to string view.
pub fn View::from_iter(iter : Iter[Char]) -> View {
  // todo: remove .view() in new version
  String::from_iter(iter).view()
}

///|
/// Create a new string by repeating the given character `value` `length` times.
pub fn View::make(length : Int, value : Char) -> View {
  // todo: remove .view() in new version
  String::make(length, value).view()
}

///|
pub impl ToJson for View with to_json(self) {
  String::to_json(self.to_string())
}
