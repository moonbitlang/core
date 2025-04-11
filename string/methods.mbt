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
/// Returns the offset of the first occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn View::find(self : View, str : View) -> Int? {
  let len = self.len()
  let sub_len = str.len()
  // Handle empty substring case
  guard sub_len > 0 else { return Some(0) }
  // If substring is longer than string, it can't be found
  guard sub_len <= len else { return None }
  let max_idx = len - sub_len
  let first = str.unsafe_charcode_at(0)
  let mut i = 0
  while i <= max_idx {
    // find first character
    while i < len && self.unsafe_charcode_at(i) != first {
      i += 1
    }
    // check the rest
    if i <= max_idx {
      for j in 1..<sub_len {
        if self.unsafe_charcode_at(i + j) != str.unsafe_charcode_at(j) {
          break
        }
      } else {
        // the substring is found
        return Some(i)
      }
    }
    i += 1
  }
  None
}

///|
/// Returns the offset of the first occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn String::find(self : String, str : View) -> Int? {
  self.view().find(str)
}

///|
test "find" {
  inspect!("hello".find("o"), content="Some(4)")
  inspect!("hello".find("l"), content="Some(2)")
  inspect!("hello".find("hello"), content="Some(0)")
  inspect!("hello".find("h"), content="Some(0)")
  inspect!("hello".find(""), content="Some(0)")
  inspect!("hello".find("world"), content="None")
  inspect!("".find(""), content="Some(0)")
  inspect!("".find("a"), content="None")
  inspect!("hello hello".find("hello"), content="Some(0)")
  inspect!("aaa".find("aa"), content="Some(0)")
  inspect!("😀😀".find("😀"), content="Some(0)")
}

///|
/// Returns the offset of the last occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn View::rfind(self : View, str : View) -> Int? {
  let len = self.len()
  let sub_len = str.len()
  guard sub_len > 0 else { return Some(len) }
  guard sub_len <= len else { return None }
  let min_idx = sub_len - 1
  let last = str.unsafe_charcode_at(sub_len - 1)
  let mut i = len - 1
  while i >= min_idx {
    while i >= 0 && self.unsafe_charcode_at(i) != last {
      i -= 1
    }
    if i >= min_idx {
      for j in 1..<sub_len {
        if self.unsafe_charcode_at(i - j) !=
          str.unsafe_charcode_at(sub_len - 1 - j) {
          break
        }
      } else {
        return Some(i - sub_len + 1)
      }
    }
    i -= 1
  }
  None
}

///|
/// Returns the offset of the last occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn String::rfind(self : String, str : View) -> Int? {
  self.view().rfind(str)
}

///|
test "rfind" {
  inspect!("hello".rfind("o"), content="Some(4)")
  inspect!("hello".rfind("l"), content="Some(3)")
  inspect!("hello".rfind("hello"), content="Some(0)")
  inspect!("hello".rfind("h"), content="Some(0)")
  inspect!("hello".rfind(""), content="Some(5)")
  inspect!("hello".rfind("world"), content="None")
  inspect!("".rfind(""), content="Some(0)")
  inspect!("".rfind("a"), content="None")
  inspect!("hello hello".rfind("hello"), content="Some(6)")
  inspect!("aaa".rfind("aa"), content="Some(1)")
  inspect!("😀😀".rfind("😀"), content="Some(2)")
}

///|
/// Returns true if this string contains the given substring.
pub fn View::contains(self : View, str : View) -> Bool {
  self.find(str) is Some(_)
}

// TODO: add back the following method when the deprecated `contains` is removed
// pub fn String::contains(self : String, str : View) -> Bool {
//   self.view().contains(str)
// }

