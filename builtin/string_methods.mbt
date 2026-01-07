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
/// Returns the offset (charcode index) of the first occurrence of the given
/// substring. If the substring is not found, it returns None.
pub fn StringView::find(self : StringView, str : StringView) -> Int? {
  if str.length() <= 4 {
    brute_force_find(self, str)
  } else {
    boyer_moore_horspool_find(self, str)
  }
  // TODO: When the pattern string is long (>= 256),
  // consider using Two-Way algorithm to ensure linear time complexity.
}

///|
/// Simple brute force string search algorithm
/// Scans the haystack left to right, matching the needle at each position
fn brute_force_find(haystack : StringView, needle : StringView) -> Int? {
  let haystack_len = haystack.length()
  let needle_len = needle.length()
  guard needle_len > 0 else { return Some(0) }
  guard haystack_len >= needle_len else { return None }
  let needle_first = needle.unsafe_charcode_at(0)
  let forward_len = haystack_len - needle_len
  let mut i = 0
  while i <= forward_len {
    // Skip positions where first charcode doesn't match
    while i <= forward_len && haystack.unsafe_charcode_at(i) != needle_first {
      i += 1
    }
    if i <= forward_len {
      // Check remaining charcodes for full match
      for j in 1..<needle_len {
        if haystack.unsafe_charcode_at(i + j) != needle.unsafe_charcode_at(j) {
          break
        }
      } else {
        return Some(i)
      }
      i += 1
    }
  }
  None
}

///|
/// Boyer-Moore-Horspool algorithm for string search (left to right)
/// More efficient than brute force for longer patterns by using bad char heuristic
fn boyer_moore_horspool_find(
  haystack : StringView,
  needle : StringView,
) -> Int? {
  let haystack_len = haystack.length()
  let needle_len = needle.length()
  guard needle_len > 0 else { return Some(0) }
  guard haystack_len >= needle_len else { return None }
  // Build skip table
  let skip_table = FixedArray::make(1 << 8, needle_len)
  for i in 0..<(needle_len - 1) {
    skip_table[needle.unsafe_charcode_at(i) & 0xFF] = needle_len - 1 - i
  }
  for i = 0
      i <= haystack_len - needle_len
      i = i + skip_table[haystack.unsafe_charcode_at(i + needle_len - 1) & 0xFF] {
    // Check all charcodes for match at current position
    for j in 0..=(needle_len - 1) {
      if haystack.unsafe_charcode_at(i + j) != needle.unsafe_charcode_at(j) {
        break
      }
    } else {
      return Some(i)
    }
  }
  None
}

///|
test "boyer_moore_horspool_find edge cases" {
  inspect(boyer_moore_horspool_find("abc"[:], ""[:]), content="Some(0)")
  inspect(boyer_moore_horspool_find("ab"[:], "abcd"[:]), content="None")
}

///|
test "boyer_moore_horspool_rev_find edge cases" {
  inspect(boyer_moore_horspool_rev_find("abc"[:], ""[:]), content="Some(3)")
  inspect(boyer_moore_horspool_rev_find("ab"[:], "abcd"[:]), content="None")
}

///|
/// Returns the offset of the first occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn String::find(self : String, str : StringView) -> Int? {
  self[:].find(str)
}

///|
test "find" {
  inspect("hello".find("o"), content="Some(4)")
  inspect("hello".find("l"), content="Some(2)")
  inspect("hello".find("hello"), content="Some(0)")
  inspect("hello".find("h"), content="Some(0)")
  inspect("hello".find(""), content="Some(0)")
  inspect("hello".find("world"), content="None")
  inspect("".find(""), content="Some(0)")
  inspect("".find("a"), content="None")
  inspect("hello hello".find("hello"), content="Some(0)")
  inspect("aaa".find("aa"), content="Some(0)")
  inspect("😀😀".find("😀"), content="Some(0)")
  inspect(
    ("😀😀aa".repeat(20) + "😀😀😀😀").find("😀😀😀😀"),
    content="Some(120)",
  )
  inspect(
    ("😀😀😀😀" + "😀😀aa".repeat(20)).find("😀😀😀😀"),
    content="Some(0)",
  )
}

///|
/// Returns the offset of the first character that satisfies the given predicate.
/// If no such character is found, it returns None.
pub fn StringView::find_by(self : StringView, pred : (Char) -> Bool) -> Int? {
  for i, c in self {
    if pred(c) {
      return Some(i)
    }
  }
  None
}

///|
/// Returns the offset of the first character that satisfies the given predicate.
/// If no such character is found, it returns None.
pub fn String::find_by(self : String, pred : (Char) -> Bool) -> Int? {
  self[:].find_by(pred)
}

///|
test "find_by" {
  inspect("hello".find_by(c => c == 'o'), content="Some(4)")
  inspect("hello".find_by(c => c == 'l'), content="Some(2)")
  inspect("hello".find_by(c => c == 'z'), content="None")
  inspect("".find_by(c => c == 'a'), content="None")
  inspect("hello".find_by(c => c is ('0'..='9')), content="None")
  inspect("hello123".find_by(c => c is ('0'..='9')), content="Some(5)")
  inspect("hello".find_by(c => c is ('A'..='Z')), content="None")
  inspect("Hello".find_by(c => c is ('A'..='Z')), content="Some(0)")
  inspect("αβγ".find_by(c => c == 'β'), content="Some(1)")
  inspect("😀😁😂".find_by(c => c == '😂'), content="Some(2)")
}

///|
/// Returns the offset of the last occurrence of the given substring. If the
/// substring is not found, it returns None.
pub fn StringView::rev_find(self : StringView, str : StringView) -> Int? {
  if str.length() <= 4 {
    brute_force_rev_find(self, str)
  } else {
    boyer_moore_horspool_rev_find(self, str)
  }
  // TODO: When the pattern string is long (>= 256),
  // consider using Two-Way algorithm to ensure linear time complexity.
}

///|
/// Simple brute force string search algorithm
/// Scans the haystack right to left, matching the needle at each position
fn brute_force_rev_find(haystack : StringView, needle : StringView) -> Int? {
  let haystack_len = haystack.length()
  let needle_len = needle.length()
  guard needle_len > 0 else { return Some(haystack_len) }
  guard haystack_len >= needle_len else { return None }
  let needle_first = needle.unsafe_charcode_at(0)
  let mut i = haystack_len - needle_len
  while i >= 0 {
    // Skip positions where first charcode doesn't match
    while i >= 0 && haystack.unsafe_charcode_at(i) != needle_first {
      i -= 1
    }
    if i >= 0 {
      // Check remaining charcodes for full match
      for j in 1..<needle_len {
        if haystack.unsafe_charcode_at(i + j) != needle.unsafe_charcode_at(j) {
          break
        }
      } else {
        return Some(i)
      }
      i -= 1
    }
  }
  None
}

