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

//region errors
test "throws on empty documents" {
  let res = parse("")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on documents with only comments" {
  let res = parse("//a")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on incomplete single line comments" {
  let res = parse("/a")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 1 }, 'a')))?
}

test "throws on unterminated multiline comments" {
  let res = parse("/*")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on unterminated multiline comment closings" {
  let res = parse("/**")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on invalid characters in values" {
  let res = parse("a")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 0 }, 'a')))?
}

test "throws on invalid characters in identifier start escapes" {
  let res = parse("{\\a:1}")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 2 }, 'a')))?
}

test "throws on invalid characters in identifier continue escapes" {
  let res = parse("{a\\a:1}")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 3 }, 'a')))?
}

test "throws on invalid identifier continue characters" {
  let res = parse("{a\\u0021:1}")
  @assertion.assert_eq(res, Err(InvalidIdentEscape({ line: 1, column: 2 })))?
}

test "throws on invalid characters following a sign" {
  let res = parse("-a")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 1 }, 'a')))?
}

test "throws on invalid characters following a leading decimal point" {
  let res = parse(".a")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 1 }, 'a')))?
}

test "throws on invalid characters following an exponent indicator" {
  let res = parse("1ea")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 2 }, 'a')))?
}

test "throws on invalid characters following an exponent sign" {
  let res = parse("1e-a")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 3 }, 'a')))?
}

test "throws on invalid characters following a hexadecimal indicator" {
  let res = parse("0xg")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 2 }, 'g')))?
}

test "throws on invalid new lines in strings" {
  let res = parse("\"\n\"")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 1 }, '\n')))?
}

test "throws on unterminated strings" {
  let res = parse("\"")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on invalid identifier start characters in property names" {
  let res = parse("{!:1}")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 1 }, '!')))?
}

test "throws on invalid characters following a property name" {
  let res = parse("{a!1}")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 2 }, '!')))?
}

test "throws on invalid characters following a property value" {
  let res = parse("{a:1!}")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 4 }, '!')))?
}

test "throws on invalid characters following an array value" {
  let res = parse("[1!]")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 2 }, '!')))?
}

test "throws on invalid characters in literals" {
  let res = parse("tru!")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 3 }, '!')))?
}

test "throws on unterminated escapes" {
  let res = parse("\"\\")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on invalid first digits in hexadecimal escapes" {
  let res = parse("\"\\xg\"")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 3 }, 'g')))?
}

test "throws on invalid second digits in hexadecimal escapes" {
  let res = parse("\"\\x0g\"")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 4 }, 'g')))?
}

test "throws on invalid unicode escapes" {
  let res = parse("\"\\u000g\"")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 6 }, 'g')))?
}

test "throws on escaped digits" {
  let res = parse("\"\\1\"")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 2 }, '1')))?
}

test "throws on octal escapes" {
  let res = parse("\"\\01\"")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 3 }, '1')))?
}

test "throws on multiple values" {
  let res = parse("1 2")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 2 }, '2')))?
}

test "throws with control characters escaped in the message" {
  let res = parse("\x01")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 0 }, '\x01')))?
}

test "throws on unclosed objects before property names" {
  let res = parse("{")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on unclosed objects after property names" {
  let res = parse("{a")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on unclosed objects before property values" {
  let res = parse("{a:")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on unclosed objects after property values" {
  let res = parse("{a:1")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on unclosed arrays before values" {
  let res = parse("[")
  @assertion.assert_eq(res, Err(InvalidEof))?
}

test "throws on unclosed arrays after values" {
  let res = parse("[1")
  @assertion.assert_eq(res, Err(InvalidEof))?
}
//endregion
