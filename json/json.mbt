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
/// Try to get this element as a Null
#deprecated("Suggestion: `if json is Null { Some(()) } else { None }`")
pub fn Json::as_null(self : Json) -> Unit? {
  guard self is Null else { return None }
  Some(())
}

///|
/// Try to get this element as a Boolean
#deprecated("Suggestion: `if json is True { Some(true) } else if json is False { Some(false) } else { None }`")
pub fn Json::as_bool(self : Json) -> Bool? {
  match self {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

///|
/// Try to get this element as a Number
#deprecated("Suggestion: `if json is Number(n) { Some(n) } else { None }`")
pub fn Json::as_number(self : Json) -> Double? {
  guard self is Number(n, ..) else { return None }
  Some(n)
}

///|
/// Try to get this element as a String
#deprecated("Suggestion: `if json is String(s) { Some(s) } else { None }`")
pub fn Json::as_string(self : Json) -> String? {
  guard self is String(s) else { return None }
  Some(s)
}

///|
/// Try to get this element as an Array
#deprecated("Suggestion: `if json is Array(array) { Some(array) } else { None }`")
pub fn Json::as_array(self : Json) -> Array[Json]? {
  guard self is Array(arr) else { return None }
  Some(arr)
}

///|
/// Try to get this element as a Json Array and get the element at the `index` as a Json Value
#deprecated("Suggestion: `if json is Array(array) { array.get(index) } else { None }`")
pub fn Json::item(self : Json, index : Int) -> Json? {
  if self is Array(arr) {
    arr.get(index)
  } else {
    None
  }
}

///|
/// Try to get this element as an Object
#deprecated
pub fn Json::as_object(self : Json) -> Map[String, Json]? {
  guard self is Object(obj) else { return None }
  Some(obj)
}

///|
/// Try to get this element as a Json Object and get the element with the `key` as a Json Value
#deprecated("Suggestion: `if json is Object(obj) { obj.get(key) } else { None }`")
pub fn Json::value(self : Json, key : String) -> Json? {
  if self is Object(obj) {
    obj.get(key)
  } else {
    None
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
  Array(Array[Json], mut i~ : Int) // (arr, index)
  Object(Iter[(String, Json)], mut first~ : Bool) // (kvs, first)
}

///|
/// A Replacer provides a way to filter and transform JSON object properties during stringification.
/// 
/// Replacers contain a function that takes a property key and value, and returns:
/// - `Some(value)` to include the property in the output (possibly transformed)
/// - `None` to exclude the property from the output
/// 
/// Only applies to object properties, not array elements.
struct Replacer((String, Json) -> Json?)

///|
/// Create a new Replacer with a custom function.
/// 
/// The function receives `(key, value)` pairs and should return:
/// - `Some(transformed_value)` to include the property
/// - `None` to exclude the property
/// 
/// ## Example
/// 
/// ```mbt check
/// test {
///   // Transform numbers and exclude sensitive fields
///   ignore(
///     @json.Replacer::new((key, value) => match key {
///       "password" | "secret" => None // exclude sensitive fields
///       _ =>
///         match value {
///           Number(n, ..) => Some(Json::number(n * 2.0)) // double all numbers
///           _ => Some(value) // keep other values as-is
///         }
///     }),
///   )
/// }
/// ```
pub fn Replacer::new(f : (String, Json) -> Json?) -> Replacer {
  Replacer(f)
}

///|
/// Create a Replacer that only keeps the specified property keys.
/// All other properties will be excluded from the output.
/// 
/// ## Example
/// 
/// ```mbt check
/// test {
///   let replacer = @json.Replacer::keep(["name", "age", "email"])
///   let json : Json = {
///     "name": "Alice",
///     "age": 30.0,
///     "email": "alice@example.com",
///     "password": "secret",
///   }
///   ignore(json.stringify(replacer~)) // {"name":"Alice","age":30,"email":"alice@example.com"}
/// }
/// ```
pub fn Replacer::keep(array : ArrayView[StringView]) -> Replacer {
  Replacer((idx, value) => if array.contains(idx) { Some(value) } else { None })
}

///|
/// Create a Replacer that excludes the specified property keys.
/// All other properties will be included in the output.
/// 
/// ## Example
/// 
/// ```mbt check
/// test {
///   let replacer = @json.Replacer::exclude(["password", "secret", "private"])
///   let json : Json = {
///     "name": "Alice",
///     "age": 30.0,
///     "password": "secret",
///     "email": "alice@example.com",
///   }
///   ignore(json.stringify(replacer~)) // {"name":"Alice","age":30,"email":"alice@example.com"}
/// }
/// ```
pub fn Replacer::exclude(array : ArrayView[StringView]) -> Replacer {
  Replacer((idx, value) => if array.contains(idx) { None } else { Some(value) })
}

///|
/// Convert this Json value to a String
/// - `escape_slash`: Whether to escape '/' as '\/' (default: false)
/// - `indent`: Number of spaces to indent nested structures (default: 0 = non-indented)
/// - `replacer`: An optional Replacer function to transform or filter values during stringification
/// 
/// ## Replacer
/// 
/// The replacer parameter allows you to control which object properties are included in the output
/// and optionally transform values during stringification. Only applies to object properties, not array elements.
/// 
/// ### Creating Replacers
/// 
/// 1. **Replacer::new(f)** - Create a custom replacer with a function `(String, Json) -> Json?`:
///    - Return `Some(value)` to include the property (possibly transformed)
///    - Return `None` to exclude the property
/// 
/// 2. **Replacer::keep(keys)** - Include only the specified property keys
/// 
/// 3. **Replacer::exclude(keys)** - Exclude the specified property keys
/// 
/// ### Examples
/// 
/// ```mbt check
/// test {
///   let json : Json = { "a": 1.0, "b": 2.0, "c": 3.0, "password": "secret" }
///
///   // Keep only specific keys
///   let keep_replacer = @json.Replacer::keep(["a", "c"])
///   ignore(json.stringify(replacer=keep_replacer)) // {"a":1,"c":3}
///
///   // Exclude sensitive keys
///   let exclude_replacer = @json.Replacer::exclude(["password"])
///   ignore(json.stringify(replacer=exclude_replacer)) // {"a":1,"b":2,"c":3}
///
///   // Custom transformation
///   let transform_replacer = @json.Replacer::new((_key, value) => match value {
///     Number(n, ..) => Some(Json::number(n * 10.0)) // multiply numbers by 10
///     _ => Some(value) // keep other values unchanged
///   })
///   ignore(json.stringify(replacer=transform_replacer)) // {"a":10,"b":20,"c":30,"password":"secret"}
///
///   // Filter and transform
///   let filter_replacer = @json.Replacer::new((key, value) => match key {
///     "password" => None // exclude password
///     _ =>
///       match value {
///         Number(n, ..) => Some(Json::number(n + 100.0)) // add 100 to numbers
///         _ => Some(value)
///       }
///   })
///   ignore(json.stringify(replacer=filter_replacer)) // {"a":101,"b":102,"c":103}
/// }
/// ```
/// 
/// ### Nested Objects
/// 
/// Replacers work recursively on nested objects:
/// 
/// ```mbt check
/// test {
///   let nested : Json = {
///     "user": { "name": "Alice", "password": "secret" },
///     "id": 123.0,
///   }
///   let safe_replacer = @json.Replacer::exclude(["password"])
///   ignore(nested.stringify(replacer=safe_replacer)) // {"user":{"name":"Alice"},"id":123}
/// }
/// ```
pub fn Json::stringify(
  self : Json,
  escape_slash? : Bool = false,
  indent? : Int = 0,
  replacer? : Replacer,
) -> String {
  let buf = StringBuilder::new(size_hint=0)

  // Explicit stack to replace recursive calls
  let stack : Array[WriteFrame] = []
  let mut depth = 0
  loop Some(self) {
    Some(value) => {
      match value {
        Object(members) =>
          if members.is_empty() {
            buf.write_string("{}")
          } else {
            depth += 1
            buf.write_char('{')
            buf.write_string(indent_str(depth, indent))
            // After child value printed, we resume from this frame
            stack.push(WriteFrame::Object(members.iter(), first=true))
          }
        Array(arr) =>
          if arr.is_empty() {
            buf.write_string("[]")
          } else {
            depth += 1
            buf.write_char('[')
            buf.write_string(indent_str(depth, indent))
            stack.push(WriteFrame::Array(arr, i=0))
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
      continue None
    }
    None =>
      // No current node to write; try to resume a pending container
      match stack {
        [] => break
        [.., WriteFrame::Array(arr, i~) as frame] =>
          if i < arr.length() {
            let element = arr[i]
            frame.i = i + 1
            if i > 0 {
              buf.write_char(',')
              buf.write_string(indent_str(depth, indent))
            }
            continue Some(element)
          } else {
            depth -= 1
            ignore(stack.pop())
            buf.write_string(indent_str(depth, indent))
            buf.write_char(']')
            continue None
          }
        [.., WriteFrame::Object(iterator, first~) as frame] =>
          match iterator.next() {
            Some((k, v)) => {
              let mut v2 = v
              if replacer is Some(replacer) {
                if replacer(k, v) is Some(v) {
                  v2 = v
                } else {
                  continue None
                }
              }
              if !first {
                buf.write_char(',')
                buf.write_string(indent_str(depth, indent))
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
              continue Some(v2)
            }
            None => {
              depth -= 1
              ignore(stack.pop())
              buf.write_string(indent_str(depth, indent))
              buf.write_char('}')
              continue None
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
/// Transform a JSON value by applying a replacer recursively to all object properties.
/// 
/// Unlike `stringify(replacer~)` which only affects the string output, `transform()` 
/// returns a new JSON value with properties filtered and transformed according to the replacer.
/// 
/// This is useful when you want to create a modified JSON structure that can be further 
/// processed, rather than just converting to a string.
/// 
/// ## Example
/// 
/// ```mbt check
/// test {
///   let json : Json = {
///     "user": { "name": "Alice", "password": "secret", "age": 30.0 },
///     "id": 123.0,
///   }
///
///   // Remove sensitive data and double numeric values  
///   ignore(
///     json.transform(
///       @json.Replacer::new((key, value) => match key {
///         "password" => None // exclude password fields
///         _ =>
///           match value {
///             Number(n, ..) => Some(Json::number(n * 2.0)) // double numbers
///             _ => Some(value) // keep other values
///           }
///       }),
///     ),
///   )
///   // Result: { "user": { "name": "Alice", "age": 60 }, "id": 246 }
/// }
/// ```
/// 
/// ## Behavior
/// 
/// - Recursively applies the replacer to all nested objects
/// - Non-object values (arrays, strings, numbers, etc.) are returned unchanged
/// - The original JSON value is not modified; a new value is returned
pub fn Json::transform(self : Self, replacer : Replacer) -> Json {
  match self {
    Object(members) =>
      members
      .iter()
      .filter_map(pair => {
        let (k, v) = pair
        if replacer(k, v) is Some(v2) {
          Some((k, v2.transform(replacer)))
        } else {
          None
        }
      })
      |> Map::from_iter()
      |> Object
    Array(members) => Array(members.map(m => m.transform(replacer)))
    value => value
  }
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
  let loc = loc.to_json_string()
  let args_loc = args_loc.to_json()
  let actual = obj.to_json().stringify(escape_slash=false)
  let want = match content {
    None => "".to_json().stringify(escape_slash=false)
    Some(x) => x.stringify(escape_slash=false)
  }
  if actual != want {
    raise InspectError::InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{want.escape()}, \"actual\": \{actual.escape()}, \"mode\": \"json\"}",
    )
  }
}