///|
test "contains" {
  inspect!("hello".contains("h"), content="true")
  inspect!("hello".contains("e"), content="true")
  inspect!("hello".contains("l"), content="true")
  inspect!("hello".contains("o"), content="true")
  inspect!("hello".contains("lo"), content="true")
  inspect!("hello".contains("hello"), content="true")
  inspect!("hello".contains(""), content="true")
  inspect!("hello".contains("world"), content="false")
  inspect!("".contains(""), content="true")
  inspect!("".contains("a"), content="false")
  inspect!("hello world".contains("world"), content="true")
  inspect!("hello world".contains("o w"), content="true")
  inspect!("😀😀".contains("😀"), content="true")
  inspect!("😀😀".contains("😀😀"), content="true")
  inspect!("😀😀".contains("😃"), content="false") // be careful that the last emoji is different 
}

///|
/// Returns true if this string contains the given character.
pub fn View::contains_char(self : View, c : Char) -> Bool {
  self.iter().any(fn(ch) { ch == c })
}

///|
/// Returns true if this string contains the given character.
pub fn String::contains_char(self : String, c : Char) -> Bool {
  self.view().contains_char(c)
}

///|
#deprecated("Use `str.contains_char(c)` instead.")
pub fn contains_char(s : String, c : Char) -> Bool {
  s.contains_char(c)
}

///|
test "contains_char" {
  inspect!("hello".contains_char('h'), content="true")
  inspect!("hello".contains_char('e'), content="true")
  inspect!("hello".contains_char('l'), content="true")
  inspect!("hello".contains_char('o'), content="true")
  inspect!("hello".contains_char('x'), content="false")
  inspect!("".contains_char('a'), content="false")
  inspect!("hello world".contains_char(' '), content="true")
  inspect!("hello world".contains_char('w'), content="true")
  inspect!("😀😀".contains_char('😀'), content="true")
  inspect!("😀😀".contains_char('😃'), content="false")
  inspect!("hello".contains_char(Char::from_int(104)), content="true") // 'h' is 104 in ASCII
}

///| 
/// Returns true if the given substring is suffix of this string.
pub fn View::has_suffix(self : View, str : View) -> Bool {
  self.rfind(str) is Some(i) && i == self.len() - str.len()
}

///|
/// Returns true if the given substring is suffix of this string.
pub fn String::has_suffix(self : String, str : View) -> Bool {
  self.view().has_suffix(str)
}

///|
test "has_suffix" {
  inspect!("hello".has_suffix("lo"), content="true")
  inspect!("hello".has_suffix("hello"), content="true")
  inspect!("hello".has_suffix(""), content="true")
  inspect!("hello".has_suffix("world"), content="false")
  inspect!("hello".has_suffix("hel"), content="false")
  inspect!("".has_suffix(""), content="true")
  inspect!("".has_suffix("a"), content="false")
  inspect!("hello world".has_suffix("world"), content="true")
  inspect!("😀😀".has_suffix("😀"), content="true")
  inspect!("😀😀".has_suffix("😀😀"), content="true")
}

///|
/// Returns true if this string starts with the given substring.
pub fn View::has_prefix(self : View, str : View) -> Bool {
  self.find(str) is Some(i) && i == 0
}

///|
/// Returns true if this string starts with the given substring.
pub fn String::has_prefix(self : String, str : View) -> Bool {
  self.view().has_prefix(str)
}

///|
test "has_prefix" {
  inspect!("hello".has_prefix("h"), content="true")
  inspect!("hello".has_prefix("he"), content="true")
  inspect!("hello".has_prefix(""), content="true")
  inspect!("hello".has_prefix("world"), content="false")
  inspect!("hello".has_prefix("lo"), content="false")
  inspect!("".has_prefix(""), content="true")
  inspect!("".has_prefix("a"), content="false")
  inspect!("😀hello".has_prefix("😀"), content="true")
  inspect!("😀😃hello".has_prefix("😀😃"), content="true")
  inspect!("😀hello".has_prefix("😃"), content="false")
  inspect!("hello😀".has_prefix("😀"), content="false")
}

