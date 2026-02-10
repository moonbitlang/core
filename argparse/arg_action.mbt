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
/// Parser-internal action model used for control flow.
priv enum ArgAction {
  Set
  SetTrue
  SetFalse
  Count
  Append
  Help
  Version
} derive(Eq)

///|
fn arg_takes_value(arg : Arg) -> Bool {
  !arg.is_flag
}

///|
fn arg_action(arg : Arg) -> ArgAction {
  if arg.is_flag {
    match arg.flag_action {
      FlagAction::SetTrue => ArgAction::SetTrue
      FlagAction::SetFalse => ArgAction::SetFalse
      FlagAction::Count => ArgAction::Count
      FlagAction::Help => ArgAction::Help
      FlagAction::Version => ArgAction::Version
    }
  } else {
    match arg.option_action {
      OptionAction::Set => ArgAction::Set
      OptionAction::Append => ArgAction::Append
    }
  }
}

///|
fn resolve_value_range(range : ValueRange) -> (Int, Int?) {
  let min = match range.lower {
    Some(value) => if range.lower_inclusive { value } else { value + 1 }
    None => 0
  }
  let max = match range.upper {
    Some(value) => Some(if range.upper_inclusive { value } else { value - 1 })
    None => None
  }
  (min, max)
}

///|
fn validate_value_range(range : ValueRange) -> (Int, Int?) raise ArgBuildError {
  let (min, max) = resolve_value_range(range)
  match max {
    Some(max_value) if max_value < min =>
      raise ArgBuildError::Unsupported("max values must be >= min values")
    _ => ()
  }
  (min, max)
}

///|
fn arg_min_max_for_validate(arg : Arg) -> (Int, Int?) raise ArgBuildError {
  match arg.num_args {
    Some(range) => validate_value_range(range)
    None => (0, None)
  }
}

///|
fn arg_min_max(arg : Arg) -> (Int, Int?) {
  match arg.num_args {
    Some(range) => resolve_value_range(range)
    None => (0, None)
  }
}
