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
/// Where a value/flag came from.
pub enum ValueSource {
  Argv
  Env
  Default
} derive(Eq, Show)

///|
/// Parse results for declarative commands.
pub struct Matches {
  flags : Map[String, Bool]
  values : Map[String, Array[String]]
  flag_counts : Map[String, Int]
  sources : Map[String, ValueSource]
  subcommand : (String, Matches)?
  priv counts : Map[String, Int]
  priv flag_sources : Map[String, ValueSource]
  priv value_sources : Map[String, Array[ValueSource]]
  priv mut parsed_subcommand : (String, Matches)?
}

///|
fn new_matches_parse_state() -> Matches {
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
  }
}

///|
fn Matches::get_flag(self : Matches, name : String) -> Bool {
  self.flags.get(name).unwrap_or(false)
}

///|
fn Matches::count_of(self : Matches, name : String) -> Int {
  self.counts.get(name).unwrap_or(0)
}

///|
fn Matches::value_source(self : Matches, name : String) -> ValueSource? {
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
fn Matches::get_many(self : Matches, name : String) -> Array[String]? {
  self.values.get(name)
}

///|
fn Matches::raw_subcommand(self : Matches) -> (String, Matches)? {
  self.parsed_subcommand
}

///|
/// Decode a full argument struct/enum from `Matches`.
pub(open) trait FromMatches {
  from_matches(matches : Matches) -> Self raise ArgParseError
}

///|
/// Decode a full argument struct/enum from `Matches`.
pub fn[T : FromMatches] from_matches(
  matches : Matches,
) -> T raise ArgParseError {
  T::from_matches(matches)
}
