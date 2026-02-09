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
/// Clap-style argument specifications.
priv enum EngineArgAction {
  /// Store a value (for options/positionals) or mark present (for flags).
  Set
  /// For flags: set to true; for value-taking args: parse as bool.
  SetTrue
  /// For flags: set to false; for value-taking args: parse as bool then invert.
  SetFalse
  /// Count occurrences (flags only).
  Count
  /// Allow multiple values by appending.
  Append
  /// Show help and exit (flags only).
  Help
  /// Show version and exit (flags only).
  Version
} derive(Eq)

///|
/// Number-of-values constraint for an argument.
priv struct EngineValueRange {
  lower : Int?
  upper : Int?
  lower_inclusive : Bool
  upper_inclusive : Bool
}

///|
fn EngineValueRange::new(
  lower? : Int? = None,
  upper? : Int? = None,
  lower_inclusive? : Bool = true,
  upper_inclusive? : Bool = true,
) -> EngineValueRange {
  EngineValueRange::{ lower, upper, lower_inclusive, upper_inclusive }
}

///|
fn resolve_value_range(range : EngineValueRange) -> (Int, Int?) {
  let min = match range.lower {
    Some(value) => if range.lower_inclusive { value } else { value + 1 }
    None => 0
  }
  let max = match range.upper {
    Some(value) => Some(if range.upper_inclusive { value } else { value - 1 })
    None => None
  }
  (min, max)
}

///|
fn validate_value_range(
  range : EngineValueRange,
) -> (Int, Int?) raise ArgBuildError {
  let (min, max) = resolve_value_range(range)
  match max {
    Some(max_value) if max_value < min =>
      raise ArgBuildError::Unsupported("max values must be >= min values")
    _ => ()
  }
  (min, max)
}

///|
fn arg_min_max_for_validate(
  arg : EngineArg,
) -> (Int, Int?) raise ArgBuildError {
  match arg.num_args {
    Some(range) => validate_value_range(range)
    None => (0, None)
  }
}

///|
fn arg_min_max(arg : EngineArg) -> (Int, Int?) {
  match arg.num_args {
    Some(range) => resolve_value_range(range)
    None => (0, None)
  }
}

///|
/// A clap-style argument definition (builder API).
priv struct EngineArg {
  name : String
  short : Char?
  long : String?
  help : String
  long_help : String
  takes_value : Bool
  action : EngineArgAction
  multiple : Bool
  index : Int?
  allow_hyphen_values : Bool
  last : Bool
  env : String?
  default_value : String?
  default_values : Array[String]?
  groups : Array[String]
  requires : Array[String]
  conflicts_with : Array[String]
  required : Bool
  num_args : EngineValueRange?
  aliases : Array[String]
  short_aliases : Array[Char]
  visible_aliases : Array[String]
  visible_short_aliases : Array[Char]
  hidden : Bool
  hide_long_help : Bool
  global : Bool
  negatable : Bool
}

///|
fn EngineArg::new(name : String) -> EngineArg {
  EngineArg::{
    name,
    short: None,
    long: None,
    help: "",
    long_help: "",
    takes_value: false,
    action: EngineArgAction::SetTrue,
    multiple: false,
    index: None,
    allow_hyphen_values: false,
    last: false,
    env: None,
    default_value: None,
    default_values: None,
    groups: [],
    requires: [],
    conflicts_with: [],
    required: false,
    num_args: None,
    aliases: [],
    short_aliases: [],
    visible_aliases: [],
    visible_short_aliases: [],
    hidden: false,
    hide_long_help: false,
    global: false,
    negatable: false,
  }
}

///|
fn EngineArg::flag(self : EngineArg) -> EngineArg {
  EngineArg::{ ..self, takes_value: false, action: EngineArgAction::SetTrue }
}

///|
fn EngineArg::option(self : EngineArg) -> EngineArg {
  EngineArg::{ ..self, takes_value: true, action: EngineArgAction::Set }
}

///|
fn EngineArg::short(self : EngineArg, value : Char) -> EngineArg {
  EngineArg::{ ..self, short: Some(value) }
}

///|
fn EngineArg::long(self : EngineArg, value : String) -> EngineArg {
  EngineArg::{ ..self, long: Some(value) }
}

///|
fn EngineArg::help(self : EngineArg, text : String) -> EngineArg {
  EngineArg::{ ..self, help: text }
}

