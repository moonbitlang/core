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
#inline
fn write_indent(
  buf : StringBuilder,
  cache : Array[String],
  level : Int,
  indent : Int,
) -> Unit {
  // Each level is the previous one plus a single indentation unit. Building a
  // level is still O(indent * level) — concatenation copies `last` — but it
  // replaces a fresh `repeat(indent * level)` with a `repeat(indent)`, roughly
  // halving the bytes written per level. It also never computes the product
  // `indent * level`, which overflows `Int` to a negative value for a large
  // `indent` and is then rejected by `String::repeat`.
  //
  // The unit is built here rather than once per `stringify` call so that a
  // document emitting no indentation at all never allocates it: callers reach
  // this only when `indent > 0`, so `repeat` never sees a negative count.
  while cache.length() <= level {
    match cache {
      [.., last] => cache.push(last + " ".repeat(indent))
      [] => cache.push("\n")
    }
  }
  buf.write_string(cache[level])
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
pub struct Replacer {
  priv f : (String, Json) -> Json?
}

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
///     @builtin.Replacer((key, value) => {
///       match key {
///         "password" | "secret" => None // exclude sensitive fields
///         _ =>
///           match value {
///             Number(n, ..) => Some(Json::number(n * 2.0)) // double all numbers
///             _ => Some(value) // keep other values as-is
///           }
///       }
///     }),
///   )
/// }
/// ```
#alias(new, deprecated="Use `Replacer()` instead")
pub fn Replacer::Replacer(f : (String, Json) -> Json?) -> Replacer {
  { f, }
}

///|
/// Create a Replacer that only keeps the specified property keys.
/// All other properties will be excluded from the output.
///
/// ## Example
///
/// ```mbt check
/// test {
///   let replacer = @builtin.Replacer::keep(["name", "age", "email"])
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
  { f: (idx, value) => if array.contains(idx) { Some(value) } else { None }, }
}

