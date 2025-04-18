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
test "get as null" {
  inspect!(Null |> @json.as_null, content="Some(())")
  inspect!(True |> @json.as_null, content="None")
  inspect!(False |> @json.as_null, content="None")
  inspect!(Number(1.0) |> @json.as_null, content="None")
  inspect!(String("Hello World") |> @json.as_null, content="None")
  inspect!(Array([String("Hello World")]) |> @json.as_null, content="None")
  inspect!(
    Object({ "key": String("key"), "value": Number(100.0) }) |> @json.as_null,
    content="None",
  )
}

///|
test "get as bool" {
  inspect!(Json::Null |> @json.as_bool, content="None")
  inspect!(Json::True |> @json.as_bool, content="Some(true)")
  inspect!(Json::False |> @json.as_bool, content="Some(false)")
  inspect!(Json::Number(1.0) |> @json.as_bool, content="None")
  inspect!(Json::String("Hello World") |> @json.as_bool, content="None")
  inspect!(
    Json::Array([Json::String("Hello World")]) |> @json.as_bool,
    content="None",
  )
  inspect!({ "key": "key", "value": 100.0 } |> @json.as_bool, content="None")
}

///|
fn check!(x : String) -> Json {
  @json.parse!(x)
}

///|
fn check2!(x : String) -> Json!@json.ParseError {
  @json.parse!(x)
}

///|
test "get as number" {
  let _ = check
  let _ = check2
  inspect!(Json::Null |> @json.as_number, content="None")
  inspect!(Json::False |> @json.as_number, content="None")
  inspect!(Json::True |> @json.as_number, content="None")
  inspect!(Json::Number(1.0) |> @json.as_number, content="Some(1)")
  inspect!(Json::String("Hello World") |> @json.as_number, content="None")
  inspect!(
    Json::Array([Json::String("Hello World")]) |> @json.as_number,
    content="None",
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    |> @json.as_number,
    content="None",
  )
}

///|
test "get as string" {
  inspect!(Json::Null |> @json.as_string, content="None")
  inspect!(Json::True |> @json.as_string, content="None")
  inspect!(Json::False |> @json.as_string, content="None")
  inspect!(Json::Number(1.0) |> @json.as_string, content="None")
  inspect!(
    Json::String("Hello World") |> @json.as_string,
    content=
      #|Some("Hello World")
    ,
  )
  inspect!(
    Json::Array([Json::String("Hello World")]) |> @json.as_string,
    content="None",
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    |> @json.as_string,
    content="None",
  )
}

///|
test "get as array" {
  inspect!(Json::Null |> @json.as_array, content="None")
  inspect!(Json::True |> @json.as_array, content="None")
  inspect!(Json::False |> @json.as_array, content="None")
  inspect!(Json::Number(1.0) |> @json.as_array, content="None")
  inspect!(Json::String("Hello World") |> @json.as_array, content="None")
  inspect!(
    Json::Array([Json::String("Hello World")]) |> @json.as_array,
    content=
      #|Some([String("Hello World")])
    ,
  )
  inspect!(
    Json::Array([Json::String("Hello World")]).item(0).bind(@json.as_string),
    content=
      #|Some("Hello World")
    ,
  )
  inspect!(
    Json::Array([Json::String("Hello World")]).item(1).bind(@json.as_string),
    content="None",
  )
  inspect!(
    Json::Array([Json::String("Hello World")]).item(0).bind(@json.as_number),
    content="None",
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    |> @json.as_array,
    content="None",
  )
}

///|
test "get as object" {
  inspect!(
    Json::Null |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    Json::True |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    Json::False |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    Json::Number(1.0) |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    Json::String("Hello World") |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    Json::Array([Json::String("Hello World")])
    |> @json.as_object
    |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    |> @json.as_object
    |> @option.map(Map::to_array),
    content=
      #|Some([("key", String("key")), ("value", Number(100))])
    ,
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    .value("key")
    .bind(@json.as_string),
    content=
      #|Some("key")
    ,
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    .value("value")
    .bind(@json.as_number),
    content="Some(100)",
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    .value("key")
    .bind(@json.as_number),
    content="None",
  )
  inspect!(
    Json::Object(
      Map::of([("key", Json::String("key")), ("value", Json::Number(100.0))]),
    )
    .value("asdf")
    .bind(@json.as_number),
    content="None",
  )
}

