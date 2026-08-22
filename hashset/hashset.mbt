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
    hashes: FixedArray::make(capacity, empty_hash),
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
    Some(capacity) | (None with capacity = default_init_capacity) =>
      capacity.max(capacity_for_length(length))
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
  self.add_with_hash(key, Hash::hash(key))
}

///|
/// The probe-sequence length of the occupied slot `idx`: how far it sits from
/// the slot its hash asked for. Derived rather than stored -- see the note on
/// `HashSet`.
#inline
fn[K] HashSet::psl_at(self : HashSet[K], idx : Int, stored : Int) -> Int {
  (idx - (stored & self.capacity_mask)) & self.capacity_mask
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
  let stored = store_hash(hash)
  let idx = for psl = 0, idx = stored & self.capacity_mask {
    // SAFETY: `idx` starts masked by `capacity_mask` and every step re-masks
    // it, so it indexes both backing arrays -- each of length `capacity` --
    // in bounds. A non-empty slot further guarantees that `keys[idx]` was
    // initialized by `set_slot`.
    let curr = self.hashes.unsafe_get(idx)
    if curr == empty_hash {
      break idx
    }
    if curr == stored && self.keys.unsafe_get(idx) == key {
      return
    }
    if psl > self.psl_at(idx, curr) {
      // Displace the richer occupant of `idx`, then write the new key here.
      self.push_away(idx, curr, self.keys.unsafe_get(idx))
      break idx
    }
    continue psl + 1, (idx + 1) & self.capacity_mask
  }
  self.set_slot(idx, stored, key)
  self.size += 1
}

///|
// Relocates the key triple `(psl, hash, key)` -- which has just been bumped out
// of an earlier slot -- to a later slot, Robin-Hood style, starting from the
// slot after `idx`.
fn[K] HashSet::push_away(
  self : HashSet[K],
  idx : Int,
  stored : Int,
  key : K,
) -> Unit {
  for psl = self.psl_at(idx, stored) + 1, idx = (idx + 1) & self.capacity_mask, stored = stored, key = key {
    // SAFETY: same masked-index and initialized-key invariants as `add_with_hash`.
    let curr = self.hashes.unsafe_get(idx)
    if curr == empty_hash {
      self.set_slot(idx, stored, key)
      break
    } else if psl > self.psl_at(idx, curr) {
      let curr_key = self.keys.unsafe_get(idx)
      self.set_slot(idx, stored, key)
      continue self.psl_at(idx, curr) + 1,
        (idx + 1) & self.capacity_mask,
        curr,
        curr_key
    } else {
      continue psl + 1, (idx + 1) & self.capacity_mask, stored, key
    }
  }
}

///|
#inline
fn[K] HashSet::set_slot(
  self : HashSet[K],
  idx : Int,
  stored : Int,
  key : K,
) -> Unit {
  // SAFETY: every caller derives `idx` from a `capacity_mask` probe, so it is
  // in bounds for both arrays.
  self.hashes.unsafe_set(idx, stored)
  self.keys.unsafe_set(idx, key)
}

