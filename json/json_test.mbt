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
test "deep access" {
  let json : Json = {
    "key": [1.0, true, null, [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": null,
    "bool": false,
    "obj": {},
  }
  inspect(
    if json is Object({ "null": Null, .. }) {
      Some(())
    } else {
      None
    },
    content="Some(())",
  )
  inspect(
    if json is Object({ "key": Array(arr), .. }) && arr.get(2) is Some(Null) {
      Some(())
    } else {
      None
    },
    content="Some(())",
  )
  inspect(
    if json is Object({ "bool": True | False as t, .. }) {
      Some(t is True)
    } else {
      None
    },
    content="Some(false)",
  )
  inspect(
    if json is Object({ "key": Array(arr), .. }) &&
      arr.get(1) is Some(True | False as b) {
      Some(b is True)
    } else {
      None
    },
    content="Some(true)",
  )
  inspect(
    if json is Object({ "key": Array(arr), .. }) {
      Some(arr)
    } else {
      None
    },
    content=(
      #|Some([Number(1), True, Null, Array([]), Object({"key": String("value"), "value": Number(100)})])
    ),
  )
  inspect(
    if json is Object({ "key": Array(arr), .. }) &&
      arr.get(3) is Some(Array(arr)) {
      Some(arr)
    } else {
      None
    },
    content="Some([])",
  )
  inspect(
    if json is Object({ "key": Array(arr), .. }) &&
      arr.get(4) is Some(Object(obj)) {
      Some(obj.to_array())
    } else {
      None
    },
    content=(
      #|Some([("key", String("value")), ("value", Number(100))])
    ),
  )
  inspect(
    if json is Object({ "obj": Object(obj), .. }) {
      Some(obj)
    } else {
      None
    },
    content="Some({})",
  )
}

///|
test "stringify" {
  let json : Json = {
    "key": [1.0, true, null, [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": null,
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
test "stringify with custom indents" {
  let json : Json = { "a": 1 }
  inspect(json.stringify(indent=5), content="{\n     \"a\": 1\n}")
  inspect(json.stringify(indent=7), content="{\n       \"a\": 1\n}")
}

///|
test "stringify with replacer" {
  let json : Json = { "a": 1.0, "b": 2.0, "c": 3.0, "d": 4.0 }

  // keep
  let replacer = @json.Replacer::keep(["a", "c", "e"])
  inspect(
    json.stringify(replacer~),
    content=(
      #|{"a":1,"c":3}
    ),
  )
  // exclude
  let replacer = @json.Replacer::exclude(["b", "d"])
  inspect(
    json.stringify(replacer~),
    content=(
      #|{"a":1,"c":3}
    ),
  )
  // custom logic
  let replacer = @json.Replacer::new((idx, value) => match idx {
    "b" => None
    "d" => None
    _ => Some(value)
  })
  inspect(
    json.stringify(replacer~),
    content=(
      #|{"a":1,"c":3}
    ),
  )
}

///|
test "stringify with replace recursively" {
  let json : Json = {
    "a": 1.0,
    "b": { "a": 2.0, "b": 3.0 },
    "c": [{ "a": 4.0, "b": 5.0 }, { "a": 6.0, "b": 7.0 }],
  }
  // keep
  let replacer = @json.Replacer::keep(["a"])
  inspect(
    json.stringify(replacer~),
    content=(
      #|{"a":1}
    ),
  )
  // exclude
  let replacer = @json.Replacer::exclude(["b"])
  inspect(
    json.stringify(replacer~),
    content=(
      #|{"a":1,"c":[{"a":4},{"a":6}]}
    ),
  )
  // custom logic
  let replacer = @json.Replacer::new((idx, value) => match idx {
    "b" => None
    _ => Some(value)
  })
  inspect(
    json.stringify(replacer~),
    content=(
      #|{"a":1,"c":[{"a":4},{"a":6}]}
    ),
  )
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
  inspect(
    nums[10].stringify(),
    content=(
      #|"NaN"
    ),
  )
  inspect(
    nums[11].stringify(),
    content=(
      #|"Infinity"
    ),
  )
  inspect(
    nums[12].stringify(),
    content=(
      #|"-Infinity"
    ),
  )
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
    "key": [1.0, true, null, [], { "key": "value", "value": 100.0 }],
    "int": 12345,
    "double": 123.45,
    "null": null,
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
test "call stack overflow" {
  let depth = 50000
  let json_string = StringBuilder::new()
  for _ in 0..=depth {
    json_string.write_char('[')
  }
  for _ in 0..=depth {
    json_string.write_char(']')
  }
  let _ = @json.parse(json_string.to_string()) catch { _ => null }
  let depth = 1500
  let json_string = StringBuilder::new()
  for _ in 0..=depth {
    json_string.write_char('[')
  }
  for _ in 0..=depth {
    json_string.write_char(']')
  }
  try @json.parse(json_string.to_string()) catch {
    DepthLimitExceeded => assert_true(true)
    _ => fail("should not happen")
  } noraise {
    _ => fail("should not happen")
  }

  // under windows/msvc debug mode, the function call stack limit is lower
  // that this will stackoverflow, this will not be caught by catch
  // try @json.parse(json_string.to_string(), max_nesting_depth=2000) catch {
  //   _ => dump(())
  // } noraise {
  //   _ => dump(()) // under macos
  // }
}

///|
test "stringify deep nested array" {
  // Build a deeply nested JSON array like [[[[[]]]]] with depth = 6000
  let depth = 6000
  let mut j : Json = []
  for _ in 1..=depth {
    j = [j]
  }
  let s = j.stringify()
  let expected = depth * 2 + 2 // each [ and ] plus the outermost []
  assert_eq(s.length(), expected)
}

///|
test "stringify deep nested object" {
  // Build a deeply nested object like {"a":{"a":{ ... {"a":null}}}} with depth = 6000
  let depth = 6000
  let mut j : Json = null
  for _ in 1..=depth {
    j = { "a": j }
  }
  let s = j.stringify()
  let expected = depth * 6 + 4 // each {"a": } plus the outermost null
  assert_eq(s.length(), expected)
}

///|
test "transformer" {
  // custom function
  let json : Json = { "a": 1.0, "b": { "c": 2.0, "d": [3.0, 4.0] } }
  let newjson = json.transform(
    @json.Replacer::new((_, value) => match value {
      Number(n, ..) => Some(Json::number(n * 10))
      other => Some(other)
    }),
  )
  @json.inspect(newjson, content={ "a": 10, "b": { "c": 20, "d": [3, 4] } })

  // keep
  let newjson2 = json.transform(@json.Replacer::keep(["a", "b", "c"]))
  @json.inspect(newjson2, content={ "a": 1, "b": { "c": 2 } })

  // exclude
  let newjson3 = json.transform(@json.Replacer::exclude(["a", "d"]))
  @json.inspect(newjson3, content={ "b": { "c": 2 } })
}

///|
test "transformer with array" {
  let json : Json = [1.0, { "a": 2.0 }, [3.0, 4.0]]
  let newjson = json.transform(
    @json.Replacer::new((_, value) => match value {
      Number(n, ..) => Some(Json::number(n + 1))
      other => Some(other)
    }),
  )
  @json.inspect(newjson, content=[1, { "a": 3 }, [3, 4]])

  // keep
  let newjson2 = json.transform(@json.Replacer::keep(["a"]))
  @json.inspect(newjson2, content=[1, { "a": 2 }, [3, 4]])

  // exclude
  let newjson3 = json.transform(@json.Replacer::exclude(["a"]))
  @json.inspect(newjson3, content=[1, {}, [3, 4]])
  let newjson4 : Json = [{ "a": [{ "b": [{ "c": [{ "d": 1 }] }] }] }]
  @json.inspect(newjson4.transform(@json.Replacer::exclude(["d"])), content=[
    { "a": [{ "b": [{ "c": [{}] }] }] },
  ])
}

///|
#warnings("-unused_trait_bound")
fn[A : FromJson] test_json_export(x : A) -> A {
  x
}

///|
test {
  let _ : Int = test_json_export(42)

}