///|
/// Returns the view of the string without the leading characters that are in
/// the given string.
pub fn View::trim_left(self : View, char_set : View) -> View {
  loop self {
    [] as v => v
    [c, .. rest] as v =>
      if char_set.contains_char(c) {
        continue rest
      } else {
        v
      }
  }
}

///|
/// Returns the view of the string without the leading characters that are in
/// the given string.
pub fn String::trim_left(self : String, char_set : View) -> View {
  self.view().trim_left(char_set)
}

///|
test "trim_left" {
  inspect!("hello".trim_left(['h']), content="ello")
  inspect!("hello".trim_left(['h', 'e']), content="llo")
  inspect!("hello".trim_left(['e', 'h']), content="llo")
  inspect!("hello".trim_left(['x']), content="hello")
  inspect!("hello".trim_left([]), content="hello")
  inspect!("".trim_left(['a']), content="")
  inspect!("   hello".trim_left([' ']), content="hello")
  inspect!("hello world".trim_left(['h', 'e', 'l', 'o']), content=" world")
  inspect!("😀😀hello".trim_left(['😀']), content="hello")
  inspect!("😀😃hello".trim_left(['😀', '😃']), content="hello")
  inspect!("aaaabc".trim_left(['a']), content="bc")
  inspect!("aaaa".trim_left(['a']), content="")
}

///|
/// Returns the view of the string without the trailing characters that are in
/// the given string.
pub fn View::trim_right(self : View, char_set : View) -> View {
  loop self {
    [] as v => v
    [.. rest, c] as v =>
      if char_set.contains_char(c) {
        continue rest
      } else {
        v
      }
  }
}

///|
/// Returns the view of the string without the trailing characters that are in
/// the given string.
pub fn String::trim_right(self : String, char_set : View) -> View {
  self.view().trim_right(char_set)
}

///|
test "trim_right" {
  inspect!("hello".trim_end(['o']), content="hell")
  inspect!("hello".trim_end(['l', 'o']), content="he")
  inspect!("hello".trim_end(['x']), content="hello")
  inspect!("hello".trim_end([]), content="hello")
  inspect!("".trim_end(['a']), content="")
  inspect!("hello   ".trim_end([' ']), content="hello")
  inspect!("hello world".trim_end(['d', 'l', 'r', 'o', 'w', ' ']), content="he")
  inspect!("hello😀😀".trim_end(['😀']), content="hello")
  inspect!("hello😀😃".trim_end(['😀', '😃']), content="hello")
  inspect!("abcccc".trim_end(['c']), content="ab")
  inspect!("cccc".trim_end(['c']), content="")
}

///|
/// Returns the view of the string without the leading and trailing characters
/// that are in the given string.
pub fn View::trim(self : View, char_set : View) -> View {
  self.trim_left(char_set).trim_right(char_set)
}

///|
test "trim" {
  inspect!("hello".trim(['h']), content="ello")
  inspect!("hello".trim(['o']), content="hell")
  inspect!("hello".trim(['h', 'o']), content="ell")
  inspect!("hello".trim(['o', 'h']), content="ell")
  inspect!("hello".trim(['x']), content="hello")
  inspect!("hello".trim([]), content="hello")
  inspect!("".trim(['a']), content="")
  inspect!("   hello   ".trim([' ']), content="hello")
  inspect!("hello world".trim(['h', 'd']), content="ello worl")
  inspect!("😀hello😀".trim(['😀']), content="hello")
  inspect!("😀😃hello😀😃".trim(['😀', '😃']), content="hello")
  inspect!("aaaabcaaa".trim(['a']), content="bc")
  inspect!("aaaa".trim(['a']), content="")
  inspect!("  hello world  ".trim([' ']), content="hello world")
  inspect!("abcabc".trim(['a', 'b', 'c']), content="")
}

///| 
/// Returns the view of the string without the leading and trailing spaces.
pub fn View::trim_space(self : View) -> View {
  self.trim(" \n\r\t".view())
}

// todo: add the method `trim_space` for String when the deprecated `trim_space`
// is removed