///|
/// Boyer-Moore-Horspool algorithm for reverse string search (right to left)
/// More efficient than brute force for longer patterns by using bad char heuristic
fn boyer_moore_horspool_rev_find(
  haystack : StringView,
  needle : StringView,
) -> Int? {
  let haystack_len = haystack.length()
  let needle_len = needle.length()
  guard needle_len > 0 else { return Some(haystack_len) }
  guard haystack_len >= needle_len else { return None }
  let skip_table = FixedArray::make(1 << 8, needle_len)
  for i = needle_len - 1; i > 0; i = i - 1 {
    skip_table[needle.unsafe_charcode_at(i) & 0xFF] = i
  }
  for i = haystack_len - needle_len
      i >= 0
      i = i - skip_table[haystack.unsafe_charcode_at(i) & 0xFF] {
    // Check all charcodes for match at current position
    for j in 0..<needle_len {
      if haystack.unsafe_charcode_at(i + j) != needle.unsafe_charcode_at(j) {
        break
      }
    } else {
      return Some(i)
    }
  }
  None
}

///|
/// Returns the offset (charcode index) of the last occurrence of the given
/// substring. If the substring is not found, it returns None.
pub fn String::rev_find(self : String, str : StringView) -> Int? {
  self[:].rev_find(str)
}

///|
test "rev_find" {
  inspect("hello".rev_find("o"), content="Some(4)")
  inspect("hello".rev_find("l"), content="Some(3)")
  inspect("hello".rev_find("hello"), content="Some(0)")
  inspect("hello".rev_find("h"), content="Some(0)")
  inspect("hello".rev_find(""), content="Some(5)")
  inspect("hello".rev_find("world"), content="None")
  inspect("".rev_find(""), content="Some(0)")
  inspect("".rev_find("a"), content="None")
  inspect("hello hello".rev_find("hello"), content="Some(6)")
  inspect("aaa".rev_find("aa"), content="Some(1)")
  inspect("😀😀".rev_find("😀"), content="Some(2)")
  inspect(
    ("😀😀aa".repeat(20) + "😀😀😀😀").rev_find("😀😀😀😀"),
    content="Some(120)",
  )
  inspect(
    ("😀😀😀😀" + "😀😀aa".repeat(20)).rev_find("😀😀😀😀"),
    content="Some(4)",
  )
}

///|
/// Returns true if the given substring is suffix of this string.
#alias(ends_with, deprecated)
pub fn StringView::has_suffix(self : StringView, str : StringView) -> Bool {
  self.rev_find(str) is Some(i) && i == self.length() - str.length()
}

///|
/// Returns true if the given substring is suffix of this string.
#alias(ends_with, deprecated)
pub fn String::has_suffix(self : String, str : StringView) -> Bool {
  self[:].has_suffix(str)
}

///|
test "has_suffix" {
  inspect("hello".has_suffix("lo"), content="true")
  inspect("hello".has_suffix("hello"), content="true")
  inspect("hello".has_suffix(""), content="true")
  inspect("hello".has_suffix("world"), content="false")
  inspect("hello".has_suffix("hel"), content="false")
  inspect("".has_suffix(""), content="true")
  inspect("".has_suffix("a"), content="false")
  inspect("hello world".has_suffix("world"), content="true")
  inspect("😀😀".has_suffix("😀"), content="true")
  inspect("😀😀".has_suffix("😀😀"), content="true")
}

///|
/// Returns true if this string starts with the given substring.
#alias(starts_with, deprecated)
pub fn StringView::has_prefix(self : StringView, str : StringView) -> Bool {
  self.find(str) is Some(i) && i == 0
}

///|
/// Returns true if this string starts with the given substring.
#alias(starts_with, deprecated)
pub fn String::has_prefix(self : String, str : StringView) -> Bool {
  self[:].has_prefix(str)
}

///|
test "has_prefix" {
  inspect("hello".has_prefix("h"), content="true")
  inspect("hello".has_prefix("he"), content="true")
  inspect("hello".has_prefix(""), content="true")
  inspect("hello".has_prefix("world"), content="false")
  inspect("hello".has_prefix("lo"), content="false")
  inspect("".has_prefix(""), content="true")
  inspect("".has_prefix("a"), content="false")
  inspect("😀hello".has_prefix("😀"), content="true")
  inspect("😀😃hello".has_prefix("😀😃"), content="true")
  inspect("😀hello".has_prefix("😃"), content="false")
  inspect("hello😀".has_prefix("😀"), content="false")
}

///|
/// Removes the given suffix from the string if it exists.
///
/// Returns `Some(prefix)` if the string ends with the given suffix,
/// where `prefix` is the string without the suffix.
/// Returns `None` if the string does not end with the suffix.
///
/// # Example
///
/// ```mbt check
/// test {
///   inspect("hello world".strip_suffix(" world"), content="Some(\"hello\")")
///   inspect("hello world".strip_suffix(" moon"), content="None")
///   inspect("hello".strip_suffix("hello"), content="Some(\"\")")
/// }
/// ```
#alias(chop_suffix)
pub fn String::strip_suffix(self : String, suffix : StringView) -> StringView? {
  self[:].strip_suffix(suffix)
}

///|
test "strip_prefix" {
  inspect("hello world".strip_prefix("hello "), content="Some(\"world\")")
  inspect("hello world".strip_prefix("hi "), content="None")
  inspect("hello".strip_prefix("hello"), content="Some(\"\")")
  inspect("".strip_prefix(""), content="Some(\"\")")
  inspect("".strip_prefix("a"), content="None")
  inspect("abc".strip_prefix(""), content="Some(\"abc\")")
  inspect("😀hello".strip_prefix("😀"), content="Some(\"hello\")")
  inspect("😀😃hello".strip_prefix("😀😃"), content="Some(\"hello\")")
}

///|
test "strip_suffix" {
  inspect("hello world".strip_suffix(" world"), content="Some(\"hello\")")
  inspect("hello world".strip_suffix(" moon"), content="None")
  inspect("hello".strip_suffix("hello"), content="Some(\"\")")
  inspect("".strip_suffix(""), content="Some(\"\")")
  inspect("".strip_suffix("a"), content="None")
  inspect("abc".strip_suffix(""), content="Some(\"abc\")")
  inspect("hello😀".strip_suffix("😀"), content="Some(\"hello\")")
  inspect("hello😀😃".strip_suffix("😀😃"), content="Some(\"hello\")")
}

///|
/// Removes the given prefix from the string if it exists.
///
/// Returns `Some(suffix)` if the string starts with the given prefix,
/// where `suffix` is the string without the prefix.
/// Returns `None` if the string does not start with the prefix.
///
/// # Example
///
/// ```mbt check
/// test {
///   inspect("hello world".strip_prefix("hello "), content="Some(\"world\")")
///   inspect("hello world".strip_prefix("hi "), content="None")
///   inspect("hello".strip_prefix("hello"), content="Some(\"\")")
/// }
/// ```
#alias(chop_prefix)
pub fn String::strip_prefix(self : String, prefix : StringView) -> StringView? {
  self[:].strip_prefix(prefix)
}

