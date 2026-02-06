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
pub(all) enum ArgAction {
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
} derive(Eq, Show)

///|
/// Number-of-values constraint for an argument.
struct ValueRange {
  lower : Int?
  upper : Int?
  lower_inclusive : Bool
  upper_inclusive : Bool
} derive(Eq, Show)

///|
pub fn ValueRange::empty() -> ValueRange {
  ValueRange::{
    lower: Some(0),
    upper: Some(0),
    lower_inclusive: true,
    upper_inclusive: true,
  }
}

///|
pub fn ValueRange::single() -> ValueRange {
  ValueRange::{
    lower: Some(1),
    upper: Some(1),
    lower_inclusive: true,
    upper_inclusive: true,
  }
}

///|
pub fn ValueRange::new(
  lower? : Int? = None,
  upper? : Int? = None,
  lower_inclusive? : Bool = true,
  upper_inclusive? : Bool = true,
) -> ValueRange {
  ValueRange::{ lower, upper, lower_inclusive, upper_inclusive }
}

///|
fn resolve_value_range(range : ValueRange) -> (Int, Int?) {
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
fn validate_value_range(range : ValueRange) -> (Int, Int?) raise ArgBuildError {
  let (min, max) = resolve_value_range(range)
  match max {
    Some(max_value) if max_value < min =>
      raise ArgBuildError::Unsupported("max values must be >= min values")
    _ => ()
  }
  (min, max)
}

///|
fn arg_min_max_for_validate(arg : Arg) -> (Int, Int?) raise ArgBuildError {
  match arg.num_args {
    Some(range) => validate_value_range(range)
    None => (0, None)
  }
}

///|
fn arg_min_max(arg : Arg) -> (Int, Int?) {
  match arg.num_args {
    Some(range) => resolve_value_range(range)
    None => (0, None)
  }
}

///|
/// A clap-style argument definition (builder API).
struct Arg {
  name : String
  short : Char?
  long : String?
  help : String
  long_help : String
  takes_value : Bool
  action : ArgAction
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
  num_args : ValueRange?
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
pub fn Arg::new(name : String) -> Arg {
  Arg::{
    name,
    short: None,
    long: None,
    help: "",
    long_help: "",
    takes_value: false,
    action: ArgAction::SetTrue,
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
pub fn Arg::flag(self : Arg) -> Arg {
  Arg::{ ..self, takes_value: false, action: ArgAction::SetTrue }
}

///|
pub fn Arg::option(self : Arg) -> Arg {
  Arg::{ ..self, takes_value: true, action: ArgAction::Set }
}

///|
pub fn Arg::short(self : Arg, value : Char) -> Arg {
  Arg::{ ..self, short: Some(value) }
}

///|
pub fn Arg::long(self : Arg, value : String) -> Arg {
  Arg::{ ..self, long: Some(value) }
}

///|
pub fn Arg::help(self : Arg, text : String) -> Arg {
  Arg::{ ..self, help: text }
}

///|
pub fn Arg::long_help(self : Arg, text : String) -> Arg {
  Arg::{ ..self, long_help: text }
}

///|
pub fn Arg::env(self : Arg, name : String) -> Arg {
  Arg::{ ..self, env: Some(name) }
}

///|
pub fn Arg::default_value(self : Arg, value : String) -> Arg {
  Arg::{ ..self, default_value: Some(value), default_values: None }
}

///|
pub fn Arg::default_values(self : Arg, values : Array[String]) -> Arg {
  Arg::{
    ..self,
    default_value: None,
    default_values: Some(clone_array_arg(values)),
  }
}

///|
pub fn Arg::required(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, required: value }
}

///|
pub fn Arg::num_args(self : Arg, range : ValueRange) -> Arg {
  Arg::{ ..self, num_args: Some(range) }
}

///|
pub fn Arg::group(self : Arg, name : String) -> Arg {
  let groups = clone_array_arg(self.groups)
  groups.push(name)
  Arg::{ ..self, groups, }
}

///|
pub fn Arg::requires(self : Arg, name : String) -> Arg {
  let requires = clone_array_arg(self.requires)
  requires.push(name)
  Arg::{ ..self, requires, }
}

///|
pub fn Arg::requires_all(self : Arg, names : Array[String]) -> Arg {
  let requires = clone_array_arg(self.requires)
  for name in names {
    requires.push(name)
  }
  Arg::{ ..self, requires, }
}

///|
pub fn Arg::conflicts_with(self : Arg, name : String) -> Arg {
  let conflicts_with = clone_array_arg(self.conflicts_with)
  conflicts_with.push(name)
  Arg::{ ..self, conflicts_with, }
}

///|
pub fn Arg::conflicts_with_all(self : Arg, names : Array[String]) -> Arg {
  let conflicts_with = clone_array_arg(self.conflicts_with)
  for name in names {
    conflicts_with.push(name)
  }
  Arg::{ ..self, conflicts_with, }
}

///|
pub fn Arg::multiple(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, multiple: value }
}

///|
pub fn Arg::index(self : Arg, value : Int) -> Arg {
  Arg::{ ..self, index: Some(value), takes_value: true, action: ArgAction::Set }
}

///|
pub fn Arg::allow_hyphen_values(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, allow_hyphen_values: value, takes_value: true }
}

///|
pub fn Arg::last(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, last: value, takes_value: true }
}

///|
pub fn Arg::action(self : Arg, value : ArgAction) -> Arg {
  Arg::{ ..self, action: value }
}

///|
pub fn Arg::global(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, global: value }
}

///|
pub fn Arg::negatable(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, negatable: value }
}

///|
pub fn Arg::alias_name(self : Arg, name : String) -> Arg {
  let aliases = clone_array_arg(self.aliases)
  aliases.push(name)
  Arg::{ ..self, aliases, }
}

///|
pub fn Arg::short_alias(self : Arg, name : Char) -> Arg {
  let aliases = clone_array_arg(self.short_aliases)
  aliases.push(name)
  Arg::{ ..self, short_aliases: aliases }
}

///|
pub fn Arg::visible_alias(self : Arg, name : String) -> Arg {
  let aliases = clone_array_arg(self.visible_aliases)
  aliases.push(name)
  Arg::{ ..self, visible_aliases: aliases }
}

///|
pub fn Arg::visible_short_alias(self : Arg, name : Char) -> Arg {
  let aliases = clone_array_arg(self.visible_short_aliases)
  aliases.push(name)
  Arg::{ ..self, visible_short_aliases: aliases }
}

///|
pub fn Arg::hide(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, hidden: value }
}

///|
pub fn Arg::hide_long_help(self : Arg, value? : Bool = true) -> Arg {
  Arg::{ ..self, hide_long_help: value }
}

///|
fn[T] clone_array_arg(arr : Array[T]) -> Array[T] {
  let out = Array::new(capacity=arr.length())
  for value in arr {
    out.push(value)
  }
  out
}
