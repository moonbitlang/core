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

// `HashMap` derives structural `Eq`, so every operation must leave the tree
// in the canonical shape a fresh construction of the same content would
// have. These tests pin that contract for the shrinking operations
// (`remove`, `filter`, `difference`): before the fix, they left
// non-canonical remnants — an uncollapsed singleton branch after `filter`,
// and a `Leaf(k, v, Empty)` node (instead of the collapsed `Flat`) after
// removing from a full-hash collision bucket — making content-equal maps
// compare unequal.
//
// Found by the QuickCheck property suite in #3999.

///|
/// Keys whose 32-bit hash keeps only the low three bits, so keys that agree
/// on `n & 7` collide on the full hash while `Eq` still distinguishes them.
priv struct CollidingKey(Int) derive(Eq)

///|
impl Hash for CollidingKey with fn hash(self) {
  self.0 & 7
}

///|
impl Hash for CollidingKey with fn hash_combine(self, hasher) {
  hasher.combine_int(self.0 & 7)
}

///|
test "removing a colliding key restores the canonical structure" {
  let original : @hashmap.HashMap[CollidingKey, Int] = @hashmap.singleton(
    CollidingKey(0),
    0,
  )
  let round_trip = original.add(CollidingKey(24), 0).remove(CollidingKey(24))
  assert_true(round_trip == original)
  assert_true(round_trip == @hashmap.singleton(CollidingKey(0), 0))
}

///|
test "filter down to one key yields the canonical map" {
  // No hash collisions involved: `filter` must collapse the branch that
  // shrank to a single entry, exactly like `remove` does.
  let original : @hashmap.HashMap[Int, Int] = @hashmap.singleton(0, 0)
  assert_true(original.add(1, 1).filter((k, _) => k == 0) == original)
}

///|
test "filter dropping a colliding key yields the canonical map" {
  let original : @hashmap.HashMap[CollidingKey, Int] = @hashmap.singleton(
    CollidingKey(0),
    0,
  )
  let filtered = original
    .add(CollidingKey(24), 1)
    .filter((k, _) => k == CollidingKey(0))
  assert_true(filtered == original)
}

///|
test "difference removing a colliding key yields the canonical map" {
  let original : @hashmap.HashMap[CollidingKey, Int] = @hashmap.singleton(
    CollidingKey(0),
    0,
  )
  let both = original.add(CollidingKey(24), 1)
  let only_other : @hashmap.HashMap[CollidingKey, Int] = @hashmap.singleton(
    CollidingKey(24),
    1,
  )
  assert_true(both.difference(only_other) == original)
}

///|
test "chained removals from a collision bucket collapse in any order" {
  // 0, 8, and 24 all hash to bucket 0, forming a three-entry collision node.
  let base : @hashmap.HashMap[CollidingKey, Int] = @hashmap.new()
  let all = base
    .add(CollidingKey(0), 0)
    .add(CollidingKey(8), 1)
    .add(CollidingKey(24), 2)
  let one_way = all.remove(CollidingKey(8)).remove(CollidingKey(24))
  let other_way = all.remove(CollidingKey(24)).remove(CollidingKey(8))
  assert_true(one_way == @hashmap.singleton(CollidingKey(0), 0))
  assert_true(one_way == other_way)
}
