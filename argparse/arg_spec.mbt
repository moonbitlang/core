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
pub(all) enum OptionAction {
  Set
  Append
} derive(Eq, Show)

///|
/// Unified argument model used by the parser internals.
priv struct Arg {
  // All
  name : String
  about : String?
  env : String?
  requires : Array[String]
  conflicts_with : Array[String]
  required : Bool
  global : Bool
  hidden : Bool
  // Flag and Option
  short : Char?
  long : String?
  // Flag
  flag_action : FlagAction
  negatable : Bool
  // Option
  option_action : OptionAction
  // Positional
  index : Int?
  num_args : ValueRange?
  // Option and Positional
  default_values : Array[String]?
  allow_hyphen_values : Bool
  last : Bool
  // other
  is_flag : Bool
  is_positional : Bool
  multiple : Bool
}

///|
/// Trait for declarative arg constructors.
trait ArgLike {
  to_arg(Self) -> Arg
  validate(Self, ValidationCtx) -> Unit raise ArgBuildError
}

///|
/// Declarative flag constructor wrapper.
pub struct FlagArg {
  priv arg : Arg

  /// Create a flag argument.
  fn new(
    name : String,
    short? : Char,
    long? : String,
    about? : String,
    action? : FlagAction,
    env? : String,
    requires? : Array[String],
    conflicts_with? : Array[String],
    required? : Bool,
    global? : Bool,
    negatable? : Bool,
    hidden? : Bool,
  ) -> FlagArg
}

///|
pub impl ArgLike for FlagArg with to_arg(self : FlagArg) {
  self.arg
}

///|
pub impl ArgLike for FlagArg with validate(self, ctx) {
  validate_flag_arg(self.arg, ctx)
}

///|
/// Create a flag argument.
///
/// At least one of `short` or `long` must be provided.
///
/// `global=true` makes the flag available in subcommands.
///
/// If `negatable=true`, `--no-<long>` is accepted for long flags.
pub fn FlagArg::new(
  name : String,
  short? : Char,
  long? : String,
  about? : String,
  action? : FlagAction = FlagAction::SetTrue,
  env? : String,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  required? : Bool = false,
  global? : Bool = false,
  negatable? : Bool = false,
  hidden? : Bool = false,
) -> FlagArg {
  FlagArg::{
    arg: Arg::{
      name,
      about,
      env,
      global,
      hidden,
      requires: requires.copy(),
      conflicts_with: conflicts_with.copy(),
      required,
      //
      short,
      long,
      flag_action: action,
      negatable,
      //
      option_action: OptionAction::Set,
      //
      index: None,
      num_args: None,
      //
      default_values: None,
      allow_hyphen_values: false,
      last: false,
      //
      is_flag: true,
      is_positional: false,
      multiple: false,
    },
  }
}

///|
/// Declarative option constructor wrapper.
pub struct OptionArg {
  priv arg : Arg

  /// Create an option argument.
  fn new(
    name : String,
    short? : Char,
    long? : String,
    about? : String,
    action? : OptionAction,
    env? : String,
    default_values? : Array[String],
    allow_hyphen_values? : Bool,
    last? : Bool,
    requires? : Array[String],
    conflicts_with? : Array[String],
    required? : Bool,
    global? : Bool,
    hidden? : Bool,
  ) -> OptionArg
}

///|
pub impl ArgLike for OptionArg with to_arg(self : OptionArg) {
  self.arg
}

///|
pub impl ArgLike for OptionArg with validate(self, ctx) {
  validate_option_arg(self.arg, ctx)
}

///|
/// Create an option argument that consumes one value per occurrence.
///
/// At least one of `short` or `long` must be provided.
///
/// Use `action=Append` for repeated occurrences.
///
/// `global=true` makes the option available in subcommands.
pub fn OptionArg::new(
  name : String,
  short? : Char,
  long? : String,
  about? : String,
  action? : OptionAction = OptionAction::Set,
  env? : String,
  default_values? : Array[String],
  allow_hyphen_values? : Bool = false,
  last? : Bool = false,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  required? : Bool = false,
  global? : Bool = false,
  hidden? : Bool = false,
) -> OptionArg {
  OptionArg::{
    arg: Arg::{
      name,
      about,
      env,
      requires: requires.copy(),
      conflicts_with: conflicts_with.copy(),
      required,
      global,
      hidden,
      //
      short,
      long,
      //
      flag_action: FlagAction::SetTrue,
      negatable: false,
      //
      option_action: action,
      //
      index: None,
      num_args: None,
      //
      default_values: default_values.map(Array::copy),
      allow_hyphen_values,
      last,
      //
      is_flag: false,
      is_positional: false,
      multiple: allows_multiple_values(action),
    },
  }
}

///|
/// Declarative positional constructor wrapper.
pub struct PositionalArg {
  priv arg : Arg

  /// Create a positional argument.
  fn new(
    name : String,
    index? : Int,
    about? : String,
    env? : String,
    default_values? : Array[String],
    num_args? : ValueRange,
    allow_hyphen_values? : Bool,
    last? : Bool,
    requires? : Array[String],
    conflicts_with? : Array[String],
    required? : Bool,
    global? : Bool,
    hidden? : Bool,
  ) -> PositionalArg
}

///|
pub impl ArgLike for PositionalArg with to_arg(self : PositionalArg) {
  self.arg
}

///|
pub impl ArgLike for PositionalArg with validate(self, ctx) {
  validate_positional_arg(self.arg, ctx)
}

///|
/// Create a positional argument.
///
/// Positional ordering:
/// - `index` is zero-based.
/// - Indexed positionals are sorted by `index`.
/// - Unindexed positionals are appended after indexed ones in declaration order.
///
/// `num_args` controls the accepted value count.
///
/// For indexed positionals that are not the last positional, `num_args` must be
/// omitted or exactly `ValueRange::single()` (`1..1`); other ranges are rejected
/// at build time.
pub fn PositionalArg::new(
  name : String,
  index? : Int,
  about? : String,
  env? : String,
  default_values? : Array[String],
  num_args? : ValueRange,
  allow_hyphen_values? : Bool = false,
  last? : Bool = false,
  requires? : Array[String] = [],
  conflicts_with? : Array[String] = [],
  required? : Bool = false,
  global? : Bool = false,
  hidden? : Bool = false,
) -> PositionalArg {
  PositionalArg::{
    arg: Arg::{
      name,
      about,
      env,
      requires: requires.copy(),
      conflicts_with: conflicts_with.copy(),
      required,
      global,
      hidden,
      //
      short: None,
      long: None,
      //
      flag_action: FlagAction::SetTrue,
      negatable: false,
      //
      option_action: OptionAction::Set,
      //
      index,
      num_args,
      //
      default_values: default_values.map(Array::copy),
      allow_hyphen_values,
      last,
      //
      is_flag: false,
      is_positional: true,
      multiple: range_allows_multiple(num_args),
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
fn allows_multiple_values(action : OptionAction) -> Bool {
  action == OptionAction::Append
}

///|
fn range_allows_multiple(range : ValueRange?) -> Bool {
  match range {
    Some(r) =>
      match r.upper {
        Some(upper) => r.lower != upper || r.lower > 1
        None => true
      }
    None => false
  }
}
