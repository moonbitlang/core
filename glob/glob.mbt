// Copyright 2025 International Digital Economy Academy
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
/// Matches a string against a glob pattern.
///
/// Supported features:
/// - `*` matches zero or more characters (excluding path separator)
/// - `?` matches exactly one character (excluding path separator)
/// - `[abc]` matches one character in the set
/// - `[a-z]` matches one character in the range
/// - `[!abc]` or `[^abc]` matches one character not in the set
/// - `{a,b,c}` matches any of the comma-separated alternatives
/// - `**` matches zero or more path segments (including `/`)
/// - `\` escapes special characters
///
/// Parameters:
/// - `pattern`: The glob pattern
/// - `text`: The string to match against
///
/// Returns:
/// - `true` if the text matches the pattern, `false` otherwise
///
/// Examples:
/// ```moonbit
/// let _ = @glob.is_match("*.txt", "hello.txt") // true
/// let _ = @glob.is_match("?.txt", "a.txt") // true
/// let _ = @glob.is_match("file[0-9].txt", "file5.txt") // true
/// let _ = @glob.is_match("file[!0-9].txt", "fileA.txt") // true
/// let _ = @glob.is_match("{a,b,c}.txt", "b.txt") // true
/// let _ = @glob.is_match("**/test/*.txt", "foo/bar/test/hello.txt") // true
/// ```
pub fn is_match(pattern : String, text : String) -> Bool {
  match_impl(pattern, text, 0, 0, false)
}

///|
fn match_impl(
  pattern : String,
  text : String,
  p_idx : Int,
  t_idx : Int,
  double_star : Bool,
) -> Bool {
  let p_len = pattern.length()
  let t_len = text.length()

  // Base cases
  if p_idx == p_len && t_idx == t_len {
    return true
  }
  if p_idx == p_len {
    return false
  }

  // Get current pattern character
  let p_char = Int::unsafe_to_char(pattern[p_idx])

  // Handle escape character
  if p_char == '\\' && p_idx + 1 < p_len {
    if t_idx >= t_len {
      return false
    }
    if pattern[p_idx + 1] == text[t_idx] {
      return match_impl(pattern, text, p_idx + 2, t_idx + 1, double_star)
    }
    return false
  }

  // Handle **
  if p_char == '*' &&
    p_idx + 1 < p_len &&
    Int::unsafe_to_char(pattern[p_idx + 1]) == '*' {
    // Handle **/ or ** at end
    let next_p = if p_idx + 2 < p_len &&
      Int::unsafe_to_char(pattern[p_idx + 2]) == '/' {
      p_idx + 3
    } else if p_idx + 2 == p_len {
      p_idx + 2
    } else {
      p_idx + 2
    }

    // Try matching zero segments
    if match_impl(pattern, text, next_p, t_idx, true) {
      return true
    }

    // Try matching one or more segments
    for i = t_idx; i < t_len; i = i + 1 {
      if match_impl(pattern, text, next_p, i + 1, true) {
        return true
      }
    }
    return false
  }

  // Handle *
  if p_char == '*' {
    // Try matching zero characters
    if match_impl(pattern, text, p_idx + 1, t_idx, double_star) {
      return true
    }

    // Try matching one or more characters (but not /)
    for i = t_idx; i < t_len; i = i + 1 {
      if Int::unsafe_to_char(text[i]) == '/' {
        break
      }
      if match_impl(pattern, text, p_idx + 1, i + 1, double_star) {
        return true
      }
    }
    return false
  }

  // Handle ?
  if p_char == '?' {
    if t_idx >= t_len || Int::unsafe_to_char(text[t_idx]) == '/' {
      return false
    }
    return match_impl(pattern, text, p_idx + 1, t_idx + 1, double_star)
  }

  // Handle character class [...]
  if p_char == '[' {
    if t_idx >= t_len {
      return false
    }
    let result = match_char_class(
      pattern,
      p_idx,
      Int::unsafe_to_char(text[t_idx]),
    )
    match result {
      Some((matched, new_p_idx)) => {
        if matched {
          return match_impl(pattern, text, new_p_idx, t_idx + 1, double_star)
        }
        return false
      }
      None => return false // Invalid character class
    }
  }

  // Handle brace expansion {a,b,c}
  if p_char == '{' {
    let alternatives = parse_alternatives(pattern, p_idx)
    match alternatives {
      Some((alts, new_p_idx)) => {
        for alt in alts {
          let prefix = pattern.unsafe_substring(start=0, end=p_idx)
          let suffix = pattern.unsafe_substring(
            start=new_p_idx,
            end=pattern.length(),
          )
          let new_pattern = prefix + alt + suffix
          if is_match(new_pattern, text) {
            return true
          }
        }
        return false
      }
      None => {
        // Not a valid brace expansion, treat { as literal
        if t_idx >= t_len || Int::unsafe_to_char(text[t_idx]) != '{' {
          return false
        }
        return match_impl(pattern, text, p_idx + 1, t_idx + 1, double_star)
      }
    }
  }

  // Handle literal character
  if t_idx >= t_len || pattern[p_idx] != text[t_idx] {
    return false
  }
  match_impl(pattern, text, p_idx + 1, t_idx + 1, double_star)
}

