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
#callsite(autofill(loc))
fn test_parse(input : String, loc~ : SourceLoc) -> Json raise Error {
  @json.parse(input) catch {
    err => fail("Parse failed, \{loc}, \{err}")
  }
}

//region objects

///|
test "parses empty object" {
  inspect(try? @json.parse("{}"), content="Ok(Object({}))")
}

///|
test "parses object" {
  inspect(
    try? @json.parse("{\"a\":1}"),
    content=(
      #|Ok(Object({"a": Number(1)}))
    ),
  )
  inspect(
    try? @json.parse("{\"a\":1,\"b\":2}"),
    content=(
      #|Ok(Object({"a": Number(1), "b": Number(2)}))
    ),
  )
}

///|
test "parses multiple properties" {
  inspect(
    try? @json.parse("{\"abc\":1,\"def\":2}"),
    content=(
      #|Ok(Object({"abc": Number(1), "def": Number(2)}))
    ),
  )
}

///|
test "parses nested objects" {
  inspect(
    try? @json.parse("{\"a\":{\"b\":2}}"),
    content=(
      #|Ok(Object({"a": Object({"b": Number(2)})}))
    ),
  )
}
//endregion

//region arrays

///|
test "parses empty arrays" {
  let json = test_parse("[]")
  assert_eq(json, Json::array([]))
}

///|
test "parses array values" {
  let json = test_parse("[1]")
  assert_eq(json, Json::array([Json::number(1.0)]))
}

///|
test "parses multiple array values" {
  let json = test_parse("[1,2]")
  assert_eq(json, Json::array([Json::number(1.0), Json::number(2.0)]))
}

///|
test "parses nested arrays" {
  let json = test_parse("[1,[2,3]]")
  assert_eq(
    json,
    Json::array([
      Json::number(1.0),
      Json::array([Json::number(2.0), Json::number(3.0)]),
    ]),
  )
}
//endregion

//region nulls

///|
test "parses nulls" {
  let json = test_parse("null")
  assert_eq(json, null)
}
//endregion

//region booleans

///|
test "parses true" {
  let json = test_parse("true")
  inspect(json, content="True")
}

///|
test "parses false" {
  let json = test_parse("false")
  inspect(json, content="False")
}
//endregion

//region numbers

///|
test "parses leading zeroes" {
  let json = test_parse("[0,0.0,0e0]")
  assert_eq(
    json,
    Json::array([Json::number(0.0), Json::number(0.0), Json::number(0.0)]),
  )
}

///|
test "parses integers" {
  let json = test_parse("[1,23,456,7890]")
  assert_eq(
    json,
    Json::array([
      Json::number(1.0),
      Json::number(23.0),
      Json::number(456.0),
      Json::number(7890.0),
    ]),
  )
}

///|
test "parses signed numbers" {
  let json = test_parse("[-1,2,-0.1,-0]")
  assert_eq(
    json,
    Json::array([
      Json::number(-1.0),
      Json::number(2.0),
      Json::number(-0.1),
      Json::number(-0.0),
    ]),
  )
}

///|
test "parses fractional numbers" {
  let json = test_parse("[1.0,1.23]")
  assert_eq(json, Json::array([Json::number(1.0), Json::number(1.23)]))
}

///|
test "parses exponents" {
  let json = test_parse("[1e0,1e1,1e01,1.0e0,1.1e0,1e-1,1e+1]")
  assert_eq(
    json,
    Json::array([
      Json::number(1.0),
      Json::number(10.0),
      Json::number(10.0),
      Json::number(1.0),
      Json::number(1.1),
      Json::number(0.1),
      Json::number(10.0),
    ]),
  )
}

///|
test "parses 1" {
  let json = test_parse("1")
  assert_eq(json, Json::number(1.0))
}

///|
test "parses +1.23e100" {
  let json = test_parse("1.23e100")
  assert_eq(json, Json::number(1.23e100))
}

//endregion

//region strings

///|
test "parses string" {
  let json = test_parse("\"abc\"")
  assert_eq(json, Json::string("abc"))
}

///|
test "parses quotes in string" {
  let json = test_parse("[\"\\\"\",\"'\"]")
  assert_eq(json, Json::array([Json::string("\""), Json::string("'")]))
}

///|
test "parses escaped characters" {
  let json = test_parse("\"\\b\\f\\n\\r\\t\\u01fF\\\"\"")
  assert_eq(json, Json::string("\u0008\u000C\n\r\t\u01FF\""))
}
//endregion

//region whitespace

///|
test "parses whitespace" {
  let json = test_parse("{\t \n\r}")
  assert_eq(json, Json::object({}))
}
//endregion

///|
test "valid" {
  inspect(@json.valid("{\"a\": 1, \"b\":2}"), content="true")
  inspect(@json.valid("{}"), content="true")
  inspect(@json.valid("{a:1, b:2}"), content="false")
  inspect(@json.valid("{"), content="false")
}

///|
test "parse unexpected token in value" {
  let result = try? @json.parse("{a:1}")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 1)")
}

///|
test "parse unexpected token in object property name" {
  let result = try? @json.parse("{\"a\":1, b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 8)")
}

///|
test "parse unexpected token after object property name" {
  let result = try? @json.parse("{\"a\" b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 5)")
}

///|
test "parse unexpected token after object value" {
  let result = try? @json.parse("{\"a\":1 b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 7)")
}

///|
test "parse unexpected token in array" {
  let result = try? @json.parse("[1, 2 a]")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 6)")
}

///|
test "parse multi-lines json" {
  let result = try? @json.parse(
    (
      #|{
      #|  "a":2,
      #|  "b":3
      #|}
    ),
  )
  inspect(
    result,
    content=(
      #|Ok(Object({"a": Number(2), "b": Number(3)}))
    ),
  )
}

///|
test "parse multi-lines json error" {
  let result = try? @json.parse(
    (
      #|{
      #|  "a":2,
      #|  "b":a
      #|}
    ),
  )
  inspect(result, content="Err(Invalid character 'a' at line 3, column 6)")
}

///|
test "parser error" {
  inspect(
    try? @json.parse("]"),
    content="Err(Invalid character ']' at line 1, column 0)",
  )
  inspect(
    try? @json.parse("}"),
    content="Err(Invalid character '}' at line 1, column 0)",
  )
  inspect(
    try? @json.parse(","),
    content="Err(Invalid character ',' at line 1, column 0)",
  )
}

///|
test "emoji" {
  inspect(
    // test first char is emoji
    try? @json.parse("\u{1F600}"),
    content="Err(Invalid character '😀' at line 1, column 0)",
  )
  inspect(
    try? @json.parse("a😀"),
    content="Err(Invalid character 'a' at line 1, column 0)",
  )
  inspect(
    try? @json.parse("a"),
    content="Err(Invalid character 'a' at line 1, column 0)",
  )
  inspect(
    // test first char is emoji (standalone emoji)
    try? @json.parse("😀"),
    content="Err(Invalid character '😀' at line 1, column 0)",
  )
}