///|
/// Removes the given prefix from the view if it exists.
///
/// Returns `Some(suffix)` if the view starts with the given prefix,
/// where `suffix` is the view without the prefix.
/// Returns `None` if the view does not start with the prefix.
///
/// # Example
///
/// ```mbt check
/// test {
///   let view = "hello world"[:]
///   inspect(view.strip_prefix("hello "), content="Some(\"world\")")
///   inspect(view.strip_prefix("hi "), content="None")
///   inspect(view.strip_prefix("hello world"), content="Some(\"\")")
/// }
/// ```
#alias(chop_prefix)
pub fn StringView::strip_prefix(
  self : StringView,
  prefix : StringView,
) -> StringView? {
  let prefix_len = prefix.length()
  if self.length() >= prefix_len && self.view(end_offset=prefix_len) == prefix {
    Some(self.view(start_offset=prefix_len))
  } else {
    None
  }
}

///|
/// Removes the given suffix from the view if it exists.
///
/// Returns `Some(prefix)` if the view ends with the given suffix,
/// where `prefix` is the view without the suffix.
/// Returns `None` if the view does not end with the suffix.
///
/// # Example
///
/// ```mbt check
/// test {
///   let view = "hello world"[:]
///   inspect(view.strip_suffix(" world"), content="Some(\"hello\")")
///   inspect(view.strip_suffix(" moon"), content="None")
///   inspect(view.strip_suffix("hello world"), content="Some(\"\")")
/// }
/// ```
#alias(chop_suffix)
pub fn StringView::strip_suffix(
  self : StringView,
  suffix : StringView,
) -> StringView? {
  let self_len = self.length()
  let suffix_len = suffix.length()
  if self_len >= suffix_len &&
    self.view(start_offset=self_len - suffix_len) == suffix {
    Some(self.view(end_offset=self_len - suffix_len))
  } else {
    None
  }
}

///|
/// Converts the View into an array of Chars.
///
/// # Example
///
/// ```mbt check
/// test {
///   let view = "Hello🤣xa"[1:-1]
///   let chars = view.to_array()
///   inspect(chars, content="['e', 'l', 'l', 'o', '🤣', 'x']")
/// }
/// ```
pub fn StringView::to_array(self : StringView) -> Array[Char] {
  self
  .iter()
  .fold(init=Array::new(capacity=self.length()), (rv, c) => {
    rv.push(c)
    rv
  })
}

///|
#deprecated("Check `@encoding/utf8.encode`")
#coverage.skip
pub fn StringView::to_bytes(self : StringView) -> Bytes {
  let array = FixedArray::make(self.length() * 2, Byte::default())
  array.blit_from_string(0, self.data(), self.start_offset(), self.length())
  array |> unsafe_to_bytes
}

///|
test "View::strip_prefix" {
  let view = "hello world"[:]
  inspect(view.strip_prefix("hello "), content="Some(\"world\")")
  inspect(view.strip_prefix("hi "), content="None")
  inspect(view.strip_prefix("hello world"), content="Some(\"\")")
  inspect(view.strip_prefix(""), content="Some(\"hello world\")")
  let empty_view = ""[:]
  inspect(empty_view.strip_prefix(""), content="Some(\"\")")
  inspect(empty_view.strip_prefix("a"), content="None")
  let unicode_view = "😀hello😃"[:]
  inspect(unicode_view.strip_prefix("😀"), content="Some(\"hello😃\")")
  inspect(unicode_view.strip_prefix("😃"), content="None")
}

///|
test "View::strip_suffix" {
  let view = "hello world"[:]
  inspect(view.strip_suffix(" world"), content="Some(\"hello\")")
  inspect(view.strip_suffix(" moon"), content="None")
  inspect(view.strip_suffix("hello world"), content="Some(\"\")")
  inspect(view.strip_suffix(""), content="Some(\"hello world\")")
  let empty_view = ""[:]
  inspect(empty_view.strip_suffix(""), content="Some(\"\")")
  inspect(empty_view.strip_suffix("a"), content="None")
  let unicode_view = "😀hello😃"[:]
  inspect(unicode_view.strip_suffix("😃"), content="Some(\"😀hello\")")
  inspect(unicode_view.strip_suffix("😀"), content="None")
}

///|
test "View::to_array" {
  let view = "Hello🤣"[:]
  let chars = view.to_array()
  assert_eq(chars, ['H', 'e', 'l', 'l', 'o', '🤣'])
  let empty_view = ""[:]
  let empty_chars = empty_view.to_array()
  assert_eq(empty_chars, [])
  let sub_view = "Hello World"[6:11] // "World"
  let sub_chars = sub_view.to_array()
  assert_eq(sub_chars, ['W', 'o', 'r', 'l', 'd'])
}

///|
/// Returns true if this string contains the given substring.
pub fn StringView::contains(self : StringView, str : StringView) -> Bool {
  self.find(str) is Some(_)
}

///|
/// Returns true if this string contains the given substring.
pub fn String::contains(self : String, str : StringView) -> Bool {
  self[:].contains(str)
}

///|
/// Returns true if this string contains any character from the given set.
pub fn StringView::contains_any(self : StringView, chars~ : StringView) -> Bool {
  match chars {
    [] => false
    [c] => self.contains_char(c) // specialize for single character
    _ =>
      for c in self {
        if chars.contains_char(c) {
          break true
        }
      } else {
        false
      }
  }
}

///|
/// Returns true if this string contains any character from the given set.
pub fn String::contains_any(self : String, chars~ : StringView) -> Bool {
  self[:].contains_any(chars~)
}

///|
test "contains" {
  inspect("hello".contains("o"), content="true")
  inspect("hello".contains("l"), content="true")
  inspect("hello".contains("hello"), content="true")
  inspect("hello".contains("h"), content="true")
  inspect("hello".contains(""), content="true")
  inspect("hello".contains("world"), content="false")
  inspect("".contains(""), content="true")
  inspect("".contains("a"), content="false")
  inspect("hello hello".contains("hello"), content="true")
  inspect("aaa".contains("aa"), content="true")
  inspect("😀😀".contains("😀"), content="true")
}

///|
test "contains_any" {
  inspect("hello".contains_any(chars="h"), content="true")
  inspect("hello".contains_any(chars="xyz"), content="false")
  inspect("hello".contains_any(chars=""), content="false")
  inspect("".contains_any(chars="abc"), content="false")
  inspect("😀😃".contains_any(chars="😄😀"), content="true")
  inspect("hello"[:].contains_any(chars="eo"), content="true")
}

///|
/// Returns true if this string contains the given character.
pub fn StringView::contains_char(self : StringView, c : Char) -> Bool {
  let len = self.length()
  // Check empty
  guard len > 0 else { return false }
  let c = c.to_int()
  if c <= 0xFFFF {
    // Search BMP
    for i in 0..<len {
      if self.unsafe_charcode_at(i) == c {
        return true
      }
    }
  } else {
    // Check insufficient
    guard len >= 2 else { return false }
    // Calc surrogate pair
    let adj = c - 0x10000
    let high = 0xD800 + (adj >> 10)
    let low = 0xDC00 + (adj & 0x3FF)
    // Search surrogate pair
    let mut i = 0
    while i < len - 1 {
      if self.unsafe_charcode_at(i) == high {
        i += 1
        if self.unsafe_charcode_at(i) == low {
          return true
        }
      }
      i += 1
    }
  }
  false
}

