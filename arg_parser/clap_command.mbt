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
/// Clap-style command specification (builder API + parser).
struct Command {
  name : String
  about : String
  args : Array[Arg]
  subcommands : Array[Command]
  help_subcommand : Bool
  groups : Array[ArgGroup]
  aliases : Array[String]
  visible_aliases : Array[String]
}

///|
priv suberror ParseError {
  Help(String)
  Arg(ArgumentError)
  Build(ArgBuildError)
}

///|
fn raise_help(text : String) -> Unit raise ParseError {
  raise ParseError::Help(text)
}

///|
fn[T] raise_arg(err : ArgumentError) -> T raise ParseError {
  raise ParseError::Arg(err)
}

///|
fn[T] raise_build(err : ArgBuildError) -> T raise ParseError {
  raise ParseError::Build(err)
}

///|
fn[T] raise_unknown_long(
  name : String,
  long_index : Map[String, Arg],
) -> T raise ParseError {
  let hint = suggest_long(name, long_index)
  raise_arg(ArgumentError::UnknownArgument("--" + name, hint))
}

///|
fn[T] raise_unknown_short(
  short : Char,
  short_index : Map[Char, Arg],
) -> T raise ParseError {
  let hint = suggest_short(short, short_index)
  raise_arg(ArgumentError::UnknownArgument("-" + short.to_string(), hint))
}

///|
pub fn Command::new(name : String) -> Command {
  Command::{
    name,
    about: "",
    args: [],
    subcommands: [],
    help_subcommand: true,
    groups: [],
    aliases: [],
    visible_aliases: [],
  }
}

///|
pub fn Command::about(self : Command, text : String) -> Command {
  Command::{ ..self, about: text }
}

///|
pub fn Command::arg(self : Command, arg : Arg) -> Command {
  let args = clone_array(self.args)
  args.push(arg)
  Command::{ ..self, args, }
}

///|
pub fn Command::args(self : Command, more : Array[Arg]) -> Command {
  let args = clone_array(self.args)
  for arg in more {
    args.push(arg)
  }
  Command::{ ..self, args, }
}

///|
pub fn Command::subcommand(self : Command, sub : Command) -> Command {
  let subs = clone_array(self.subcommands)
  subs.push(sub)
  Command::{ ..self, subcommands: subs }
}

///|
/// Disable the built-in `help` subcommand (enabled by default).
pub fn Command::disable_help_subcommand(
  self : Command,
  disabled? : Bool = true,
) -> Command {
  Command::{ ..self, help_subcommand: !disabled }
}

///|
pub fn Command::group(self : Command, group : ArgGroup) -> Command {
  let groups = clone_array(self.groups)
  groups.push(group)
  Command::{ ..self, groups, }
}

///|
/// Add a command alias (accepted by the parser).
pub fn Command::alias_name(self : Command, alias_name : String) -> Command {
  let aliases = clone_array(self.aliases)
  aliases.push(alias_name)
  Command::{ ..self, aliases, }
}

///|
/// Add a visible command alias (accepted by the parser and shown in help).
pub fn Command::visible_alias(self : Command, alias_name : String) -> Command {
  let visible = clone_array(self.visible_aliases)
  visible.push(alias_name)
  Command::{ ..self, visible_aliases: visible }
}

///|
pub fn Command::render_help(
  self : Command,
  mode? : HelpMode = HelpMode::Plain,
) -> String {
  render_help_with_mode(self, mode)
}

///|
fn default_argv() -> Array[String] {
  let args = @env.args()
  if args.length() > 1 {
    args[1:].to_array()
  } else {
    []
  }
}

///|
/// Parse using explicit argv array (excluding program name).
///
/// Help is returned as `CommandError::Help(text)` instead of printing/exiting.
pub fn Command::parse(
  self : Command,
  argv? : Array[String] = default_argv(),
  env? : Map[String, String] = @env.get_env_vars(),
) -> Matches raise CommandError {
  parse_command(self, argv, env, []) catch {
    ParseError::Help(text) => raise CommandError::Help(text)
    ParseError::Arg(err) => raise CommandError::Arg(err)
    ParseError::Build(err) => raise CommandError::Build(err)
  }
}

