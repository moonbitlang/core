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
  inspect(Json::null().as_null(), content="Some(())")
  inspect(Json::boolean(true).as_null(), content="None")
  inspect(Json::boolean(false).as_null(), content="None")
  inspect(Json::number(1.0).as_null(), content="None")
  inspect(Json::string("Hello World").as_null(), content="None")
  inspect(Json::array([Json::string("Hello World")]).as_null(), content="None")
  inspect(
    Json::object({ "key": Json::string("key"), "value": Json::number(100.0) }).as_null(),
    content="None",
  )
}

///|
test "get as bool" {
  inspect(Json::null().as_bool(), content="None")
  inspect(Json::boolean(true).as_bool(), content="Some(true)")
  inspect(Json::boolean(false).as_bool(), content="Some(false)")
  inspect(Json::number(1.0).as_bool(), content="None")
  inspect(Json::string("Hello World").as_bool(), content="None")
  inspect(Json::array([Json::string("Hello World")]).as_bool(), content="None")
  inspect(Json::as_bool({ "key": "key", "value": 100.0 }), content="None")
}

///|
fn _check(x : String) -> Json raise {
  @json.parse(x)
}

///|
fn _check2(x : String) -> Json raise @json.ParseError {
  @json.parse(x)
}

///|
test "get as number" {
  inspect(Json::null().as_number(), content="None")
  inspect(Json::boolean(false).as_number(), content="None")
  inspect(Json::boolean(true).as_number(), content="None")
  inspect(Json::number(1.0).as_number(), content="Some(1)")
  inspect(Json::string("Hello World").as_number(), content="None")
  inspect(
    Json::array([Json::string("Hello World")]).as_number(),
    content="None",
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    ).as_number(),
    content="None",
  )
}

///|
test "get as string" {
  inspect(Json::null().as_string(), content="None")
  inspect(Json::boolean(true).as_string(), content="None")
  inspect(Json::boolean(false).as_string(), content="None")
  inspect(Json::number(1.0).as_string(), content="None")
  inspect(
    Json::string("Hello World").as_string(),
    content=(
      #|Some("Hello World")
    ),
  )
  inspect(
    Json::array([Json::string("Hello World")]).as_string(),
    content="None",
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    ).as_string(),
    content="None",
  )
}

///|
test "get as array" {
  inspect(Json::null().as_array(), content="None")
  inspect(Json::boolean(true).as_array(), content="None")
  inspect(Json::boolean(false).as_array(), content="None")
  inspect(Json::number(1.0).as_array(), content="None")
  inspect(Json::string("Hello World").as_array(), content="None")
  inspect(
    Json::array([Json::string("Hello World")]).as_array(),
    content=(
      #|Some([String("Hello World")])
    ),
  )
  inspect(
    Json::array([Json::string("Hello World")]).item(0).bind(Json::as_string),
    content=(
      #|Some("Hello World")
    ),
  )
  inspect(
    Json::array([Json::string("Hello World")]).item(1).bind(Json::as_string),
    content="None",
  )
  inspect(
    Json::array([Json::string("Hello World")]).item(0).bind(Json::as_number),
    content="None",
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    ).as_array(),
    content="None",
  )
}

///|
test "get as object" {
  inspect(Json::null().as_object().map(_.to_array()), content="None")
  inspect(Json::boolean(true).as_object().map(_.to_array()), content="None")
  inspect(Json::boolean(false).as_object().map(_.to_array()), content="None")
  inspect(Json::number(1.0).as_object().map(_.to_array()), content="None")
  inspect(
    Json::string("Hello World").as_object().map(_.to_array()),
    content="None",
  )
  inspect(
    Json::array([Json::string("Hello World")]).as_object().map(_.to_array()),
    content="None",
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    )
    .as_object()
    .map(_.to_array()),
    content=(
      #|Some([("key", String("key")), ("value", Number(100))])
    ),
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    )
    .value("key")
    .bind(_.as_string()),
    content=(
      #|Some("key")
    ),
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    )
    .value("value")
    .bind(_.as_number()),
    content="Some(100)",
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    )
    .value("key")
    .bind(_.as_number()),
    content="None",
  )
  inspect(
    Json::object(
      Map::of([("key", Json::string("key")), ("value", Json::number(100.0))]),
    )
    .value("asdf")
    .bind(_.as_number()),
    content="None",
  )
}

