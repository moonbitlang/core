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

// `HashSet` shares the HAMT design (and its structural `Eq`) with
// `immut/hashmap`, so shrinking operations must likewise collapse to the
// canonical shape a fresh construction would have. Before the fix,
// removing an element from a full-hash collision bucket left a
// non-canonical `Leaf(k, Empty)` node, making content-equal sets compare
// unequal; `difference` shares the same path.

///|
/// Elements whose 32-bit hash keeps only the low three bits, so values
/// agreeing on `n & 7` collide on the full hash.
priv struct CollidingElem(Int) derive(Eq)

///|
impl Hash for CollidingElem with fn hash(self) {
  self.0 & 7
}

///|
impl Hash for CollidingElem with fn hash_combine(self, hasher) {
  hasher.combine_int(self.0 & 7)
}

///|
test "removing a colliding element restores the canonical structure" {
  let original : @hashset.HashSet[CollidingElem] = HashSet([CollidingElem(0)])
  let round_trip = original.add(CollidingElem(24)).remove(CollidingElem(24))
  assert_true(round_trip == original)
}

///|
test "difference removing a colliding element yields the canonical set" {
  let original : @hashset.HashSet[CollidingElem] = HashSet([CollidingElem(0)])
  let both = original.add(CollidingElem(24))
  let only_other : @hashset.HashSet[CollidingElem] = HashSet([CollidingElem(24)])
  assert_true(both.difference(only_other) == original)
}