///|
/// Match a character against a character class pattern [...]
/// Returns Some((matched, next_index)) or None if invalid
fn match_char_class(
  pattern : String,
  start_idx : Int,
  ch : Char,
) -> (Bool, Int)? {
  let p_len = pattern.length()
  let mut i = start_idx + 1 // Skip opening [
  if i >= p_len {
    return None
  }

  // Check for negation
  let negate = Int::unsafe_to_char(pattern[i]) == '!' ||
    Int::unsafe_to_char(pattern[i]) == '^'
  if negate {
    i = i + 1
  }
  if i >= p_len {
    return None
  }
  let mut matched = false
  let mut found_close = false
  while i < p_len && not(found_close) {
    let curr = Int::unsafe_to_char(pattern[i])
    if curr == ']' && i != start_idx + 1 && i != start_idx + 2 {
      // Allow ] as first character in class
      found_close = true
      break
    }

    // Check for range
    if i + 2 < p_len &&
      Int::unsafe_to_char(pattern[i + 1]) == '-' &&
      Int::unsafe_to_char(pattern[i + 2]) != ']' {
      let range_start = Int::unsafe_to_char(pattern[i])
      let range_end = Int::unsafe_to_char(pattern[i + 2])
      if ch >= range_start && ch <= range_end {
        matched = true
      }
      i = i + 3
    } else {
      if curr == ch {
        matched = true
      }
      i = i + 1
    }
  }

  // Find closing ]
  while i < p_len && Int::unsafe_to_char(pattern[i]) != ']' {
    i = i + 1
  }
  if i >= p_len {
    return None // No closing ]
  }
  let final_match = if negate { not(matched) } else { matched }
  Some((final_match, i + 1))
}

///|
/// Parse brace expansion {a,b,c}
/// Returns Some((alternatives, next_index)) or None if not a valid brace expansion
fn parse_alternatives(
  pattern : String,
  start_idx : Int,
) -> (Array[String], Int)? {
  let p_len = pattern.length()
  let mut i = start_idx + 1 // Skip opening {
  let alternatives : Array[String] = []
  let mut current = ""
  let mut depth = 0
  let mut found_comma = false
  while i < p_len {
    let ch = Int::unsafe_to_char(pattern[i])
    if ch == '{' {
      depth = depth + 1
      current = current + "{"
      i = i + 1
    } else if ch == '}' {
      if depth == 0 {
        // End of brace expansion
        alternatives.push(current)
        if alternatives.length() > 1 || found_comma {
          return Some((alternatives, i + 1))
        }
        return None // Single item without comma is not valid expansion
      }
      depth = depth - 1
      current = current + "}"
      i = i + 1
    } else if ch == ',' && depth == 0 {
      found_comma = true
      alternatives.push(current)
      current = ""
      i = i + 1
    } else if ch == '\\' && i + 1 < p_len {
      current = current + "\\" + Int::unsafe_to_char(pattern[i + 1]).to_string()
      i = i + 2
    } else {
      current = current + ch.to_string()
      i = i + 1
    }
  }
  None // No closing }
}
