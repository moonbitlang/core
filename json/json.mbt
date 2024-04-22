pub fn get_as_null(json : JsonValue) -> Option[Unit] {
  match json {
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

pub fn get_as_bool(json : JsonValue) -> Option[Bool] {
  match json {
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

pub fn get_as_number(json : JsonValue) -> Option[Double] {
  match json {
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

pub fn get_as_string(json : JsonValue) -> Option[String] {
  match json {
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

pub fn get_as_array(json : JsonValue) -> Option[@vec.Vec[JsonValue]] {
  match json {
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

pub fn get_as_object(json : JsonValue) -> Option[@map.Map[String, JsonValue]] {
  match json {
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
