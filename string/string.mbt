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
/// Convert char array to string.
///
/// ```
/// let s = @string.from_array(['H', 'e', 'l', 'l', 'o'])
/// assert_eq!(s, "Hello")
/// ```
///
/// Do not convert large datas to `Array[Char]` and build a string with `String::from_array`.
///
/// For efficiency considerations, it's recommended to use `Buffer` instead.
pub fn String::from_array(chars : Array[Char]) -> String {
  let buf = StringBuilder::new(size_hint=chars.length() * 4)
  for c in chars {
    buf.write_char(c)
  }
  buf.to_string()
}

///| same as `String::from_array`
#deprecated("Use `String::from_array(chars)` instead.")
pub fn from_array(chars : Array[Char]) -> String {
  String::from_array(chars)
}

///|
/// Convert char iterator to string,
/// a simple wrapper for `from_array`.
pub fn String::from_iter(iter : Iter[Char]) -> String {
  let chars = iter.collect()
  String::from_array(chars)
}

///|
/// same as `String::from_iter`
#deprecated("Use `String::from_iter(iter)` instead.")
pub fn from_iter(iter : Iter[Char]) -> String {
  let chars = iter.collect()
  String::from_array(chars)
}

///|
/// Concatenate strings.
///
/// ```
/// let s = @string.concat(["Hello", ", ", "world!"])
/// assert_eq!(s, "Hello, world!")
/// let s = @string.concat(["a", "b", "c"], separator=",")
/// assert_eq!(s, "a,b,c")
/// ```
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
/// Strings are ordered lexicographically by their charcodes(code unit). This 
/// orders Unicode characters based on their positions in the code charts. This is
/// not necessarily the same as "alphabetical" order, which varies by language
/// and locale.
pub impl Compare for String with compare(self, other) {
  let len = self.length()
  match len.compare(other.length()) {
    0 => {
      for i in 0..<len {
        let order = self
          .unsafe_charcode_at(i)
          .compare(other.unsafe_charcode_at(i))
        if order != 0 {
          return order
        }
      }
      0
    }
    order => order
  }
}

///|
/// The empty string
pub impl Default for String with default() {
  ""
}

///|
/// same as `String::default`
#deprecated("Use `String::default()` instead.")
pub fn default() -> String {
  ""
}

///|
/// `String` holds a sequence of UTF-16 code units encoded in little endian format
#deprecated("Use `Bytes::of_string(str)` instead.")
pub fn to_bytes(self : String) -> Bytes {
  Bytes::of_string(self)
}

///|
/// Converts the String into an array of Chars.
#deprecated("Use `str.iter().collect()` instead.")
pub fn to_array(self : String) -> Array[Char] {
  self.iter().collect()
}

