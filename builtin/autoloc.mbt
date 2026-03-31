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
/// Represents a source code location in a MoonBit program, containing
/// information about the file path, line number, and column number. Used
/// internally by the compiler for error reporting and debugging purposes.
///
/// This type is public to all packages but its internal representation is
/// opaque. Users cannot construct values of this type directly; they are
/// automatically created by the compiler when needed.
/// TODO: can not make a dummy loc
pub(all) type SourceLoc

///|
/// Converts a source location to its string representation.
///
/// Parameters:
///
/// * `source_location` : A source code location containing information about the
/// file path, line number, and column number.
///
/// Returns a string representation of the source location, typically in the
/// format "@package:file:start_line:start_column-end_line:end_column".
///
/// Note: This function is primarily used internally by the compiler for error
/// reporting and debugging purposes. Source locations are automatically created
/// by the compiler when needed.
fn SourceLoc::repr(self : Self) -> String = "%loc_to_string"

///|
pub impl Show for SourceLoc with to_string(self) {
  self.repr()
}

///|
priv struct SourceLocRepr {
  filename : StringView
  start_line : StringView
  start_column : StringView
  end_line : StringView
  end_column : StringView
}

///|
fn SourceLocRepr::parse(repr : String) -> SourceLocRepr {
  lexmatch repr[:] {
    (
      (".+?" as filename)
      ":"
      ("[[:digit:]]+" as start_line)
      ":"
      ("[[:digit:]]+" as start_column)
      "-"
      ("[[:digit:]]+" as end_line)
      ":"
      ("[[:digit:]]+" as end_column)
      "@"
      ("[^:]*" as _module)
    ) => { filename, start_line, start_column, end_line, end_column }
    _ => panic()
  }
}

///|
fn SourceLocRepr::to_json_string(self : SourceLocRepr) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{\"filename\":")
  sb.write_object(self.filename)
  sb.write_string(",\"start_line\":\{self.start_line}")
  sb.write_string(",\"start_column\":\{self.start_column}")
  sb.write_string(",\"end_line\":\{self.end_line}")
  sb.write_string(",\"end_column\":\{self.end_column}}")
  sb.to_string()
}

///|
/// Convert a source location to a JSON string
pub fn SourceLoc::to_json_string(self : SourceLoc) -> String {
  SourceLocRepr::parse(self.repr()).to_json_string()
}

///|
/// Represents a type for storing argument locations in source code. It is an
/// array of optional source locations, where each element corresponds to an
/// argument's location in the source code. Used internally by the compiler for
/// error reporting and debugging purposes.
pub(all) struct ArgsLoc(Array[SourceLoc?]) derive(Show)

///|
/// Converts an array of optional source locations to its JSON string
/// representation. Each location in the array is either represented as a string
/// if present, or "null" if absent.
///
/// Parameters:
///
/// * `self` : The array of optional source locations to be converted.
///
/// Returns a JSON array string where each element is either a string
/// representation of a source location or "null".
pub fn ArgsLoc::to_json(self : ArgsLoc) -> String {
  let buf = StringBuilder::new(size_hint=10)
  let ArgsLoc(self) = self
  buf.write_char('[')
  for i, item in self {
    if i != 0 {
      buf.write_string(", ")
    }
    match item {
      None => buf.write_string("null")
      Some(loc) => buf.write_string(loc.to_json_string())
    }
  }
  buf.write_char(']')
  buf.to_string()
}