///|
fn parse_command(
  cmd : Command,
  argv : Array[String],
  env : Map[String, String],
  inherited_globals : Array[Arg],
) -> Matches raise ParseError {
  validate_command(cmd) catch {
    err => raise_build(err)
  }
  let matches = Matches::new()
  let globals_here = collect_globals(cmd.args)
  let child_globals = concat_globals(inherited_globals, globals_here)
  let long_index = build_long_index(inherited_globals, cmd.args)
  let short_index = build_short_index(inherited_globals, cmd.args)
  let positionals = positional_args(cmd.args)
  let positional_values = []
  let last_pos_idx = last_positional_index(positionals)
  let mut i = 0
  while i < argv.length() {
    let arg = argv[i]
    let force_positional = match last_pos_idx {
      Some(idx) => positional_values.length() >= idx
      None => false
    }
    if force_positional {
      positional_values.push(arg)
      i = i + 1
      continue
    }
    if arg == "--" {
      for rest in argv[i + 1:] {
        positional_values.push(rest)
      }
      break
    }
    if arg == "-h" || arg == "--help" {
      raise_help(cmd.render_help())
    }
    if arg.has_prefix("--help=") {
      let mode = help_mode(arg)
      raise_help(cmd.render_help(mode~))
    }
    if should_parse_as_positional(
        arg, positionals, positional_values, long_index, short_index,
      ) {
      positional_values.push(arg)
      i = i + 1
      continue
    }
    if arg.has_prefix("--") {
      let (name, inline) = split_long(arg)
      match long_index.get(name) {
        None =>
          // Support `--no-<flag>` when the underlying flag is marked `negatable`.
          if name.has_prefix("no-") {
            let target = match name.strip_prefix("no-") {
              Some(view) => view.to_string()
              None => ""
            }
            match long_index.get(target) {
              None => raise_unknown_long(name, long_index)
              Some(spec) => {
                if !spec.negatable || spec.takes_value {
                  raise_unknown_long(name, long_index)
                }
                if inline is Some(_) {
                  raise_arg(ArgumentError::InvalidArgument(arg))
                }
                let value = match spec.action {
                  ArgAction::SetFalse => true
                  _ => false
                }
                matches.flags[spec.name] = value
                matches.flag_sources[spec.name] = ValueSource::Argv
              }
            }
          } else {
            raise_unknown_long(name, long_index)
          }
        Some(spec) =>
          if spec.takes_value {
            let value = if inline is Some(v) {
              v
            } else {
              if i + 1 >= argv.length() {
                raise_arg(ArgumentError::MissingValue("--" + name))
              }
              i = i + 1
              argv[i]
            }
            match assign_value(matches, spec, value, ValueSource::Argv) {
              Ok(_) => ()
              Err(e) => raise_arg(e)
            }
          } else {
            apply_flag(matches, spec, ValueSource::Argv)
          }
      }
      i = i + 1
      continue
    }
    if arg.has_prefix("-") && arg != "-" {
      // Parse short groups like `-abc` and short values like `-c3`.
      let mut pos = 1
      while pos < arg.length() {
        let short = arg.get_char(pos).unwrap()
        if short == 'h' {
          raise_help(cmd.render_help())
        }
        let spec = match short_index.get(short) {
          Some(v) => v
          None => raise_unknown_short(short, short_index)
        }
        if spec.takes_value {
          let value = if pos + 1 < arg.length() {
            let rest0 = arg.unsafe_substring(start=pos + 1, end=arg.length())
            match rest0.strip_prefix("=") {
              Some(view) => view.to_string()
              None => rest0
            }
          } else {
            if i + 1 >= argv.length() {
              raise_arg(ArgumentError::MissingValue("-" + short.to_string()))
            }
            i = i + 1
            argv[i]
          }
          match assign_value(matches, spec, value, ValueSource::Argv) {
            Ok(_) => ()
            Err(e) => raise_arg(e)
          }
          break
        } else {
          apply_flag(matches, spec, ValueSource::Argv)
        }
        pos = pos + 1
      }
      i = i + 1
      continue
    }
    if help_subcommand_enabled(cmd) && arg == "help" {
      let rest = argv[i + 1:].to_array()
      let (target, mode) = resolve_help_target(cmd, rest)
      let text = target.render_help(mode~)
      raise_help(text)
    }
    if cmd.subcommands.length() > 0 {
      match find_subcommand(cmd.subcommands, arg) {
        Some(sub) => {
          let rest = argv[i + 1:].to_array()
          let sub_matches = parse_command(sub, rest, env, child_globals)
          matches.subcommand = Some((sub.name, sub_matches))
          // Merge argv-provided globals from the subcommand parse into the parent
          // so globals work even when they appear after the subcommand name.
          merge_globals_from_child(matches, sub_matches, child_globals)
          let env_args = concat_globals(inherited_globals, cmd.args)
          let parent_matches = finalize_matches(
            cmd, matches, positionals, positional_values, env_args, env,
          )
          match parent_matches.subcommand {
            Some((sub_name, sub_m)) => {
              // After parent parsing, copy the final globals into the subcommand.
              propagate_globals_to_child(parent_matches, sub_m, child_globals)
              parent_matches.subcommand = Some((sub_name, sub_m))
            }
            None => ()
          }
          return parent_matches
        }
        None => ()
      }
    }
    positional_values.push(arg)
    i = i + 1
  }
  let env_args = concat_globals(inherited_globals, cmd.args)
  finalize_matches(cmd, matches, positionals, positional_values, env_args, env)
}

