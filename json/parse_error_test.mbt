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

//region errors

///|
test "throws on empty documents" {
  inspect(try? @json.parse(""), content="Err(Unexpected end of file)")
}

///|
test "throws on invalid characters in values" {
  inspect(
    try? @json.parse("a"),
    content="Err(Invalid character 'a' at line 1, column 0)",
  )
}

///|
test "throws on invalid characters following a sign" {
  inspect(
    try? @json.parse("-a"),
    content="Err(Invalid character 'a' at line 1, column 1)",
  )
}

///|
test "throws on invalid characters following a leading decimal point" {
  inspect(
    try? @json.parse("1.a"),
    content="Err(Invalid character 'a' at line 1, column 2)",
  )
}

///|
test "throws on invalid characters following an exponent indicator" {
  inspect(
    try? @json.parse("1ea"),
    content="Err(Invalid character 'a' at line 1, column 2)",
  )
}

///|
test "throws on invalid characters following an exponent sign" {
  inspect(
    try? @json.parse("1e-a"),
    content="Err(Invalid character 'a' at line 1, column 3)",
  )
}

///|
test "throws on invalid new lines in strings" {
  inspect(
    try? @json.parse("\"\n\""),
    content="Err(Invalid character '\\n' at line 1, column 1)",
  )
}

///|
test "throws on unterminated strings" {
  inspect(try? @json.parse("\""), content="Err(Unexpected end of file)")
}

///|
test "throws on invalid identifier start characters in property names" {
  inspect(
    try? @json.parse("{!:1}"),
    content="Err(Invalid character '!' at line 1, column 1)",
  )
}

///|
test "throws on invalid characters following a property name" {
  inspect(
    try? @json.parse("{\"a\"!1}"),
    content="Err(Invalid character '!' at line 1, column 4)",
  )
}

///|
test "throws on invalid characters following a property value" {
  inspect(
    try? @json.parse("{\"a\":1!}"),
    content="Err(Invalid character '!' at line 1, column 6)",
  )
}

///|
test "throws on invalid characters following an array value" {
  inspect(
    try? @json.parse("[1!]"),
    content="Err(Invalid character '!' at line 1, column 2)",
  )
}

///|
test "throws on invalid characters in literals" {
  inspect(
    try? @json.parse("tru!"),
    content="Err(Invalid character '!' at line 1, column 3)",
  )
}

///|
test "throws on unterminated escapes" {
  inspect(try? @json.parse("\"\\"), content="Err(Unexpected end of file)")
}

///|
test "throws on invalid unicode escapes" {
  inspect(
    try? @json.parse("\"\\u000g\""),
    content="Err(Invalid character 'g' at line 1, column 6)",
  )
}

///|
test "throws on escaped digits" {
  inspect(
    try? @json.parse("\"\\0\""),
    content="Err(Invalid character '0' at line 1, column 2)",
  )
  inspect(
    try? @json.parse("\"\\1\""),
    content="Err(Invalid character '1' at line 1, column 2)",
  )
}

///|
test "throws on multiple values" {
  inspect(
    try? @json.parse("1 2"),
    content="Err(Invalid character '2' at line 1, column 2)",
  )
}

///|
test "throws on unclosed objects before property names" {
  inspect(try? @json.parse("{"), content="Err(Unexpected end of file)")
}

///|
test "throws on unclosed objects after property names" {
  inspect(try? @json.parse("{\"a\""), content="Err(Unexpected end of file)")
}

///|
test "throws on unclosed objects before property values" {
  inspect(try? @json.parse("{\"a\":"), content="Err(Unexpected end of file)")
}

///|
test "throws on unclosed objects after property values" {
  inspect(try? @json.parse("{\"a\":1"), content="Err(Unexpected end of file)")
}

///|
test "throws on unclosed arrays before values" {
  inspect(try? @json.parse("["), content="Err(Unexpected end of file)")
}

///|
test "throws on unclosed arrays after values" {
  inspect(try? @json.parse("[1"), content="Err(Unexpected end of file)")
}

///|
test "throws on invalid property names" {
  inspect(
    try? @json.parse("{a:1}"),
    content="Err(Invalid character 'a' at line 1, column 1)",
  )
}

///|
test "throws on array with extra comma" {
  inspect(
    try? @json.parse("[1,]"),
    content="Err(Invalid character ']' at line 1, column 3)",
  )
  inspect(
    try? @json.parse("[\"\",]"),
    content="Err(Invalid character ']' at line 1, column 4)",
  )
}

///|
test "throws on object with extra comma" {
  inspect(
    try? @json.parse("{\"id\":0,}"),
    content="Err(Invalid character '}' at line 1, column 8)",
  )
}

///|
test "throws on invalid number" {
  inspect(
    try? @json.parse("+1"),
    content="Err(Invalid character '+' at line 1, column 0)",
  )
  inspect(try? @json.parse("-2."), content="Err(Unexpected end of file)")
  inspect(
    try? @json.parse(".2e-3"),
    content="Err(Invalid character '.' at line 1, column 0)",
  )
  inspect(
    try? @json.parse("0.e1"),
    content="Err(Invalid character 'e' at line 1, column 2)",
  )
  inspect(
    try? @json.parse("2.e+3"),
    content="Err(Invalid character 'e' at line 1, column 2)",
  )
  inspect(
    try? @json.parse("2.e-3"),
    content="Err(Invalid character 'e' at line 1, column 2)",
  )
  inspect(
    try? @json.parse("-.123"),
    content="Err(Invalid character '.' at line 1, column 1)",
  )
  inspect(try? @json.parse("1."), content="Err(Unexpected end of file)")
  inspect(
    try? @json.parse(".123"),
    content="Err(Invalid character '.' at line 1, column 0)",
  )
  inspect(
    try? @json.parse("[1.]"),
    content="Err(Invalid character ']' at line 1, column 3)",
  )
}

///|
test "throws on invalid chars" {
  inspect(
    try? @json.parse("[\u000c]"),
    content="Err(Invalid character '\\u{0c}' at line 1, column 1)",
  )
  inspect(
    try? @json.parse("[\"\u0009\"]"),
    content="Err(Invalid character '\\t' at line 1, column 2)",
  )
  inspect(
    try? @json.parse("[\"a\u0000a\"]"),
    content="Err(Invalid character '\\u{00}' at line 1, column 3)",
  )
}

//endregion
