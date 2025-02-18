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
  let res = Array::make(self.length(), ToJson::to_json(self[0]))
  for i in 1..<len {
    res[i] = ToJson::to_json(self[i])
  }
  Array(res)
}

///|
pub impl[X : ToJson] ToJson for ArrayView[X] with to_json(self) {
  let len = self.length()
  if len == 0 {
    return []
  }
  let res = Array::make(self.length(), ToJson::to_json(self[0]))
  for i in 1..<len {
    res[i] = ToJson::to_json(self[i])
  }
  Array(res)
}

///|
pub impl[K : Show, V : ToJson] ToJson for Map[K, V] with to_json(self) {
  let object = {}
  for k, v in self {
    object[k.to_string()] = v.to_json()
  }
  Object(object)
}

///|
pub impl[X : ToJson] ToJson for Set[X] with to_json(self) {
  let array = []
  for v in self {
    array.push(v.to_json())
  }
  Array(array)
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
pub fn Json::default() -> Json {
  false
}
