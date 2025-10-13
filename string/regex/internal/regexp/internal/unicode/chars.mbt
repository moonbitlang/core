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

//////////////
/// RANGES ///
//////////////

///|
pub let ranges_is_digit : Array[Char] = ['0', '9']

///|
pub let ranges_is_not_digit : Array[Char] = ['\u{0}', '/', ':', '\u{10FFFF}']

///|
pub let ranges_is_word : Array[Char] = ['0', '9', 'A', 'Z', '_', '_', 'a', 'z']

///|
pub let ranges_is_not_word : Array[Char] = [
  '\u{0}', '/', ':', '@', '[', '^', '`', '`', '{', '\u{10FFFF}',
]

///|
pub let ranges_any : Array[Char] = ['\u{0}', '\u{10FFFF}']

///|
pub let ranges_any_not_new_line : Array[Char] = [
  '\u{0}', '\u{9}', '\u{11}', '\u{10FFFF}',
]

///|
/// white space: \u{9}, \u{B}, \u{C}, \u{FEFF}, Zs
/// line terminator: \u{A}, \u{D}, \u{2028}, \u{2029}
/// references:
/// - https://tc39.es/ecma262/multipage/ecmascript-language-lexical-grammar.html#sec-white-space
/// - https://tc39.es/ecma262/multipage/ecmascript-language-lexical-grammar.html#sec-line-terminators
/// - https://www.unicode.org/Public/UCD/latest/ucd/PropList.txt
pub let ranges_is_white_space_or_line_terminator : Array[Char] = [
  '\u{9}', '\u{D}', '\u{20}', '\u{20}', '\u{A0}', '\u{A0}', '\u{1680}', '\u{1680}',
  '\u{2000}', '\u{200A}', '\u{2028}', '\u{2029}', '\u{202F}', '\u{202F}', '\u{205F}',
  '\u{205F}', '\u{3000}', '\u{3000}', '\u{FEFF}', '\u{FEFF}',
]

///|
pub let ranges_is_not_white_space_or_line_terminator : Array[Char] = [
  '\u{00}', '\u{8}', '\u{E}', '\u{1F}', '\u{21}', '\u{9f}', '\u{A1}', '\u{167F}',
  '\u{1681}', '\u{1FFF}', '\u{200B}', '\u{2027}', '\u{202a}', '\u{202E}', '\u{2030}',
  '\u{205E}', '\u{2060}', '\u{2FFF}', '\u{3001}', '\u{FEFE}', '\u{FF00}', '\u{10ffff}',
]

///|
test "ordered range" {
  for
    range in [
      ranges_is_digit, ranges_is_not_digit, ranges_is_word, ranges_is_not_word, ranges_any,
      ranges_any_not_new_line, ranges_is_white_space_or_line_terminator,
    ] {
    assert_eq(simplify_char_ranges(range), range)
  }
}

///|
/// TODO: consider unicode mode
pub fn is_word_char_at(input : StringView, sp : Int) -> Bool {
  if sp == -1 || sp == input.length() {
    return false
  }
  let c = input.get_char(sp).unwrap()
  is_word_char(c)
}

///|
fn is_word_char(c : Char) -> Bool {
  // Check if the character is a word character (alphanumeric or underscore)
  return c is ('a'..='z' | 'A'..='Z' | '0'..='9' | '_')
}

///|
test "is word char" {
  for i in 0..<256 {
    let ch = i.unsafe_to_char()
    assert_eq(is_word_char(ch), char_in_ranges(ch, ranges_is_word))
  }
}

///|
/// Use binary search to check if a character is within any of the ranges.
/// The chars array contains pairs of characters [start1, end1, start2, end2, ...] 
/// representing ranges [start1-end1], [start2-end2], etc.
/// Assumes the ranges are sorted and non-overlapping.
pub fn char_in_ranges(ch : Char, chars : Array[Char]) -> Bool {
  let mut left = 0
  let mut right = chars.length() / 2 - 1
  while left <= right {
    let mid = (left + right) / 2
    let start = chars[mid * 2]
    let end = chars[mid * 2 + 1]
    if ch < start {
      right = mid - 1
    } else if ch > end {
      left = mid + 1
    } else {
      // ch is within the range [start, end]
      return true
    }
  }
  return false
}

///|
/// Simplifies a character class by merging overlapping ranges and removing duplicates.
/// Input: Array of characters representing ranges [start1, end1, start2, end2, ...]
/// Output: Simplified array with non-overlapping ranges in sorted order
/// 
/// Invariant: The input array must contain an even number of elements, representing pairs of start and end characters.
pub fn simplify_char_ranges(chars : Array[Char]) -> Array[Char] {
  if chars.length() == 0 {
    return []
  }

  // Convert chars to array of ranges (start, end) pairs
  let ranges = []
  for i = 0; i < chars.length(); i = i + 2 {
    let start = chars[i]
    let end = chars[i + 1]
    ranges.push((start, end))
  }

  // Sort ranges by start character
  ranges.sort_by_key(range => range.0)

  // Simplify ranges by merging overlapping or adjacent ranges
  let simplified = []
  let mut current_start = '\u{0}'
  let mut current_end = '\u{0}'
  if ranges.length() > 0 {
    current_start = ranges[0].0
    current_end = ranges[0].1
    for range in ranges[1:] {
      let (next_start, next_end) = range

      // Check if ranges overlap or are adjacent
      if next_start <= (current_end.to_int() + 1).unsafe_to_char() {
        // Merge ranges
        current_end = if current_end > next_end {
          current_end
        } else {
          next_end
        }
      } else {
        // Add current range to result and start new range
        simplified.push(current_start)
        simplified.push(current_end)
        current_start = next_start
        current_end = next_end
      }
    }

    // Add the last range
    simplified.push(current_start)
    simplified.push(current_end)
  }
  simplified
}

