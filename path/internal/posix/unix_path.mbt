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
priv enum UnixPrefix {
  /// Syntax: `/` or `/{3,}`
  ///
  /// A pathname consisting of a single <slash> shall resolve to the root directory of the process.
  Root
  None
} derive(@json.ToJson, Hash, Eq)

///|
/// [Posix 4.13 Pathname Resolution](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_13)
priv struct UnixPath {
  prefix : UnixPrefix
  trailing_separator : Bool
  components : Array[StringView]
} derive(@json.ToJson, Hash, Eq)

///|
fn is_unix_sep_at(path : StringView, index : Int32) -> Bool {
  path.get_char(index) == Some('/')
}

///|
impl Show for UnixPath with fn output(self : UnixPath, logger : &Logger) -> Unit {
  let { prefix, trailing_separator, components, } = self
  match prefix {
    Root => logger.write_char('/')
    None => ()
  }
  match components {
    [] =>
      if prefix is None {
        if trailing_separator {
          logger <+ "./"
        } else {
          logger.write_char('.')
        }
      }
    [x, .. xs] => {
      logger.write_view(x)
      for x in xs {
        logger <+ "/\{x}"
      }
      if trailing_separator {
        logger.write_char('/')
      }
    }
  }
}

///|
fn push_unix_component(
  components : Array[StringView],
  component : StringView,
  allow_above_root~ : Bool,
) -> Unit {
  match component {
    "." => ()
    ".." =>
      match components.pop() {
        Some("..") => {
          components.push("..")
          if allow_above_root {
            components.push("..")
          }
        }
        None => if allow_above_root { components.push("..") }
        Some(_) => ()
      }
    _ => components.push(component)
  }
}

///|
fn skip_unix_separators(path : StringView, start : Int32) -> Int32 {
  let mut index = start
  while index < path.length() && is_unix_sep_at(path, index) {
    index += 1
  }
  index
}

///|
fn parse_unix_components(
  path : StringView,
  start : Int32,
  allow_above_root~ : Bool,
) -> Array[StringView] {
  let components : Array[StringView] = []
  path[start:]
  .split("/")
  .filter(fn(component) { !component.is_empty() })
  .each(fn(component) {
    push_unix_component(components, component, allow_above_root~)
  })
  components
}

///|
fn UnixPath::parse(path : StringView) -> UnixPath {
  let prefix = if !path.is_empty() && is_unix_sep_at(path, 0) {
    Root
  } else {
    None
  }
  let start = if prefix is Root { skip_unix_separators(path, 0) } else { 0 }
  let trailing_separator = path.length() > 0 &&
    is_unix_sep_at(path, path.length() - 1)
  let components = parse_unix_components(
    path,
    start,
    allow_above_root=prefix is None,
  )
  { prefix, trailing_separator, components, }
}
