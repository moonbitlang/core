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

pub type! JsonParseError (JsonPath, String) derive(Eq, Show)

/// Trait for types that can be converted from `Json`
pub trait FromJson {
  from_json(Json, JsonPath) -> Self!JsonParseError
}

pub fn from_json[T : FromJson](
  json : Json,
  ~path : JsonPath = Root
) -> T!JsonParseError {
  FromJson::from_json!(json, path)
}

pub impl FromJson for Bool with from_json(json, path) {
  match json {
    True => true
    False => false
    _ => raise JsonParseError((path, "Bool::from_json: expected boolean "))
  }
}

pub impl FromJson for Int with from_json(json, path) {
  match json {
    Number(n) => n.to_int()
    _ => raise JsonParseError((path, "Int::from_json: expected number"))
  }
}

pub impl FromJson for Int64 with from_json(json, path) {
  match json {
    Number(n) => n.to_int64()
    _ => raise JsonParseError((path, "Int64::from_json: expected number"))
  }
}

pub impl FromJson for Double with from_json(json, path) {
  match json {
    Number(n) => n
    _ => raise JsonParseError((path, "Double::from_json: expected number"))
  }
}

pub impl FromJson for String with from_json(json, path) {
  match json {
    String(a) => a
    _ => raise JsonParseError((path, "String::from_json: expected string"))
  }
}

pub impl FromJson for Char with from_json(json, path) {
  match json {
    String(a) =>
      if a.length() != 1 {
        raise JsonParseError(
          (path, "Char::from_json: expected single character"),
        )
      } else {
        a[0]
      }
    _ => raise JsonParseError((path, "Char::from_json: expected string"))
  }
}

pub impl[X : FromJson] FromJson for Array[X] with from_json(json, path) {
  match json {
    Array(a) => {
      let res : Array[X] = Array::new(capacity=a.length())
      for i = 0; i < a.length(); i = i + 1 {
        res.push(FromJson::from_json!(a[i], Index(path, i)))
      }
      res
    }
    _ => raise JsonParseError((path, "Array::from_json: expected array"))
  }
}

pub impl[V : FromJson] FromJson for Map[String, V] with from_json(json, path) {
  match json {
    Object(obj) => {
      let res = {  }
      for k, v in obj {
        res[k] = FromJson::from_json!(v, Key(path, k))
      }
      res
    }
    _ => raise JsonParseError((path, "Map::from_json: expected object"))
  }
}
