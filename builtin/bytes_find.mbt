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
let find_max_short_pattern : Int = 32

///|
let find_max_bruteforce : Int = 64

///|
let find_prime_rk : UInt = 16777619U

///|
/// Returns the offset of the first occurrence of the given bytes substring.
///
/// If the substring is not found, `None` is returned.
pub fn BytesView::find(target : BytesView, pattern : BytesView) -> Int? {
  find_index(target, pattern)
}

///|
/// Returns the offset of the first occurrence of the given bytes substring.
///
/// If the substring is not found, `None` is returned.
pub fn Bytes::find(target : Bytes, pattern : BytesView) -> Int? {
  target[:].find(pattern)
}

///|
// Handle trivial cases first, use the short-pattern scanner when the pattern is
// small, then use the guarded long-pattern scanner.
fn find_index(target : BytesView, pattern : BytesView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  if pattern_len == 0 {
    return Some(0)
  }
  if pattern_len > target_len {
    return None
  }
  if pattern_len == 1 {
    let found = find_byte_from_view(
      target,
      0,
      target_len,
      pattern.unsafe_get(0),
    )
    if found < 0 {
      None
    } else {
      Some(found)
    }
  } else if pattern_len == target_len {
    if find_match_range(target, pattern, 0, 0, pattern_len) {
      Some(0)
    } else {
      None
    }
  } else if pattern_len <= find_max_short_pattern {
    find_short(target, pattern)
  } else {
    find_long_by_byte_scanner(target, pattern)
  }
}

///|
// Number of failed first-byte candidates tolerated before the long scanner
// switches to Rabin-Karp. This keeps dense false positives linear-time.
#inline
fn find_cutover(i : Int) -> Int {
  4 + i / 16
}

///|
#inline
fn find_match_range(
  target : BytesView,
  pattern : BytesView,
  candidate : Int,
  start : Int,
  end : Int,
) -> Bool {
  // Some callers already check the full requested range.
  if start >= end {
    return true
  }
  // `candidate`, `start`, and `end` are relative to the views. Convert both
  // sides to offsets in their backing `Bytes` before comparing.
  target
  .data()
  .unsafe_range_equal(
    target.start_offset() + candidate + start,
    pattern.data(),
    pattern.start_offset() + start,
    end - start,
  )
}

///|
// Scalar byte scanner for backends without direct linear-memory vector loads.
#cfg(any(target="js", target="wasm-gc"))
fn find_byte_from_view(
  target : BytesView,
  start : Int,
  end : Int,
  byte : Byte,
) -> Int {
  for pos in start..<end {
    if target.unsafe_get(pos) == byte {
      break pos
    }
  } nobreak {
    -1
  }
}

///|
#cfg(any(target="native", target="wasm"))
fn Bytes::v128_load(self : Bytes, offset : Int) -> V128 {
  v128_load(unsafe_from_bytes(self), offset)
}

///|
// SIMD byte scanner for linear-memory backends. The vector loop scans 16 bytes
// at a time, then the scalar tail handles the remaining bytes.
#cfg(any(target="native", target="wasm"))
fn find_byte_from_bytes(
  data : Bytes,
  start : Int,
  end : Int,
  byte : Byte,
) -> Int {
  let byte_v = i8x16_splat(byte)
  let tail_start = for pos = start; pos + 16 <= end; {
    let mask = i8x16_bitmask(i8x16_eq(data.v128_load(pos), byte_v))
    if mask != 0 {
      return pos + mask.ctz()
    }
    continue pos + 16
  } nobreak {
    pos
  }
  for pos in tail_start..<end {
    if data.unsafe_get(pos) == byte {
      break pos
    }
  } nobreak {
    -1
  }
}

///|
// Convert view-relative bounds to backing `Bytes` offsets before scanning.
#cfg(any(target="native", target="wasm"))
fn find_byte_from_view(
  target : BytesView,
  start : Int,
  end : Int,
  byte : Byte,
) -> Int {
  let target_start = target.start_offset()
  let found = find_byte_from_bytes(
    target.data(),
    target_start + start,
    target_start + end,
    byte,
  )
  if found < 0 {
    -1
  } else {
    found - target_start
  }
}

