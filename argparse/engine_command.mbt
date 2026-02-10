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
fn raise_help(text : String, long_help : Bool) -> Unit raise {
  if long_help {
    raise DisplayHelp::Long(text)
  } else {
    raise DisplayHelp::Short(text)
  }
}

///|
fn raise_version(text : String, is_long : Bool) -> Unit raise {
  if is_long {
    raise DisplayVersion::Long(text)
  } else {
    raise DisplayVersion::Short(text)
  }
}

///|
fn[T] raise_unknown_long(
  name : String,
  long_index : Map[String, EngineArg],
) -> T raise {
  let hint = suggest_long(name, long_index)
  raise ArgParseError::UnknownArgument("--" + name, hint)
}

///|
fn[T] raise_unknown_short(
  short : Char,
  short_index : Map[Char, EngineArg],
) -> T raise {
  let hint = suggest_short(short, short_index)
  raise ArgParseError::UnknownArgument("-" + short.to_string(), hint)
}

///|
fn render_help_for_style(cmd : Command, long_help : Bool) -> String {
  if long_help {
    render_help_long(cmd)
  } else {
    render_help_short(cmd)
  }
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
fn parse_command(
  cmd : Command,
  argv : Array[String],
  env : Map[String, String],
  inherited_globals : Array[EngineArg],
) -> EngineMatches raise {
  let args = command_engine_args(cmd)
  let groups = command_engine_groups(cmd)
  let subcommands = cmd.subcommands
  validate_command(cmd, args, groups)
  if cmd.arg_required_else_help && argv.length() == 0 {
    raise_help(render_help_short(cmd), false)
  }
  let matches = EngineMatches()
  let globals_here = collect_globals(args)
  let child_globals = concat_globals(inherited_globals, globals_here)
  let long_index = build_long_index(inherited_globals, args)
  let short_index = build_short_index(inherited_globals, args)
  let builtin_help_short = help_flag_enabled(cmd) &&
    short_index.get('h') is None
  let builtin_help_long = help_flag_enabled(cmd) &&
    long_index.get("help") is None
  let builtin_version_short = version_flag_enabled(cmd) &&
    short_index.get('V') is None
  let builtin_version_long = version_flag_enabled(cmd) &&
    long_index.get("version") is None
  let positionals = positional_args(args)
  let positional_values = []
  let last_pos_idx = last_positional_index(positionals)
  let mut i = 0
  while i < argv.length() {
    let arg = argv[i]
    if arg == "--" {
      for rest in argv[i + 1:] {
        positional_values.push(rest)
      }
      break
    }
    let force_positional = match last_pos_idx {
      Some(idx) => positional_values.length() >= idx
      None => false
    }
    if force_positional {
      positional_values.push(arg)
      i = i + 1
      continue
    }
    if builtin_help_short && arg == "-h" {
      raise_help(render_help_short(cmd), false)
    }
    if builtin_help_long && arg == "--help" {
      raise_help(render_help_long(cmd), true)
    }
    if builtin_version_short && arg == "-V" {
      raise_version(command_version(cmd, false), false)
    }
    if builtin_version_long && arg == "--version" {
      raise_version(command_version(cmd, true), true)
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
      if builtin_help_long && name == "help" {
        if inline is Some(_) {
          raise ArgParseError::InvalidArgument(arg)
        }
        raise_help(render_help_long(cmd), true)
      }
      if builtin_version_long && name == "version" {
        if inline is Some(_) {
          raise ArgParseError::InvalidArgument(arg)
        }
        raise_version(command_version(cmd, true), true)
      }
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
                  raise ArgParseError::InvalidArgument(arg)
                }
                let value = match spec.action {
                  EngineArgAction::SetFalse => true
                  _ => false
                }
                if spec.action == EngineArgAction::Count {
                  matches.counts[spec.name] = 0
                }
                matches.flags[spec.name] = value
                matches.flag_sources[spec.name] = EngineValueSource::Argv
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
                raise ArgParseError::MissingValue("--" + name)
              }
              i = i + 1
              argv[i]
            }
            match assign_value(matches, spec, value, EngineValueSource::Argv) {
              Ok(_) => ()
              Err(e) => raise e
            }
            match
              consume_required_option_values(
                matches,
                spec,
                argv,
                i + 1,
                long_index,
                short_index,
              ) {
              Ok(consumed) => i = i + consumed
              Err(e) => raise e
            }
          } else {
            if inline is Some(_) {
              raise ArgParseError::InvalidArgument(arg)
            }
            match spec.action {
              EngineArgAction::Help => raise_help(render_help_long(cmd), true)
              EngineArgAction::Version =>
                raise_version(command_version(cmd, true), true)
              _ => apply_flag(matches, spec, EngineValueSource::Argv)
            }
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
        if short == 'h' && builtin_help_short {
          raise_help(render_help_short(cmd), false)
        }
        if short == 'V' && builtin_version_short {
          raise_version(command_version(cmd, false), false)
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
              raise ArgParseError::MissingValue("-" + short.to_string())
            }
            i = i + 1
            argv[i]
          }
          match assign_value(matches, spec, value, EngineValueSource::Argv) {
            Ok(_) => ()
            Err(e) => raise e
          }
          match
            consume_required_option_values(
              matches,
              spec,
              argv,
              i + 1,
              long_index,
              short_index,
            ) {
            Ok(consumed) => i = i + consumed
            Err(e) => raise e
          }
          break
        } else {
          match spec.action {
            EngineArgAction::Help => raise_help(render_help_short(cmd), false)
            EngineArgAction::Version =>
              raise_version(command_version(cmd, false), false)
            _ => apply_flag(matches, spec, EngineValueSource::Argv)
          }
        }
        pos = pos + 1
      }
      i = i + 1
      continue
    }
    if help_subcommand_enabled(cmd) && arg == "help" {
      let rest = argv[i + 1:].to_array()
      let (target, long_help) = resolve_help_target(
        cmd, rest, builtin_help_short, builtin_help_long,
      )
      let text = render_help_for_style(target, long_help)
      raise_help(text, long_help)
    }
    if subcommands.length() > 0 {
      match find_subcommand(subcommands, arg) {
        Some(sub) => {
          let rest = argv[i + 1:].to_array()
          let sub_matches = parse_command(sub, rest, env, child_globals)
          matches.subcommand = Some((sub.name, sub_matches))
          // Merge argv-provided globals from the subcommand parse into the parent
          // so globals work even when they appear after the subcommand name.
          merge_globals_from_child(matches, sub_matches, child_globals)
          let env_args = concat_globals(inherited_globals, args)
          let parent_matches = finalize_matches(
            cmd, args, groups, matches, positionals, positional_values, env_args,
            env,
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
  let env_args = concat_globals(inherited_globals, args)
  finalize_matches(
    cmd, args, groups, matches, positionals, positional_values, env_args, env,
  )
}

///|
fn finalize_matches(
  cmd : Command,
  args : Array[EngineArg],
  groups : Array[EngineArgGroup],
  matches : EngineMatches,
  positionals : Array[EngineArg],
  positional_values : Array[String],
  env_args : Array[EngineArg],
  env : Map[String, String],
) -> EngineMatches raise {
  match assign_positionals(matches, positionals, positional_values) {
    Ok(_) => ()
    Err(e) => raise e
  }
  match apply_env(matches, env_args, env) {
    Ok(_) => ()
    Err(e) => raise e
  }
  apply_defaults(matches, env_args)
  validate_values(args, matches)
  validate_relationships(matches, env_args)
  validate_groups(args, groups, matches)
  validate_command_policies(cmd, matches)
  matches
}

///|
fn help_subcommand_enabled(cmd : Command) -> Bool {
  !cmd.disable_help_subcommand && cmd.subcommands.length() > 0
}

///|
fn help_flag_enabled(cmd : Command) -> Bool {
  !cmd.disable_help_flag
}

///|
fn version_flag_enabled(cmd : Command) -> Bool {
  !cmd.disable_version_flag && cmd.version is Some(_)
}

///|
fn command_version(cmd : Command, is_long : Bool) -> String {
  let _ = is_long
  cmd.version.unwrap_or("")
}

///|
fn validate_command(
  cmd : Command,
  args : Array[EngineArg],
  groups : Array[EngineArgGroup],
) -> Unit raise ArgBuildError {
  validate_group_defs(groups)
  validate_group_refs(args, groups)
  validate_arg_defs(args)
  validate_subcommand_defs(cmd.subcommands)
  validate_subcommand_required_policy(cmd)
  validate_help_subcommand(cmd)
  validate_version_actions(cmd)
  for arg in args {
    validate_arg(arg)
  }
  for sub in cmd.subcommands {
    validate_command(sub, command_engine_args(sub), command_engine_groups(sub))
  }
}

///|
fn validate_arg(arg : EngineArg) -> Unit raise ArgBuildError {
  let positional = is_positional_arg(arg)
  let has_positional_only = arg.index is Some(_) ||
    arg.allow_hyphen_values ||
    arg.last
  if !positional && has_positional_only {
    raise ArgBuildError::Unsupported(
      "positional-only settings require no short/long",
    )
  }
  if arg.negatable && arg.takes_value {
    raise ArgBuildError::Unsupported("negatable is only supported for flags")
  }
  if arg.action == EngineArgAction::Count && arg.takes_value {
    raise ArgBuildError::Unsupported("count is only supported for flags")
  }
  if arg.action == EngineArgAction::Help ||
    arg.action == EngineArgAction::Version {
    if arg.takes_value {
      raise ArgBuildError::Unsupported("help/version actions require flags")
    }
    if arg.negatable {
      raise ArgBuildError::Unsupported(
        "help/version actions do not support negatable",
      )
    }
    if arg.env is Some(_) || arg.default_values is Some(_) {
      raise ArgBuildError::Unsupported(
        "help/version actions do not support env/defaults",
      )
    }
    if arg.num_args is Some(_) || arg.multiple {
      raise ArgBuildError::Unsupported(
        "help/version actions do not support multiple values",
      )
    }
    let has_option = arg.long is Some(_) || arg.short is Some(_)
    if !has_option {
      raise ArgBuildError::Unsupported(
        "help/version actions require short/long option",
      )
    }
  }
  if arg.num_args is Some(_) && !arg.takes_value {
    raise ArgBuildError::Unsupported(
      "min/max values require value-taking arguments",
    )
  }
  let (min, max) = arg_min_max_for_validate(arg)
  let allow_multi = arg.multiple || arg.action == EngineArgAction::Append
  if (min > 1 || (max is Some(m) && m > 1)) && !allow_multi {
    raise ArgBuildError::Unsupported(
      "multiple values require action=Append or num_args allowing >1",
    )
  }
  if arg.default_values is Some(_) && !arg.takes_value {
    raise ArgBuildError::Unsupported(
      "default values require value-taking arguments",
    )
  }
  match arg.default_values {
    Some(values) if values.length() > 1 &&
      !arg.multiple &&
      arg.action != EngineArgAction::Append =>
      raise ArgBuildError::Unsupported(
        "default_values require action=Append or num_args allowing >1",
      )
    _ => ()
  }
}

///|
fn validate_group_defs(
  groups : Array[EngineArgGroup],
) -> Unit raise ArgBuildError {
  let seen : Map[String, Bool] = {}
  for group in groups {
    if seen.get(group.name) is Some(_) {
      raise ArgBuildError::Unsupported("duplicate group: " + group.name)
    }
    seen[group.name] = true
  }
  for group in groups {
    for required in group.requires {
      if required == group.name {
        raise ArgBuildError::Unsupported(
          "group cannot require itself: " + group.name,
        )
      }
      if seen.get(required) is None {
        raise ArgBuildError::Unsupported(
          "unknown group requires target: " + group.name + " -> " + required,
        )
      }
    }
    for conflict in group.conflicts_with {
      if conflict == group.name {
        raise ArgBuildError::Unsupported(
          "group cannot conflict with itself: " + group.name,
        )
      }
      if seen.get(conflict) is None {
        raise ArgBuildError::Unsupported(
          "unknown group conflicts_with target: " +
          group.name +
          " -> " +
          conflict,
        )
      }
    }
  }
}

///|
fn validate_group_refs(
  args : Array[EngineArg],
  groups : Array[EngineArgGroup],
) -> Unit raise ArgBuildError {
  if groups.length() == 0 {
    return
  }
  let group_index : Map[String, Bool] = {}
  for group in groups {
    group_index[group.name] = true
  }
  let arg_index : Map[String, Bool] = {}
  for arg in args {
    arg_index[arg.name] = true
  }
  for arg in args {
    for name in arg.groups {
      if group_index.get(name) is None {
        raise ArgBuildError::Unsupported("unknown group: " + name)
      }
    }
  }
  for group in groups {
    for name in group.args {
      if arg_index.get(name) is None {
        raise ArgBuildError::Unsupported(
          "unknown group arg: " + group.name + " -> " + name,
        )
      }
    }
  }
}

///|
fn validate_arg_defs(args : Array[EngineArg]) -> Unit raise ArgBuildError {
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
  for arg in args {
    for required in arg.requires {
      if required == arg.name {
        raise ArgBuildError::Unsupported(
          "arg cannot require itself: " + arg.name,
        )
      }
      if seen_names.get(required) is None {
        raise ArgBuildError::Unsupported(
          "unknown requires target: " + arg.name + " -> " + required,
        )
      }
    }
    for conflict in arg.conflicts_with {
      if conflict == arg.name {
        raise ArgBuildError::Unsupported(
          "arg cannot conflict with itself: " + arg.name,
        )
      }
      if seen_names.get(conflict) is None {
        raise ArgBuildError::Unsupported(
          "unknown conflicts_with target: " + arg.name + " -> " + conflict,
        )
      }
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
fn validate_subcommand_required_policy(
  cmd : Command,
) -> Unit raise ArgBuildError {
  if cmd.subcommand_required && cmd.subcommands.length() == 0 {
    raise ArgBuildError::Unsupported(
      "subcommand_required requires at least one subcommand",
    )
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
fn validate_version_actions(cmd : Command) -> Unit raise ArgBuildError {
  if cmd.version is Some(_) {
    return
  }
  for arg in command_engine_args(cmd) {
    if arg.action == EngineArgAction::Version {
      raise ArgBuildError::Unsupported(
        "version action requires command version text",
      )
    }
  }
}

///|
fn validate_command_policies(
  cmd : Command,
  matches : EngineMatches,
) -> Unit raise {
  if cmd.subcommand_required &&
    cmd.subcommands.length() > 0 &&
    matches.subcommand is None {
    raise ArgParseError::MissingRequired("subcommand")
  }
}

///|
fn validate_groups(
  args : Array[EngineArg],
  groups : Array[EngineArgGroup],
  matches : EngineMatches,
) -> Unit raise {
  if groups.length() == 0 {
    return
  }
  let group_presence : Map[String, Int] = {}
  for group in groups {
    let mut count = 0
    for arg in args {
      if !arg_in_group(arg, group) {
        continue
      }
      if matches_has_value_or_flag(matches, arg.name) {
        count = count + 1
      }
    }
    group_presence[group.name] = count
    if group.required && count == 0 {
      raise ArgParseError::MissingGroup(group.name)
    }
    if !group.multiple && count > 1 {
      raise ArgParseError::GroupConflict(group.name)
    }
  }
  for group in groups {
    let count = group_presence[group.name]
    if count == 0 {
      continue
    }
    for required in group.requires {
      if group_presence.get(required).unwrap_or(0) == 0 {
        raise ArgParseError::MissingGroup(required)
      }
    }
    for conflict in group.conflicts_with {
      if group_presence.get(conflict).unwrap_or(0) > 0 {
        raise ArgParseError::GroupConflict(
          group.name + " conflicts with " + conflict,
        )
      }
    }
  }
}

///|
fn arg_in_group(arg : EngineArg, group : EngineArgGroup) -> Bool {
  arg.groups.contains(group.name) || group.args.contains(arg.name)
}

///|
fn validate_values(
  args : Array[EngineArg],
  matches : EngineMatches,
) -> Unit raise {
  for arg in args {
    let present = matches_has_value_or_flag(matches, arg.name)
    if arg.required && !present {
      raise ArgParseError::MissingRequired(arg.name)
    }
    if !arg.takes_value {
      continue
    }
    let values = matches.values.get(arg.name).unwrap_or([])
    let count = values.length()
    let (min, max) = arg_min_max(arg)
    if count < min {
      raise ArgParseError::TooFewValues(arg.name, count, min)
    }
    match max {
      Some(max) if count > max =>
        raise ArgParseError::TooManyValues(arg.name, count, max)
      _ => ()
    }
  }
}

///|
fn validate_relationships(
  matches : EngineMatches,
  args : Array[EngineArg],
) -> Unit raise {
  for arg in args {
    if !matches_has_value_or_flag(matches, arg.name) {
      continue
    }
    for required in arg.requires {
      if !matches_has_value_or_flag(matches, required) {
        raise ArgParseError::MissingRequired(required)
      }
    }
    for conflict in arg.conflicts_with {
      if matches_has_value_or_flag(matches, conflict) {
        raise ArgParseError::InvalidArgument(
          "conflicting arguments: " + arg.name + " and " + conflict,
        )
      }
    }
  }
}

///|
fn is_positional_arg(arg : EngineArg) -> Bool {
  arg.short is None && arg.long is None
}

///|
fn assign_positionals(
  matches : EngineMatches,
  positionals : Array[EngineArg],
  values : Array[String],
) -> Result[Unit, ArgParseError] {
  let mut cursor = 0
  for idx in 0..<positionals.length() {
    let arg = positionals[idx]
    let remaining = values.length() - cursor
    if arg.multiple {
      let (min, max) = arg_min_max(arg)
      let reserve = remaining_positional_min(positionals, idx + 1)
      let mut take = remaining - reserve
      if take < 0 {
        take = 0
      }
      match max {
        Some(max_count) if take > max_count => take = max_count
        _ => ()
      }
      if take < min {
        take = min
      }
      if take > remaining {
        take = remaining
      }
      let mut taken = 0
      while taken < take {
        match
          add_value(
            matches,
            arg.name,
            values[cursor + taken],
            arg,
            EngineValueSource::Argv,
          ) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        taken = taken + 1
      }
      cursor = cursor + taken
      continue
    }
    if remaining > 0 {
      match
        add_value(
          matches,
          arg.name,
          values[cursor],
          arg,
          EngineValueSource::Argv,
        ) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      cursor = cursor + 1
    }
  }
  if cursor < values.length() {
    return Err(ArgParseError::TooManyPositionals)
  }
  Ok(())
}

///|
fn positional_min_required(arg : EngineArg) -> Int {
  let (min, _) = arg_min_max(arg)
  if min > 0 {
    min
  } else if arg.required {
    1
  } else {
    0
  }
}

///|
fn remaining_positional_min(positionals : Array[EngineArg], start : Int) -> Int {
  let mut total = 0
  let mut idx = start
  while idx < positionals.length() {
    total = total + positional_min_required(positionals[idx])
    idx = idx + 1
  }
  total
}

///|
fn add_value(
  matches : EngineMatches,
  name : String,
  value : String,
  arg : EngineArg,
  source : EngineValueSource,
) -> Result[Unit, ArgParseError] {
  if arg.multiple || arg.action == EngineArgAction::Append {
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
  matches : EngineMatches,
  arg : EngineArg,
  value : String,
  source : EngineValueSource,
) -> Result[Unit, ArgParseError] {
  match arg.action {
    EngineArgAction::Append => add_value(matches, arg.name, value, arg, source)
    EngineArgAction::Set => add_value(matches, arg.name, value, arg, source)
    EngineArgAction::SetTrue =>
      match parse_bool(value) {
        Ok(flag) => {
          matches.flags[arg.name] = flag
          matches.flag_sources[arg.name] = source
          Ok(())
        }
        Err(e) => Err(e)
      }
    EngineArgAction::SetFalse =>
      match parse_bool(value) {
        Ok(flag) => {
          matches.flags[arg.name] = !flag
          matches.flag_sources[arg.name] = source
          Ok(())
        }
        Err(e) => Err(e)
      }
    EngineArgAction::Count =>
      match parse_count(value) {
        Ok(count) => {
          matches.counts[arg.name] = count
          matches.flags[arg.name] = count > 0
          matches.flag_sources[arg.name] = source
          Ok(())
        }
        Err(e) => Err(e)
      }
    EngineArgAction::Help =>
      Err(ArgParseError::InvalidArgument("help action does not take values"))
    EngineArgAction::Version =>
      Err(ArgParseError::InvalidArgument("version action does not take values"))
  }
}

///|
fn required_option_value_count(matches : EngineMatches, arg : EngineArg) -> Int {
  match arg.num_args {
    None => 0
    Some(_) => {
      let (min, _) = arg_min_max(arg)
      if min <= 0 {
        return 0
      }
      let count = matches.values.get(arg.name).unwrap_or([]).length()
      if count >= min {
        0
      } else {
        min - count
      }
    }
  }
}

///|
fn consume_required_option_values(
  matches : EngineMatches,
  arg : EngineArg,
  argv : Array[String],
  start : Int,
  long_index : Map[String, EngineArg],
  short_index : Map[Char, EngineArg],
) -> Result[Int, ArgParseError] {
  let need = required_option_value_count(matches, arg)
  if need == 0 {
    return Ok(0)
  }
  let mut consumed = 0
  while consumed < need && start + consumed < argv.length() {
    let value = argv[start + consumed]
    if starts_known_option(value, long_index, short_index) {
      break
    }
    match assign_value(matches, arg, value, EngineValueSource::Argv) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
    consumed = consumed + 1
  }
  Ok(consumed)
}

///|
fn starts_known_option(
  arg : String,
  long_index : Map[String, EngineArg],
  short_index : Map[Char, EngineArg],
) -> Bool {
  if !arg.has_prefix("-") || arg == "-" {
    return false
  }
  if arg.has_prefix("--") {
    let (name, _) = split_long(arg)
    if long_index.get(name) is Some(_) {
      return true
    }
    if name.has_prefix("no-") {
      let target = match name.strip_prefix("no-") {
        Some(view) => view.to_string()
        None => ""
      }
      match long_index.get(target) {
        Some(spec) => !spec.takes_value && spec.negatable
        None => false
      }
    } else {
      false
    }
  } else {
    match arg.get_char(1) {
      Some(ch) => short_index.get(ch) is Some(_)
      None => false
    }
  }
}

///|
fn apply_env(
  matches : EngineMatches,
  args : Array[EngineArg],
  env : Map[String, String],
) -> Result[Unit, ArgParseError] {
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
      match assign_value(matches, arg, value, EngineValueSource::Env) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      continue
    }
    match arg.action {
      EngineArgAction::Count =>
        match parse_count(value) {
          Ok(count) => {
            matches.counts[name] = count
            matches.flags[name] = count > 0
            matches.flag_sources[name] = EngineValueSource::Env
          }
          Err(e) => return Err(e)
        }
      EngineArgAction::SetFalse =>
        match parse_bool(value) {
          Ok(flag) => {
            matches.flags[name] = !flag
            matches.flag_sources[name] = EngineValueSource::Env
          }
          Err(e) => return Err(e)
        }
      EngineArgAction::SetTrue =>
        match parse_bool(value) {
          Ok(flag) => {
            matches.flags[name] = flag
            matches.flag_sources[name] = EngineValueSource::Env
          }
          Err(e) => return Err(e)
        }
      EngineArgAction::Set =>
        match parse_bool(value) {
          Ok(flag) => {
            matches.flags[name] = flag
            matches.flag_sources[name] = EngineValueSource::Env
          }
          Err(e) => return Err(e)
        }
      EngineArgAction::Append => ()
      EngineArgAction::Help => ()
      EngineArgAction::Version => ()
    }
  }
  Ok(())
}

///|
fn apply_defaults(matches : EngineMatches, args : Array[EngineArg]) -> Unit {
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
          let _ = add_value(
            matches,
            arg.name,
            value,
            arg,
            EngineValueSource::Default,
          )
        }
      _ => ()
    }
  }
}

///|
fn matches_has_value_or_flag(matches : EngineMatches, name : String) -> Bool {
  matches.flags.get(name) is Some(_) || matches.values.get(name) is Some(_)
}

///|
fn collect_long_names(arg : EngineArg) -> Array[String] {
  let names = []
  match arg.long {
    Some(value) => names.push(value)
    None => ()
  }
  names
}

///|
fn collect_short_names(arg : EngineArg) -> Array[Char] {
  let names = []
  match arg.short {
    Some(value) => names.push(value)
    None => ()
  }
  names
}

///|
fn collect_subcommand_names(cmd : Command) -> Array[String] {
  [cmd.name]
}

///|
fn apply_flag(
  matches : EngineMatches,
  arg : EngineArg,
  source : EngineValueSource,
) -> Unit {
  match arg.action {
    EngineArgAction::SetTrue => matches.flags[arg.name] = true
    EngineArgAction::SetFalse => matches.flags[arg.name] = false
    EngineArgAction::Count => {
      let current = matches.counts.get(arg.name).unwrap_or(0)
      matches.counts[arg.name] = current + 1
      matches.flags[arg.name] = true
    }
    EngineArgAction::Help => ()
    EngineArgAction::Version => ()
    _ => matches.flags[arg.name] = true
  }
  matches.flag_sources[arg.name] = source
}

///|
fn parse_bool(value : String) -> Result[Bool, ArgParseError] {
  if value == "1" || value == "true" || value == "yes" || value == "on" {
    Ok(true)
  } else if value == "0" || value == "false" || value == "no" || value == "off" {
    Ok(false)
  } else {
    Err(ArgParseError::InvalidValue("invalid bool: " + value))
  }
}

///|
fn parse_count(value : String) -> Result[Int, ArgParseError] {
  let res : Result[Int, Error] = try? @strconv.parse_int(value)
  match res {
    Ok(v) =>
      if v >= 0 {
        Ok(v)
      } else {
        Err(ArgParseError::InvalidValue("invalid int: " + value))
      }
    Err(_) => Err(ArgParseError::InvalidValue("invalid int: " + value))
  }
}

///|
fn suggest_long(name : String, long_index : Map[String, EngineArg]) -> String? {
  let candidates = map_string_keys(long_index)
  match suggest_name(name, candidates) {
    Some(best) => Some("--" + best)
    None => None
  }
}

///|
fn suggest_short(short : Char, short_index : Map[Char, EngineArg]) -> String? {
  let candidates = map_char_keys(short_index)
  let input = short.to_string()
  match suggest_name(input, candidates) {
    Some(best) => Some("-" + best)
    None => None
  }
}

///|
fn map_string_keys(map : Map[String, EngineArg]) -> Array[String] {
  let keys = []
  for key, _ in map {
    keys.push(key)
  }
  keys
}

///|
fn map_char_keys(map : Map[Char, EngineArg]) -> Array[String] {
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
  globals : Array[EngineArg],
  args : Array[EngineArg],
) -> Map[String, EngineArg] {
  let index : Map[String, EngineArg] = {}
  for arg in globals {
    if arg.long is Some(name) {
      index[name] = arg
    }
  }
  for arg in args {
    if arg.long is Some(name) {
      index[name] = arg
    }
  }
  index
}

///|
fn build_short_index(
  globals : Array[EngineArg],
  args : Array[EngineArg],
) -> Map[Char, EngineArg] {
  let index : Map[Char, EngineArg] = {}
  for arg in globals {
    if arg.short is Some(value) {
      index[value] = arg
    }
  }
  for arg in args {
    if arg.short is Some(value) {
      index[value] = arg
    }
  }
  index
}

///|
fn collect_globals(args : Array[EngineArg]) -> Array[EngineArg] {
  let out = []
  for arg in args {
    if arg.global && (arg.long is Some(_) || arg.short is Some(_)) {
      out.push(arg)
    }
  }
  out
}

///|
fn concat_globals(
  parent : Array[EngineArg],
  more : Array[EngineArg],
) -> Array[EngineArg] {
  let out = clone_array(parent)
  for arg in more {
    out.push(arg)
  }
  out
}

///|
fn source_priority(source : EngineValueSource?) -> Int {
  match source {
    Some(EngineValueSource::Argv) => 3
    Some(EngineValueSource::Env) => 2
    Some(EngineValueSource::Default) => 1
    None => 0
  }
}

///|
fn prefer_child_source(
  parent_source : EngineValueSource?,
  child_source : EngineValueSource?,
) -> Bool {
  let parent_priority = source_priority(parent_source)
  let child_priority = source_priority(child_source)
  if child_priority > parent_priority {
    true
  } else if child_priority < parent_priority {
    false
  } else {
    child_source is Some(EngineValueSource::Argv)
  }
}

///|
fn strongest_source(
  parent_source : EngineValueSource?,
  child_source : EngineValueSource?,
) -> EngineValueSource? {
  if prefer_child_source(parent_source, child_source) {
    child_source
  } else {
    match parent_source {
      Some(source) => Some(source)
      None => child_source
    }
  }
}

///|
fn source_from_values(
  sources : Array[EngineValueSource]?,
) -> EngineValueSource? {
  match sources {
    Some(items) if items.length() > 0 => highest_source(items)
    _ => None
  }
}

///|
fn merge_globals_from_child(
  parent : EngineMatches,
  child : EngineMatches,
  globals : Array[EngineArg],
) -> Unit {
  for arg in globals {
    let name = arg.name
    if arg.takes_value {
      let parent_vals = parent.values.get(name)
      let child_vals = child.values.get(name)
      let parent_srcs = parent.value_sources.get(name)
      let child_srcs = child.value_sources.get(name)
      let has_parent = parent_vals is Some(pv) && pv.length() > 0
      let has_child = child_vals is Some(cv) && cv.length() > 0
      if !has_parent && !has_child {
        continue
      }
      let parent_source = source_from_values(parent_srcs)
      let child_source = source_from_values(child_srcs)
      if arg.multiple || arg.action == EngineArgAction::Append {
        let both_argv = parent_source is Some(EngineValueSource::Argv) &&
          child_source is Some(EngineValueSource::Argv)
        if both_argv {
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
          let choose_child = has_child &&
            (!has_parent || prefer_child_source(parent_source, child_source))
          if choose_child {
            if child_vals is Some(cv) && cv.length() > 0 {
              parent.values[name] = clone_array(cv)
            }
            if child_srcs is Some(cs) && cs.length() > 0 {
              parent.value_sources[name] = clone_array(cs)
            }
          } else if parent_vals is Some(pv) && pv.length() > 0 {
            parent.values[name] = clone_array(pv)
            if parent_srcs is Some(ps) && ps.length() > 0 {
              parent.value_sources[name] = clone_array(ps)
            }
          }
        }
      } else {
        let choose_child = has_child &&
          (!has_parent || prefer_child_source(parent_source, child_source))
        if choose_child {
          if child_vals is Some(cv) && cv.length() > 0 {
            parent.values[name] = clone_array(cv)
          }
          if child_srcs is Some(cs) && cs.length() > 0 {
            parent.value_sources[name] = clone_array(cs)
          }
        } else if parent_vals is Some(pv) && pv.length() > 0 {
          parent.values[name] = clone_array(pv)
          if parent_srcs is Some(ps) && ps.length() > 0 {
            parent.value_sources[name] = clone_array(ps)
          }
        }
      }
    } else {
      match child.flags.get(name) {
        Some(v) =>
          if arg.action == EngineArgAction::Count {
            let has_parent = parent.flags.get(name) is Some(_)
            let parent_source = parent.flag_sources.get(name)
            let child_source = child.flag_sources.get(name)
            let both_argv = parent_source is Some(EngineValueSource::Argv) &&
              child_source is Some(EngineValueSource::Argv)
            if both_argv {
              let parent_count = parent.counts.get(name).unwrap_or(0)
              let child_count = child.counts.get(name).unwrap_or(0)
              let total = parent_count + child_count
              parent.counts[name] = total
              parent.flags[name] = total > 0
              match strongest_source(parent_source, child_source) {
                Some(src) => parent.flag_sources[name] = src
                None => ()
              }
            } else {
              let choose_child = !has_parent ||
                prefer_child_source(parent_source, child_source)
              if choose_child {
                let child_count = child.counts.get(name).unwrap_or(0)
                parent.counts[name] = child_count
                parent.flags[name] = child_count > 0
                match child_source {
                  Some(src) => parent.flag_sources[name] = src
                  None => ()
                }
              }
            }
          } else {
            let has_parent = parent.flags.get(name) is Some(_)
            let parent_source = parent.flag_sources.get(name)
            let child_source = child.flag_sources.get(name)
            let choose_child = !has_parent ||
              prefer_child_source(parent_source, child_source)
            if choose_child {
              parent.flags[name] = v
              match child_source {
                Some(src) => parent.flag_sources[name] = src
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
fn propagate_globals_to_child(
  parent : EngineMatches,
  child : EngineMatches,
  globals : Array[EngineArg],
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
          if arg.action == EngineArgAction::Count {
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
fn positional_args(args : Array[EngineArg]) -> Array[EngineArg] {
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
fn last_positional_index(positionals : Array[EngineArg]) -> Int? {
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
fn next_positional(
  positionals : Array[EngineArg],
  collected : Array[String],
) -> EngineArg? {
  if collected.length() < positionals.length() {
    Some(positionals[collected.length()])
  } else {
    None
  }
}

///|
fn should_parse_as_positional(
  arg : String,
  positionals : Array[EngineArg],
  collected : Array[String],
  long_index : Map[String, EngineArg],
  short_index : Map[Char, EngineArg],
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
fn sort_positionals(items : Array[(Int, EngineArg)]) -> Unit {
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
  }
  None
}

///|
fn resolve_help_target(
  cmd : Command,
  argv : Array[String],
  builtin_help_short : Bool,
  builtin_help_long : Bool,
) -> (Command, Bool) raise {
  let (long_help, targets) = split_help_style(
    argv, builtin_help_short, builtin_help_long,
  )
  let mut current = cmd
  let mut subs = cmd.subcommands
  for name in targets {
    if name.has_prefix("-") {
      raise ArgParseError::InvalidArgument("unexpected help argument: " + name)
    }
    match find_subcommand(subs, name) {
      Some(sub) => {
        current = sub
        subs = sub.subcommands
      }
      None =>
        raise ArgParseError::InvalidArgument("unknown subcommand: " + name)
    }
  }
  (current, long_help)
}

///|
fn split_help_style(
  argv : Array[String],
  help_short : Bool,
  help_long : Bool,
) -> (Bool, Array[String]) {
  if argv.length() == 0 {
    return (true, argv)
  }
  if !help_short && !help_long {
    return (true, argv)
  }
  let last = argv[argv.length() - 1]
  if (last == "-h" && help_short) || (last == "--help" && help_long) {
    let long_help = last == "--help"
    let rest = argv[:argv.length() - 1].to_array()
    (long_help, rest)
  } else {
    (true, argv)
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
fn[T] clone_array(arr : Array[T]) -> Array[T] {
  let out = Array::new(capacity=arr.length())
  for value in arr {
    out.push(value)
  }
  out
}
