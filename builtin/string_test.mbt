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

///|
test "String::suffixes" {
  let suffixes = "za🤣b".suffixes().map(v => v.to_string()).collect()
  @json.inspect(suffixes, content=["za🤣b", "a🤣b", "🤣b", "b"])
  let suffixes_with_empty = "za🤣b"
    .suffixes(include_empty=true)
    .map(v => v.to_string())
    .collect()
  @json.inspect(suffixes_with_empty, content=[
    "za🤣b", "a🤣b", "🤣b", "b", "",
  ])
  let suffixes_no_empty = "za🤣b"
    .suffixes(include_empty=false)
    .map(v => v.to_string())
    .collect()
  @json.inspect(suffixes_no_empty, content=["za🤣b", "a🤣b", "🤣b", "b"])
  let empty_suffixes = "".suffixes().map(v => v.to_string()).collect()
  @json.inspect(empty_suffixes, content=[])
  let empty_suffixes_with_empty = ""
    .suffixes(include_empty=true)
    .map(v => v.to_string())
    .collect()
  @json.inspect(empty_suffixes_with_empty, content=[""])
}

///|
test "code_unit_at" {
  let s = "Hello, 世界!😀"
  assert_true(s.code_unit_at(0) is 'H')
  assert_true(s.code_unit_at(7) is '世')
  assert_true(s.code_unit_at(8) is '界')
  assert_true(s.code_unit_at(0) is ('A'..='Z'))
  inspect(s.code_unit_at(0), content="72") // 'H'
  inspect(s.code_unit_at(7), content="19990") // '世'
  inspect(s.code_unit_at(8), content="30028") // '界'
  inspect(s.code_unit_at(10), content="55357") // High surrogate of '😀'
  inspect(s.code_unit_at(11), content="56832") // Low surrogate of '😀'
}

///|
test "String default and to_array" {
  inspect(String::default(), content="")
  let chars = "Hi".to_array()
  inspect(chars.length(), content="2")
  inspect(String::from_array(chars), content="Hi")
}

///|
test "String from_iter" {
  let iter = ['a', 'b', 'c'].iter()
  inspect(String::from_iter(iter), content="abc")
}

///|
test "String rev_iter with surrogate" {
  let buf = StringBuilder::new()
  "A😀B".rev_iter().each(c => buf.write_char(c))
  inspect(buf.to_string(), content="B😀A")
}

///|
test "char_length_eq and char_length_ge" {
  let s = "hi😀"
  inspect(s.char_length_eq(3), content="true")
  inspect(s.char_length_eq(4), content="false")
  inspect(s.char_length_ge(2), content="true")
  inspect(s.char_length_ge(5), content="false")
}

///|
test "offset_of_nth_char out of range" {
  inspect("abc".offset_of_nth_char(5), content="None")
}

///|
test "panic char_length invalid range" {
  ignore("abc".char_length(start_offset=2, end_offset=1))
}

///|
test "panic char_length_eq invalid surrogate" {
  let invalid = String::from_array([(0xD800).unsafe_to_char(), 'a'])
  ignore(invalid.char_length_eq(1))
}

///|
test "panic char_length_ge invalid surrogate" {
  let invalid = String::from_array([(0xD800).unsafe_to_char(), 'a'])
  ignore(invalid.char_length_ge(1))
}

///|
test "StringView pad_start and pad_end no padding" {
  let view = "hello"[1:3]
  inspect(view.pad_start(2, 'x'), content="el")
  inspect(view.pad_end(2, 'x'), content="el")
}

///|
test "StringView repeat non-positive" {
  let view = "hi"[:]
  let mut n = 1
  n -= view.length()
  inspect(view.repeat(n), content="")
}

///|
test "StringView replace and replace_all" {
  let chars = Array::make(6, 'x')
  chars[0] = 'a'
  chars[1] = 'b'
  chars[2] = 'c'
  chars[3] = 'a'
  chars[4] = 'b'
  chars[5] = 'c'
  let base = String::from_array(chars)
  let view = base[:]
  inspect(view.replace(old="ab", new="X"), content="Xcabc")
  inspect(view.replace(old="zz", new="X"), content="abcabc")
  inspect(view.replace_all(old="ab", new="X"), content="XcXc")
}

///|
test "String replace_all basic" {
  let chars = Array::make(3, 'x')
  chars[0] = 'a'
  chars[1] = 'b'
  chars[2] = 'a'
  let base = String::from_array(chars)
  inspect(base.replace_all(old="a", new="x"), content="xbx")
}

///|
test "String to_lower no uppercase" {
  inspect("abc".to_lower(), content="abc")
  inspect("abc"[:].to_lower(), content="abc")
}

///|
test "panic offset_of_nth_char invalid range" {
  ignore("abc".offset_of_nth_char(0, start_offset=2, end_offset=1))
}

///|
test "offset_of_nth_char backward out of range" {
  inspect(
    "abc".offset_of_nth_char(-2, start_offset=0, end_offset=1),
    content="None",
  )
}

///|
test "String get_char invalid surrogate pair" {
  let invalid = String::from_array([(0xD800).unsafe_to_char(), 'a'])
  inspect(invalid.get_char(0), content="None")
  inspect(invalid[:].get_char(0), content="None")
}

///|
test "StringView repeat single" {
  let view = "repeat".view()
  inspect(view.repeat(1), content="repeat")
}