///|
test "simplify char ranges" {
  inspect(simplify_char_ranges(['A', 'z', 'A', 'Z']), content="['A', 'z']")
}

///|
/// Computes the complement of a character class.
/// Input: Array of characters representing ranges [start1, end1, start2, end2, ...]
/// Output: Array representing the complement ranges
/// 
/// Invariant: The input array must contain an even number of elements, representing pairs of start and end characters.
pub fn compute_char_class_complement(chars : Array[Char]) -> Array[Char] {
  // First simplify the input ranges
  let simplified = simplify_char_ranges(chars)
  if simplified.length() == 0 {
    // Empty character class, complement is everything
    return ['\u{0}', '\u{10FFFF}']
  }
  let complement = []
  let min_char = '\u{0}'
  let max_char = '\u{10FFFF}'

  // Add range before first range if it doesn't start at minimum
  if simplified[0] > min_char {
    complement.push(min_char)
    complement.push((simplified[0].to_int() - 1).unsafe_to_char())
  }

  // Add gaps between ranges
  for i = 0; i < simplified.length() / 2 - 1; i = i + 1 {
    let current_end = simplified[i * 2 + 1]
    let next_start = simplified[(i + 1) * 2]
    let gap_start = (current_end.to_int() + 1).unsafe_to_char()
    let gap_end = (next_start.to_int() - 1).unsafe_to_char()
    if gap_start <= gap_end {
      complement.push(gap_start)
      complement.push(gap_end)
    }
  }

  // Add range after last range if it doesn't end at maximum
  let last_end = simplified[simplified.length() - 1]
  if last_end < max_char {
    complement.push((last_end.to_int() + 1).unsafe_to_char())
    complement.push(max_char)
  }
  complement
}

///|
test "compute complement of charclass" {
  assert_eq(ranges_is_digit, compute_char_class_complement(ranges_is_not_digit))
  assert_eq(ranges_is_not_digit, compute_char_class_complement(ranges_is_digit))
  assert_eq(ranges_is_word, compute_char_class_complement(ranges_is_not_word))
  assert_eq(ranges_is_not_word, compute_char_class_complement(ranges_is_word))
  assert_eq(
    ranges_is_not_white_space_or_line_terminator,
    compute_char_class_complement(ranges_is_white_space_or_line_terminator),
  )
  inspect(
    compute_char_class_complement([]),
    content="['\\u{00}', '\\u{10ffff}']",
  )
}

///|
pub fn case_insensitive_char_class(chars : Array[Char]) -> Array[Char] {
  // This function should compute the case-insensitive character class
  // based on the provided character ranges.
  // For simplicity, we will just return the input for now.
  // In a real implementation, this would involve looking up case folding data.
  let result = []
  for i in 0..<(chars.length() / 2) {
    let mut start = chars[i * 2]
    let mut end = chars[i * 2 + 1]
    if (start <= MIN_FOLD && end >= MAX_FOLD) ||
      end < MIN_FOLD ||
      start > MAX_FOLD {
      // If the range is outside the simple case folding range, just add it
      result..push(start)..push(end)
      continue
    }
    if start < MIN_FOLD {
      result..push(start)..push((MIN_FOLD.to_int() - 1).unsafe_to_char())
      start = MIN_FOLD
    } else if end > MAX_FOLD {
      result..push((MAX_FOLD.to_int() + 1).unsafe_to_char())..push(end)
      end = MAX_FOLD
    }
    // For each character in the range, add its case-insensitive equivalents
    for c in start.to_int()..=end.to_int() {
      let char = c.unsafe_to_char()
      let mut ch0 = char
      result..push(char)..push(char)
      // Add both lower and upper case versions of the character
      while case_folding.get(ch0) is Some(ch) && ch != char {
        result.push(ch)
        result.push(ch)
        ch0 = ch
      }
    }
  }
  simplify_char_ranges(result)
}

///|
test "case insensitive char class" {
  inspect(
    case_insensitive_char_class(['a', 'z']),
    content="['A', 'Z', 'a', 'z', 'ſ', 'ſ', 'K', 'K']",
  )
  inspect(
    case_insensitive_char_class(['A', 'Z']),
    content="['A', 'Z', 'a', 'z', 'ſ', 'ſ', 'K', 'K']",
  )
  inspect(
    case_insensitive_char_class(['\u{0}', '\n']),
    content="['\\u{00}', '\\n']",
  )
  inspect(
    case_insensitive_char_class(['!', 'z']),
    content="['!', 'z', 'ſ', 'ſ', 'K', 'K']",
  )
  inspect(case_insensitive_char_class(['B', '🀄']), content="['A', '🀄']")
  inspect(
    case_insensitive_char_class(['🀄', '🀡']),
    content="['🀄', '🀡']",
  )
}
