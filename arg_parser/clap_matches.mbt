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
/// Parse results for clap-style commands.
struct Matches {
  flags : Map[String, Bool]
  values : Map[String, Array[String]]
  counts : Map[String, Int]
  flag_sources : Map[String, ValueSource]
  value_sources : Map[String, Array[ValueSource]]
  mut subcommand : (String, Matches)?
}

///|
pub fn Matches::new() -> Matches {
  Matches::{
    flags: {},
    values: {},
    counts: {},
    flag_sources: {},
    value_sources: {},
    subcommand: None,
  }
}

///|
/// Where a value/flag came from.
pub enum ValueSource {
  Argv
  Env
  Default
} derive(Eq, Show)

///|
/// Decode a full argument struct/enum from `Matches`.
pub(open) trait FromMatches {
  from_matches(matches : Matches) -> Self raise ArgumentError
}

///|
pub fn[T : FromMatches] Matches::decode(
  self : Matches,
) -> T raise ArgumentError {
  T::from_matches(self)
}

///|

///|
/// Resolved flag value (false if never set).
pub fn Matches::get_flag(self : Matches, name : String) -> Bool {
  self.flags.get(name).unwrap_or(false)
}

///|
pub fn Matches::value_of(self : Matches, name : String) -> String? {
  match self.values.get(name) {
    Some(values) if values.length() > 0 => Some(values[0])
    _ => None
  }
}

///|
pub fn Matches::values_of(self : Matches, name : String) -> Array[String]? {
  self.values.get(name)
}

///|
/// Occurrence count for a flag (0 if never seen).
pub fn Matches::count_of(self : Matches, name : String) -> Int {
  self.counts.get(name).unwrap_or(0)
}

///|
/// Source for the argument as a whole.
pub fn Matches::source_of(self : Matches, name : String) -> ValueSource? {
  match self.flag_sources.get(name) {
    Some(v) => Some(v)
    None =>
      match self.value_sources.get(name) {
        Some(sources) => highest_source(sources)
        None => None
      }
  }
}

///|
/// Sources for each collected value (if any).
pub fn Matches::value_sources_of(
  self : Matches,
  name : String,
) -> Array[ValueSource]? {
  self.value_sources.get(name)
}

///|
fn highest_source(sources : Array[ValueSource]) -> ValueSource? {
  if sources.length() == 0 {
    return None
  }
  let mut saw_env = false
  let mut saw_default = false
  for s in sources {
    if s == ValueSource::Argv {
      return Some(ValueSource::Argv)
    }
    if s == ValueSource::Env {
      saw_env = true
    }
    if s == ValueSource::Default {
      saw_default = true
    }
  }
  if saw_env {
    Some(ValueSource::Env)
  } else if saw_default {
    Some(ValueSource::Default)
  } else {
    None
  }
}

///|
pub fn Matches::get_one(
  self : Matches,
  name : String,
) -> String raise ArgumentError {
  guard self.values.get(name) is Some(values) else {
    raise ArgumentError::InvalidValue("value not found: " + name)
  }
  guard values.length() == 1 else {
    raise ArgumentError::InvalidValueCount(
      "invalid value count for " + name + ": " + values.length().to_string(),
    )
  }
  values[0]
}

///|
pub fn Matches::get_option(
  self : Matches,
  name : String,
) -> String? raise ArgumentError {
  guard self.values.get(name) is Some(values) else { return None }
  guard values.length() <= 1 else {
    raise ArgumentError::InvalidValueCount(
      "invalid value count for " + name + ": " + values.length().to_string(),
    )
  }
  match values.get(0) {
    Some(value) => Some(value)
    None => None
  }
}

///|
pub fn Matches::get_array(self : Matches, name : String) -> Array[String] {
  guard self.values.get(name) is Some(values) else { return [] }
  values
}

///|
pub fn Matches::subcommand_name(self : Matches) -> String? {
  match self.subcommand {
    Some((name, _)) => Some(name)
    None => None
  }
}

///|
pub fn Matches::subcommand_matches(self : Matches, name : String) -> Matches? {
  match self.subcommand {
    Some((sub_name, matches)) if sub_name == name => Some(matches)
    _ => None
  }
}
