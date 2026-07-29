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
fn suggest_long(name : StringView, long_index : Map[String, Arg]) -> String? {
  let candidates = long_index.keys().collect()
  if suggest_name(name, candidates) is Some(best) {
    Some("--\{best}")
  } else {
    None
  }
}

///|
fn suggest_short(short : Char, short_index : Map[Char, Arg]) -> String? {
  let candidates = short_index.keys().map(c => c.to_string()).collect()
  let input = short.to_string()
  if suggest_name(input, candidates) is Some(best) {
    Some("-\{best}")
  } else {
    None
  }
}

///|
/// Pick the candidate closest to `input` in UTF-16 code-unit Levenshtein
/// distance, keeping the first candidate on ties. The threshold is derived
/// from the input length in the same code units; candidates beyond it are
/// rejected by the banded search without computing their full distance.
fn suggest_name(input : StringView, candidates : Array[String]) -> String? {
  let max_dist = suggestion_threshold(input.length())
  for cand in candidates; best = (None : String?), best_dist = 0 {
    match
      @edit_distance.edit_distance_str_within(
        input,
        cand,
        max_distance=max_dist,
      ) {
      Some(dist) if best is None || dist < best_dist =>
        continue Some(cand), dist
      _ => continue best, best_dist
    }
  } nobreak {
    best
  }
}

///|
fn suggestion_threshold(len : Int) -> Int {
  if len <= 4 {
    1
  } else if len <= 8 {
    2
  } else {
    3
  }
}
