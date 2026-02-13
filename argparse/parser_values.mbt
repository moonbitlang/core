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
fn assign_positionals(
  matches : Matches,
  positionals : Array[Arg],
  values : Array[String],
) -> Unit raise ArgParseError {
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
        add_value(
          matches,
          arg.name,
          values[cursor + taken],
          arg,
          ValueSource::Argv,
        )
        taken = taken + 1
      }
      cursor = cursor + taken
      continue
    }
    if remaining > 0 {
      add_value(matches, arg.name, values[cursor], arg, ValueSource::Argv)
      cursor = cursor + 1
    }
  }
  if cursor < values.length() {
    raise ArgParseError::TooManyPositionals
  }
}

///|
fn positional_min_required(arg : Arg) -> Int {
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
fn remaining_positional_min(positionals : Array[Arg], start : Int) -> Int {
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
  matches : Matches,
  name : String,
  value : String,
  arg : Arg,
  source : ValueSource,
) -> Unit {
  if arg.multiple || arg_action(arg) == ArgAction::Append {
    let arr = matches.values.get(name).unwrap_or([])
    arr.push(value)
    matches.values[name] = arr
    matches.value_sources[name] = source
  } else {
    matches.values[name] = [value]
    matches.value_sources[name] = source
  }
}

///|
fn assign_value(
  matches : Matches,
  arg : Arg,
  value : String,
  source : ValueSource,
) -> Unit raise ArgParseError {
  match arg_action(arg) {
    ArgAction::Append => add_value(matches, arg.name, value, arg, source)
    ArgAction::Set => add_value(matches, arg.name, value, arg, source)
    ArgAction::SetTrue => {
      let flag = parse_bool(value)
      matches.flags[arg.name] = flag
      matches.flag_sources[arg.name] = source
    }
    ArgAction::SetFalse => {
      let flag = parse_bool(value)
      matches.flags[arg.name] = !flag
      matches.flag_sources[arg.name] = source
    }
    ArgAction::Count => {
      let count = parse_count(value)
      matches.counts[arg.name] = count
      matches.flags[arg.name] = count > 0
      matches.flag_sources[arg.name] = source
    }
    ArgAction::Help =>
      raise ArgParseError::InvalidArgument("help action does not take values")
    ArgAction::Version =>
      raise ArgParseError::InvalidArgument(
        "version action does not take values",
      )
  }
}

///|
fn option_conflict_label(arg : Arg) -> String {
  match arg.long {
    Some(name) => "--\{name}"
    None =>
      match arg.short {
        Some(short) => "-\{short}"
        None => arg.name
      }
  }
}

///|
fn check_duplicate_set_occurrence(
  matches : Matches,
  arg : Arg,
) -> Unit raise ArgParseError {
  if arg_action(arg) != ArgAction::Set {
    return
  }
  if matches.values.get(arg.name) is Some(_) {
    raise ArgParseError::InvalidArgument(
      "argument '\{option_conflict_label(arg)}' cannot be used multiple times",
    )
  }
}

///|
fn should_stop_option_value(
  value : String,
  arg : Arg,
  _long_index : Map[String, Arg],
  _short_index : Map[Char, Arg],
) -> Bool {
  if !value.has_prefix("-") || value == "-" {
    return false
  }
  if arg.allow_hyphen_values {
    // Rust clap parity:
    // - `clap_builder/src/parser/parser.rs`: `parse_long_arg` / `parse_short_arg`
    //   return `ParseResult::MaybeHyphenValue` when the pending arg in
    //   `ParseState::Opt` or `ParseState::Pos` has `allow_hyphen_values`.
    // - `clap_builder/src/builder/arg.rs` (`Arg::allow_hyphen_values` docs):
    //   prior args with this setting take precedence over known flags/options.
    // - `tests/builder/opts.rs` (`leading_hyphen_with_flag_after`):
    //   a pending option consumes `-f` as a value rather than parsing flag `-f`.
    // This also means `--` is consumed as a value while the option remains pending.
    return false
  }
  true
}

///|
fn apply_env(
  matches : Matches,
  args : Array[Arg],
  env : Map[String, String],
) -> Unit raise ArgParseError {
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
    if arg_takes_value(arg) {
      assign_value(matches, arg, value, ValueSource::Env)
      continue
    }
    match arg_action(arg) {
      ArgAction::Count => {
        let count = parse_count(value)
        matches.counts[name] = count
        matches.flags[name] = count > 0
        matches.flag_sources[name] = ValueSource::Env
      }
      ArgAction::SetFalse => {
        let flag = parse_bool(value)
        matches.flags[name] = !flag
        matches.flag_sources[name] = ValueSource::Env
      }
      ArgAction::SetTrue => {
        let flag = parse_bool(value)
        matches.flags[name] = flag
        matches.flag_sources[name] = ValueSource::Env
      }
      ArgAction::Set => {
        let flag = parse_bool(value)
        matches.flags[name] = flag
        matches.flag_sources[name] = ValueSource::Env
      }
      ArgAction::Append => ()
      ArgAction::Help => ()
      ArgAction::Version => ()
    }
  }
}

///|
fn apply_defaults(matches : Matches, args : Array[Arg]) -> Unit {
  for arg in args {
    if !arg_takes_value(arg) {
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
      _ => ()
    }
  }
}

///|
fn matches_has_value_or_flag(matches : Matches, name : String) -> Bool {
  matches.flags.get(name) is Some(_) || matches.values.get(name) is Some(_)
}

///|
fn apply_flag(matches : Matches, arg : Arg, source : ValueSource) -> Unit {
  match arg_action(arg) {
    ArgAction::SetTrue => matches.flags[arg.name] = true
    ArgAction::SetFalse => matches.flags[arg.name] = false
    ArgAction::Count => {
      let current = matches.counts.get(arg.name).unwrap_or(0)
      matches.counts[arg.name] = current + 1
      matches.flags[arg.name] = true
    }
    ArgAction::Help => ()
    ArgAction::Version => ()
    _ => matches.flags[arg.name] = true
  }
  matches.flag_sources[arg.name] = source
}

///|
fn parse_bool(value : String) -> Bool raise ArgParseError {
  if value == "1" || value == "true" || value == "yes" || value == "on" {
    true
  } else if value == "0" || value == "false" || value == "no" || value == "off" {
    false
  } else {
    raise ArgParseError::InvalidValue(
      "invalid value '\{value}' for boolean flag; expected one of: 1, 0, true, false, yes, no, on, off",
    )
  }
}

///|
fn parse_count(value : String) -> Int raise ArgParseError {
  try @strconv.parse_int(value) catch {
    _ =>
      raise ArgParseError::InvalidValue(
        "invalid value '\{value}' for count; expected a non-negative integer",
      )
  } noraise {
    _..<0 =>
      raise ArgParseError::InvalidValue(
        "invalid value '\{value}' for count; expected a non-negative integer",
      )
    v => v
  }
}
