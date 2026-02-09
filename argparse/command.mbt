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
/// Declarative command specification.
pub struct Command {
  priv name : String
  priv args : Array[Arg]
  priv subcommands : Array[Command]
  priv about : String?
  priv long_about : String?
  priv version : String?
  priv long_version : String?
  priv aliases : Array[String]
  priv visible_aliases : Array[String]
  priv disable_help_flag : Bool
  priv disable_version_flag : Bool
  priv disable_help_subcommand : Bool
  priv arg_required_else_help : Bool
  priv subcommand_required : Bool
  priv hidden : Bool

  fn new(
    name : String,
    args? : Array[&ArgLike],
    subcommands? : Array[Command],
    about? : String,
    long_about? : String,
    version? : String,
    long_version? : String,
    aliases? : Array[String],
    visible_aliases? : Array[String],
    disable_help_flag? : Bool,
    disable_version_flag? : Bool,
    disable_help_subcommand? : Bool,
    arg_required_else_help? : Bool,
    subcommand_required? : Bool,
    hidden? : Bool,
  ) -> Command
}

///|
pub fn Command::new(
  name : String,
  args? : Array[&ArgLike] = [],
  subcommands? : Array[Command] = [],
  about? : String,
  long_about? : String,
  version? : String,
  long_version? : String,
  aliases? : Array[String] = [],
  visible_aliases? : Array[String] = [],
  disable_help_flag? : Bool = false,
  disable_version_flag? : Bool = false,
  disable_help_subcommand? : Bool = false,
  arg_required_else_help? : Bool = false,
  subcommand_required? : Bool = false,
  hidden? : Bool = false,
) -> Command {
  Command::{
    name,
    args: normalize_args(args),
    subcommands: clone_array_cmd(subcommands),
    about,
    long_about,
    version,
    long_version,
    aliases: clone_array_cmd(aliases),
    visible_aliases: clone_array_cmd(visible_aliases),
    disable_help_flag,
    disable_version_flag,
    disable_help_subcommand,
    arg_required_else_help,
    subcommand_required,
    hidden,
  }
}

///|
fn normalize_args(args : Array[&ArgLike]) -> Array[Arg] {
  let out = Array::new(capacity=args.length())
  for arg in args {
    out.push(arg.to_arg())
  }
  out
}

///|
/// Render short help text without parsing.
pub fn Command::render_help(self : Command) -> String {
  render_help_short(self)
}

///|
/// Render long help text without parsing.
pub fn Command::render_long_help(self : Command) -> String {
  render_help_long(self)
}

///|
/// Parse argv/environment according to this command spec.
pub fn Command::parse(
  self : Command,
  argv? : Array[String] = default_argv(),
  env? : Map[String, String] = {},
) -> Matches raise {
  let raw = parse_command(self, argv, env, [])
  build_matches(self, raw)
}

///|
fn build_matches(cmd : Command, raw : EngineMatches) -> Matches {
  let flags : Map[String, Bool] = {}
  let values : Map[String, Array[String]] = {}
  let counts : Map[String, Int] = {}
  let value_sources : Map[String, ValueSource] = {}

  for spec in cmd.args {
    let name = arg_name(spec)
    match raw.get_many(name) {
      Some(vs) => values[name] = clone_array_cmd(vs)
      None => ()
    }
    let count = raw.count_of(name)
    if count > 0 {
      counts[name] = count
    }
    match raw.value_source(name) {
      Some(source) => {
        value_sources[name] = convert_source(source)
        if is_flag_spec(spec) {
          if is_count_flag_spec(spec) {
            flags[name] = count > 0
          } else {
            flags[name] = raw.get_flag(name)
          }
        }
      }
      None => ()
    }
  }

  let subcommand = match raw.subcommand() {
    Some((name, sub_raw)) =>
      match find_decl_subcommand(cmd.subcommands, name) {
        Some(sub_spec) => Some((name, build_matches(sub_spec, sub_raw)))
        None => Some((name, Matches::new()))
      }
    None => None
  }

  Matches::{ flags, values, counts, value_sources, subcommand }
}

