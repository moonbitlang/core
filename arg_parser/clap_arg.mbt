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
} derive(Eq, Show)

///|
/// A clap-style argument definition (builder API).
struct Arg {
  name : String
  short : Char?
  long : String?
  help : String
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
  required : Bool
  min_values : Int?
  max_values : Int?
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
    required: false,
    min_values: None,
    max_values: None,
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
pub fn Arg::min_values(self : Arg, value : Int) -> Arg {
  Arg::{ ..self, min_values: Some(value) }
}

///|
pub fn Arg::max_values(self : Arg, value : Int) -> Arg {
  Arg::{ ..self, max_values: Some(value) }
}

///|
pub fn Arg::num_values(self : Arg, min : Int, max : Int) -> Arg {
  Arg::{ ..self, min_values: Some(min), max_values: Some(max) }
}

///|
pub fn Arg::group(self : Arg, name : String) -> Arg {
  let groups = clone_array_arg(self.groups)
  groups.push(name)
  Arg::{ ..self, groups, }
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