///|
fn finalize_matches(
  cmd : Command,
  matches : Matches,
  positionals : Array[Arg],
  positional_values : Array[String],
  env_args : Array[Arg],
  env : Map[String, String],
) -> Matches raise ParseError {
  match assign_positionals(matches, positionals, positional_values) {
    Ok(_) => ()
    Err(e) => raise_arg(e)
  }
  match apply_env(matches, env_args, env) {
    Ok(_) => ()
    Err(e) => raise_arg(e)
  }
  apply_defaults(matches, env_args)
  validate_values(cmd, matches)
  validate_groups(cmd, matches)
  matches
}

///|
fn help_subcommand_enabled(cmd : Command) -> Bool {
  cmd.help_subcommand && cmd.subcommands.length() > 0
}

///|
fn validate_command(cmd : Command) -> Unit raise ArgBuildError {
  validate_group_defs(cmd.groups)
  validate_group_refs(cmd)
  validate_arg_defs(cmd.args)
  validate_subcommand_defs(cmd.subcommands)
  validate_help_subcommand(cmd)
  for arg in cmd.args {
    validate_arg(arg)
  }
  for sub in cmd.subcommands {
    validate_command(sub)
  }
}

///|
fn validate_arg(arg : Arg) -> Unit raise ArgBuildError {
  let positional = is_positional_arg(arg)
  let has_positional_only = arg.index is Some(_) ||
    arg.allow_hyphen_values ||
    arg.last
  if !positional && has_positional_only {
    raise ArgBuildError::Unsupported(
      "positional-only settings require no short/long/aliases",
    )
  }
  if arg.negatable && arg.takes_value {
    raise ArgBuildError::Unsupported("negatable is only supported for flags")
  }
  if arg.action == ArgAction::Count && arg.takes_value {
    raise ArgBuildError::Unsupported("count is only supported for flags")
  }
  if (arg.min_values is Some(_) || arg.max_values is Some(_)) &&
    !arg.takes_value {
    raise ArgBuildError::Unsupported(
      "min/max values require value-taking arguments",
    )
  }
  match (arg.min_values, arg.max_values) {
    (Some(min), Some(max)) if max < min =>
      raise ArgBuildError::Unsupported("max values must be >= min values")
    (_, Some(max)) if max < 1 =>
      raise ArgBuildError::Unsupported("max values must be >= 1")
    _ => ()
  }
  let min = arg.min_values.unwrap_or(0)
  let max = arg.max_values
  let allow_multi = arg.multiple || arg.action == ArgAction::Append
  if (min > 1 || (max is Some(m) && m > 1)) && !allow_multi {
    raise ArgBuildError::Unsupported("multiple values require multiple/append")
  }
  if (arg.default_value is Some(_) || arg.default_values is Some(_)) &&
    !arg.takes_value {
    raise ArgBuildError::Unsupported(
      "default values require value-taking arguments",
    )
  }
  match arg.default_values {
    Some(values) if values.length() > 1 &&
      !arg.multiple &&
      arg.action != ArgAction::Append =>
      raise ArgBuildError::Unsupported(
        "default_values require multiple/append arguments",
      )
    _ => ()
  }
}

///|
fn validate_group_defs(groups : Array[ArgGroup]) -> Unit raise ArgBuildError {
  let seen : Map[String, Bool] = {}
  for group in groups {
    if seen.get(group.name) is Some(_) {
      raise ArgBuildError::Unsupported("duplicate group: " + group.name)
    }
    seen[group.name] = true
  }
}

///|
fn validate_group_refs(cmd : Command) -> Unit raise ArgBuildError {
  if cmd.groups.length() == 0 {
    return
  }
  let group_index : Map[String, Bool] = {}
  for group in cmd.groups {
    group_index[group.name] = true
  }
  for arg in cmd.args {
    for name in arg.groups {
      if group_index.get(name) is None {
        raise ArgBuildError::Unsupported("unknown group: " + name)
      }
    }
  }
}