///|
/// Returns an iterator over the Unicode characters in the string.
///
/// Note: This iterator yields Unicode characters, not Utf16 code units.
/// As a result, the count of characters returned by `iter().count()` may not be equal to the length of the string returned by `length()`.
///
/// ```
/// let s = "Hello, World!🤣";
/// assert_eq!(s.iter().count(), 14); // Unicode characters
/// assert_eq!(s.length(), 15); // Utf16 code units
/// ```
pub fn String::iter(self : String) -> Iter[Char] {
  Iter::new(fn(yield_) {
    let len = self.length()
    for index in 0..<len {
      let c1 = self.unsafe_charcode_at(index)
      if is_leading_surrogate(c1) && index + 1 < len {
        let c2 = self.unsafe_charcode_at(index + 1)
        if is_trailing_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index + 2
        }
      }
      //TODO: handle garbage input
      guard yield_(Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
#deprecated("Use `str.iter()` instead.")
pub fn iter(s : String) -> Iter[Char] {
  s.iter()
}

///|
pub fn String::iter2(self : String) -> Iter2[Int, Char] {
  Iter2::new(fn(yield_) {
    let len = self.length()
    for index = 0, n = 0; index < len; index = index + 1, n = n + 1 {
      let c1 = self.unsafe_charcode_at(index)
      if is_leading_surrogate(c1) && index + 1 < len {
        let c2 = self.unsafe_charcode_at(index + 1)
        if is_trailing_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(n, c) is IterContinue else { break IterEnd }
          continue index + 2, n + 1
        }
      }
      //TODO: handle garbage input
      guard yield_(n, Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
#deprecated("Use `str.iter2()` instead.")
pub fn iter2(s : String) -> Iter2[Int, Char] {
  s.iter2()
}

///|
/// Returns an iterator that yields characters from the end to the start of the string. This function handles
/// Unicode surrogate pairs correctly, ensuring that characters are not split across surrogate pairs.
///
/// # Parameters
///
/// - `self` : The input `String` to be iterated in reverse.
///
/// # Returns
///
/// - An `Iter[Char]` that yields characters from the end to the start of the string.
///
/// # Behavior
///
/// - The function iterates over the string in reverse order.
/// - If a trailing surrogate is encountered, it checks for a preceding leading surrogate to form a complete Unicode code point.
/// - Yields each character or combined code point to the iterator.
/// - Stops iteration if the `yield_` function returns `IterEnd`.
///
/// # Examples
///
/// ```
/// let input = "Hello, World!"
/// let reversed = input.rev_iter().collect()
/// assert_eq!(reversed, ['!', 'd', 'l', 'r', 'o', 'W', ' ', ',', 'o', 'l', 'l', 'e', 'H'])
/// ```
pub fn String::rev_iter(self : String) -> Iter[Char] {
  Iter::new(fn(yield_) {
    let len = self.length()
    for index = len - 1; index >= 0; index = index - 1 {
      let c1 = self.unsafe_charcode_at(index)
      if is_trailing_surrogate(c1) && index - 1 >= 0 {
        let c2 = self.unsafe_charcode_at(index - 1)
        if is_leading_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c2, c1)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index - 2
        }
      }
      // TODO: handle garbage input
      guard yield_(Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
#deprecated("Use `str.rev_iter()` instead.")
pub fn rev_iter(s : String) -> Iter[Char] {
  s.rev_iter()
}

///|
#deprecated("Use `str.view().trim_space().to_string()` instead.")
pub fn trim_space(self : String) -> String {
  self.view().trim_space().to_string()
}

///|
#deprecated("Use `str.view().trim(trim_set).to_string()` instead.")
pub fn trim(self : String, trim_set : String) -> String {
  self.view().trim(trim_set).to_string()
}

///|
#deprecated("Use `str.trim_left(trim_set).to_string()` instead.")
pub fn trim_start(self : String, trim_set : String) -> String {
  self.trim_left(trim_set).to_string()
}

///|
#deprecated("Use `str.trim_right(trim_set).to_string()` instead.")
pub fn trim_end(self : String, trim_set : String) -> String {
  self.trim_right(trim_set).to_string()
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
#deprecated("Use `s.rfind(substr)` instead. If the optional argument `from` is not 0, take view from the string first. Please do not use an invalid `from` argument.")
pub fn last_index_of(
  self : String,
  str : String,
  from~ : Int = self.length()
) -> Int {
  if from >= self.length() {
    if self.rfind(str.view()) is Some(idx) {
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
  } else if self.view(end_offset=from).rfind(str.view()) is Some(idx) {
    idx
  } else {
    -1
  }
}

///|
/// Returns true if this string contains given sub string.
#deprecated("Use `s.view().contains(str)` instead.")
pub fn contains(self : String, str : String) -> Bool {
  self.view().contains(str)
}

///|
/// Returns true if this string starts with a sub string.
#deprecated("Use `s.has_prefix(str)` instead.")
pub fn starts_with(self : String, str : String) -> Bool {
  self.has_prefix(str)
}

///|
/// Returns true if this string ends with a sub string.
#deprecated("Use `s.has_suffix(str)` instead.")
pub fn ends_with(self : String, str : String) -> Bool {
  self.has_suffix(str)
}

///|
/// Splits the input `String` into an `Iter` of `String` using the specified `separator`.
///
/// # Parameters
///
/// - `self` : The input `String` to be split.
/// - `separator` : The `String` used as the delimiter for splitting.
///
/// # Returns
///
/// - An `Iter` of `String` where each element is a substring of the original string, separated by the `separator`.
///
/// # Behavior
///
/// - If the `separator` is an empty string (`""`), the function returns an `Iter` where each element is a single character from the input string converted to a `String`.
/// - If the `separator` is not empty, the function searches for occurrences of the `separator` in the input string and yields substrings between these occurrences.
/// - If no more occurrences of the `separator` are found, the remaining part of the string is yielded as the last element of the `Iter`.
///
/// # Examples
///
/// ```
/// let input = "a,b,c,d"
/// let separator = ","
/// let result = input.split(separator).collect()
/// assert_eq!(result, ["a", "b", "c", "d"])
/// ```
#deprecated("Use `str.view().split(sep).map(View::to_string)` instead.")
pub fn split(self : String, separator : String) -> Iter[String] {
  self.view().split(separator).map(View::to_string)
}

///|
/// Replace the first old string in this string to new string.
#deprecated("Use `str.view().replace(old, new).to_string()` instead.")
pub fn replace(self : String, old~ : String, new~ : String) -> String {
  self.view().replace(old~, new~).to_string()
}

///|
/// Replace all old string in this string to new string.
#deprecated("Use `str.view().replace_all(old, new).to_string()` instead.")
pub fn replace_all(self : String, old~ : String, new~ : String) -> String {
  self.view().replace_all(old~, new~).to_string()
}

///|
/// Converts this string to lowercase.
#deprecated("Use `str.view().to_lower().to_string()` instead.")
pub fn to_lower(self : String) -> String {
  self.view().to_lower().to_string()
}

///|
/// Converts this string to uppercase.
#deprecated("Use `str.view().to_upper().to_string()` instead.")
pub fn to_upper(self : String) -> String {
  self.view().to_upper().to_string()
}

///|
/// Reverse string
/// It respects Unicode characters and surrogate pairs but not grapheme clusters.
/// TODO: make it an intrinsic function
#deprecated("Use `str.view().rev().to_string()` instead.")
pub fn rev(self : String) -> String {
  self.view().rev().to_string()
}

///|
/// Repeats the string `n` times.
#deprecated("Use `str.view().repeat(n).to_string()` instead.")
pub fn repeat(self : String, n : Int) -> String {
  self.view().repeat(n).to_string()
}

///|
/// `pad_start` is a new string with `padding_char`s prefixed to `self` if `self.length() < total_width`. The length of the
/// returned string is `total_width`.
///
/// Example:
///
/// ```
/// assert_eq!("2".pad_start(3, '0'), "002")
/// ```
#deprecated("Use `str.view().pad_start(total_width, padding_char).to_string()` instead.")
pub fn pad_start(
  self : String,
  total_width : Int,
  padding_char : Char
) -> String {
  self.view().pad_start(total_width, padding_char).to_string()
}

///|
/// `pad_end` is a new String with `padding_char`s suffixed to `self` if `self.length() < total_width`. The length of the
/// returned string is `total_width`.
///
/// Example:
///
/// ```
/// assert_eq!("2".pad_end(3, 'x'), "2xx")
/// ```
#deprecated("Use `str.view().pad_end(total_width, padding_char).to_string()` instead.")
pub fn pad_end(self : String, total_width : Int, padding_char : Char) -> String {
  self.view().pad_end(total_width, padding_char).to_string()
}

///|
/// Returns the index of the n-th (zero-indexed) character within the range [start, end).
fn String::offset_of_nth_char_forward(
  self : String,
  n : Int,
  start_offset~ : Int,
  end_offset~ : Int
) -> Int? {
  guard start_offset >= 0 && start_offset <= end_offset else {
    abort("Invalid start index")
  }
  let mut utf16_offset = start_offset
  let mut char_count = 0
  while utf16_offset < end_offset && char_count < n {
    let c = self.unsafe_charcode_at(utf16_offset)
    // check if this is a surrogate pair
    if is_leading_surrogate(c) {
      utf16_offset = utf16_offset + 2
    } else {
      utf16_offset = utf16_offset + 1
    }
    char_count = char_count + 1
  }
  // Return None if either:
  // 1. We couldn't reach the requested character offset
  // 2. The resulting offset is beyond the end of the string
  // This handles the empty string case correctly.
  if char_count < n || utf16_offset >= end_offset {
    None
  } else {
    Some(utf16_offset)
  }
}

///|
/// Returns the index of the n-th (zero-indexed) character within the range [start, end).
/// self[end] is counted as the 0-th character (though it might not exist if end = self.length()).
fn String::offset_of_nth_char_backward(
  self : String,
  n : Int,
  start_offset~ : Int,
  end_offset~ : Int
) -> Int? {
  let mut char_count = 0
  let mut utf16_offset = end_offset
  // Iterating backwards from the end of the string. 
  // Invariant: utf16_offset always points to the previous character
  while utf16_offset - 1 >= start_offset && char_count < n {
    let c = self.unsafe_charcode_at(utf16_offset - 1)
    if is_trailing_surrogate(c) {
      utf16_offset = utf16_offset - 2
    } else {
      utf16_offset = utf16_offset - 1
    }
    char_count = char_count + 1
  }
  if char_count < n || utf16_offset < start_offset {
    None
  } else {
    Some(utf16_offset)
  }
}

///|
/// Returns the UTF-16 index of the i-th (zero-indexed) Unicode character 
/// within the range [start, end). If i is negative, it returns the index of 
/// the (n + i)-th character where n is the number of Unicode characters 
/// in the range [start, end).
/// 
/// This functions assumes that the string is valid UTF-16.
pub fn String::offset_of_nth_char(
  self : String,
  i : Int,
  start_offset~ : Int = 0,
  end_offset~ : Int = self.length()
) -> Int? {
  if i >= 0 {
    // forward case
    self.offset_of_nth_char_forward(i, start_offset~, end_offset~)
  } else {
    // backward case
    self.offset_of_nth_char_backward(-i, start_offset~, end_offset~)
  }
}

///|
/// Returns the Unicode character at the given index.
pub fn String::char_at(self : String, index : Int) -> Char {
  guard index >= 0 && index < self.length() else {
    abort("index out of bounds")
  }
  self.unsafe_char_at(index)
}

///|
/// Test if the length of the string is equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
pub fn String::char_length_eq(
  self : String,
  len : Int,
  start_offset~ : Int = 0,
  end_offset~ : Int = self.length()
) -> Bool {
  for index = start_offset, count = 0
      index < end_offset && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if is_leading_surrogate(c1) && index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(index + 1)
      if is_trailing_surrogate(c2) {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count == len && index == end_offset
  }
}

///|
/// Test if the length of the string is greater than or equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
pub fn String::char_length_ge(
  self : String,
  len : Int,
  start_offset~ : Int = 0,
  end_offset~ : Int = self.length()
) -> Bool {
  for index = start_offset, count = 0
      index < end_offset && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if is_leading_surrogate(c1) && index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(index + 1)
      if is_trailing_surrogate(c2) {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count >= len
  }
}
