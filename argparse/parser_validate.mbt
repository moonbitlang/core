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
priv struct ValidationCtx {
  inherited_global_names : @set.Set[String]
  seen_names : @set.Set[String]
  seen_long : @set.Set[String]
  seen_short : @set.Set[Char]
  seen_positional_indices : @set.Set[Int]
  args : Array[Arg]
}

///|
fn ValidationCtx::new(
  inherited_global_names? : @set.Set[String] = @set.new(),
) -> ValidationCtx {
  {
    inherited_global_names: inherited_global_names.copy(),
    seen_names: @set.new(),
    seen_long: @set.new(),
    seen_short: @set.new(),
    seen_positional_indices: @set.new(),
    args: [],
  }
}

///|
fn ValidationCtx::record_arg(
  self : ValidationCtx,
  arg : Arg,
) -> Unit raise ArgBuildError {
  if !self.seen_names.add_and_check(arg.name) {
    raise Unsupported("duplicate arg name: \{arg.name}")
  }
  if !arg.global && self.inherited_global_names.contains(arg.name) {
    raise Unsupported(
      "arg '\{arg.name}' shadows an inherited global; rename the arg or mark it global",
    )
  }
  fn check_long(name) raise _ {
    if !self.seen_long.add_and_check(name) {
      raise ArgBuildError::Unsupported("duplicate long option: --\{name}")
    }
  }
  fn check_short(short) raise _ {
    if !self.seen_short.add_and_check(short) {
      raise ArgBuildError::Unsupported("duplicate short option: -\{short}")
    }
  }
  match arg.info {
    Flag(long~, short~, negatable~, ..) => {
      if long is Some(name) {
        check_long(name)
        if negatable {
          check_long("no-\{name}")
        }
      }
      if short is Some(short) {
        check_short(short)
      }
    }
    Option(long~, short~, ..) => {
      if long is Some(name) {
        check_long(name)
      }
      if short is Some(short) {
        check_short(short)
      }
    }
    Positional(index~, ..) =>
      if index is Some(index) &&
        !self.seen_positional_indices.add_and_check(index) {
        raise Unsupported("duplicate positional index: \{index}")
      }
  }
  self.args.push(arg)
}

///|
fn ValidationCtx::finalize(self : ValidationCtx) -> Unit raise ArgBuildError {
  validate_requires_conflicts_targets(self.args, self.seen_names)
  validate_indexed_positional_num_args(self.args)
}

///|
fn validate_command(
  cmd : Command,
  args : Array[Arg],
  groups : Array[ArgGroup],
  inherited_global_names : @set.Set[String],
) -> Unit raise ArgBuildError {
  match cmd.build_error {
    Some(err) => raise err
    None => ()
  }
  validate_inherited_global_shadowing(args, inherited_global_names)
  validate_group_defs(args, groups)
  validate_group_refs(args, groups)
  validate_subcommand_defs(cmd.subcommands)
  validate_subcommand_required_policy(cmd)
  validate_help_subcommand(cmd)
  validate_version_actions(cmd)
  let child_inherited_global_names = inherited_global_names.copy()
  for global in collect_globals(args) {
    child_inherited_global_names.add(global.name)
  }
  for sub in cmd.subcommands {
    validate_command(sub, sub.args, sub.groups, child_inherited_global_names)
  }
}

///|
fn validate_inherited_global_shadowing(
  args : Array[Arg],
  inherited_global_names : @set.Set[String],
) -> Unit raise ArgBuildError {
  for arg in args {
    if arg.global {
      continue
    }
    if inherited_global_names.contains(arg.name) {
      raise Unsupported(
        "arg '\{arg.name}' shadows an inherited global; rename the arg or mark it global",
      )
    }
  }
}

///|
fn validate_indexed_positional_num_args(
  args : Array[Arg],
) -> Unit raise ArgBuildError {
  let positionals = positional_args(args)
  if positionals.length() <= 1 {
    return
  }
  let mut idx = 0
  while idx + 1 < positionals.length() {
    let arg = positionals[idx]
    guard arg.info is Positional(index~, num_args~, ..)
    if index is Some(_) && num_args is Some(range) {
      if !(range is { lower: 1, upper: Some(1) }) {
        raise Unsupported(
          "indexed positional '\{arg.name}' cannot set num_args unless it is the last positional or exactly 1..1",
        )
      }
    }
    idx = idx + 1
  }
}

