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

///-----------------------------------------------------------------------------
pub enum Json {
  Null
  True
  False
  Number(Double)
  String(String)
  Array(Array[Json])
  Object(Map[String, Json])
} derive(Eq)

///-----------------------------------------------------------------------------
/// Trait for types that can be converted to `Json`
pub trait ToJson {
  to_json(Self) -> Json
}

///-----------------------------------------------------------------------------
pub fn Bool::to_json(self : Bool) -> Json {
  if self {
    true
  } else {
    false
  }
}

///-----------------------------------------------------------------------------
pub fn Int::to_json(self : Int) -> Json {
  Number(self.to_double())
}

///-----------------------------------------------------------------------------
pub fn Int64::to_json(self : Int64) -> Json {
  Number(self.to_double())
}

///-----------------------------------------------------------------------------
pub fn Double::to_json(self : Double) -> Json {
  Number(self)
}

///-----------------------------------------------------------------------------
pub fn Float::to_json(self : Float) -> Json {
  Number(self.to_double())
}

///-----------------------------------------------------------------------------
fn escape_json_string(str : String) -> String {
  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  let len = str.length()
  let buf = StringBuilder::new(size_hint=len)
  for i in 0..<len {
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

///-----------------------------------------------------------------------------
pub fn String::to_json(self : String) -> Json {
  String(escape_json_string(self))
}

///-----------------------------------------------------------------------------
pub fn Char::to_json(self : Char) -> Json {
  String(self.to_string())
}

///-----------------------------------------------------------------------------
pub fn BigInt::to_json(self : BigInt) -> Json {
  String(self.to_string())
}

///-----------------------------------------------------------------------------
pub fn Array::to_json[X : ToJson](self : Array[X]) -> Json {
  Array(self.map(ToJson::to_json))
}

///-----------------------------------------------------------------------------
pub fn FixedArray::to_json[X : ToJson](self : FixedArray[X]) -> Json {
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

///-----------------------------------------------------------------------------
pub fn ArrayView::to_json[X : ToJson](self : ArrayView[X]) -> Json {
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

///-----------------------------------------------------------------------------
pub fn Map::to_json[K : Show, V : ToJson](self : Map[K, V]) -> Json {
  let object = {}
  for k, v in self {
    object[k.to_string()] = v.to_json()
  }
  Object(object)
}

///-----------------------------------------------------------------------------
pub fn Set::to_json[X : ToJson](self : Set[X]) -> Json {
  let array = []
  for v in self {
    array.push(v.to_json())
  }
  Array(array)
}

///-----------------------------------------------------------------------------
pub fn Option::to_json[T : ToJson](self : T?) -> Json {
  match self {
    None => Null
    Some(value) => [value.to_json()]
  }
}

///-----------------------------------------------------------------------------
pub fn Result::to_json[Ok : ToJson, Err : ToJson](
  self : Result[Ok, Err]
) -> Json {
  match self {
    Ok(ok) => { "Ok": ok.to_json() }
    Err(err) => { "Err": err.to_json() }
  }
}

///-----------------------------------------------------------------------------
// unit
pub fn Unit::to_json(_self : Unit) -> Json {
  Null
}