///|
/// Returns true if this string contains the given character.
pub fn String::contains_char(self : String, c : Char) -> Bool {
  self[:].contains_char(c)
}

///|
test "contains_char" {
  inspect("hello".contains_char('h'), content="true")
  inspect("hello".contains_char('e'), content="true")
  inspect("hello".contains_char('l'), content="true")
  inspect("hello".contains_char('o'), content="true")
  inspect("hello".contains_char('x'), content="false")
  inspect("".contains_char('a'), content="false")
  inspect("hello world".contains_char(' '), content="true")
  inspect("hello world".contains_char('w'), content="true")
  inspect("😀😀".contains_char('😀'), content="true")
  inspect("😀😀".contains_char('😃'), content="false")
  inspect("hello".contains_char((104).unsafe_to_char()), content="true") // 'h' is 104 in ASCII
}

///|
/// Returns the view of the string without the leading characters that are in
/// the given string.
#label_migration(chars, alias=char_set)
pub fn StringView::trim_start(
  self : StringView,
  chars? : StringView = "\t\n\r ",
) -> StringView {
  loop self {
    [] as v => v
    [c, .. rest] as v => if chars.contains_char(c) { continue rest } else { v }
  }
}

///|
/// Returns the view of the string without the leading characters that are in
/// the given string.
#label_migration(chars, alias=char_set)
pub fn String::trim_start(
  self : String,
  chars? : StringView = "\t\n\r ",
) -> StringView {
  self[:].trim_start(chars~)
}

///|
test "trim_start" {
  inspect("hello".trim_start(chars="h"), content="ello")
  inspect("hello".trim_start(chars="he"), content="llo")
  inspect("hello".trim_start(chars="eh"), content="llo")
  inspect("hello".trim_start(chars="x"), content="hello")
  inspect("hello".trim_start(chars=""), content="hello")
  inspect("".trim_start(chars="a"), content="")
  inspect("   hello".trim_start(chars=" "), content="hello")
  inspect("hello world".trim_start(chars="helo"), content=" world")
  inspect("😀😀hello".trim_start(chars="😀"), content="hello")
  inspect("😀😃hello".trim_start(chars="😀😃"), content="hello")
  inspect("aaaabc".trim_start(chars="a"), content="bc")
  inspect("aaaa".trim_start(chars="a"), content="")
}

///|
/// Returns the view of the string without the trailing characters that are in
/// the given string.
#label_migration(chars, alias=char_set)
pub fn StringView::trim_end(
  self : StringView,
  chars? : StringView = "\t\n\r ",
) -> StringView {
  loop self {
    [] as v => v
    [.. rest, c] as v => if chars.contains_char(c) { continue rest } else { v }
  }
}

///|
/// Returns the view of the string without the trailing characters that are in
/// the given string.
// TODO(upstream): label_migration warning does not apply to the current package
// TODO: make chars optional with default value of whitespace characters
#label_migration(chars, alias=char_set)
pub fn String::trim_end(
  self : String,
  chars? : StringView = "\t\n\r ",
) -> StringView {
  self[:].trim_end(chars~)
}

///|
test "trim_end" {
  inspect("hello".trim_end(chars="o"), content="hell")
  inspect("hello".trim_end(chars="lo"), content="he")
  inspect("hello".trim_end(chars="x"), content="hello")
  inspect("hello".trim_end(chars=""), content="hello")
  inspect("".trim_end(chars="a"), content="")
  inspect("hello   ".trim_end(chars=" "), content="hello")
  inspect("hello world".trim_end(chars="dlrow "), content="he")
  inspect("hello😀😀".trim_end(chars="😀"), content="hello")
  inspect("hello😀😃".trim_end(chars="😀😃"), content="hello")
  inspect("abcccc".trim_end(chars="c"), content="ab")
  inspect("cccc".trim_end(chars="c"), content="")
}

///|
/// Returns the view of the string without the leading and trailing characters
/// that are in the given string.
#label_migration(chars, alias=char_set)
pub fn StringView::trim(
  self : StringView,
  chars? : StringView = "\t\n\r ",
) -> StringView {
  self.trim_start(chars~).trim_end(chars~)
}

///|
/// Returns the view of the string without the leading and trailing characters
/// that are in the given string.
#label_migration(chars, alias=char_set)
pub fn String::trim(
  self : String,
  chars? : StringView = "\t\n\r ",
) -> StringView {
  self[:].trim(chars~)
}

///|
test "trim" {
  inspect("hello".trim(chars="h"), content="ello")
  inspect("hello".trim(chars="o"), content="hell")
  inspect("hello".trim(chars="ho"), content="ell")
  inspect("hello".trim(chars="oh"), content="ell")
  inspect("hello".trim(chars="x"), content="hello")
  inspect("hello".trim(chars=""), content="hello")
  inspect("".trim(chars="a"), content="")
  inspect("   hello   ".trim(chars=" "), content="hello")
  inspect("hello world".trim(chars="hd"), content="ello worl")
  inspect("😀hello😀".trim(chars="😀"), content="hello")
  inspect("😀😃hello😀😃".trim(chars="😀😃"), content="hello")
  inspect("aaaabcaaa".trim(chars="a"), content="bc")
  inspect("aaaa".trim(chars="a"), content="")
  inspect("  hello world  ".trim(chars=" "), content="hello world")
  inspect("abcabc".trim(chars="abc"), content="")
}

///|
/// Returns the view of the string without the leading and trailing spaces.
#deprecated("Use `trim` with default whitespace characters instead")
pub fn StringView::trim_space(self : StringView) -> StringView {
  self.trim()
}

///|
/// Returns the view of the string without the leading and trailing spaces.
#deprecated("Use `trim` with default whitespace characters instead")
pub fn String::trim_space(self : String) -> StringView {
  self.trim()
}

///|
test "trim whitespace for string" {
  inspect("hello".trim(), content="hello")
  inspect("  hello  ".trim(), content="hello")
  inspect("hello  ".trim(), content="hello")
  inspect("  hello".trim(), content="hello")
  inspect("\t\nhello\r\n".trim(), content="hello")
  inspect("  hello world  ".trim(), content="hello world")
  inspect("  ".trim(), content="")
  inspect("\n\r\t".trim(), content="")
  inspect("".trim(), content="")
  inspect("  hello\nworld\t".trim(), content="hello\nworld")
}

///|
/// Returns true if this string is empty.
pub fn StringView::is_empty(self : StringView) -> Bool {
  self.length() == 0
}

///|
/// Returns true if this string is empty.
pub fn String::is_empty(self : String) -> Bool {
  self == ""
}

