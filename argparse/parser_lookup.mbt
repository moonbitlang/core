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
fn build_long_index(
  globals : Array[Arg],
  args : Array[Arg],
) -> Map[String, Arg] {
  let index : Map[String, Arg] = {}
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
fn build_short_index(globals : Array[Arg], args : Array[Arg]) -> Map[Char, Arg] {
  let index : Map[Char, Arg] = {}
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
fn collect_globals(args : Array[Arg]) -> Array[Arg] {
  args.filter(arg => arg.global && (arg.long is Some(_) || arg.short is Some(_)))
}

///|
fn collect_non_global_names(args : Array[Arg]) -> @set.Set[String] {
  @set.from_iter(args.iter().filter(arg => !arg.global).map(arg => arg.name))
}

///|
fn resolve_help_target(
  cmd : Command,
  argv : Array[String],
  builtin_help_short : Bool,
  builtin_help_long : Bool,
  inherited_globals : Array[Arg],
) -> (Command, Array[Arg]) raise ArgParseError {
  let targets = if argv.length() == 0 {
    argv
  } else {
    let last = argv[argv.length() - 1]
    if (last == "-h" && builtin_help_short) ||
      (last == "--help" && builtin_help_long) {
      argv[:argv.length() - 1].to_array()
    } else {
      argv
    }
  }
  let mut current = cmd
  let mut current_globals = inherited_globals
  let mut subs = cmd.subcommands
  for name in targets {
    if name.has_prefix("-") {
      raise ArgParseError::InvalidArgument("unexpected help argument: \{name}")
    }
    guard subs.iter().find_first(sub => sub.name == name) is Some(sub) else {
      raise ArgParseError::InvalidArgument("unknown subcommand: \{name}")
    }
    current_globals = current_globals + collect_globals(current.args)
    current = sub
    subs = sub.subcommands
  }
  (current, current_globals)
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
