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
  for arg in globals.iter() + args.iter() {
    if arg.info is (Flag(long~, ..) | Option(long~, ..)) && long is Some(name) {
      index[name] = arg
    }
  }
  index
}

///|
fn build_short_index(globals : Array[Arg], args : Array[Arg]) -> Map[Char, Arg] {
  let index : Map[Char, Arg] = {}
  for arg in globals.iter() + args.iter() {
    if arg.info is (Flag(short~, ..) | Option(short~, ..)) &&
      short is Some(value) {
      index[value] = arg
    }
  }
  index
}

///|
fn collect_globals(args : Array[Arg]) -> Array[Arg] {
  args.filter(arg => arg.global && arg.info is (Flag(_) | Option(_)))
}

///|
fn collect_non_global_names(args : Array[Arg]) -> @set.Set[String] {
  @set.from_iter(args.iter().filter(arg => !arg.global).map(arg => arg.name))
}

///|
fn resolve_help_target(
  cmd : Command,
  argv : ArrayView[String],
  builtin_help_short : Bool,
  builtin_help_long : Bool,
  inherited_globals : Array[Arg],
  command_path : String,
) -> (Command, Array[Arg], String) raise ArgParseError {
  let targets = match argv {
    [.. pre, "-h"] if builtin_help_short => pre
    [.. pre, "--help"] if builtin_help_long => pre
    _ => argv
  }
  let mut current = cmd
  let mut current_path = command_path
  let mut current_globals = inherited_globals
  for name in targets {
    if name.has_prefix("-") {
      raise InvalidArgument("unexpected help argument: \{name}")
    }
    guard current.subcommands.iter().find_first(sub => sub.name == name)
      is Some(sub) else {
      raise InvalidArgument("unknown subcommand: \{name}")
    }
    current_globals = current_globals + collect_globals(current.args)
    current = sub
    current_path = if current_path == "" {
      sub.name
    } else {
      "\{current_path} \{sub.name}"
    }
  }
  (current, current_globals, current_path)
}
