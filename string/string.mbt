// Copyright 2024 International Digital Economy Academy
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

/// Compare two strings.
/// 
/// String are compared char-by-char by unicode code point value. 
/// 
/// ## Application Notes
/// 
/// For the char represented by UTF-16 surrogate pairs, comparation behavior may be 
/// different from JavaScript mathematical operators (`<`, `>`). This is because current
/// major JavaScript runtimes simply compare UTF-16 strings 16-bit-word-by-16-bit-word, 
/// hence different from the order of Unicode code point value. 
pub fn compare(self : String, other : String) -> Int {
  // NOTE: use traditional while loops, since we have no way to 
  // poll 2 iterators (Iter[Char]) simultaneously.
  let mut pa = 0
  let mut pb = 0
  let (la, lb) = (self.length(), other.length())
  while pa < la && pa < lb {
    let mut wa = self[pa].to_int()
    let mut wb = other[pb].to_int()
    if is_high_surrogate(wa) {
      wa = char_from_surrogate_unchecked(wa, self[pa + 1].to_int()).to_int()
      pa += 1
    }
    if is_high_surrogate(wb) {
      wb = char_from_surrogate_unchecked(wb, other[pb + 1].to_int()).to_int()
      pb += 1
    }
    if not(wa == wb) {
      return wa.compare(wb)
    } else {
      pa += 1
      pb += 1
    }
  }
  la.compare(lb) // compare directly by length if common parts are identical
}

test "compare" {
  @assertion.assert_eq(0, "".compare(""))?
  @assertion.assert_eq(-1, "".compare("abc"))?
  @assertion.assert_eq(1, "abc".compare(""))?
  @assertion.assert_eq(-1, "abcd".compare("abce"))?
  @assertion.assert_eq(1, "abce".compare("abcd"))?
  @assertion.assert_eq(1, "c".compare("ab"))?
  @assertion.assert_eq(-1, "ab".compare("c"))?

  // real world examples
  @assertion.assert_eq(-1, "Alice".compare("Bob"))?
  @assertion.assert_eq(-1, "Bob".compare("John"))?
  @assertion.assert_eq(-1, "Alice".compare("John"))?

  // case-sensitive
  @assertion.assert_eq(1, "alice".compare("Alice"))?
  @assertion.assert_eq(1, "alice".compare("Bob"))?
  @assertion.assert_eq(1, "alice".compare("Zulu"))?

  // correct compare with surrogate pairs
  // note: U+1F600 = 0xD83D 0xDE00 in UTF16
  @assertion.assert_eq(-1, "\u{AC00}".compare("\u{FE11}"))?
  @assertion.assert_eq(-1, "\u{FE11}".compare("\u{1F600}"))?
  @assertion.assert_eq(-1, "\u{AC00}".compare("\u{1F600}"))?
}

/// Compare two strings case-insensitive.
///
/// String are compared char-by-char by unicode code point value, but ASCII letters 
/// are compared case-insensitive. 
pub fn compare_case_insensitive(self : String, other : String) -> Int {
  // NOTE: use traditional while loops, since we have no way to 
  // poll 2 iterators (Iter[Char]) simultaneously.
  let mut pa = 0
  let mut pb = 0
  let (la, lb) = (self.length(), other.length())
  while pa < la && pa < lb {
    let mut wa = self[pa].to_int()
    let mut wb = other[pb].to_int()
    if is_high_surrogate(wa) {
      wa = char_from_surrogate_unchecked(wa, self[pa + 1].to_int()).to_int()
      pa += 1
    }
    if is_high_surrogate(wb) {
      wb = char_from_surrogate_unchecked(wb, other[pb + 1].to_int()).to_int()
      pb += 1
    }
    if not(wa == wb) {
      return wa.compare(wb)
    } else {
      pa += 1
      pb += 1
    }
  }
  la.compare(lb) // compare directly by length if common parts are identical
}

test "compare_case_insensitive" {
  // real world case-insensitive examples
  @assertion.assert_eq(-1, "Alice".compare_case_insensitive("BOB"))?
  @assertion.assert_eq(-1, "bOB".compare_case_insensitive("joHN"))?
  @assertion.assert_eq(-1, "Alice".compare_case_insensitive("jOHn"))?
}

/// The empty string
pub fn String::default() -> String {
  ""
}

/// `String` holds a sequence of UTF-16 code units encoded in little endian format
pub fn to_bytes(self : String) -> Bytes {
  let len = self.length()
  let bytes = Bytes::make(len * 2)
  bytes.blit_from_string(0, self, 0, len)
  bytes
}