///|
test "deep access" {
  let json : Json = {
    "key": [1.0, true, Null, [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": Null,
    "bool": false,
    "obj": {},
  }
  inspect!(json.value("null").bind(@json.as_null), content="Some(())")
  inspect!(
    json.value("key").bind(fn { array => array.item(2) }).bind(@json.as_null),
    content="Some(())",
  )
  inspect!(json.value("bool").bind(@json.as_bool), content="Some(false)")
  inspect!(
    json.value("key").bind(fn { array => array.item(1) }).bind(@json.as_bool),
    content="Some(true)",
  )
  inspect!(
    json.value("key").bind(@json.as_array),
    content=
      #|Some([Number(1), True, Null, Array([]), Object({"key": String("value"), "value": Number(100)})])
    ,
  )
  inspect!(
    json.value("key").bind(fn { array => array.item(3) }).bind(@json.as_array),
    content="Some([])",
  )
  inspect!(
    json
    .value("key")
    .bind(fn { array => array.item(4) })
    .bind(@json.as_object)
    .map(Map::to_array),
    content=
      #|Some([("key", String("value")), ("value", Number(100))])
    ,
  )
  inspect!(
    json.value("obj").bind(@json.as_object).map(Map::to_array),
    content="Some([])",
  )
}

///|
test "stringify" {
  let json : Json = {
    "key": [1.0, true, Null, [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": Null,
    "bool": false,
    "obj": {},
  }
  inspect!(
    json.stringify(),
    content=
      #|{"key":[1,true,null,[],{"key":"value","value":100}],"int":12345,"double":123.45,"null":null,"bool":false,"obj":{}}
    ,
  )

  // not mut once we have `try except else` syntax
  // we do come across issues like ParseError not unified with String
  let newjson = @json.parse!(json.stringify())
  match json {
    { "key": [_, _, _, _, { "value": Number(i), .. }, ..], .. } =>
      inspect!(i, content="100")
    _ => fail!("Failed to match the JSON")
  }
  assert_eq!(newjson, json)
}

///|
let json : Json = {
  "\b": "\"hello\"",
  "\n": "\n\r\t\u{0C}",
  "\\": "/",
  "\u001F": "\u{0001}",
  "actual": "\u{0000}",
  "escape": "\u{0000}",
  "actual": "a,\"b\",c",
}

///|
test "stringify escape 1 " {
  inspect!(
    json.stringify(),
    content=
      #|{"\b":"\"hello\"","\n":"\n\r\t\f","\\":"/","\u001f":"\u0001","actual":"a,\"b\",c","escape":"\u0000"}
    ,
  )
}

///|
test "stringify escape 2" {
  inspect!(
    json.stringify(escape_slash=true),
    content=
      #|{"\b":"\"hello\"","\n":"\n\r\t\f","\\":"\/","\u001f":"\u0001","actual":"a,\"b\",c","escape":"\u0000"}
    ,
  )
}

///|
test "stringify escape 3" {
  inspect!(
    json.stringify(escape_slash=false, indent=2),
    content=
      #|{
      #|  "\b": "\"hello\"",
      #|  "\n": "\n\r\t\f",
      #|  "\\": "/",
      #|  "\u001f": "\u0001",
      #|  "actual": "a,\"b\",c",
      #|  "escape": "\u0000"
      #|}
    ,
  )
}

///|
test "stringify escape 4" {
  inspect!(
    json.stringify(escape_slash=false),
    content=
      #|{"\b":"\"hello\"","\n":"\n\r\t\f","\\":"/","\u001f":"\u0001","actual":"a,\"b\",c","escape":"\u0000"}
    ,
  )
}

///|
test "stringify escape round trip" {
  match @json.parse?(json.stringify()) {
    Err(e) => raise e
    Ok(newjson) => assert_eq!(newjson, json)
  }
}

///|
test "string from and to json round trip" {
  let greeting =
    #|
    #|     (\(\
    #|     ( -.-)
    #|     o_(")(")
    #|     __  __     ____         __  ___                  ____  _ __
    #|    / / / /__  / / /___     /  |/  /___  ____  ____  / __ )(_) /_
    #|   / /_/ / _ \/ / / __ \   / /|_/ / __ \/ __ \/ __ \/ __  / / __/
    #|  / __  /  __/ / / /_/ /  / /  / / /_/ / /_/ / / / / /_/ / / /_
    #| /_/ /_/\___/_/_/\____/  /_/  /_/\____/\____/_/ /_/_____/_/\__/
    #|
  assert_eq!(@json.from_json!(greeting.to_json()), greeting)
}

///|
test "escape" {
  let s = "http://example.com/"
  inspect!(
    @json.stringify(String(s), escape_slash=true),
    content=
      #|"http:\/\/example.com\/"
    ,
  )
  inspect!(
    @json.stringify(String(s)),
    content=
      #|"http://example.com/"
    ,
  )
}

///|
test "stringify number" {
  let nums : Array[Json] = [
    0.0,
    -0.0,
    1.0,
    12345,
    123.45,
    9223372036854775807,
    9223372036854775808,
    999999999999223372036854775808,
    @double.min_value.to_json(),
    @double.max_value.to_json(),
    @double.not_a_number.to_json(),
    @double.infinity.to_json(),
    @double.neg_infinity.to_json(),
  ]
  inspect!(nums[0].stringify(), content="0")
  inspect!(nums[1].stringify(), content="0")
  inspect!(nums[2].stringify(), content="1")
  inspect!(nums[3].stringify(), content="12345")
  inspect!(nums[4].stringify(), content="123.45")
  inspect!(nums[5].stringify(), content="9223372036854776000")
  inspect!(nums[6].stringify(), content="9223372036854776000")
  inspect!(nums[7].stringify(), content="9.999999999992234e+29")
  inspect!(nums[8].stringify(), content="-1.7976931348623157e+308")
  inspect!(nums[9].stringify(), content="1.7976931348623157e+308")
  inspect!(nums[10].stringify(), content="null")
  inspect!(nums[11].stringify(), content="null")
  inspect!(nums[12].stringify(), content="null")
  let err : Array[String] = []
  for json in nums {
    match @json.parse?(json.stringify()) {
      Err(e) => err.push(e.to_string())
      Ok(newjson) => assert_eq!(newjson, json)
    }
  }
  inspect!(err, content="[]")
}

///|
test "stringify with indent" {
  let json : Json = {
    "key": [1.0, true, Null, [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": Null,
    "bool": false,
    "obj": {},
  }
  inspect!(
    json.stringify(indent=0),
    content=
      #|{"key":[1,true,null,[],{"key":"value","value":100}],"int":12345,"double":123.45,"null":null,"bool":false,"obj":{}}
    ,
  )
  inspect!(
    json.stringify(indent=1),
    content=
      #|{
      #| "key": [
      #|  1,
      #|  true,
      #|  null,
      #|  [],
      #|  {
      #|   "key": "value",
      #|   "value": 100
      #|  }
      #| ],
      #| "int": 12345,
      #| "double": 123.45,
      #| "null": null,
      #| "bool": false,
      #| "obj": {}
      #|}
    ,
  )
  inspect!(
    json.stringify(indent=2),
    content=
      #|{
      #|  "key": [
      #|    1,
      #|    true,
      #|    null,
      #|    [],
      #|    {
      #|      "key": "value",
      #|      "value": 100
      #|    }
      #|  ],
      #|  "int": 12345,
      #|  "double": 123.45,
      #|  "null": null,
      #|  "bool": false,
      #|  "obj": {}
      #|}
    ,
  )
  inspect!(
    json.stringify(indent=4),
    content=
      #|{
      #|    "key": [
      #|        1,
      #|        true,
      #|        null,
      #|        [],
      #|        {
      #|            "key": "value",
      #|            "value": 100
      #|        }
      #|    ],
      #|    "int": 12345,
      #|    "double": 123.45,
      #|    "null": null,
      #|    "bool": false,
      #|    "obj": {}
      #|}
    ,
  )
}

///|
test "Bool from_json with invalid input" {
  let json_null = Json::Null
  let result : Result[Bool, _] = @json.from_json?(json_null)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "Bool::from_json: expected boolean")))
    ,
  )
  let json_num = Json::Number(123)
  let result2 : Result[Bool, _] = @json.from_json?(json_num)
  inspect!(
    result2,
    content=
      #|Err(JsonDecodeError(($, "Bool::from_json: expected boolean")))
    ,
  )
}

///|
test "Int64 from_json error cases" {
  // Test with non-string input
  let json_num = Json::Number(123)
  let result : Result[Int64, _] = @json.from_json?(json_num)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "Int64::from_json: expected number in string representation")))
    ,
  )

  // Test with invalid string input
  let json_str = Json::String("not_a_number")
  let result2 : Result[Int64, _] = @json.from_json?(json_str)
  inspect!(
    result2,
    content=
      #|Err(JsonDecodeError(($, "Int64::from_json: parsing failure invalid syntax")))
    ,
  )
}

