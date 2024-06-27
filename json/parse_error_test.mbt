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
  inspect(parse(""), content="Err(Unexpected end of file)")!
}

test "throws on invalid characters in values" {
  inspect(parse("a"), content="Err(Invalid character 'a' at line 1, column 0)")!
}

test "throws on invalid characters following a sign" {
  inspect(parse("-a"), content="Err(Invalid character 'a' at line 1, column 1)")!
}

test "throws on invalid characters following a leading decimal point" {
  inspect(
    parse("1.a"),
    content="Err(Invalid character 'a' at line 1, column 2)",
  )!
}

test "throws on invalid characters following an exponent indicator" {
  inspect(
    parse("1ea"),
    content="Err(Invalid character 'a' at line 1, column 2)",
  )!
}

test "throws on invalid characters following an exponent sign" {
  inspect(
    parse("1e-a"),
    content="Err(Invalid character 'a' at line 1, column 3)",
  )!
}

test "throws on invalid new lines in strings" {
  let res = parse("\"\n\"")
  @assertion.assert_eq(res, Err(InvalidChar({ line: 1, column: 1 }, '\n')))!
}

test "throws on unterminated strings" {
  inspect(parse("\""), content="Err(Unexpected end of file)")!
}

test "throws on invalid identifier start characters in property names" {
  inspect(
    parse("{!:1}"),
    content="Err(Invalid character '!' at line 1, column 1)",
  )!
}

test "throws on invalid characters following a property name" {
  inspect(
    parse("{\"a\"!1}"),
    content="Err(Invalid character '!' at line 1, column 4)",
  )!
}

test "throws on invalid characters following a property value" {
  inspect(
    parse("{\"a\":1!}"),
    content="Err(Invalid character '!' at line 1, column 6)",
  )!
}

test "throws on invalid characters following an array value" {
  inspect(
    parse("[1!]"),
    content="Err(Invalid character '!' at line 1, column 2)",
  )!
}

test "throws on invalid characters in literals" {
  inspect(
    parse("tru!"),
    content="Err(Invalid character '!' at line 1, column 3)",
  )!
}

test "throws on unterminated escapes" {
  inspect(parse("\"\\"), content="Err(Unexpected end of file)")!
}

test "throws on invalid unicode escapes" {
  inspect(
    parse("\"\\u000g\""),
    content="Err(Invalid character 'g' at line 1, column 6)",
  )!
}

test "throws on escaped digits" {
  inspect(
    parse("\"\\0\""),
    content="Err(Invalid character '0' at line 1, column 2)",
  )!
  inspect(
    parse("\"\\1\""),
    content="Err(Invalid character '1' at line 1, column 2)",
  )!
}

test "throws on multiple values" {
  inspect(
    parse("1 2"),
    content="Err(Invalid character '2' at line 1, column 2)",
  )!
}

test "throws on unclosed objects before property names" {
  inspect(parse("{"), content="Err(Unexpected end of file)")!
}

test "throws on unclosed objects after property names" {
  inspect(parse("{\"a\""), content="Err(Unexpected end of file)")!
}

test "throws on unclosed objects before property values" {
  inspect(parse("{\"a\":"), content="Err(Unexpected end of file)")!
}

test "throws on unclosed objects after property values" {
  inspect(parse("{\"a\":1"), content="Err(Unexpected end of file)")!
}

test "throws on unclosed arrays before values" {
  inspect(parse("["), content="Err(Unexpected end of file)")!
}

test "throws on unclosed arrays after values" {
  inspect(parse("[1"), content="Err(Unexpected end of file)")!
}

test "throws on invalid property names" {
  inspect(
    parse("{a:1}"),
    content="Err(Invalid character 'a' at line 1, column 1)",
  )!
}

test "throws on array with extra comma" {
  inspect(
    parse("[1,]"),
    content="Err(Invalid character ']' at line 1, column 3)",
  )!
  inspect(
    parse("[\"\",]"),
    content="Err(Invalid character ']' at line 1, column 4)",
  )!
}

test "throws on object with extra comma" {
  inspect(
    parse("{\"id\":0,}"),
    content="Err(Invalid character '}' at line 1, column 8)",
  )!
}

test "throws on invalid number" {
  inspect(parse("+1"), content="Err(Invalid character '+' at line 1, column 0)")!
  inspect(parse("-2."), content="Err(Unexpected end of file)")!
  inspect(
    parse(".2e-3"),
    content="Err(Invalid character '.' at line 1, column 0)",
  )!
  inspect(
    parse("0.e1"),
    content="Err(Invalid character 'e' at line 1, column 2)",
  )!
  inspect(
    parse("2.e+3"),
    content="Err(Invalid character 'e' at line 1, column 2)",
  )!
  inspect(
    parse("2.e-3"),
    content="Err(Invalid character 'e' at line 1, column 2)",
  )!
  inspect(
    parse("-.123"),
    content="Err(Invalid character '.' at line 1, column 1)",
  )!
  inspect(parse("1."), content="Err(Unexpected end of file)")!
  inspect(
    parse(".123"),
    content="Err(Invalid character '.' at line 1, column 0)",
  )!
  inspect(
    parse("[1.]"),
    content="Err(Invalid character ']' at line 1, column 3)",
  )!
}

test "throws on invalid chars" {
  inspect(
    parse("[\u000c]"),
    content="Err(Invalid character '\x0c' at line 1, column 1)",
  )!
  inspect(
    parse("[\"\u0009\"]"),
    content="Err(Invalid character '\t' at line 1, column 2)",
  )!
  inspect(
    parse("[\"a\u0000a\"]"),
    content="Err(Invalid character '\x00' at line 1, column 3)",
  )!
}

//endregion
