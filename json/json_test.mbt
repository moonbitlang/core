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

test "get as null" {
  inspect(JsonValue::Null |> as_null, content="Some(())")?
  inspect(JsonValue::True |> as_null, content="None")?
  inspect(JsonValue::False |> as_null, content="None")?
  inspect(JsonValue::Number(1.0) |> as_null, content="None")?
  inspect(JsonValue::String("Hello World") |> as_null, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_null,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_null,
    content="None",
  )?
}

test "get as bool" {
  inspect(JsonValue::Null |> as_bool, content="None")?
  inspect(JsonValue::True |> as_bool, content="Some(true)")?
  inspect(JsonValue::False |> as_bool, content="Some(false)")?
  inspect(JsonValue::Number(1.0) |> as_bool, content="None")?
  inspect(JsonValue::String("Hello World") |> as_bool, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_bool,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_bool,
    content="None",
  )?
}

test "get as number" {
  inspect(JsonValue::Null |> as_number, content="None")?
  inspect(JsonValue::False |> as_number, content="None")?
  inspect(JsonValue::True |> as_number, content="None")?
  inspect(JsonValue::Number(1.0) |> as_number, content="Some(1.0)")?
  inspect(JsonValue::String("Hello World") |> as_number, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_number,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_number,
    content="None",
  )?
}

test "get as string" {
  inspect(JsonValue::Null |> as_string, content="None")?
  inspect(JsonValue::True |> as_string, content="None")?
  inspect(JsonValue::False |> as_string, content="None")?
  inspect(JsonValue::Number(1.0) |> as_string, content="None")?
  inspect(
    JsonValue::String("Hello World") |> as_string,
    content="Some(Hello World)",
  )?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_string,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_string,
    content="None",
  )?
}

test "get as array" {
  inspect(JsonValue::Null |> as_array, content="None")?
  inspect(JsonValue::True |> as_array, content="None")?
  inspect(JsonValue::False |> as_array, content="None")?
  inspect(JsonValue::Number(1.0) |> as_array, content="None")?
  inspect(JsonValue::String("Hello World") |> as_array, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_array,
    content=
      #|Some([String(\"Hello World\")])
    ,
  )?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]).item(0).bind(as_string),
    content="Some(Hello World)",
  )?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]).item(1).bind(as_string),
    content="None",
  )?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]).item(0).bind(as_number),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_array,
    content="None",
  )?
}

test "get as object" {
  inspect(
    JsonValue::Null |> as_object |> Option::map(Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::True |> as_object |> Option::map(Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::False |> as_object |> Option::map(Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::Number(1.0) |> as_object |> Option::map(Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::String("Hello World") |> as_object |> Option::map(Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")])
    |> as_object
    |> Option::map(Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_object
    |> Option::map(Map::to_array),
    content=
      #|Some([(key, String(\"key\")), (value, Number(100.0))])
    ,
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("key").bind(as_string),
    content="Some(key)",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("value").bind(as_number),
    content="Some(100.0)",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("key").bind(as_number),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("asdf").bind(as_number),
    content="None",
  )?
}

test "deep access" {
  let json = JsonValue::Object(
    Map::[
      (
        "key",
        JsonValue::Array(
          [
            JsonValue::Number(1.0),
            JsonValue::True,
            JsonValue::Null,
            JsonValue::Array([]),
            JsonValue::Object(
              Map::[
                ("key", JsonValue::String("value")),
                ("value", JsonValue::Number(100.0)),
              ],
            ),
          ],
        ),
      ),
      ("null", JsonValue::Null),
      ("bool", JsonValue::False),
      ("obj", JsonValue::Object(Map::[])),
    ],
  )
  inspect(json.value("null").bind(as_null), content="Some(())")?
  inspect(
    json.value("key").bind(fn { array => array.item(2) }).bind(as_null),
    content="Some(())",
  )?
  inspect(json.value("bool").bind(as_bool), content="Some(false)")?
  inspect(
    json.value("key").bind(fn { array => array.item(1) }).bind(as_bool),
    content="Some(true)",
  )?
  inspect(
    json.value("key").bind(as_array),
    content=
      #|Some([Number(1.0), True, Null, Array([]), Object({key:String(\"value\"), value:Number(100.0)})])
    ,
  )?
  inspect(
    json.value("key").bind(fn { array => array.item(3) }).bind(as_array),
    content="Some([])",
  )?
  inspect(
    json.value("key").bind(fn { array => array.item(4) }).bind(as_object).map(
      Map::to_array,
    ),
    content=
      #|Some([(key, String(\"value\")), (value, Number(100.0))])
    ,
  )?
  inspect(
    json.value("obj").bind(as_object).map(Map::to_array),
    content="Some([])",
  )?
  inspect(
    (fn() { json.value("key")?.item(4)?.value("value")?.as_number() })(),
    content="Some(100.0)",
  )?
}

test "stringify" {
  let json = JsonValue::Object(
    Map::[
      (
        "key",
        JsonValue::Array(
          [
            JsonValue::Number(1.0),
            JsonValue::True,
            JsonValue::Null,
            JsonValue::Array([]),
            JsonValue::Object(
              Map::[
                ("key", JsonValue::String("value")),
                ("value", JsonValue::Number(100.0)),
              ],
            ),
          ],
        ),
      ),
      ("null", JsonValue::Null),
      ("bool", JsonValue::False),
      ("obj", JsonValue::Object(Map::[])),
    ],
  )
  inspect(
    json.stringify(),
    content=
      #|{"key":[1.0,true,null,[],{"key":"value","value":100.0}],"null":null,"bool":false,"obj":{}}
    ,
  )?
  @assertion.assert_true(parse(json.stringify()) == Ok(json))?
}