///|
/// Returns `true` if the set contains the given key.
pub fn[K : Hash + Eq] HashSet::contains(self : HashSet[K], key : K) -> Bool {
  // inline lookup to avoid unnecessary allocations
  let stored = store_hash(Hash::hash(key))
  for i = 0, idx = stored & self.capacity_mask {
    // SAFETY: `idx` is masked by `capacity_mask`; both backing arrays have
    // length `capacity`, so the probe index is in bounds. A non-empty slot
    // also guarantees that `keys[idx]` was initialized by `set_slot`.
    let curr = self.hashes.unsafe_get(idx)
    guard curr != empty_hash else { break false }
    if curr == stored && self.keys.unsafe_get(idx) == key {
      break true
    }
    if i > self.psl_at(idx, curr) {
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
  let stored = store_hash(Hash::hash(key))
  for i = 0, idx = stored & self.capacity_mask {
    // SAFETY: same masked-index and initialized-key invariants as `contains`.
    let curr = self.hashes.unsafe_get(idx)
    guard curr != empty_hash else { break }
    if curr == stored && self.keys.unsafe_get(idx) == key {
      self.shift_back(idx)
      self.size -= 1
      break
    }
    if i > self.psl_at(idx, curr) {
      break
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
fn[K] HashSet::shift_back(self : HashSet[K], idx : Int) -> Unit {
  // SAFETY: `cur` is in bounds by either route its callers take -- `remove`
  // derives it from a masked probe, and `retain` reaches here only after a
  // checked read of that slot succeeded. `next` is re-masked each step, and
  // later `cur` values are previous `next` values.
  for cur = idx {
    let next = (cur + 1) & self.capacity_mask
    let next_stored = self.hashes.unsafe_get(next)
    if next_stored == empty_hash || self.psl_at(next, next_stored) == 0 {
      self.hashes.unsafe_set(cur, empty_hash)
      // Not redundant with the line above: the hash marks the slot free, but
      // the key slot would still hold the removed key alive until something
      // overwrites it, retaining up to one dead key per vacated slot.
      self.keys.set_null(cur)
      break
    } else {
      // Moving the occupant one slot back drops its derived PSL by one, so
      // nothing has to be recomputed or written for it.
      self.set_slot(cur, next_stored, self.keys.unsafe_get(next))
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
    self.hashes = FixedArray::make(self.capacity, empty_hash)
    self.keys = UninitializedArray::make(self.capacity)
    return
  }
  let old_hashes = self.hashes
  let old_keys = self.keys
  let old_capacity = self.capacity
  let new_capacity = self.capacity * 2
  self.hashes = FixedArray::make(new_capacity, empty_hash)
  self.keys = UninitializedArray::make(new_capacity)
  self.capacity = new_capacity
  self.capacity_mask = new_capacity - 1
  self.grow_at = calc_grow_threshold(self.capacity)
  for i in 0..<old_capacity {
    // SAFETY: `i < old_capacity`, the length of both old arrays, and a
    // non-empty slot means the old key slot was initialized.
    let stored = old_hashes.unsafe_get(i)
    if stored != empty_hash {
      self.rehash_place_entry(stored, old_keys.unsafe_get(i))
    }
  }
}

///|
fn[K] HashSet::rehash_place_entry(
  self : HashSet[K],
  stored : Int,
  key : K,
) -> Unit {
  for psl = 0, idx = stored & self.capacity_mask {
    // SAFETY: same masked-index and initialized-key invariants as `add_with_hash`.
    let curr = self.hashes.unsafe_get(idx)
    if curr == empty_hash {
      self.set_slot(idx, stored, key)
      return
    } else if psl > self.psl_at(idx, curr) {
      self.push_away(idx, curr, self.keys.unsafe_get(idx))
      self.set_slot(idx, stored, key)
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
    if self.hashes[i] != empty_hash {
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
    if self.hashes[i] != empty_hash {
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
    if self.hashes[i] != empty_hash {
      self.hashes[i] = empty_hash
      self.keys.set_null(i)
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
        // SAFETY: `idx < len`, which is the capacity captured when the
        // iterator was created, and the table never shrinks; a non-empty PSL
        // means the key slot was initialized.
        if self.hashes.unsafe_get(idx) != empty_hash {
          return Some(self.keys.unsafe_get(idx))
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
    if self.hashes[i] != empty_hash {
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
    while self.hashes[i] != empty_hash {
      j += 1
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
fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

///|
fn[K : Show] HashSet::_debug_entries(self : HashSet[K]) -> String {
  for i in 0..<self.capacity; s = "" {
    let s = if i > 0 { s + "," } else { s }
    continue if self.hashes[i] == empty_hash {
        s + "_"
      } else {
        s + "(\{self.psl_at(i, self.hashes[i])},\{self.keys[i]})"
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
test "contains handles collided slots across table wraparound" {
  let m : HashSet[MyString] = new_hashset(8)
  fn key(value) {
    MyString::MyString(value)
  }

  // All keys hash to 7, so the probe sequence starts at the final slot and
  // wraps around to the start of the table.
  m.add("aaaaaaa" |> key)
  m.add("bbbbbbb" |> key)
  m.add("ccccccc" |> key)
  m.add("ddddddd" |> key)
  m.add("eeeeeee" |> key)

  assert_true(m.contains("aaaaaaa" |> key))
  assert_true(m.contains("eeeeeee" |> key))
  assert_false(m.contains("fffffff" |> key))
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
  let hashes = m.hashes
  let keys = m.keys
  inspect(m.length(), content="4")
  m.clear()
  inspect(m.length(), content="0")
  inspect(m.capacity(), content="8")
  inspect(physical_equal(m.hashes, hashes), content="true")
  inspect(physical_equal(m.keys, keys), content="true")
  for i in 0..<m.capacity {
    @test.assert_eq(m.hashes[i], empty_hash)
  }
  m.add("MoonBit" |> i)
  inspect(m.length(), content="1")
  inspect(m.contains("MoonBit" |> i), content="true")
}

///|
test "copy sparse set only copies occupied key slots" {
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
  let copied = m.copy()
  inspect(copied.length(), content="5")
  inspect(copied.capacity(), content="8")
  inspect(physical_equal(copied.hashes, m.hashes), content="false")
  inspect(physical_equal(copied.keys, m.keys), content="false")
  let mut occupied = 0
  for idx in 0..<m.capacity {
    @test.assert_eq(copied.hashes[idx], m.hashes[idx])
    if m.hashes[idx] != empty_hash {
      occupied += 1
      assert_true(copied.keys[idx] == m.keys[idx])
    }
  }
  inspect(occupied, content="5")
  inspect(copied.contains("ab" |> i), content="false")
  inspect(copied.contains("abcdef" |> i), content="true")
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
  // `copy` on the metadata arrays rather than make-then-blit: it is one
  // allocation-and-copy each instead of allocate, fill, then overwrite, and
  // on js it lowers to `Array.slice`.
  //
  // Independence is structural here, unlike the boxed layout this replaces:
  // the arrays hold values, not shared mutable entries, so neither set can
  // disturb the other's probe sequences.
  let other = {
    capacity: self.capacity,
    hashes: self.hashes.copy(),
    keys: UninitializedArray::make(self.capacity),
    size: self.size,
    capacity_mask: self.capacity_mask,
    grow_at: self.grow_at,
  }
  for i in 0..<self.capacity {
    // SAFETY: `i < capacity`, the length of every backing array, and a
    // non-empty PSL means the key slot was initialized.
    if self.hashes.unsafe_get(i) != empty_hash {
      other.keys.unsafe_set(i, self.keys.unsafe_get(i))
    }
  }
  other
}

///|
/// ToJson implementation for hashset
pub impl[X : ToJson] ToJson for HashSet[X] with fn to_json(self) {
  // Built directly rather than via `to_array`, which would materialize an
  // `Array[X]` before the `Array[Json]`.
  [
    for i in 0..<self.capacity if self.hashes[i] != empty_hash => self.keys[i]
  ]
}

///|
/// Default implementation for hashset
pub impl[K] Default for HashSet[K] with fn default() {
  new_hashset(default_init_capacity)
}

///|
