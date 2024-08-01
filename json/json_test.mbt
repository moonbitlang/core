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
  inspect!(@json.T::Null |> @json.as_bool, content="None")
  inspect!(@json.T::True |> @json.as_bool, content="Some(true)")
  inspect!(@json.T::False |> @json.as_bool, content="Some(false)")
  inspect!(@json.T::Number(1.0) |> @json.as_bool, content="None")
  inspect!(
    @json.T::String("Hello World") |> @json.as_bool,
    content="None",
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")])
    |> @json.as_bool,
    content="None",
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    )
    |> @json.as_bool,
    content="None",
  )
}

test "get as number" {
  inspect!(@json.T::Null |> @json.as_number, content="None")
  inspect!(@json.T::False |> @json.as_number, content="None")
  inspect!(@json.T::True |> @json.as_number, content="None")
  inspect!(@json.T::Number(1.0) |> @json.as_number, content="Some(1.0)")
  inspect!(
    @json.T::String("Hello World") |> @json.as_number,
    content="None",
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")])
    |> @json.as_number,
    content="None",
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    )
    |> @json.as_number,
    content="None",
  )
}

test "get as string" {
  inspect!(@json.T::Null |> @json.as_string, content="None")
  inspect!(@json.T::True |> @json.as_string, content="None")
  inspect!(@json.T::False |> @json.as_string, content="None")
  inspect!(@json.T::Number(1.0) |> @json.as_string, content="None")
  inspect!(
    @json.T::String("Hello World") |> @json.as_string,
    content=
      #|Some("Hello World")
    ,
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")])
    |> @json.as_string,
    content="None",
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    )
    |> @json.as_string,
    content="None",
  )
}

test "get as array" {
  inspect!(@json.T::Null |> @json.as_array, content="None")
  inspect!(@json.T::True |> @json.as_array, content="None")
  inspect!(@json.T::False |> @json.as_array, content="None")
  inspect!(@json.T::Number(1.0) |> @json.as_array, content="None")
  inspect!(
    @json.T::String("Hello World") |> @json.as_array,
    content="None",
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")])
    |> @json.as_array,
    content=
      #|Some([String("Hello World")])
    ,
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")]).item(0).bind(
      @json.as_string,
    ),
    content=
      #|Some("Hello World")
    ,
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")]).item(1).bind(
      @json.as_string,
    ),
    content="None",
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")]).item(0).bind(
      @json.as_number,
    ),
    content="None",
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    )
    |> @json.as_array,
    content="None",
  )
}

test "get as object" {
  inspect!(
    @json.T::Null |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.T::True |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.T::False |> @json.as_object |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.T::Number(1.0)
    |> @json.as_object
    |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.T::String("Hello World")
    |> @json.as_object
    |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.T::Array([@json.T::String("Hello World")])
    |> @json.as_object
    |> @option.map(Map::to_array),
    content="None",
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
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
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    ).value("key").bind(@json.as_string),
    content=
      #|Some("key")
    ,
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    ).value("value").bind(@json.as_number),
    content="Some(100.0)",
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    ).value("key").bind(@json.as_number),
    content="None",
  )
  inspect!(
    @json.T::Object(
      Map::of(
        [
          ("key", @json.T::String("key")),
          ("value", @json.T::Number(100.0)),
        ],
      ),
    ).value("asdf").bind(@json.as_number),
    content="None",
  )
}

test "deep access" {
  let json = @json.T::Object(
    Map::of(
      [
        (
          "key",
          @json.T::Array(
            [
              @json.T::Number(1.0),
              @json.T::True,
              @json.T::Null,
              @json.T::Array([]),
              @json.T::Object(
                Map::of(
                  [
                    ("key", @json.T::String("value")),
                    ("value", @json.T::Number(100.0)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ("null", @json.T::Null),
        ("bool", @json.T::False),
        ("obj", @json.T::Object({  })),
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
      #|Some([Number(1.0), True, Null, Array([]), Object({"key": String("value"), "value": Number(100.0)})])
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
}

test "stringify" {
  let json : @json.T = {
    "key": [1.0, true, Null, [], { "key": "value", "value": 100.0 }],
    "null": Null,
    "bool": false,
    "obj": {  },
  }
  inspect!(
    json.stringify(),
    content=
      #|{"key":[1.0,true,null,[],{"key":"value","value":100.0}],"null":null,"bool":false,"obj":{}}
    ,
  )

  // not mut once we have `try except else` syntax
  // we do come across issues like ParseError not unified with String
  let newjson = @json.parse!(json.stringify())
  match json {
    { "key": [_, _, _, _, { "value": Number(i) }, ..] } =>
      inspect!(i, content="100.0")
    _ => fail!("Failed to match the JSON")
  }
  @test.eq!(newjson, json)
}
