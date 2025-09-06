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
/// ```mbt
///   let s = "Hello🤣";
///   inspect(s.char_length(), content = "6"); // 6 actual characters
///   inspect(s.length(), content = "7");  // 5 ASCII chars + 2 surrogate pairs
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
#deprecated("Use `str[:]` or `str[:].to_string()` instead")
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
