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
/// Trait for types that can be converted to `Json`
pub(open) trait ToJson {
  fn to_json(Self) -> Json
}

///|
/// Convert `value` to `Json`.
///
/// This is the free-function form of the `ToJson` trait method, symmetric with
/// `@json.from_json`. Prefer it over the promoted `value.to_json()` method.
///
/// ```mbt check
/// test {
///   @debug.debug_inspect(
///     @json.to_json([1, 2, 3]),
///     content="Array([Number(1), Number(2), Number(3)])",
///   )
/// }
/// ```
pub fn[T : ToJson] to_json(value : T) -> Json {
  ToJson::to_json(value)
}

///|
/// Useful for json interpolation
pub impl ToJson for Json with fn to_json(self) {
  self
}

///|
pub impl ToJson for Unit with fn to_json(_self) {
  Null
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
pub impl ToJson for Char with fn to_json(self : Char) -> Json {
  Json::string(self.to_string())
}

///|
pub impl ToJson for Int16 with fn to_json(self : Int16) -> Json {
  Json::number(self.to_int().to_double())
}

///|
pub impl ToJson for Int32 with fn to_json(self : Int32) -> Json {
  Json::number(self.to_double())
}

///|
pub impl ToJson for Int64 with fn to_json(self : Int64) -> Json {
  ToJson::to_json(self.to_string())
}

///|
pub impl ToJson for UInt16 with fn to_json(self : UInt16) -> Json {
  Json::number(self.to_int().to_double())
}

///|
pub impl ToJson for UInt32 with fn to_json(self : UInt32) -> Json {
  Json::number(self.to_uint64().to_double())
}

///|
pub impl ToJson for UInt64 with fn to_json(self : UInt64) -> Json {
  ToJson::to_json(self.to_string())
}

///|
pub impl ToJson for Float with fn to_json(self : Float) -> Json {
  ToJson::to_json(self.to_double())
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
pub impl ToJson for StringView with fn to_json(self) {
  ToJson::to_json(self.to_owned())
}

///|
/// Converts a `Bytes` value to a JSON representation.
/// The representation is picked for easier debugging.
/// Printable ASCII characters (from space to tilde, excluding '"' and '\') are output as-is.
/// All other bytes are represented as \xHH, where HH is the two-digit hexadecimal value of the byte.
pub impl ToJson for Bytes with fn to_json(self : Bytes) -> Json {
  ToJson::to_json(self[:])
}

///|
pub impl ToJson for BytesView with fn to_json(self) -> Json {
  let sb = StringBuilder()
  for byte in self {
    if byte is (b' '..<=b'~') && byte != b'"' && byte != b'\\' {
      sb.write_char(byte.to_char())
    } else {
      sb.write_string("\\x")
      sb.write_string(byte.to_hex())
    }
  }
  Json::string(sb.to_string())
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
  let res = Array::unsafe_make_uninit(len)
  for i, x in self {
    res.unsafe_set(i, ToJson::to_json(x))
  }
  Array(res)
}

///|
/// ToJson implementation for ReadOnlyArray.
pub impl[T : ToJson] ToJson for ReadOnlyArray[T] with fn to_json(self) {
  ToJson::to_json(self[:])
}

///|
pub impl[X : ToJson] ToJson for ArrayView[X] with fn to_json(self) {
  let len = self.length()
  if len == 0 {
    return []
  }
  let res = Array::unsafe_make_uninit(len)
  for i, x in self {
    res.unsafe_set(i, ToJson::to_json(x))
  }
  Array(res)
}

///|
pub impl[X : ToJson] ToJson for Iter[X] with fn to_json(self) {
  [
    for x in self => x
  ]
}

///|
pub impl[K : Show, V : ToJson] ToJson for Map[K, V] with fn to_json(self) {
  let object = Map([], capacity=self.length())
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

///|
/// Returns the JSON representation of this error.
pub impl ToJson for Error with fn to_json(self) = "%error.to_json"

///|
pub impl ToJson for Failure with fn to_json(self) {
  let Failure(message) = self
  ["Failure", message]
}
