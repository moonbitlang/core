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

/// Try to get this element as a Null
pub fn as_null(self : JsonValue) -> Option[Unit] {
  match self {
    Null => Some(())
    _ => None
  }
}

/// Try to get this element as a Json Array and try to get the element at the `index` as a Null
/// 
/// Same as `item(index)?.as_null()`
pub fn item_as_null(self : JsonValue, index : Int) -> Option[Unit] {
  self.as_array()?.get(index)?.as_null()
}

/// Try to get this element as a Json Object and try to get the element with the `key` as a Null
/// 
/// Same as `value(key)?.as_null()`
pub fn value_as_null(self : JsonValue, key : String) -> Option[Unit] {
  self.as_object()?.lookup(key)?.as_null()
}

test "get as null" {
  inspect(JsonValue::Null |> as_null, content="Some(())")?
  inspect(JsonValue::Boolean(false) |> as_null, content="None")?
  inspect(JsonValue::Number(1.0) |> as_null, content="None")?
  inspect(JsonValue::String("Hello World") |> as_null, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]) |> as_null,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_null,
    content="None",
  )?
}

/// Try to get this element as a Boolean
pub fn as_bool(self : JsonValue) -> Option[Bool] {
  match self {
    Boolean(b) => Some(b)
    _ => None
  }
}

/// Try to get this element as a Json Array and try to get the element at the `index` as a Boolean
/// 
/// Same as `item(index)?.as_bool()`
pub fn item_as_bool(self : JsonValue, index : Int) -> Option[Bool] {
  self.as_array()?.get(index)?.as_bool()
}

/// Try to get this element as a Json Object and try to get the element with the `key` as a Boolean
/// 
/// Same as `value(key)?.as_bool()`
pub fn value_as_bool(self : JsonValue, key : String) -> Option[Bool] {
  self.as_object()?.lookup(key)?.as_bool()
}

test "get as bool" {
  inspect(JsonValue::Null |> as_bool, content="None")?
  inspect(JsonValue::Boolean(false) |> as_bool, content="Some(false)")?
  inspect(JsonValue::Number(1.0) |> as_bool, content="None")?
  inspect(JsonValue::String("Hello World") |> as_bool, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]) |> as_bool,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_bool,
    content="None",
  )?
}

/// Try to get this element as a Number
pub fn as_number(self : JsonValue) -> Option[Double] {
  match self {
    Number(n) => Some(n)
    _ => None
  }
}

/// Try to get this element as a Json Array and try to get the element at the `index` as a Number
/// 
/// Same as `item(index)?.as_number()`
pub fn item_as_number(self : JsonValue, index : Int) -> Option[Double] {
  self.as_array()?.get(index)?.as_number()
}

/// Try to get this element as a Json Object and try to get the element with the `key` as a Number
/// 
/// Same as `value(key)?.as_number()`
pub fn value_as_number(self : JsonValue, key : String) -> Option[Double] {
  self.as_object()?.lookup(key)?.as_number()
}

test "get as number" {
  inspect(JsonValue::Null |> as_number, content="None")?
  inspect(JsonValue::Boolean(false) |> as_number, content="None")?
  inspect(JsonValue::Number(1.0) |> as_number, content="Some(1.0)")?
  inspect(JsonValue::String("Hello World") |> as_number, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]) |> as_number,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_number,
    content="None",
  )?
}

/// Try to get this element as a String
pub fn as_string(self : JsonValue) -> Option[String] {
  match self {
    String(s) => Some(s)
    _ => None
  }
}

/// Try to get this element as a Json Array and try to get the element at the `index` as a String
/// 
/// Same as `item(index)?.as_string()`
pub fn item_as_string(self : JsonValue, index : Int) -> Option[String] {
  self.as_array()?.get(index)?.as_string()
}

/// Try to get this element as a Json Object and try to get the element with the `key` as a String
/// 
/// Same as `value(key)?.as_string()`
pub fn value_as_string(self : JsonValue, key : String) -> Option[String] {
  self.as_object()?.lookup(key)?.as_string()
}

test "get as string" {
  inspect(JsonValue::Null |> as_string, content="None")?
  inspect(JsonValue::Boolean(false) |> as_string, content="None")?
  inspect(JsonValue::Number(1.0) |> as_string, content="None")?
  inspect(
    JsonValue::String("Hello World") |> as_string,
    content="Some(Hello World)",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]) |> as_string,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_string,
    content="None",
  )?
}

/// Try to get this element as an Array
pub fn as_array(self : JsonValue) -> Option[@vec.Vec[JsonValue]] {
  match self {
    Array(arr) => Some(arr)
    _ => None
  }
}

