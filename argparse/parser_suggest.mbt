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
fn suggest_long(name : String, long_index : Map[String, Arg]) -> String? {
  let candidates = long_index.keys().collect()
  if suggest_name(name, candidates) is Some(best) {
    Some("--\{best}")
  } else {
    None
  }
}

///|
fn suggest_short(short : Char, short_index : Map[Char, Arg]) -> String? {
  let candidates = short_index.keys().map(Char::to_string).collect()
  let input = short.to_string()
  if suggest_name(input, candidates) is Some(best) {
    Some("-\{best}")
  } else {
    None
  }
}

///|
fn suggest_name(input : String, candidates : Array[String]) -> String? {
  let mut best : String? = None
  let mut best_dist = 0
  let mut has_best = false
  let max_dist = suggestion_threshold(input.length())
  for cand in candidates {
    let dist = levenshtein(input, cand)
    if !has_best || dist < best_dist {
      best_dist = dist
      best = Some(cand)
      has_best = true
    }
  }
  match best {
    Some(name) if best_dist <= max_dist => Some(name)
    _ => None
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
fn levenshtein(a : String, b : String) -> Int {
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
  let mut j = 0
  while j <= n {
    prev.push(j)
    curr.push(0)
    j = j + 1
  }
  let mut i = 1
  while i <= m {
    curr[0] = i
    let mut j2 = 1
    while j2 <= n {
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
      j2 = j2 + 1
    }
    let temp = prev
    prev = curr
    curr = temp
    i = i + 1
  }
  prev[n]
}