///|
test "deep access" {
  let json : Json = {
    "key": [1.0, true, Json::null(), [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": Json::null(),
    "bool": false,
    "obj": {},
  }
  inspect(json.value("null").bind(_.as_null()), content="Some(())")
  inspect(
    json.value("key").bind(_.item(2)).bind(_.as_null()),
    content="Some(())",
  )
  inspect(json.value("bool").bind(_.as_bool()), content="Some(false)")
  inspect(
    json.value("key").bind(_.item(1)).bind(_.as_bool()),
    content="Some(true)",
  )
  inspect(
    json.value("key").bind(_.as_array()),
    content=(
      #|Some([Number(1), True, Null, Array([]), Object({"key": String("value"), "value": Number(100)})])
    ),
  )
  inspect(
    json.value("key").bind(_.item(3)).bind(_.as_array()),
    content="Some([])",
  )
  inspect(
    json.value("key").bind(_.item(4)).bind(_.as_object()).map(_.to_array()),
    content=(
      #|Some([("key", String("value")), ("value", Number(100))])
    ),
  )
  inspect(
    json.value("obj").bind(_.as_object()).map(_.to_array()),
    content="Some([])",
  )
}

///|
test "stringify" {
  let json : Json = {
    "key": [1.0, true, Json::null(), [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": Json::null(),
    "bool": false,
    "obj": {},
  }
  inspect(
    json.stringify(),
    content=(
      #|{"key":[1,true,null,[],{"key":"value","value":100}],"int":12345,"double":123.45,"null":null,"bool":false,"obj":{}}
    ),
  )

  // not mut once we have `try except else` syntax
  // we do come across issues like ParseError not unified with String
  let newjson = @json.parse(json.stringify())
  match json {
    { "key": [_, _, _, _, { "value": Number(i, ..), .. }, ..], .. } =>
      inspect(i, content="100")
    _ => fail("Failed to match the JSON")
  }
  assert_eq(newjson, json)
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
  inspect(
    json.stringify(),
    content=(
      #|{"\b":"\"hello\"","\n":"\n\r\t\f","\\":"/","\u001f":"\u0001","actual":"a,\"b\",c","escape":"\u0000"}
    ),
  )
}

///|
test "stringify escape 2" {
  inspect(
    json.stringify(escape_slash=true),
    content=(
      #|{"\b":"\"hello\"","\n":"\n\r\t\f","\\":"\/","\u001f":"\u0001","actual":"a,\"b\",c","escape":"\u0000"}
    ),
  )
}

///|
test "stringify escape 3" {
  inspect(
    json.stringify(escape_slash=false, indent=2),
    content=(
      #|{
      #|  "\b": "\"hello\"",
      #|  "\n": "\n\r\t\f",
      #|  "\\": "/",
      #|  "\u001f": "\u0001",
      #|  "actual": "a,\"b\",c",
      #|  "escape": "\u0000"
      #|}
    ),
  )
}

///|
test "stringify escape 4" {
  inspect(
    json.stringify(escape_slash=false),
    content=(
      #|{"\b":"\"hello\"","\n":"\n\r\t\f","\\":"/","\u001f":"\u0001","actual":"a,\"b\",c","escape":"\u0000"}
    ),
  )
}

///|
test "stringify escape round trip" {
  let newjson = @json.parse(json.stringify())
  assert_eq(newjson, json)
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
  assert_eq(@json.from_json(greeting.to_json()), greeting)
}

///|
test "escape" {
  let s = "http://example.com/"
  inspect(
    Json::string(s).stringify(escape_slash=true),
    content=(
      #|"http:\/\/example.com\/"
    ),
  )
  inspect(
    Json::string(s).stringify(),
    content=(
      #|"http://example.com/"
    ),
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
  inspect(nums[0].stringify(), content="0")
  inspect(nums[1].stringify(), content="0")
  inspect(nums[2].stringify(), content="1")
  inspect(nums[3].stringify(), content="12345")
  inspect(nums[4].stringify(), content="123.45")
  inspect(nums[5].stringify(), content="9223372036854776000")
  inspect(nums[6].stringify(), content="9223372036854776000")
  inspect(nums[7].stringify(), content="9.999999999992234e+29")
  inspect(nums[8].stringify(), content="-1.7976931348623157e+308")
  inspect(nums[9].stringify(), content="1.7976931348623157e+308")
  inspect(nums[10].stringify(), content="null")
  inspect(nums[11].stringify(), content="null")
  inspect(nums[12].stringify(), content="null")
  let err : Array[String] = []
  for json in nums {
    let json = @json.parse(json.stringify()) catch {
      e => {
        err.push(e.to_string())
        continue
      }
    }
    match json {
      Number(_, repr~) as newjson =>
        if repr is Some(_) {
          assert_eq(newjson.stringify(), json.stringify())
        } else {
          assert_eq(newjson, json)
        }
      newjson => assert_eq(newjson, json)
    }
  }
  inspect(err, content="[]")
}

///|
test "stringify with indent" {
  let json : Json = {
    "key": [1.0, true, Json::null(), [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": Json::null(),
    "bool": false,
    "obj": {},
  }
  inspect(
    json.stringify(indent=0),
    content=(
      #|{"key":[1,true,null,[],{"key":"value","value":100}],"int":12345,"double":123.45,"null":null,"bool":false,"obj":{}}
    ),
  )
  inspect(
    json.stringify(indent=1),
    content=(
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
    ),
  )
  inspect(
    json.stringify(indent=2),
    content=(
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
    ),
  )
  inspect(
    json.stringify(indent=4),
    content=(
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
    ),
  )
}

///|
test "nested json" {
  struct X {
    w : Int
  } derive(ToJson)
  let u : Int = 3
  let h = X::{ w: 3 }
  let v : Json = {
    "nestedmap": {
      "key1": u, // auto to json
      "a": h,
      "key2": "value2",
      "key3": { "subkey1": u, "subkey2": h, "subkey3": [1, 2, 3] },
    },
  }
  @json.inspect(v, content={
    "nestedmap": {
      "key1": 3,
      "a": { "w": 3 },
      "key2": "value2",
      "key3": { "subkey1": 3, "subkey2": { "w": 3 }, "subkey3": [1, 2, 3] },
    },
  })
}

///|
test "to_yaml - null value" {
  let json = Json::null()
  inspect(json.to_yaml(), content="null")
}

///|
test "to_yaml - boolean values" {
  let json_true = Json::boolean(true)
  let json_false = Json::boolean(false)
  inspect(json_true.to_yaml(), content="true")
  inspect(json_false.to_yaml(), content="false")
}

///|
test "to_yaml - number values" {
  let json = Json::number(42.5)
  inspect(json.to_yaml(), content="42.5")
  let json_with_repr = Json::number(1.0 / 0.0, repr="Infinity")
  inspect(json_with_repr.to_yaml(), content="Infinity")
}

///|
test "to_yaml - string values" {
  // Simple string
  let json = Json::string("hello")
  inspect(json.to_yaml(), content="hello")

  // String that needs quotes (looks like number)
  let json_num = Json::string("123")
  inspect(json_num.to_yaml(), content="\"123\"")

  // String that needs quotes (looks like boolean)
  let json_bool = Json::string("true")
  inspect(json_bool.to_yaml(), content="\"true\"")

  // String with special characters
  let json_special = Json::string("hello: world")
  inspect(json_special.to_yaml(), content="\"hello: world\"")

  // String with newline
  let json_newline = Json::string("hello\nworld")
  inspect(json_newline.to_yaml(), content="\"hello\\nworld\"")

  // Empty string
  let json_empty = Json::string("")
  inspect(json_empty.to_yaml(), content="\"\"")
}

///|
test "to_yaml - empty array" {
  let json = Json::array([])
  inspect(json.to_yaml(), content="[]")
}

///|
test "to_yaml - simple array" {
  let json = Json::array([
    Json::number(1.0),
    Json::string("hello"),
    Json::boolean(true),
    Json::null(),
  ])
  let yaml = json.to_yaml()
  inspect(yaml, content="- 1\n- hello\n- true\n- null")
}

///|
test "to_yaml - nested array" {
  let json = Json::array([
    Json::number(1.0),
    Json::array([Json::number(2.0), Json::number(3.0)]),
    Json::string("end"),
  ])
  let yaml = json.to_yaml()
  inspect(yaml, content="- 1\n- - 2\n  - 3\n- end")
}

///|
test "to_yaml - empty object" {
  let json = Json::object({})
  inspect(json.to_yaml(), content="{}")
}

///|
test "to_yaml - simple object" {
  let json = Json::object({
    "name": Json::string("John"),
    "age": Json::number(30.0),
    "active": Json::boolean(true),
  })
  // Note: Map iteration order might not be guaranteed
  let yaml = json.to_yaml()
  assert_true(yaml.contains("name: John"))
  assert_true(yaml.contains("age: 30"))
  assert_true(yaml.contains("active: true"))
}

///|
test "to_yaml - nested object" {
  let json = Json::object({
    "person": Json::object({
      "name": Json::string("John"),
      "age": Json::number(30.0),
    }),
    "items": Json::array([Json::string("item1"), Json::string("item2")]),
  })
  let yaml = json.to_yaml()
  inspect(yaml, content=(
    #|person:
    #|  name: John
    #|  age: 30
    #|items:
    #|  - item1
    #|  - item2
  ))
}

///|
test "to_yaml - array of objects" {
  let json = Json::array([
    Json::object({ "id": Json::number(1.0), "name": Json::string("First") }),
    Json::object({ "id": Json::number(2.0), "name": Json::string("Second") }),
  ])
  let yaml = json.to_yaml()
  inspect(yaml, content=(
    #|- id: 1
    #|  name: First
    #|- id: 2
    #|  name: Second
  ))
}

///|
test "to_yaml - object with array inside" {
  let json = Json::object({
    "fruits": Json::array([
      Json::string("apple"),
      Json::string("banana"),
      Json::string("orange"),
    ]),
  })
  let yaml = json.to_yaml()
  inspect(yaml, content=(
    #|fruits:
    #|  - apple
    #|  - banana
    #|  - orange
  ))
}

///|
test "to_yaml - custom indent" {
  let json = Json::object({
    "level1": Json::object({ "level2": Json::string("value") }),
  })
  let yaml_2 = json.to_yaml(indent=2)
  let yaml_4 = json.to_yaml(indent=4)
  inspect(yaml_2, content=(
    #|level1:
    #|  level2: value

  ))
  inspect(yaml_4, content=(
    #|level1:
    #|    level2: value

  ))
}

///|
test "to_yaml - special string keys" {
  let json = Json::object({
    "123": Json::string("numeric key"),
    "true": Json::string("boolean key"),
    "key:with:colons": Json::string("special chars"),
  })
  let yaml = json.to_yaml()
  inspect(yaml, content=(
    #|"123": numeric key
    #|"true": boolean key
    #|"key:with:colons": special chars
  ))
}
