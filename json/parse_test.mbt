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

fn test_parse(
  input : String,
  ~loc : SourceLoc = _
) -> JsonValue!String {
  match parse(input) {
    Ok(json) => json
    Err(err) => 
      raise "Parse failed, \(loc), \(err)"
  }
}

//region objects
test "parses empty object" {
  inspect(parse("{}"), content="Ok(Object({}))")!
}

test "parses object" {
  inspect(parse("{\"a\":1}"), content="Ok(Object({a:Number(1.0)}))")!
  inspect(
    parse("{\"a\":1,\"b\":2}"),
    content="Ok(Object({a:Number(1.0), b:Number(2.0)}))",
  )!
}

test "parses multiple properties" {
  inspect(
    parse("{\"abc\":1,\"def\":2}"),
    content="Ok(Object({abc:Number(1.0), def:Number(2.0)}))",
  )!
}

test "parses nested objects" {
  inspect(
    parse("{\"a\":{\"b\":2}}"),
    content="Ok(Object({a:Object({b:Number(2.0)})}))",
  )!
}
//endregion

//region arrays
test "parses empty arrays" {
  let json = test_parse("[]")!
  @assertion.assert_eq(json, JsonValue::Array([]))!
}

test "parses array values" {
  let json = test_parse("[1]")!
  @assertion.assert_eq(json, JsonValue::Array([JsonValue::Number(1.0)]))!
}

test "parses multiple array values" {
  let json = test_parse("[1,2]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array([JsonValue::Number(1.0), JsonValue::Number(2.0)]),
  )!
}

test "parses nested arrays" {
  let json = test_parse("[1,[2,3]]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array(
      [
        JsonValue::Number(1.0),
        JsonValue::Array([JsonValue::Number(2.0), JsonValue::Number(3.0)]),
      ],
    ),
  )!
}
//endregion

//region nulls
test "parses nulls" {
  let json = test_parse("null")!
  @assertion.assert_eq(json, JsonValue::Null)!
}
//endregion

//region booleans
test "parses true" {
  let json = test_parse("true")!
  inspect(json, content="True")!
}

test "parses false" {
  let json = test_parse("false")!
  inspect(json, content="False")!
}
//endregion

//region numbers
test "parses leading zeroes" {
  let json = test_parse("[0,0.0,0e0]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array(
      [JsonValue::Number(0.0), JsonValue::Number(0.0), JsonValue::Number(0.0)],
    ),
  )!
}

test "parses integers" {
  let json = test_parse("[1,23,456,7890]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array(
      [
        JsonValue::Number(1.0),
        JsonValue::Number(23.0),
        JsonValue::Number(456.0),
        JsonValue::Number(7890.0),
      ],
    ),
  )!
}

test "parses signed numbers" {
  let json = test_parse("[-1,2,-0.1,-0]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array(
      [
        JsonValue::Number(-1.0),
        JsonValue::Number(2.0),
        JsonValue::Number(-0.1),
        JsonValue::Number(-0.0),
      ],
    ),
  )!
}

test "parses fractional numbers" {
  let json = test_parse("[1.0,1.23]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array([JsonValue::Number(1.0), JsonValue::Number(1.23)]),
  )!
}

test "parses exponents" {
  let json = test_parse("[1e0,1e1,1e01,1.0e0,1.1e0,1e-1,1e+1]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array(
      [
        JsonValue::Number(1.0),
        JsonValue::Number(10.0),
        JsonValue::Number(10.0),
        JsonValue::Number(1.0),
        JsonValue::Number(1.1),
        JsonValue::Number(0.1),
        JsonValue::Number(10.0),
      ],
    ),
  )!
}

test "parses 1" {
  let json = test_parse("1")!
  @assertion.assert_eq(json, JsonValue::Number(1.0))!
}

test "parses +1.23e100" {
  let json = test_parse("1.23e100")!
  @assertion.assert_eq(json, JsonValue::Number(1.23e100))!
}

//endregion

//region strings
test "parses string" {
  let json = test_parse("\"abc\"")!
  @assertion.assert_eq(json, JsonValue::String("abc"))!
}

test "parses quotes in string" {
  let json = test_parse("[\"\\\"\",\"'\"]")!
  @assertion.assert_eq(
    json,
    JsonValue::Array([JsonValue::String("\""), JsonValue::String("'")]),
  )!
}

test "parses escaped characters" {
  let json = test_parse("\"\\b\\f\\n\\r\\t\\u01fF\\\"\"")!
  @assertion.assert_eq(json, JsonValue::String("\u0008\u000C\n\r\t\u01FF\""))!
}
//endregion

//region whitespace
test "parses whitespace" {
  let json = test_parse("{\t\u000b\u000c \u00A0\uFEFF\n\r\u2028\u2029\u2003}")!
  @assertion.assert_eq(json, JsonValue::Object(of([])))!
}
//endregion

test "valid" {
  inspect(valid("{\"a\": 1, \"b\":2}"), content="true")!
  inspect(valid("{}"), content="true")!
  inspect(valid("{a:1, b:2}"), content="false")!
  inspect(valid("{"), content="false")!
}

test "parse unexpected token in value" {
  let result = parse("{a:1}")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 1)")!
}

test "parse unexpected token in object property name" {
  let result = parse("{\"a\":1, b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 8)")!
}

test "parse unexpected token after object property name" {
  let result = parse("{\"a\" b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 5)")!
}

test "parse unexpected token after object value" {
  let result = parse("{\"a\":1 b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 7)")!
}

test "parse unexpected token in array" {
  let result = parse("[1, 2 a]")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 6)")!
}

test "parse unexpected token in value" {
  let result = parse("{a:1}")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 1)")!
}

test "parse unexpected token in object property name" {
  let result = parse("{\"a\":1, b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 8)")!
}

test "parse unexpected token after object property name" {
  let result = parse("{\"a\" b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 5)")!
}

test "parse unexpected token after object value" {
  let result = parse("{\"a\":1 b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 7)")!
}

test "parse unexpected token in array" {
  let result = parse("[1, 2 a]")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 6)")!
}

test "parse unexpected token in value" {
  let result = parse("{a:1}")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 1)")!
}

test "parse unexpected token in object property name" {
  let result = parse("{\"a\":1, b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 8)")!
}

test "parse unexpected token after object property name" {
  let result = parse("{\"a\" b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 5)")!
}

test "parse unexpected token after object value" {
  let result = parse("{\"a\":1 b:2}")
  inspect(result, content="Err(Invalid character 'b' at line 1, column 7)")!
}

test "parse unexpected token in array" {
  let result = parse("[1, 2 a]")
  inspect(result, content="Err(Invalid character 'a' at line 1, column 6)")!
}
