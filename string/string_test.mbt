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

test "default" {
  inspect(default())?
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

test "to_bytes" {
  @assertion.assert_eq("中文".to_bytes().to_string(), "中文")?
  @assertion.assert_eq("asdf".to_bytes().to_string(), "asdf")?
  @assertion.assert_eq("🤣🤣".to_bytes().to_string(), "🤣🤣")?
  @assertion.assert_eq("🤔".to_bytes().to_string(), "🤔")?
}

test "debug_write" {
  fn repr(s : String) {
    let buf = Buffer::new(size_hint=0)
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

test "substring" {
  @assertion.assert_eq("abc".substring(), "abc")?
  @assertion.assert_eq("abc".substring(start=1), "bc")?
  @assertion.assert_eq("abc".substring(end=2), "ab")?
  @assertion.assert_eq("abc".substring(start=1, end=2), "b")?
}

test "chars" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B".iter().each(
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

test "starts_with" {
  @assertion.assert_true("abc".starts_with("a"))?
  @assertion.assert_true("abc".starts_with("ab"))?
  @assertion.assert_true("abc".starts_with("abc"))?
  @assertion.assert_false("abc".starts_with("abcd"))?
  @assertion.assert_false("abc".starts_with("b"))?
}

test "ends_with" {
  @assertion.assert_true("abc".ends_with("c"))?
  @assertion.assert_true("abc".ends_with("bc"))?
  @assertion.assert_true("abc".ends_with("abc"))?
  @assertion.assert_false("abc".ends_with("d"))?
  @assertion.assert_false("abc".ends_with("ab"))?
  inspect("abc".ends_with("abcd"), content="false")?
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

// [debug_write] is in [builtin].
// due to cyclic dependency issue we can only test it here

// test here to avlid cyclic dependency between assertion and builtin
test "Buffer::to_bytes" {
  let buffer = Buffer::new(size_hint=16)
  buffer.write_string("中文")
  @assertion.assert_eq(buffer.to_bytes().to_string(), "中文")?
}

test "panic substring_start_index_error" {
  "test".substring(start=-1, end=0) |> ignore
}

test "panic substring_end_index_error" {
  "test".substring(start=0, end=-1) |> ignore
}

test "panic substring_start_end_index_error" {
  "test".substring(start=1, end=0) |> ignore
}

test "panic substring_length_index_error" {
  "test".substring(start=0, end=5) |> ignore
}