///|
fn validate_arg_defs(args : Array[Arg]) -> Unit raise ArgBuildError {
  let seen_names : Map[String, Bool] = {}
  let seen_long : Map[String, Bool] = {}
  let seen_short : Map[Char, Bool] = {}
  for arg in args {
    if seen_names.get(arg.name) is Some(_) {
      raise ArgBuildError::Unsupported("duplicate arg name: " + arg.name)
    }
    seen_names[arg.name] = true
    for name in collect_long_names(arg) {
      if seen_long.get(name) is Some(_) {
        raise ArgBuildError::Unsupported("duplicate long option: --" + name)
      }
      seen_long[name] = true
    }
    for short in collect_short_names(arg) {
      if seen_short.get(short) is Some(_) {
        raise ArgBuildError::Unsupported(
          "duplicate short option: -" + short.to_string(),
        )
      }
      seen_short[short] = true
    }
  }
}

///|
fn validate_subcommand_defs(subs : Array[Command]) -> Unit raise ArgBuildError {
  if subs.length() == 0 {
    return
  }
  let seen : Map[String, Bool] = {}
  for sub in subs {
    for name in collect_subcommand_names(sub) {
      if seen.get(name) is Some(_) {
        raise ArgBuildError::Unsupported("duplicate subcommand: " + name)
      }
      seen[name] = true
    }
  }
}

///|
fn validate_help_subcommand(cmd : Command) -> Unit raise ArgBuildError {
  if !help_subcommand_enabled(cmd) {
    return
  }
  if find_subcommand(cmd.subcommands, "help") is Some(_) {
    raise ArgBuildError::Unsupported(
      "subcommand name reserved for built-in help: help (disable with disable_help_subcommand)",
    )
  }
}

///|
fn validate_groups(cmd : Command, matches : Matches) -> Unit raise ParseError {
  if cmd.groups.length() == 0 {
    return
  }
  for group in cmd.groups {
    let mut count = 0
    for arg in cmd.args {
      if !arg.groups.contains(group.name) {
        continue
      }
      if matches_has_value_or_flag(matches, arg.name) {
        count = count + 1
      }
    }
    if group.required && count == 0 {
      raise_arg(ArgumentError::MissingGroup(group.name))
    }
    if !group.multiple && count > 1 {
      raise_arg(ArgumentError::GroupConflict(group.name))
    }
  }
}

///|
fn validate_values(cmd : Command, matches : Matches) -> Unit raise ParseError {
  for arg in cmd.args {
    let present = matches_has_value_or_flag(matches, arg.name)
    if arg.required && !present {
      raise_arg(ArgumentError::MissingRequired(arg.name))
    }
    if !arg.takes_value {
      continue
    }
    let values = matches.values.get(arg.name).unwrap_or([])
    let count = values.length()
    let min = arg.min_values.unwrap_or(0)
    if count < min {
      raise_arg(ArgumentError::TooFewValues(arg.name, count, min))
    }
    match arg.max_values {
      Some(max) if count > max =>
        raise_arg(ArgumentError::TooManyValues(arg.name, count, max))
      _ => ()
    }
  }
}

///|
fn is_positional_arg(arg : Arg) -> Bool {
  arg.short is None &&
  arg.long is None &&
  arg.aliases.length() == 0 &&
  arg.short_aliases.length() == 0 &&
  arg.visible_aliases.length() == 0 &&
  arg.visible_short_aliases.length() == 0
}

///|
fn assign_positionals(
  matches : Matches,
  positionals : Array[Arg],
  values : Array[String],
) -> Result[Unit, ArgumentError] {
  let mut cursor = 0
  for idx in 0..<positionals.length() {
    let arg = positionals[idx]
    let remaining = values.length() - cursor
    if arg.multiple {
      let mut taken = 0
      while cursor + taken < values.length() {
        match
          add_value(
            matches,
            arg.name,
            values[cursor + taken],
            arg,
            ValueSource::Argv,
          ) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        taken = taken + 1
      }
      cursor = values.length()
      continue
    }
    if remaining > 0 {
      match
        add_value(matches, arg.name, values[cursor], arg, ValueSource::Argv) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      cursor = cursor + 1
    }
  }
  if cursor < values.length() {
    return Err(ArgumentError::TooManyPositionals)
  }
  Ok(())
}

///|
fn add_value(
  matches : Matches,
  name : String,
  value : String,
  arg : Arg,
  source : ValueSource,
) -> Result[Unit, ArgumentError] {
  if arg.multiple || arg.action == ArgAction::Append {
    let arr = matches.values.get(name).unwrap_or([])
    arr.push(value)
    matches.values[name] = arr
    let srcs = matches.value_sources.get(name).unwrap_or([])
    srcs.push(source)
    matches.value_sources[name] = srcs
  } else {
    matches.values[name] = [value]
    matches.value_sources[name] = [source]
  }
  Ok(())
}