///|
fn EngineArg::long_help(self : EngineArg, text : String) -> EngineArg {
  EngineArg::{ ..self, long_help: text }
}

///|
fn EngineArg::env(self : EngineArg, name : String) -> EngineArg {
  EngineArg::{ ..self, env: Some(name) }
}

///|
fn EngineArg::default_value(self : EngineArg, value : String) -> EngineArg {
  EngineArg::{ ..self, default_value: Some(value), default_values: None }
}

///|
fn EngineArg::default_values(
  self : EngineArg,
  values : Array[String],
) -> EngineArg {
  EngineArg::{
    ..self,
    default_value: None,
    default_values: Some(clone_array_arg(values)),
  }
}

///|
fn EngineArg::required(self : EngineArg, value? : Bool = true) -> EngineArg {
  EngineArg::{ ..self, required: value }
}

///|
fn EngineArg::num_args(self : EngineArg, range : EngineValueRange) -> EngineArg {
  EngineArg::{ ..self, num_args: Some(range) }
}

///|
fn EngineArg::group(self : EngineArg, name : String) -> EngineArg {
  let groups = clone_array_arg(self.groups)
  groups.push(name)
  EngineArg::{ ..self, groups, }
}

///|
fn EngineArg::requires(self : EngineArg, name : String) -> EngineArg {
  let requires = clone_array_arg(self.requires)
  requires.push(name)
  EngineArg::{ ..self, requires, }
}

///|
fn EngineArg::conflicts_with(self : EngineArg, name : String) -> EngineArg {
  let conflicts_with = clone_array_arg(self.conflicts_with)
  conflicts_with.push(name)
  EngineArg::{ ..self, conflicts_with, }
}

///|
fn EngineArg::multiple(self : EngineArg, value? : Bool = true) -> EngineArg {
  EngineArg::{ ..self, multiple: value }
}

///|
fn EngineArg::index(self : EngineArg, value : Int) -> EngineArg {
  EngineArg::{
    ..self,
    index: Some(value),
    takes_value: true,
    action: EngineArgAction::Set,
  }
}

///|
fn EngineArg::allow_hyphen_values(
  self : EngineArg,
  value? : Bool = true,
) -> EngineArg {
  EngineArg::{ ..self, allow_hyphen_values: value, takes_value: true }
}

///|
fn EngineArg::last(self : EngineArg, value? : Bool = true) -> EngineArg {
  EngineArg::{ ..self, last: value, takes_value: true }
}

///|
fn EngineArg::action(self : EngineArg, value : EngineArgAction) -> EngineArg {
  EngineArg::{ ..self, action: value }
}

///|
fn EngineArg::global(self : EngineArg, value? : Bool = true) -> EngineArg {
  EngineArg::{ ..self, global: value }
}

///|
fn EngineArg::negatable(self : EngineArg, value? : Bool = true) -> EngineArg {
  EngineArg::{ ..self, negatable: value }
}

///|
fn EngineArg::alias_name(self : EngineArg, name : String) -> EngineArg {
  let aliases = clone_array_arg(self.aliases)
  aliases.push(name)
  EngineArg::{ ..self, aliases, }
}

///|
fn EngineArg::short_alias(self : EngineArg, name : Char) -> EngineArg {
  let aliases = clone_array_arg(self.short_aliases)
  aliases.push(name)
  EngineArg::{ ..self, short_aliases: aliases }
}

///|
fn EngineArg::visible_alias(self : EngineArg, name : String) -> EngineArg {
  let aliases = clone_array_arg(self.visible_aliases)
  aliases.push(name)
  EngineArg::{ ..self, visible_aliases: aliases }
}

///|
fn EngineArg::visible_short_alias(self : EngineArg, name : Char) -> EngineArg {
  let aliases = clone_array_arg(self.visible_short_aliases)
  aliases.push(name)
  EngineArg::{ ..self, visible_short_aliases: aliases }
}

///|
fn EngineArg::hide(self : EngineArg, value? : Bool = true) -> EngineArg {
  EngineArg::{ ..self, hidden: value }
}

///|
fn EngineArg::hide_long_help(
  self : EngineArg,
  value? : Bool = true,
) -> EngineArg {
  EngineArg::{ ..self, hide_long_help: value }
}

///|
fn[T] clone_array_arg(arr : Array[T]) -> Array[T] {
  let out = Array::new(capacity=arr.length())
  for value in arr {
    out.push(value)
  }
  out
}
