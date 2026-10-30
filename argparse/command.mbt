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
  priv default_subcommand : String?
  priv hidden : Bool
  priv mut build_error : ArgBuildError?
} derive(@debug.Debug)

///|
/// Create a declarative command specification.
///
/// Notes:
/// - `flags`, `options`, and `positionals` declare arguments by kind.
/// - `groups` declares argument-group membership and policies.
/// - `disable_help_flag` / `disable_version_flag` disable built-in
///   `--help` / `--version`.
/// - `disable_help_subcommand` disables built-in `help <subcommand>` routing.
/// - `arg_required_else_help=true` prints help when no argv tokens are provided.
/// - `subcommand_required=true` requires selecting a subcommand.
/// - `default_subcommand` dispatches missing subcommands to a visible child.
/// - `hidden=true` omits this command from parent command listings.
#alias(new, deprecated="Use `Command()` instead")
pub fn Command::Command(
  name : StringView,
  flags~ : ArrayView[FlagArg] = [],
  options~ : ArrayView[OptionArg] = [],
  positionals~ : ArrayView[PositionArg] = [],
  subcommands~ : ArrayView[Command] = [],
  about? : StringView,
  version? : StringView,
  disable_help_flag~ : Bool = false,
  disable_version_flag~ : Bool = false,
  disable_help_subcommand~ : Bool = false,
  arg_required_else_help~ : Bool = false,
  subcommand_required~ : Bool = false,
  hidden~ : Bool = false,
  groups~ : ArrayView[ArgGroup] = [],
  default_subcommand? : StringView,
) -> Command {
  let (parsed_args, arg_error) = collect_args(flags, options, positionals)
  let groups = groups.to_owned()
  let cmd = Command::{
    name: name.to_owned(),
    args: parsed_args,
    groups,
    subcommands: subcommands.to_owned(),
    about: about.map(v => v.to_owned()),
    version: version.map(v => v.to_owned()),
    disable_help_flag,
    disable_version_flag,
    disable_help_subcommand,
    arg_required_else_help,
    subcommand_required,
    default_subcommand: default_subcommand.map(v => v.to_owned()),
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
/// A successful argument parse or a request to display help or version text.
/// `Help` and `Version` contain the text printed by `Command::parse`, without
/// the final newline added when printing.
pub(all) enum ParseOutcome {
  /// Parsed arguments, ready for the command to execute.
  Parsed(Matches)
  /// A request for command or subcommand help.
  Help(String)
  /// A request for version information.
  Version(String)
}

///|
/// Parse explicit arguments without reading process state, printing, exiting,
/// or raising errors. The command, arguments, and environment map are not mutated.
///
/// `argv` excludes the program name and is required. Environment values come
/// only from `env`, which defaults to empty. Precedence is
/// `argv > env > default_values`.
///
/// Help and version requests return `Ok(Help(text))` and `Ok(Version(text))`.
/// Failures return `Err(error)` with display-ready text: parse errors include
/// contextual help, while command-definition errors contain only validation text.
/// Errors are ordinary return values so callers can handle every outcome without
/// an error effect.
/// Use `Command::parse` for automatic process arguments and help/version exit.
///
/// ```mbt check
/// test {
///   let cmd = @argparse.Command("demo", version="1.0.0")
///   match cmd.parse_as_result(argv=["--version"]) {
///     Ok(Version(text)) => inspect(text, content="1.0.0")
///     _ => fail("expected a version request")
///   }
/// }
/// ```
#as_free_fn
#warnings("-result_error_return")
pub fn Command::parse_as_result(
  self : Command,
  argv~ : ArrayView[String],
  env~ : Map[String, String] = Map([]),
) -> Result[ParseOutcome, Error] {
  try {
    let raw = parse_command(self, argv, env, [], Map([]), Map([]), self.name)
    Ok(Parsed(build_matches(self, raw, [])))
  } catch {
    DisplayHelp::Message(text) => Ok(Help(trim_single_trailing_newline(text)))
    DisplayVersion::Message(text) =>
      Ok(Version(trim_single_trailing_newline(text)))
    err => Err(err)
  }
}

///|
/// Parse argv/environment according to this command spec.
///
/// Behavior:
/// - Help/version requests print output immediately and terminate with exit code
///   `0`. Use `Command::parse_as_result` to receive results without these effects.
/// - Parse failures raise display-ready error text with full contextual help.
/// - Command-definition validation failures raise display-ready validation
///   text (without appended help).
///
/// Explicit `argv` contains only arguments, without the program name. By default,
/// the runtime command line is used with its executable prefix removed (including
/// the script path on JavaScript/Node).
/// Environment values are read only from the supplied `env` map, which defaults
/// to empty; pass `@env.get_env_vars()` to use the process environment.
/// Value precedence is `argv > env > default_values`.
#as_free_fn
pub fn Command::parse(
  self : Command,
  argv~ : ArrayView[String] = default_argv(),
  env~ : Map[String, String] = Map([]),
) -> Matches raise {
  try {
    let raw = parse_command(self, argv, env, [], Map([]), Map([]), self.name)
    build_matches(self, raw, [])
  } catch {
    DisplayHelp::Message(text) => print_and_exit_success(text)
    DisplayVersion::Message(text) => print_and_exit_success(text)
    ArgError::Message(_) as err => raise err
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
fn build_matches(
  cmd : Command,
  raw : Matches,
  inherited_globals : Array[Arg],
) -> Matches {
  let flags = Map([])
  let values = Map([])
  let flag_counts = Map([])
  let sources = Map([])
  let specs = inherited_globals + cmd.args

  for spec in specs {
    let name = spec.name
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
      if spec.info is FlagInfo(action~, ..) {
        if action is Count {
          flags[name] = count > 0
        } else {
          flags[name] = raw.flags.get(name).unwrap_or(false)
        }
      }
    }
  }
  let child_globals = merge_global_defs(
    inherited_globals,
    collect_globals(cmd.args),
  )

  let subcommand = match raw.parsed_subcommand {
    Some((name, sub_raw)) =>
      if cmd.subcommands.iter().find_first(sub => sub.name == name)
        is Some(sub_spec) {
        Some((name, build_matches(sub_spec, sub_raw, child_globals)))
      } else {
        Some((name, new_matches_parse_state()))
      }
    None => None
  }

  {
    flags,
    values,
    flag_counts,
    sources,
    subcommand,
    counts: Map([]),
    flag_sources: Map([]),
    value_sources: Map([]),
    parsed_subcommand: None,
  }
}

///|
fn collect_args(
  flags : ArrayView[FlagArg],
  options : ArrayView[OptionArg],
  positionals : ArrayView[PositionArg],
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
  let first_error : ArgBuildError? = for
    flag in flags
    first_error = (None : ArgBuildError?) {
    validate_flag_arg(flag.arg, ctx) catch {
      err => if first_error is None { continue Some(err) }
    }
    continue first_error
  } nobreak {
    first_error
  }
  let first_error : ArgBuildError? = for
    option in options
    first_error = first_error {
    validate_option_arg(option.arg, ctx) catch {
      err => if first_error is None { continue Some(err) }
    }
    continue first_error
  } nobreak {
    first_error
  }
  let first_error : ArgBuildError? = for
    positional in positionals
    first_error = first_error {
    validate_positional_arg(positional.arg, ctx) catch {
      err => if first_error is None { continue Some(err) }
    }
    continue first_error
  } nobreak {
    first_error
  }
  let first_error = if first_error is None {
    try {
      ctx.finalize()
      None
    } catch {
      err => Some(err)
    }
  } else {
    first_error
  }
  (args, first_error)
}
