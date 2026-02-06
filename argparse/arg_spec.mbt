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
pub enum FlagAction {
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
/// Declarative flag specification.
pub struct FlagArg {
  name : String
  short : Char?
  long : String?
  about : String?
  long_about : String?
  action : FlagAction
  env : String?
  default_value : String?
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
pub fn FlagArg::new(
  name : String,
  short? : Char? = None,
  long? : String? = None,
  about? : String? = None,
  long_about? : String? = None,
  action? : FlagAction = FlagAction::SetTrue,
  env? : String? = None,
  default_value? : String? = None,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  group? : String? = None,
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
    name,
    short,
    long,
    about,
    long_about,
    action,
    env,
    default_value,
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
  }
}

///|
/// Declarative option specification.
pub struct OptionArg {
  name : String
  short : Char?
  long : String?
  about : String?
  long_about : String?
  action : OptionAction
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
  aliases : Array[String]
  short_aliases : Array[Char]
  visible_aliases : Array[String]
  visible_short_aliases : Array[Char]
  hidden : Bool
  hide_long_help : Bool
}

///|
pub fn OptionArg::new(
  name : String,
  short? : Char? = None,
  long? : String? = None,
  about? : String? = None,
  long_about? : String? = None,
  action? : OptionAction = OptionAction::Set,
  env? : String? = None,
  default_value? : String? = None,
  default_values? : Array[String]? = None,
  num_args? : ValueRange? = None,
  multiple? : Bool = false,
  allow_hyphen_values? : Bool = false,
  last? : Bool = false,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  group? : String? = None,
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
    name,
    short,
    long,
    about,
    long_about,
    action,
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
    aliases: clone_array_spec(aliases),
    short_aliases: clone_array_spec(short_aliases),
    visible_aliases: clone_array_spec(visible_aliases),
    visible_short_aliases: clone_array_spec(visible_short_aliases),
    hidden,
    hide_long_help,
  }
}

///|
/// Declarative positional specification.
pub struct PositionalArg {
  name : String
  index : Int?
  about : String?
  long_about : String?
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
  hidden : Bool
  hide_long_help : Bool
}

///|
pub fn PositionalArg::new(
  name : String,
  index? : Int? = None,
  about? : String? = None,
  long_about? : String? = None,
  env? : String? = None,
  default_value? : String? = None,
  default_values? : Array[String]? = None,
  num_args? : ValueRange? = None,
  multiple? : Bool = false,
  allow_hyphen_values? : Bool = false,
  last? : Bool = false,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  group? : String? = None,
  required? : Bool = false,
  global? : Bool = false,
  hidden? : Bool = false,
  hide_long_help? : Bool = false,
) -> PositionalArg {
  PositionalArg::{
    name,
    index,
    about,
    long_about,
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
    hidden,
    hide_long_help,
  }
}

///|
/// Sum type for command arg declarations.
pub enum ArgSpec {
  Flag(FlagArg)
  Option(OptionArg)
  Positional(PositionalArg)
}

///|
pub fn ArgSpec::flag(arg : FlagArg) -> ArgSpec {
  Flag(arg)
}

///|
pub fn ArgSpec::option(arg : OptionArg) -> ArgSpec {
  Option(arg)
}

///|
pub fn ArgSpec::positional(arg : PositionalArg) -> ArgSpec {
  Positional(arg)
}

///|
fn arg_name(spec : ArgSpec) -> String {
  match spec {
    Flag(arg) => arg.name
    Option(arg) => arg.name
    Positional(arg) => arg.name
  }
}

///|
fn is_flag_spec(spec : ArgSpec) -> Bool {
  match spec {
    Flag(_) => true
    _ => false
  }
}

///|
fn is_count_flag_spec(spec : ArgSpec) -> Bool {
  match spec {
    Flag(arg) => arg.action == FlagAction::Count
    _ => false
  }
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
