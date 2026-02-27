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
fn positional_indexed_args(args : Array[Arg]) -> Array[(Int, Arg)] {
  let entries = []
  let mut next_index = 0
  for arg in args {
    if arg.info is Positional(index~, ..) {
      let resolved = match index {
        Some(value) => {
          let candidate = value + 1
          if candidate > next_index {
            next_index = candidate
          }
          value
        }
        None => {
          let value = next_index
          next_index = value + 1
          value
        }
      }
      entries.push((resolved, arg))
    }
  }
  entries.sort_by_key(pair => pair.0)
  entries
}

///|
fn positional_args(args : Array[Arg]) -> Array[Arg] {
  let ordered = []
  for item in positional_indexed_args(args) {
    let (_, arg) = item
    ordered.push(arg)
  }
  ordered
}

///|
fn next_positional(positionals : Array[Arg], collected : Array[String]) -> Arg? {
  let target = collected.length()
  let total = target + 1
  let mut cursor = 0
  for idx in 0..<positionals.length() {
    if cursor >= total {
      break
    }
    let arg = positionals[idx]
    let remaining = total - cursor
    let take = if arg.multiple {
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
      take
    } else if remaining > 0 {
      1
    } else {
      0
    }
    if take > 0 && target < cursor + take {
      return Some(arg)
    }
    cursor = cursor + take
  }
  None
}

///|
fn should_parse_as_positional(
  arg : String,
  positionals : Array[Arg],
  collected : Array[String],
  long_index : Map[String, Arg],
  short_index : Map[Char, Arg],
) -> Bool {
  if !arg.has_prefix("-") || arg == "-" {
    return false
  }
  let next = match next_positional(positionals, collected) {
    Some(v) => v
    None => return false
  }
  let next_allow = match next.info {
    Flag(_) => false
    Option(allow_hyphen_values~, ..) | Positional(allow_hyphen_values~, ..) =>
      allow_hyphen_values
  }
  let allow = next_allow || is_negative_number(arg)
  if !allow {
    return false
  }
  if arg.has_prefix("--") {
    let (name, _) = split_long(arg)
    return long_index.get(name) is None
  }
  let short = arg.get_char(1)
  match short {
    Some(ch) => short_index.get(ch) is None
    None => true
  }
}

///|
fn is_negative_number(arg : String) -> Bool {
  if arg.length() < 2 {
    return false
  }
  guard arg.get_char(0) is Some('-') else { return false }
  let mut i = 1
  while i < arg.length() {
    let ch = arg.get_char(i).unwrap()
    if ch < '0' || ch > '9' {
      return false
    }
    i = i + ch.utf16_len()
  }
  true
}