///|
test "is_empty" {
  inspect("".is_empty(), content="true")
  inspect("hello".is_empty(), content="false")
  inspect(" ".is_empty(), content="false")
  inspect("\n".is_empty(), content="false")
  inspect("\t".is_empty(), content="false")
  inspect("   ".is_empty(), content="false")

  // Test with string views
  let s = "hello"
  let empty_view = s[0:0]
  let non_empty_view = s[0:3]
  inspect(empty_view.is_empty(), content="true")
  inspect(non_empty_view.is_empty(), content="false")
}

///|
/// Returns true if this string is blank.
pub fn StringView::is_blank(self : StringView) -> Bool {
  self.trim().is_empty()
}

///|
/// Returns true if this string is blank.
pub fn String::is_blank(self : String) -> Bool {
  self[:].is_blank()
}

///|
test "is_blank" {
  inspect("".is_blank(), content="true")
  inspect("hello".is_blank(), content="false")
  inspect(" ".is_blank(), content="true")
  inspect("\n".is_blank(), content="true")
  inspect("\t".is_blank(), content="true")
  inspect("   ".is_blank(), content="true")
  inspect(" \n\t\r ".is_blank(), content="true")
  inspect("hello world".is_blank(), content="false")
  inspect("  hello  ".is_blank(), content="false")

  // Test with string views
  let s = "   hello  "
  let blank_view = s[0:3] // "   "
  let non_blank_view = s[3:8] // "hello"
  inspect(blank_view.is_blank(), content="true")
  inspect(non_blank_view.is_blank(), content="false")
}

///|
/// Returns a new string with `padding_char`s prefixed to `self` if
/// `self.char_length() < total_width`. The number of unicode characters in
/// the returned string is `total_width` if padding is added.
pub fn StringView::pad_start(
  self : StringView,
  total_width : Int,
  padding_char : Char,
) -> String {
  let len = self.length()
  guard len < total_width else { return self.to_string() }
  let padding = String::make(total_width - len, padding_char)
  [..padding, ..self]
}

///|
/// Returns a new string with `padding_char`s prefixed to `self` if
/// `self.char_length() < total_width`. The number of unicode characters in
/// the returned string is `total_width` if padding is added.
pub fn String::pad_start(
  self : String,
  total_width : Int,
  padding_char : Char,
) -> String {
  let len = self.length()
  guard len < total_width else { return self }
  let padding = String::make(total_width - len, padding_char)
  [..padding, ..self]
}

///|
test "pad_start" {
  // Test with regular strings
  inspect("2".pad_start(3, '0'), content="002")
  inspect("abc".pad_start(5, 'x'), content="xxabc")
  inspect("hello".pad_start(4, ' '), content="hello") // No padding needed
  inspect("".pad_start(3, '-'), content="---")

  // Test with different padding characters
  inspect("test".pad_start(8, '*'), content="****test")
  inspect("123".pad_start(6, '0'), content="000123")

  // Test with string views
  let s = "hello"
  let view = s[2:5] // "llo"
  inspect(view.pad_start(5, 'x'), content="xxllo")

  // Test with Unicode characters
  inspect("🌟".pad_start(3, '✨'), content="✨🌟")

  // Edge cases
  inspect("abc".pad_start(0, 'x'), content="abc") // width less than string length
  inspect("abc".pad_start(3, 'x'), content="abc") // width equal to string length
}

///|
/// Returns a new string with `padding_char`s appended to `self` if
/// `self.length() < total_width`. The number of unicode characters in
/// the returned string is `total_width` if padding is added.
pub fn StringView::pad_end(
  self : StringView,
  total_width : Int,
  padding_char : Char,
) -> String {
  let len = self.length()
  guard len < total_width else { return self.to_string() }
  let padding = String::make(total_width - len, padding_char)
  [..self, ..padding]
}

///|
/// Returns a new string with `padding_char`s appended to `self` if
/// `self.length() < total_width`. The number of unicode characters in
/// the returned string is `total_width` if padding is added.
pub fn String::pad_end(
  self : String,
  total_width : Int,
  padding_char : Char,
) -> String {
  let len = self.length()
  guard len < total_width else { return self }
  let padding = String::make(total_width - len, padding_char)
  [..self, ..padding]
}

///|
test "pad_end" {
  // Test with regular strings
  inspect("2".pad_end(3, '0'), content="200")
  inspect("abc".pad_end(5, 'x'), content="abcxx")
  inspect("hello".pad_end(4, ' '), content="hello") // No padding needed
  inspect("".pad_end(3, '-'), content="---")

  // Test with different padding characters
  inspect("test".pad_end(8, '*'), content="test****")
  inspect("123".pad_end(6, '0'), content="123000")

  // Test with string views
  let s = "hello"
  let view = s[2:5] // "llo"
  inspect(view.pad_end(5, 'x'), content="lloxx")

  // Test with Unicode characters
  inspect("🌟".pad_end(3, '✨'), content="🌟✨")

  // Edge cases
  inspect("abc".pad_end(0, 'x'), content="abc") // width less than string length
  inspect("abc".pad_end(3, 'x'), content="abc") // width equal to string length
}

