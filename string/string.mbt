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
/// String with longer length is bigger.
/// strings of the same length are compared in lexicalgraphic order.
pub fn compare(self : String, other : String) -> Int {
  let len = self.length()
  match len.compare(other.length()) {
    0 => {
      for i = 0; i < len; i = i + 1 {
        let order = self[i].compare(other[i])
        if order != 0 {
          return order
        }
      }
      0
    }
    order => order
  }
}

test "compare" {
  @assertion.assert_eq(0, "".compare(""))?
  @assertion.assert_eq(-1, "".compare("abc"))?
  @assertion.assert_eq(1, "abc".compare(""))?
  @assertion.assert_eq(-1, "abcd".compare("abce"))?
  @assertion.assert_eq(1, "abce".compare("abcd"))?
  @assertion.assert_eq(-1, "c".compare("ab"))?
  @assertion.assert_eq(1, "ab".compare("c"))?
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
        let c = self[index].to_int()
        if c >= 0xD800 && c <= 0xDBFF && index + 1 < len {
          let c2 = self[index + 1].to_int()
          if c2 >= 0xDC00 && c2 <= 0xDFFF {
            let c = Char::from_int((c - 0xD800) * 0x400 + c2 - 0xDC00 + 0x10000)
            if yield(c) {
              continue index + 2
            } else {
              break false
            }
          }
        }
        //TODO: handle garbage input
        if not(yield(Char::from_int(c))) {
          break false
        }
      } else {
        true
      }
    },
  )
}

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

pub fn starts_with(self : String, str : String) -> Bool {
  if str.length() > self.length() {
    false
  } else {
    self.substring(end=str.length()).compare(str) == 0
  }
}

test "starts_with" {
  @assertion.assert_true("abc".starts_with("a"))?
  @assertion.assert_true("abc".starts_with("ab"))?
  @assertion.assert_true("abc".starts_with("abc"))?
  @assertion.assert_false("abc".starts_with("abcd"))?
  @assertion.assert_false("abc".starts_with("b"))?
}

pub fn ends_with(self : String, str : String) -> Bool {
  if str.length() > self.length() {
    false
  } else {
    self.substring(start=self.length() - str.length()).compare(str) == 0
  }
}

test "ends_with" {
  @assertion.assert_true("abc".ends_with("c"))?
  @assertion.assert_true("abc".ends_with("bc"))?
  @assertion.assert_true("abc".ends_with("abc"))?
  @assertion.assert_false("abc".ends_with("d"))?
  @assertion.assert_false("abc".ends_with("ab"))?
}

pub fn index_of(self : String, str : String) -> Int {
  let len = self.length()
  let sub_len = str.length()
  if sub_len == 0 {
    0
  } else if sub_len > len {
    -1
  } else {
    for i = 0; i < len - sub_len + 1; i = i + 1 {
      if self.substring(start=i, end=i + sub_len).compare(str) == 0 {
        return i
      }
    }
    -1
  }
}

test "index_of" {
  @assertion.assert_true("abc".index_of("a") == 0)?
  @assertion.assert_true("abc".index_of("b") == 1)?
  @assertion.assert_true("abc".index_of("c") == 2)?
  @assertion.assert_true("abc".index_of("ab") == 0)?
  @assertion.assert_true("abc".index_of("bc") == 1)?
  @assertion.assert_true("abc".index_of("") == 0)?
  @assertion.assert_true("abc".index_of("d") == -1)?
  @assertion.assert_true("abc".index_of("abcd") == -1)?
}
