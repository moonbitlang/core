// Copyright 2024 International Digital Economy Academy
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

/// a simple bit set to store a set of integers less than 32
priv type Bitset Int

let empty_bitset : Bitset = Bitset(0)

/// `has(self: Bitset, idx: Int)`
///
/// Check if the given index is present in the bitset.
fn has(self : Bitset, idx : Int) -> Bool {
  self.0.land((1).lsl(idx)) != 0
}

test "Bitset::has" {
  let b = empty_bitset.add(2)
  @assertion.assert_false(b.has(0))?
  @assertion.assert_true(b.has(2))?
  let b = b.add(0)
  @assertion.assert_true(b.has(0))?
  @assertion.assert_true(b.has(2))?
}

/// `index_of(self: Bitset, idx: Int)`
///
/// Get the index of the bit in the bitset.
fn index_of(self : Bitset, idx : Int) -> Int {
  let items_below_idx = self.0.land((1).lsl(idx) - 1)
  ctpop(items_below_idx)
}

test "Bitset::index_of" {
  let b = empty_bitset.add(2)
  @assertion.assert_eq(b.index_of(2), 0)?
  let b = b.add(0)
  @assertion.assert_eq(b.index_of(2), 1)?
  let b = b.add(5)
  @assertion.assert_eq(b.index_of(2), 1)?
}

/// `add(self: Bitset, idx: Int)`
///
/// Add a new index to the bitset.
fn add(self : Bitset, idx : Int) -> Bitset {
  Bitset(self.0.lor((1).lsl(idx)))
}

/// `remove(self: Bitset, idx: Int)`
///
/// Remove an index from the bitset.
fn remove(self : Bitset, idx : Int) -> Bitset {
  Bitset(self.0.lxor((1).lsl(idx)))
}

test "Bitset::remove" {
  let b = empty_bitset.add(2).add(3)
  @assertion.assert_true(b.has(2))?
  @assertion.assert_true(b.has(3))?
  @assertion.assert_eq(b.index_of(2), 0)?
  @assertion.assert_eq(b.index_of(3), 1)?
  let b = b.remove(2)
  @assertion.assert_false(b.has(2))?
  @assertion.assert_true(b.has(3))?
  @assertion.assert_eq(b.index_of(3), 0)?
}

/// `size(self: Bitset) -> Int`
///
/// Calculate the size of a bitset
fn size(self : Bitset) -> Int {
  ctpop(self.0)
}

test "Bitset::size" {
  let b = empty_bitset
  @assertion.assert_eq(b.size(), 0)?
  let b = b.add(0)
  @assertion.assert_eq(b.size(), 1)?
  let b = b.add(1)
  @assertion.assert_eq(b.size(), 2)?
  let b = b.add(1)
  @assertion.assert_eq(b.size(), 2)?
}

/// `ctpop(n: Int)`
///
/// Count the number of set bits (1s) in a 32-bit integer.
fn ctpop(n : Int) -> Int {
  // extract the lower bit of every 2-bit group
  let low_of_2bits = 0x55555555
  // count the number of "1"s in every 2-bit group
  // store the result in the same 2-bit group
  let c2 = n.land(low_of_2bits) + n.lsr(1).land(low_of_2bits)
  // count the number of "1"s in every 4-bit group (i.e. two 2-bit groups),
  // store the result in the same 4-bit group
  let low_of_4bits = 0x33333333
  let c4 = c2.land(low_of_4bits) + c2.lsr(2).land(low_of_4bits)
  // similarly for every 8-bit group
  let low_of_8bits = 0x0f0f0f0f
  let c8 = c4.land(low_of_8bits) + c4.lsr(4).land(low_of_8bits)
  // 16-bit group.
  // there will be only two groups left, without rist of overlapping,
  // so there's no need to clean the unused higher bits
  let c16 = c8 + c8.lsr(8)
  // the final 32-bit group
  // [ctpop(x) <= 32], so only the last 6 bits are meaningful
  let lower_6bits = 63 // 0x3f
  (c16 + c16.lsr(16)).land(lower_6bits)
}

test "Bitset::ctpop" {
  @assertion.assert_eq(ctpop(0), 0)?
  @assertion.assert_eq(ctpop(0xf0f0f0f0), 16)?
  @assertion.assert_eq(ctpop(0x3c3c0ff0), 16)?
}