///|
test "trim_space" {
  inspect!("hello".trim_space(), content="hello")
  inspect!("  hello  ".trim_space(), content="hello")
  inspect!("hello  ".trim_space(), content="hello")
  inspect!("  hello".trim_space(), content="hello")
  inspect!("\t\nhello\r\n".trim_space(), content="hello")
  inspect!("  hello world  ".trim_space(), content="hello world")
  inspect!("  ".trim_space(), content="")
  inspect!("\n\r\t".trim_space(), content="")
  inspect!("".trim_space(), content="")
  inspect!("  hello\nworld\t".trim_space(), content="hello\nworld")
}

///|
/// Returns true if this string is empty.
pub fn View::is_empty(self : View) -> Bool {
  self.len() == 0
}

///|
/// Returns true if this string is empty.
pub fn String::is_empty(self : String) -> Bool {
  self == ""
}

///|
#deprecated("Use `str.is_empty()` instead.")
pub fn is_empty(str : String) -> Bool {
  str.is_empty()
}

///|
test "is_empty" {
  inspect!("".is_empty(), content="true")
  inspect!("hello".is_empty(), content="false")
  inspect!(" ".is_empty(), content="false")
  inspect!("\n".is_empty(), content="false")
  inspect!("\t".is_empty(), content="false")
  inspect!("   ".is_empty(), content="false")

  // Test with string views
  let s = "hello"
  let empty_view = s[0:0]
  let non_empty_view = s[0:3]
  inspect!(empty_view.is_empty(), content="true")
  inspect!(non_empty_view.is_empty(), content="false")
}

///|
/// Returns true if this string is blank.
pub fn View::is_blank(self : View) -> Bool {
  self.trim_space().is_empty()
}

///|
/// Returns true if this string is blank.
pub fn String::is_blank(self : String) -> Bool {
  self.view().is_blank()
}

///|
#deprecated("Use `str.is_blank()` instead.")
pub fn is_blank(str : String) -> Bool {
  str.is_blank()
}

///|
test "is_blank" {
  inspect!("".is_blank(), content="true")
  inspect!("hello".is_blank(), content="false")
  inspect!(" ".is_blank(), content="true")
  inspect!("\n".is_blank(), content="true")
  inspect!("\t".is_blank(), content="true")
  inspect!("   ".is_blank(), content="true")
  inspect!(" \n\t\r ".is_blank(), content="true")
  inspect!("hello world".is_blank(), content="false")
  inspect!("  hello  ".is_blank(), content="false")

  // Test with string views
  let s = "   hello  "
  let blank_view = s[0:3] // "   "
  let non_blank_view = s[3:8] // "hello"
  inspect!(blank_view.is_blank(), content="true")
  inspect!(non_blank_view.is_blank(), content="false")
}

///|
/// Returns a new string with `padding_char`s prefixed to `self` if
/// `self.char_length() < total_width`. The number of unicode characters in
/// the returned string is `total_width` if padding is added.
pub fn View::pad_start(
  self : View,
  total_width : Int,
  padding_char : Char
) -> View {
  let len = self.char_length()
  guard len < total_width else { return self }
  let padding = String::make(total_width - len, padding_char)
  [..padding, ..self]
}

// todo: add the method `pad_start` for String when the deprecated `pad_start` is
// removed

///|
test "pad_start" {
  // Test with regular strings
  inspect!("2".pad_start(3, '0'), content="002")
  inspect!("abc".pad_start(5, 'x'), content="xxabc")
  inspect!("hello".pad_start(4, ' '), content="hello") // No padding needed
  inspect!("".pad_start(3, '-'), content="---")

  // Test with different padding characters
  inspect!("test".pad_start(8, '*'), content="****test")
  inspect!("123".pad_start(6, '0'), content="000123")

  // Test with string views
  let s = "hello"
  let view = s[2:5] // "llo"
  inspect!(view.pad_start(5, 'x'), content="xxllo")

  // Test with Unicode characters
  inspect!("🌟".pad_start(3, '✨'), content="✨✨🌟")

  // Edge cases
  inspect!("abc".pad_start(0, 'x'), content="abc") // width less than string length
  inspect!("abc".pad_start(3, 'x'), content="abc") // width equal to string length
}