///|
fn assign_value(
  matches : Matches,
  arg : Arg,
  value : String,
  source : ValueSource,
) -> Result[Unit, ArgumentError] {
  match arg.action {
    ArgAction::Append => add_value(matches, arg.name, value, arg, source)
    ArgAction::Set => add_value(matches, arg.name, value, arg, source)
    ArgAction::SetTrue =>
      match parse_bool(value) {
        Ok(flag) => {
          matches.flags[arg.name] = flag
          matches.flag_sources[arg.name] = source
          Ok(())
        }
        Err(e) => Err(e)
      }
    ArgAction::SetFalse =>
      match parse_bool(value) {
        Ok(flag) => {
          matches.flags[arg.name] = !flag
          matches.flag_sources[arg.name] = source
          Ok(())
        }
        Err(e) => Err(e)
      }
    ArgAction::Count =>
      match parse_count(value) {
        Ok(count) => {
          matches.counts[arg.name] = count
          matches.flags[arg.name] = count > 0
          matches.flag_sources[arg.name] = source
          Ok(())
        }
        Err(e) => Err(e)
      }
  }
}

///|
fn apply_env(
  matches : Matches,
  args : Array[Arg],
  env : Map[String, String],
) -> Result[Unit, ArgumentError] {
  for arg in args {
    let name = arg.name
    if matches_has_value_or_flag(matches, name) {
      continue
    }
    let env_name = match arg.env {
      Some(value) => value
      None => continue
    }
    let value = match env.get(env_name) {
      Some(v) => v
      None => continue
    }
    if arg.takes_value {
      match assign_value(matches, arg, value, ValueSource::Env) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      continue
    }
    match arg.action {
      ArgAction::Count =>
        match parse_count(value) {
          Ok(count) => {
            matches.counts[name] = count
            matches.flags[name] = count > 0
            matches.flag_sources[name] = ValueSource::Env
          }
          Err(e) => return Err(e)
        }
      ArgAction::SetFalse =>
        match parse_bool(value) {
          Ok(flag) => {
            matches.flags[name] = !flag
            matches.flag_sources[name] = ValueSource::Env
          }
          Err(e) => return Err(e)
        }
      ArgAction::SetTrue =>
        match parse_bool(value) {
          Ok(flag) => {
            matches.flags[name] = flag
            matches.flag_sources[name] = ValueSource::Env
          }
          Err(e) => return Err(e)
        }
      ArgAction::Set =>
        match parse_bool(value) {
          Ok(flag) => {
            matches.flags[name] = flag
            matches.flag_sources[name] = ValueSource::Env
          }
          Err(e) => return Err(e)
        }
      ArgAction::Append => ()
    }
  }
  Ok(())
}

///|
fn apply_defaults(matches : Matches, args : Array[Arg]) -> Unit {
  for arg in args {
    if !arg.takes_value {
      continue
    }
    if matches_has_value_or_flag(matches, arg.name) {
      continue
    }
    match arg.default_values {
      Some(values) if values.length() > 0 =>
        for value in values {
          let _ = add_value(matches, arg.name, value, arg, ValueSource::Default)

        }
      _ =>
        match arg.default_value {
          Some(value) => {
            let _ = add_value(
              matches,
              arg.name,
              value,
              arg,
              ValueSource::Default,
            )

          }
          None => ()
        }
    }
  }
}

///|
fn matches_has_value_or_flag(matches : Matches, name : String) -> Bool {
  matches.flags.get(name) is Some(_) || matches.values.get(name) is Some(_)
}

///|
fn collect_long_names(arg : Arg) -> Array[String] {
  let names = []
  match arg.long {
    Some(value) => names.push(value)
    None => ()
  }
  for name in arg.aliases {
    names.push(name)
  }
  for name in arg.visible_aliases {
    names.push(name)
  }
  names
}

///|
fn collect_short_names(arg : Arg) -> Array[Char] {
  let names = []
  match arg.short {
    Some(value) => names.push(value)
    None => ()
  }
  for name in arg.short_aliases {
    names.push(name)
  }
  for name in arg.visible_short_aliases {
    names.push(name)
  }
  names
}

///|
fn collect_subcommand_names(cmd : Command) -> Array[String] {
  let names = [cmd.name]
  for name in cmd.aliases {
    names.push(name)
  }
  for name in cmd.visible_aliases {
    names.push(name)
  }
  names
}

///|
fn apply_flag(matches : Matches, arg : Arg, source : ValueSource) -> Unit {
  match arg.action {
    ArgAction::SetTrue => matches.flags[arg.name] = true
    ArgAction::SetFalse => matches.flags[arg.name] = false
    ArgAction::Count => {
      let current = matches.counts.get(arg.name).unwrap_or(0)
      matches.counts[arg.name] = current + 1
      matches.flags[arg.name] = true
    }
    _ => matches.flags[arg.name] = true
  }
  matches.flag_sources[arg.name] = source
}

