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
/// The two capabilities the distance DP needs from its input: the pair of
/// lengths and cross-sequence equality by index. Lets `ArrayView` pairs and
/// `StringView` pairs (code units) share one implementation of the
/// trimming, banding, saturation, and overflow handling. The cores assume
/// the `a` side is at least as long as the `b` side; the public wrappers
/// swap first (the distance is symmetric).
priv trait LevInput {
  fn a_length(Self) -> Int
  fn b_length(Self) -> Int
  fn eq(Self, Int, Int) -> Bool
}

///|
priv struct ViewPair[T] {
  a : ArrayView[T]
  b : ArrayView[T]
}

///|
impl[T : Eq] LevInput for ViewPair[T] with fn a_length(self) {
  self.a.length()
}

///|
impl[T : Eq] LevInput for ViewPair[T] with fn b_length(self) {
  self.b.length()
}

///|
impl[T : Eq] LevInput for ViewPair[T] with fn eq(self, i, j) {
  self.a[i] == self.b[j]
}

///|
priv struct StrPair {
  a : StringView
  b : StringView
}

///|
impl LevInput for StrPair with fn a_length(self) {
  self.a.length()
}

///|
impl LevInput for StrPair with fn b_length(self) {
  self.b.length()
}

///|
impl LevInput for StrPair with fn eq(self, i, j) {
  self.a[i] == self.b[j]
}

///|
/// Distance core: trim the common prefix and suffix via `eq`, then run two
/// rolling rows over the (shorter) `b` side.
fn[S : LevInput] lev_distance(s : S) -> Int {
  let alen = s.a_length()
  let blen = s.b_length()
  let mut p = 0
  while p < blen && s.eq(p, p) {
    p += 1
  }
  let mut suffix = 0
  while suffix < blen - p && s.eq(alen - 1 - suffix, blen - 1 - suffix) {
    suffix += 1
  }
  let m = alen - p - suffix
  let n = blen - p - suffix
  if n == 0 {
    return m
  }
  // with m below @int.MAX_VALUE, no row allocation (n + 1 <= m + 1) or DP
  // addition (every candidate <= m + 1) can overflow
  guard m < @int.MAX_VALUE else { abort("edit_distance: input too large") }
  let mut prev = FixedArray::makei(n + 1, j => j)
  let mut cur = FixedArray::make(n + 1, 0)
  // loop bounds stay 0-based so no endpoint ever exceeds a view length
  for i0 in 0..<m {
    let i = i0 + 1
    cur[0] = i
    for j0 in 0..<n {
      let j = j0 + 1
      let sub = prev[j - 1] + (if s.eq(p + i - 1, p + j - 1) { 0 } else { 1 })
      let del = prev[j] + 1
      let ins = cur[j - 1] + 1
      let mut best = sub
      if del < best {
        best = del
      }
      if ins < best {
        best = ins
      }
      cur[j] = best
    }
    let t = prev
    prev = cur
    cur = t
  }
  prev[n]
}

///|
/// Banded-search core; `max_distance` is non-negative and below the length
/// of the (longer) `a` side after delegation.
fn[S : LevInput] lev_within(s : S, max_distance : Int) -> Int? {
  let alen = s.a_length()
  let blen = s.b_length()
  let mut p = 0
  while p < blen && s.eq(p, p) {
    p += 1
  }
  let mut suffix = 0
  while suffix < blen - p && s.eq(alen - 1 - suffix, blen - 1 - suffix) {
    suffix += 1
  }
  let m = alen - p - suffix
  let n = blen - p - suffix
  // the distance is at least the length difference
  if m - n > max_distance {
    return None
  }
  // a bound that covers the longer input can never be exceeded (the
  // distance is at most m); delegating also keeps `k + 1` below Int range
  if max_distance >= m {
    return Some(lev_distance(s))
  }
  // with m below @int.MAX_VALUE and values saturated at `inf` below, no row
  // allocation or DP addition can overflow (every candidate <= inf + 1 with
  // inf = k + 1 <= m)
  guard m < @int.MAX_VALUE else {
    abort("edit_distance_within: input too large")
  }
  let k = max_distance
  let inf = k + 1
  let mut prev = FixedArray::makei(n + 1, j => if j <= k { j } else { inf })
  let mut cur = FixedArray::make(n + 1, inf)
  for i0 in 0..<m {
    let i = i0 + 1
    let lo = if i - k > 1 { i - k } else { 1 }
    // i + k computed as a comparison against n - i to avoid overflow
    let hi = if k >= n - i { n } else { i + k }
    // cells left of the band are unreachable within the bound
    cur[lo - 1] = if lo == 1 && i <= k { i } else { inf }
    let mut row_min = inf
    for j in lo..<(hi + 1) {
      let sub = prev[j - 1] + (if s.eq(p + i - 1, p + j - 1) { 0 } else { 1 })
      let del = prev[j] + 1
      let ins = cur[j - 1] + 1
      let mut best = sub
      if del < best {
        best = del
      }
      if ins < best {
        best = ins
      }
      // saturate: anything past the bound is equally dead, and unclamped
      // stale cells could otherwise creep one past `inf` per row
      if best > inf {
        best = inf
      }
      cur[j] = best
      if best < row_min {
        row_min = best
      }
    }
    if row_min > k {
      return None
    }
    // seal the right edge so the next row reads it as out-of-band
    if hi < n {
      cur[hi + 1] = inf
    }
    let t = prev
    prev = cur
    cur = t
  }
  if prev[n] <= k {
    Some(prev[n])
  } else {
    None
  }
}