///|
test "UInt from_json with invalid input" {
  let json_str = Json::String("123")
  let result : Result[UInt, _] = @json.from_json?(json_str)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "UInt::from_json: expected number")))
    ,
  )
}

///|
test "UInt64 from_json error cases" {
  // Test with non-string input
  let json_num = Json::Number(123)
  let result : Result[UInt64, _] = @json.from_json?(json_num)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "UInt64::from_json: expected number in string representation")))
    ,
  )

  // Test with invalid string input
  let json_str = Json::String("not_a_number")
  let result2 : Result[UInt64, _] = @json.from_json?(json_str)
  inspect!(
    result2,
    content=
      #|Err(JsonDecodeError(($, "UInt64::from_json: parsing failure invalid syntax")))
    ,
  )
}

///|
test "String and View from_json with invalid input" {
  let json_num = Json::Number(123)

  // Test String
  let result1 : Result[String, _] = @json.from_json?(json_num)
  inspect!(
    result1,
    content=
      #|Err(JsonDecodeError(($, "String::from_json: expected string")))
    ,
  )

  // Test View
  let result2 : Result[@string.View, _] = @json.from_json?(json_num)
  inspect!(
    result2,
    content=
      #|Err(JsonDecodeError(($, "View::from_json: expected string")))
    ,
  )
}

