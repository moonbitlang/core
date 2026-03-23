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
fn StringView::next_char_index(self : StringView, index : Int) -> Int {
  if index < self.length() && self.unsafe_get(index).is_leading_surrogate() {
    index + 2
  } else {
    index + 1
  }
}

///|
/// Replaces all non-overlapping matches in `str` using `replacer`.
/// 
/// The `replacer` callback is called once for each match and receives the
/// corresponding `MatchResult`.
///
/// If `limit` is provided, at most `limit` matches are replaced.
/// When omitted, all matches are replaced.
/// 
/// Returns `str` unchanged when there is no match.
/// 
/// If the regex can match an empty string, replacement content is inserted at
/// the beginning, between characters, and at the end of `str`.
/// 
/// Example:
/// 
/// ```mbt check
/// test {
///   let regex = @string.Regex("[[:digit:]]+")
///   let result = regex.replace_by("a12b3", m => "[\{m.content()}]")
///   inspect(result, content="a[12]b[3]")
/// }
/// ```
pub fn Regex::replace_by(
  regex : Regex,
  str : StringView,
  replacer : (MatchResult) -> StringView,
  limit? : Int,
) -> StringView {
  // Delay buffer creation until we find the first match to avoid
  // unnecessary allocation when the regex doesn't match at all.
  let mut buf : StringBuilder? = None
  let copy_index = for copy_index = 0, search_index = 0, replaced = 0; search_index <=
                      str.length(); {
    if limit is Some(limit) && replaced >= limit {
      break copy_index
    }
    match regex.execute(str, last_index=search_index) {
      None => break copy_index
      Some(m) => {
        guard m.result.group(0) is Some((start, end)) else { break copy_index }
        let b = match buf {
          Some(b) => b
          None => {
            let b = StringBuilder::new()
            buf = Some(b)
            b
          }
        }
        b.write_stringview(str[copy_index:start])
        b.write_stringview(replacer(m))
        let search_index = if start == end {
          str.next_char_index(end)
        } else {
          end
        }
        continue end, search_index, replaced + 1
      }
    }
  } nobreak {
    copy_index
  }
  match buf {
    None => str
    Some(b) => {
      b.write_stringview(str[copy_index:])
      b.to_string()[:]
    }
  }
}

///|
/// Returns an iterator over all non-overlapping matches in `str`.
///
/// Matches are produced from left to right.
///
/// If the regex can match an empty string, iteration still terminates: after
/// each empty match, search resumes at the next character.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @string.Regex("[[:digit:]]+")
///   let matches = regex.find("a12b3").to_array()
///   inspect(matches.length(), content="2")
///   inspect(matches[0].content(), content="12")
///   inspect(matches[1].content(), content="3")
/// }
/// ```
pub fn Regex::find(regex : Regex, str : StringView) -> Iter[MatchResult] {
  let mut search_index = 0
  let len = str.length()
  Iter::new(() => {
    guard search_index <= len else { None }
    match regex.execute(str, last_index=search_index) {
      None => None
      Some(m) => {
        guard m.result.group(0) is Some((start, end)) else { return None }
        search_index = if start == end { str.next_char_index(end) } else { end }
        Some(m)
      }
    }
  })
}

///|
/// Splits `str` into all segments separated by regex matches.
/// 
/// If there is no match, the returned iterator yields only `str`.
/// 
/// Consecutive matches and boundary matches produce empty segments.
/// 
/// If the regex can match an empty string, the result includes boundary empty
/// segments and per-character splits.
/// 
/// Example:
/// 
/// ```mbt check
/// test {
///   let regex = @string.Regex(",")
///   let parts = regex.split("a,,b").to_array()
///   inspect(parts.length(), content="3")
///   inspect(parts[0], content="a")
///   inspect(parts[1], content="")
///   inspect(parts[2], content="b")
/// }
/// ```
pub fn Regex::split(regex : Regex, str : StringView) -> Iter[StringView] {
  let mut copy_index = 0
  let mut search_index = 0
  let len = str.length()
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    while search_index <= len {
      match regex.execute(str, last_index=search_index) {
        None => {
          done = true
          return Some(str[copy_index:])
        }
        Some(m) => {
          guard m.result.group(0) is Some((start, end)) else {
            done = true
            return Some(str[copy_index:])
          }
          let part = str[copy_index:start]
          copy_index = end
          search_index = if start == end {
            str.next_char_index(end)
          } else {
            end
          }
          return Some(part)
        }
      }
    }
    done = true
    Some(str[copy_index:])
  })
}
