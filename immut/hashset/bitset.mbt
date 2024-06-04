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

/// `index_of(self: Bitset, idx: Int)`
///
/// Get the index of the bit in the bitset.
fn index_of(self : Bitset, idx : Int) -> Int {
  self.0.land((1).lsl(idx) - 1).popcnt()
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

/// `size(self: Bitset) -> Int`
///
/// Calculate the size of a bitset
fn size(self : Bitset) -> Int {
  self.0.popcnt()
}
