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
test "String::escape" {
  inspect!(
    "abc,def".escape(),
    content=
      #|"abc,def"
    ,
  )
  inspect!(
    "\n\t\\".escape(),
    content=
      #|"\n\t\\"
    ,
  )
  inspect!(
    "\"'".escape(),
    content=
      #|"\"'"
    ,
  )
  inspect!(
    "\x00\x01\x20\x21".escape(),
    content=
      #|"\x00\x01 !"
    ,
  )
}

///|
test "substring" {
  assert_eq!("abc".substring(), "abc")
  assert_eq!("abc".substring(start=1), "bc")
  assert_eq!("abc".substring(end=2), "ab")
  assert_eq!("abc".substring(start=1, end=2), "b")
}

///|
test "panic codepoint_at1" {
  let str = "Hello🤣🤣🤣"
  let _ = str.codepoint_at(8)

}

///|
test "panic codepoint_at2" {
  let str = "Hello🤣🤣🤣"
  let _ = str.codepoint_at(-1)

}

///|
test "panic charcode_at with negative index" {
  let s = "Hello"
  ignore(charcode_at(s, -1))
}

///|
test "charcode_at with valid index" {
  let s = "Hello"
  inspect!(charcode_at(s, 0), content="72")
}

///|
test "codepoint_at regular character at end of string" {
  let s = "Hello"
  inspect!(codepoint_at(s, 4), content="'o'")
}

///|
test "codepoint_at emoji" {
  let s = "👋"
  inspect!(codepoint_at(s, 0), content="'👋'")
}

///|
test "codepoint_length basic" {
  let str = "hello"
  inspect!(codepoint_length(str), content="5")
}

///|
test "codepoint_length with surrogate pairs" {
  let str = "Hello🤣"
  inspect!(codepoint_length(str), content="6")
}

///|
test "panic String::make with negative length" {
  ignore(String::make(-1, 'A'))
}

///|
test "String::make with zero length" {
  inspect!(String::make(0, 'A'), content="")
}

///|
test "panic codepoint_length with invalid surrogate pair" {
  // Create a string with a leading surrogate (0xD800) followed by an invalid trailing surrogate
  let s = String::from_array([
      Char::from_int(0xD800), // leading surrogate
      'a',
    ], // invalid trailing surrogate
  )
  ignore(@builtin.codepoint_length(s))
}
