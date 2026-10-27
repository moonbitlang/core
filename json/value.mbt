// Copyright 2026 International Digital Economy Academy
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
/// JSON value type used by core serialization APIs.
///
/// Example:
///
/// ```mbt check
/// test {
///   let value : Json = Json::array([Json::number(1.0), Json::null()])
///   inspect(value.stringify(), content="[1,null]")
/// }
/// ```
pub enum Json {
  Null
  True
  False
  Number(Double, repr~ : String?) // 1.0000000000000000000e100 
  String(String)
  Array(Array[Json])
  Object(Map[String, Json])
}

///|
pub impl Eq for Json with fn equal(a, b) {
  match (a, b) {
    (Null, Null) | (True, True) | (False, False) => true
    (Number(a_num, ..), Number(b_num, ..)) => a_num == b_num
    (String(a_str), String(b_str)) => a_str == b_str
    (Array(a_arr), Array(b_arr)) => a_arr == b_arr
    (Object(a_obj), Object(b_obj)) => a_obj == b_obj
    _ => false
  }
}

///|
/// Creates a JSON null value.
///
/// Returns a JSON value representing `null`.
pub fn Json::null() -> Json {
  return Null
}

///|
/// JSON `null` constant.
///
/// Equivalent to `Json::null()`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(null.stringify(), content="null")
/// }
/// ```
pub let null : Json = Null

///|
/// JSON `{}` constant.
pub fn Json::empty_object() -> Json {
  Object(Map([]))
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
/// ```mbt check
/// test {
///   @debug.debug_inspect(Json::number(3.14), content="Number(3.14)")
///   inspect(
///     Json::number(@double.infinity, repr="1e9999999999999999999999999999999").stringify(),
///     content="1e9999999999999999999999999999999",
///   )
/// }
/// ```
#owned(repr)
pub fn Json::number(number : Double, repr? : String) -> Json {
  return Number(number, repr~)
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
/// ```mbt check
/// test {
///   @debug.debug_inspect(Json::string("hello"), content="String(\"hello\")")
/// }
/// ```
#owned(string)
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
/// ```mbt check
/// test {
///   @debug.debug_inspect(Json::boolean(true), content="True")
///   @debug.debug_inspect(Json::boolean(false), content="False")
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
/// ```mbt check
/// test {
///   let values : Array[Json] = [1.0, "hello"]
///   @debug.debug_inspect(
///     Json::array(values),
///     content="Array([Number(1), String(\"hello\")])",
///   )
/// }
/// ```
#owned(array)
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
/// ```mbt check
/// test {
///   let map : Map[String, Json] = { "name": "John", "age": 42.0 }
///   @debug.debug_inspect(
///     Json::object(map),
///     content="Object({ \"name\": String(\"John\"), \"age\": Number(42) })",
///   )
/// }
/// ```
#owned(object)
pub fn Json::object(object : Map[String, Json]) -> Json {
  return Object(object)
}

///|
/// Converts any value implementing `ToJson` into a `Json`.
///
/// This is the constructor of `Json`, so it is written `Json(value)`, and it is
/// re-exported by the prelude — no import is needed. Prefer it over calling
/// `ToJson::to_json` directly.
///
/// Parameters:
///
/// * `value` : The value to convert.
///
/// Returns the `Json` representation of `value`.
///
/// Example:
///
/// ```mbt check
/// test {
///   @debug.debug_inspect(Json(42), content="Number(42)")
///   @debug.debug_inspect(Json("hello"), content="String(\"hello\")")
///   @debug.debug_inspect(Json([1, 2]), content="Array([Number(1), Number(2)])")
/// }
/// ```
pub fn[T : ToJson] Json::Json(value : T) -> Json {
  ToJson::to_json(value)
}

///|
pub impl Default for Json with fn default() {
  false
}