///|
/// Returns a new string with `padding_char`s appended to `self` if
/// `self.length() < total_width`. The number of unicode characters in
/// the returned string is `total_width` if padding is added.
pub fn View::pad_end(
  self : View,
  total_width : Int,
  padding_char : Char
) -> View {
  let len = self.char_length()
  guard len < total_width else { return self }
  let padding = String::make(total_width - len, padding_char)
  [..self, ..padding]
}

// todo: add the method `pad_end` for String when the deprecated `pad_end` is
// removed

///|
test "pad_end" {
  // Test with regular strings
  inspect!("2".pad_end(3, '0'), content="200")
  inspect!("abc".pad_end(5, 'x'), content="abcxx")
  inspect!("hello".pad_end(4, ' '), content="hello") // No padding needed
  inspect!("".pad_end(3, '-'), content="---")

  // Test with different padding characters
  inspect!("test".pad_end(8, '*'), content="test****")
  inspect!("123".pad_end(6, '0'), content="123000")

  // Test with string views
  let s = "hello"
  let view = s[2:5] // "llo"
  inspect!(view.pad_end(5, 'x'), content="lloxx")

  // Test with Unicode characters
  inspect!("🌟".pad_end(3, '✨'), content="🌟✨✨")

  // Edge cases
  inspect!("abc".pad_end(0, 'x'), content="abc") // width less than string length
  inspect!("abc".pad_end(3, 'x'), content="abc") // width equal to string length
}

///|
/// Returns a new string with `self` repeated `n` times.
pub fn View::repeat(self : View, n : Int) -> View {
  match n {
    _..=0 => ""
    1 => self
    _ => {
      let len = self.len()
      let buf = StringBuilder::new(size_hint=len * n)
      let str = self.to_string()
      for _ in 0..<n {
        buf.write_string(str)
      }
      buf.to_string()
    }
  }
}

///|
test "repeat" {
  // Test with regular strings
  inspect!("abc".repeat(3), content="abcabcabc")
  inspect!("x".repeat(5), content="xxxxx")
  inspect!("hello ".repeat(2), content="hello hello ")

  // Test with empty string
  inspect!("".repeat(10), content="")

  // Test with string views
  let s = "hello world"
  let view = s[6:11] // "world"
  inspect!(view.repeat(2), content="worldworld")

  // Test with Unicode characters
  inspect!("🌟".repeat(3), content="🌟🌟🌟")
  inspect!("✨🌟".repeat(2), content="✨🌟✨🌟")

  // Edge cases
  inspect!("abc".repeat(0), content="")
  inspect!("abc".repeat(-5), content="")
  inspect!("abc".repeat(1), content="abc")
}

///|
/// Returns a new string with the characters in reverse order. It respects
/// Unicode characters and surrogate pairs but not grapheme clusters.
pub fn View::rev(self : View) -> View {
  let buf = StringBuilder::new(size_hint=self.len())
  for c in self.rev_iter() {
    buf.write_char(c)
  }
  buf.to_string()
}

///|
test "rev" {
  inspect!("hello".rev(), content="olleh")
  inspect!("".rev(), content="")
  inspect!("abc".rev(), content="cba")
  inspect!("😀😃".rev(), content="😃😀")
}