///|
/// Create a Replacer that excludes the specified property keys.
/// All other properties will be included in the output.
///
/// ## Example
///
/// ```mbt check
/// test {
///   let replacer = @builtin.Replacer::exclude(["password", "secret", "private"])
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
  { f: (idx, value) => if array.contains(idx) { None } else { Some(value) }, }
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
/// 1. **Replacer(f)** - Create a custom replacer with a function `(String, Json) -> Json?`:
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
///   let keep_replacer = @builtin.Replacer::keep(["a", "c"])
///   ignore(json.stringify(replacer=keep_replacer)) // {"a":1,"c":3}
///
///   // Exclude sensitive keys
///   let exclude_replacer = @builtin.Replacer::exclude(["password"])
///   ignore(json.stringify(replacer=exclude_replacer)) // {"a":1,"b":2,"c":3}
///
///   // Custom transformation
///   let transform_replacer = @builtin.Replacer((_key, value) => {
///     match value {
///       Number(n, ..) => Some(Json::number(n * 10.0)) // multiply numbers by 10
///       _ => Some(value) // keep other values unchanged
///     }
///   })
///   ignore(json.stringify(replacer=transform_replacer)) // {"a":10,"b":20,"c":30,"password":"secret"}
///
///   // Filter and transform
///   let filter_replacer = @builtin.Replacer((key, value) => {
///     match key {
///       "password" => None // exclude password
///       _ =>
///         match value {
///           Number(n, ..) => Some(Json::number(n + 100.0)) // add 100 to numbers
///           _ => Some(value)
///         }
///     }
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
///   let safe_replacer = @builtin.Replacer::exclude(["password"])
///   ignore(nested.stringify(replacer=safe_replacer)) // {"user":{"name":"Alice"},"id":123}
/// }
/// ```
pub fn Json::stringify(
  self : Json,
  escape_slash? : Bool = false,
  indent? : Int = 0,
  replacer? : Replacer,
) -> String {
  let buf = StringBuilder(size_hint=0)
  let indent_cache : Array[String] = []

  // Explicit stack to replace recursive calls
  let stack : Array[WriteFrame] = []
  let mut depth = 0
  for x = Some(self) {
    match x {
      Some(value) => {
        match value {
          Object(members) =>
            if members.is_empty() {
              buf.write_string("{}")
            } else {
              depth += 1
              buf.write_char('{')
              if indent > 0 {
                write_indent(buf, indent_cache, depth, indent)
              }
              // After child value printed, we resume from this frame
              stack.push(Object(members.iter(), first=true))
            }
          Array(arr) =>
            if arr.is_empty() {
              buf.write_string("[]")
            } else {
              depth += 1
              buf.write_char('[')
              if indent > 0 {
                write_indent(buf, indent_cache, depth, indent)
              }
              stack.push(Array(arr, i=0))
            }
          String(s) => {
            buf.write_char('\"')
            write_escaped(buf, s, escape_slash~)
            buf.write_char('\"')
          }
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
          [.., Array(arr, i~) as frame] =>
            if i < arr.length() {
              let element = arr[i]
              frame.i = i + 1
              if i > 0 {
                buf.write_char(',')
                if indent > 0 {
                  write_indent(buf, indent_cache, depth, indent)
                }
              }
              continue Some(element)
            } else {
              depth -= 1
              ignore(stack.pop())
              if indent > 0 {
                write_indent(buf, indent_cache, depth, indent)
              }
              buf.write_char(']')
              continue None
            }
          [.., Object(iterator, first~) as frame] =>
            match iterator.next() {
              Some((k, v)) => {
                let mut v2 = v
                if replacer is Some(replacer) {
                  if (replacer.f)(k, v) is Some(v) {
                    v2 = v
                  } else {
                    continue None
                  }
                }
                if !first {
                  buf.write_char(',')
                  if indent > 0 {
                    write_indent(buf, indent_cache, depth, indent)
                  }
                }
                buf.write_char('\"')
                write_escaped(buf, k, escape_slash~)
                buf.write_char('\"')
                buf.write_char(':')
                if indent > 0 {
                  buf.write_char(' ')
                }
                frame.first = false
                continue Some(v2)
              }
              None => {
                depth -= 1
                ignore(stack.pop())
                if indent > 0 {
                  write_indent(buf, indent_cache, depth, indent)
                }
                buf.write_char('}')
                continue None
              }
            }
        }
    }
  }
  buf.to_string()
}

///|
#inline
fn need_escape_scalar(
  str : String,
  escape_slash : Bool,
  start : Int,
  end : Int,
) -> Bool {
  for i in start..<end {
    let code = str.unsafe_get(i)
    if code == '"' ||
      code == '\\' ||
      code < ' ' ||
      (escape_slash && code == '/') {
      return true
    }
  }
  false
}

///|
#cfg(not(any(target="native", target="wasm")))
fn need_escape(str : String, escape_slash : Bool) -> Bool {
  need_escape_scalar(str, escape_slash, 0, str.length())
}

///|
// Scan eight UTF-16 code units at a time on linear-memory backends, then scan
// the remaining tail one code unit at a time.
#cfg(any(target="native", target="wasm"))
fn need_escape(str : String, escape_slash : Bool) -> Bool {
  let len = str.length()
  guard len >= 8 else { return need_escape_scalar(str, escape_slash, 0, len) }
  // Control characters are exactly the unsigned code units <= 0x1F.
  let control_limit = i16x8_splat(0x1F)
  let quote = i16x8_splat('"')
  let backslash = i16x8_splat('\\')
  let slash = i16x8_splat('/')
  let tail_start = for pos = 0; pos + 8 <= len; {
    let block = v128_load_i16x8(str, pos)
    let escaped = v128_or(
      i16x8_le_u(block, control_limit),
      v128_or(i16x8_eq(block, quote), i16x8_eq(block, backslash)),
    )
    let escaped = if escape_slash {
      v128_or(escaped, i16x8_eq(block, slash))
    } else {
      escaped
    }
    if v128_any_true(escaped) {
      return true
    }
    continue pos + 8
  } nobreak {
    pos
  }
  need_escape_scalar(str, escape_slash, tail_start, len)
}

///|
fn write_escaped(
  buf : StringBuilder,
  str : String,
  escape_slash~ : Bool,
) -> Unit {
  if !need_escape(str, escape_slash) {
    buf.write_string(str)
    return
  }
  for code in str.code_units() {
    match code {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '/' =>
        if escape_slash {
          buf.write_string("\\/")
        } else {
          buf.write_char('/')
        }
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\b' => buf.write_string("\\b")
      '\t' => buf.write_string("\\t")
      0x0C => buf.write_string("\\f")
      _ =>
        if code < ' ' {
          buf.write_string("\\u00")
          buf.write_string(code.to_byte().to_hex())
        } else {
          buf.write_char(code.unsafe_to_char())
        }
    }
  }
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
///       Replacer((key, value) => {
///         match key {
///           "password" => None // exclude password fields
///           _ =>
///             match value {
///               Number(n, ..) => Some(Json::number(n * 2.0)) // double numbers
///               _ => Some(value) // keep other values
///             }
///         }
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
/// - Arrays are rebuilt element by element, so objects nested inside an array are
///   transformed as well (the replacer itself is only applied to object members)
/// - All other values (strings, numbers, booleans, null) are returned unchanged
/// - The original JSON value is not modified; a new value is returned
pub fn Json::transform(self : Self, replacer : Replacer) -> Json {
  match self {
    Object(members) =>
      members
      .iter()
      .filter_map(pair => {
        let (k, v) = pair
        if (replacer.f)(k, v) is Some(v2) {
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
