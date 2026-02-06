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
/// Decode a full argument struct/enum from `Matches`.
pub fn[T : FromMatches] from_matches(
  matches : Matches,
) -> T raise ArgumentError {
  T::from_matches(matches)
}

///|

///|
/// Resolved flag value (false if never set).
pub fn Matches::get_flag(self : Matches, name : String) -> Bool {
  self.flags.get(name).unwrap_or(false)
}

///|
/// Occurrence count for a flag (0 if never seen).
pub fn Matches::count_of(self : Matches, name : String) -> Int {
  self.counts.get(name).unwrap_or(0)
}

///|
/// Source for the argument as a whole.
pub fn Matches::value_source(self : Matches, name : String) -> ValueSource? {
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
pub fn Matches::get_one(self : Matches, name : String) -> String? {
  guard self.values.get(name) is Some(values) else { return None }
  values.get(0)
}

///|
/// Clap-style many-values accessor.
pub fn Matches::get_many(self : Matches, name : String) -> Array[String]? {
  self.values.get(name)
}

///|
pub fn Matches::subcommand_name(self : Matches) -> String? {
  match self.subcommand {
    Some((name, _)) => Some(name)
    None => None
  }
}

///|
/// Return the parsed subcommand tuple `(name, matches)` if present.
pub fn Matches::subcommand(self : Matches) -> (String, Matches)? {
  self.subcommand
}

///|
pub fn Matches::subcommand_matches(self : Matches, name : String) -> Matches? {
  match self.subcommand {
    Some((sub_name, matches)) if sub_name == name => Some(matches)
    _ => None
  }
}