///|
/// Splits the string into all substrings separated by the given separator.
/// 
/// If the string does not contain the separator and the separator is not empty,
/// the returned iterator will contain only one element, which is the original
/// string.
/// 
/// If the separator is empty, the returned iterator will contain all the
/// characters in the string as single elements.
pub fn View::split(self : View, sep : View) -> Iter[View] {
  let sep_len = sep.len()
  if sep_len == 0 {
    return self.iter().map(fn(c) { [c] })
  }
  Iter::new(fn(yield_) {
    let mut view = self
    while view.find(sep) is Some(end) {
      guard yield_(view.view(end_offset=end)) is IterContinue else {
        break IterEnd
      }
      view = view.view(start_offset=end + sep_len)
    } else {
      if view.is_empty() {
        IterContinue
      } else {
        yield_(view)
      }
    }
  })
}

///|
test "split" {
  assert_eq!("a,b,c".split(",").collect(), ["a", "b", "c"])
  assert_eq!("a,b,c".split("").collect(), ["a", ",", "b", ",", "c"])
  assert_eq!("apple::orange::banana".split("::").collect(), [
    "apple", "orange", "banana",
  ])
  assert_eq!("abc".split("").collect(), ["a", "b", "c"])
  assert_eq!("hello".split(",").collect(), ["hello"])
  assert_eq!(",a,b,c".split(",").collect(), ["", "a", "b", "c"])
  assert_eq!("a,b,c,".split(",").collect(), ["a", "b", "c"])
  assert_eq!("a,b,c".split("").collect(), ["a", ",", "b", ",", "c"])
  assert_eq!("".split("").collect(), [])
  assert_eq!("".split(",").collect(), [])
  assert_eq!("😀,😃,😄".split(",").collect(), ["😀", "😃", "😄"])
  assert_eq!("a😀b😀c".split("😀").collect(), ["a", "b", "c"])
}

///|
/// Replaces the first occurrence of `old` with `new` in `self`.
/// 
/// If `old` is empty, it matches the beginning of the string, and `new` is
/// prepended to the string.
pub fn View::replace(self : View, old~ : View, new~ : View) -> View {
  match self.find(old) {
    Some(end) =>
      [
        ..self.view(end_offset=end),
        ..new,
        ..self.view(start_offset=end + old.len()),
      ]
    None => self
  }
}

///|
test "replace" {
  assert_eq!("hello".replace(old="o", new="a"), "hella")
  assert_eq!("hello".replace(old="l", new="a"), "healo")
  assert_eq!("hello".replace(old="hello", new="a"), "a")
  assert_eq!("hello".replace(old="h", new="a"), "aello")
  assert_eq!("hello".replace(old="", new="a"), "ahello")
  assert_eq!("hello".replace(old="world", new="a"), "hello")
  assert_eq!("".replace(old="", new="a"), "a")
}

///|
/// Replaces all non-overlapping occurrences of `old` with `new` in `self`.
/// 
/// If `old` is empty, it matches at the beginning of the string and after each
/// character in the string, so `new` is inserted at the beginning of the string
/// and after each character.
pub fn View::replace_all(self : View, old~ : View, new~ : View) -> View {
  let buf = StringBuilder::new(size_hint=self.len())
  let len = self.len()
  let old_len = old.len()
  // todo: improve performance
  if old_len == 0 {
    buf.write_string(new.to_string())
    self
    .iter()
    .each(fn(c) {
      buf.write_char(c)
      buf.write_string(new.to_string())
    })
  } else {
    let mut view = self
    while view.find(old) is Some(end) {
      buf.write_string(view.view(end_offset=end).to_string())
      buf.write_string(new.to_string())
      if end + old_len <= len {
        view = view.view(start_offset=end + old_len)
      } else {
        break
      }
    }
    buf.write_string(view.to_string())
  }
  buf.to_string()
}