///|
fn validate_flag_arg(
  arg : Arg,
  ctx : ValidationCtx,
) -> Unit raise ArgBuildError {
  validate_named_option_arg(arg)
  guard arg.info is Flag(action~, negatable~, ..)
  if action is (Help | Version) {
    guard !negatable else {
      raise Unsupported("help/version actions do not support negatable")
    }
    guard arg.env is None else {
      raise Unsupported("help/version actions do not support env/defaults")
    }
    guard !arg.multiple else {
      raise Unsupported("help/version actions do not support multiple values")
    }
  }
  ctx.record_arg(arg)
}

///|
fn validate_option_arg(
  arg : Arg,
  ctx : ValidationCtx,
) -> Unit raise ArgBuildError {
  validate_named_option_arg(arg)
  validate_default_values(arg)
  ctx.record_arg(arg)
}

///|
fn validate_positional_arg(
  arg : Arg,
  ctx : ValidationCtx,
) -> Unit raise ArgBuildError {
  let (min, max) = arg_min_max_for_validate(arg)
  if (min > 1 || (max is Some(m) && m > 1)) && !arg.multiple {
    raise Unsupported(
      "multiple values require action=Append or num_args allowing >1",
    )
  }
  validate_default_values(arg)
  ctx.record_arg(arg)
}

///|
fn validate_named_option_arg(arg : Arg) -> Unit raise ArgBuildError {
  guard arg.info is (Flag(long~, short~, ..) | Option(long~, short~, ..))
  guard long is Some(_) || short is Some(_) else {
    raise Unsupported("flag/option args require short/long")
  }
}

///|
fn validate_default_values(arg : Arg) -> Unit raise ArgBuildError {
  if arg.info is (Option(default_values~, ..) | Positional(default_values~, ..)) &&
    default_values is Some(values) &&
    values.length() > 1 &&
    !arg.multiple &&
    !(arg.info is Option(action=Append, ..)) {
    raise Unsupported(
      "default_values with multiple entries require action=Append",
    )
  }
}

///|
fn validate_group_defs(
  args : Array[Arg],
  groups : Array[ArgGroup],
) -> Unit raise ArgBuildError {
  let seen : @set.Set[String] = @set.new()
  let arg_seen : @set.Set[String] = @set.new()
  for arg in args {
    arg_seen.add(arg.name)
  }
  for group in groups {
    if !seen.add_and_check(group.name) {
      raise Unsupported("duplicate group: \{group.name}")
    }
  }
  for group in groups {
    for required in group.requires {
      if required == group.name {
        raise Unsupported("group cannot require itself: \{group.name}")
      }
      if !seen.contains(required) && !arg_seen.contains(required) {
        raise Unsupported(
          "unknown group requires target: \{group.name} -> \{required}",
        )
      }
    }
    for conflict in group.conflicts_with {
      if conflict == group.name {
        raise Unsupported("group cannot conflict with itself: \{group.name}")
      }
      if !seen.contains(conflict) && !arg_seen.contains(conflict) {
        raise Unsupported(
          "unknown group conflicts_with target: \{group.name} -> \{conflict}",
        )
      }
    }
  }
}

///|
fn validate_group_refs(
  args : Array[Arg],
  groups : Array[ArgGroup],
) -> Unit raise ArgBuildError {
  if groups.length() == 0 {
    return
  }
  let arg_index : @set.Set[String] = @set.new()
  for arg in args {
    arg_index.add(arg.name)
  }
  for group in groups {
    for name in group.args {
      if !arg_index.contains(name) {
        raise Unsupported("unknown group arg: \{group.name} -> \{name}")
      }
    }
  }
}

