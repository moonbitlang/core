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

/// Create new hash set.
pub fn HashSet::new[K](~hasher : Option[(K) -> Int] = None) -> HashSet[K] {
  HashSet(@robinhood_hash.new(~hasher))
}

/// Create new hash set from array.
pub fn HashSet::from_array[K : Hash + Eq](arr : Array[K]) -> HashSet[K] {
  // Sadly we cannot do type casting from Array[K] to Array[(K, Unit)].
  // And it would be computationally stupid to create a new array.
  // So let's just do it the by hand.
  let m = @robinhood_hash.new()
  arr.iter(fn(e) { m.set(e, ()) })
  HashSet(m)
}

/// Insert a key into hash set.
/// @alert unsafe "Panic if the hash set is full."
pub fn insert[K : Hash + Eq](self : HashSet[K], key : K) -> Unit {
  self.0.set(key, ())
}

/// Check if the hash set contains a key.
pub fn contains[K : Hash + Eq](self : HashSet[K], key : K) -> Bool {
  self.0.contains(key)
}

/// Remove a key from hash set.
pub fn remove[K : Hash + Eq](self : HashSet[K], key : K) -> Unit {
  self.0.remove(key)
}

/// Get the number of keys in the set.
pub fn size[K](self : HashSet[K]) -> Int {
  self.0.size()
}

/// Get the capacity of the set.
pub fn capacity[K](self : HashSet[K]) -> Int {
  self.0.capacity()
}

/// Check if the hash set is empty.
pub fn is_empty[K](self : HashSet[K]) -> Bool {
  self.0.is_empty()
}

/// Iterate over all keys of the set.
pub fn iter[K](self : HashSet[K], f : (K) -> Unit) -> Unit {
  self.0.iter(fn(k, _v) { f(k) })
}

/// Iterate over all keys of the set, with index.
pub fn iteri[K](self : HashSet[K], f : (Int, K) -> Unit) -> Unit {
  self.0.iteri(fn(i, k, _v) { f(i, k) })
}

/// Clears the set, removing all keys. Keeps the allocated space.
pub fn clear[K](self : HashSet[K]) -> Unit {
  self.0.clear()
}

/// Union of two hash sets.
/// Safety:
/// - If one of the HashSet has a custom hasher, the other HashSet must have the same hasher.
///
/// @alert unsafe "Panic if the hash set is full."
pub fn union[K : Hash + Eq](
  self : HashSet[K],
  other : HashSet[K]
) -> HashSet[K] {
  let m = HashSet::new()
  self.iter(fn(k) { m.insert(k) })
  other.iter(fn(k) { m.insert(k) })
  m
}

/// Intersection of two hash sets.
/// Safety:
/// - If one of the HashSet has a custom hasher, the other HashSet must have the same hasher.
pub fn intersection[K : Hash + Eq](
  self : HashSet[K],
  other : HashSet[K]
) -> HashSet[K] {
  let m = HashSet::new(hasher=self.0.hasher())
  self.iter(fn(k) { if other.contains(k) { m.insert(k) } })
  m
}

/// Difference of two hash sets.
/// Safety:
/// - If one of the HashSet has a custom hasher, the other HashSet must have the same hasher.
pub fn difference[K : Hash + Eq](
  self : HashSet[K],
  other : HashSet[K]
) -> HashSet[K] {
  let m = HashSet::new(hasher=self.0.hasher())
  self.iter(fn(k) { if not(other.contains(k)) { m.insert(k) } })
  m
}

/// Symmetric difference of two hash sets.
/// Safety:
/// - If one of the HashSet has a custom hasher, the other HashSet must have the same hasher.
pub fn symmetric_difference[K : Hash + Eq](
  self : HashSet[K],
  other : HashSet[K]
) -> HashSet[K] {
  let m = HashSet::new(hasher=self.0.hasher())
  self.iter(fn(k) { if not(other.contains(k)) { m.insert(k) } })
  other.iter(fn(k) { if not(self.contains(k)) { m.insert(k) } })
  m
}

test "union" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.union(m2)
  @assertion.assert_eq(m.size(), 4)?
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_true(m.contains("b"))?
  @assertion.assert_true(m.contains("c"))?
  @assertion.assert_true(m.contains("d"))?
}

test "intersection" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.intersection(m2)
  @assertion.assert_eq(m.size(), 2)?
  @assertion.assert_false(m.contains("a"))?
  @assertion.assert_true(m.contains("b"))?
  @assertion.assert_true(m.contains("c"))?
  @assertion.assert_false(m.contains("d"))?
}

test "difference" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.difference(m2)
  @assertion.assert_eq(m.size(), 1)?
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_false(m.contains("b"))?
  @assertion.assert_false(m.contains("c"))?
  @assertion.assert_false(m.contains("d"))?
}

test "symmetric_difference" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.symmetric_difference(m2)
  @assertion.assert_eq(m.size(), 2)?
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_false(m.contains("b"))?
  @assertion.assert_false(m.contains("c"))?
  @assertion.assert_true(m.contains("d"))?
}
