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

test "get as bool" {
  inspect!(@json.JsonValue::Null |> @json.as_bool, content="None")
  inspect!(@json.JsonValue::True |> @json.as_bool, content="Some(true)")
  inspect!(@json.JsonValue::False |> @json.as_bool, content="Some(false)")
  inspect!(@json.JsonValue::Number(1.0) |> @json.as_bool, content="None")
  inspect!(
    @json.JsonValue::String("Hello World") |> @json.as_bool,
    content="None",
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")])
    |> @json.as_bool,
    content="None",
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    )
    |> @json.as_bool,
    content="None",
  )
}

test "get as number" {
  inspect!(@json.JsonValue::Null |> @json.as_number, content="None")
  inspect!(@json.JsonValue::False |> @json.as_number, content="None")
  inspect!(@json.JsonValue::True |> @json.as_number, content="None")
  inspect!(@json.JsonValue::Number(1.0) |> @json.as_number, content="Some(1.0)")
  inspect!(
    @json.JsonValue::String("Hello World") |> @json.as_number,
    content="None",
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")])
    |> @json.as_number,
    content="None",
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    )
    |> @json.as_number,
    content="None",
  )
}

test "get as string" {
  inspect!(@json.JsonValue::Null |> @json.as_string, content="None")
  inspect!(@json.JsonValue::True |> @json.as_string, content="None")
  inspect!(@json.JsonValue::False |> @json.as_string, content="None")
  inspect!(@json.JsonValue::Number(1.0) |> @json.as_string, content="None")
  inspect!(
    @json.JsonValue::String("Hello World") |> @json.as_string,
    content=
      #|Some("Hello World")
    ,
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")])
    |> @json.as_string,
    content="None",
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    )
    |> @json.as_string,
    content="None",
  )
}

test "get as array" {
  inspect!(@json.JsonValue::Null |> @json.as_array, content="None")
  inspect!(@json.JsonValue::True |> @json.as_array, content="None")
  inspect!(@json.JsonValue::False |> @json.as_array, content="None")
  inspect!(@json.JsonValue::Number(1.0) |> @json.as_array, content="None")
  inspect!(
    @json.JsonValue::String("Hello World") |> @json.as_array,
    content="None",
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")])
    |> @json.as_array,
    content=
      #|Some([String("Hello World")])
    ,
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")]).item(0).bind(
      @json.as_string,
    ),
    content=
      #|Some("Hello World")
    ,
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")]).item(1).bind(
      @json.as_string,
    ),
    content="None",
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")]).item(0).bind(
      @json.as_number,
    ),
    content="None",
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    )
    |> @json.as_array,
    content="None",
  )
}

test "get as object" {
  inspect!(
    @json.JsonValue::Null |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.JsonValue::True |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.JsonValue::False |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.JsonValue::Number(1.0)
    |> @json.as_object
    |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.JsonValue::String("Hello World")
    |> @json.as_object
    |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.JsonValue::Array([@json.JsonValue::String("Hello World")])
    |> @json.as_object
    |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    )
    |> @json.as_object
    |> @option.map(Map::to_array),
    content=
      #|Some([("key", String("key")), ("value", Number(100.0))])
    ,
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    ).value("key").bind(@json.as_string),
    content=
      #|Some("key")
    ,
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    ).value("value").bind(@json.as_number),
    content="Some(100.0)",
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    ).value("key").bind(@json.as_number),
    content="None",
  )
  inspect!(
    @json.JsonValue::Object(
      Map::of(
        [
          ("key", @json.JsonValue::String("key")),
          ("value", @json.JsonValue::Number(100.0)),
        ],
      ),
    ).value("asdf").bind(@json.as_number),
    content="None",
  )
}

test "deep access" {
  let json = @json.JsonValue::Object(
    Map::of(
      [
        (
          "key",
          @json.JsonValue::Array(
            [
              @json.JsonValue::Number(1.0),
              @json.JsonValue::True,
              @json.JsonValue::Null,
              @json.JsonValue::Array([]),
              @json.JsonValue::Object(
                Map::of(
                  [
                    ("key", @json.JsonValue::String("value")),
                    ("value", @json.JsonValue::Number(100.0)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ("null", @json.JsonValue::Null),
        ("bool", @json.JsonValue::False),
        ("obj", @json.JsonValue::Object({  })),
      ],
    ),
  )
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
      #|Some([Number(1.0), True, Null, Array([]), Object("key": String("value"), "value": Number(100.0)})])
    ,
  )
  inspect!(
    json.value("key").bind(fn { array => array.item(3) }).bind(@json.as_array),
    content="Some([])",
  )
  inspect!(
    json.value("key").bind(fn { array => array.item(4) }).bind(@json.as_object).map(
      Map::to_array,
    ),
    content=
      #|Some([("key", String("value")), ("value", Number(100.0))])
    ,
  )
  inspect!(
    json.value("obj").bind(@json.as_object).map(Map::to_array),
    content="Some([])",
  )
  inspect!(
    (fn() { json.value("key")?.item(4)?.value("value")?.as_number() })(),
    content="Some(100.0)",
  )
}

test "stringify" {
  let json = @json.JsonValue::Object(
    Map::of(
      [
        (
          "key",
          @json.JsonValue::Array(
            [
              @json.JsonValue::Number(1.0),
              @json.JsonValue::True,
              @json.JsonValue::Null,
              @json.JsonValue::Array([]),
              @json.JsonValue::Object(
                Map::of(
                  [
                    ("key", @json.JsonValue::String("value")),
                    ("value", @json.JsonValue::Number(100.0)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ("null", @json.JsonValue::Null),
        ("bool", @json.JsonValue::False),
        ("obj", @json.JsonValue::Object({  })),
      ],
    ),
  )
  inspect!(
    json.stringify(),
    content=
      #|{"key":[1.0,true,null,[],{"key":"value","value":100.0}],"null":null,"bool":false,"obj":{}}
    ,
  )

  // not mut once we have `try except else` syntax
  // we do come across issues like ParseError not unified with String
  let newjson = try {
    @json.parse!(json.stringify())
  } catch {
    _ => @test.fail!("Failed to parse the stringified JSON")
  }
  @test.eq!(newjson, json)
}