///|
fn find_decl_subcommand(subs : Array[Command], name : String) -> Command? {
  for sub in subs {
    if sub.name == name {
      return Some(sub)
    }
    if sub.aliases.contains(name) || sub.visible_aliases.contains(name) {
      return Some(sub)
    }
  }
  None
}

///|
fn convert_source(source : EngineValueSource) -> ValueSource {
  match source {
    EngineValueSource::Argv => ValueSource::Argv
    EngineValueSource::Env => ValueSource::Env
    EngineValueSource::Default => ValueSource::Default
  }
}

///|
fn command_engine_args(cmd : Command) -> Array[EngineArg] {
  let args = Array::new(capacity=cmd.args.length())
  for spec in cmd.args {
    args.push(to_engine_arg(spec))
  }
  args
}

///|
fn command_engine_groups(cmd : Command) -> Array[EngineArgGroup] {
  collect_implicit_groups(cmd.args)
}

///|
fn collect_implicit_groups(specs : Array[Arg]) -> Array[EngineArgGroup] {
  let group_names : Array[String] = []
  let group_members : Array[Array[String]] = []

  for spec in specs {
    match spec.group {
      Some(group_name) => {
        let mut idx : Int? = None
        for i = 0; i < group_names.length(); i = i + 1 {
          if group_names[i] == group_name {
            idx = Some(i)
            break
          }
        }
        match idx {
          Some(i) => group_members[i].push(arg_name(spec))
          None => {
            group_names.push(group_name)
            group_members.push([arg_name(spec)])
          }
        }
      }
      None => ()
    }
  }

  let out = Array::new(capacity=group_names.length())
  for i = 0; i < group_names.length(); i = i + 1 {
    out.push(EngineArgGroup::{
      name: group_names[i],
      required: false,
      multiple: true,
      args: clone_array_cmd(group_members[i]),
      requires: [],
      conflicts_with: [],
    })
  }
  out
}

