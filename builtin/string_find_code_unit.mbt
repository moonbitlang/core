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
// Convert view-relative bounds to backing-string offsets before scanning.
fn find_code_unit_from_view(
  target : StringView,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  let target_start = target.start_offset()
  let found = find_code_unit_from_string(
    target.data(),
    target_start + start,
    target_start + end,
    code,
  )
  if found < 0 {
    -1
  } else {
    found - target_start
  }
}

///|
// Convert view-relative bounds to backing-string offsets before reverse
// scanning.
fn rev_find_code_unit_from_view(
  target : StringView,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  let target_start = target.start_offset()
  let found = rev_find_code_unit_from_string(
    target.data(),
    target_start + start,
    target_start + end,
    code,
  )
  if found < 0 {
    -1
  } else {
    found - target_start
  }
}

///|
// The caller must ensure `0 <= start <= end <= data.length()`.
#inline
fn find_code_unit_scalar(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  for pos in start..<end {
    if data.unsafe_get(pos) == code {
      break pos
    }
  } nobreak {
    -1
  }
}

///|
// The caller must ensure `0 <= start <= end <= data.length()`.
#inline
fn rev_find_code_unit_scalar(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  for pos = end - 1; pos >= start; {
    if data.unsafe_get(pos) == code {
      break pos
    }
    continue pos - 1
  } nobreak {
    -1
  }
}

///|
#cfg(not(any(target="native", target="wasm")))
fn find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  find_code_unit_scalar(data, start, end, code)
}

///|
#cfg(not(any(target="native", target="wasm")))
fn rev_find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  rev_find_code_unit_scalar(data, start, end, code)
}

///|
// SIMD code-unit scanner for linear-memory backends. The vector loop scans
// eight UTF-16 code units at a time, then the scalar tail handles the remainder.
#cfg(any(target="native", target="wasm"))
fn find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  guard start < end else { return -1 }
  if data.unsafe_get(start) == code {
    return start
  }
  let code_v = i16x8_splat(code)
  let tail_start = for pos = start; pos + 8 <= end; {
    let mask = i16x8_bitmask(i16x8_eq(v128_load_i16x8(data, pos), code_v))
    if mask != 0 {
      return pos + mask.ctz()
    }
    continue pos + 8
  } nobreak {
    pos
  }
  find_code_unit_scalar(data, tail_start, end, code)
}

///|
// SIMD reverse code-unit scanner for linear-memory backends. It scans
// eight-code-unit chunks from the end and returns the highest matching offset.
#cfg(any(target="native", target="wasm"))
fn rev_find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  guard start < end else { return -1 }
  if data.unsafe_get(end - 1) == code {
    return end - 1
  }
  let code_v = i16x8_splat(code)
  let head_end = for pos = end; pos - 8 >= start; {
    let chunk_start = pos - 8
    let mask = i16x8_bitmask(
      i16x8_eq(v128_load_i16x8(data, chunk_start), code_v),
    )
    if mask != 0 {
      return chunk_start + 31 - mask.clz()
    }
    continue chunk_start
  } nobreak {
    pos
  }
  rev_find_code_unit_scalar(data, start, head_end, code)
}

///|
// Finds a multi-code-unit pattern by scanning candidate positions where both
// the first and last code units match, then checking only the middle range.
// The caller must ensure `2 <= pattern.length() <= target.length()`.
fn find_by_two_anchors(target : StringView, pattern : StringView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  let target_start = target.start_offset()
  let pattern_start = pattern.start_offset()
  let last_offset = pattern_len - 1
  let candidate_end = target_start + target_len - pattern_len + 1
  let first = pattern.unsafe_get(0)
  let last = pattern.unsafe_get(last_offset)
  let middle_len = last_offset - 1
  for pos = target_start, failures = 0; pos < candidate_end; {
    let found = find_two_anchor_candidate_from_string(
      target.data(),
      pos,
      candidate_end,
      first,
      last_offset,
      last,
    )
    if found < 0 {
      break None
    }
    if string_ranges_equal(
        target.data(),
        found + 1,
        pattern.data(),
        pattern_start + 1,
        middle_len,
      ) {
      break Some(found - target_start)
    }
    let failures = failures + 1
    let scanned = found - target_start
    if two_anchor_should_fallback(failures, scanned) {
      break find_pattern_scalar_from(target, pattern, scanned + 1)
    }
    continue found + 1, failures
  } nobreak {
    None
  }
}

