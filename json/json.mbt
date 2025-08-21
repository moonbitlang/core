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
/// Try to get this element as a Null
pub fn as_null(self : Json) -> Unit? {
  guard self is Null else { return None }
  Some(())
}

///|
/// Try to get this element as a Boolean
pub fn as_bool(self : Json) -> Bool? {
  match self {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

///|
/// Try to get this element as a Number
pub fn as_number(self : Json) -> Double? {
  guard self is Number(n, ..) else { return None }
  Some(n)
}

///|
/// Try to get this element as a String
pub fn as_string(self : Json) -> String? {
  guard self is String(s) else { return None }
  Some(s)
}

///|
/// Try to get this element as an Array
pub fn as_array(self : Json) -> Array[Json]? {
  guard self is Array(arr) else { return None }
  Some(arr)
}

///|
/// Try to get this element as a Json Array and get the element at the `index` as a Json Value
pub fn item(self : Json, index : Int) -> Json? {
  match self.as_array() {
    Some(arr) => arr.get(index)
    None => None
  }
}

///|
/// Try to get this element as an Object
pub fn as_object(self : Json) -> Map[String, Json]? {
  guard self is Object(obj) else { return None }
  Some(obj)
}

///|
/// Try to get this element as a Json Object and get the element with the `key` as a Json Value
pub fn value(self : Json, key : String) -> Json? {
  match self.as_object() {
    Some(obj) => obj.get(key)
    None => None
  }
}

///|
fn indent_str(level : Int, indent : Int) -> String {
  if indent == 0 {
    ""
  } else {
    "\n" + " ".repeat(indent * level)
  }
}

///|
pub fn stringify(
  self : Json,
  escape_slash? : Bool = false,
  indent? : Int = 0,
) -> String {
  let buf = StringBuilder::new(size_hint=0)
  fn stringify_inner(value : Json, level : Int) -> Unit {
    match value {
      Object(members) => {
        if members.is_empty() {
          buf.write_string("{}")
          return
        }
        buf.write_char('{')
        buf.write_string(indent_str(level + 1, indent))
        let mut first = true
        for k, v in members {
          if first {
            first = false
          } else {
            buf.write_char(',')
            buf.write_string(indent_str(level + 1, indent))
          }
          buf
          ..write_char('\"')
          ..write_string(escape(k, escape_slash~))
          ..write_char('\"')
          if indent == 0 {
            buf.write_char(':')
          } else {
            buf.write_string(": ")
          }
          stringify_inner(v, level + 1)
        }
        buf.write_string(indent_str(level, indent))
        buf.write_char('}')
      }
      Array(arr) => {
        if arr.is_empty() {
          buf.write_string("[]")
          return
        }
        buf.write_char('[')
        buf.write_string(indent_str(level + 1, indent))
        for i, v in arr {
          if i > 0 {
            buf.write_char(',')
            buf.write_string(indent_str(level + 1, indent))
          }
          stringify_inner(v, level + 1)
        }
        buf.write_string(indent_str(level, indent))
        buf.write_char(']')
      }
      String(s) =>
        buf
        ..write_char('\"')
        ..write_string(escape(s, escape_slash~))
        ..write_char('\"')
      Number(n, repr~) =>
        match repr {
          None => buf.write_object(n)
          Some(r) => buf.write_string(r)
        }
      True => buf.write_string("true")
      False => buf.write_string("false")
      Null => buf.write_string("null")
    }
  }

  stringify_inner(self, 0)
  buf.to_string()
}

///|
fn escape(str : String, escape_slash~ : Bool) -> String {
  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      ('0'.to_int() + i).unsafe_to_char()
    } else {
      ('a'.to_int() + (i - 10)).unsafe_to_char()
    }
  }

  let buf = StringBuilder::new(size_hint=str.length())
  for c in str {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
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

///|
/// Useful for json interpolation
pub impl ToJson for Json with to_json(self) {
  self
}

///|
#callsite(autofill(args_loc, loc))
pub fn inspect(
  obj : &ToJson,
  content? : Json,
  loc~ : SourceLoc,
  args_loc~ : ArgsLoc,
) -> Unit raise InspectError {
  let loc = loc.to_string().escape()
  let args_loc = args_loc.to_json().escape()
  let actual = obj.to_json().stringify(escape_slash=false)
  let want = match content {
    None => "".to_json().stringify(escape_slash=false)
    Some(x) => x.stringify(escape_slash=false)
  }
  if actual != want {
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{want.escape()}, \"actual\": \{actual.escape()}, \"mode\": \"json\"}",
    )
  }
}
