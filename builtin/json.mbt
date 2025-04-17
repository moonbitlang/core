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
#visibility(change_to="readonly", "Use smart constructor to make json")
pub(all) enum Json {
  Null
  True
  False
  Number(Double)
  String(String)
  Array(Array[Json])
  Object(Map[String, Json])
} derive(Eq)

///|
/// Creates a JSON null value.
///
/// Returns a JSON value representing `null`.
///
/// Example:
///
/// ```moonbit
/// test "null" {
///   inspect!(Json::null(), content="Null")
/// }
/// ```
pub fn Json::null() -> Json {
  return Null
}

///|
/// Creates a JSON number value from a double-precision floating-point number.
///
/// Parameters:
///
/// * `value` : A double-precision floating-point number to be converted to a
/// JSON number.
///
/// Returns a JSON value representing the given number.
///
/// Example:
///
/// ```moonbit
/// test "number" {
///   inspect!(Json::number(3.14), content="Number(3.14)")
/// }
/// ```
pub fn Json::number(number : Double) -> Json {
  return Number(number)
}

///|
/// Creates a JSON string value from a MoonBit string.
///
/// Parameters:
///
/// * `string` : A MoonBit string to be converted to a JSON string value.
///
/// Returns a JSON value representing the given string.
///
/// Example:
///
/// ```moonbit
/// test "string" {
///   inspect!(Json::string("hello"), content="String(\"hello\")")
/// }
/// ```
pub fn Json::string(string : String) -> Json {
  return String(string)
}

///|
/// Creates a JSON boolean value from a MoonBit boolean.
///
/// Parameters:
///
/// * `boolean` : A MoonBit boolean to be converted to a JSON boolean value.
///
/// Returns a JSON value representing the given boolean.
///
/// Example:
///
/// ```moonbit
/// test "boolean" {
///   inspect!(Json::boolean(true), content="True")
///   inspect!(Json::boolean(false), content="False")
/// }
/// ```
pub fn Json::boolean(boolean : Bool) -> Json {
  if boolean {
    True
  } else {
    False
  }
}

///|
/// Creates a JSON array value from a MoonBit array.
///
/// Parameters:
///
/// * `values` : An array of JSON values to be converted to a JSON array value.
///
/// Returns a JSON value representing the given array.
///
/// Example:
///
/// ```moonbit
/// test "array" {
///   let values : Array[Json] = [1.0, "hello"]
///   inspect!(
///     Json::array(values),
///     content="Array([Number(1), String(\"hello\")])",
///   )
/// }
/// ```
pub fn Json::array(array : Array[Json]) -> Json {
  return Array(array)
}

///|
/// Creates a JSON object value from a MoonBit map.
///
/// Parameters:
///
/// * `map` : A map from strings to JSON values to be converted to a JSON object
/// value.
///
/// Returns a JSON value representing the given map.
///
/// Example:
///
/// ```moonbit
/// test "object" {
///   let map : Map[String, Json] = { "name": "John", "age": 42.0 }
///   inspect!(
///     Json::object(map),
///     content="Object({\"name\": String(\"John\"), \"age\": Number(42)})",
///   )
/// }
/// ```
pub fn Json::object(object : Map[String, Json]) -> Json {
  return Object(object)
}

///|
/// Trait for types that can be converted to `Json`
pub(open) trait ToJson {
  to_json(Self) -> Json
}

///|
pub impl ToJson for Bool with to_json(self : Bool) -> Json {
  if self {
    true
  } else {
    false
  }
}

///|
pub impl ToJson for Int with to_json(self : Int) -> Json {
  Number(self.to_double())
}

///|
pub impl ToJson for Int64 with to_json(self : Int64) -> Json {
  String::to_json(self.to_string())
}

///|
pub impl ToJson for UInt with to_json(self : UInt) -> Json {
  Number(self.to_uint64().to_double())
}

///|
pub impl ToJson for UInt64 with to_json(self : UInt64) -> Json {
  String::to_json(self.to_string())
}

///|
pub impl ToJson for Double with to_json(self : Double) -> Json {
  if self != self ||
    self > 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double() ||
    self < 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double() {
    return Null
  }
  Number(self)
}

///|
pub impl ToJson for Float with to_json(self : Float) -> Json {
  Number(self.to_double())
}

///|
pub impl ToJson for String with to_json(self : String) -> Json {
  String(self)
}

///|
pub impl ToJson for Char with to_json(self : Char) -> Json {
  String(self.to_string())
}

///|
pub impl ToJson for BigInt with to_json(self : BigInt) -> Json {
  String(self.to_string())
}

///|
pub impl[X : ToJson] ToJson for Array[X] with to_json(self) {
  Array(self.map(ToJson::to_json))
}

///|
pub impl[X : ToJson] ToJson for FixedArray[X] with to_json(self) {
  let len = self.length()
  if len == 0 {
    return []
  }
  let res = Array::make_uninit(self.length())
  for i, x in self {
    res.unsafe_set(i, ToJson::to_json(x))
  }
  Array(res)
}

///|
pub impl[X : ToJson] ToJson for ArrayView[X] with to_json(self) {
  let len = self.length()
  if len == 0 {
    return []
  }
  let res = Array::make_uninit(self.length())
  for i, x in self {
    res.unsafe_set(i, ToJson::to_json(x))
  }
  Array(res)
}

///|
pub impl[K : Show, V : ToJson] ToJson for Map[K, V] with to_json(self) {
  let object = Map::new(capacity=self.capacity)
  for k, v in self {
    object[k.to_string()] = v.to_json()
  }
  Object(object)
}

///|
pub impl[T : ToJson] ToJson for T? with to_json(self) {
  match self {
    None => Null
    Some(value) => [value.to_json()]
  }
}

///|
pub impl[Ok : ToJson, Err : ToJson] ToJson for Result[Ok, Err] with to_json(
  self : Result[Ok, Err]
) -> Json {
  match self {
    Ok(ok) => { "Ok": ok.to_json() }
    Err(err) => { "Err": err.to_json() }
  }
}

///|
//| unit
pub impl ToJson for Unit with to_json(_self) {
  Null
}

///|
pub impl Default for Json with default() {
  false
}