///|
test "replace_all" {
  assert_eq!("hello".replace_all(old="o", new="a"), "hella")
  assert_eq!("hello".replace_all(old="l", new="a"), "heaao")
  assert_eq!("hello".replace_all(old="ll", new="rr"), "herro")
  assert_eq!("hello".replace_all(old="hello", new="world"), "world")
  assert_eq!("hello hello hello".replace_all(old="hello", new="hi"), "hi hi hi")
  assert_eq!("hello".replace_all(old="", new="a"), "ahaealalaoa")
  assert_eq!("hello".replace_all(old="world", new="a"), "hello")
  assert_eq!("".replace_all(old="", new="a"), "a")
  assert_eq!("aaa".replace_all(old="a", new="b"), "bbb")
  assert_eq!("aaa".replace_all(old="a", new="bb"), "bbbbbb")
  assert_eq!("aaa".replace_all(old="aa", new="b"), "ba")
  assert_eq!("🤣🤣🤣".replace_all(old="🤣", new="😊"), "😊😊😊")
  assert_eq!("abc123abc".replace_all(old="abc", new="xyz"), "xyz123xyz")
  assert_eq!("abcabcabc".replace_all(old="abc", new=""), "")
  assert_eq!("abc".replace_all(old="abc", new=""), "")
  assert_eq!("abc".replace_all(old="", new="x"), "xaxbxcx")
}

///|
/// Converts this string to lowercase.
pub fn View::to_lower(self : View) -> View {
  // TODO: deal with non-ascii characters
  let buf = StringBuilder::new(size_hint=self.len())
  for c in self {
    if c >= 'A' && c <= 'Z' {
      buf.write_char(Char::from_int(c.to_int() + 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
test "to_lower" {
  assert_eq!("Hello".to_lower(), "hello")
  assert_eq!("HELLO".to_lower(), "hello")
  assert_eq!("Hello, World!".to_lower(), "hello, world!")
}

///|
/// Converts this string to uppercase.
pub fn View::to_upper(self : View) -> View {
  // TODO: deal with non-ascii characters
  let buf = StringBuilder::new(size_hint=self.len())
  for c in self {
    if c >= 'a' && c <= 'z' {
      buf.write_char(Char::from_int(c.to_int() - 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
test "to_upper" {
  assert_eq!("hello".to_upper(), "HELLO")
  assert_eq!("HELLO".to_upper(), "HELLO")
  assert_eq!("Hello, World!".to_upper(), "HELLO, WORLD!")
}

///|
/// Folds the characters of the string into a single value.
pub fn View::fold[A](self : View, init~ : A, f : (A, Char) -> A) -> A {
  let mut rv = init
  for c in self {
    rv = f(rv, c)
  }
  rv
}

///| Folds the characters of the string into a single value.
pub fn String::fold[A](self : String, init~ : A, f : (A, Char) -> A) -> A {
  self.view().fold(init~, f)
}

///|
#deprecated("Use `str.fold(init~, f)` instead.")
pub fn fold[A](s : String, init~ : A, f : (A, Char) -> A) -> A {
  s.view().fold(init~, f)
}

///|
test "fold" {
  assert_eq!("hello".fold(init=[], fn(acc, c) { acc..push(c) }), [
    'h', 'e', 'l', 'l', 'o',
  ])
  assert_eq!(
    "hello".fold(init=0, fn(acc, c) { acc + c.to_int() }),
    104 + 101 + 108 + 108 + 111,
  )
}

///|
pub fn View::rev_fold[A](self : View, init~ : A, f : (A, Char) -> A) -> A {
  let mut rv = init
  for c in self.rev_iter() {
    rv = f(rv, c)
  }
  rv
}

///|
pub fn String::rev_fold[A](self : String, init~ : A, f : (A, Char) -> A) -> A {
  self.view().rev_fold(init~, f)
}

///|
#deprecated("Use `str.rev_fold(init~, f)` instead.")
pub fn rev_fold[A](s : String, init~ : A, f : (A, Char) -> A) -> A {
  s.view().rev_fold(init~, f)
}

///|
test "rev_fold" {
  assert_eq!("hello".rev_fold(init=[], fn(acc, c) { acc..push(c) }), [
    'o', 'l', 'l', 'e', 'h',
  ])
  assert_eq!(
    "hello".rev_fold(init=0, fn(acc, c) { acc + c.to_int() }),
    111 + 108 + 108 + 101 + 104,
  )
}
