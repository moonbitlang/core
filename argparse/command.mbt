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

  fn new(
    name : String,
    args? : Array[&ArgLike],
    subcommands? : Array[Command],
    about? : String,
    version? : String,
    disable_help_flag? : Bool,
    disable_version_flag? : Bool,
    disable_help_subcommand? : Bool,
    arg_required_else_help? : Bool,
    subcommand_required? : Bool,
    hidden? : Bool,
    groups? : Array[ArgGroup],
  ) -> Command
}

///|
pub fn Command::new(
  name : String,
  args? : Array[&ArgLike] = [],
  subcommands? : Array[Command] = [],
  about? : String,
  version? : String,
  disable_help_flag? : Bool = false,
  disable_version_flag? : Bool = false,
  disable_help_subcommand? : Bool = false,
  arg_required_else_help? : Bool = false,
  subcommand_required? : Bool = false,
  hidden? : Bool = false,
  groups? : Array[ArgGroup] = [],
) -> Command {
  Command::{
    name,
    args: args.map(x => x.to_arg()),
    groups: groups.copy(),
    subcommands: subcommands.copy(),
    about,
    version,
    disable_help_flag,
    disable_version_flag,
    disable_help_subcommand,
    arg_required_else_help,
    subcommand_required,
    hidden,
  }
}

///|
/// Render help text without parsing.
pub fn Command::render_help(self : Command) -> String {
  render_help(self)
}

///|
/// Parse argv/environment according to this command spec.
pub fn Command::parse(
  self : Command,
  argv? : Array[String] = default_argv(),
  env? : Map[String, String] = {},
) -> Matches raise {
  let raw = parse_command(self, argv, env, [])
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
    match raw.values.get(name) {
      Some(vs) => values[name] = vs.copy()
      None => ()
    }
    let count = raw.counts.get(name).unwrap_or(0)
    if count > 0 {
      flag_counts[name] = count
    }
    let source = match raw.flag_sources.get(name) {
      Some(v) => Some(v)
      None =>
        match raw.value_sources.get(name) {
          Some(vs) => highest_source(vs)
          None => None
        }
    }
    match source {
      Some(source) => {
        sources[name] = source
        if is_flag_spec(spec) {
          if is_count_flag_spec(spec) {
            flags[name] = count > 0
          } else {
            flags[name] = raw.flags.get(name).unwrap_or(false)
          }
        }
      }
      None => ()
    }
  }
  let child_globals = inherited_globals +
    cmd.args.filter(arg => {
      arg.global && (arg.long is Some(_) || arg.short is Some(_))
    })

  let subcommand = match raw.parsed_subcommand {
    Some((name, sub_raw)) =>
      match find_decl_subcommand(cmd.subcommands, name) {
        Some(sub_spec) =>
          Some((name, build_matches(sub_spec, sub_raw, child_globals)))
        None =>
          Some(
            (
              name,
              Matches::{
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

  Matches::{
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
fn command_groups(cmd : Command) -> Array[ArgGroup] {
  let groups = cmd.groups.copy()
  for arg in cmd.args {
    match arg.group {
      Some(group_name) =>
        add_arg_to_group_membership(groups, group_name, arg_name(arg))
      None => ()
    }
  }
  groups
}

///|
fn add_arg_to_group_membership(
  groups : Array[ArgGroup],
  group_name : String,
  arg_name : String,
) -> Unit {
  let mut idx : Int? = None
  for i = 0; i < groups.length(); i = i + 1 {
    if groups[i].name == group_name {
      idx = Some(i)
      break
    }
  }
  match idx {
    Some(i) => {
      if groups[i].args.contains(arg_name) {
        return
      }
      let args = [..groups[i].args, arg_name]
      groups[i] = ArgGroup::{ ..groups[i], args, }
    }
    None =>
      groups.push(ArgGroup::{
        name: group_name,
        required: false,
        multiple: true,
        args: [arg_name],
        requires: [],
        conflicts_with: [],
      })
  }
}
