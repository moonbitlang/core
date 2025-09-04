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
  inspect(
    "abc,def".escape(),
    content=(
      #|"abc,def"
    ),
  )
  inspect(
    "\n\t\\".escape(),
    content=(
      #|"\n\t\\"
    ),
  )
  inspect(
    "\"'".escape(),
    content=(
      #|"\"'"
    ),
  )
  inspect(
    "\u{00}\u{01}\u{20}\u{21}".escape(),
    content=(
      #|"\u{00}\u{01} !"
    ),
  )
}

///|
test "panic codepoint_at1" {
  let str = "Hello🤣🤣🤣"
  let _ = str.iter().nth(8).unwrap()

}

///|
test "codepoint_at regular character at end of string" {
  let s = "Hello"
  inspect(s.iter().nth(4).unwrap(), content="o")
}

///|
test "codepoint_at emoji" {
  let s = "👋"
  inspect(s.iter().nth(0).unwrap(), content="👋")
}

///|
test "char_length basic" {
  let str = "hello"
  inspect(str.char_length(), content="5")
}

///|
test "char_length with surrogate pairs" {
  let str = "Hello🤣"
  inspect(str.char_length(), content="6")
}

///|
test "panic String::make with negative length" {
  ignore(String::make(-1, 'A'))
}

///|
test "String::make with non-bmp" {
  inspect(String::make(2, '🤣'), content="🤣🤣")
}

///|
test "String::make with zero length" {
  inspect(String::make(0, 'A'), content="")
}

///|
test "panic codepoint_length with invalid surrogate pair" {
  // Create a string with a leading surrogate (0xD800) followed by an invalid trailing surrogate
  let s = String::from_array([
      (0xD800).unsafe_to_char(), // leading surrogate
      'a',
    ], // invalid trailing surrogate
  )
  ignore(s.char_length())
}