///|
// Scalar short-pattern scanner: find matches for the last byte, then verify
// the unchecked prefix range for each candidate.
#cfg(any(target="js", target="wasm-gc"))
fn find_short(target : BytesView, pattern : BytesView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  let last_offset = pattern_len - 1
  let last_byte = pattern.unsafe_get(last_offset)
  for anchor_pos = last_offset; anchor_pos < target_len; {
    let found = find_byte_from_view(target, anchor_pos, target_len, last_byte)
    if found < 0 {
      break None
    }
    let candidate = found - last_offset
    if find_match_range(target, pattern, candidate, 0, last_offset) {
      break Some(candidate)
    }
    continue found + 1
  } nobreak {
    None
  }
}

///|
// SIMD short-pattern prefilter: match first and last bytes before scalar
// verification of the unchecked middle range.
#cfg(any(target="native", target="wasm"))
fn find_short_candidate_from_bytes(
  data : Bytes,
  start : Int,
  candidate_end : Int,
  first : Byte,
  last_offset : Int,
  last : Byte,
) -> Int {
  let first_v = i8x16_splat(first)
  let last_v = i8x16_splat(last)
  let tail_start = for pos = start; pos + 16 <= candidate_end; {
    let mask = v128_and(
      i8x16_eq(data.v128_load(pos), first_v),
      i8x16_eq(data.v128_load(pos + last_offset), last_v),
    )
    let bits = i8x16_bitmask(mask)
    if bits != 0 {
      return pos + bits.ctz()
    }
    continue pos + 16
  } nobreak {
    pos
  }
  for pos in tail_start..<candidate_end {
    if data.unsafe_get(pos) == first &&
      data.unsafe_get(pos + last_offset) == last {
      break pos
    }
  } nobreak {
    -1
  }
}

///|
// Native/wasm short-needle path: use the SIMD prefilter to skip most false
// candidates, then compare the unchecked middle range only on hits.
#cfg(any(target="native", target="wasm"))
fn find_short(target : BytesView, pattern : BytesView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  let last = target_len - pattern_len
  let target_start = target.start_offset()
  let candidate_end = target_start + last + 1
  let first = pattern.unsafe_get(0)
  let last_offset = pattern_len - 1
  let last_byte = pattern.unsafe_get(last_offset)
  for pos = 0; pos <= last; {
    let found = find_short_candidate_from_bytes(
      target.data(),
      target_start + pos,
      candidate_end,
      first,
      last_offset,
      last_byte,
    )
    if found < 0 {
      break None
    }
    let candidate = found - target_start
    if find_match_range(target, pattern, candidate, 1, last_offset) {
      break Some(candidate)
    }
    continue candidate + 1
  } nobreak {
    None
  }
}

///|
// Linear-time fallback for long needles. Hash matches are verified to avoid
// returning false positives from collisions.
fn find_rabin_karp_from(
  target : BytesView,
  pattern : BytesView,
  start : Int,
) -> Int? {
  fn hash(bytes : BytesView, start : Int, length : Int) -> UInt {
    for i in 0..<length; hash = 0U {
      continue hash * find_prime_rk + bytes.unsafe_get(start + i).to_uint()
    } nobreak {
      hash
    }
  }

  fn prime_pow(length : Int) -> UInt {
    for pow = 1U, square = find_prime_rk, exp = length; exp > 0; {
      let next_pow = if exp % 2 == 1 { pow * square } else { pow }
      continue next_pow, square * square, exp / 2
    } nobreak {
      pow
    }
  }

  let pattern_len = pattern.length()
  let target_len = target.length()
  if start + pattern_len > target_len {
    return None
  }
  let pattern_hash = hash(pattern, 0, pattern_len)
  let pow = prime_pow(pattern_len)
  let hash = hash(target, start, pattern_len)
  if hash == pattern_hash &&
    find_match_range(target, pattern, start, 0, pattern_len) {
    return Some(start)
  }
  for index = start + pattern_len, hash = hash; index < target_len; {
    let hash = hash * find_prime_rk + target.unsafe_get(index).to_uint()
    let hash = hash - pow * target.unsafe_get(index - pattern_len).to_uint()
    let candidate = index - pattern_len + 1
    if hash == pattern_hash &&
      find_match_range(target, pattern, candidate, 0, pattern_len) {
      break Some(candidate)
    }
    continue index + 1, hash
  } nobreak {
    None
  }
}

