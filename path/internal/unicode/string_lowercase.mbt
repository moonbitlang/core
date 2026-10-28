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
// Inclusive ranges stored as [start, end, start, end, ...].
fn in_ranges(ch : Char, ranges : ReadOnlyArray[Int32]) -> Bool {
  let code = ch.to_int()
  for lo = 0, hi = ranges.length() / 2; lo < hi; {
    let mid = lo + (hi - lo) / 2
    let start = ranges[2 * mid]
    let end = ranges[2 * mid + 1]
    if code < start {
      continue lo, mid
    } else if code > end {
      continue mid + 1, hi
    } else {
      return true
    }
  } nobreak {
    false
  }
}

///|
fn followed_by_cased(rest : StringView) -> Bool {
  for ch in rest {
    if !in_ranges(ch, case_ignorable_ranges) {
      return in_ranges(ch, cased_ranges)
    }
  }
  false
}

///|
/// Unicode default string lowercasing, as used by Node's path comparisons.
/// SpecialCasing-17.0.0 adds one expansion (U+0130) and one contextual rule
/// (Final_Sigma) to simple lowercase mappings, excluding locale-specific rules.
pub fn lowercase(source : StringView) -> String {
  let builder = StringBuilder(size_hint=source.length())
  let mut offset = 0
  let mut preceded_by_cased = false
  for ch in source {
    offset += ch.utf16_len()
    match ch {
      '\u{0130}' => builder.write_string("i\u{0307}")
      'Σ' if preceded_by_cased && !followed_by_cased(source[offset:]) =>
        builder.write_char('ς')
      _ => builder.write_char(to_lowercase(ch))
    }
    // Context is evaluated in the original string. Some characters are both
    // Cased and Case_Ignorable; ignoring them takes precedence in this rule.
    if !in_ranges(ch, case_ignorable_ranges) {
      preceded_by_cased = in_ranges(ch, cased_ranges)
    }
  }
  builder.to_string()
}
