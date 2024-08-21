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

/// Try to get this element as a Null
pub fn as_null(self : JsonValue) -> Unit? {
  match self {
    Null => Some(())
    _ => None
  }
}

/// Try to get this element as a Boolean
pub fn as_bool(self : JsonValue) -> Bool? {
  match self {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

/// Try to get this element as a Number
pub fn as_number(self : JsonValue) -> Double? {
  match self {
    Number(n) => Some(n)
    _ => None
  }
}

/// Try to get this element as a String
pub fn as_string(self : JsonValue) -> String? {
  match self {
    String(s) => Some(s)
    _ => None
  }
}

/// Try to get this element as an Array
pub fn as_array(self : JsonValue) -> Array[JsonValue]? {
  match self {
    Array(arr) => Some(arr)
    _ => None
  }
}

/// Try to get this element as a Json Array and get the element at the `index` as a Json Value
pub fn item(self : JsonValue, index : Int) -> JsonValue? {
  match self.as_array() {
    Some(arr) => arr.get(index)
    None => None
  }
}

/// Try to get this element as an Object
pub fn as_object(self : JsonValue) -> Map[String, JsonValue]? {
  match self {
    Object(obj) => Some(obj)
    _ => None
  }
}

/// Try to get this element as a Json Object and get the element with the `key` as a Json Value
pub fn value(self : JsonValue, key : String) -> JsonValue? {
  match self.as_object() {
    Some(obj) => obj[key]
    None => None
  }
}

pub fn stringify(self : JsonValue) -> String {
  let buf = Buffer::new(size_hint=0)
  match self {
    Object(members) => {
      buf.write_char('{')
      members.eachi(
        fn(i, k, v) {
          if i > 0 {
            buf.write_char(',')
          }
          buf.write_char('\"')
          buf.write_string(escape(k))
          buf.write_char('\"')
          buf.write_char(':')
          buf.write_string(v.stringify())
        },
      )
      buf.write_char('}')
    }
    Array(arr) => {
      buf.write_char('[')
      arr.eachi(
        fn(i, v) {
          if i > 0 {
            buf.write_char(',')
          }
          buf.write_string(v.stringify())
        },
      )
      buf.write_char(']')
    }
    String(s) => {
      buf.write_char('\"')
      buf.write_string(escape(s))
      buf.write_char('\"')
    }
    Number(n) => {
      let int_n = n.to_int64()
      return if n == int_n.to_double() {
        int_n.to_string()
      } else {
        n.to_string()
      }
    }
    True => return "true"
    False => return "false"
    Null => return "null"
  }
  buf.to_string()
}

fn escape(str : String) -> String {
  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  let buf = Buffer::new(size_hint=str.length())
  for c in str {
    match c {
      '"' | '\\' | '/' => buf.write_string("\\\{c}")
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

/// Useful for json interpolation
pub fn to_json(self : JsonValue) -> JsonValue {
  self
}