///|
/// `edit_distance(a, b)` returns the Levenshtein edit distance between `a`
/// and `b`: the minimum number of single-element insertions, deletions, and
/// substitutions that transform one into the other.
///
/// Every operation costs exactly 1. In particular a substitution costs 1,
/// not a deletion plus an insertion — this is the unit-cost Levenshtein
/// metric, distinct from the insert/delete-only distance that `Diff`'s
/// Myers machinery minimizes (and that `Diff::Diff`'s `cutoff` counts),
/// where replacing an element costs 2. Weighted costs are out of scope: all
/// operations are unit-cost.
///
/// The distance is symmetric (the parameters are positional and unordered),
/// `0` iff the inputs are equal, and at most `max(a.length(), b.length())`.
/// It operates on elements: for text, convert to `Array[Char]` first, which
/// yields Unicode-scalar-level distance (not grapheme or normalized-text
/// distance), or use `edit_distance_str` for UTF-16 code-unit distance with
/// no conversion of the inputs.
///
/// Runs in `O(a.length() * b.length())` time and
/// `O(min(a.length(), b.length()))` space, after trimming the common prefix
/// and suffix. When you only care whether the distance is small, use
/// `edit_distance_within`, which is faster on distant inputs.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(
///     @edit_distance.edit_distance("kitten".to_array(), "sitting".to_array()),
///     content="3",
///   )
///   inspect(@edit_distance.edit_distance([1, 2, 3], [1, 2, 3]), content="0")
///   inspect(@edit_distance.edit_distance([], [1, 2]), content="2")
/// }
/// ```
pub fn[T : Eq] edit_distance(a : ArrayView[T], b : ArrayView[T]) -> Int {
  let (a, b) = if a.length() >= b.length() { (a, b) } else { (b, a) }
  let s : ViewPair[T] = { a, b, }
  lev_distance(s)
}

///|
/// `edit_distance_within(a, b, max_distance~)` returns
/// `Some(edit_distance(a, b))` when the distance is at most `max_distance`,
/// and `None` otherwise.
///
/// A negative `max_distance` always yields `None`; `max_distance = 0` yields
/// `Some(0)` exactly when the inputs are equal.
///
/// Unlike `edit_distance`, the search is banded: it only explores alignments
/// within `max_distance` of the diagonal and bails out as soon as the bound
/// is exceeded, so it runs in
/// `O(min(max_distance, max(m, n)) * min(m, n))` time. This makes it the
/// right choice for threshold-based uses such as "did you mean" suggestions,
/// where most candidates are far away.
///
/// # Example
/// ```mbt check
/// test {
///   let a = "kitten".to_array()
///   let b = "sitting".to_array()
///   debug_inspect(
///     @edit_distance.edit_distance_within(a, b, max_distance=3),
///     content="Some(3)",
///   )
///   debug_inspect(
///     @edit_distance.edit_distance_within(a, b, max_distance=2),
///     content="None",
///   )
/// }
/// ```
pub fn[T : Eq] edit_distance_within(
  a : ArrayView[T],
  b : ArrayView[T],
  max_distance~ : Int,
) -> Int? {
  if max_distance < 0 {
    return None
  }
  let (a, b) = if a.length() >= b.length() { (a, b) } else { (b, a) }
  let s : ViewPair[T] = { a, b, }
  lev_within(s, max_distance)
}

///|
/// `edit_distance_str(a, b)` returns the Levenshtein edit distance between
/// two string views, counted in UTF-16 code units — the same unit as
/// `StringView::length()` and `s[i]` indexing. Each code-unit insertion,
/// deletion, and substitution costs exactly 1.
///
/// Working in code units means the inputs are used as-is — no conversion or
/// copying, only the DP's two scratch rows are allocated — with O(1)
/// comparisons. But characters outside the BMP occupy two units:
/// substituting one astral character for an unrelated one costs 2, though
/// related characters sharing a high surrogate still cost 1. For
/// Unicode-scalar distance, use `edit_distance` over `to_array()` views.
///
/// `String` arguments convert to views implicitly.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@edit_distance.edit_distance_str("kitten", "sitting"), content="3")
///   // 🍎 and 🍏 share a high surrogate: one unit apart
///   inspect(@edit_distance.edit_distance_str("🍎", "🍏"), content="1")
///   // 🙂 and 🍎 differ in both units
///   inspect(@edit_distance.edit_distance_str("🙂", "🍎"), content="2")
/// }
/// ```
pub fn edit_distance_str(a : StringView, b : StringView) -> Int {
  let (a, b) = if a.length() >= b.length() { (a, b) } else { (b, a) }
  let s : StrPair = { a, b, }
  lev_distance(s)
}

///|
/// `edit_distance_str_within(a, b, max_distance~)` returns
/// `Some(edit_distance_str(a, b))` when the code-unit distance is at most
/// `max_distance`, and `None` otherwise — the string counterpart of
/// `edit_distance_within`, with the same banded search and early bail-out.
///
/// # Example
/// ```mbt check
/// test {
///   debug_inspect(
///     @edit_distance.edit_distance_str_within("kitten", "sitting", max_distance=3),
///     content="Some(3)",
///   )
///   debug_inspect(
///     @edit_distance.edit_distance_str_within("kitten", "sitting", max_distance=2),
///     content="None",
///   )
/// }
/// ```
pub fn edit_distance_str_within(
  a : StringView,
  b : StringView,
  max_distance~ : Int,
) -> Int? {
  if max_distance < 0 {
    return None
  }
  let (a, b) = if a.length() >= b.length() { (a, b) } else { (b, a) }
  let s : StrPair = { a, b, }
  lev_within(s, max_distance)
}