///|
fn parse_bool(value : String) -> Result[Bool, ArgumentError] {
  if value == "1" || value == "true" || value == "yes" || value == "on" {
    Ok(true)
  } else if value == "0" || value == "false" || value == "no" || value == "off" {
    Ok(false)
  } else {
    Err(ArgumentError::InvalidValue("invalid bool: " + value))
  }
}

///|
fn parse_count(value : String) -> Result[Int, ArgumentError] {
  let res : Result[Int, Error] = try? @strconv.parse_int(value)
  match res {
    Ok(v) => Ok(v)
    Err(_) => Err(ArgumentError::InvalidValue("invalid int: " + value))
  }
}

///|
fn suggest_long(name : String, long_index : Map[String, Arg]) -> String? {
  let candidates = map_string_keys(long_index)
  match suggest_name(name, candidates) {
    Some(best) => Some("--" + best)
    None => None
  }
}

///|
fn suggest_short(short : Char, short_index : Map[Char, Arg]) -> String? {
  let candidates = map_char_keys(short_index)
  let input = short.to_string()
  match suggest_name(input, candidates) {
    Some(best) => Some("-" + best)
    None => None
  }
}

///|
fn map_string_keys(map : Map[String, Arg]) -> Array[String] {
  let keys = []
  for key, _ in map {
    keys.push(key)
  }
  keys
}

///|
fn map_char_keys(map : Map[Char, Arg]) -> Array[String] {
  let keys = []
  for key, _ in map {
    keys.push(key.to_string())
  }
  keys
}

///|
fn suggest_name(input : String, candidates : Array[String]) -> String? {
  let mut best : String? = None
  let mut best_dist = 0
  let mut has_best = false
  let max_dist = suggestion_threshold(input.length())
  for cand in candidates {
    let dist = levenshtein(input, cand)
    if !has_best || dist < best_dist {
      best_dist = dist
      best = Some(cand)
      has_best = true
    }
  }
  match best {
    Some(name) if best_dist <= max_dist => Some(name)
    _ => None
  }
}

///|
fn suggestion_threshold(len : Int) -> Int {
  if len <= 4 {
    1
  } else if len <= 8 {
    2
  } else {
    3
  }
}

///|
fn levenshtein(a : String, b : String) -> Int {
  let aa = string_chars(a)
  let bb = string_chars(b)
  let m = aa.length()
  let n = bb.length()
  if m == 0 {
    return n
  }
  if n == 0 {
    return m
  }
  let mut prev = Array::new(capacity=n + 1)
  let mut curr = Array::new(capacity=n + 1)
  let mut j = 0
  while j <= n {
    prev.push(j)
    curr.push(0)
    j = j + 1
  }
  let mut i = 1
  while i <= m {
    curr[0] = i
    let mut j2 = 1
    while j2 <= n {
      let cost = if aa[i - 1] == bb[j2 - 1] { 0 } else { 1 }
      let del = prev[j2] + 1
      let ins = curr[j2 - 1] + 1
      let sub = prev[j2 - 1] + cost
      curr[j2] = min3(del, ins, sub)
      j2 = j2 + 1
    }
    let temp = prev
    prev = curr
    curr = temp
    i = i + 1
  }
  prev[n]
}

///|
fn string_chars(s : String) -> Array[Char] {
  let out = []
  for ch in s {
    out.push(ch)
  }
  out
}

///|
fn min3(a : Int, b : Int, c : Int) -> Int {
  let m = if a < b { a } else { b }
  if c < m {
    c
  } else {
    m
  }
}

///|
fn build_long_index(
  globals : Array[Arg],
  args : Array[Arg],
) -> Map[String, Arg] {
  let index : Map[String, Arg] = {}
  for arg in globals {
    if arg.long is Some(name) {
      index[name] = arg
    }
    for alias_name in arg.aliases {
      index[alias_name] = arg
    }
    for alias_name in arg.visible_aliases {
      index[alias_name] = arg
    }
  }
  for arg in args {
    if arg.long is Some(name) {
      index[name] = arg
    }
    for alias_name in arg.aliases {
      index[alias_name] = arg
    }
    for alias_name in arg.visible_aliases {
      index[alias_name] = arg
    }
  }
  index
}

