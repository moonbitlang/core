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

// The tests below pin canonicity at the maximum trie depth, where a single
// entry historically had two representations: `add` into an existing
// bottom-level branch stored `Flat(k, v, exhausted-path)` while `join_2`
// splitting a `Flat` stored `Leaf(k, v, Empty)`. Content-equal maps built
// through different histories then compared unequal.

///|
/// Keys whose hash lives only in the top path segment (bits 25..=29): all
/// keys share path segments 1-5, so they diverge — or fully collide — only
/// at the maximum trie depth.
priv struct DeepKey(Int) derive(Eq)

///|
impl Hash for DeepKey with fn hash(self) {
  (self.0 & 3) << 25
}

///|
impl Hash for DeepKey with fn hash_combine(self, hasher) {
  hasher.combine_int((self.0 & 3) << 25)
}

///|
test "insertion order cannot affect the structure at maximum depth" {
  let one_way : @hashmap.HashMap[DeepKey, Int] = @hashmap.new()
    .add(DeepKey(0), 0)
    .add(DeepKey(1), 1)
    .add(DeepKey(2), 2)
  let other_way : @hashmap.HashMap[DeepKey, Int] = @hashmap.new()
    .add(DeepKey(2), 2)
    .add(DeepKey(1), 1)
    .add(DeepKey(0), 0)
  assert_true(one_way == other_way)
}

///|
test "removing a maximum-depth sibling leaves the canonical structure" {
  let removed = @hashmap.new()
    .add(DeepKey(0), 0)
    .add(DeepKey(1), 1)
    .add(DeepKey(2), 2)
    .remove(DeepKey(1))
  let fresh : @hashmap.HashMap[DeepKey, Int] = @hashmap.new()
    .add(DeepKey(0), 0)
    .add(DeepKey(2), 2)
  assert_true(removed == fresh)
}

///|
test "full-hash collision arriving at a maximum-depth Flat stays canonical" {
  // 2 and 6 collide on the full hash. Adding 0 and 1 first forces the
  // maximum-depth branch into existence, so DeepKey(2) is stored there as
  // a single entry with a fully consumed path when DeepKey(6) arrives.
  let one_way : @hashmap.HashMap[DeepKey, Int] = @hashmap.new()
    .add(DeepKey(0), 0)
    .add(DeepKey(1), 1)
    .add(DeepKey(2), 2)
    .add(DeepKey(6), 6)
  let other_way : @hashmap.HashMap[DeepKey, Int] = @hashmap.new()
    .add(DeepKey(2), 2)
    .add(DeepKey(6), 6)
    .add(DeepKey(0), 0)
    .add(DeepKey(1), 1)
  assert_eq(one_way.get(DeepKey(2)), Some(2))
  assert_eq(one_way.get(DeepKey(6)), Some(6))
  assert_eq(one_way.length(), 4)
  assert_true(one_way == other_way)
}

///|
test "bulk construction agrees with incremental adds at maximum depth" {
  // 80 entries exceed the bulk-build threshold (64), so the constructor
  // and a sized `from_iter` take the range-partitioning bulk builder,
  // whose bottom-level handoff must produce the same canonical shapes as
  // plain `add` — here four maximum-depth collision buckets of 20 keys.
  let pairs : Array[(DeepKey, Int)] = []
  for i in 0..<80 {
    pairs.push((DeepKey(i), i))
  }
  let bulk : @hashmap.HashMap[DeepKey, Int] = HashMap(pairs)
  let via_iter = @hashmap.from_iter(pairs.iter())
  let mut added : @hashmap.HashMap[DeepKey, Int] = @hashmap.new()
  for kv in pairs {
    added = added.add(kv.0, kv.1)
  }
  let mut reversed : @hashmap.HashMap[DeepKey, Int] = @hashmap.new()
  for i in 0..<pairs.length() {
    let kv = pairs[pairs.length() - 1 - i]
    reversed = reversed.add(kv.0, kv.1)
  }
  assert_eq(bulk.length(), 80)
  assert_true(bulk == added)
  assert_true(via_iter == added)
  assert_true(reversed == added)
}

///|
test "intersection dropping a colliding key yields the canonical map" {
  // Pins the `intersection`/`intersection_with` call sites that collapse
  // shrunken branches (values come from the right-hand side).
  let left : @hashmap.HashMap[CollidingKey, Int] = @hashmap.singleton(
    CollidingKey(0),
    0,
  ).add(CollidingKey(24), 1)
  let right : @hashmap.HashMap[CollidingKey, Int] = @hashmap.singleton(
    CollidingKey(0),
    0,
  ).add(CollidingKey(8), 2)
  let expected : @hashmap.HashMap[CollidingKey, Int] = @hashmap.singleton(
    CollidingKey(0),
    0,
  )
  assert_true(left.intersection(right) == expected)
  assert_true(left.intersection_with(right, (_, x, y) => x + y) == expected)
}