///|
fn to_engine_arg(arg : Arg) -> EngineArg {
  if arg.is_flag {
    let mut out = EngineArg::new(arg.name).flag()
    match arg.short {
      Some(v) => out = out.short(v)
      None => ()
    }
    match arg.long {
      Some(v) => out = out.long(v)
      None => ()
    }
    match arg.about {
      Some(v) => out = out.help(v)
      None => ()
    }
    match arg.long_about {
      Some(v) => out = out.long_help(v)
      None => ()
    }
    match arg.env {
      Some(v) => out = out.env(v)
      None => ()
    }
    match arg.default_value {
      Some(v) => out = out.default_value(v)
      None => ()
    }
    match arg.group {
      Some(group) => out = out.group(group)
      None => ()
    }
    out = out.action(convert_flag_action(arg.flag_action))
    for name in arg.requires {
      out = out.requires(name)
    }
    for name in arg.conflicts_with {
      out = out.conflicts_with(name)
    }
    for name in arg.aliases {
      out = out.alias_name(name)
    }
    for name in arg.short_aliases {
      out = out.short_alias(name)
    }
    for name in arg.visible_aliases {
      out = out.visible_alias(name)
    }
    for name in arg.visible_short_aliases {
      out = out.visible_short_alias(name)
    }
    if arg.required {
      out = out.required()
    }
    if arg.global {
      out = out.global()
    }
    if arg.negatable {
      out = out.negatable()
    }
    if arg.hidden {
      out = out.hide()
    }
    if arg.hide_long_help {
      out = out.hide_long_help()
    }
    out
  } else if arg.is_positional {
    let mut out = EngineArg::new(arg.name).option()
    match arg.index {
      Some(v) => out = out.index(v)
      None => ()
    }
    match arg.about {
      Some(v) => out = out.help(v)
      None => ()
    }
    match arg.long_about {
      Some(v) => out = out.long_help(v)
      None => ()
    }
    match arg.env {
      Some(v) => out = out.env(v)
      None => ()
    }
    match arg.default_value {
      Some(v) => out = out.default_value(v)
      None => ()
    }
    match arg.default_values {
      Some(vs) => out = out.default_values(vs)
      None => ()
    }
    match arg.num_args {
      Some(range) => out = out.num_args(convert_value_range(range))
      None => ()
    }
    match arg.group {
      Some(group) => out = out.group(group)
      None => ()
    }
    for name in arg.requires {
      out = out.requires(name)
    }
    for name in arg.conflicts_with {
      out = out.conflicts_with(name)
    }
    if arg.multiple {
      out = out.multiple()
    }
    if arg.allow_hyphen_values {
      out = out.allow_hyphen_values()
    }
    if arg.last {
      out = out.last()
    }
    if arg.required {
      out = out.required()
    }
    if arg.global {
      out = out.global()
    }
    if arg.hidden {
      out = out.hide()
    }
    if arg.hide_long_help {
      out = out.hide_long_help()
    }
    out
  } else {
    let mut out = EngineArg::new(arg.name).option()
    match arg.short {
      Some(v) => out = out.short(v)
      None => ()
    }
    match arg.long {
      Some(v) => out = out.long(v)
      None => ()
    }
    match arg.about {
      Some(v) => out = out.help(v)
      None => ()
    }
    match arg.long_about {
      Some(v) => out = out.long_help(v)
      None => ()
    }
    match arg.env {
      Some(v) => out = out.env(v)
      None => ()
    }
    match arg.default_value {
      Some(v) => out = out.default_value(v)
      None => ()
    }
    match arg.default_values {
      Some(vs) => out = out.default_values(vs)
      None => ()
    }
    match arg.num_args {
      Some(range) => out = out.num_args(convert_value_range(range))
      None => ()
    }
    match arg.group {
      Some(group) => out = out.group(group)
      None => ()
    }
    out = out.action(convert_option_action(arg.option_action))
    for name in arg.requires {
      out = out.requires(name)
    }
    for name in arg.conflicts_with {
      out = out.conflicts_with(name)
    }
    for name in arg.aliases {
      out = out.alias_name(name)
    }
    for name in arg.short_aliases {
      out = out.short_alias(name)
    }
    for name in arg.visible_aliases {
      out = out.visible_alias(name)
    }
    for name in arg.visible_short_aliases {
      out = out.visible_short_alias(name)
    }
    if arg.multiple {
      out = out.multiple()
    }
    if arg.allow_hyphen_values {
      out = out.allow_hyphen_values()
    }
    if arg.last {
      out = out.last()
    }
    if arg.required {
      out = out.required()
    }
    if arg.global {
      out = out.global()
    }
    if arg.hidden {
      out = out.hide()
    }
    if arg.hide_long_help {
      out = out.hide_long_help()
    }
    out
  }
}

///|
fn convert_value_range(range : ValueRange) -> EngineValueRange {
  EngineValueRange::new(
    lower=range.lower,
    upper=range.upper,
    lower_inclusive=range.lower_inclusive,
    upper_inclusive=range.upper_inclusive,
  )
}

///|
fn convert_flag_action(action : FlagAction) -> EngineArgAction {
  match action {
    FlagAction::SetTrue => EngineArgAction::SetTrue
    FlagAction::SetFalse => EngineArgAction::SetFalse
    FlagAction::Count => EngineArgAction::Count
    FlagAction::Help => EngineArgAction::Help
    FlagAction::Version => EngineArgAction::Version
  }
}

///|
fn convert_option_action(action : OptionAction) -> EngineArgAction {
  match action {
    OptionAction::Set => EngineArgAction::Set
    OptionAction::Append => EngineArgAction::Append
  }
}

///|
fn[T] clone_array_cmd(arr : Array[T]) -> Array[T] {
  let out = Array::new(capacity=arr.length())
  for value in arr {
    out.push(value)
  }
  out
}