///|
fn build_short_index(globals : Array[Arg], args : Array[Arg]) -> Map[Char, Arg] {
  let index : Map[Char, Arg] = {}
  for arg in globals {
    if arg.short is Some(value) {
      index[value] = arg
    }
    for alias_name in arg.short_aliases {
      index[alias_name] = arg
    }
    for alias_name in arg.visible_short_aliases {
      index[alias_name] = arg
    }
  }
  for arg in args {
    if arg.short is Some(value) {
      index[value] = arg
    }
    for alias_name in arg.short_aliases {
      index[alias_name] = arg
    }
    for alias_name in arg.visible_short_aliases {
      index[alias_name] = arg
    }
  }
  index
}

///|
fn collect_globals(args : Array[Arg]) -> Array[Arg] {
  let out = []
  for arg in args {
    if arg.global &&
      (
        arg.long is Some(_) ||
        arg.short is Some(_) ||
        arg.aliases.length() > 0 ||
        arg.short_aliases.length() > 0 ||
        arg.visible_aliases.length() > 0 ||
        arg.visible_short_aliases.length() > 0
      ) {
      out.push(arg)
    }
  }
  out
}

///|
fn concat_globals(parent : Array[Arg], more : Array[Arg]) -> Array[Arg] {
  let out = clone_array(parent)
  for arg in more {
    out.push(arg)
  }
  out
}

///|
fn merge_globals_from_child(
  parent : Matches,
  child : Matches,
  globals : Array[Arg],
) -> Unit {
  for arg in globals {
    let name = arg.name
    if arg.takes_value {
      let parent_vals = parent.values.get(name)
      let child_vals = child.values.get(name)
      let parent_srcs = parent.value_sources.get(name)
      let child_srcs = child.value_sources.get(name)
      if arg.multiple || arg.action == ArgAction::Append {
        let merged = []
        let merged_srcs = []
        if parent_vals is Some(pv) {
          for v in pv {
            merged.push(v)
          }
        }
        if parent_srcs is Some(ps) {
          for s in ps {
            merged_srcs.push(s)
          }
        }
        if child_vals is Some(cv) {
          for v in cv {
            merged.push(v)
          }
        }
        if child_srcs is Some(cs) {
          for s in cs {
            merged_srcs.push(s)
          }
        }
        if merged.length() > 0 {
          parent.values[name] = merged
          parent.value_sources[name] = merged_srcs
        }
      } else {
        let chosen = if child_vals is Some(cv) && cv.length() > 0 {
          cv
        } else if parent_vals is Some(pv) && pv.length() > 0 {
          pv
        } else {
          []
        }
        if chosen.length() > 0 {
          parent.values[name] = clone_array(chosen)
          let chosen_srcs = if child_srcs is Some(cs) && cs.length() > 0 {
            cs
          } else if parent_srcs is Some(ps) && ps.length() > 0 {
            ps
          } else {
            []
          }
          if chosen_srcs.length() > 0 {
            parent.value_sources[name] = clone_array(chosen_srcs)
          }
        }
      }
    } else {
      match child.flags.get(name) {
        Some(v) => {
          parent.flags[name] = v
          match child.flag_sources.get(name) {
            Some(src) => parent.flag_sources[name] = src
            None => ()
          }
          if arg.action == ArgAction::Count {
            let parent_count = parent.counts.get(name).unwrap_or(0)
            let child_count = child.counts.get(name).unwrap_or(0)
            let total = parent_count + child_count
            parent.counts[name] = total
            parent.flags[name] = total > 0
            if parent.flag_sources.get(name) is Some(_) ||
              child.flag_sources.get(name) is Some(_) {
              parent.flag_sources[name] = ValueSource::Argv
            }
          }
        }
        None => ()
      }
    }
  }
}

///|
fn propagate_globals_to_child(
  parent : Matches,
  child : Matches,
  globals : Array[Arg],
) -> Unit {
  for arg in globals {
    let name = arg.name
    if arg.takes_value {
      match parent.values.get(name) {
        Some(values) => {
          child.values[name] = clone_array(values)
          match parent.value_sources.get(name) {
            Some(srcs) => child.value_sources[name] = clone_array(srcs)
            None => ()
          }
        }
        None => ()
      }
    } else {
      match parent.flags.get(name) {
        Some(v) => {
          child.flags[name] = v
          match parent.flag_sources.get(name) {
            Some(src) => child.flag_sources[name] = src
            None => ()
          }
          if arg.action == ArgAction::Count {
            match parent.counts.get(name) {
              Some(c) => child.counts[name] = c
              None => ()
            }
          }
        }
        None => ()
      }
    }
  }
}

///|

///|

///|
fn positional_args(args : Array[Arg]) -> Array[Arg] {
  let with_index = []
  let without_index = []
  for arg in args {
    if arg.long is None && arg.short is None {
      if arg.index is Some(idx) {
        with_index.push((idx, arg))
      } else {
        without_index.push(arg)
      }
    }
  }
  sort_positionals(with_index)
  let ordered = []
  for item in with_index {
    let (_, arg) = item
    ordered.push(arg)
  }
  for arg in without_index {
    ordered.push(arg)
  }
  ordered
}

