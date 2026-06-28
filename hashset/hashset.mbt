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

// Default initial capacity

///|
let default_init_capacity = 8

///|
fn[K] new_hashset(capacity : Int) -> HashSet[K] {
  let capacity = capacity.next_power_of_two()
  {
    size: 0,
    capacity,
    capacity_mask: capacity - 1,
    grow_at: calc_grow_threshold(capacity),
    psls: FixedArray::make(capacity, empty_psl),
    hashes: FixedArray::make(capacity, 0),
    keys: UninitializedArray::make(capacity),
  }
}

///|
fn capacity_for_length(length : Int) -> Int {
  let mut capacity = length.next_power_of_two()
  if length > calc_grow_threshold(capacity) {
    capacity *= 2
  }
  capacity
}

///|
/// Creates a hash set containing all elements from the given array.
/// The optional `capacity` is treated as a minimum initial capacity and will be
/// rounded up to the smallest power of 2 that can hold the requested capacity.
#alias(from_array)
#as_free_fn(from_array)
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[K : Hash + Eq] HashSet::HashSet(
  arr : ArrayView[K],
  capacity? : Int,
) -> HashSet[K] {
  let length = arr.length()
  let capacity = match capacity {
    Some(capacity) => capacity.max(capacity_for_length(length))
    None => default_init_capacity.max(capacity_for_length(length))
  }
  let m = new_hashset(capacity)
  arr.each(e => m.add(e))
  m
}

///|
/// Insert a key into hash set.
///
/// Parameters:
///
/// * `self` : The hash set to modify.
/// * `key` : The key to insert. Must implement `Hash` and `Eq` traits.
///
/// Example:
///
/// ```mbt check
/// test {
///   let set : @hashset.HashSet[String] = HashSet([])
///   set.add("key")
///   inspect(set.contains("key"), content="true")
///   set.add("key") // no effect since it already exists
///   inspect(set.length(), content="1")
/// }
/// ```
#alias(insert, deprecated)
pub fn[K : Hash + Eq] HashSet::add(self : HashSet[K], key : K) -> Unit {
  self.add_with_hash(key, key.hash())
}

///|
fn[K : Eq] HashSet::add_with_hash(
  self : HashSet[K],
  key : K,
  hash : Int,
) -> Unit {
  if self.size >= self.grow_at {
    self.grow()
  }
  let (idx, psl) = for psl = 0, idx = hash & self.capacity_mask {
    let curr_psl = self.psls[idx]
    if curr_psl == empty_psl {
      break (idx, psl)
    }
    if self.hashes[idx] == hash && self.keys[idx] == key {
      return
    }
    if psl > curr_psl {
      // Displace the richer occupant of `idx`, then write the new key here.
      self.push_away(idx, curr_psl, self.hashes[idx], self.keys[idx])
      break (idx, psl)
    }
    continue psl + 1, (idx + 1) & self.capacity_mask
  }
  self.set_slot(idx, psl, hash, key)
  self.size += 1
}

///|
// Relocates the key triple `(psl, hash, key)` -- which has just been bumped out
// of an earlier slot -- to a later slot, Robin-Hood style, starting from the
// slot after `idx`.
fn[K] HashSet::push_away(
  self : HashSet[K],
  idx : Int,
  psl : Int,
  hash : Int,
  key : K,
) -> Unit {
  for psl = psl + 1, idx = (idx + 1) & self.capacity_mask, hash = hash, key = key {
    let curr_psl = self.psls[idx]
    if curr_psl == empty_psl {
      self.set_slot(idx, psl, hash, key)
      break
    } else if psl > curr_psl {
      let curr_hash = self.hashes[idx]
      let curr_key = self.keys[idx]
      self.set_slot(idx, psl, hash, key)
      continue curr_psl + 1, (idx + 1) & self.capacity_mask, curr_hash, curr_key
    } else {
      continue psl + 1, (idx + 1) & self.capacity_mask, hash, key
    }
  }
}

///|
#inline
fn[K] HashSet::set_slot(
  self : HashSet[K],
  idx : Int,
  psl : Int,
  hash : Int,
  key : K,
) -> Unit {
  self.psls[idx] = psl
  self.hashes[idx] = hash
  self.keys[idx] = key
}

