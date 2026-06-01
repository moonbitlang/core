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
  debug_inspect(test_parse("{}"), content="Object({})")
}

///|
test "parses object" {
  debug_inspect(
    test_parse("{\"a\":1}"),
    content=(
      #|Object({ "a": Number(1) })
    ),
  )
  debug_inspect(
    test_parse("{\"a\":1,\"b\":2}"),
    content=(
      #|Object({ "a": Number(1), "b": Number(2) })
    ),
  )
}

///|
test "parses multiple properties" {
  debug_inspect(
    test_parse("{\"abc\":1,\"def\":2}"),
    content=(
      #|Object({ "abc": Number(1), "def": Number(2) })
    ),
  )
}

///|
test "parses nested objects" {
  debug_inspect(
    test_parse("{\"a\":{\"b\":2}}"),
    content=(
      #|Object({ "a": Object({ "b": Number(2) }) })
    ),
  )
}
//endregion

//region arrays

///|
test "parses empty arrays" {
  let json = test_parse("[]")
  @debug.assert_eq(json, Json::array([]))
}

///|
test "parses array values" {
  let json = test_parse("[1]")
  @debug.assert_eq(json, Json::array([Json::number(1.0)]))
}

///|
test "parses multiple array values" {
  let json = test_parse("[1,2]")
  @debug.assert_eq(json, Json::array([Json::number(1.0), Json::number(2.0)]))
}

///|
test "parses nested arrays" {
  let json = test_parse("[1,[2,3]]")
  @debug.assert_eq(
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
  @debug.assert_eq(json, null)
}
//endregion

//region booleans

///|
test "parses true" {
  let json = test_parse("true")
  debug_inspect(json, content="True")
}

///|
test "parses false" {
  let json = test_parse("false")
  debug_inspect(json, content="False")
}
//endregion

//region numbers

///|
test "parses leading zeroes" {
  let json = test_parse("[0,0.0,0e0]")
  @debug.assert_eq(
    json,
    Json::array([Json::number(0.0), Json::number(0.0), Json::number(0.0)]),
  )
}

///|
test "parses integers" {
  let json = test_parse("[1,23,456,7890]")
  @debug.assert_eq(
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
  @debug.assert_eq(
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
  @debug.assert_eq(json, Json::array([Json::number(1.0), Json::number(1.23)]))
}

///|
test "parses exponents" {
  let json = test_parse("[1e0,1e1,1e01,1.0e0,1.1e0,1e-1,1e+1]")
  @debug.assert_eq(
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
  @debug.assert_eq(json, Json::number(1.0))
}

///|
test "parses +1.23e100" {
  let json = test_parse("1.23e100")
  @debug.assert_eq(json, Json::number(1.23e100))
}

//endregion

//region strings

///|
test "parses string" {
  let json = test_parse("\"abc\"")
  @debug.assert_eq(json, Json::string("abc"))
}

///|
test "parses quotes in string" {
  let json = test_parse("[\"\\\"\",\"'\"]")
  @debug.assert_eq(json, Json::array([Json::string("\""), Json::string("'")]))
}

///|
test "parses escaped characters" {
  let json = test_parse("\"\\b\\f\\n\\r\\t\\u01fF\\\"\"")
  @debug.assert_eq(json, Json::string("\u0008\u000C\n\r\t\u01FF\""))
}
//endregion

//region whitespace

///|
test "parses whitespace" {
  let json = test_parse("{\t \n\r}")
  @debug.assert_eq(json, Json::object({}))
}

///|
test "parses leading and trailing whitespace" {
  let json = test_parse(" \n\t[1, 2]\r ")
  @debug.assert_eq(json, Json::array([Json::number(1.0), Json::number(2.0)]))
}

///|
test "parses whitespace around separators" {
  let json = test_parse("{\"a\" \n:\t1 ,\r\"b\" : [ true , false ] }")
  @debug.assert_eq(
    json,
    Json::object({
      "a": Json::number(1.0),
      "b": Json::array([Json::boolean(true), Json::boolean(false)]),
    }),
  )
}
//endregion

///|
test "valid" {
  debug_inspect(@json.valid("{\"a\": 1, \"b\":2}"), content="true")
  debug_inspect(@json.valid("{}"), content="true")
  debug_inspect(@json.valid("{a:1, b:2}"), content="false")
  debug_inspect(@json.valid("{"), content="false")
}

///|
test "parse unexpected token in value" {
  let err = expect_parse_error("{a:1}", "expected parse failure")
  debug_inspect(
    err,
    content=(
      #|InvalidChar({ line: 1, column: 1 }, 'a')
    ),
  )
}

///|
test "parse unexpected token in object property name" {
  let err = expect_parse_error("{\"a\":1, b:2}", "expected parse failure")
  debug_inspect(
    err,
    content=(
      #|InvalidChar({ line: 1, column: 8 }, 'b')
    ),
  )
}

///|
test "parse unexpected token after object property name" {
  let err = expect_parse_error("{\"a\" b:2}", "expected parse failure")
  debug_inspect(
    err,
    content=(
      #|InvalidChar({ line: 1, column: 5 }, 'b')
    ),
  )
}

///|
test "parse unexpected token after object value" {
  let err = expect_parse_error("{\"a\":1 b:2}", "expected parse failure")
  debug_inspect(
    err,
    content=(
      #|InvalidChar({ line: 1, column: 7 }, 'b')
    ),
  )
}

///|
test "parse unexpected token in array" {
  let err = expect_parse_error("[1, 2 a]", "expected parse failure")
  debug_inspect(
    err,
    content=(
      #|InvalidChar({ line: 1, column: 6 }, 'a')
    ),
  )
}

///|
test "parse multi-lines json" {
  let json = test_parse(
    (
      #|{
      #|  "a":2,
      #|  "b":3
      #|}
    ),
  )
  debug_inspect(
    json,
    content=(
      #|Object({ "a": Number(2), "b": Number(3) })
    ),
  )
}

///|
test "parse multi-lines json error" {
  let err = expect_parse_error(
    (
      #|{
      #|  "a":2,
      #|  "b":a
      #|}
    ),
    "expected parse failure",
  )
  debug_inspect(
    err,
    content=(
      #|InvalidChar({ line: 3, column: 6 }, 'a')
    ),
  )
}

///|
test "parser error" {
  debug_inspect(
    expect_parse_error("]", "expected parse failure"),
    content=(
      #|InvalidChar({ line: 1, column: 0 }, ']')
    ),
  )
  debug_inspect(
    expect_parse_error("}", "expected parse failure"),
    content=(
      #|InvalidChar({ line: 1, column: 0 }, '}')
    ),
  )
  debug_inspect(
    expect_parse_error(",", "expected parse failure"),
    content=(
      #|InvalidChar({ line: 1, column: 0 }, ',')
    ),
  )
}

///|
test "emoji" {
  debug_inspect(
    // test first char is emoji
    expect_parse_error("\u{1F600}", "expected parse failure"),
    content=(
      #|InvalidChar({ line: 1, column: 0 }, '😀')
    ),
  )
  debug_inspect(
    expect_parse_error("a😀", "expected parse failure"),
    content=(
      #|InvalidChar({ line: 1, column: 0 }, 'a')
    ),
  )
  debug_inspect(
    expect_parse_error("a", "expected parse failure"),
    content=(
      #|InvalidChar({ line: 1, column: 0 }, 'a')
    ),
  )
  debug_inspect(
    // test first char is emoji (standalone emoji)
    expect_parse_error("😀", "expected parse failure"),
    content=(
      #|InvalidChar({ line: 1, column: 0 }, '😀')
    ),
  )
}
