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
test "Show for Unit" {
  inspect!(().to_string(), content="()")
}

///|
test "Show for Bool" {
  inspect!(true.to_string(), content="true")
  inspect!(false.to_string(), content="false")
}

///|
test "Show for Int" {
  inspect!((0).to_string(), content="0")
  inspect!(@int.max_value.to_string(), content="2147483647")
  inspect!(@int.min_value.to_string(), content="-2147483648")
}

///|
test "Show for Int64" {
  inspect!((0 : Int64).to_string(), content="0")
  inspect!(@int64.max_value.to_string(), content="9223372036854775807")
  inspect!(@int64.min_value.to_string(), content="-9223372036854775808")
}

///|
test "Show for Int16" {
  inspect!((0 : Int16).to_string(), content="0")
  inspect!((32767 : Int16).to_string(), content="32767")
  inspect!((-32768 : Int16).to_string(), content="-32768")
}

///|
test "Show for UInt" {
  inspect!((0 : UInt).to_string(), content="0")
  inspect!(@uint.max_value.to_string(), content="4294967295")
  inspect!(@uint.min_value.to_string(), content="0")
}

///|
test "Show for UInt64" {
  inspect!((0 : UInt64).to_string(), content="0")
  inspect!(@uint64.max_value.to_string(), content="18446744073709551615")
  inspect!(@uint64.min_value.to_string(), content="0")
}

///|
test "Show for UInt16" {
  inspect!((0 : UInt16).to_string(), content="0")
  inspect!((65535 : UInt16).to_string(), content="65535")
}

///|
test "Show for Bytes" {
  inspect!(
    Show::to_string(b"abcdefg"),
    content=
      #|b"\x61\x62\x63\x64\x65\x66\x67"
    ,
  )
  inspect!(
    Show::to_string(b"\x00\xff\x63"),
    content=
      #|b"\x00\xff\x63"
    ,
  )
}

///|
test "Show for BytesView" {
  inspect!(
    b"abcdefg"[1:5].to_string(),
    content=
      #|b"\x62\x63\x64\x65"
    ,
  )
  inspect!(
    b"\x00\xff\x63"[:].to_string(),
    content=
      #|b"\x00\xff\x63"
    ,
  )
}

///|
test "Show for String" {
  fn to_string_using_output(str) {
    let buf = StringBuilder::new()
    Show::output(str, buf)
    buf.to_string()
  }

  inspect!(
    to_string_using_output("abcdefg中文字符"),
    content=
      #|"abcdefg中文字符"
    ,
  )
  inspect!(
    Show::to_string("abcdefg中文字符"),
    content="abcdefg中文字符",
  )
  inspect!(
    to_string_using_output("---\"---'---\\---\n---\t---\x67---"),
    content=
      #|"---\"---'---\\---\n---\t---g---"
    ,
  )
  // should be identity
  inspect!(
    Show::to_string("---\"---'---\\---\n---\t---\x67---"),
    content=
      #|---"---'---\---
      #|---	---g---
    ,
  )
}

///|
test "Show for Result" {
  // use explicit type annotation to specify the type of Ok/Err
  fn result_to_string(x : Result[String, String]) {
    x.to_string()
  }

  inspect!(
    result_to_string(Ok("abc")),
    content=
      #|Ok("abc")
    ,
  )
  inspect!(
    result_to_string(Err("def")),
    content=
      #|Err("def")
    ,
  )
}

///|
test "Show for Ref" {
  inspect!(
    { val: "abc" }.to_string(),
    content=
      #|{val: "abc"}
    ,
  )
}

///|
test "Show for FixedArray" {
  inspect!(
    (["a", "b", "c"] : FixedArray[_]).to_string(),
    content=
      #|["a", "b", "c"]
    ,
  )
  inspect!(([] : FixedArray[String]).to_string(), content="[]")
}

///|
test "Show for Array" {
  inspect!(
    ["a", "b", "c"].to_string(),
    content=
      #|["a", "b", "c"]
    ,
  )
  inspect!(([] : Array[String]).to_string(), content="[]")
}

///|
test "Show for ArrayView" {
  let arr = ["a", "b", "c", "d"]
  inspect!(
    arr[1:3].to_string(),
    content=
      #|["b", "c"]
    ,
  )
  inspect!(arr[2:2].to_string(), content="[]")
}

///|
test "Show for Char" {
  inspect!(Show::to_string('a'), content="a")
  inspect!(Show::to_string('字'), content="字")
  inspect!(
    Show::to_string('\n'),
    content=
      #|
      #|
    ,
  )
  inspect!(Show::to_string('\t'), content="\t")
  inspect!(
    Show::to_string('"'),
    content=
      #|"
    ,
  )
  inspect!(Show::to_string('\''), content="'")
  inspect!(Show::to_string('\\'), content="\\")
  inspect!('a'.to_string(), content="a")
  inspect!('字'.to_string(), content="字")
  inspect!(
    '\n'.to_string(),
    content=
      #|
      #|
    ,
  )
  inspect!('\t'.to_string(), content="\t")
  inspect!(
    '"'.to_string(),
    content=
      #|"
    ,
  )
  inspect!('\''.to_string(), content="'")
  inspect!('\\'.to_string(), content="\\")
}

///|
test "char show hex digits" {
  // inspect!('\x01', content="\x01")
  // FIXME: inspect!('\x0b') will not work with update test
  // inspect!('\x0b', content="\x0b")
  assert_true!('\u{01}'.to_string() == "\x01")
  assert_true!('\u{0b}'.to_string() == "\x0b")
}

///|
test "char_special" {
  inspect!('\r', content="\r")
  inspect!('\b', content="\u{8}")
}

///|
test "Show for Failure" {
  let f = Failure("test error message")
  inspect!(
    f.to_string(),
    content=
      #|"Failure(test error message)"
    ,
  )
}

///|
test "Show for Char special cases" {
  // Test escape sequences
  inspect!('\''.to_string(), content="'")

  // Test various special character outputs
  let quote_buf = StringBuilder::new()
  '\''.output(quote_buf)
  inspect!(quote_buf.to_string(), content="'\\''")
  let backslash_buf = StringBuilder::new()
  '\\'.output(backslash_buf)
  inspect!(backslash_buf.to_string(), content="'\\\\'")
  let cr_buf = StringBuilder::new()
  '\r'.output(cr_buf)
  inspect!(cr_buf.to_string(), content="'\\r'")
  let backspace_buf = StringBuilder::new()
  '\b'.output(backspace_buf)
  inspect!(backspace_buf.to_string(), content="'\\b'")
  let tab_buf = StringBuilder::new()
  '\t'.output(tab_buf)
  inspect!(tab_buf.to_string(), content="'\\t'")

  // Test hex output for control characters
  let ctrl1_buf = StringBuilder::new()
  '\u{01}'.output(ctrl1_buf)
  inspect!(ctrl1_buf.to_string(), content="'\\x01'")
  let ctrl_f_buf = StringBuilder::new()
  '\u{0F}'.output(ctrl_f_buf)
  inspect!(ctrl_f_buf.to_string(), content="'\\x0f'")
  let ctrl_1f_buf = StringBuilder::new()
  '\u{1F}'.output(ctrl_1f_buf)
  inspect!(ctrl_1f_buf.to_string(), content="'\\x1f'")
}