/// Try to get this element as a Json Array and try to get the element at the `index` as an Array
/// 
/// Same as `item(index)?.as_array()`
pub fn item_as_array(
  self : JsonValue,
  index : Int
) -> Option[@vec.Vec[JsonValue]] {
  self.as_array()?.get(index)?.as_array()
}

/// Try to get this element as a Json Object and try to get the element with the `key` as an Array
/// 
/// Same as `value(key)?.as_array()`
pub fn value_as_array(
  self : JsonValue,
  key : String
) -> Option[@vec.Vec[JsonValue]] {
  self.as_object()?.lookup(key)?.as_array()
}

/// Try to get this element as a Json Array and get the element at the `index` as a Json Value
pub fn item(self : JsonValue, index : Int) -> Option[JsonValue] {
  self.as_array()?.get(index)
}

test "get as array" {
  inspect(JsonValue::Null |> as_array, content="None")?
  inspect(JsonValue::Boolean(false) |> as_array, content="None")?
  inspect(JsonValue::Number(1.0) |> as_array, content="None")?
  inspect(JsonValue::String("Hello World") |> as_array, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]) |> as_array,
    content="Some(Vec::[String(\"Hello World\")])",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]).item_as_string(
      0,
    ),
    content="Some(Hello World)",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]).item_as_string(
      1,
    ),
    content="None",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]).item_as_number(
      0,
    ),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_array,
    content="None",
  )?
}

/// Try to get this element as an Object
pub fn as_object(self : JsonValue) -> Option[@map.Map[String, JsonValue]] {
  match self {
    Object(obj) => Some(obj)
    _ => None
  }
}

/// Try to get this element as a Json Array and try to get the element at the `index` as an Object
/// 
/// Same as `item(index)?.as_object()`
pub fn item_as_object(
  self : JsonValue,
  index : Int
) -> Option[@map.Map[String, JsonValue]] {
  self.as_array()?.get(index)?.as_object()
}

/// Try to get this element as a Json Object and try to get the element with the `key` as an Object
/// 
/// Same as `value(key)?.as_object()`
pub fn value_as_object(
  self : JsonValue,
  key : String
) -> Option[@map.Map[String, JsonValue]] {
  self.as_object()?.lookup(key)?.as_object()
}

/// Try to get this element as a Json Object and get the element with the `key` as a Json Value
pub fn value(self : JsonValue, key : String) -> Option[JsonValue] {
  self.as_object()?.lookup(key)
}

test "get as object" {
  inspect(
    JsonValue::Null |> as_object |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::Boolean(false) |> as_object |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::Number(1.0) |> as_object |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::String("Hello World")
    |> as_object
    |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> as_object
    |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> as_object
    |> Option::map(@map.Map::to_vec),
    content="Some(Vec::[(key, String(\"key\")), (value, Number(100.0))])",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value_as_string("key"),
    content="Some(key)",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value_as_number("value"),
    content="Some(100.0)",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value_as_number("key"),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value_as_number("asdf"),
    content="None",
  )?
}

test "deep access" {
  let json = JsonValue::Object(
    @map.Map::[
      (
        "key",
        JsonValue::Array(
          @vec.Vec::[
            JsonValue::Number(1.0),
            JsonValue::Boolean(true),
            JsonValue::Null,
            JsonValue::Array(@vec.Vec::[]),
            JsonValue::Object(
              @map.Map::[
                ("key", JsonValue::String("value")),
                ("value", JsonValue::Number(100.0)),
              ],
            ),
          ],
        ),
      ),
      ("null", JsonValue::Null),
      ("bool", JsonValue::Boolean(false)),
      ("obj", JsonValue::Object(@map.Map::[])),
    ],
  )
  inspect(json.value_as_null("null"), content="Some(())")?
  inspect(
    json.value("key").bind(fn { array => array.item_as_null(2) }),
    content="Some(())",
  )?
  inspect(json.value_as_bool("bool"), content="Some(false)")?
  inspect(
    json.value("key").bind(fn { array => array.item_as_bool(1) }),
    content="Some(true)",
  )?
  inspect(
    json.value_as_array("key"),
    content="Some(Vec::[Number(1.0), Boolean(true), Null, Array(Vec::[]), Object(Map::[(\"key\", String(\"value\")), (\"value\", Number(100.0))])])",
  )?
  inspect(
    json.value("key").bind(fn { array => array.item_as_array(3) }),
    content="Some(Vec::[])",
  )?
  inspect(
    json.value("key").bind(fn { array => array.item_as_object(4) }).map(
      @map.Map::to_vec,
    ),
    content="Some(Vec::[(key, String(\"value\")), (value, Number(100.0))])",
  )?
  inspect(
    json.value_as_object("obj").map(@map.Map::to_vec),
    content="Some(Vec::[])",
  )?
  inspect(
    (fn() { json.value("key")?.item(4)?.value_as_number("value") })(),
    content="Some(100.0)",
  )?
}
