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
fn raise_help(text : String) -> Unit raise DisplayHelp {
  raise Message(text)
}

///|
fn raise_version(text : String) -> Unit raise DisplayVersion {
  raise Message(text)
}

///|
fn[T] raise_unknown_long(
  name : String,
  long_index : Map[String, Arg],
) -> T raise ArgParseError {
  let hint = suggest_long(name, long_index)
  raise UnknownArgument("--\{name}", hint)
}

///|
fn[T] raise_unknown_short(
  short : Char,
  short_index : Map[Char, Arg],
) -> T raise ArgParseError {
  let hint = suggest_short(short, short_index)
  raise UnknownArgument("-\{short}", hint)
}

///|
fn[T] raise_subcommand_conflict(name : String) -> T raise ArgParseError {
  raise InvalidArgument(
    "subcommand '\{name}' cannot be used with positional arguments",
  )
}

///|
fn render_help_for_context(
  cmd : Command,
  inherited_globals : Array[Arg],
) -> String {
  let help_cmd = if inherited_globals.length() == 0 {
    cmd
  } else {
    { ..cmd, args: inherited_globals + cmd.args }
  }
  render_help(help_cmd)
}

///|
fn raise_context_help(
  cmd : Command,
  inherited_globals : Array[Arg],
) -> Unit raise DisplayHelp {
  raise_help(render_help_for_context(cmd, inherited_globals))
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
fn merge_global_defs(
  inherited_globals : Array[Arg],
  globals_here : Array[Arg],
) -> Array[Arg] {
  let merged = inherited_globals.copy()
  for global in globals_here {
    match merged.search_by(arg => arg.name == global.name) {
      Some(idx) => merged[idx] = global
      None => merged.push(global)
    }
  }
  merged
}

///|
fn parse_command(
  cmd : Command,
  argv : ArrayView[String],
  env : Map[String, String],
  inherited_globals : Array[Arg],
  inherited_version_long : Map[String, String],
  inherited_version_short : Map[Char, String],
) -> Matches raise {
  match cmd.build_error {
    Some(err) => raise err
    None => ()
  }
  let args = cmd.args
  let groups = cmd.groups
  let subcommands = cmd.subcommands
  if cmd.arg_required_else_help && argv.length() == 0 {
    raise_context_help(cmd, inherited_globals)
  }
  let matches = new_matches_parse_state()
  let globals_here = collect_globals(args)
  let child_globals = merge_global_defs(inherited_globals, globals_here)
  let child_version_long = inherited_version_long.copy()
  let child_version_short = inherited_version_short.copy()
  for global in globals_here {
    if global.info is Flag(long~, short~, action=Version, ..) {
      if long is Some(name) {
        child_version_long[name] = command_version(cmd)
      }
      if short is Some(short) {
        child_version_short[short] = command_version(cmd)
      }
    }
  }
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
  let last_pos_idx = positionals.search_by(arg => {
    arg.info is Positional(last=true, ..)
  })
  let mut i = 0
  let mut positional_arg_found = false
  while i < argv.length() {
    let arg = argv[i]
    if arg == "--" {
      if i + 1 < argv.length() {
        positional_arg_found = true
      }
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
      positional_arg_found = true
      i = i + 1
      continue
    }
    if builtin_help_short && arg == "-h" {
      raise_context_help(cmd, inherited_globals)
    }
    if builtin_help_long && arg == "--help" {
      raise_context_help(cmd, inherited_globals)
    }
    if builtin_version_short && arg == "-V" {
      raise_version(command_version(cmd))
    }
    if builtin_version_long && arg == "--version" {
      raise_version(command_version(cmd))
    }
    if should_parse_as_positional(
        arg, positionals, positional_values, long_index, short_index,
      ) {
      positional_values.push(arg)
      positional_arg_found = true
      i = i + 1
      continue
    }
    if arg.has_prefix("--") {
      let (name, inline) = split_long(arg)
      if builtin_help_long && name == "help" {
        if inline is Some(_) {
          raise ArgParseError::InvalidArgument(arg)
        }
        raise_context_help(cmd, inherited_globals)
      }
      if builtin_version_long && name == "version" {
        if inline is Some(_) {
          raise ArgParseError::InvalidArgument(arg)
        }
        raise_version(command_version(cmd))
      }
      match long_index.get(name) {
        None =>
          // Support `--no-<flag>` when the underlying flag is marked `negatable`.
          if name is [.. "no-", .. target] &&
            long_index.get(target.to_string())
            is Some({ info: Flag(negatable=true, action~, ..), .. } as spec) {
            if inline is Some(_) {
              raise ArgParseError::InvalidArgument(arg)
            }
            let value = match action {
              SetFalse => true
              _ => false
            }
            if action is Count {
              matches.counts[spec.name] = 0
            }
            matches.flags[spec.name] = value
            matches.flag_sources[spec.name] = Argv
          } else {
            raise_unknown_long(name, long_index)
          }
        Some(spec) =>
          if spec.info is (Option(_) | Positional(_)) {
            check_duplicate_set_occurrence(matches, spec)
            if inline is Some(v) {
              assign_value(matches, spec, v, Argv)
            } else {
              let can_take_next = i + 1 < argv.length() &&
                !should_stop_option_value(
                  argv[i + 1],
                  spec,
                  long_index,
                  short_index,
                )
              if can_take_next {
                i = i + 1
                assign_value(matches, spec, argv[i], Argv)
              } else {
                raise ArgParseError::MissingValue("--\{name}")
              }
            }
          } else {
            if inline is Some(_) {
              raise ArgParseError::InvalidArgument(arg)
            }
            match spec.info {
              Flag(action=Help, ..) =>
                raise_context_help(cmd, inherited_globals)
              Flag(action=Version, ..) =>
                raise_version(
                  version_text_for_long_action(
                    cmd, name, inherited_version_long,
                  ),
                )
              _ => apply_flag(matches, spec, Argv)
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
          raise_context_help(cmd, inherited_globals)
        }
        if short == 'V' && builtin_version_short {
          raise_version(command_version(cmd))
        }
        let spec = match short_index.get(short) {
          Some(v) => v
          None => raise_unknown_short(short, short_index)
        }
        if spec.info is (Option(_) | Positional(_)) {
          check_duplicate_set_occurrence(matches, spec)
          if pos + 1 < arg.length() {
            let rest = arg.unsafe_substring(start=pos + 1, end=arg.length())
            let inline = match rest.strip_prefix("=") {
              Some(view) => view.to_string()
              None => rest
            }
            assign_value(matches, spec, inline, Argv)
          } else {
            let can_take_next = i + 1 < argv.length() &&
              !should_stop_option_value(
                argv[i + 1],
                spec,
                long_index,
                short_index,
              )
            if can_take_next {
              i = i + 1
              assign_value(matches, spec, argv[i], Argv)
            } else {
              raise ArgParseError::MissingValue("-\{short}")
            }
          }
          break
        } else {
          match spec.info {
            Flag(action=Help, ..) => raise_context_help(cmd, inherited_globals)
            Flag(action=Version, ..) =>
              raise_version(
                version_text_for_short_action(
                  cmd, short, inherited_version_short,
                ),
              )
            _ => apply_flag(matches, spec, Argv)
          }
        }
        pos = pos + short.utf16_len()
      }
      i = i + 1
      continue
    }
    if help_subcommand_enabled(cmd) && arg == "help" {
      if positional_arg_found {
        raise_subcommand_conflict("help")
      }
      let rest = argv[i + 1:].to_array()
      let (target, target_globals) = resolve_help_target(
        cmd, rest, builtin_help_short, builtin_help_long, inherited_globals,
      )
      let text = render_help_for_context(target, target_globals)
      raise_help(text)
    }
    if subcommands.iter().find_first(sub => sub.name == arg) is Some(sub) {
      if positional_arg_found {
        raise_subcommand_conflict(sub.name)
      }
      let rest = argv[i + 1:].to_array()
      let sub_matches = parse_command(
        sub, rest, env, child_globals, child_version_long, child_version_short,
      )
      let child_local_non_globals = collect_non_global_names(sub.args)
      matches.parsed_subcommand = Some((sub.name, sub_matches))
      // Merge argv-provided globals from the subcommand parse into the parent
      // so globals work even when they appear after the subcommand name.
      merge_globals_from_child(
        matches, sub_matches, child_globals, child_local_non_globals,
      )
      let env_args = inherited_globals + args
      let parent_matches = finalize_matches(
        cmd, args, groups, matches, positionals, positional_values, env_args, env,
      )
      validate_relationships(parent_matches, args)
      match parent_matches.parsed_subcommand {
        Some((sub_name, sub_m)) => {
          // After parent parsing, copy the final globals into the subcommand.
          propagate_globals_to_child(
            parent_matches, sub_m, child_globals, child_local_non_globals,
          )
          parent_matches.parsed_subcommand = Some((sub_name, sub_m))
        }
        None => ()
      }
      return parent_matches
    }

    positional_values.push(arg)
    positional_arg_found = true
    i = i + 1
  }
  let env_args = inherited_globals + args
  let final_matches = finalize_matches(
    cmd, args, groups, matches, positionals, positional_values, env_args, env,
  )
  validate_relationships(final_matches, args)
  final_matches
}

///|
fn finalize_matches(
  cmd : Command,
  args : Array[Arg],
  groups : Array[ArgGroup],
  matches : Matches,
  positionals : Array[Arg],
  positional_values : Array[String],
  env_args : Array[Arg],
  env : Map[String, String],
) -> Matches raise ArgParseError {
  assign_positionals(matches, positionals, positional_values)
  apply_env(matches, env_args, env)
  apply_defaults(matches, env_args)
  validate_values(args, matches)
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
fn command_version(cmd : Command) -> String {
  cmd.version.unwrap_or("")
}

///|
fn version_text_for_long_action(
  cmd : Command,
  long : String,
  inherited_version_long : Map[String, String],
) -> String {
  for arg in cmd.args {
    if arg.info is Flag(long=Some(name), action=Version, ..) && name == long {
      return command_version(cmd)
    }
  }
  inherited_version_long.get(long).unwrap_or(command_version(cmd))
}

///|
fn version_text_for_short_action(
  cmd : Command,
  short : Char,
  inherited_version_short : Map[Char, String],
) -> String {
  for arg in cmd.args {
    if arg.info is Flag(short=Some(value), action=Version, ..) && value == short {
      return command_version(cmd)
    }
  }
  inherited_version_short.get(short).unwrap_or(command_version(cmd))
}
