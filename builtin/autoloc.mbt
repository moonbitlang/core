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
pub impl Show for SourceLoc with output(self, logger) {
  SourceLocRepr::parse(self.repr()).output(logger)
}

///|
priv struct SourceLocRepr {
  pkg : StringView
  filename : StringView
  start_line : StringView
  start_column : StringView
  end_line : StringView
  end_column : StringView
}

///|
impl Show for SourceLocRepr with output(self, logger) {
  let pkg = self.pkg
  let (module_name, package_name) = {
    guard pkg.find("/") is Some(first_slash) else { (pkg, None) }
    guard pkg.view(start_offset=first_slash + 1).find("/") is Some(second_slash) else {
      (pkg, None)
    }
    let module_name_end = first_slash + 1 + second_slash
    (
      pkg.view(end_offset=module_name_end),
      Some(pkg.view(start_offset=module_name_end + 1)),
    )
  }
  if package_name is Some(pkg_name) {
    logger..write_view(pkg_name)..write_char('/')
  }
  logger
  ..write_view(self.filename)
  ..write_char(':')
  ..write_view(self.start_line)
  ..write_char(':')
  ..write_view(self.start_column)
  ..write_char('-')
  ..write_view(self.end_line)
  ..write_char(':')
  ..write_view(self.end_column)
  ..write_char('@')
  ..write_view(module_name)
}

///|
fn SourceLocRepr::parse(repr : String) -> SourceLocRepr {
  fn parse_loc(view : StringView) -> (StringView, StringView)? {
    guard view.find(":") is Some(i) else { None }
    guard i > 0 && i + 1 < view.length() else { None }
    Some((view.view(end_offset=i), view.view(start_offset=i + 1)))
  }
  // extract package name
  guard repr is ['@', .. rest]
  guard rest.find(":") is Some(pkg_end)
  let pkg = rest.view(start_offset=0, end_offset=pkg_end)

  // extract end location in reverse
  guard rest.rev_find("-") is Some(start_loc_end)
  guard start_loc_end + 1 < rest.length()
  let end_loc = rest.view(start_offset=start_loc_end + 1)
  guard parse_loc(end_loc) is Some((end_line, end_column))
  let rest = rest.view(end_offset=start_loc_end)

  // extract start location
  guard rest.rev_find(":") is Some(start_line_end) &&
    rest.view(end_offset=start_line_end).rev_find(":") is Some(filename_end)
  guard filename_end + 1 < rest.length()
  let start_loc = rest.view(start_offset=filename_end + 1)
  guard parse_loc(start_loc) is Some((start_line, start_column))

  // everything else remaining is treated as filename
  guard filename_end > pkg_end + 1
  let filename = rest.view(start_offset=pkg_end + 1, end_offset=filename_end)
  { pkg, filename, start_line, start_column, end_line, end_column }
}

///|
fn SourceLocRepr::to_json_string(self : SourceLocRepr) -> String {
  StringBuilder::new()
  ..write_string("{\"pkg\":\"\{self.pkg}\"")
  ..write_string(",\"filename\":")
  ..write_object(self.filename)
  ..write_string(",\"start_line\":\{self.start_line}")
  ..write_string(",\"start_column\":\{self.start_column}")
  ..write_string(",\"end_line\":\{self.end_line}")
  ..write_string(",\"end_column\":\{self.end_column}}")
  .to_string()
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
  for i in 0..<self.length() {
    if i != 0 {
      buf.write_string(", ")
    }
    let item = self[i]
    match item {
      None => buf.write_string("null")
      Some(loc) => buf.write_string(loc.to_json_string())
    }
  }
  buf.write_char(']')
  buf.to_string()
}
