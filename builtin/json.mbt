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
/// `Number` carries the numeric value as a `Double` together with an optional
/// `repr`, the exact source text of the literal. `stringify` writes `repr` out
/// verbatim in place of the double, so it must be valid JSON number syntax and
/// must denote the accompanying `Double`: text that is not a JSON number makes
/// the output invalid JSON, or turns the value into a different JSON type
/// altogether (`repr="null"` emits `null`), and text denoting some other value
/// silently changes what the document says.
///
/// The parser attaches a `repr` to every integer literal whose digits run past
/// the exact-integer range of a `Double` — whether or not the value happens to
/// land on one, so `9007199254740992` keeps its text too — and to every literal
/// that overflows to an infinity. It leaves `repr` as `None` everywhere else,
/// including decimals that round (`0.1`) and those that underflow to zero
/// (`1e-400`).
///
/// Equality compares numeric values and ignores `repr`, so two equal `Json`
/// values may stringify differently:
///
/// ```mbt check
/// test {
///   let one : Json = Json::number(1)
///   let padded : Json = Json::number(1, repr="1.000")
///   inspect(one == padded, content="true")
///   inspect(one.stringify(), content="1")
///   inspect(padded.stringify(), content="1.000")
/// }
/// ```
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
/// * `repr` : The exact source text of the literal, if it is worth preserving.
/// `stringify` writes it verbatim in place of `value`, so it must be valid JSON
/// number syntax and must denote `value` itself: text that is not a JSON number
/// makes the output invalid JSON or gives it a different JSON type, and text
/// denoting some other value makes the document disagree with the `Double`
/// every consumer reads. Supply it only for literals a `Double` cannot render
/// back as written, such as integers beyond the exact-integer range or
/// magnitudes beyond the range of a `Double` altogether.
///
/// Returns a JSON value representing the given number.
///
/// `NaN` and the infinities have no JSON syntax. Passing one without a `repr`
/// is accepted and stringifies to the strings `"NaN"`, `"Infinity"` and
/// `"-Infinity"`, matching how `Double::to_json` encodes them and what
/// `Double::from_json` accepts back.
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
///   inspect(Json::number(@double.infinity).stringify(), content="\"Infinity\"")
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
/// Trait for types that can be converted to `Json`
pub(open) trait ToJson {
  fn to_json(Self) -> Json
}

///|
pub impl ToJson for Bool with fn to_json(self : Bool) -> Json {
  if self {
    true
  } else {
    false
  }
}

///|
pub impl ToJson for Byte with fn to_json(self : Byte) -> Json {
  Json::number(self.to_double())
}

///|
pub impl ToJson for Int with fn to_json(self : Int) -> Json {
  Json::number(self.to_double())
}

///|
pub impl ToJson for Int64 with fn to_json(self : Int64) -> Json {
  String::to_json(self.to_string())
}

///|
pub impl ToJson for UInt with fn to_json(self : UInt) -> Json {
  Json::number(self.to_uint64().to_double())
}

///|
pub impl ToJson for UInt64 with fn to_json(self : UInt64) -> Json {
  String::to_json(self.to_string())
}

///|
pub impl ToJson for Double with fn to_json(self : Double) -> Json {
  if self != self {
    Json::string("NaN")
  } else if self > 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double() {
    Json::string("Infinity")
  } else if self < 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double() {
    Json::string("-Infinity")
  } else {
    Json::number(self)
  }
}

///|
pub impl ToJson for String with fn to_json(self : String) -> Json {
  String(self)
}

///|
pub impl[X : ToJson] ToJson for Array[X] with fn to_json(self) {
  Array(self.map(x => x.to_json()))
}

///|
pub impl[X : ToJson] ToJson for FixedArray[X] with fn to_json(self) {
  let len = self.length()
  if len == 0 {
    return []
  }
  let res = Array::unsafe_make_uninit(self.length())
  for i, x in self {
    res.unsafe_set(i, ToJson::to_json(x))
  }
  Array(res)
}

///|
pub impl[X : ToJson] ToJson for ArrayView[X] with fn to_json(self) {
  let len = self.length()
  if len == 0 {
    return []
  }
  let res = Array::unsafe_make_uninit(self.length())
  for i, x in self {
    res.unsafe_set(i, ToJson::to_json(x))
  }
  Array(res)
}

///|
pub impl[K : Show, V : ToJson] ToJson for Map[K, V] with fn to_json(self) {
  let object = Map([], capacity=self.capacity)
  for k, v in self {
    object[k.to_string()] = v.to_json()
  }
  Object(object)
}

///|
pub impl[T : ToJson] ToJson for T? with fn to_json(self) {
  match self {
    None => Null
    Some(value) => [value]
  }
}

///|
pub impl[Ok : ToJson, Err : ToJson] ToJson for Result[Ok, Err] with fn to_json(
  self : Result[Ok, Err],
) -> Json {
  match self {
    Ok(ok) => { "Ok": ok }
    Err(err) => { "Err": err }
  }
}

//| unit

///|
pub impl ToJson for Unit with fn to_json(_self) {
  Null
}

///|
pub impl Default for Json with fn default() {
  false
}
