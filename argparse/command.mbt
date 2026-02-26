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
  priv groups : Array[ArgGroup]
  priv subcommands : Array[Command]
  priv about : String?
  priv version : String?
  priv disable_help_flag : Bool
  priv disable_version_flag : Bool
  priv disable_help_subcommand : Bool
  priv arg_required_else_help : Bool
  priv subcommand_required : Bool
  priv hidden : Bool
  priv mut build_error : ArgBuildError?

  /// Create a declarative command specification.
  fn new(
    name : StringView,
    flags? : ArrayView[FlagArg],
    options? : ArrayView[OptionArg],
    positionals? : ArrayView[PositionalArg],
    subcommands? : ArrayView[Command],
    about? : StringView,
    version? : StringView,
    disable_help_flag? : Bool,
    disable_version_flag? : Bool,
    disable_help_subcommand? : Bool,
    arg_required_else_help? : Bool,
    subcommand_required? : Bool,
    hidden? : Bool,
    groups? : ArrayView[ArgGroup],
  ) -> Command
}

///|
/// Create a declarative command specification.
///
/// Notes:
/// - `flags` / `options` / `positionals` declare command arguments by kind.
/// - `groups` explicitly declares all group memberships and policies.
/// - Built-in `--help`/`--version` behavior can be disabled with the flags below.
pub fn Command::new(
  name : StringView,
  flags? : ArrayView[FlagArg] = [],
  options? : ArrayView[OptionArg] = [],
  positionals? : ArrayView[PositionalArg] = [],
  subcommands? : ArrayView[Command] = [],
  about? : StringView,
  version? : StringView,
  disable_help_flag? : Bool = false,
  disable_version_flag? : Bool = false,
  disable_help_subcommand? : Bool = false,
  arg_required_else_help? : Bool = false,
  subcommand_required? : Bool = false,
  hidden? : Bool = false,
  groups? : ArrayView[ArgGroup] = [],
) -> Command {
  let (parsed_args, arg_error) = collect_args(flags, options, positionals)
  let groups = groups.to_array()
  let cmd = Command::{
    name: name.to_string(),
    args: parsed_args,
    groups,
    subcommands: subcommands.to_array(),
    about: about.map(v => v.to_string()),
    version: version.map(v => v.to_string()),
    disable_help_flag,
    disable_version_flag,
    disable_help_subcommand,
    arg_required_else_help,
    subcommand_required,
    hidden,
    build_error: arg_error,
  }
  if cmd.build_error is None {
    validate_command(cmd, parsed_args, groups, []) catch {
      err => cmd.build_error = Some(err)
    }
  }
  cmd
}

///|
/// Render help text without parsing.
pub fn Command::render_help(self : Command) -> String {
  render_help(self)
}

///|
/// Parse argv/environment according to this command spec.
///
/// Error and event model:
/// - Raises `DisplayHelp::Message` / `DisplayVersion::Message` for display
///   actions instead of exiting the process.
/// - Raises `ArgBuildError` when the command definition is invalid.
/// - Raises `ArgParseError` when user input does not satisfy the definition.
///
/// Value precedence is `argv > env > default_values`.
pub fn Command::parse(
  self : Command,
  argv? : ArrayView[String] = default_argv(),
  env? : Map[String, String] = {},
) -> Matches raise {
  let raw = parse_command(self, argv, env, [], {}, {})
  build_matches(self, raw, [])
}

///|
fn build_matches(
  cmd : Command,
  raw : Matches,
  inherited_globals : Array[Arg],
) -> Matches {
  let flags : Map[String, Bool] = {}
  let values : Map[String, Array[String]] = {}
  let flag_counts : Map[String, Int] = {}
  let sources : Map[String, ValueSource] = {}
  let specs = inherited_globals + cmd.args

  for spec in specs {
    let name = arg_name(spec)
    if raw.values.get(name) is Some(vs) {
      values[name] = vs.copy()
    }
    let count = raw.counts.get_or_default(name, 0)
    if count > 0 {
      flag_counts[name] = count
    }
    let source = match raw.flag_sources.get(name) {
      Some(v) => Some(v)
      None => raw.value_sources.get(name)
    }
    if source is Some(source) {
      sources[name] = source
      if spec.info is Flag(action~, ..) {
        if action is Count {
          flags[name] = count > 0
        } else {
          flags[name] = raw.flags.get(name).unwrap_or(false)
        }
      }
    }
  }
  let child_globals = inherited_globals +
    cmd.args.filter(arg => {
      arg.global &&
      arg.info is (Option(long~, short~, ..) | Flag(long~, short~, ..)) &&
      (long is Some(_) || short is Some(_))
    })

  let subcommand = match raw.parsed_subcommand {
    Some((name, sub_raw)) =>
      if find_decl_subcommand(cmd.subcommands, name) is Some(sub_spec) {
        Some((name, build_matches(sub_spec, sub_raw, child_globals)))
      } else {
        Some(
          (
            name,
            {
              flags: {},
              values: {},
              flag_counts: {},
              sources: {},
              subcommand: None,
              counts: {},
              flag_sources: {},
              value_sources: {},
              parsed_subcommand: None,
            },
          ),
        )
      }
    None => None
  }

  {
    flags,
    values,
    flag_counts,
    sources,
    subcommand,
    counts: {},
    flag_sources: {},
    value_sources: {},
    parsed_subcommand: None,
  }
}

///|
fn find_decl_subcommand(subs : Array[Command], name : String) -> Command? {
  for sub in subs {
    if sub.name == name {
      return Some(sub)
    }
  }
  None
}

///|
fn collect_args(
  flags : ArrayView[FlagArg],
  options : ArrayView[OptionArg],
  positionals : ArrayView[PositionalArg],
) -> (Array[Arg], ArgBuildError?) {
  let args : Array[Arg] = []
  for flag in flags {
    args.push(flag.arg)
  }
  for option in options {
    args.push(option.arg)
  }
  for positional in positionals {
    args.push(positional.arg)
  }
  let ctx = ValidationCtx::new()
  let mut first_error : ArgBuildError? = None
  for flag in flags {
    validate_flag_arg(flag.arg, ctx) catch {
      err => if first_error is None { first_error = Some(err) }
    }
  }
  for option in options {
    validate_option_arg(option.arg, ctx) catch {
      err => if first_error is None { first_error = Some(err) }
    }
  }
  for positional in positionals {
    validate_positional_arg(positional.arg, ctx) catch {
      err => if first_error is None { first_error = Some(err) }
    }
  }
  if first_error is None {
    ctx.finalize() catch {
      err => first_error = Some(err)
    }
  }
  (args, first_error)
}
