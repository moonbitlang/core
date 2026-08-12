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
// `immut/hashmap`, so every operation must leave the trie in the canonical
// shape a fresh construction of the same content would have. These tests
// pin that contract for the shrinking operations (`remove`,
// `intersection`, `difference`) and for the insert path at maximum trie
// depth, mirroring the hashmap suite from the canonicalization work.

///|
/// Elements whose 32-bit hash keeps only the low three bits, so values
/// agreeing on `n & 7` collide on the whole stored path.
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
/// Elements whose hash lives only in the top path segment (bits 25..=29):
/// all values share path segments 1-5, so they diverge — or fully collide —
/// only at the maximum trie depth.
priv struct DeepElem(Int) derive(Eq)

///|
impl Hash for DeepElem with fn hash(self) {
  (self.0 & 3) << 25
}

///|
impl Hash for DeepElem with fn hash_combine(self, hasher) {
  hasher.combine_int((self.0 & 3) << 25)
}

///|
test "removing a colliding element restores the canonical structure" {
  let original : @hashset.HashSet[CollidingElem] = HashSet([CollidingElem(0)])
  let round_trip = original.add(CollidingElem(24)).remove(CollidingElem(24))
  assert_true(round_trip == original)
}

///|
test "chained removals from a collision bucket collapse in any order" {
  // 0, 8, and 24 all hash to bucket 0, forming a three-element collision
  // node.
  let all : @hashset.HashSet[CollidingElem] = @hashset.new()
    .add(CollidingElem(0))
    .add(CollidingElem(8))
    .add(CollidingElem(24))
  let one_way = all.remove(CollidingElem(8)).remove(CollidingElem(24))
  let other_way = all.remove(CollidingElem(24)).remove(CollidingElem(8))
  assert_true(one_way == HashSet([CollidingElem(0)]))
  assert_true(one_way == other_way)
}

///|
test "difference removing a colliding element yields the canonical set" {
  let original : @hashset.HashSet[CollidingElem] = HashSet([CollidingElem(0)])
  let both = original.add(CollidingElem(24))
  let only_other : @hashset.HashSet[CollidingElem] = HashSet([CollidingElem(24)])
  assert_true(both.difference(only_other) == original)
}

///|
test "intersection dropping a colliding element yields the canonical set" {
  let left : @hashset.HashSet[CollidingElem] = HashSet([
    CollidingElem(0),
    CollidingElem(24),
  ])
  let right : @hashset.HashSet[CollidingElem] = HashSet([
    CollidingElem(0),
    CollidingElem(8),
  ])
  assert_true(left.intersection(right) == HashSet([CollidingElem(0)]))
}

///|
test "insertion order cannot affect the structure at maximum depth" {
  let one_way : @hashset.HashSet[DeepElem] = @hashset.new()
    .add(DeepElem(0))
    .add(DeepElem(1))
    .add(DeepElem(2))
  let other_way : @hashset.HashSet[DeepElem] = @hashset.new()
    .add(DeepElem(2))
    .add(DeepElem(1))
    .add(DeepElem(0))
  assert_true(one_way == other_way)
}

///|
test "removing a maximum-depth sibling leaves the canonical structure" {
  let removed = @hashset.new()
    .add(DeepElem(0))
    .add(DeepElem(1))
    .add(DeepElem(2))
    .remove(DeepElem(1))
  let fresh : @hashset.HashSet[DeepElem] = @hashset.new()
    .add(DeepElem(0))
    .add(DeepElem(2))
  assert_true(removed == fresh)
}

///|
test "path collision arriving at a maximum-depth Flat stays canonical" {
  // 2 and 6 collide on every path segment. Adding 0 and 1 first forces
  // the maximum-depth branch into existence, so DeepElem(2) is stored
  // there as a single element with a fully consumed path when DeepElem(6)
  // arrives.
  let one_way : @hashset.HashSet[DeepElem] = @hashset.new()
    .add(DeepElem(0))
    .add(DeepElem(1))
    .add(DeepElem(2))
    .add(DeepElem(6))
  let other_way : @hashset.HashSet[DeepElem] = @hashset.new()
    .add(DeepElem(2))
    .add(DeepElem(6))
    .add(DeepElem(0))
    .add(DeepElem(1))
  assert_true(one_way.contains(DeepElem(2)))
  assert_true(one_way.contains(DeepElem(6)))
  assert_eq(one_way.length(), 4)
  assert_true(one_way == other_way)
}

///|
test "bulk construction agrees with incremental adds at maximum depth" {
  // 80 elements exceed the bulk-build threshold (64), so the constructor
  // and a sized `from_iter` take the range-partitioning bulk builder,
  // whose bottom-level handoff must produce the same canonical shapes as
  // plain `add` — here four maximum-depth collision buckets of 20 keys.
  let elems : Array[DeepElem] = []
  for i in 0..<80 {
    elems.push(DeepElem(i))
  }
  let bulk : @hashset.HashSet[DeepElem] = HashSet(elems)
  let via_iter = @hashset.from_iter(elems.iter())
  let mut added : @hashset.HashSet[DeepElem] = @hashset.new()
  for e in elems {
    added = added.add(e)
  }
  let mut reversed : @hashset.HashSet[DeepElem] = @hashset.new()
  for i in 0..<elems.length() {
    reversed = reversed.add(elems[elems.length() - 1 - i])
  }
  assert_eq(bulk.length(), 80)
  assert_true(bulk == added)
  assert_true(via_iter == added)
  assert_true(reversed == added)
}

///|
test "bulk construction eliminates duplicates canonically" {
  // 96 entries over 12 distinct elements exceed the bulk threshold while
  // forcing duplicate elimination inside the bulk builder, through both
  // of its traversal directions (constructor and sized `from_iter`).
  let elems : Array[DeepElem] = []
  for i in 0..<96 {
    elems.push(DeepElem(i % 12))
  }
  let distinct_elems : Array[DeepElem] = []
  for i in 0..<12 {
    distinct_elems.push(DeepElem(i))
  }
  let bulk : @hashset.HashSet[DeepElem] = HashSet(elems)
  let via_iter = @hashset.from_iter(elems.iter())
  let mut added : @hashset.HashSet[DeepElem] = @hashset.new()
  for e in elems {
    added = added.add(e)
  }
  let distinct : @hashset.HashSet[DeepElem] = HashSet(distinct_elems)
  assert_eq(bulk.length(), 12)
  assert_true(bulk == added)
  assert_true(via_iter == added)
  assert_true(bulk == distinct)
}
