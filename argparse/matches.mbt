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
struct Matches {
  flags : Map[String, Bool]
  values : Map[String, Array[String]]
  counts : Map[String, Int]
  value_sources : Map[String, ValueSource]
  subcommand : (String, Matches)?

  fn new() -> Matches
}

///|
pub fn Matches::new() -> Matches {
  Matches::{
    flags: {},
    values: {},
    counts: {},
    value_sources: {},
    subcommand: None,
  }
}

///|
/// Raw flag map for direct pattern matching.
pub fn Matches::flags_map(self : Matches) -> Map[String, Bool] {
  self.flags
}

///|
/// Raw value map for direct pattern matching.
pub fn Matches::values_map(self : Matches) -> Map[String, Array[String]] {
  self.values
}

///|
/// Raw subcommand pair `(name, matches)` if present.
pub fn Matches::subcommand(self : Matches) -> (String, Matches)? {
  self.subcommand
}

///|
/// Resolved flag value (`false` if absent).
pub fn Matches::get_flag(self : Matches, name : String) -> Bool {
  self.flags.get(name).unwrap_or(false)
}

///|
/// First value for an argument (`None` if absent).
pub fn Matches::get_one(self : Matches, name : String) -> String? {
  guard self.values.get(name) is Some(values) else { return None }
  values.get(0)
}

///|
/// All values for an argument (`None` if absent).
pub fn Matches::get_many(self : Matches, name : String) -> Array[String]? {
  self.values.get(name)
}

///|
/// Count for count-style args.
pub fn Matches::count_of(self : Matches, name : String) -> Int {
  self.counts.get(name).unwrap_or(0)
}

///|
/// Source for an argument as a whole.
pub fn Matches::value_source(self : Matches, name : String) -> ValueSource? {
  self.value_sources.get(name)
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
