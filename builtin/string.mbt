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
fn unsafe_make_string(length : Int, value : Char) -> String = "$moonbit.unsafe_make_string"

///|
/// Create new string of `length`, where each character is `value`
///
/// ```mbt
///   assert_eq(String::make(5,'S'), "SSSSS")
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
let min_leading_surrogate = 0xD800

///|
let max_leading_surrogate = 0xDBFF

///|
let min_trailing_surrogate = 0xDC00

///|
let max_trailing_surrogate = 0xDFFF

///|
fn is_leading_surrogate(c : Int) -> Bool {
  min_leading_surrogate <= c && c <= max_leading_surrogate
}

///|
fn is_trailing_surrogate(c : Int) -> Bool {
  min_trailing_surrogate <= c && c <= max_trailing_surrogate
}

///|
fn code_point_of_surrogate_pair(leading : Int, trailing : Int) -> Char {
  ((leading - 0xD800) * 0x400 + trailing - 0xDC00 + 0x10000).unsafe_to_char()
}

///|
/// Returns the UTF-16 code unit at the given index.
/// 
/// This function will panic if the index is out of bounds.
///
/// # Examples
///
/// ```mbt
///   let s = "Hello🤣";
///   inspect(s.charcode_at(0), content="72");
///   inspect(s.charcode_at(5), content="55358"); // First surrogate of 🤣
///   inspect(s.charcode_at(6), content="56611"); // Second surrogate of 🤣
/// ```
///
pub fn String::charcode_at(self : String, index : Int) -> Int = "%string_get"

///|
/// Returns the Unicode code point at the given index.
///
/// This method counts Unicode code points (characters) rather than UTF-16 code units.
/// It properly handles surrogate pairs to return the correct Unicode character.
///
/// # Examples
///
/// ```mbt
///   let s = "Hello🤣";
///   inspect(s.iter().nth(0).unwrap(), content="H");
///   inspect(s.iter().nth(5).unwrap(), content="🤣"); // Returns full emoji character
/// ```
///
/// # Panics
///
/// Panics if:
/// - The index is out of bounds
/// - The string contains an invalid surrogate pair
#deprecated("The index will be changed to utf16 index. If you want to access n-th character, use `str.iter().nth(n).unwrap()` instead.")
pub fn String::codepoint_at(self : String, index : Int) -> Char {
  let charcode_len = self.length()
  guard index >= 0 && index < charcode_len else { abort("index out of bounds") }
  for char_count = 0, utf16_offset = 0
      char_count < charcode_len && utf16_offset < index
      char_count = char_count + 1, utf16_offset = utf16_offset + 1 {
    let c1 = self.unsafe_charcode_at(char_count)
    if is_leading_surrogate(c1) && char_count + 1 < charcode_len {
      let c2 = self.unsafe_charcode_at(char_count + 1)
      if is_trailing_surrogate(c2) {
        continue char_count + 2, utf16_offset + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    guard utf16_offset == index && char_count < charcode_len else {
      abort("index out of bounds")
    }
    let c1 = self.unsafe_charcode_at(char_count)
    if is_leading_surrogate(c1) && char_count + 1 < charcode_len {
      let c2 = self.unsafe_charcode_at(char_count + 1)
      if is_trailing_surrogate(c2) {
        code_point_of_surrogate_pair(c1, c2)
      } else {
        abort("invalid surrogate pair")
      }
    } else {
      c1.unsafe_to_char()
    }
  }
}

///|
/// Returns the Unicode code point at the given index without bounds checking.
pub fn String::unsafe_char_at(self : String, index : Int) -> Char {
  let c1 = self.unsafe_charcode_at(index)
  if is_leading_surrogate(c1) {
    let c2 = self.unsafe_charcode_at(index + 1)
    code_point_of_surrogate_pair(c1, c2)
  } else {
    c1.unsafe_to_char()
  }
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
/// ```mbt
///   let s = "Hello🤣";
///   inspect(s.char_length(), content = "6"); // 6 actual characters
///   inspect(s.length(), content = "7");  // 5 ASCII chars + 2 surrogate pairs
/// ```
pub fn String::char_length(
  self : String,
  start_offset~ : Int = 0,
  end_offset? : Int
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
    if is_leading_surrogate(c1) && utf16_index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(utf16_index + 1)
      if is_trailing_surrogate(c2) {
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
#deprecated("Use `char_length` instead.")
pub fn String::codepoint_length(
  self : String,
  start_offset~ : Int = 0,
  end_offset? : Int
) -> Int {
  self.char_length(start_offset~, end_offset?)
}

///|
#intrinsic("%string.substring")
fn unsafe_substring(str : String, start : Int, end : Int) -> String {
  let len = end - start
  let bytes = FixedArray::make(len * 2, Byte::default())
  bytes.blit_from_string(0, str, start, len)
  bytes.unsafe_to_bytes().to_unchecked_string()
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
/// Example:
///
/// ```moonbit
///   let s = "Hello world"
///   inspect(s.substring(start=0, end=5), content="Hello")
///   inspect(s.substring(start=6, end=11), content="world")
///   inspect(s.substring(), content="Hello world")
///
///   let s = "test"
///   inspect(s.substring(start=2, end=2), content="")
///   inspect("".substring(), content="")
/// ```
pub fn String::substring(self : String, start~ : Int = 0, end? : Int) -> String {
  let len = self.length()
  let end = match end {
    Some(end) => end
    None => len
  }
  guard start >= 0 && start <= end && end <= len
  unsafe_substring(self, start, end)
}

///|
test "substring/basic" {
  let s = "hello, world"
  inspect(s.substring(start=0, end=5), content="hello")
  inspect(s.substring(start=7, end=12), content="world")
  inspect(s.substring(), content="hello, world")
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
