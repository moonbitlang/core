pub fn get_as_null(self : JsonValue) -> Option[Unit] {
  match self {
    Null => Some(())
    _ => None
  }
}

test "get as null" {
  inspect(JsonValue::Null |> get_as_null, content="Some(())")?
  inspect(JsonValue::Boolean(false) |> get_as_null, content="None")?
  inspect(JsonValue::Number(1.0) |> get_as_null, content="None")?
  inspect(JsonValue::String("Hello World") |> get_as_null, content="None")?
  inspect(
    JsonValue::Array(@vec.Vec::[JsonValue::String("Hello World")])
    |> get_as_null,
  content="None")?
  inspect(
    JsonValue::Object(
      @map.Map::[
        ("key", JsonValue::String("key")),
        ("value", JsonValue::Number(100.0)),
      ],
    )
    |> get_as_null,
  content="None")?
}

pub fn get_as_bool(self : JsonValue) -> Option[Bool] {
  match self {
    Boolean(b) => Some(b)
    _ => None
  }
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

test "get as string" {
  inspect(JsonValue::Null |> get_as_string, content="None")?
  inspect(JsonValue::Boolean(false) |> get_as_string, content="None")?
  inspect(JsonValue::Number(1.0) |> get_as_string, content="None")?
  inspect(JsonValue::String("Hello World") |> get_as_string, content="Some(Hello World)")?
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
}
