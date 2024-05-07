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
  inspect(b.has(0), content="false")?
  inspect(b.has(2), content="true")?
  let b = b.add(0)
  inspect(b.has(0), content="true")?
  inspect(b.has(2), content="true")?
}

/// `index_of(self: Bitset, idx: Int)`
///
/// Get the index of the bit in the bitset.
fn index_of(self : Bitset, idx : Int) -> Int {
  self.0.land((1).lsl(idx) - 1).popcnt()
}

test "Bitset::index_of" {
  let b = empty_bitset.add(2)
  inspect(b.index_of(2), content="0")?
  let b = b.add(0)
  inspect(b.index_of(2), content="1")?
  let b = b.add(5)
  inspect(b.index_of(2), content="1")?
  // when elem is missing  
  inspect(b.index_of(3), content="2")?
  inspect(b.index_of(4), content="2")?
  // 5 is 
  inspect(b.index_of(5), content="2")?
  // 6 is not
  inspect(b.index_of(6), content="3")?
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
  inspect(b.has(2), content="true")?
  inspect(b.has(3), content="true")?
  inspect(b.index_of(2), content="0")?
  inspect(b.index_of(3), content="1")?
  let b = b.remove(2)
  inspect(b.has(2), content="false")?
  inspect(b.has(3), content="true")?
  inspect(b.index_of(3), content="0")?
}

/// `size(self: Bitset) -> Int`
///
/// Calculate the size of a bitset
fn size(self : Bitset) -> Int {
  self.0.popcnt()
}

test "Bitset::size" {
  let b = empty_bitset
  inspect(b.size(), content="0")?
  let b = b.add(0)
  inspect(b.size(), content="1")?
  let b = b.add(1)
  inspect(b.size(), content="2")?
  let b = b.add(1)
  inspect(b.size(), content="2")?
}

test "Bitset::ctpop" {
  inspect(
    [0, 0xf0f0f0f0, 0x3c3c0ff0].map(fn { x => x.popcnt() }),
    content="[0, 16, 16]",
  )?
}