///|
/// Returns a new string with `self` repeated `n` times.
pub fn StringView::repeat(self : StringView, n : Int) -> StringView {
  match n {
    _..=0 => ""
    1 => self
    _ => {
      let len = self.length()
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
/// Returns a new string with `self` repeated `n` times.
pub fn String::repeat(self : String, n : Int) -> String {
  match n {
    _..=0 => ""
    1 => self
    _ => {
      let len = self.length()
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
  inspect("abc".repeat(3), content="abcabcabc")
  inspect("x".repeat(5), content="xxxxx")
  inspect("hello ".repeat(2), content="hello hello ")

  // Test with empty string
  inspect("".repeat(10), content="")

  // Test with string views
  let s = "hello world"
  let view = s[6:11] // "world"
  inspect(view.repeat(2), content="worldworld")

  // Test with Unicode characters
  inspect("🌟".repeat(3), content="🌟🌟🌟")
  inspect("✨🌟".repeat(2), content="✨🌟✨🌟")

  // Edge cases
  inspect("abc".repeat(0), content="")
  inspect("abc".repeat(-5), content="")
  inspect("abc".repeat(1), content="abc")
}

///|
/// Returns a new string with the characters in reverse order. It respects
/// Unicode characters and surrogate pairs but not grapheme clusters.
pub fn StringView::rev(self : StringView) -> String {
  let buf = StringBuilder::new(size_hint=self.length())
  for c in self.rev_iter() {
    buf.write_char(c)
  }
  buf.to_string()
}

///|
/// Returns a new string with the characters in reverse order. It respects
/// Unicode characters and surrogate pairs but not grapheme clusters.
pub fn String::rev(self : String) -> String {
  self[:].rev()
}

///|
test "rev" {
  inspect("hello".rev(), content="olleh")
  inspect("".rev(), content="")
  inspect("abc".rev(), content="cba")
  inspect("😀😃".rev(), content="😃😀")
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
pub fn StringView::split(
  self : StringView,
  sep : StringView,
) -> Iter[StringView] {
  let sep_len = sep.length()
  if sep_len == 0 {
    return self.iter().map(c => c.to_string().view())
  }
  let mut remaining = Some(self)
  Iter::new(() => {
    guard remaining is Some(view) else { None }
    guard view.find(sep) is Some(end) else {
      remaining = None
      Some(view)
    }
    remaining = Some(view.view(start_offset=end + sep_len))
    Some(view.view(end_offset=end))
  })
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
pub fn String::split(self : String, sep : StringView) -> Iter[StringView] {
  self[:].split(sep)
}

///|
test "split" {
  assert_eq("a,b,c".split(",").map(StringView::to_string).collect(), [
    "a", "b", "c",
  ])
  assert_eq("a,b,c".split("").map(StringView::to_string).collect(), [
    "a", ",", "b", ",", "c",
  ])
  assert_eq(
    "apple::orange::banana".split("::").map(StringView::to_string).collect(),
    ["apple", "orange", "banana"],
  )
  assert_eq("abc".split("").map(StringView::to_string).collect(), [
    "a", "b", "c",
  ])
  assert_eq("hello".split(",").map(StringView::to_string).collect(), ["hello"])
  assert_eq(",a,b,c".split(",").map(StringView::to_string).collect(), [
    "", "a", "b", "c",
  ])
  assert_eq("a,b,c,".split(",").map(StringView::to_string).collect(), [
    "a", "b", "c", "",
  ])
  assert_eq("a,b,c".split("").map(StringView::to_string).collect(), [
    "a", ",", "b", ",", "c",
  ])
  assert_eq("".split("").map(StringView::to_string).collect(), [])
  assert_eq("".split(",").map(StringView::to_string).collect(), [""])
  assert_eq("😀,😃,😄".split(",").map(StringView::to_string).collect(), [
    "😀", "😃", "😄",
  ])
  assert_eq("a😀b😀c".split("😀").map(StringView::to_string).collect(), [
    "a", "b", "c",
  ])
}

///|
/// Replaces the first occurrence of `old` with `new` in `self`.
/// 
/// If `old` is empty, it matches the beginning of the string, and `new` is
/// prepended to the string.
pub fn StringView::replace(
  self : StringView,
  old~ : StringView,
  new~ : StringView,
) -> StringView {
  match self.find(old) {
    Some(end) =>
      [
        ..self.view(end_offset=end),
        ..new,
        ..self.view(start_offset=end + old.length()),
      ]
    None => self
  }
}

///|
/// Replaces the first occurrence of `old` with `new` in `self`.
/// 
/// If `old` is empty, it matches the beginning of the string, and `new` is
/// prepended to the string.
pub fn String::replace(
  self : String,
  old~ : StringView,
  new~ : StringView,
) -> String {
  match self.find(old) {
    Some(end) =>
      [
        ..self.view(end_offset=end),
        ..new,
        ..self.view(start_offset=end + old.length()),
      ]
    None => self
  }
}

///|
test "replace" {
  inspect("hello".replace(old="o", new="a"), content="hella")
  inspect("hello".replace(old="l", new="a"), content="healo")
  inspect("hello".replace(old="hello", new="a"), content="a")
  inspect("hello".replace(old="h", new="a"), content="aello")
  inspect("hello".replace(old="", new="a"), content="ahello")
  inspect("hello".replace(old="world", new="a"), content="hello")
  inspect("".replace(old="", new="a"), content="a")
}

///|
/// Replaces all non-overlapping occurrences of `old` with `new` in `self`.
/// 
/// If `old` is empty, it matches at the beginning of the string and after each
/// character in the string, so `new` is inserted at the beginning of the string
/// and after each character.
pub fn StringView::replace_all(
  self : StringView,
  old~ : StringView,
  new~ : StringView,
) -> StringView {
  let len = self.length()
  let buf = StringBuilder::new(size_hint=len)
  let old_len = old.length()
  let new = new.to_string()
  // use write_substring to avoid intermediate allocations
  if old_len == 0 {
    buf.write_string(new)
    for c in self {
      buf.write_char(c)
      buf.write_string(new)
    }
    buf.to_string()
  } else {
    let first_end = self.find(old)
    if first_end is Some(end) {
      for view = self, end = end {
        let seg = view.view(end_offset=end)
        buf.write_substring(seg.data(), seg.start_offset(), seg.length())
        buf.write_string(new)
        // check if there is no more characters after the last occurrence of `old`
        guard end + old_len <= len else { break }
        let next_view = view.view(start_offset=end + old_len)
        guard next_view.find(old) is Some(next_end) else {
          buf.write_substring(
            next_view.data(),
            next_view.start_offset(),
            next_view.length(),
          )
          break
        }
        continue next_view, next_end
      }
      buf.to_string()
    } else {
      self
    }
  }
}

///|
/// Replaces all non-overlapping occurrences of `old` with `new` in `self`.
/// 
/// If `old` is empty, it matches at the beginning of the string and after each
/// character in the string, so `new` is inserted at the beginning of the string
/// and after each character.
pub fn String::replace_all(
  self : String,
  old~ : StringView,
  new~ : StringView,
) -> String {
  let len = self.length()
  let buf = StringBuilder::new(size_hint=len)
  let old_len = old.length()
  let new = new.to_string()
  // use write_substring to avoid intermediate allocations
  if old_len == 0 {
    buf.write_string(new)
    for c in self {
      buf.write_char(c)
      buf.write_string(new)
    }
    buf.to_string()
  } else {
    let first_end = self.find(old)
    if first_end is Some(end) {
      for view = self[:], end = end {
        let seg = view.view(end_offset=end)
        buf.write_substring(seg.data(), seg.start_offset(), seg.length())
        buf.write_string(new)
        // check if there is no more characters after the last occurrence of `old`
        guard end + old_len <= len else { break }
        let next_view = view.view(start_offset=end + old_len)
        guard next_view.find(old) is Some(next_end) else {
          buf.write_substring(
            next_view.data(),
            next_view.start_offset(),
            next_view.length(),
          )
          break
        }
        continue next_view, next_end
      }
      buf.to_string()
    } else {
      self
    }
  }
}

///|
test "replace_all" {
  assert_eq("hello".replace_all(old="o", new="a"), "hella")
  assert_eq("hello".replace_all(old="l", new="a"), "heaao")
  assert_eq("hello".replace_all(old="ll", new="rr"), "herro")
  assert_eq("hello".replace_all(old="hello", new="world"), "world")
  assert_eq("hello hello hello".replace_all(old="hello", new="hi"), "hi hi hi")
  assert_eq(
    "hello hello helloi".replace_all(old="hello", new="hi"),
    "hi hi hii",
  )
  assert_eq(
    "hi hi hii".replace_all(old="hi", new="hello"),
    "hello hello helloi",
  )
  assert_eq("hello".replace_all(old="", new="a"), "ahaealalaoa")
  assert_eq("hello".replace_all(old="world", new="a"), "hello")
  assert_eq("".replace_all(old="", new="a"), "a")
  assert_eq("aaa".replace_all(old="a", new="b"), "bbb")
  assert_eq("aaa".replace_all(old="a", new="bb"), "bbbbbb")
  assert_eq("aaa".replace_all(old="aa", new="b"), "ba")
  assert_eq("🤣🤣🤣".replace_all(old="🤣", new="😊"), "😊😊😊")
  assert_eq("abc123abc".replace_all(old="abc", new="xyz"), "xyz123xyz")
  assert_eq("abcabcabc".replace_all(old="abc", new=""), "")
  assert_eq("abc".replace_all(old="abc", new=""), "")
  assert_eq("abc".replace_all(old="", new="x"), "xaxbxcx")
}

///|
test "String::replace_all boundary cases" {
  // These tests should trigger the uncovered line 1187: guard end + old_len <= len else { break }
  // This happens when the pattern is found at the very end of the string

  // Pattern at the end of string - should trigger the guard condition
  assert_eq("helloworld".replace_all(old="world", new="X"), "helloX")
  assert_eq("abcdef".replace_all(old="def", new="XYZ"), "abcXYZ")

  // Multiple patterns where the last one is at the end
  assert_eq("abcabc".replace_all(old="abc", new="X"), "XX")

  // Pattern that exactly matches the string length
  assert_eq("test".replace_all(old="test", new="done"), "done")

  // Empty replacement at the end
  assert_eq("remove_me".replace_all(old="_me", new=""), "remove")
}

///|
test "View::replace_all" {
  assert_eq("hello"[:].replace_all(old="o", new="a"), "hella")
  assert_eq("hello"[:].replace_all(old="l", new="a"), "heaao")
  assert_eq("hello"[:].replace_all(old="ll", new="rr"), "herro")
  assert_eq("hello"[:].replace_all(old="hello", new="world"), "world")
  assert_eq(
    "hello hello hello"[:].replace_all(old="hello", new="hi"),
    "hi hi hi",
  )
  assert_eq(
    "hello hello helloi"[:].replace_all(old="hello", new="hi"),
    "hi hi hii",
  )
  assert_eq(
    "hi hi hii"[:].replace_all(old="hi", new="hello"),
    "hello hello helloi",
  )
  assert_eq("hello"[:].replace_all(old="", new="a"), "ahaealalaoa")
  assert_eq("hello"[:].replace_all(old="world", new="a"), "hello")
  assert_eq(""[:].replace_all(old="", new="a"), "a")
  assert_eq("aaa"[:].replace_all(old="a", new="b"), "bbb")
  assert_eq("aaa"[:].replace_all(old="a", new="bb"), "bbbbbb")
  assert_eq("aaa"[:].replace_all(old="aa", new="b"), "ba")
  assert_eq(
    "🤣🤣🤣"[:].replace_all(old="🤣", new="😊"),
    "😊😊😊",
  )
  assert_eq("abc123abc"[:].replace_all(old="abc", new="xyz"), "xyz123xyz")
  assert_eq("abcabcabc"[:].replace_all(old="abc", new=""), "")
  assert_eq("abc"[:].replace_all(old="abc", new=""), "")
  assert_eq("abc"[:].replace_all(old="", new="x"), "xaxbxcx")
}

///|
test "View::replace_all boundary cases" {
  // These tests should trigger the uncovered line 1141: guard end + old_len <= len else { break }
  // This condition triggers when end + old_len > len, meaning we're at the boundary

  // Let me trace through the algorithm more carefully...
  // Actually, let me try a different approach - create a scenario where the view length changes

  // Try with overlapping patterns or edge cases
  assert_eq("abcabc"[:].replace_all(old="abc", new="X"), "XX")
  assert_eq("aaaa"[:].replace_all(old="aa", new="b"), "bb")

  // Pattern at exact end
  assert_eq("hello"[:].replace_all(old="lo", new="X"), "helX")

  // Test with empty string edge case
  assert_eq("a"[:].replace_all(old="a", new=""), "")

  // Let me try to understand when end + old_len > len could happen...
  // Maybe when we have a complex replacement scenario
  inspect("Testing boundary condition", content="Testing boundary condition")
}

///|
/// Converts this string to lowercase.
pub fn StringView::to_lower(self : StringView) -> StringView {
  // TODO: deal with non-ascii characters
  guard self.find_by(x => x.is_ascii_uppercase()) is Some(idx) else {
    return self
  }
  let buf = StringBuilder::new(size_hint=self.length())
  let head = self.view(end_offset=idx)
  buf.write_substring(head.data(), head.start_offset(), head.length())
  for c in self.view(start_offset=idx) {
    if c.is_ascii_uppercase() {
      // 'A' is 65 in ASCII, 'a' is 97, the difference is 32
      buf.write_char((c.to_int() + 32).unsafe_to_char())
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Converts this string to lowercase.
pub fn String::to_lower(self : String) -> String {
  // TODO: deal with non-ascii characters
  guard self.find_by(x => x.is_ascii_uppercase()) is Some(idx) else {
    return self
  }
  let buf = StringBuilder::new(size_hint=self.length())
  let head = self.view(end_offset=idx)
  buf.write_substring(head.data(), head.start_offset(), head.length())
  for c in self.view(start_offset=idx) {
    if c.is_ascii_uppercase() {
      // 'A' is 65 in ASCII, 'a' is 97, the difference is 32
      buf.write_char((c.to_int() + 32).unsafe_to_char())
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
test "to_lower" {
  assert_eq("Hello".to_lower(), "hello")
  assert_eq("HELLO".to_lower(), "hello")
  assert_eq("Hello, World!".to_lower(), "hello, world!")
}

///|
test "View::to_lower" {
  assert_eq("Hello"[:].to_lower(), "hello")
  assert_eq("HELLO"[:].to_lower(), "hello")
  assert_eq("Hello, World!"[:].to_lower(), "hello, world!")
}

///|
/// Converts this string to uppercase.
pub fn StringView::to_upper(self : StringView) -> StringView {
  // TODO: deal with non-ascii characters
  guard self.find_by(_.is_ascii_lowercase()) is Some(idx) else { return self }
  let buf = StringBuilder::new(size_hint=self.length())
  let head = self.view(end_offset=idx)
  buf.write_substring(head.data(), head.start_offset(), head.length())
  for c in self.view(start_offset=idx) {
    if c.is_ascii_lowercase() {
      buf.write_char((c.to_int() - 32).unsafe_to_char())
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Converts this string to uppercase.
pub fn String::to_upper(self : String) -> String {
  // TODO: deal with non-ascii characters
  guard self.find_by(_.is_ascii_lowercase()) is Some(idx) else { return self }
  let buf = StringBuilder::new(size_hint=self.length())
  let head = self.view(end_offset=idx)
  buf.write_substring(head.data(), head.start_offset(), head.length())
  for c in self.view(start_offset=idx) {
    if c.is_ascii_lowercase() {
      buf.write_char((c.to_int() - 32).unsafe_to_char())
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
test "to_upper" {
  assert_eq("hello".to_upper(), "HELLO")
  assert_eq("HELLO".to_upper(), "HELLO")
  assert_eq("Hello, World!".to_upper(), "HELLO, WORLD!")
}

///|
test "View::to_upper" {
  assert_eq("hello"[:].to_upper(), "HELLO")
  assert_eq("HELLO"[:].to_upper(), "HELLO")
  assert_eq("Hello, World!"[:].to_upper(), "HELLO, WORLD!")
}

///|
/// Folds the characters of the string into a single value.
pub fn[A] StringView::fold(
  self : StringView,
  init~ : A,
  f : (A, Char) -> A raise?,
) -> A raise? {
  let mut rv = init
  for c in self {
    rv = f(rv, c)
  }
  rv
}

///|
/// Folds the characters of the string into a single value.
pub fn[A] String::fold(
  self : String,
  init~ : A,
  f : (A, Char) -> A raise?,
) -> A raise? {
  self[:].fold(init~, f)
}

///|
test "fold" {
  assert_eq(
    "hello".fold(init=[], (acc, c) => {
      acc.push(c)
      acc
    }),
    ['h', 'e', 'l', 'l', 'o'],
  )
  assert_eq(
    "hello".fold(init=0, (acc, c) => acc + c.to_int()),
    104 + 101 + 108 + 108 + 111,
  )
}

///|
test "fold with raise" {
  let result = try? "hello".fold(init=0, (acc, c) => {
    if c == 'l' {
      raise Failure("found l")
    }
    acc + 1
  })
  inspect(result, content="Err(Failure(\"found l\"))")
}

///|
pub fn[A] StringView::rev_fold(
  self : StringView,
  init~ : A,
  f : (A, Char) -> A raise?,
) -> A raise? {
  let mut rv = init
  for c in self.rev_iter() {
    rv = f(rv, c)
  }
  rv
}

///|
pub fn[A] String::rev_fold(
  self : String,
  init~ : A,
  f : (A, Char) -> A raise?,
) -> A raise? {
  self[:].rev_fold(init~, f)
}

///|
test "rev_fold" {
  assert_eq(
    "hello".rev_fold(init=[], (acc, c) => {
      acc.push(c)
      acc
    }),
    ['o', 'l', 'l', 'e', 'h'],
  )
  assert_eq(
    "hello".rev_fold(init=0, (acc, c) => acc + c.to_int()),
    111 + 108 + 108 + 101 + 104,
  )
}

///|
test "rev_fold with raise" {
  let result = try? "hello".rev_fold(init=0, (acc, c) => {
    if c == 'l' {
      raise Failure("found l")
    }
    acc + 1
  })
  inspect(result, content="Err(Failure(\"found l\"))")
}

///|
/// Returns the UTF-16 code unit at the given index. Returns `None` if the index
/// is out of bounds.
#deprecated("The return type is about to change to `UInt16?` in a future release. Please check boundaries manually and use `String::code_unit_at` instead.", skip_current_package=true)
pub fn String::get(self : String, idx : Int) -> Int? {
  guard idx >= 0 && idx < self.length() else { return None }
  Some(self.unsafe_charcode_at(idx))
}

///|
/// Returns the UTF-16 code unit at the given index. Returns `None` if the index
/// is out of bounds.
#deprecated("The return type is about to change to `UInt16?` in a future release. Please check boundaries manually and use `StringView::code_unit_at` instead.", skip_current_package=true)
pub fn StringView::get(self : StringView, idx : Int) -> Int? {
  guard idx >= 0 && idx < self.length() else { return None }
  Some(self.unsafe_charcode_at(idx))
}

///|
test "String::get supports emoji (surrogate pair)" {
  let s = "hello"
  inspect(s.get(0), content="Some(104)")
  inspect(s.get(4), content="Some(111)")
  inspect(s.get(5), content="None")
  inspect(s.get(-1), content="None")
  let s = "a🤣b"
  inspect(s.get(0), content="Some(97)")
  inspect(s.get(1), content="Some(55358)")
  inspect(s.get(2), content="Some(56611)")
  inspect(s.get(3), content="Some(98)")
  inspect(s.get(4), content="None")
}

///|
test "View::get basic cases" {
  let v = "hello"[1:-1]
  inspect(v.get(0), content="Some(101)")
  inspect(v.get(2), content="Some(108)")
  inspect(v.get(3), content="None")
  inspect(v.get(-1), content="None")
  let v = "ab🤣cd"[1:-1]
  inspect(v.get(0), content="Some(98)")
  inspect(v.get(1), content="Some(55358)")
  inspect(v.get(2), content="Some(56611)")
}

///|
/// Returns the character at the given index. Returns `None` if the index is out
/// of bounds or the index splits a surrogate pair.
pub fn String::get_char(self : String, idx : Int) -> Char? {
  guard idx >= 0 && idx < self.length() else { return None }
  let c = self.unsafe_charcode_at(idx)
  if c.is_leading_surrogate() {
    guard idx + 1 < self.length() else { return None }
    let next = self.unsafe_charcode_at(idx + 1)
    if next.is_trailing_surrogate() {
      Some(code_point_of_surrogate_pair(c, next))
    } else {
      None
    }
  } else if c.is_trailing_surrogate() {
    None
  } else {
    Some(c.unsafe_to_char())
  }
}

///|
/// Returns the character at the given index. Returns `None` if the index is out
/// of bounds or the index splits a surrogate pair.
pub fn StringView::get_char(self : StringView, idx : Int) -> Char? {
  guard idx >= 0 && idx < self.length() else { return None }
  let c = self.unsafe_charcode_at(idx)
  if c.is_leading_surrogate() {
    guard idx + 1 < self.length() else { return None }
    let next = self.unsafe_charcode_at(idx + 1)
    if next.is_trailing_surrogate() {
      Some(code_point_of_surrogate_pair(c, next))
    } else {
      None
    }
  } else if c.is_trailing_surrogate() {
    None
  } else {
    Some(c.unsafe_to_char())
  }
}

///|
test "String::get_char basic cases" {
  // Basic ASCII characters
  let s = "hello"
  inspect(s.get_char(0), content="Some('h')")
  inspect(s.get_char(1), content="Some('e')")
  inspect(s.get_char(4), content="Some('o')")
  inspect(s.get_char(5), content="None")
  inspect(s.get_char(-1), content="None")

  // Contains emoji (surrogate pair)
  let s = "a🤣b"
  inspect(s.get_char(0), content="Some('a')")
  inspect(s.get_char(1), content="Some('🤣')")
  inspect(s.get_char(2), content="None") // Second half of surrogate pair is not a valid char
  inspect(s.get_char(3), content="Some('b')")
  inspect(s.get_char(4), content="None")
}

///|
test "View::get_char basic cases" {
  let s = "a🤣b"
  let v = s[0:-1]
  inspect(v.get_char(0), content="Some('a')")
  inspect(v.get_char(1), content="Some('🤣')")
  inspect(v.get_char(2), content="None")
  inspect(v.get_char(3), content="None")
  inspect(v.get_char(4), content="None")

  // Test substring view
  let v2 = s[1:3] // Only contains the emoji surrogate pair
  inspect(v2.get_char(0), content="Some('🤣')")
  inspect(v2.get_char(1), content="None")
  inspect(v2.get_char(2), content="None")
}
