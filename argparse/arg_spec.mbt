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
/// Behavior for flag args.
pub(all) enum FlagAction {
  SetTrue
  SetFalse
  Count
  Help
  Version
} derive(Eq, Show)

///|
/// Behavior for option args.
pub enum OptionAction {
  Set
  Append
} derive(Eq, Show)

///|
/// Unified argument model used by the parser internals.
priv struct Arg {
  name : String
  short : Char?
  long : String?
  index : Int?
  about : String?
  long_about : String?
  is_flag : Bool
  is_positional : Bool
  flag_action : FlagAction
  option_action : OptionAction
  env : String?
  default_value : String?
  default_values : Array[String]?
  num_args : ValueRange?
  multiple : Bool
  allow_hyphen_values : Bool
  last : Bool
  requires : Array[String]
  conflicts_with : Array[String]
  group : String?
  required : Bool
  global : Bool
  negatable : Bool
  aliases : Array[String]
  short_aliases : Array[Char]
  visible_aliases : Array[String]
  visible_short_aliases : Array[Char]
  hidden : Bool
  hide_long_help : Bool
}

///|
/// Trait for declarative arg constructors.
trait ArgLike {
  to_arg(Self) -> Arg
}

///|
/// Declarative flag constructor wrapper.
pub struct FlagArg {
  priv arg : Arg

  fn new(
    name : String,
    short? : Char,
    long? : String,
    about? : String,
    long_about? : String,
    action? : FlagAction,
    env? : String,
    default_value? : String,
    requires? : Array[String],
    conflicts_with? : Array[String],
    group? : String,
    required? : Bool,
    global? : Bool,
    negatable? : Bool,
    aliases? : Array[String],
    short_aliases? : Array[Char],
    visible_aliases? : Array[String],
    visible_short_aliases? : Array[Char],
    hidden? : Bool,
    hide_long_help? : Bool,
  ) -> FlagArg
}

///|
pub impl ArgLike for FlagArg with to_arg(self : FlagArg) {
  self.arg
}

///|
pub fn FlagArg::new(
  name : String,
  short? : Char,
  long? : String,
  about? : String,
  long_about? : String,
  action? : FlagAction = FlagAction::SetTrue,
  env? : String,
  default_value? : String,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  group? : String,
  required? : Bool = false,
  global? : Bool = false,
  negatable? : Bool = false,
  aliases? : Array[String] = [],
  short_aliases? : Array[Char] = [],
  visible_aliases? : Array[String] = [],
  visible_short_aliases? : Array[Char] = [],
  hidden? : Bool = false,
  hide_long_help? : Bool = false,
) -> FlagArg {
  FlagArg::{
    arg: Arg::{
      name,
      short,
      long,
      index: None,
      about,
      long_about,
      is_flag: true,
      is_positional: false,
      flag_action: action,
      option_action: OptionAction::Set,
      env,
      default_value,
      default_values: None,
      num_args: None,
      multiple: false,
      allow_hyphen_values: false,
      last: false,
      requires: clone_array_spec(requires),
      conflicts_with: clone_array_spec(conflicts_with),
      group,
      required,
      global,
      negatable,
      aliases: clone_array_spec(aliases),
      short_aliases: clone_array_spec(short_aliases),
      visible_aliases: clone_array_spec(visible_aliases),
      visible_short_aliases: clone_array_spec(visible_short_aliases),
      hidden,
      hide_long_help,
    },
  }
}

///|
/// Declarative option constructor wrapper.
pub struct OptionArg {
  priv arg : Arg

  fn new(
    name : String,
    short? : Char,
    long? : String,
    about? : String,
    long_about? : String,
    action? : OptionAction,
    env? : String,
    default_value? : String,
    default_values? : Array[String],
    num_args? : ValueRange,
    multiple? : Bool,
    allow_hyphen_values? : Bool,
    last? : Bool,
    requires? : Array[String],
    conflicts_with? : Array[String],
    group? : String,
    required? : Bool,
    global? : Bool,
    aliases? : Array[String],
    short_aliases? : Array[Char],
    visible_aliases? : Array[String],
    visible_short_aliases? : Array[Char],
    hidden? : Bool,
    hide_long_help? : Bool,
  ) -> OptionArg
}

