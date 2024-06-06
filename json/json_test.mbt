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
  inspect(JsonValue::Boolean(false) |> as_null, content="None")?
  inspect(JsonValue::Number(1.0) |> as_null, content="None")?
  inspect(JsonValue::String("Hello World") |> as_null, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_null,
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

test "get as bool" {
  inspect(JsonValue::Null |> as_bool, content="None")?
  inspect(JsonValue::Boolean(false) |> as_bool, content="Some(false)")?
  inspect(JsonValue::Number(1.0) |> as_bool, content="None")?
  inspect(JsonValue::String("Hello World") |> as_bool, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_bool,
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

test "get as number" {
  inspect(JsonValue::Null |> as_number, content="None")?
  inspect(JsonValue::Boolean(false) |> as_number, content="None")?
  inspect(JsonValue::Number(1.0) |> as_number, content="Some(1.0)")?
  inspect(JsonValue::String("Hello World") |> as_number, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_number,
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

test "get as string" {
  inspect(JsonValue::Null |> as_string, content="None")?
  inspect(JsonValue::Boolean(false) |> as_string, content="None")?
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
      @map.Map::[
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
  inspect(JsonValue::Boolean(false) |> as_array, content="None")?
  inspect(JsonValue::Number(1.0) |> as_array, content="None")?
  inspect(JsonValue::String("Hello World") |> as_array, content="None")?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")]) |> as_array,
    content="Some([String(\"Hello World\")])",
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
      @map.Map::[
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
    JsonValue::Null |> as_object |> Option::map(@map.Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::Boolean(false) |> as_object |> Option::map(@map.Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::Number(1.0) |> as_object |> Option::map(@map.Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::String("Hello World")
    |> as_object
    |> Option::map(@map.Map::to_array),
    content="None",
  )?
  inspect(
    JsonValue::Array([JsonValue::String("Hello World")])
    |> as_object
    |> Option::map(@map.Map::to_array),
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
    |> Option::map(@map.Map::to_array),
    content="Some([(key, String(\"key\")), (value, Number(100.0))])",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("key").bind(as_string),
    content="Some(key)",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("value").bind(as_number),
    content="Some(100.0)",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("key").bind(as_number),
    content="None",
  )?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    ).value("asdf").bind(as_number),
    content="None",
  )?
}

test "deep access" {
  let json = JsonValue::Object(
    @map.Map::[
      (
        "key",
        JsonValue::Array(
          [
            JsonValue::Number(1.0),
            JsonValue::Boolean(true),
            JsonValue::Null,
            JsonValue::Array([]),
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
    content="Some([Number(1.0), Boolean(true), Null, Array([]), Object(Map::[(\"key\", String(\"value\")), (\"value\", Number(100.0))])])",
  )?
  inspect(
    json.value("key").bind(fn { array => array.item(3) }).bind(as_array),
    content="Some([])",
  )?
  inspect(
    json.value("key").bind(fn { array => array.item(4) }).bind(as_object).map(
      @map.Map::to_array,
    ),
    content="Some([(key, String(\"value\")), (value, Number(100.0))])",
  )?
  inspect(
    json.value("obj").bind(as_object).map(@map.Map::to_array),
    content="Some([])",
  )?
  inspect(
    (fn() { json.value("key")?.item(4)?.value("value")?.as_number() })(),
    content="Some(100.0)",
  )?
}

test "stringify" {
  fn temp_remove_json_chunks(json : String, chunk : String) -> String {
    // TODO: obviously should be replaced by `String.replace(self,needle,replacement)`.
    fn temp_compare_from_offset(
      haystack : String,
      needle : String,
      offset : Int
    ) -> Bool {
      for i = 0; i < needle.length(); i = i + 1 {
        if haystack[offset + i] != needle[i] {
          return false
        }
      }
      return true
    }

    let max_offset = json.length() - chunk.length()
    for offset = 0; offset <= max_offset; offset = offset + 1 {
      if temp_compare_from_offset(json, chunk, offset) {
        return json.substring(end=offset) + json.substring(
            start=offset + chunk.length(),
          )
      }
    }
    return json
  }

  let json = JsonValue::Object(
    @map.Map::[
      (
        "key",
        JsonValue::Array(
          [
            JsonValue::Number(1.0),
            JsonValue::Boolean(true),
            JsonValue::Null,
            JsonValue::Array([]),
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
  // NOTE: 
  // JSON stringify doesn't have to be canonical, hence the comparasion have to be field order insensitive.
  // This may cause troubles for our test here if not handled properly. 
  inspect(
    json.stringify()
    |> temp_remove_json_chunks("{\"key\":\"value\",\"value\":100.0}")
    |> temp_remove_json_chunks("{\"value\":100.0,\"key\":\"value\"}")
    |> temp_remove_json_chunks("\"key\":[1.0,true,null,[],]")
    |> temp_remove_json_chunks("\"obj\":{}")
    |> temp_remove_json_chunks("\"bool\":false")
    |> temp_remove_json_chunks("\"null\":null"),
    content="{,,,}",
  )?
  inspect(parse(json.stringify()) == Ok(json), content="true")?
}