///|
// Finds the last multi-code-unit pattern occurrence using the same two-anchor
// prefilter as the forward search. Candidate positions are scanned backwards.
// The caller must ensure `2 <= pattern.length() <= target.length()`.
fn rev_find_by_two_anchors(target : StringView, pattern : StringView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  let target_start = target.start_offset()
  let pattern_start = pattern.start_offset()
  let last_offset = pattern_len - 1
  let first = pattern.unsafe_get(0)
  let last = pattern.unsafe_get(last_offset)
  let middle_len = last_offset - 1
  let last_candidate = target_len - pattern_len
  for candidate_end = target_start + last_candidate + 1, failures = 0; candidate_end >
     target_start; {
    let found = rev_find_two_anchor_candidate_from_string(
      target.data(),
      target_start,
      candidate_end,
      first,
      last_offset,
      last,
    )
    if found < 0 {
      break None
    }
    if string_ranges_equal(
        target.data(),
        found + 1,
        pattern.data(),
        pattern_start + 1,
        middle_len,
      ) {
      break Some(found - target_start)
    }
    let candidate = found - target_start
    let failures = failures + 1
    let scanned = last_candidate - candidate
    if two_anchor_should_fallback(failures, scanned) {
      break rev_find_pattern_scalar_before(target, pattern, candidate)
    }
    continue found, failures
  } nobreak {
    None
  }
}

///|
// Dense first/last-anchor matches make repeated SIMD candidate scans more
// expensive than direct comparison. Cut over after enough false candidates,
// following the guarded-scanner strategy used by Bytes search.
#inline
fn two_anchor_should_fallback(failures : Int, scanned : Int) -> Bool {
  failures > 64 || failures > 4 + scanned / 8
}

///|
// Direct forward fallback used after the two-anchor filter encounters dense
// false positives. It checks the middle first because the cutover has already
// established that first/last matches are not selective. `start` is relative
// to `target`.
fn find_pattern_scalar_from(
  target : StringView,
  pattern : StringView,
  start : Int,
) -> Int? {
  let pattern_len = pattern.length()
  let last_offset = pattern_len - 1
  let first = pattern.unsafe_get(0)
  let last = pattern.unsafe_get(last_offset)
  let last_candidate = target.length() - pattern_len
  for candidate in start..<=last_candidate {
    let middle_matches = for i in 1..<last_offset {
      if target.unsafe_get(candidate + i) != pattern.unsafe_get(i) {
        break false
      }
    } nobreak {
      true
    }
    if middle_matches &&
      target.unsafe_get(candidate) == first &&
      target.unsafe_get(candidate + last_offset) == last {
      break Some(candidate)
    }
  } nobreak {
    None
  }
}

///|
// Direct reverse fallback used after the two-anchor filter encounters dense
// false positives. It checks the middle first because the cutover has already
// established that first/last matches are not selective. `candidate_end` is
// target-relative and exclusive.
fn rev_find_pattern_scalar_before(
  target : StringView,
  pattern : StringView,
  candidate_end : Int,
) -> Int? {
  guard candidate_end > 0 else { return None }
  let pattern_len = pattern.length()
  let last_offset = pattern_len - 1
  let first = pattern.unsafe_get(0)
  let last = pattern.unsafe_get(last_offset)
  for candidate = candidate_end - 1; candidate >= 0; {
    let middle_matches = for i in 1..<last_offset {
      if target.unsafe_get(candidate + i) != pattern.unsafe_get(i) {
        break false
      }
    } nobreak {
      true
    }
    if middle_matches &&
      target.unsafe_get(candidate) == first &&
      target.unsafe_get(candidate + last_offset) == last {
      break Some(candidate)
    }
    continue candidate - 1
  } nobreak {
    None
  }
}

///|
// Compares two raw UTF-16 ranges. The caller must ensure both ranges are in
// bounds; using backing strings directly also permits isolated surrogate code
// units without constructing intermediate StringViews.
#inline
fn string_ranges_equal(
  left : String,
  left_start : Int,
  right : String,
  right_start : Int,
  length : Int,
) -> Bool {
  for i in 0..<length {
    if left.unsafe_get(left_start + i) != right.unsafe_get(right_start + i) {
      return false
    }
  }
  true
}

