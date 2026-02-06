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
  name : String
  args : Array[ArgSpec]
  subcommands : Array[Command]
  about : String?
  long_about : String?
  version : String?
  long_version : String?
  aliases : Array[String]
  visible_aliases : Array[String]
  disable_help_flag : Bool
  disable_version_flag : Bool
  disable_help_subcommand : Bool
  arg_required_else_help : Bool
  subcommand_required : Bool
  hidden : Bool

  fn new(
    name : String,
    args? : Array[ArgSpec],
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
  args? : Array[ArgSpec] = [],
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
    args: clone_array_cmd(args),
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
/// Render short help text without parsing.
pub fn Command::render_help(self : Command) -> String {
  to_engine_command(self).render_help()
}

///|
/// Render long help text without parsing.
pub fn Command::render_long_help(self : Command) -> String {
  to_engine_command(self).render_long_help()
}

///|
/// Parse argv/environment according to this command spec.
pub fn Command::parse(
  self : Command,
  argv? : Array[String],
  env? : Map[String, String],
) -> Matches raise {
  let raw = match (argv, env) {
    (Some(actual_argv), Some(actual_env)) =>
      to_engine_command(self).parse(argv=actual_argv, env=actual_env) catch {
        EngineDisplayHelp::Short(text) => raise DisplayHelp::Short(text)
        EngineDisplayHelp::Long(text) => raise DisplayHelp::Long(text)
        EngineDisplayVersion::Short(text) => raise DisplayVersion::Short(text)
        EngineDisplayVersion::Long(text) => raise DisplayVersion::Long(text)
        EngineArgumentError::UnknownArgument(arg, hint) =>
          raise ArgumentError::UnknownArgument(arg, hint)
        EngineArgumentError::InvalidArgument(msg) =>
          raise ArgumentError::InvalidArgument(msg)
        EngineArgumentError::MissingValue(msg) =>
          raise ArgumentError::MissingValue(msg)
        EngineArgumentError::MissingRequired(name) =>
          raise ArgumentError::MissingRequired(name)
        EngineArgumentError::TooFewValues(name, got, min) =>
          raise ArgumentError::TooFewValues(name, got, min)
        EngineArgumentError::TooManyValues(name, got, max) =>
          raise ArgumentError::TooManyValues(name, got, max)
        EngineArgumentError::TooManyPositionals =>
          raise ArgumentError::TooManyPositionals
        EngineArgumentError::InvalidValue(msg) =>
          raise ArgumentError::InvalidValue(msg)
        EngineArgumentError::MissingGroup(name) =>
          raise ArgumentError::MissingGroup(name)
        EngineArgumentError::GroupConflict(name) =>
          raise ArgumentError::GroupConflict(name)
        EngineArgBuildError::Unsupported(msg) =>
          raise ArgBuildError::Unsupported(msg)
        _ => panic()
      }
    (Some(actual_argv), None) =>
      to_engine_command(self).parse(argv=actual_argv) catch {
        EngineDisplayHelp::Short(text) => raise DisplayHelp::Short(text)
        EngineDisplayHelp::Long(text) => raise DisplayHelp::Long(text)
        EngineDisplayVersion::Short(text) => raise DisplayVersion::Short(text)
        EngineDisplayVersion::Long(text) => raise DisplayVersion::Long(text)
        EngineArgumentError::UnknownArgument(arg, hint) =>
          raise ArgumentError::UnknownArgument(arg, hint)
        EngineArgumentError::InvalidArgument(msg) =>
          raise ArgumentError::InvalidArgument(msg)
        EngineArgumentError::MissingValue(msg) =>
          raise ArgumentError::MissingValue(msg)
        EngineArgumentError::MissingRequired(name) =>
          raise ArgumentError::MissingRequired(name)
        EngineArgumentError::TooFewValues(name, got, min) =>
          raise ArgumentError::TooFewValues(name, got, min)
        EngineArgumentError::TooManyValues(name, got, max) =>
          raise ArgumentError::TooManyValues(name, got, max)
        EngineArgumentError::TooManyPositionals =>
          raise ArgumentError::TooManyPositionals
        EngineArgumentError::InvalidValue(msg) =>
          raise ArgumentError::InvalidValue(msg)
        EngineArgumentError::MissingGroup(name) =>
          raise ArgumentError::MissingGroup(name)
        EngineArgumentError::GroupConflict(name) =>
          raise ArgumentError::GroupConflict(name)
        EngineArgBuildError::Unsupported(msg) =>
          raise ArgBuildError::Unsupported(msg)
        _ => panic()
      }
    (None, Some(actual_env)) =>
      to_engine_command(self).parse(env=actual_env) catch {
        EngineDisplayHelp::Short(text) => raise DisplayHelp::Short(text)
        EngineDisplayHelp::Long(text) => raise DisplayHelp::Long(text)
        EngineDisplayVersion::Short(text) => raise DisplayVersion::Short(text)
        EngineDisplayVersion::Long(text) => raise DisplayVersion::Long(text)
        EngineArgumentError::UnknownArgument(arg, hint) =>
          raise ArgumentError::UnknownArgument(arg, hint)
        EngineArgumentError::InvalidArgument(msg) =>
          raise ArgumentError::InvalidArgument(msg)
        EngineArgumentError::MissingValue(msg) =>
          raise ArgumentError::MissingValue(msg)
        EngineArgumentError::MissingRequired(name) =>
          raise ArgumentError::MissingRequired(name)
        EngineArgumentError::TooFewValues(name, got, min) =>
          raise ArgumentError::TooFewValues(name, got, min)
        EngineArgumentError::TooManyValues(name, got, max) =>
          raise ArgumentError::TooManyValues(name, got, max)
        EngineArgumentError::TooManyPositionals =>
          raise ArgumentError::TooManyPositionals
        EngineArgumentError::InvalidValue(msg) =>
          raise ArgumentError::InvalidValue(msg)
        EngineArgumentError::MissingGroup(name) =>
          raise ArgumentError::MissingGroup(name)
        EngineArgumentError::GroupConflict(name) =>
          raise ArgumentError::GroupConflict(name)
        EngineArgBuildError::Unsupported(msg) =>
          raise ArgBuildError::Unsupported(msg)
        _ => panic()
      }
    (None, None) =>
      to_engine_command(self).parse() catch {
        EngineDisplayHelp::Short(text) => raise DisplayHelp::Short(text)
        EngineDisplayHelp::Long(text) => raise DisplayHelp::Long(text)
        EngineDisplayVersion::Short(text) => raise DisplayVersion::Short(text)
        EngineDisplayVersion::Long(text) => raise DisplayVersion::Long(text)
        EngineArgumentError::UnknownArgument(arg, hint) =>
          raise ArgumentError::UnknownArgument(arg, hint)
        EngineArgumentError::InvalidArgument(msg) =>
          raise ArgumentError::InvalidArgument(msg)
        EngineArgumentError::MissingValue(msg) =>
          raise ArgumentError::MissingValue(msg)
        EngineArgumentError::MissingRequired(name) =>
          raise ArgumentError::MissingRequired(name)
        EngineArgumentError::TooFewValues(name, got, min) =>
          raise ArgumentError::TooFewValues(name, got, min)
        EngineArgumentError::TooManyValues(name, got, max) =>
          raise ArgumentError::TooManyValues(name, got, max)
        EngineArgumentError::TooManyPositionals =>
          raise ArgumentError::TooManyPositionals
        EngineArgumentError::InvalidValue(msg) =>
          raise ArgumentError::InvalidValue(msg)
        EngineArgumentError::MissingGroup(name) =>
          raise ArgumentError::MissingGroup(name)
        EngineArgumentError::GroupConflict(name) =>
          raise ArgumentError::GroupConflict(name)
        EngineArgBuildError::Unsupported(msg) =>
          raise ArgBuildError::Unsupported(msg)
        _ => panic()
      }
  }
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
fn to_engine_command(cmd : Command) -> EngineCommand {
  let mut out = EngineCommand::new(cmd.name)

  match cmd.about {
    Some(text) => out = out.about(text)
    None => ()
  }
  match cmd.long_about {
    Some(text) => out = out.long_about(text)
    None => ()
  }
  match cmd.version {
    Some(text) => out = out.version(text)
    None => ()
  }
  match cmd.long_version {
    Some(text) => out = out.long_version(text)
    None => ()
  }
  for alias_name in cmd.aliases {
    out = out.alias_name(alias_name)
  }
  for visible_alias_name in cmd.visible_aliases {
    out = out.visible_alias(visible_alias_name)
  }

  if cmd.hidden {
    out = out.hide()
  }
  if cmd.disable_help_flag {
    out = out.disable_help_flag()
  }
  if cmd.disable_version_flag {
    out = out.disable_version_flag()
  }
  if cmd.disable_help_subcommand {
    out = out.disable_help_subcommand()
  }
  if cmd.arg_required_else_help {
    out = out.arg_required_else_help()
  }
  if cmd.subcommand_required {
    out = out.subcommand_required()
  }

  for spec in cmd.args {
    out = out.arg(to_engine_arg(spec))
  }
  for sub in cmd.subcommands {
    out = out.subcommand(to_engine_command(sub))
  }
  out
}

///|
fn to_engine_arg(spec : ArgSpec) -> EngineArg {
  match spec {
    Flag(flag) => {
      let mut out = EngineArg::new(flag.name).flag()
      match flag.short {
        Some(v) => out = out.short(v)
        None => ()
      }
      match flag.long {
        Some(v) => out = out.long(v)
        None => ()
      }
      match flag.about {
        Some(v) => out = out.help(v)
        None => ()
      }
      match flag.long_about {
        Some(v) => out = out.long_help(v)
        None => ()
      }
      match flag.env {
        Some(v) => out = out.env(v)
        None => ()
      }
      match flag.default_value {
        Some(v) => out = out.default_value(v)
        None => ()
      }
      match flag.group {
        Some(group) => out = out.group(group)
        None => ()
      }
      out = out.action(convert_flag_action(flag.action))
      for name in flag.requires {
        out = out.requires(name)
      }
      for name in flag.conflicts_with {
        out = out.conflicts_with(name)
      }
      for name in flag.aliases {
        out = out.alias_name(name)
      }
      for name in flag.short_aliases {
        out = out.short_alias(name)
      }
      for name in flag.visible_aliases {
        out = out.visible_alias(name)
      }
      for name in flag.visible_short_aliases {
        out = out.visible_short_alias(name)
      }
      if flag.required {
        out = out.required()
      }
      if flag.global {
        out = out.global()
      }
      if flag.negatable {
        out = out.negatable()
      }
      if flag.hidden {
        out = out.hide()
      }
      if flag.hide_long_help {
        out = out.hide_long_help()
      }
      out
    }
    Option(option) => {
      let mut out = EngineArg::new(option.name).option()
      match option.short {
        Some(v) => out = out.short(v)
        None => ()
      }
      match option.long {
        Some(v) => out = out.long(v)
        None => ()
      }
      match option.about {
        Some(v) => out = out.help(v)
        None => ()
      }
      match option.long_about {
        Some(v) => out = out.long_help(v)
        None => ()
      }
      match option.env {
        Some(v) => out = out.env(v)
        None => ()
      }
      match option.default_value {
        Some(v) => out = out.default_value(v)
        None => ()
      }
      match option.default_values {
        Some(vs) => out = out.default_values(vs)
        None => ()
      }
      match option.num_args {
        Some(range) => out = out.num_args(convert_value_range(range))
        None => ()
      }
      match option.group {
        Some(group) => out = out.group(group)
        None => ()
      }
      out = out.action(convert_option_action(option.action))
      for name in option.requires {
        out = out.requires(name)
      }
      for name in option.conflicts_with {
        out = out.conflicts_with(name)
      }
      for name in option.aliases {
        out = out.alias_name(name)
      }
      for name in option.short_aliases {
        out = out.short_alias(name)
      }
      for name in option.visible_aliases {
        out = out.visible_alias(name)
      }
      for name in option.visible_short_aliases {
        out = out.visible_short_alias(name)
      }
      if option.multiple {
        out = out.multiple()
      }
      if option.allow_hyphen_values {
        out = out.allow_hyphen_values()
      }
      if option.last {
        out = out.last()
      }
      if option.required {
        out = out.required()
      }
      if option.global {
        out = out.global()
      }
      if option.hidden {
        out = out.hide()
      }
      if option.hide_long_help {
        out = out.hide_long_help()
      }
      out
    }
    Positional(position) => {
      let mut out = EngineArg::new(position.name).option()
      match position.index {
        Some(v) => out = out.index(v)
        None => ()
      }
      match position.about {
        Some(v) => out = out.help(v)
        None => ()
      }
      match position.long_about {
        Some(v) => out = out.long_help(v)
        None => ()
      }
      match position.env {
        Some(v) => out = out.env(v)
        None => ()
      }
      match position.default_value {
        Some(v) => out = out.default_value(v)
        None => ()
      }
      match position.default_values {
        Some(vs) => out = out.default_values(vs)
        None => ()
      }
      match position.num_args {
        Some(range) => out = out.num_args(convert_value_range(range))
        None => ()
      }
      match position.group {
        Some(group) => out = out.group(group)
        None => ()
      }
      for name in position.requires {
        out = out.requires(name)
      }
      for name in position.conflicts_with {
        out = out.conflicts_with(name)
      }
      if position.multiple {
        out = out.multiple()
      }
      if position.allow_hyphen_values {
        out = out.allow_hyphen_values()
      }
      if position.last {
        out = out.last()
      }
      if position.required {
        out = out.required()
      }
      if position.global {
        out = out.global()
      }
      if position.hidden {
        out = out.hide()
      }
      if position.hide_long_help {
        out = out.hide_long_help()
      }
      out
    }
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