///|
/// Returns `true` if the set contains the given key.
pub fn[K : Hash + Eq] HashSet::contains(self : HashSet[K], key : K) -> Bool {
  // inline lookup to avoid unnecessary allocations
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    let psl = self.psls[idx]
    guard psl != empty_psl else { break false }
    if self.hashes[idx] == hash && self.keys[idx] == key {
      break true
    }
    if i > psl {
      break false
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
/// Remove a key from hash set. If the key exists in the set, removes it
/// and adjusts the probe sequence length (PSL) of subsequent entries to
/// maintain the Robin Hood hashing invariant. If the key does not exist,
/// the set remains unchanged.
///
/// Parameters:
///
/// * `self` : The hash set to remove the key from.
/// * `key` : The key to remove from the set.
///
/// Example:
///
/// ```mbt check
/// test {
///   let set = @hashset.from_array(["a", "b"])
///   set.remove("a")
///   inspect(set.contains("a"), content="false")
///   inspect(set.length(), content="1")
/// }
/// ```
pub fn[K : Hash + Eq] HashSet::remove(self : HashSet[K], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    let psl = self.psls[idx]
    guard psl != empty_psl else { break }
    if self.hashes[idx] == hash && self.keys[idx] == key {
      self.shift_back(idx)
      self.size -= 1
      break
    }
    if i > psl {
      break
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
fn[K] HashSet::shift_back(self : HashSet[K], idx : Int) -> Unit {
  for cur = idx {
    let next = (cur + 1) & self.capacity_mask
    let next_psl = self.psls[next]
    if next_psl == empty_psl || next_psl == 0 {
      self.psls[cur] = empty_psl
      set_null(self.keys, cur)
      break
    } else {
      self.set_slot(cur, next_psl - 1, self.hashes[next], self.keys[next])
      continue next
    }
  }
}

///|
fn[K] HashSet::grow(self : HashSet[K]) -> Unit {
  // handle zero capacity
  if self.capacity == 0 {
    self.capacity = default_init_capacity
    self.capacity_mask = self.capacity - 1
    self.grow_at = calc_grow_threshold(self.capacity)
    self.size = 0
    self.psls = FixedArray::make(self.capacity, empty_psl)
    self.hashes = FixedArray::make(self.capacity, 0)
    self.keys = UninitializedArray::make(self.capacity)
    return
  }
  let old_psls = self.psls
  let old_hashes = self.hashes
  let old_keys = self.keys
  let old_capacity = self.capacity
  let new_capacity = self.capacity * 2
  self.psls = FixedArray::make(new_capacity, empty_psl)
  self.hashes = FixedArray::make(new_capacity, 0)
  self.keys = UninitializedArray::make(new_capacity)
  self.capacity = new_capacity
  self.capacity_mask = new_capacity - 1
  self.grow_at = calc_grow_threshold(self.capacity)
  for i in 0..<old_capacity {
    if old_psls[i] != empty_psl {
      self.rehash_place_entry(old_hashes[i], old_keys[i])
    }
  }
}

///|
fn[K] HashSet::rehash_place_entry(
  self : HashSet[K],
  hash : Int,
  key : K,
) -> Unit {
  for psl = 0, idx = hash & self.capacity_mask {
    let curr_psl = self.psls[idx]
    if curr_psl == empty_psl {
      self.set_slot(idx, psl, hash, key)
      return
    } else if psl > curr_psl {
      self.push_away(idx, curr_psl, self.hashes[idx], self.keys[idx])
      self.set_slot(idx, psl, hash, key)
      return
    } else {
      continue psl + 1, (idx + 1) & self.capacity_mask
    }
  }
}

// Utils

///|
#deprecated("Use @debug.Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[K : Show] Show for HashSet[K]

///|
pub impl[K : Show] Show for HashSet[K] with fn output(self, logger) {
  logger.write_iter(self.iter(), prefix="@hashset.from_array([", suffix="])")
}

///|
/// Returns the number of elements in the set.
#alias(size, deprecated)
pub fn[K] HashSet::length(self : HashSet[K]) -> Int {
  self.size
}

///|
/// Returns the current capacity of the internal storage.
pub fn[K] HashSet::capacity(self : HashSet[K]) -> Int {
  self.capacity
}

///|
/// Returns `true` if the set contains no elements.
pub fn[K] HashSet::is_empty(self : HashSet[K]) -> Bool {
  self.size == 0
}

///|
/// Calls `f` on each element in the set.
#locals(f)
pub fn[K] HashSet::each(
  self : HashSet[K],
  f : (K) -> Unit raise?,
) -> Unit raise? {
  for i in 0..<self.capacity {
    if self.psls[i] != empty_psl {
      f(self.keys[i])
    }
  }
}

///|
/// Calls `f` on each element with its index (0-based).
#locals(f)
pub fn[K] HashSet::eachi(
  self : HashSet[K],
  f : (Int, K) -> Unit raise?,
) -> Unit raise? {
  for i in 0..<self.capacity; idx = 0 {
    if self.psls[i] != empty_psl {
      f(idx, self.keys[i])
      continue idx + 1
    } else {
      continue idx
    }
  }
}

///|
/// Clears the set, removing all keys. Keeps the allocated space.
pub fn[K] HashSet::clear(self : HashSet[K]) -> Unit {
  // Reuse the existing buffers (keeps the allocated space) and only null the
  // occupied key slots so their references can be reclaimed.
  for i in 0..<self.capacity {
    if self.psls[i] != empty_psl {
      self.psls[i] = empty_psl
      set_null(self.keys, i)
    }
  }
  self.size = 0
}

///|
/// Returns an iterator over the elements of the set.
#alias(iterator, deprecated)
pub fn[K] HashSet::iter(self : HashSet[K]) -> Iter[K] {
  let mut i = 0
  let len = self.capacity
  Iter::new(
    fn() {
      while i < len {
        let idx = i
        i += 1
        if self.psls[idx] != empty_psl {
          return Some(self.keys[idx])
        }
      } nobreak {
        None
      }
    },
    size_hint=self.size,
  )
}

///|
/// Converts the hash set to an array.
pub fn[K] HashSet::to_array(self : HashSet[K]) -> Array[K] {
  let arr = Array::new(capacity=self.size)
  for i in 0..<self.capacity {
    if self.psls[i] != empty_psl {
      arr.push(self.keys[i])
    }
  }
  arr
}

///|
/// Creates a hash set from an iterator of keys.
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Hash + Eq] HashSet::from_iter(iter : Iter[K]) -> HashSet[K] {
  let s = new_hashset(default_init_capacity)
  while iter.next() is Some(e) {
    s.add(e)
  }
  s
}

///|
/// Returns a new set containing all elements from both sets.
pub fn[K : Hash + Eq] HashSet::union(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new_hashset(default_init_capacity)
  self.each(k => m.add(k))
  other.each(k => m.add(k))
  m
}

///|
/// Returns a new set containing only elements present in both sets.
pub fn[K : Hash + Eq] HashSet::intersection(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new_hashset(default_init_capacity)
  self.each(k => if other.contains(k) { m.add(k) })
  m
}

///|
/// Returns a new set containing elements in `self` that are not in `other`.
pub fn[K : Hash + Eq] HashSet::difference(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new_hashset(default_init_capacity)
  self.each(k => if !other.contains(k) { m.add(k) })
  m
}

///|
/// Symmetric difference of two hash sets.
pub fn[K : Hash + Eq] HashSet::symmetric_difference(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new_hashset(default_init_capacity)
  self.each(k => if !other.contains(k) { m.add(k) })
  other.each(k => if !self.contains(k) { m.add(k) })
  m
}

///|
/// Returns `true` if the two sets have no elements in common.
pub fn[K : Hash + Eq] HashSet::is_disjoint(
  self : HashSet[K],
  other : HashSet[K],
) -> Bool {
  if self.length() <= other.length() {
    self.iter().all(k => !other.contains(k))
  } else {
    other.iter().all(k => !self.contains(k))
  }
}

///|
/// Returns `true` if every element of `self` is also in `other`.
pub fn[K : Hash + Eq] HashSet::is_subset(
  self : HashSet[K],
  other : HashSet[K],
) -> Bool {
  if self.length() <= other.length() {
    self.iter().all(k => other.contains(k))
  } else {
    false
  }
}

///|
/// Returns `true` if every element of `other` is also in `self`.
pub fn[K : Hash + Eq] HashSet::is_superset(
  self : HashSet[K],
  other : HashSet[K],
) -> Bool {
  other.is_subset(self)
}

///|
/// Intersection of two hash sets.
pub impl[K : Hash + Eq] BitAnd for HashSet[K] with fn land(self, other) {
  self.intersection(other)
}

///|
/// Union of two hash sets.
pub impl[K : Hash + Eq] BitOr for HashSet[K] with fn lor(self, other) {
  self.union(other)
}

///|
/// Symmetric difference of two hash sets.
pub impl[K : Hash + Eq] BitXOr for HashSet[K] with fn lxor(self, other) {
  self.symmetric_difference(other)
}

///|
/// Difference of two hash sets.
pub impl[K : Hash + Eq] Sub for HashSet[K] with fn sub(self, other) {
  self.difference(other)
}

///|
/// Removes all elements for which the predicate returns `false`.
#locals(f)
pub fn[K] HashSet::retain(self : HashSet[K], f : (K) -> Bool) -> Unit {
  let size = self.size
  let mut j = 0
  for i = 0; j < size; i = i + 1 {
    while self.psls[i] != empty_psl {
      j = j + 1
      if f(self.keys[i]) {
        break
      } else {
        self.shift_back(i)
        self.size -= 1
      }
    }
  }
}

///|
pub impl[X : @quickcheck.Arbitrary + Eq + Hash] @quickcheck.Arbitrary for HashSet[
  X,
] with fn arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|
fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

///|
fn[K : Show] HashSet::_debug_entries(self : HashSet[K]) -> String {
  for i in 0..<self.capacity; s = "" {
    let s = if i > 0 { s + "," } else { s }
    continue if self.psls[i] == empty_psl {
        s + "_"
      } else {
        s + "(\{self.psls[i]},\{self.keys[i]})"
      }
  } nobreak {
    s
  }
}

///|
priv struct MyString(String) derive(Eq)

///|
impl Hash for MyString with fn hash(self) {
  let MyString(self) = self
  self.length()
}

///|
impl Hash for MyString with fn hash_combine(self, hasher) {
  let MyString(self) = self
  hasher.combine_string(self)
}

///|
test "set" {
  let m : HashSet[MyString] = new_hashset(default_init_capacity)
  m.add("a")
  m.add("b")
  m.add("bc")
  m.add("abc")
  m.add("cd")
  m.add("c")
  m.add("d")
  inspect(m.size, content="7")
  // assert_eq(
  //   m._debug_entries(),
  //   "_,(0,a),(1,b),(2,c),(3,d),(3,bc),(4,cd),(4,abc),_,_,_,_,_,_,_,_",
  // )
}

///|
test "remove" {
  let m : HashSet[MyString] = new_hashset(default_init_capacity)
  fn i(s) {
    MyString::MyString(s)
  }

  m.add("a" |> i)
  m.add("ab" |> i)
  m.add("bc" |> i)
  m.add("cd" |> i)
  m.add("abc" |> i)
  m.add("abcdef" |> i)
  m.remove("ab" |> i)
  inspect(m.length(), content="5")
  // inspect(
  //   m._debug_entries(),
  //   content="_,(0,a),(0,bc),(1,cd),(1,abc),_,(0,abcdef),_",
  // )
}

///|
test "remove_unexist_key" {
  let m : HashSet[MyString] = new_hashset(default_init_capacity)
  fn i(s) {
    MyString::MyString(s)
  }

  m.add("a" |> i)
  m.add("ab" |> i)
  m.add("abc" |> i)
  m.remove("d" |> i)
  inspect(m.length(), content="3")
  // inspect(m._debug_entries(), content="_,(0,a),(0,ab),(0,abc),_,_,_,_")
}

///|
test "grow" {
  let m : HashSet[MyString] = new_hashset(default_init_capacity)
  fn i(s) {
    MyString::MyString(s)
  }

  m.add("C" |> i)
  m.add("Go" |> i)
  m.add("C++" |> i)
  m.add("Java" |> i)
  m.add("Scala" |> i)
  m.add("Julia" |> i)
  inspect(m.size, content="6")
  inspect(m.capacity, content="8")
  m.add("Cobol" |> i)
  inspect(m.size, content="7")
  inspect(m.capacity, content="16")
  m.add("Python" |> i)
  m.add("Haskell" |> i)
  m.add("Rescript" |> i)
  inspect(m.size, content="10")
  inspect(m.capacity, content="16")
  // assert_eq(
  //   m._debug_entries(),
  //   "_,(0,C),(0,Go),(0,C++),(0,Java),(0,Scala),(1,Julia),(2,Cobol),(2,Python),(2,Haskell),(2,Rescript),_,_,_,_,_",
  // )
}

///|
test "clear" {
  let m : HashSet[MyString] = new_hashset(default_init_capacity)
  fn i(s) {
    MyString::MyString(s)
  }

  m.add("C" |> i)
  m.add("Go" |> i)
  m.add("C++" |> i)
  m.add("Java" |> i)
  let psls = m.psls
  let hashes = m.hashes
  let keys = m.keys
  inspect(m.length(), content="4")
  m.clear()
  inspect(m.length(), content="0")
  inspect(m.capacity(), content="8")
  inspect(physical_equal(m.psls, psls), content="true")
  inspect(physical_equal(m.hashes, hashes), content="true")
  inspect(physical_equal(m.keys, keys), content="true")
  for i in 0..<m.capacity {
    @test.assert_eq(m.psls[i], empty_psl)
  }
  m.add("MoonBit" |> i)
  inspect(m.length(), content="1")
  inspect(m.contains("MoonBit" |> i), content="true")
}

///|
/// Insert a key into the hash set and returns whether the key was successfully added.
///
/// Parameters:
///
/// * `self` : The hash set to modify.
/// * `key` : The key to insert. Must implement `Hash` and `Eq` traits.
///
/// Returns `true` if the key was successfully added (i.e., it wasn't already present),
/// `false` if the key already existed in the set.
///
/// Example:
///
/// ```mbt check
/// test {
///   let set : @hashset.HashSet[String] = HashSet([])
///   inspect(set.add_and_check("key"), content="true") // First insertion
///   inspect(set.add_and_check("key"), content="false") // Already exists
///   inspect(set.length(), content="1")
/// }
/// ```
pub fn[K : Hash + Eq] HashSet::add_and_check(
  self : HashSet[K],
  key : K,
) -> Bool {
  let old_size = self.length()
  self.add(key)
  self.length() > old_size
}

///|
/// Remove a key from the hash set and returns whether the key was successfully removed.
///
/// Parameters:
///
/// * `self` : The hash set to modify.
/// * `key` : The key to remove. Must implement `Hash` and `Eq` traits.
///
/// Returns `true` if the key was successfully removed (i.e., it was present),
/// `false` if the key didn't exist in the set.
///
/// Example:
///
/// ```mbt check
/// test {
///   let set = @hashset.from_array(["a", "b"])
///   inspect(set.remove_and_check("a"), content="true") // Successfully removed
///   inspect(set.remove_and_check("a"), content="false") // Already removed
///   inspect(set.length(), content="1")
/// }
/// ```
pub fn[K : Hash + Eq] HashSet::remove_and_check(
  self : HashSet[K],
  key : K,
) -> Bool {
  let old_size = self.size
  self.remove(key)
  self.size < old_size
}

///|
/// Copy the set, creating a new set with the same keys.
#alias(clone, deprecated)
pub fn[K] HashSet::copy(self : HashSet[K]) -> HashSet[K] {
  let other = {
    capacity: self.capacity,
    psls: FixedArray::make(self.capacity, empty_psl),
    hashes: FixedArray::make(self.capacity, 0),
    keys: UninitializedArray::make(self.capacity),
    size: self.size,
    capacity_mask: self.capacity_mask,
    grow_at: self.grow_at,
  }
  self.psls.blit_to(other.psls, len=self.capacity)
  self.hashes.blit_to(other.hashes, len=self.capacity)
  UninitializedArray::unsafe_blit(other.keys, 0, self.keys, 0, self.capacity)
  other
}

///|
/// ToJson implementation for hashset
pub impl[X : ToJson] ToJson for HashSet[X] with fn to_json(self) {
  self.to_array().to_json()
}

///|
/// Default implementation for hashset
pub impl[K] Default for HashSet[K] with fn default() {
  new_hashset(default_init_capacity)
}

///|
