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
priv struct EngineMatches {
  flags : Map[String, Bool]
  values : Map[String, Array[String]]
  counts : Map[String, Int]
  flag_sources : Map[String, EngineValueSource]
  value_sources : Map[String, Array[EngineValueSource]]
  mut subcommand : (String, EngineMatches)?
}

///|
fn EngineMatches::new() -> EngineMatches {
  EngineMatches::{
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
priv enum EngineValueSource {
  Argv
  Env
  Default
} derive(Eq)

///|
/// Resolved flag value (false if never set).
fn EngineMatches::get_flag(self : EngineMatches, name : String) -> Bool {
  self.flags.get(name).unwrap_or(false)
}

///|
/// Occurrence count for a flag (0 if never seen).
fn EngineMatches::count_of(self : EngineMatches, name : String) -> Int {
  self.counts.get(name).unwrap_or(0)
}

///|
/// Source for the argument as a whole.
fn EngineMatches::value_source(
  self : EngineMatches,
  name : String,
) -> EngineValueSource? {
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
fn highest_source(sources : Array[EngineValueSource]) -> EngineValueSource? {
  if sources.length() == 0 {
    return None
  }
  let mut saw_env = false
  let mut saw_default = false
  for s in sources {
    if s == EngineValueSource::Argv {
      return Some(EngineValueSource::Argv)
    }
    if s == EngineValueSource::Env {
      saw_env = true
    }
    if s == EngineValueSource::Default {
      saw_default = true
    }
  }
  if saw_env {
    Some(EngineValueSource::Env)
  } else if saw_default {
    Some(EngineValueSource::Default)
  } else {
    None
  }
}

///|
fn EngineMatches::get_many(
  self : EngineMatches,
  name : String,
) -> Array[String]? {
  self.values.get(name)
}

///|
/// Return the parsed subcommand tuple `(name, matches)` if present.
fn EngineMatches::subcommand(self : EngineMatches) -> (String, EngineMatches)? {
  self.subcommand
}
