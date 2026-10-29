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
/// A set of bytes `0..=255` as a 256-bit bitmap: the byte counterpart of the
/// interval tree `RecharSet` of the string engine. The engine also uses it
/// for sets of symbols, which are never more than 256. The words are 32-bit
/// so that the JavaScript backend needs no 64-bit arithmetic.
struct ByteSet {
  w0 : UInt32
  w1 : UInt32
  w2 : UInt32
  w3 : UInt32
  w4 : UInt32
  w5 : UInt32
  w6 : UInt32
  w7 : UInt32
}

///|
/// The set without any byte.
pub fn ByteSet::empty() -> ByteSet {
  { w0: 0, w1: 0, w2: 0, w3: 0, w4: 0, w5: 0, w6: 0, w7: 0, }
}

///|
/// Every byte.
pub fn ByteSet::full() -> ByteSet {
  ByteSet::char_range(0, 255)
}

///|
/// Bits `lo..=hi` of the word that holds `base..=base + 31`. Both bounds are
/// in `0..=255`, so nothing below overflows.
fn range_mask(lo : Int32, hi : Int32, base : Int32) -> UInt32 {
  let lo = Int32::max(lo, base) - base
  let hi = Int32::min(hi, base + 31) - base
  if lo > hi {
    0
  } else {
    (0xFFFF_FFFFU >> (31 - hi)) & (0xFFFF_FFFFU << lo)
  }
}

///|
/// The bytes `lo..=hi`; the part of the range outside `0..=255` is dropped.
pub fn ByteSet::char_range(lo : Int32, hi : Int32) -> ByteSet {
  let lo = Int32::max(lo, 0)
  let hi = Int32::min(hi, 255)
  guard lo <= hi else { ByteSet::empty() }
  {
    w0: range_mask(lo, hi, 0),
    w1: range_mask(lo, hi, 32),
    w2: range_mask(lo, hi, 64),
    w3: range_mask(lo, hi, 96),
    w4: range_mask(lo, hi, 128),
    w5: range_mask(lo, hi, 160),
    w6: range_mask(lo, hi, 192),
    w7: range_mask(lo, hi, 224),
  }
}

///|
/// The set of the single byte `c`.
pub fn ByteSet::char(c : Int32) -> ByteSet {
  ByteSet::char_range(c, c)
}

///|
/// Word `i` of the bitmap, bytes `32 * i..=32 * i + 31`.
fn ByteSet::word(self : ByteSet, i : Int32) -> UInt32 {
  match i {
    0 => self.w0
    1 => self.w1
    2 => self.w2
    3 => self.w3
    4 => self.w4
    5 => self.w5
    6 => self.w6
    _ => self.w7
  }
}

///|
/// Whether `c` is in the set. Values outside `0..=255` never are.
pub fn ByteSet::contains(self : ByteSet, c : Int32) -> Bool {
  guard c >= 0 && c < 256 else { false }
  ((self.word(c >> 5) >> (c & 31)) & 1) != 0
}

///|
/// Whether the set has no byte.
pub fn ByteSet::is_empty(self : ByteSet) -> Bool {
  (
    self.w0 |
    self.w1 |
    self.w2 |
    self.w3 |
    self.w4 |
    self.w5 |
    self.w6 |
    self.w7
  ) ==
  0
}

///|
fn ByteSet::zip(
  self : ByteSet,
  other : ByteSet,
  f : (UInt32, UInt32) -> UInt32,
) -> ByteSet {
  {
    w0: f(self.w0, other.w0),
    w1: f(self.w1, other.w1),
    w2: f(self.w2, other.w2),
    w3: f(self.w3, other.w3),
    w4: f(self.w4, other.w4),
    w5: f(self.w5, other.w5),
    w6: f(self.w6, other.w6),
    w7: f(self.w7, other.w7),
  }
}

///|
/// The bytes in either set.
pub fn ByteSet::union(self : ByteSet, other : ByteSet) -> ByteSet {
  self.zip(other, (a, b) => a | b)
}

///|
/// The bytes in both sets.
pub fn ByteSet::intersection(self : ByteSet, other : ByteSet) -> ByteSet {
  self.zip(other, (a, b) => a & b)
}

///|
/// The bytes of `self` that are not in `other`.
pub fn ByteSet::difference(self : ByteSet, other : ByteSet) -> ByteSet {
  self.zip(other, (a, b) => a & b.lnot())
}

///|
/// Same as `union`.
pub impl Add for ByteSet with fn add(self, other) {
  self.union(other)
}

///|
/// Same as `intersection`.
pub impl BitAnd for ByteSet with fn land(self, other) {
  self.intersection(other)
}

///|
/// Same as `difference`.
pub impl Sub for ByteSet with fn sub(self, other) {
  self.difference(other)
}

///|
/// The maximal runs `(lo, hi)` of the set, in ascending order.
pub fn ByteSet::intervals(self : ByteSet) -> Iter[(Int32, Int32)] {
  let runs = []
  let mut c = 0
  while c < 256 {
    if (c & 31) == 0 && self.word(c >> 5) == 0 {
      c += 32
    } else if self.contains(c) {
      let lo = c
      while c < 256 && self.contains(c) {
        c += 1
      }
      runs.push((lo, c - 1))
    } else {
      c += 1
    }
  }
  runs.iter()
}

///|
/// The image of the set under `f`. Images outside `0..=255` are dropped.
pub fn ByteSet::offset_by(self : ByteSet, f : (Int32) -> Int32) -> ByteSet {
  let mut out = ByteSet::empty()
  for c in 0..<256 {
    if self.contains(c) {
      out = out + ByteSet::char(f(c))
    }
  }
  out
}

///|
/// The runs of the set, as `intervals` lists them.
pub impl @debug.Debug for ByteSet with fn to_repr(self) {
  Repr(self.intervals().to_array())
}
