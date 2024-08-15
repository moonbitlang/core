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

pub type! JsonTypeError String derive(Eq, Show)

/// Trait for types that can be converted from `Json`
pub trait FromJson {
  from_json(Json) -> Self!JsonTypeError
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

fn escape_json_string(str : String) -> String {
  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  let buf = Buffer::new(size_hint=str.length())
  for i = 0; i < str.length(); i = i + 1 {
    let c = str[i]
    match c {
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\b' => buf.write_string("\\b")
      '\t' => buf.write_string("\\t")
      _ => {
        let code = c.to_int()
        if code == 0x0C {
          buf.write_string("\\f")
        } else if code < 0x20 {
          buf.write_string("\\u00")
          buf.write_char(to_hex_digit(code / 16))
          buf.write_char(to_hex_digit(code % 16))
        } else {
          buf.write_char(c)
        }
      }
    }
  }
  buf.to_string()
}

pub fn String::to_json(self : String) -> Json {
  String(escape_json_string(self))
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

pub impl FromJson for Bool with from_json(json) {
  match json {
    True => true
    False => false
    _ => raise JsonTypeError("Bool::from_json: expected boolean")
  }
}

pub impl FromJson for Int with from_json(json) {
  match json {
    Number(n) => n.to_int()
    _ => raise JsonTypeError("Int::from_json: expected number")
  }
}

pub impl FromJson for Int64 with from_json(json) {
  match json {
    Number(n) => n.to_int64()
    _ => raise JsonTypeError("Int64::from_json: expected number")
  }
}

pub impl FromJson for Double with from_json(json) {
  match json {
    Number(n) => n
    _ => raise JsonTypeError("Double::from_json: expected number")
  }
}

pub impl FromJson for String with from_json(json) {
  match json {
    String(a) => a
    _ => raise JsonTypeError("String::from_json: expected string")
  }
}

pub impl FromJson for Char with from_json(json) {
  match json {
    String(a) =>
      if a.length() != 1 {
        raise JsonTypeError("Char::from_json: expected single character")
      } else {
        a[0]
      }
    _ => raise JsonTypeError("Char::from_json: expected string")
  }
}

pub impl[X : FromJson] FromJson for Array[X] with from_json(json) {
  match json {
    Array(a) => {
      let res : Array[X] = Array::new(capacity=a.length())
      for i = 0; i < a.length(); i = i + 1 {
        res.push(FromJson::from_json!(a[i]))
      }
      res
    }
    _ => raise JsonTypeError("Array::from_json: expected array")
  }
}

pub impl[V : FromJson] FromJson for Map[String, V] with from_json(json) {
  match json {
    Object(obj) => {
      let res : Map[String, V] = Map::new()
      for kv in obj.iter() {
        res[kv.0] = FromJson::from_json!(kv.1)
      }
      res
    }
    _ => raise JsonTypeError("Map::from_json: expected object")
  }
}
