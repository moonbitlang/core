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
fn suggest_name(input : StringView, candidates : Array[String]) -> String? {
  let max_dist = suggestion_threshold(input.length())
  for cand in candidates; best = (None : String?), best_dist = 0 {
    let dist = levenshtein(input, cand)
    if best is None || dist < best_dist {
      continue Some(cand), dist
    } else {
      continue best, best_dist
    }
  } nobreak {
    match best {
      Some(name) if best_dist <= max_dist => Some(name)
      _ => None
    }
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

///|
fn levenshtein(a : StringView, b : StringView) -> Int {
  let aa = a.to_array()
  let bb = b.to_array()
  let m = aa.length()
  let n = bb.length()
  if m == 0 {
    return n
  }
  if n == 0 {
    return m
  }
  let mut prev = Array::new(capacity=n + 1)
  let mut curr = Array::new(capacity=n + 1)
  for j = 0; j <= n; {
    prev.push(j)
    curr.push(0)
    continue j + 1
  }
  for i = 1; i <= m; {
    curr[0] = i
    for j2 = 1; j2 <= n; {
      let cost = if aa[i - 1] == bb[j2 - 1] { 0 } else { 1 }
      let del = prev[j2] + 1
      let ins = curr[j2 - 1] + 1
      let sub = prev[j2 - 1] + cost
      curr[j2] = if del < ins {
        if del < sub {
          del
        } else {
          sub
        }
      } else if ins < sub {
        ins
      } else {
        sub
      }
      continue j2 + 1
    }
    let temp = prev
    prev = curr
    curr = temp
    continue i + 1
  }
  prev[n]
}