///|
pub impl ArgLike for OptionArg with to_arg(self : OptionArg) {
  self.arg
}

///|
pub fn OptionArg::new(
  name : String,
  short? : Char,
  long? : String,
  about? : String,
  long_about? : String,
  action? : OptionAction = OptionAction::Set,
  env? : String,
  default_value? : String,
  default_values? : Array[String],
  num_args? : ValueRange,
  multiple? : Bool = false,
  allow_hyphen_values? : Bool = false,
  last? : Bool = false,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  group? : String,
  required? : Bool = false,
  global? : Bool = false,
  aliases? : Array[String] = [],
  short_aliases? : Array[Char] = [],
  visible_aliases? : Array[String] = [],
  visible_short_aliases? : Array[Char] = [],
  hidden? : Bool = false,
  hide_long_help? : Bool = false,
) -> OptionArg {
  OptionArg::{
    arg: Arg::{
      name,
      short,
      long,
      index: None,
      about,
      long_about,
      is_flag: false,
      is_positional: false,
      flag_action: FlagAction::SetTrue,
      option_action: action,
      env,
      default_value,
      default_values: clone_optional_array_string(default_values),
      num_args,
      multiple,
      allow_hyphen_values,
      last,
      requires: clone_array_spec(requires),
      conflicts_with: clone_array_spec(conflicts_with),
      group,
      required,
      global,
      negatable: false,
      aliases: clone_array_spec(aliases),
      short_aliases: clone_array_spec(short_aliases),
      visible_aliases: clone_array_spec(visible_aliases),
      visible_short_aliases: clone_array_spec(visible_short_aliases),
      hidden,
      hide_long_help,
    },
  }
}

///|
/// Declarative positional constructor wrapper.
pub struct PositionalArg {
  priv arg : Arg

  fn new(
    name : String,
    index? : Int,
    about? : String,
    long_about? : String,
    env? : String,
    default_value? : String,
    default_values? : Array[String],
    num_args? : ValueRange,
    multiple? : Bool,
    allow_hyphen_values? : Bool,
    last? : Bool,
    requires? : Array[String],
    conflicts_with? : Array[String],
    group? : String,
    required? : Bool,
    global? : Bool,
    hidden? : Bool,
    hide_long_help? : Bool,
  ) -> PositionalArg
}

///|
pub impl ArgLike for PositionalArg with to_arg(self : PositionalArg) {
  self.arg
}

///|
pub fn PositionalArg::new(
  name : String,
  index? : Int,
  about? : String,
  long_about? : String,
  env? : String,
  default_value? : String,
  default_values? : Array[String],
  num_args? : ValueRange,
  multiple? : Bool = false,
  allow_hyphen_values? : Bool = false,
  last? : Bool = false,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  group? : String,
  required? : Bool = false,
  global? : Bool = false,
  hidden? : Bool = false,
  hide_long_help? : Bool = false,
) -> PositionalArg {
  PositionalArg::{
    arg: Arg::{
      name,
      short: None,
      long: None,
      index,
      about,
      long_about,
      is_flag: false,
      is_positional: true,
      flag_action: FlagAction::SetTrue,
      option_action: OptionAction::Set,
      env,
      default_value,
      default_values: clone_optional_array_string(default_values),
      num_args,
      multiple,
      allow_hyphen_values,
      last,
      requires: clone_array_spec(requires),
      conflicts_with: clone_array_spec(conflicts_with),
      group,
      required,
      global,
      negatable: false,
      aliases: [],
      short_aliases: [],
      visible_aliases: [],
      visible_short_aliases: [],
      hidden,
      hide_long_help,
    },
  }
}

///|
fn arg_name(arg : Arg) -> String {
  arg.name
}

///|
fn is_flag_spec(arg : Arg) -> Bool {
  arg.is_flag
}

///|
fn is_count_flag_spec(arg : Arg) -> Bool {
  arg.is_flag && arg.flag_action == FlagAction::Count
}

///|
fn[T] clone_array_spec(arr : Array[T]) -> Array[T] {
  let out = Array::new(capacity=arr.length())
  for value in arr {
    out.push(value)
  }
  out
}

///|
fn clone_optional_array_string(values : Array[String]?) -> Array[String]? {
  match values {
    Some(arr) => Some(clone_array_spec(arr))
    None => None
  }
}
