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

pub fn to_bytes(self : String) -> Bytes {
  let len = self.length()
  let bytes = Bytes::make(len * 2, 0)
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
  let len = self.length()
  let rv = Array::make(len, '\x00')
  for i = 0; i < len; i = i + 1 {
    rv[i] = self[i]
  }
  rv
}

test "to_array" {
  let a = "你好！mbt".to_array()
  inspect(a[0], content="你")?
  inspect(a[1], content="好")?
  inspect(a[2], content="！")?
  inspect(a[3], content="m")?
  inspect(a[4], content="b")?
  inspect(a[5], content="t")?
}

/// Returns an integer between 0 and 65535 representing the UTF-16 code unit at the given index.
pub fn char_code_at(self : String, index : Int) -> Option[Int] {
  if index < 0 || index >= self.length() {
    None
  } else {
    Some(self[index].to_int())
  }
}

test "char_code_at" {
  inspect("ABC".char_code_at(0), content="Some(65)")?
  inspect("🤣".char_code_at(0), content="Some(55358)")?
  inspect("🤣".char_code_at(1), content="Some(56611)")?
  inspect("ABC".char_code_at(4), content="None")?
}

/// Returns a non-negative integer that is the Unicode code point value of the character starting at the given index.
/// If the element at index is a UTF-16 leading surrogate, returns the code point of the surrogate pair.
/// If the element at index is a UTF-16 trailing surrogate, returns only the trailing surrogate unit.
pub fn code_point_at(self : String, index : Int) -> Option[Int] {
  if index < 0 || index >= self.length() {
    return None
  }
  let c = self[index]
  if c.is_high_surrogate() {
    let cl = self[index + 1]
    Some(Char::to_code_point(c, cl))
  } else {
    Some(c.to_int())
  }
}

test "code_point_at" {
  inspect("ABC".code_point_at(0), content="Some(65)")?
  inspect("🤣".code_point_at(0), content="Some(129315)")?
  inspect("🤣".code_point_at(1), content="Some(56611)")?
  inspect("ABC".code_point_at(4), content="None")?
}
