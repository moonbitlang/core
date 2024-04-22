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

pub fn get_as_null(self : JsonValue) -> Option[Unit] {
  match self {
    Null => Some(())
    _ => None
  }
}

pub fn get_item_as_null(self : JsonValue, index : Int) -> Option[Unit] {
  self.get_as_array()?.get(index)?.get_as_null()
}

pub fn get_value_as_null(self : JsonValue, key : String) -> Option[Unit] {
  self.get_as_object()?.lookup(key)?.get_as_null()
}

test "get as null" {
  inspect(JsonValue::Null |> get_as_null, content="Some(())")?
  inspect(JsonValue::Boolean(false) |> get_as_null, content="None")?
  inspect(JsonValue::Number(1.0) |> get_as_null, content="None")?
  inspect(JsonValue::String("Hello World") |> get_as_null, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> get_as_null,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> get_as_null,
    content="None",
  )?
}

pub fn get_as_bool(self : JsonValue) -> Option[Bool] {
  match self {
    Boolean(b) => Some(b)
    _ => None
  }
}

pub fn get_item_as_bool(self : JsonValue, index : Int) -> Option[Bool] {
  self.get_as_array()?.get(index)?.get_as_bool()
}

pub fn get_value_as_bool(self : JsonValue, key : String) -> Option[Bool] {
  self.get_as_object()?.lookup(key)?.get_as_bool()
}

test "get as bool" {
  inspect(JsonValue::Null |> get_as_bool, content="None")?
  inspect(JsonValue::Boolean(false) |> get_as_bool, content="Some(false)")?
  inspect(JsonValue::Number(1.0) |> get_as_bool, content="None")?
  inspect(JsonValue::String("Hello World") |> get_as_bool, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> get_as_bool,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> get_as_bool,
    content="None",
  )?
}

pub fn get_as_number(self : JsonValue) -> Option[Double] {
  match self {
    Number(n) => Some(n)
    _ => None
  }
}

pub fn get_item_as_number(self : JsonValue, index : Int) -> Option[Double] {
  self.get_as_array()?.get(index)?.get_as_number()
}

pub fn get_value_as_number(self : JsonValue, key : String) -> Option[Double] {
  self.get_as_object()?.lookup(key)?.get_as_number()
}

test "get as number" {
  inspect(JsonValue::Null |> get_as_number, content="None")?
  inspect(JsonValue::Boolean(false) |> get_as_number, content="None")?
  inspect(JsonValue::Number(1.0) |> get_as_number, content="Some(1.0)")?
  inspect(JsonValue::String("Hello World") |> get_as_number, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> get_as_number,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> get_as_number,
    content="None",
  )?
}

pub fn get_as_string(self : JsonValue) -> Option[String] {
  match self {
    String(s) => Some(s)
    _ => None
  }
}

pub fn get_item_as_string(self : JsonValue, index : Int) -> Option[String] {
  self.get_as_array()?.get(index)?.get_as_string()
}

pub fn get_value_as_string(self : JsonValue, key : String) -> Option[String] {
  self.get_as_object()?.lookup(key)?.get_as_string()
}

test "get as string" {
  inspect(JsonValue::Null |> get_as_string, content="None")?
  inspect(JsonValue::Boolean(false) |> get_as_string, content="None")?
  inspect(JsonValue::Number(1.0) |> get_as_string, content="None")?
  inspect(
    JsonValue::String("Hello World") |> get_as_string,
    content="Some(Hello World)",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> get_as_string,
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> get_as_string,
    content="None",
  )?
}

pub fn get_as_array(self : JsonValue) -> Option[@vec.Vec[JsonValue]] {
  match self {
    Array(arr) => Some(arr)
    _ => None
  }
}

pub fn get_item_as_array(
  self : JsonValue,
  index : Int
) -> Option[@vec.Vec[JsonValue]] {
  self.get_as_array()?.get(index)?.get_as_array()
}

pub fn get_value_as_array(
  self : JsonValue,
  key : String
) -> Option[@vec.Vec[JsonValue]] {
  self.get_as_object()?.lookup(key)?.get_as_array()
}

pub fn get_item(self : JsonValue, index : Int) -> Option[JsonValue] {
  self.get_as_array()?.get(index)
}

test "get as array" {
  inspect(JsonValue::Null |> get_as_array, content="None")?
  inspect(JsonValue::Boolean(false) |> get_as_array, content="None")?
  inspect(JsonValue::Number(1.0) |> get_as_array, content="None")?
  inspect(JsonValue::String("Hello World") |> get_as_array, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> get_as_array,
    content="Some(Vec::[String(\"Hello World\")])",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]).get_item_as_string(
      0,
    ),
    content="Some(Hello World)",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]).get_item_as_string(
      1,
    ),
    content="None",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")]).get_item_as_number(
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
    |> get_as_array,
    content="None",
  )?
}

pub fn get_as_object(self : JsonValue) -> Option[@map.Map[String, JsonValue]] {
  match self {
    Object(obj) => Some(obj)
    _ => None
  }
}

pub fn get_item_as_object(
  self : JsonValue,
  index : Int
) -> Option[@map.Map[String, JsonValue]] {
  self.get_as_array()?.get(index)?.get_as_object()
}

pub fn get_value_as_object(
  self : JsonValue,
  key : String
) -> Option[@map.Map[String, JsonValue]] {
  self.get_as_object()?.lookup(key)?.get_as_object()
}

pub fn get_value(self : JsonValue, key : String) -> Option[JsonValue] {
  self.get_as_object()?.lookup(key)
}

test "get as object" {
  inspect(
    JsonValue::Null |> get_as_object |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::Boolean(false) |> get_as_object |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::Number(1.0) |> get_as_object |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::String("Hello World")
    |> get_as_object
    |> Option::map(@map.Map::to_vec),
    content="None",
  )?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> get_as_object
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
    |> get_as_object
    |> Option::map(@map.Map::to_vec),
    content="Some(Vec::[(key, String(\"key\")), (value, Number(100.0))])",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).get_value_as_string("key"),
    content="Some(key)",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).get_value_as_number("value"),
    content="Some(100.0)",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).get_value_as_number("key"),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).get_value_as_number("asdf"),
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
  inspect(json.get_value_as_null("null"), content="Some(())")?
  inspect(
    json.get_value("key").bind(fn { array => array.get_item_as_null(2) }),
    content="Some(())",
  )?
  inspect(json.get_value_as_bool("bool"), content="Some(false)")?
  inspect(
    json.get_value("key").bind(fn { array => array.get_item_as_bool(1) }),
    content="Some(true)",
  )?
  inspect(
    json.get_value_as_array("key"),
    content="Some(Vec::[Number(1.0), Boolean(true), Null, Array(Vec::[]), Object(Map::[(\"key\", String(\"value\")), (\"value\", Number(100.0))])])",
  )?
  inspect(
    json.get_value("key").bind(fn { array => array.get_item_as_array(3) }),
    content="Some(Vec::[])",
  )?
  inspect(
    json.get_value("key").bind(fn { array => array.get_item_as_object(4) }).map(
      @map.Map::to_vec,
    ),
    content="Some(Vec::[(key, String(\"value\")), (value, Number(100.0))])",
  )?
  inspect(
    json.get_value_as_object("obj").map(@map.Map::to_vec),
    content="Some(Vec::[])",
  )?
  inspect(
    json.get_value("key").bind(fn { array => array.get_item(4) }).bind(
      fn { obj => obj.get_value_as_number("value") },
    ),
    content="Some(100.0)",
  )?
}
