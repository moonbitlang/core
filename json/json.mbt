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
pub fn Json::as_null(self : Json) -> Unit? {
  guard self is Null else { return None }
  Some(())
}

///|
/// Try to get this element as a Boolean
pub fn Json::as_bool(self : Json) -> Bool? {
  match self {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

///|
/// Try to get this element as a Number
pub fn Json::as_number(self : Json) -> Double? {
  guard self is Number(n, ..) else { return None }
  Some(n)
}

///|
/// Try to get this element as a String
pub fn Json::as_string(self : Json) -> String? {
  guard self is String(s) else { return None }
  Some(s)
}

///|
/// Try to get this element as an Array
pub fn Json::as_array(self : Json) -> Array[Json]? {
  guard self is Array(arr) else { return None }
  Some(arr)
}

///|
/// Try to get this element as a Json Array and get the element at the `index` as a Json Value
pub fn Json::item(self : Json, index : Int) -> Json? {
  match self.as_array() {
    Some(arr) => arr.get(index)
    None => None
  }
}

///|
/// Try to get this element as an Object
pub fn Json::as_object(self : Json) -> Map[String, Json]? {
  guard self is Object(obj) else { return None }
  Some(obj)
}

///|
/// Try to get this element as a Json Object and get the element with the `key` as a Json Value
pub fn Json::value(self : Json, key : String) -> Json? {
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
    let spaces = indent * level
    match spaces {
      0 => "\n"
      1 => "\n "
      2 => "\n  "
      3 => "\n   "
      4 => "\n    "
      5 => "\n     "
      6 => "\n      "
      7 => "\n       "
      8 => "\n        "
      _ => "\n" + " ".repeat(spaces)
    }
  }
}

///|
/// Internal stack frame used by iterative stringify to avoid recursion
priv enum WriteFrame {
  Array(Array[Json], mut i~ : Int, Int) // (arr, index, depth)
  Object(Iterator[(String, Json)], mut first~ : Bool, Int) // (kvs, first, depth)
}

///|
/// Convert this Json value to a String
/// - `escape_slash`: Whether to escape '/' as '\/' (default: false)
/// - `indent`: Number of spaces to indent nested structures (default: 0 = non-indented)
pub fn Json::stringify(
  self : Json,
  escape_slash? : Bool = false,
  indent? : Int = 0,
) -> String {
  let buf = StringBuilder::new(size_hint=0)

  // Explicit stack to replace recursive calls
  let stack : Array[WriteFrame] = []
  loop (Some(self), 0) {
    (Some(value), depth) =>
      match value {
        Object(members) =>
          if members.is_empty() {
            buf.write_string("{}")
            continue (None, depth)
          } else {
            buf.write_char('{')
            buf.write_string(indent_str(depth + 1, indent))
            // After child value printed, we resume from this frame
            stack.push(
              WriteFrame::Object(members.iterator(), first=true, depth),
            )
            continue (None, depth)
          }
        Array(arr) =>
          if arr.is_empty() {
            buf.write_string("[]")
            continue (None, depth)
          } else {
            buf.write_char('[')
            buf.write_string(indent_str(depth + 1, indent))
            stack.push(WriteFrame::Array(arr, i=0, depth))
            continue (None, depth)
          }
        String(s) => {
          buf
          ..write_char('\"')
          ..write_string(escape(s, escape_slash~))
          ..write_char('\"')
          continue (None, depth)
        }
        Number(n, repr~) => {
          match repr {
            None => buf.write_object(n)
            Some(r) => buf.write_string(r)
          }
          continue (None, depth)
        }
        True => {
          buf.write_string("true")
          continue (None, depth)
        }
        False => {
          buf.write_string("false")
          continue (None, depth)
        }
        Null => {
          buf.write_string("null")
          continue (None, depth)
        }
      }
    (None, _) =>
      // No current node to write; try to resume a pending container
      match stack {
        [] => break
        [.., WriteFrame::Array(arr, i~, depth) as frame] =>
          if i < arr.length() {
            if i > 0 {
              buf.write_char(',')
              buf.write_string(indent_str(depth + 1, indent))
            }
            let element = arr[i]
            frame.i = i + 1
            continue (Some(element), depth + 1)
          } else {
            ignore(stack.pop())
            buf.write_string(indent_str(depth, indent))
            buf.write_char(']')
            continue (None, depth)
          }
        [.., WriteFrame::Object(iterator, first~, depth) as frame] =>
          match iterator.next() {
            Some((k, v)) => {
              if !first {
                buf.write_char(',')
                buf.write_string(indent_str(depth + 1, indent))
              }
              buf
              ..write_char('\"')
              ..write_string(escape(k, escape_slash~))
              ..write_char('\"')
              ..write_char(':')
              if indent > 0 {
                buf.write_char(' ')
              }
              frame.first = false
              continue (Some(v), depth + 1)
            }
            None => {
              ignore(stack.pop())
              buf.write_string(indent_str(depth, indent))
              buf.write_char('}')
              continue (None, depth)
            }
          }
      }
  }
  buf.to_string()
}

///|
fn escape(str : String, escape_slash~ : Bool) -> String {
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
        } else if code < ' ' {
          buf.write_string("\\u00")
          buf.write_string(code.to_byte().to_hex())
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