test "to_bytes" {
  @assertion.assert_eq("中文".to_bytes().to_string(), "中文")?
  @assertion.assert_eq("asdf".to_bytes().to_string(), "asdf")?
  @assertion.assert_eq("🤣🤣".to_bytes().to_string(), "🤣🤣")?
  @assertion.assert_eq("🤔".to_bytes().to_string(), "🤔")?
}

pub fn hash(self : String) -> Int {
  self.to_bytes().hash()
}

// [debug_write] is in [builtin].
// due to cyclic dependency issue we can only test it here
test "debug_write" {
  fn repr(s : String) {
    let buf = Buffer::make(0)
    s.debug_write(buf)
    buf.to_string()
  }

  @assertion.assert_eq(repr("a"), "\"a\"")?
  @assertion.assert_eq(repr("'"), "\"'\"")?
  @assertion.assert_eq(repr("\""), "\"\\\"\"")?
  @assertion.assert_eq(repr("\\"), "\"\\\\\"")?
  @assertion.assert_eq(repr("\n"), "\"\\n\"")?
  @assertion.assert_eq(repr("\r"), "\"\\r\"")?
  @assertion.assert_eq(repr("\b"), "\"\\b\"")?
  @assertion.assert_eq(repr("\t"), "\"\\t\"")?
  @assertion.assert_eq(repr("\x00"), "\"\\x00\"")?
  @assertion.assert_eq(repr("abc'\"def\\"), "\"abc'\\\"def\\\\\"")?
}

// test here to avlid cyclic dependency between assertion and builtin
test "Buffer::to_bytes" {
  let buffer = Buffer::make(16)
  buffer.write_string("中文")
  @assertion.assert_eq(buffer.to_bytes().to_string(), "中文")?
}

/// Converts the String into an array of Chars.
pub fn to_array(self : String) -> Array[Char] {
  self.as_iter().fold(
    fn(rv, c) {
      rv.push(c)
      rv
    },
    Array::with_capacity(self.length()),
  )
}

test "to_array" {
  let a = "你好！mbt😀".to_array()
  inspect(a[0], content="你")?
  inspect(a[1], content="好")?
  inspect(a[2], content="！")?
  inspect(a[3], content="m")?
  inspect(a[4], content="b")?
  inspect(a[5], content="t")?
  inspect(a[6], content="😀")?
}

/// @intrinsic %string.substring
fn unsafe_substring(str : String, start : Int, end : Int) -> String {
  let len = end - start
  let buf = Buffer::make(len)
  buf.write_sub_string(str, start, len)
  buf.to_string()
}

/// Get substring of the string from [start] to [end] exclusive.
pub fn substring(
  self : String,
  ~start : Int = 0,
  ~end : Int = self.length()
) -> String {
  if start < 0 {
    abort("String::substring: start index is negative")
  }
  if end < 0 {
    abort("String::substring: end index is negative")
  }
  if start > end {
    abort("String::substring: start index is greater than end index")
  }
  if end > self.length() {
    abort(
      "String::substring: end index is greater than the length of the string",
    )
  }
  unsafe_substring(self, start, end)
}

test "substring" {
  @assertion.assert_eq("abc".substring(), "abc")?
  @assertion.assert_eq("abc".substring(start=1), "bc")?
  @assertion.assert_eq("abc".substring(end=2), "ab")?
  @assertion.assert_eq("abc".substring(start=1, end=2), "b")?
}

pub fn as_iter(self : String) -> Iter[Char] {
  Iter::_unstable_internal_make(
    fn(yield) {
      let len = self.length()
      for index = 0; index < len; index = index + 1 {
        let w1 = self[index].to_int()
        if is_high_surrogate(w1) && index + 1 < len {
          let w2 = self[index + 1].to_int()
          if is_low_surrogate(w2) {
            let c = char_from_surrogate_unchecked(w1, w2)
            if yield(c) {
              continue index + 2
            } else {
              break false
            }
          }
        }
        //TODO: handle garbage input
        if not(yield(Char::from_int(w1))) {
          break false
        }
      } else {
        true
      }
    },
  )
}

fn is_high_surrogate(word: Int) -> Bool { 0xD800 <= word && word <= 0xDBFF }
fn is_low_surrogate(word: Int) -> Bool { 0xDC00 <= word && word <= 0xDFFF }

test "chars" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B".as_iter().iter(
    fn(c) { str = str + c.to_int().to_string() + "\n" },
  )
  inspect(
    str,
    content=
      #|65
      #|128522
      #|134071
      #|66
      #|65
      #|128522
      #|134071
      #|66
      #|
    ,
  )?
}

fn char_from_surrogate_unchecked(high: Int, low: Int) -> Char {
  // NOTE: should put in `Char` if `pub(module)` accessibility level is available
  Char::from_int((high.land(0x000003FF).lsl(10) + low.land(0x000003FF)) + 0x00010000)
}
