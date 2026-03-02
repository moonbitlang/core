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
///
/// - `SetTrue` / `SetFalse` set a boolean value.
/// - `Count` increments `Matches.flag_counts`.
/// - `Help` / `Version` display output and exit successfully when triggered.
pub(all) enum FlagAction {
  SetTrue
  SetFalse
  Count
  Help
  Version
} derive(Eq, Show)

///|
/// Behavior for option args.
///
/// - `Set` keeps the last provided value.
/// - `Append` keeps all provided values in order.
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
  FlagInfo(
    short~ : Char?,
    long~ : String?,
    action~ : FlagAction,
    negatable~ : Bool
  )
  OptionInfo(
    short~ : Char?,
    long~ : String?,
    action~ : OptionAction,
    default_values~ : Array[String]?,
    allow_hyphen_values~ : Bool
  )
  PositionalInfo(
    num_args~ : ValueRange?,
    default_values~ : Array[String]?,
    allow_hyphen_values~ : Bool
  )
}

///|
/// Declarative flag constructor wrapper.
pub struct Flag {
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
  ) -> Flag
}

///|
/// Create a flag argument.
///
/// Notes:
/// - `long` defaults to `name`.
/// - Use `long=""` to disable the long form.
/// - At least one of `short`, `long`, or `env` must be available.
/// - `global=true` makes the flag available in subcommands.
/// - `negatable=true` accepts `--no-<long>` for long flags.
/// - If `env` is set, accepted boolean values are:
///   `1`, `0`, `true`, `false`, `yes`, `no`, `on`, `off`.
pub fn Flag::new(
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
) -> Flag {
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
      info: FlagInfo(short~, long~, action~, negatable~),
      multiple: false,
    },
  }
}

///|
/// Declarative option constructor wrapper.
pub struct Option {
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
  ) -> Option
}

///|
/// Create an option argument.
///
/// Notes:
/// - `long` defaults to `name`.
/// - Use `long=""` to disable the long form.
/// - At least one of `short`, `long`, or `env` must be available.
/// - Use `action=Append` to keep repeated occurrences.
/// - `global=true` makes the option available in subcommands.
/// - `allow_hyphen_values=true` allows values like `-1` or `--raw` to be
///   consumed as this option's value when parsing argv.
pub fn Option::new(
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
) -> Option {
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
      info: OptionInfo(
        short~,
        long~,
        action~,
        default_values=default_values.map(values => values.to_array()),
        allow_hyphen_values~,
      ),
      multiple: action is Append,
    },
  }
}

///|
/// Declarative positional constructor wrapper.
pub struct Positional {
  priv arg : Arg

  /// Create a positional argument.
  fn new(
    name : StringView,
    about? : StringView,
    env? : StringView,
    default_values? : ArrayView[String],
    num_args? : ValueRange,
    allow_hyphen_values? : Bool,
    requires? : ArrayView[String],
    conflicts_with? : ArrayView[String],
    global? : Bool,
    hidden? : Bool,
  ) -> Positional
}

///|
/// Create a positional argument.
///
/// Notes:
/// - Positional order follows declaration order.
/// - `num_args` controls accepted value count.
/// - If `num_args` is omitted, the default is an optional single value
///   (`0..=1`).
/// - Use `num_args=ValueRange::single()` for a required single positional.
/// - `allow_hyphen_values=true` allows leading-`-` tokens to be consumed as
///   positional values (unless they match a declared option).
/// - Tokens after `--` are always treated as positional values.
pub fn Positional::new(
  name : StringView,
  about? : StringView,
  env? : StringView,
  default_values? : ArrayView[String],
  num_args? : ValueRange,
  allow_hyphen_values? : Bool = false,
  requires? : ArrayView[String] = [],
  conflicts_with? : ArrayView[String] = [],
  global? : Bool = false,
  hidden? : Bool = false,
) -> Positional {
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
      required: false,
      global,
      hidden,
      info: PositionalInfo(
        num_args~,
        default_values=default_values.map(values => values.to_array()),
        allow_hyphen_values~,
      ),
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
  range is Some(r) &&
  (match r.upper {
    Some(upper) => upper > 1
    None => true
  })
}
