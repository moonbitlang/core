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
  info : ArgInfo
  multiple : Bool
}

///|
priv enum ArgInfo {
  Flag(short~ : Char?, long~ : String?, action~ : FlagAction, negatable~ : Bool)
  Option(
    short~ : Char?,
    long~ : String?,
    action~ : OptionAction,
    default_values~ : Array[String]?,
    allow_hyphen_values~ : Bool
  )
  Positional(
    num_args~ : ValueRange?,
    last~ : Bool,
    default_values~ : Array[String]?,
    allow_hyphen_values~ : Bool
  )
}

///|
/// Declarative flag constructor wrapper.
pub struct FlagArg {
  priv arg : Arg

  /// Create a flag argument.
  fn new(
    name : StringView,
    short? : Char,
    long? : StringView,
    about? : StringView,
    action? : FlagAction,
    env? : StringView,
    requires? : ArrayView[String],
    conflicts_with? : ArrayView[String],
    required? : Bool,
    global? : Bool,
    negatable? : Bool,
    hidden? : Bool,
  ) -> FlagArg
}

///|
/// Create a flag argument.
///
/// `long` defaults to `name`.
///
/// Pass `long=""` to disable the long form explicitly.
///
/// At least one of `short` or `long` or `env` must be available.
///
/// `global=true` makes the flag available in subcommands.
///
/// If `negatable=true`, `--no-<long>` is accepted for long flags.
pub fn FlagArg::new(
  name : StringView,
  short? : Char,
  long? : StringView = name,
  about? : StringView,
  action? : FlagAction = SetTrue,
  env? : StringView,
  requires? : ArrayView[String] = [],
  conflicts_with? : ArrayView[String] = [],
  required? : Bool = false,
  global? : Bool = false,
  negatable? : Bool = false,
  hidden? : Bool = false,
) -> FlagArg {
  let name = name.to_string()
  let long = if long == "" { None } else { Some(long.to_string()) }
  let about = about.map(v => v.to_string())
  let env = env.map(v => v.to_string())
  {
    arg: {
      name,
      about,
      env,
      global,
      hidden,
      requires: requires.to_array(),
      conflicts_with: conflicts_with.to_array(),
      required,
      //
      info: Flag(short~, long~, action~, negatable~),
      //
      // option_action: OptionAction::Set,
      //
      // index: None,
      // num_args: None,
      //
      // default_values: None,
      // allow_hyphen_values: false,
      // last: false,
      //
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
    name : StringView,
    short? : Char,
    long? : StringView,
    about? : StringView,
    action? : OptionAction,
    env? : StringView,
    default_values? : ArrayView[String],
    allow_hyphen_values? : Bool,
    requires? : ArrayView[String],
    conflicts_with? : ArrayView[String],
    required? : Bool,
    global? : Bool,
    hidden? : Bool,
  ) -> OptionArg
}

///|
/// Create an option argument that consumes one value per occurrence.
///
/// `long` defaults to `name`.
///
/// Pass `long=""` to disable the long form explicitly.
///
/// At least one of `short` or `long` or `env` must be available.
///
/// Use `action=Append` for repeated occurrences.
///
/// `global=true` makes the option available in subcommands.
pub fn OptionArg::new(
  name : StringView,
  short? : Char,
  long? : StringView = name,
  about? : StringView,
  action? : OptionAction = Set,
  env? : StringView,
  default_values? : ArrayView[String],
  allow_hyphen_values? : Bool = false,
  requires? : ArrayView[String] = [],
  conflicts_with? : ArrayView[String] = [],
  required? : Bool = false,
  global? : Bool = false,
  hidden? : Bool = false,
) -> OptionArg {
  let name = name.to_string()
  let long = if long == "" { None } else { Some(long.to_string()) }
  let about = about.map(v => v.to_string())
  let env = env.map(v => v.to_string())
  {
    arg: {
      name,
      about,
      env,
      requires: requires.to_array(),
      conflicts_with: conflicts_with.to_array(),
      required,
      global,
      hidden,
      //
      info: Option(
        short~,
        long~,
        action~,
        default_values=default_values.map(values => values.to_array()),
        allow_hyphen_values~,
      ),
      //
      // flag_action: FlagAction::SetTrue,
      // negatable: false,
      //
      // option_action: action,
      //
      // index: None,
      // num_args: None,
      //
      multiple: action is Append,
    },
  }
}

///|
/// Declarative positional constructor wrapper.
pub struct PositionalArg {
  priv arg : Arg

  /// Create a positional argument.
  fn new(
    name : StringView,
    about? : StringView,
    env? : StringView,
    default_values? : ArrayView[String],
    num_args? : ValueRange,
    allow_hyphen_values? : Bool,
    last? : Bool,
    requires? : ArrayView[String],
    conflicts_with? : ArrayView[String],
    required? : Bool,
    global? : Bool,
    hidden? : Bool,
  ) -> PositionalArg
}

///|
/// Create a positional argument.
///
/// Positional ordering is declaration order.
///
/// `num_args` controls the accepted value count.
pub fn PositionalArg::new(
  name : StringView,
  about? : StringView,
  env? : StringView,
  default_values? : ArrayView[String],
  num_args? : ValueRange,
  allow_hyphen_values? : Bool = false,
  last? : Bool = false,
  requires? : ArrayView[String] = [],
  conflicts_with? : ArrayView[String] = [],
  required? : Bool = false,
  global? : Bool = false,
  hidden? : Bool = false,
) -> PositionalArg {
  let name = name.to_string()
  let about = about.map(v => v.to_string())
  let env = env.map(v => v.to_string())
  {
    arg: {
      name,
      about,
      env,
      requires: requires.to_array(),
      conflicts_with: conflicts_with.to_array(),
      required,
      global,
      hidden,
      //
      info: Positional(
        num_args~,
        last~,
        default_values=default_values.map(values => values.to_array()),
        allow_hyphen_values~,
      ),
      // short: None,
      // long: None,
      //
      // flag_action: FlagAction::SetTrue,
      // negatable: false,
      //
      // option_action: OptionAction::Set,
      //
      multiple: range_allows_multiple(num_args),
    },
  }
}

///|
fn arg_name(arg : Arg) -> String {
  arg.name
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