///|
test "Char from_json error cases" {
  // Test with non-string input
  let json_num = Json::Number(123)
  let result : Result[Char, _] = @json.from_json?(json_num)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "Char::from_json: expected string")))
    ,
  )

  // Test with multi-character string
  let json_str = Json::String("abc")
  let result2 : Result[Char, _] = @json.from_json?(json_str)
  inspect!(
    result2,
    content=
      #|Err(JsonDecodeError(($, "Char::from_json: expected single character")))
    ,
  )
}

///|
test "BigInt from_json with invalid input" {
  let json_num = Json::Number(123)
  let result : Result[BigInt, _] = @json.from_json?(json_num)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "BigInt::from_json: expected number")))
    ,
  )
}

///|
test "Array and FixedArray from_json with invalid input" {
  let json_num = Json::Number(123)
  let result1 : Result[Array[Int], _] = @json.from_json?(json_num)
  inspect!(
    result1,
    content=
      #|Err(JsonDecodeError(($, "Array::from_json: expected array")))
    ,
  )
  let result2 : Result[FixedArray[Int], _] = @json.from_json?(json_num)
  inspect!(
    result2,
    content=
      #|Err(JsonDecodeError(($, "FixedArray::from_json: expected array")))
    ,
  )
}

///|
test "Map from_json with invalid input" {
  let json_num = Json::Number(123)
  let result : Result[Map[String, Int], _] = @json.from_json?(json_num)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "Map::from_json: expected object")))
    ,
  )
}

///|
test "Option from_json with invalid input" {
  let json_obj = Json::Object({ "key": Json::Number(123) })
  let result : Result[Int?, _] = @json.from_json?(json_obj)
  inspect!(
    result,
    content=
      #|Err(JsonDecodeError(($, "Option::from_json: expected array or null")))
    ,
  )
}

///|
test "Result from_json error cases" {
  let json_num = Json::Number(123)

  // Test with non-object
  inspect!(
    @json.from_json?(json_num),
    content=
      #|Err(JsonDecodeError(($, "Unit::from_json: expected null")))
    ,
  )

  // Test with object with more than one field
  let json_obj = Json::Object({
    "Ok": Json::Number(123),
    "Extra": Json::Number(456),
  })
  inspect!(
    @json.from_json?(json_obj),
    content=
      #|Err(JsonDecodeError(($, "Unit::from_json: expected null")))
    ,
  )

  // Test with object with invalid field name
  let json_obj2 = Json::Object({ "Invalid": Json::Number(123) })
  inspect!(
    @json.from_json?(json_obj2),
    content=
      #|Err(JsonDecodeError(($, "Unit::from_json: expected null")))
    ,
  )
}

///|
test "Unit from_json with invalid input" {
  let json_num = Json::Number(123)
  inspect!(
    @json.from_json?(json_num),
    content=
      #|Err(JsonDecodeError(($, "Unit::from_json: expected null")))
    ,
  )
}
