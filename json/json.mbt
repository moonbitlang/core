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

pub fn stringify(self : JsonValue, ~escape_slash : Bool = true) -> String {
  match self {
    Object(members) => {
      let buf = Buffer::new(size_hint=0)
      buf.write_char('{')
      let mut first = true
      for k, v in members {
        if first {
          first = false
        } else {
          buf.write_char(',')
        }
        buf
        ..write_char('\"')
        ..write_string(escape(k, ~escape_slash))
        ..write_char('\"')
        ..write_char(':')
        .write_string(v.stringify(~escape_slash))
      }
      buf..write_char('}').to_string()
    }
    Array(arr) => {
      let buf = Buffer::new(size_hint=0)
      buf.write_char('[')
      for i, v in arr {
        if i > 0 {
          buf.write_char(',')
        }
        buf.write_string(v.stringify(~escape_slash))
      }
      buf..write_char(']').to_string()
    }
    String(s) => {
      let buf = Buffer::new(size_hint=0)
      buf
      ..write_char('\"')
      ..write_string(escape(s, ~escape_slash))
      ..write_char('\"')
      .to_string()
    }
    Number(n) => n.to_string()
    True => "true"
    False => "false"
    Null => "null"
  }
}

fn escape(str : String, ~escape_slash : Bool) -> String {
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
      '"' | '\\' => buf.write_string("\\\{c}")
      '/' =>
        if escape_slash {
          buf.write_string("\\/")
        } else {
          buf.write_char(c)
        }
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
