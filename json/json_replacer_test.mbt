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
test "JsonReplacer::Nop - no changes" {
  let json = Json::object({ "x": Json::number(1), "y": Json::number(2) })
  let result = json.apply_replacer(JsonReplacer::Nop)
  inspect(result, content="Object({\"x\": Number(1), \"y\": Number(2)})")
}

///|
test "JsonReplacer::KeepFields - single field" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
    "z": Json::number(3),
  })
  let result = json.apply_replacer(
    JsonReplacer::KeepFields(["x"][:]),
  )
  inspect(result, content="Object({\"x\": Number(1)})")
}

///|
test "JsonReplacer::KeepFields - multiple fields" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
    "z": Json::number(3),
  })
  let result = json.apply_replacer(
    JsonReplacer::KeepFields(["x", "z"][:]),
  )
  inspect(result, content="Object({\"x\": Number(1), \"z\": Number(3)})")
}

///|
test "JsonReplacer::KeepFields - non-existent field" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
  })
  let result = json.apply_replacer(
    JsonReplacer::KeepFields(["x", "w"][:]),
  )
  inspect(result, content="Object({\"x\": Number(1)})")
}

///|
test "JsonReplacer::ExcludeFields - single field" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
    "z": Json::number(3),
  })
  let result = json.apply_replacer(
    JsonReplacer::ExcludeFields(["y"][:]),
  )
  inspect(result, content="Object({\"x\": Number(1), \"z\": Number(3)})")
}

///|
test "JsonReplacer::ExcludeFields - multiple fields" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
    "z": Json::number(3),
  })
  let result = json.apply_replacer(
    JsonReplacer::ExcludeFields(["y", "z"][:]),
  )
  inspect(result, content="Object({\"x\": Number(1)})")
}

///|
test "JsonReplacer::ExcludeFields - all fields excluded" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
  })
  let result = json.apply_replacer(
    JsonReplacer::ExcludeFields(["x", "y"][:]),
  )
  inspect(result, content="Object({})")
}

///|
test "JsonReplacer::Function - custom transformation" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
  })
  let replacer = JsonReplacer::Function(fn(key, value, _depth) {
    // Double all numbers with key "x"
    if key == "x" {
      match value {
        Json::Number(n, repr~) =>
          match repr {
            Some(r) => Some(Json::number(n * 2.0, repr=r))
            None => Some(Json::number(n * 2.0))
          }
        _ => Some(value)
      }
    } else {
      Some(value)
    }
  })
  let result = json.apply_replacer(replacer)
  inspect(result, content="Object({\"x\": Number(2), \"y\": Number(2)})")
}

///|
test "JsonReplacer::Function - filter values" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
    "z": Json::number(3),
  })
  let replacer = JsonReplacer::Function(fn(key, value, _depth) {
    // Exclude values less than 2
    match value {
      Json::Number(n, ..) if n < 2.0 => None
      _ => Some(value)
    }
  })
  let result = json.apply_replacer(replacer)
  inspect(result, content="Object({\"y\": Number(2), \"z\": Number(3)})")
}

///|
test "JsonReplacer with nested objects - KeepFields" {
  let json = Json::object({
    "user": Json::object({
      "name": Json::string("John"),
      "age": Json::number(30),
      "email": Json::string("john@example.com"),
    }),
    "status": Json::string("active"),
  })
  let result = json.apply_replacer(
    JsonReplacer::KeepFields(["name", "age"][:]),
  )
  // KeepFields applies to the entire structure recursively
  // So it keeps these fields at any level
  inspect(
    result,
    content="Object({})",
  )
}

///|
test "JsonReplacer with nested objects - ExcludeFields" {
  let json = Json::object({
    "user": Json::object({
      "name": Json::string("John"),
      "age": Json::number(30),
      "email": Json::string("john@example.com"),
    }),
    "status": Json::string("active"),
  })
  let result = json.apply_replacer(
    JsonReplacer::ExcludeFields(["email"][:]),
  )
  inspect(
    result,
    content="Object({\"user\": Object({\"name\": String(\"John\"), \"age\": Number(30)}), \"status\": String(\"active\")})",
  )
}

///|
test "JsonReplacer with arrays" {
  let json = Json::array([
    Json::object({ "x": Json::number(1), "y": Json::number(2) }),
    Json::object({ "x": Json::number(3), "y": Json::number(4) }),
  ])
  let result = json.apply_replacer(
    JsonReplacer::KeepFields(["x"][:]),
  )
  inspect(
    result,
    content="Array([Object({\"x\": Number(1)}), Object({\"x\": Number(3)})])",
  )
}

///|
test "JsonReplacer::Function with depth" {
  let json = Json::object({
    "level1": Json::object({
      "level2": Json::object({ "value": Json::number(42) }),
    }),
  })
  let replacer = JsonReplacer::Function(fn(key, value, depth) {
    // Only process at depth 0 (keep the root)
    if depth == 0 {
      Some(value)
    } else {
      None
    }
  })
  let result = json.apply_replacer(replacer)
  // At depth 0, we keep "level1", but at depth 1 we remove "level2"
  inspect(result, content="Object({\"level1\": Object({})})")
}

///|
test "JsonReplacer::Function - keep only strings" {
  let json = Json::object({
    "name": Json::string("Alice"),
    "age": Json::number(25),
    "city": Json::string("NYC"),
    "active": Json::boolean(true),
  })
  let replacer = JsonReplacer::Function(fn(key, value, _depth) {
    match value {
      Json::String(_) => Some(value)
      _ => None
    }
  })
  let result = json.apply_replacer(replacer)
  inspect(result, content="Object({\"name\": String(\"Alice\"), \"city\": String(\"NYC\")})")
}

///|
test "JsonReplacer with null values" {
  let json = Json::object({
    "x": Json::null(),
    "y": Json::number(2),
    "z": Json::string("test"),
  })
  let replacer = JsonReplacer::Function(fn(key, value, _depth) {
    match value {
      Json::Null => None
      _ => Some(value)
    }
  })
  let result = json.apply_replacer(replacer)
  inspect(result, content="Object({\"y\": Number(2), \"z\": String(\"test\")})")
}

///|
test "JsonReplacer::Nop with arrays - no changes" {
  let json = Json::array([
    Json::number(1),
    Json::number(2),
    Json::number(3),
  ])
  let result = json.apply_replacer(JsonReplacer::Nop)
  inspect(result, content="Array([Number(1), Number(2), Number(3)])")
}

///|
test "JsonReplacer::KeepFields empty object" {
  let json = Json::object({})
  let result = json.apply_replacer(
    JsonReplacer::KeepFields(["x"][:]),
  )
  inspect(result, content="Object({})")
}

///|
test "JsonReplacer::ExcludeFields - non-existent field" {
  let json = Json::object({
    "x": Json::number(1),
    "y": Json::number(2),
  })
  let result = json.apply_replacer(
    JsonReplacer::ExcludeFields(["z"][:]),
  )
  inspect(result, content="Object({\"x\": Number(1), \"y\": Number(2)})")
}
