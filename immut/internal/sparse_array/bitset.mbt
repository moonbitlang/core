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
/// a simple bit set to store a set of integers less than 32
pub(all) struct Bitset(UInt) derive(Eq)

///|
let empty_bitset : Bitset = Bitset(0)

///|
/// Check if the given index is present in the bitset.
pub fn Bitset::has(self : Bitset, idx : Int) -> Bool {
  (self.0 & (1U << idx)) != 0
}

///|
/// Get the index of the bit in the bitset.
pub fn Bitset::index_of(self : Bitset, idx : Int) -> Int {
  (self.0 & ((1U << idx) - 1)).popcnt()
}

///|
pub fn Bitset::first_idx(self : Bitset) -> Int {
  self.0.ctz()
}

///|
pub fn Bitset::union(self : Bitset, other : Bitset) -> Bitset {
  Bitset(self.0 | other.0)
}

///|
pub fn Bitset::intersection(self : Bitset, other : Bitset) -> Bitset {
  Bitset(self.0 & other.0)
}

///|
/// Add a new index to the bitset.
pub fn Bitset::add(self : Bitset, idx : Int) -> Bitset {
  Bitset(self.0 | (1U << idx))
}

///|
/// Remove an index from the bitset.
pub fn Bitset::remove(self : Bitset, idx : Int) -> Bitset {
  Bitset(self.0 ^ (1U << idx))
}

///|
/// Calculate the size of a bitset
#alias(size, deprecated)
pub fn Bitset::length(self : Bitset) -> Int {
  let Bitset(self) = self
  self.popcnt()
}

///|
test "Bitset::has" {
  let b = empty_bitset.add(2)
  inspect(b.has(0), content="false")
  inspect(b.has(2), content="true")
  let b = b.add(0)
  inspect(b.has(0), content="true")
  inspect(b.has(2), content="true")
}

///|
test "Bitset::index_of" {
  let b = empty_bitset.add(2)
  inspect(b.index_of(2), content="0")
  let b = b.add(0)
  inspect(b.index_of(2), content="1")
  let b = b.add(5)
  inspect(b.index_of(2), content="1")
  // when elem is missing
  inspect(b.index_of(3), content="2")
  inspect(b.index_of(4), content="2")
  // 5 is
  inspect(b.index_of(5), content="2")
  // 6 is not
  inspect(b.index_of(6), content="3")
}

///|
test "Bitset::union" {
  let b1 = empty_bitset.add(2).add(3)
  let b2 = empty_bitset.add(0).add(1)
  let b3 = b1.union(b2)
  inspect(b3.has(0), content="true")
  inspect(b3.has(1), content="true")
  inspect(b3.has(2), content="true")
  inspect(b3.has(3), content="true")
}

///|
test "Bitset::intersection" {
  let b1 = empty_bitset.add(2).add(3)
  let b2 = empty_bitset.add(0).add(1).add(2)
  let b3 = b1.intersection(b2)
  inspect(b3.has(0), content="false")
  inspect(b3.has(1), content="false")
  inspect(b3.has(2), content="true")
  inspect(b3.has(3), content="false")
}

///|
test "Bitset::remove" {
  let b = empty_bitset.add(2).add(3)
  inspect(b.has(2), content="true")
  inspect(b.has(3), content="true")
  inspect(b.index_of(2), content="0")
  inspect(b.index_of(3), content="1")
  let b = b.remove(2)
  inspect(b.has(2), content="false")
  inspect(b.has(3), content="true")
  inspect(b.index_of(3), content="0")
}

///|
test "Bitset::size" {
  let b = empty_bitset
  inspect(b.length(), content="0")
  let b = b.add(0)
  inspect(b.length(), content="1")
  let b = b.add(1)
  inspect(b.length(), content="2")
  let b = b.add(1)
  inspect(b.length(), content="2")
}

///|
test "Bitset::ctpop" {
  inspect(
    ([0, 0xf0f0f0f0, 0x3c3c0ff0] : Array[_]).map(x => x.popcnt()),
    content="[0, 16, 16]",
  )
}