///|
// Long-needle scanner: start with first-byte candidates for common fast cases,
// but switch to Rabin-Karp after enough failed verifications.
fn find_long_by_byte_scanner(target : BytesView, pattern : BytesView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  let last = target_len - pattern_len
  let first_byte = pattern.unsafe_get(0)
  for pos = 0, failures = 0; pos <= last; {
    let found = find_byte_from_view(target, pos, target_len, first_byte)
    if found < 0 || found > last {
      break None
    }
    if find_match_range(target, pattern, found, 1, pattern_len) {
      break Some(found)
    }
    let failures = failures + 1
    if failures > find_max_bruteforce || failures > find_cutover(found) {
      break find_rabin_karp_from(target, pattern, found + 1)
    }
    continue found + 1, failures
  } nobreak {
    None
  }
}

///|
/// Returns the offset of the last occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn BytesView::rev_find(target : BytesView, pattern : BytesView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  if pattern_len == 0 {
    return Some(target_len)
  }
  if pattern_len > target_len {
    return None
  }
  if pattern_len == 1 {
    let byte = pattern.unsafe_get(0)
    return for i = target_len - 1; i >= 0; i = i - 1 {
      if target.unsafe_get(i) == byte {
        break Some(i)
      }
    } nobreak {
      None
    }
  }
  let last_offset = pattern_len - 1
  let first = pattern.unsafe_get(0)
  let last = pattern.unsafe_get(last_offset)
  for candidate = target_len - pattern_len
      candidate >= 0
      candidate = candidate - 1 {
    if target.unsafe_get(candidate) == first &&
      target.unsafe_get(candidate + last_offset) == last &&
      find_match_range(target, pattern, candidate, 1, last_offset) {
      return Some(candidate)
    }
  } nobreak {
    None
  }
}

///|
/// Returns the offset of the last occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn Bytes::rev_find(target : Bytes, pattern : BytesView) -> Int? {
  target[:].rev_find(pattern)
}

///|
/// Returns true if this bytes view starts with the given prefix.
pub fn BytesView::has_prefix(self : BytesView, prefix : BytesView) -> Bool {
  let prefix_len = prefix.length()
  self.length() >= prefix_len && self[:prefix_len] == prefix
}

///|
/// Returns true if this bytes starts with the given prefix.
pub fn Bytes::has_prefix(self : Bytes, prefix : BytesView) -> Bool {
  self[:].has_prefix(prefix)
}

///|
/// Returns true if this bytes view ends with the given suffix.
pub fn BytesView::has_suffix(self : BytesView, suffix : BytesView) -> Bool {
  let self_len = self.length()
  let suffix_len = suffix.length()
  self_len >= suffix_len && self[self_len - suffix_len:] == suffix
}

///|
/// Returns true if this bytes ends with the given suffix.
pub fn Bytes::has_suffix(self : Bytes, suffix : BytesView) -> Bool {
  self[:].has_suffix(suffix)
}

///|
/// Removes the given prefix from the view if it exists.
///
/// Returns `Some(suffix)` if the view starts with the given prefix.
/// Returns `None` otherwise.
pub fn BytesView::chop_prefix(
  self : BytesView,
  prefix : BytesView,
) -> BytesView? {
  let prefix_len = prefix.length()
  if self.length() >= prefix_len && self[:prefix_len] == prefix {
    Some(self[prefix_len:])
  } else {
    None
  }
}

///|
/// Removes the given prefix from the bytes if it exists.
pub fn Bytes::chop_prefix(self : Bytes, prefix : BytesView) -> BytesView? {
  self[:].chop_prefix(prefix)
}

///|
/// Removes the given suffix from the view if it exists.
///
/// Returns `Some(prefix)` if the view ends with the given suffix.
/// Returns `None` otherwise.
pub fn BytesView::chop_suffix(
  self : BytesView,
  suffix : BytesView,
) -> BytesView? {
  let self_len = self.length()
  let suffix_len = suffix.length()
  if self_len >= suffix_len && self[self_len - suffix_len:] == suffix {
    Some(self[:self_len - suffix_len])
  } else {
    None
  }
}

///|
/// Removes the given suffix from the bytes if it exists.
pub fn Bytes::chop_suffix(self : Bytes, suffix : BytesView) -> BytesView? {
  self[:].chop_suffix(suffix)
}