///|
fn validate_requires_conflicts_targets(
  args : Array[Arg],
  seen_names : @set.Set[String],
) -> Unit raise ArgBuildError {
  for arg in args {
    for required in arg.requires {
      if required == arg.name {
        raise Unsupported("arg cannot require itself: \{arg.name}")
      }
      if !seen_names.contains(required) {
        raise Unsupported("unknown requires target: \{arg.name} -> \{required}")
      }
    }
    for conflict in arg.conflicts_with {
      if conflict == arg.name {
        raise Unsupported("arg cannot conflict with itself: \{arg.name}")
      }
      if !seen_names.contains(conflict) {
        raise Unsupported(
          "unknown conflicts_with target: \{arg.name} -> \{conflict}",
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
  let seen : @set.Set[String] = @set.new()
  for sub in subs {
    if !seen.add_and_check(sub.name) {
      raise Unsupported("duplicate subcommand: \{sub.name}")
    }
  }
}

///|
fn validate_subcommand_required_policy(
  cmd : Command,
) -> Unit raise ArgBuildError {
  if cmd.subcommand_required && cmd.subcommands.length() == 0 {
    raise Unsupported("subcommand_required requires at least one subcommand")
  }
}

///|
fn validate_help_subcommand(cmd : Command) -> Unit raise ArgBuildError {
  if help_subcommand_enabled(cmd) &&
    cmd.subcommands.any(cmd => cmd.name == "help") {
    raise Unsupported(
      "subcommand name reserved for built-in help: help (disable with disable_help_subcommand)",
    )
  }
}

///|
fn validate_version_actions(cmd : Command) -> Unit raise ArgBuildError {
  if cmd.version is None &&
    cmd.args.any(arg => arg.info is Flag(action=Version, ..)) {
    raise Unsupported("version action requires command version text")
  }
}

///|
fn validate_command_policies(
  cmd : Command,
  matches : Matches,
) -> Unit raise ArgParseError {
  if cmd.subcommand_required &&
    cmd.subcommands.length() > 0 &&
    matches.parsed_subcommand is None {
    raise MissingRequired("subcommand")
  }
}

///|
fn validate_groups(
  args : Array[Arg],
  groups : Array[ArgGroup],
  matches : Matches,
) -> Unit raise ArgParseError {
  if groups.length() == 0 {
    return
  }
  let group_presence : Map[String, Int] = {}
  let group_seen : @set.Set[String] = @set.new()
  let arg_seen : @set.Set[String] = @set.new()
  for group in groups {
    group_seen.add(group.name)
  }
  for arg in args {
    arg_seen.add(arg.name)
  }
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
      raise MissingGroup(group.name)
    }
    if !group.multiple && count > 1 {
      raise GroupConflict(group.name)
    }
  }
  for group in groups {
    let count = group_presence[group.name]
    if count == 0 {
      continue
    }
    for required in group.requires {
      if group_seen.contains(required) {
        if group_presence.get(required).unwrap_or(0) == 0 {
          raise MissingGroup(required)
        }
      } else if arg_seen.contains(required) {
        if !matches_has_value_or_flag(matches, required) {
          raise MissingRequired(required)
        }
      }
    }
    for conflict in group.conflicts_with {
      if group_seen.contains(conflict) {
        if group_presence.get(conflict).unwrap_or(0) > 0 {
          raise GroupConflict("\{group.name} conflicts with \{conflict}")
        }
      } else if arg_seen.contains(conflict) {
        if matches_has_value_or_flag(matches, conflict) {
          raise GroupConflict("\{group.name} conflicts with \{conflict}")
        }
      }
    }
  }
}

///|
fn arg_in_group(arg : Arg, group : ArgGroup) -> Bool {
  group.args.contains(arg.name)
}

///|
fn validate_values(
  args : Array[Arg],
  matches : Matches,
) -> Unit raise ArgParseError {
  for arg in args {
    let present = matches_has_value_or_flag(matches, arg.name)
    if arg.required && !present {
      raise MissingRequired(arg.name)
    }
    guard arg.info is (Option(_) | Positional(_)) else { continue }
    if !present {
      if arg.info is Positional(_) {
        let (min, _) = arg_min_max(arg)
        if min > 0 {
          raise TooFewValues(arg.name, 0, min)
        }
      }
      continue
    }
    let values = matches.values.get(arg.name).unwrap_or([])
    let count = values.length()
    let (min, max) = arg_min_max(arg)
    if count < min {
      raise TooFewValues(arg.name, count, min)
    }
    if !(arg.info is Option(action=Append, ..)) {
      match max {
        Some(max) if count > max => raise TooManyValues(arg.name, count, max)
        _ => ()
      }
    }
  }
}

///|
fn validate_relationships(
  matches : Matches,
  args : Array[Arg],
) -> Unit raise ArgParseError {
  for arg in args {
    if !matches_has_value_or_flag(matches, arg.name) {
      continue
    }
    for required in arg.requires {
      if !matches_has_value_or_flag(matches, required) {
        raise MissingRequired(required)
      }
    }
    for conflict in arg.conflicts_with {
      if matches_has_value_or_flag(matches, conflict) {
        raise InvalidArgument(
          "conflicting arguments: \{arg.name} and \{conflict}",
        )
      }
    }
  }
}
