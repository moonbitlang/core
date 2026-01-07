// Copyright 2026 International Digital Economy Academy
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
fn unsafe_make_string(length : Int, value : Char) -> String = "$moonbit.unsafe_make_string"

///|
/// Create new string of `length`, where each character is `value`
///
/// ```mbt check
/// test {
///   assert_eq(String::make(5, 'S'), "SSSSS")
/// }
/// ```
pub fn String::make(length : Int, value : Char) -> String {
  guard length >= 0 else { abort("invalid length") }
  if value.to_int() <= 0xFFFF {
    unsafe_make_string(length, value)
  } else {
    let buf = StringBuilder::new(size_hint=2 * length)
    for _ in 0..<length {
      buf.write_char(value)
    }
    buf.to_string()
  }
}

///|
fn code_point_of_surrogate_pair(leading : Int, trailing : Int) -> Char {
  ((leading - 0xD800) * 0x400 + trailing - 0xDC00 + 0x10000).unsafe_to_char()
}

///|
/// Returns the number of Unicode code points (characters) in the string.
///
/// This method counts actual Unicode characters, properly handling surrogate pairs
/// that represent single characters like emojis. For the raw UTF-16 code unit count,
/// use `length()` instead.
///
/// # Examples
///
/// ```mbt check
/// test {
///   let s = "Hello🤣"
///   inspect(s.char_length(), content="6") // 6 actual characters
///   inspect(s.length(), content="7")
/// } // 5 ASCII chars + 2 surrogate pairs
/// ```
#alias(codepoint_length, deprecated)
pub fn String::char_length(
  self : String,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> Int {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  guard start_offset >= 0 &&
    start_offset <= end_offset &&
    end_offset <= self.length() else {
    abort("invalid start or end index for String::codepoint_length")
  }
  for utf16_index = start_offset, char_count = 0
      utf16_index < end_offset
      utf16_index = utf16_index + 1, char_count = char_count + 1 {
    let c1 = self.unsafe_charcode_at(utf16_index)
    if c1.is_leading_surrogate() && utf16_index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(utf16_index + 1)
      if c2.is_trailing_surrogate() {
        continue utf16_index + 2, char_count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    char_count
  }
}

///|
#intrinsic("%string.substring")
pub fn String::unsafe_substring(
  str : String,
  start~ : Int,
  end~ : Int,
) -> String {
  if start == 0 && end == str.length() {
    return str
  }
  let len = end - start
  let bytes = FixedArray::make(len * 2, Byte::default())
  bytes.blit_from_string(0, str, start, len)
  bytes.unsafe_reinterpret_as_bytes().to_unchecked_string()
}

///|
/// Returns a new string containing characters from the original string starting
/// at `start` index up to (but not including) `end` index.
///
/// Parameters:
///
/// * `string` : The source string from which to extract the substring.
/// * `start` : The starting index of the substring (inclusive). Defaults to 0.
/// * `end` : The ending index of the substring (exclusive). Defaults to the
/// length of the string.
///
/// Returns a new string containing the specified substring.
///
#deprecated("Use `str[:]` or `str[:].to_string()` instead", skip_current_package=true)
pub fn String::substring(self : String, start? : Int = 0, end? : Int) -> String {
  let len = self.length()
  let end = match end {
    Some(end) => end
    None => len
  }
  guard start >= 0 && start <= end && end <= len
  self.unsafe_substring(start~, end~)
}

///|
/// Iterates over all suffixes of the string as views that reuse the
/// original storage. Surrogate pairs stay intact while advancing.
pub fn String::suffixes(
  self : String,
  include_empty? : Bool = false,
) -> Iter[StringView] {
  self[:].suffixes(include_empty~)
}

///|
test "substring/empty" {
  let s = "test"
  inspect(s.substring(start=2, end=2), content="")
  inspect(s.substring(start=4, end=4), content="")
  inspect("".substring(), content="")
}

///|
test "panic substring/invalid_range" {
  let s = "test"
  ignore(s.substring(start=-1))
  ignore(s.substring(end=5))
  ignore(s.substring(start=3, end=2))
}

///|
test "substring/basic" {
  inspect("Hello world".substring(start=0, end=5), content="Hello")
  inspect("Hello world".substring(start=6, end=11), content="world")
  inspect("Hello world".substring(start=0), content="Hello world")
  inspect("Hello world".substring(start=6), content="world")
}

///|
test "substring/boundary" {
  inspect("".substring(start=0, end=0), content="")
  inspect("a".substring(start=0, end=1), content="a")
  inspect("abc".substring(start=0), content="abc")
  inspect("abc".substring(start=1), content="bc")
  inspect("abc".substring(start=0, end=3), content="abc")
}

///|
test "panic substring/out_of_bounds" {
  ignore("hello".substring(start=-1, end=4))
  ignore("hello".substring(start=6, end=4))
  ignore("hello".substring(start=0, end=6))
}

///|
/// Strings are ordered based on shortlex order by their charcodes (code units). This 
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
/// `String` holds a sequence of UTF-16 code units encoded in little endian format
#deprecated("Check `@encoding/utf8.encode`")
pub fn String::to_bytes(self : String) -> Bytes {
  let array = FixedArray::make(self.length() * 2, Byte::default())
  array.blit_from_string(0, self, 0, self.length())
  array |> unsafe_to_bytes
}

///|
fn unsafe_to_bytes(array : FixedArray[Byte]) -> Bytes = "%identity"

///|
/// Converts the String into an array of Chars.
pub fn String::to_array(self : String) -> Array[Char] {
  self
  .iter()
  .fold(init=Array::new(capacity=self.length()), (rv, c) => {
    rv.push(c)
    rv
  })
}

///|
/// Returns an iterator over the Unicode characters in the string.
///
/// Note: This iterator yields Unicode characters, not Utf16 code units.
/// As a result, the count of characters returned by `iterator().count()` may not be equal to the length of the string returned by `length()`.
///
/// ```mbt check
/// test {
///   let s = "Hello, World!🤣"
///   assert_eq(s.iter().count(), 14) // Unicode characters
///   assert_eq(s.length(), 15)
/// } // Utf16 code units
/// ```
#alias(iterator, deprecated)
pub fn String::iter(self : String) -> Iter[Char] {
  let len = self.length()
  let mut index = 0
  Iter::new(fn() {
    guard index < len else { None }
    let c1 = self.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < len {
      let c2 = self.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        let c = code_point_of_surrogate_pair(c1, c2)
        index += 2
        return Some(c)
      }
    }
    index += 1
    //TODO: handle garbage input
    Some(c1.unsafe_to_char())
  })
}

///|
#alias(iterator2, deprecated)
pub fn String::iter2(self : String) -> Iter2[Int, Char] {
  self.iter().iter2()
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
/// ```mbt check
/// test {
///   let input = "Hello, World!"
///   let reversed = input.rev_iter().collect()
///   assert_eq(reversed, [
///     '!', 'd', 'l', 'r', 'o', 'W', ' ', ',', 'o', 'l', 'l', 'e', 'H',
///   ])
/// }
/// ```
#alias(rev_iterator, deprecated)
pub fn String::rev_iter(self : String) -> Iter[Char] {
  let len = self.length()
  let mut index = len
  Iter::new(fn() {
    guard index > 0 else { None }
    index -= 1
    let c1 = self.unsafe_charcode_at(index)
    if c1.is_trailing_surrogate() && index - 1 >= 0 {
      let c2 = self.unsafe_charcode_at(index - 1)
      if c2.is_leading_surrogate() {
        index -= 1
        return Some(code_point_of_surrogate_pair(c2, c1))
      }
    }
    Some(c1.unsafe_to_char())
  })
}

///|
/// Returns the index of the n-th (zero-indexed) character within the range [start, end).
fn String::offset_of_nth_char_forward(
  self : String,
  n : Int,
  start_offset~ : Int,
  end_offset~ : Int,
) -> Int? {
  guard start_offset >= 0 && start_offset <= end_offset else {
    abort("Invalid start index")
  }
  let mut utf16_offset = start_offset
  let mut char_count = 0
  while utf16_offset < end_offset && char_count < n {
    let c = self.unsafe_charcode_at(utf16_offset)
    // check if this is a surrogate pair
    if c.is_leading_surrogate() {
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
  end_offset~ : Int,
) -> Int? {
  let mut char_count = 0
  let mut utf16_offset = end_offset
  // Iterating backwards from the end of the string. 
  // Invariant: utf16_offset always points to the previous character
  while utf16_offset - 1 >= start_offset && char_count < n {
    let c = self.unsafe_charcode_at(utf16_offset - 1)
    if c.is_trailing_surrogate() {
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
  start_offset? : Int = 0,
  end_offset? : Int,
) -> Int? {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  if i >= 0 {
    // forward case
    self.offset_of_nth_char_forward(i, start_offset~, end_offset~)
  } else {
    // backward case
    self.offset_of_nth_char_backward(-i, start_offset~, end_offset~)
  }
}

///|
/// Test if the length of the string is equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
pub fn String::char_length_eq(
  self : String,
  len : Int,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> Bool {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  for index = start_offset, count = 0
      index < end_offset && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
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
  start_offset? : Int = 0,
  end_offset? : Int,
) -> Bool {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  for index = start_offset, count = 0
      index < end_offset && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count >= len
  }
}

///|
/// Performs a lexicographical comparison of two strings.
///
/// This method compares the strings character by character (UTF-16 code unit by code unit),
/// similar to Java's `String.compareTo()`. Unlike the `Compare` trait implementation which
/// uses shortlex order (shorter strings come first), this method compares based purely on
/// character values until a difference is found or one string is exhausted.
///
/// # Returns
///
/// - A negative integer if `self` is lexicographically less than `other`
/// - Zero if `self` is lexicographically equal to `other`
/// - A positive integer if `self` is lexicographically greater than `other`
///
/// # Example
///
/// ```mbt check
/// test {
///   inspect("ab".lexical_compare("abc"), content="-1")
///   inspect("abc".lexical_compare("ab"), content="1")
///   inspect("abc".lexical_compare("abc"), content="0")
///   inspect("abc".lexical_compare("abd"), content="-1")
/// }
/// ```
///
/// # Note
///
/// Since MoonBit strings are UTF-16 encoded (like Java), this comparison operates on
/// UTF-16 code units, not Unicode code points. Surrogate pairs (used for characters
/// outside the Basic Multilingual Plane) are compared as individual code units.
pub fn String::lexical_compare(self : String, other : String) -> Int {
  self[:].lexical_compare(other[:])
}

///|
/// Convert char array to string.
///
/// ```mbt check
/// test {
///   let s = String::from_array(['H', 'e', 'l', 'l', 'o'])
///   assert_eq(s, "Hello")
/// }
/// ```
///
/// Do not convert large data to `Array[Char]` and build a string with `String::from_array`.
///
/// For efficiency considerations, it's recommended to use `Buffer` instead.
pub fn String::from_array(chars : ArrayView[Char]) -> String {
  let buf = StringBuilder::new(size_hint=chars.length() * 4)
  for c in chars {
    buf.write_char(c)
  }
  buf.to_string()
}

///|
/// Convert char iterator to string,
#alias(from_iterator, deprecated)
pub fn String::from_iter(iter : Iter[Char]) -> String {
  let buf = StringBuilder::new()
  for c in iter {
    buf.write_char(c)
  }
  buf.to_string()
}
