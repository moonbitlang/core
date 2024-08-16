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

pub enum Json {
  Null
  True
  False
  Number(Double)
  String(String)
  Array(Array[Json])
  Object(Map[String, Json])
} derive(Eq)

/// Trait for types that can be converted to `Json`
pub trait ToJson {
  to_json(Self) -> Json
}

pub fn Bool::to_json(self : Bool) -> Json {
  if self {
    True
  } else {
    False
  }
}

pub fn Int::to_json(self : Int) -> Json {
  Number(self.to_double())
}

pub fn Int64::to_json(self : Int64) -> Json {
  Number(self.to_double())
}

pub fn Double::to_json(self : Double) -> Json {
  Number(self)
}

pub fn String::to_json(self : String) -> Json {
  String(self.escape())
}

pub fn Char::to_json(self : Char) -> Json {
  String(self.to_string())
}

pub fn Array::to_json[X : ToJson](self : Array[X]) -> Json {
  Array(self.map(ToJson::to_json))
}

pub fn Map::to_json[V : ToJson](self : Map[String, V]) -> Json {
  let object = {  }
  self.each(fn(k, v) { object[k] = v.to_json() })
  Object(object)
}
