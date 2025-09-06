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
/// FJS (Franek-Jennings-Smyth) algorithm for string search
/// Combines KMP and Boyer-Moore techniques for optimal performance
/// Returns the offset of the first occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn View::find(target : View, pattern : View) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  guard pattern_len > 0 else { return Some(0) }
  guard target_len >= pattern_len else { return None }
  if pattern_len == 1 {
    // Optimized single character search
    let pattern_byte = pattern.unsafe_get(0)
    for i in 0..<target_len {
      if target.unsafe_get(i) == pattern_byte {
        return Some(i)
      }
    }
    return None
  }

  // Build KMP failure function (border array)
  let border = build_border_array(pattern)

  // Build Boyer-Moore bad character skip table
  let skip_table = build_skip_table(pattern)
  fjs_search(target, pattern, border, skip_table)
}

///|
/// Build KMP border array (failure function)
fn build_border_array(pattern : View) -> Array[Int] {
  let pattern_len = pattern.length()
  let border = Array::make(pattern_len, 0)
  let mut j = 0
  for i in 1..<pattern_len {
    while j > 0 && pattern.unsafe_get(i) != pattern.unsafe_get(j) {
      j = border[j - 1]
    }
    if pattern.unsafe_get(i) == pattern.unsafe_get(j) {
      j += 1
    }
    border[i] = j
  }
  border
}

///|
/// Build Boyer-Moore bad character skip table
fn build_skip_table(pattern : View) -> Array[Int] {
  let pattern_len = pattern.length()
  let skip_table = Array::make(256, pattern_len)

  // Fill skip table with distances from rightmost occurrence
  for i in 0..<(pattern_len - 1) {
    let byte_val = pattern.unsafe_get(i).to_int()
    skip_table[byte_val] = pattern_len - 1 - i
  }
  skip_table
}

///|
/// FJS hybrid search algorithm
fn fjs_search(
  target : View,
  pattern : View,
  border : Array[Int],
  skip_table : Array[Int],
) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  let last_pattern_byte = pattern.unsafe_get(pattern_len - 1)
  let mut i = 0 // position in target
  while i <= target_len - pattern_len {
    // Boyer-Moore style: check last character first
    let target_byte = target.unsafe_get(i + pattern_len - 1)
    if target_byte != last_pattern_byte {
      // Bad character skip
      let skip = skip_table[target_byte.to_int()]
      i += skip
      continue
    }

    // Last character matches, now use KMP-style matching from left
    let mut j = 0 // position in pattern
    let mut k = i // current position in target
    while j < pattern_len &&
          k < target_len &&
          target.unsafe_get(k) == pattern.unsafe_get(j) {
      j += 1
      k += 1
    }
    if j == pattern_len {
      return Some(i) // Found match
    }

    // Mismatch occurred, use KMP shift or Boyer-Moore shift, whichever is larger
    let kmp_shift = if j == 0 { 1 } else { j - border[j - 1] }
    let bm_shift = 1 // Minimum shift for Boyer-Moore when last char matched
    i += if kmp_shift > bm_shift { kmp_shift } else { bm_shift }
  }
  None
}

///|
/// Returns the offset of the first occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn Bytes::find(target : Bytes, pattern : View) -> Int? {
  target[:].find(pattern)
}

///|
/// FJS algorithm for reverse search
/// Returns the offset of the last occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn View::rev_find(target : View, pattern : View) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  guard pattern_len > 0 else { return Some(target_len) }
  guard target_len >= pattern_len else { return None }
  if pattern_len == 1 {
    // Optimized single character reverse search
    let pattern_byte = pattern.unsafe_get(0)
    for i = target_len - 1; i >= 0; i = i - 1 {
      if target.unsafe_get(i) == pattern_byte {
        return Some(i)
      }
    }
    return None
  }

  // Build reverse KMP failure function
  let rev_border = build_reverse_border_array(pattern)

  // Build reverse Boyer-Moore skip table
  let rev_skip_table = build_reverse_skip_table(pattern)
  fjs_reverse_search(target, pattern, rev_border, rev_skip_table)
}

///|
/// Build reverse KMP border array
fn build_reverse_border_array(pattern : View) -> Array[Int] {
  let pattern_len = pattern.length()
  let border = Array::make(pattern_len, 0)
  let mut j = 0
  for i = pattern_len - 2; i >= 0; i = i - 1 {
    while j > 0 &&
          pattern.unsafe_get(i) != pattern.unsafe_get(pattern_len - 1 - j) {
      j = border[pattern_len - 1 - j]
    }
    if pattern.unsafe_get(i) == pattern.unsafe_get(pattern_len - 1 - j) {
      j += 1
    }
    border[i] = j
  }
  border
}

///|
/// Build reverse Boyer-Moore skip table
fn build_reverse_skip_table(pattern : View) -> Array[Int] {
  let pattern_len = pattern.length()
  let skip_table = Array::make(256, pattern_len)

  // Fill skip table with distances from leftmost occurrence (for reverse)
  for i = pattern_len - 1; i > 0; i = i - 1 {
    let byte_val = pattern.unsafe_get(i).to_int()
    skip_table[byte_val] = i
  }
  skip_table
}

///|
/// FJS reverse search algorithm
fn fjs_reverse_search(
  target : View,
  pattern : View,
  _border : Array[Int],
  skip_table : Array[Int],
) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  let first_pattern_byte = pattern.unsafe_get(0)
  let mut i = target_len - pattern_len // position in target
  while i >= 0 {
    // Boyer-Moore style: check first character first (for reverse)
    let target_byte = target.unsafe_get(i)
    if target_byte != first_pattern_byte {
      // Bad character skip (reverse)
      let skip = skip_table[target_byte.to_int()]
      let skip_val = if skip > 1 { skip } else { 1 }
      i -= skip_val
      continue
    }

    // First character matches, now use KMP-style matching from left
    let mut j = 0 // position in pattern
    let mut k = i // current position in target
    while j < pattern_len &&
          k < target_len &&
          target.unsafe_get(k) == pattern.unsafe_get(j) {
      j += 1
      k += 1
    }
    if j == pattern_len {
      return Some(i) // Found match
    }

    // Use skip table value for mismatches after partial matches, similar to forward search
    let skip = if j > 0 {
      let skip_val = skip_table[target.unsafe_get(i).to_int()]
      if skip_val > 1 {
        skip_val
      } else {
        1
      }
    } else {
      1
    }
    i -= skip
  }
  None
}

///|
/// Returns the offset of the last occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn Bytes::rev_find(target : Bytes, pattern : View) -> Int? {
  target[:].rev_find(pattern)
}
