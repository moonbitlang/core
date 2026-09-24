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
priv struct Rng {
  mut s : UInt64
}

///|
fn Rng::next(self : Rng, n : Int) -> Int {
  self.s = self.s * 6364136223846793005UL + 1442695040888963407UL
  ((self.s >> 33).to_int() & 0x7FFFFFFF) % n
}

///|
const DOM = 40

///|
fn to_bits(s : RecharSet) -> UInt64 {
  let mut b = 0UL
  for c in 0..<DOM {
    if s.contains(c) {
      b = b | (1UL << c)
    }
  }
  b
}

///|
/// Intervals must be ascending, non-empty, and neither overlapping nor
/// adjacent (adjacent runs are merged on construction).
fn is_canonical(s : RecharSet) -> Bool {
  let mut prev_hi = -0x80000000
  let mut first = true
  for iv in s.intervals() {
    let (lo, hi) = iv
    if lo > hi || (!first && lo <= prev_hi + 1) {
      return false
    }
    first = false
    prev_hi = hi
  }
  true
}

///|
fn rand_set(r : Rng, depth : Int) -> RecharSet {
  if depth == 0 || r.next(3) == 0 {
    let k = r.next(4)
    let mut s = RecharSet::empty()
    for _ in 0..<k {
      let lo = r.next(DOM)
      let hi = lo + r.next(DOM - lo)
      s = s + RecharSet::char_range(lo, hi)
    }
    s
  } else {
    let a = rand_set(r, depth - 1)
    let b = rand_set(r, depth - 1)
    match r.next(3) {
      0 => a + b
      1 => a & b
      _ => a - b
    }
  }
}

///|
test "union merges a run that touches an interval in the middle of a subtree" {
  // Regression: the merge step used to inspect the wrong end of the
  // neighbouring subtree, leaving [0,0] and [1,1] unmerged.
  let s = RecharSet::char_range(0, 0) +
    RecharSet::char_range(3, 3) +
    RecharSet::char_range(1, 1)
  assert_true(s.intervals().to_array() == [(0, 1), (3, 3)])
  let t = RecharSet::char_range(9, 9) +
    RecharSet::char_range(5, 6) +
    RecharSet::char_range(7, 8)
  assert_true(t.intervals().to_array() == [(5, 9)])
}

///|
test "set algebra agrees with a bitset and stays canonical" {
  let r = { s: 99UL, }
  let mask = (1UL << DOM) - 1UL
  let full = RecharSet::char_range(0, DOM - 1)
  for _ in 0..<3000 {
    let a = rand_set(r, 3)
    let b = rand_set(r, 3)
    assert_true(is_canonical(a))
    let ba = to_bits(a)
    let bb = to_bits(b)
    assert_true(to_bits(a + b) == (ba | bb))
    assert_true(to_bits(a & b) == (ba & bb))
    assert_true(to_bits(a - b) == (ba & bb.lnot()))
    assert_true((to_bits(full - a) & mask) == (ba.lnot() & mask))
    assert_true(a.is_subset(b) == ((ba & bb.lnot()) == 0UL))
    assert_true(a.is_empty() == (ba == 0UL))
    let rebuilt = RecharSet::from_sorted_array(a.intervals().to_array())
    assert_true(to_bits(rebuilt) == ba)
    assert_true(is_canonical(rebuilt))
    assert_true(to_bits(a.offset_by(c => c + 1)) == ((ba << 1) & mask))
  }
}

///|
test "extreme bounds" {
  let all = RecharSet::char_range(-0x80000000, 0x7FFFFFFF)
  assert_true((all - all).is_empty())
  let s = RecharSet::char_range(0x7FFFFFF0, 0x7FFFFFFF) +
    RecharSet::char_range(-0x80000000, -0x7FFFFFF0)
  assert_true(s.contains(0x7FFFFFFF))
  assert_true(s.contains(-0x80000000))
  let c = all - s
  assert_true(!c.contains(0x7FFFFFFF))
  assert_true(c.contains(0))
  assert_true((all - c).intervals().to_array() == s.intervals().to_array())
}
