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
fn[T] raise_help(text : String) -> T raise DisplayHelp {
  raise Message(text)
}

///|
fn[T] raise_version(text : String) -> T raise DisplayVersion {
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
  command_path : String,
) -> String {
  let help_name = if command_path == "" { cmd.name } else { command_path }
  let help_cmd = { ..cmd, args: inherited_globals + cmd.args, name: help_name }
  render_help(help_cmd)
}

///|
fn[T] raise_context_help(
  cmd : Command,
  inherited_globals : Array[Arg],
  command_path : String,
) -> T raise DisplayHelp {
  raise_help(render_help_for_context(cmd, inherited_globals, command_path))
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
fn format_error_with_help(
  msg : String,
  cmd : Command,
  inherited_globals : Array[Arg],
  command_path : String,
) -> String {
  "\{msg}\n\n\{render_help_for_context(cmd, inherited_globals, command_path)}"
}

///|
fn arg_error_for_parse_failure(
  err : ArgParseError,
  cmd : Command,
  inherited_globals : Array[Arg],
  command_path : String,
) -> ArgError {
  Message(
    format_error_with_help(
      err.arg_parse_error_message(),
      cmd,
      inherited_globals,
      command_path,
    ),
  )
}

///|
fn arg_error_for_build_failure(
  err : ArgBuildError,
  cmd : Command,
  inherited_globals : Array[Arg],
  command_path : String,
) -> ArgError {
  Message(
    format_error_with_help(
      err.arg_build_error_message(),
      cmd,
      inherited_globals,
      command_path,
    ),
  )
}

///|
fn parse_command(
  cmd : Command,
  argv : ArrayView[String],
  env : Map[String, String],
  inherited_globals : Array[Arg],
  inherited_version_long : Map[String, String],
  inherited_version_short : Map[Char, String],
  command_path : String,
) -> Matches raise {
  parse_command_impl(
    cmd, argv, env, inherited_globals, inherited_version_long, inherited_version_short,
    command_path,
  ) catch {
    UnknownArgument(arg, hint) =>
      raise arg_error_for_parse_failure(
        UnknownArgument(arg, hint),
        cmd,
        inherited_globals,
        command_path,
      )
    InvalidArgument(msg) =>
      raise arg_error_for_parse_failure(
        InvalidArgument(msg),
        cmd,
        inherited_globals,
        command_path,
      )
    MissingValue(name) =>
      raise arg_error_for_parse_failure(
        MissingValue(name),
        cmd,
        inherited_globals,
        command_path,
      )
    MissingRequired(name, by) =>
      raise arg_error_for_parse_failure(
        MissingRequired(name, by),
        cmd,
        inherited_globals,
        command_path,
      )
    TooFewValues(name, got, min) =>
      raise arg_error_for_parse_failure(
        TooFewValues(name, got, min),
        cmd,
        inherited_globals,
        command_path,
      )
    TooManyValues(name, got, max) =>
      raise arg_error_for_parse_failure(
        TooManyValues(name, got, max),
        cmd,
        inherited_globals,
        command_path,
      )
    TooManyPositionals =>
      raise arg_error_for_parse_failure(
        TooManyPositionals,
        cmd,
        inherited_globals,
        command_path,
      )
    InvalidValue(msg) =>
      raise arg_error_for_parse_failure(
        InvalidValue(msg),
        cmd,
        inherited_globals,
        command_path,
      )
    MissingGroup(name) =>
      raise arg_error_for_parse_failure(
        MissingGroup(name),
        cmd,
        inherited_globals,
        command_path,
      )
    GroupConflict(name) =>
      raise arg_error_for_parse_failure(
        GroupConflict(name),
        cmd,
        inherited_globals,
        command_path,
      )
    Unsupported(msg) =>
      raise arg_error_for_build_failure(
        Unsupported(msg),
        cmd,
        inherited_globals,
        command_path,
      )
    err => raise err
  }
}

///|
fn parse_command_impl(
  cmd : Command,
  argv : ArrayView[String],
  env : Map[String, String],
  inherited_globals : Array[Arg],
  inherited_version_long : Map[String, String],
  inherited_version_short : Map[Char, String],
  command_path : String,
) -> Matches raise {
  match cmd.build_error {
    Some(err) => raise err
    None => ()
  }
  let args = cmd.args
  let groups = cmd.groups
  let subcommands = cmd.subcommands
  if cmd.arg_required_else_help && argv.length() == 0 {
    raise_context_help(cmd, inherited_globals, command_path)
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

  let builtin_help_short = help_flag_enabled(cmd) && !short_index.contains('h')
  let builtin_help_long = help_flag_enabled(cmd) && !long_index.contains("help")
  let builtin_version_short = version_flag_enabled(cmd) &&
    !short_index.contains('V')
  let builtin_version_long = version_flag_enabled(cmd) &&
    !long_index.contains("version")

  let positionals = positional_args(args)
  let positional_values = []
  let last_pos_idx = last_positional_index(positionals)
  let mut positional_arg_found = false

  loop argv {
    [] => ()
    ["--", .. rest_argv] => positional_values.append(rest_argv)
    [arg, .. rest_argv] => {
      let force_positional = last_pos_idx is Some(idx) &&
        positional_values.length() >= idx
      let rest_argv = if force_positional ||
        should_parse_as_positional(
          arg, positionals, positional_values, long_index, short_index,
        ) {
        positional_values.push(arg)
        positional_arg_found = true
        rest_argv
      } else if arg is [.. "--", .. name_value] {
        // name_value is not ""
        let (name, inline) = match name_value.split_once("=") {
          None => (name_value.to_string(), None)
          Some((name, inline)) => (name.to_string(), Some(inline))
        }
        if builtin_help_long && name == "help" {
          guard inline is None else {
            raise ArgParseError::InvalidArgument(arg)
          }
          raise_context_help(cmd, inherited_globals, command_path)
        } else if builtin_version_long && name == "version" {
          guard inline is None else {
            raise ArgParseError::InvalidArgument(arg)
          }
          raise_version(command_version(cmd))
        } else if long_index.get(name) is Some(spec) {
          match spec.info {
            Flag(action~, ..) => {
              guard inline is None else {
                raise ArgParseError::InvalidArgument(arg)
              }
              match action {
                Help => raise_context_help(cmd, inherited_globals, command_path)
                Version =>
                  raise_version(
                    version_text_for_long_action(
                      cmd, name, inherited_version_long,
                    ),
                  )
                _ => {
                  apply_flag(matches, spec, Argv)
                  rest_argv
                }
              }
            }
            Option(_) | Positional(_) => {
              check_duplicate_set_occurrence(matches, spec)
              if inline is Some(v) {
                assign_value(matches, spec, v.to_string(), Argv)
                rest_argv
              } else {
                guard rest_argv is [next, .. rest_argv] &&
                  !should_stop_option_value(next, spec, long_index, short_index) else {
                  raise ArgParseError::MissingValue("--\{name}")
                }
                assign_value(matches, spec, next, Argv)
                rest_argv
              }
            }
          }
          // Support `--no-<flag>` when the underlying flag is marked `negatable`.
        } else if name is [.. "no-", .. target] &&
          long_index.get(target.to_string())
          is Some({ info: Flag(negatable=true, action~, ..), .. } as spec) {
          guard inline is None else {
            raise ArgParseError::InvalidArgument(arg)
          }
          if action is Count {
            matches.counts[spec.name] = 0
          }
          matches.flags[spec.name] = match action {
            SetFalse => true
            _ => false
          }
          matches.flag_sources[spec.name] = Argv
          rest_argv
        } else {
          raise_unknown_long(name, long_index)
        }
      } else if arg is ['-', .. shorts] && shorts is [_, ..] {
        // Parse short groups like `-abc` and short values like `-c3`.
        inner~: loop shorts {
          [] => rest_argv
          ['h', ..] if builtin_help_short =>
            raise_context_help(cmd, inherited_globals, command_path)
          ['V', ..] if builtin_version_short =>
            raise_version(command_version(cmd))
          [short, .. rest_shorts] => {
            guard short_index.get(short) is Some(spec) else {
              raise_unknown_short(short, short_index)
            }
            match spec.info {
              Flag(action=Help, ..) =>
                raise_context_help(cmd, inherited_globals, command_path)
              Flag(action=Version, ..) =>
                raise_version(
                  version_text_for_short_action(
                    cmd, short, inherited_version_short,
                  ),
                )
              Flag(_) => {
                apply_flag(matches, spec, Argv)
                continue inner~ rest_shorts
              }
              Option(_) => {
                check_duplicate_set_occurrence(matches, spec)
                match rest_shorts {
                  [] => {
                    guard rest_argv is [value, .. rest_rest_argv] &&
                      !should_stop_option_value(
                        value, spec, long_index, short_index,
                      ) else {
                      raise ArgParseError::MissingValue("-\{short}")
                    }
                    assign_value(matches, spec, value, Argv)
                    rest_rest_argv
                  }
                  ['=', .. inline] | inline => {
                    assign_value(matches, spec, inline.to_string(), Argv)
                    rest_argv
                  }
                }
              }
              Positional(_) => panic()
            }
          }
        }
      } else if help_subcommand_enabled(cmd) && arg == "help" {
        guard !positional_arg_found else { raise_subcommand_conflict("help") }
        let (target, target_globals, target_path) = resolve_help_target(
          cmd, rest_argv, builtin_help_short, builtin_help_long, inherited_globals,
          command_path,
        )
        raise_context_help(target, target_globals, target_path)
      } else if subcommands.iter().find_first(sub => sub.name == arg)
        is Some(sub) {
        guard !positional_arg_found else { raise_subcommand_conflict(sub.name) }

        let sub_path = if command_path == "" {
          sub.name
        } else {
          "\{command_path} \{sub.name}"
        }
        let sub_matches = parse_command(
          sub, rest_argv, env, child_globals, child_version_long, child_version_short,
          sub_path,
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
        if parent_matches.parsed_subcommand is Some((_, sub_m)) {
          // After parent parsing, copy the final globals into the subcommand.
          propagate_globals_to_child(
            parent_matches, sub_m, child_globals, child_local_non_globals,
          )
        }
        return parent_matches
      } else { // arg is positional
        positional_values.push(arg)
        positional_arg_found = true
        rest_argv
      }
      continue rest_argv
    }
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