///|
fn last_positional_index(positionals : Array[Arg]) -> Int? {
  let mut i = 0
  while i < positionals.length() {
    if positionals[i].last {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn next_positional(positionals : Array[Arg], collected : Array[String]) -> Arg? {
  if collected.length() < positionals.length() {
    Some(positionals[collected.length()])
  } else {
    None
  }
}

///|
fn should_parse_as_positional(
  arg : String,
  positionals : Array[Arg],
  collected : Array[String],
  long_index : Map[String, Arg],
  short_index : Map[Char, Arg],
) -> Bool {
  if !arg.has_prefix("-") || arg == "-" {
    return false
  }
  let next = match next_positional(positionals, collected) {
    Some(v) => v
    None => return false
  }
  let allow = next.allow_hyphen_values || is_negative_number(arg)
  if !allow {
    return false
  }
  if arg.has_prefix("--") {
    let (name, _) = split_long(arg)
    return long_index.get(name) is None
  }
  let short = arg.get_char(1)
  match short {
    Some(ch) => short_index.get(ch) is None
    None => true
  }
}

///|
fn is_negative_number(arg : String) -> Bool {
  if arg.length() < 2 {
    return false
  }
  guard arg.get_char(0) is Some('-') else { return false }
  let mut i = 1
  while i < arg.length() {
    let ch = arg.get_char(i).unwrap()
    if ch < '0' || ch > '9' {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn sort_positionals(items : Array[(Int, Arg)]) -> Unit {
  let mut i = 1
  while i < items.length() {
    let key = items[i]
    let mut j = i - 1
    while j >= 0 && items[j].0 > key.0 {
      items[j + 1] = items[j]
      if j == 0 {
        j = -1
      } else {
        j = j - 1
      }
    }
    items[j + 1] = key
    i = i + 1
  }
}

///|
fn find_subcommand(subs : Array[Command], name : String) -> Command? {
  for sub in subs {
    if sub.name == name {
      return Some(sub)
    }
    for alias_name in sub.aliases {
      if alias_name == name {
        return Some(sub)
      }
    }
    for alias_name in sub.visible_aliases {
      if alias_name == name {
        return Some(sub)
      }
    }
  }
  None
}

///|
fn resolve_help_target(
  cmd : Command,
  argv : Array[String],
) -> (Command, HelpMode) raise ParseError {
  let (mode, targets) = split_help_mode(argv)
  let mut current = cmd
  let mut subs = cmd.subcommands
  for name in targets {
    if name.has_prefix("-") {
      raise_arg(
        ArgumentError::InvalidArgument("unexpected help argument: " + name),
      )
    }
    match find_subcommand(subs, name) {
      Some(sub) => {
        current = sub
        subs = sub.subcommands
      }
      None =>
        raise_arg(ArgumentError::InvalidArgument("unknown subcommand: " + name))
    }
  }
  (current, mode)
}

///|
fn split_help_mode(argv : Array[String]) -> (HelpMode, Array[String]) {
  if argv.length() == 0 {
    return (HelpMode::Plain, argv)
  }
  let last = argv[argv.length() - 1]
  if last == "-h" || last == "--help" || last.has_prefix("--help=") {
    let mode = if last.has_prefix("--help=") {
      help_mode(last)
    } else {
      HelpMode::Plain
    }
    let rest = argv[:argv.length() - 1].to_array()
    (mode, rest)
  } else {
    (HelpMode::Plain, argv)
  }
}

///|
fn split_long(arg : String) -> (String, String?) {
  let parts = []
  for part in arg.split("=") {
    parts.push(part.to_string())
  }
  if parts.length() <= 1 {
    let name = match parts[0].strip_prefix("--") {
      Some(view) => view.to_string()
      None => parts[0]
    }
    (name, None)
  } else {
    let name = match parts[0].strip_prefix("--") {
      Some(view) => view.to_string()
      None => parts[0]
    }
    let value = parts[1:].to_array().join("=")
    (name, Some(value))
  }
}

///|
fn help_mode(arg : String) -> HelpMode {
  match arg.strip_prefix("--help=") {
    Some(view) => if view == "man" { HelpMode::Man } else { HelpMode::Plain }
    None => HelpMode::Plain
  }
}

///|
fn[T] clone_array(arr : Array[T]) -> Array[T] {
  let out = Array::new(capacity=arr.length())
  for value in arr {
    out.push(value)
  }
  out
}