///|
// Scalar first/last-code-unit candidate scanner.
#inline
fn find_two_anchor_candidate_scalar(
  data : String,
  start : Int,
  candidate_end : Int,
  first : UInt16,
  last_offset : Int,
  last : UInt16,
) -> Int {
  for pos in start..<candidate_end {
    if data.unsafe_get(pos) == first &&
      data.unsafe_get(pos + last_offset) == last {
      break pos
    }
  } nobreak {
    -1
  }
}

///|
// Scalar reverse first/last-code-unit candidate scanner.
#inline
fn rev_find_two_anchor_candidate_scalar(
  data : String,
  start : Int,
  candidate_end : Int,
  first : UInt16,
  last_offset : Int,
  last : UInt16,
) -> Int {
  for pos = candidate_end - 1; pos >= start; {
    if data.unsafe_get(pos) == first &&
      data.unsafe_get(pos + last_offset) == last {
      break pos
    }
    continue pos - 1
  } nobreak {
    -1
  }
}

///|
#cfg(not(any(target="native", target="wasm")))
fn find_two_anchor_candidate_from_string(
  data : String,
  start : Int,
  candidate_end : Int,
  first : UInt16,
  last_offset : Int,
  last : UInt16,
) -> Int {
  find_two_anchor_candidate_scalar(
    data, start, candidate_end, first, last_offset, last,
  )
}

///|
#cfg(not(any(target="native", target="wasm")))
fn rev_find_two_anchor_candidate_from_string(
  data : String,
  start : Int,
  candidate_end : Int,
  first : UInt16,
  last_offset : Int,
  last : UInt16,
) -> Int {
  rev_find_two_anchor_candidate_scalar(
    data, start, candidate_end, first, last_offset, last,
  )
}

///|
// SIMD first/last-code-unit prefilter. Eight candidate positions are checked
// per iteration and the middle range is left to the caller for verification.
#cfg(any(target="native", target="wasm"))
fn find_two_anchor_candidate_from_string(
  data : String,
  start : Int,
  candidate_end : Int,
  first : UInt16,
  last_offset : Int,
  last : UInt16,
) -> Int {
  guard start < candidate_end else { return -1 }
  if data.unsafe_get(start) == first &&
    data.unsafe_get(start + last_offset) == last {
    return start
  }
  let first_v = i16x8_splat(first)
  let last_v = i16x8_splat(last)
  let tail_start = for pos = start; pos + 8 <= candidate_end; {
    let mask = v128_and(
      i16x8_eq(v128_load_i16x8(data, pos), first_v),
      i16x8_eq(v128_load_i16x8(data, pos + last_offset), last_v),
    )
    let bits = i16x8_bitmask(mask)
    if bits != 0 {
      return pos + bits.ctz()
    }
    continue pos + 8
  } nobreak {
    pos
  }
  find_two_anchor_candidate_scalar(
    data, tail_start, candidate_end, first, last_offset, last,
  )
}

///|
// SIMD reverse first/last-code-unit prefilter. It returns the highest matching
// candidate position from each eight-lane block.
#cfg(any(target="native", target="wasm"))
fn rev_find_two_anchor_candidate_from_string(
  data : String,
  start : Int,
  candidate_end : Int,
  first : UInt16,
  last_offset : Int,
  last : UInt16,
) -> Int {
  guard start < candidate_end else { return -1 }
  let final_candidate = candidate_end - 1
  if data.unsafe_get(final_candidate) == first &&
    data.unsafe_get(final_candidate + last_offset) == last {
    return final_candidate
  }
  let first_v = i16x8_splat(first)
  let last_v = i16x8_splat(last)
  let head_end = for pos = candidate_end; pos - 8 >= start; {
    let chunk_start = pos - 8
    let mask = v128_and(
      i16x8_eq(v128_load_i16x8(data, chunk_start), first_v),
      i16x8_eq(v128_load_i16x8(data, chunk_start + last_offset), last_v),
    )
    let bits = i16x8_bitmask(mask)
    if bits != 0 {
      return chunk_start + 31 - bits.clz()
    }
    continue chunk_start
  } nobreak {
    pos
  }
  rev_find_two_anchor_candidate_scalar(
    data, start, head_end, first, last_offset, last,
  )
}
