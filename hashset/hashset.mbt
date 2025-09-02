// Copyright 2025 International Digital Economy Academy
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
/// Create new hash set.
#as_free_fn
pub fn[K] HashSet::new(capacity? : Int = default_init_capacity) -> HashSet[K] {
  {
    size: 0,
    capacity,
    capacity_mask: capacity - 1,
    grow_at: calc_grow_threshold(capacity),
    entries: FixedArray::make(capacity, None),
  }
}

///|
/// Create new hash set from array.
#as_free_fn
pub fn[K : Hash + Eq] HashSet::from_array(arr : Array[K]) -> HashSet[K] {
  let m = new()
  arr.each(e => m.add(e))
  m
}

///|
#as_free_fn
pub fn[K : Hash + Eq] HashSet::of(arr : FixedArray[K]) -> HashSet[K] {
  let m = new()
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
/// ```moonbit
///   let set : @hashset.HashSet[String] = @hashset.new()
///   set.add("key")
///   inspect(set.contains("key"), content="true")
///   set.add("key") // no effect since it already exists
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] add(self : HashSet[K], key : K) -> Unit {
  self.add_with_hash(key, key.hash())
}

///|
fn[K : Eq] add_with_hash(self : HashSet[K], key : K, hash : Int) -> Unit {
  if self.size >= self.grow_at {
    self.grow()
  }
  let (idx, psl) = for psl = 0, idx = abs(hash) & self.capacity_mask {
    match self.entries[idx] {
      None => break (idx, psl)
      Some(curr_entry) => {
        if curr_entry.hash == hash && curr_entry.key == key {
          return
        }
        if psl > curr_entry.psl {
          self.push_away(idx, curr_entry)
          break (idx, psl)
        }
        continue psl + 1, (idx + 1) & self.capacity_mask
      }
    }
  }
  let entry = { psl, key, hash }
  self.set_entry(entry, idx)
  self.size += 1
}

///|
fn[K] push_away(self : HashSet[K], idx : Int, entry : Entry[K]) -> Unit {
  for psl = entry.psl + 1, idx = (idx + 1) & self.capacity_mask, entry = entry {
    match self.entries[idx] {
      None => {
        entry.psl = psl
        self.set_entry(entry, idx)
        break
      }
      Some(curr_entry) =>
        if psl > curr_entry.psl {
          entry.psl = psl
          self.set_entry(entry, idx)
          continue curr_entry.psl + 1,
            (idx + 1) & self.capacity_mask,
            curr_entry
        } else {
          continue psl + 1, (idx + 1) & self.capacity_mask, entry
        }
    }
  }
}

///|
#inline
fn[K] set_entry(self : HashSet[K], entry : Entry[K], new_idx : Int) -> Unit {
  self.entries[new_idx] = Some(entry)
}

///|
/// Check if the hash set contains a key.
pub fn[K : Hash + Eq] contains(self : HashSet[K], key : K) -> Bool {
  // inline lookup to avoid unnecessary allocations
  let hash = key.hash()
  for i = 0, idx = abs(hash) & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break false }
    if entry.hash == hash && entry.key == key {
      break true
    }
    if i > entry.psl {
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
/// ```moonbit
///   let set = @hashset.of(["a", "b"])
///   set.remove("a")
///   inspect(set.contains("a"), content="false")
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] remove(self : HashSet[K], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = abs(hash) & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break }
    if entry.hash == hash && entry.key == key {
      self.shift_back(idx)
      self.size -= 1
      break
    }
    if i > entry.psl {
      break
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
fn[K] shift_back(self : HashSet[K], idx : Int) -> Unit {
  let next = (idx + 1) & self.capacity_mask
  match self.entries[next] {
    None | Some({ psl: 0, .. }) => self.entries[idx] = None
    Some(entry) => {
      entry.psl -= 1
      self.set_entry(entry, idx)
      self.shift_back(next)
    }
  }
}

///|
fn[K : Eq] grow(self : HashSet[K]) -> Unit {
  // handle zero capacity
  if self.capacity == 0 {
    self.capacity = default_init_capacity
    self.capacity_mask = self.capacity - 1
    self.grow_at = calc_grow_threshold(self.capacity)
    self.size = 0
    self.entries = FixedArray::make(self.capacity, None)
    return
  }
  let old_entries = self.entries
  self.entries = FixedArray::make(self.capacity * 2, None)
  self.capacity = self.capacity * 2
  self.capacity_mask = self.capacity - 1
  self.grow_at = calc_grow_threshold(self.capacity)
  self.size = 0
  for i in 0..<old_entries.length() {
    if old_entries[i] is Some({ key, hash, .. }) {
      self.add_with_hash(key, hash)
    }
  }
}

// Utils

///|
pub impl[K : Show] Show for HashSet[K] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@hashset.of([", suffix="])")
}

///|
/// Get the number of keys in the set.
pub fn[K] size(self : HashSet[K]) -> Int {
  self.size
}

///|
/// Get the capacity of the set.
pub fn[K] capacity(self : HashSet[K]) -> Int {
  self.capacity
}

///|
/// Check if the hash set is empty.
pub fn[K] is_empty(self : HashSet[K]) -> Bool {
  self.size == 0
}

///|
/// Iterate over all keys of the set.
#locals(f)
pub fn[K] each(self : HashSet[K], f : (K) -> Unit raise?) -> Unit raise? {
  for entry in self.entries {
    if entry is Some({ key, .. }) {
      f(key)
    }
  }
}

///|
/// Iterate over all keys of the set, with index.
#locals(f)
pub fn[K] eachi(self : HashSet[K], f : (Int, K) -> Unit raise?) -> Unit raise? {
  let mut idx = 0
  for i in 0..<self.capacity {
    if self.entries[i] is Some({ key, .. }) {
      f(idx, key)
      idx += 1
    }
  }
}

///|
/// Clears the set, removing all keys. Keeps the allocated space.
pub fn[K] clear(self : HashSet[K]) -> Unit {
  self.entries.fill(None)
  self.size = 0
}

///|
/// Returns the iterator of the hash set.
pub fn[K] iter(self : HashSet[K]) -> Iter[K] {
  Iter::new(yield_ => for entry in self.entries {
    if entry is Some({ key, .. }) {
      guard yield_(key) is IterContinue else { break IterEnd }
    }
  } else {
    IterContinue
  })
}

///|
/// Converts the hash set to an array.
pub fn[K] to_array(self : HashSet[K]) -> Array[K] {
  let arr = Array::new(capacity=self.size)
  for entry in self.entries {
    if entry is Some({ key, .. }) {
      arr.push(key)
    }
  }
  arr
}

///|
#as_free_fn
pub fn[K : Hash + Eq] HashSet::from_iter(iter : Iter[K]) -> HashSet[K] {
  let s = new()
  iter.each(e => s.add(e))
  s
}

///|
/// Union of two hash sets.
pub fn[K : Hash + Eq] union(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new()
  self.each(k => m.add(k))
  other.each(k => m.add(k))
  m
}

///|
/// Intersection of two hash sets.
pub fn[K : Hash + Eq] intersection(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new()
  self.each(k => if other.contains(k) { m.add(k) })
  m
}

///|
/// Difference of two hash sets.
pub fn[K : Hash + Eq] difference(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new()
  self.each(k => if !other.contains(k) { m.add(k) })
  m
}

///|
/// Symmetric difference of two hash sets.
pub fn[K : Hash + Eq] symmetric_difference(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  let m = new()
  self.each(k => if !other.contains(k) { m.add(k) })
  other.each(k => if !self.contains(k) { m.add(k) })
  m
}

///|
/// Check if two sets have no common elements.
pub fn[K : Hash + Eq] is_disjoint(
  self : HashSet[K],
  other : HashSet[K],
) -> Bool {
  if self.size() <= other.size() {
    self.iter().all(k => !other.contains(k))
  } else {
    other.iter().all(k => !self.contains(k))
  }
}

///|
/// Check if the current set is a subset of another set.
pub fn[K : Hash + Eq] is_subset(self : HashSet[K], other : HashSet[K]) -> Bool {
  if self.size() <= other.size() {
    self.iter().all(k => other.contains(k))
  } else {
    false
  }
}

///|
/// Check if the current set is a superset of another set.
pub fn[K : Hash + Eq] is_superset(
  self : HashSet[K],
  other : HashSet[K],
) -> Bool {
  other.is_subset(self)
}

///|
/// Intersection of two hash sets.
pub impl[K : Hash + Eq] BitAnd for HashSet[K] with land(self, other) {
  self.intersection(other)
}

///|
/// Union of two hash sets.
pub impl[K : Hash + Eq] BitOr for HashSet[K] with lor(self, other) {
  self.union(other)
}

///|
/// Symmetric difference of two hash sets.
pub impl[K : Hash + Eq] BitXOr for HashSet[K] with lxor(self, other) {
  self.symmetric_difference(other)
}

///|
/// Difference of two hash sets.
pub impl[K : Hash + Eq] Sub for HashSet[K] with sub(self, other) {
  self.difference(other)
}

///|
pub impl[X : @quickcheck.Arbitrary + Eq + Hash] @quickcheck.Arbitrary for HashSet[
  X,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|
fn abs(n : Int) -> Int {
  if n < 0 {
    -n
  } else {
    n
  }
}

///|
fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

///|
fn[K : Show] debug_entries(self : HashSet[K]) -> String {
  let mut s = ""
  for i in 0..<self.entries.length() {
    if i > 0 {
      s += ","
    }
    match self.entries[i] {
      None => s += "_"
      Some({ psl, key, .. }) => s += "(\{psl},\{key})"
    }
  }
  s
}

///|
priv struct MyString(String) derive(Eq)

///|
impl Hash for MyString with hash(self) {
  let MyString(self) = self
  self.length()
}

///|
impl Hash for MyString with hash_combine(self, hasher) {
  let MyString(self) = self
  hasher.combine_string(self)
}

///|
impl Show for MyString with output(self, logger) {
  let MyString(self) = self
  logger.write_string(self)
}

///|
test "set" {
  let m : HashSet[MyString] = new()
  m.add("a")
  m.add("b")
  m.add("bc")
  m.add("abc")
  m.add("cd")
  m.add("c")
  m.add("d")
  inspect(m.size, content="7")
  assert_eq(
    m.debug_entries(),
    "_,(0,a),(1,b),(2,c),(3,d),(3,bc),(4,cd),(4,abc),_,_,_,_,_,_,_,_",
  )
}

///|
test "remove" {
  let m : HashSet[MyString] = new()
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
  inspect(m.size(), content="5")
  inspect(
    m.debug_entries(),
    content="_,(0,a),(0,bc),(1,cd),(1,abc),_,(0,abcdef),_",
  )
}

///|
test "remove_unexist_key" {
  let m : HashSet[MyString] = new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.add("a" |> i)
  m.add("ab" |> i)
  m.add("abc" |> i)
  m.remove("d" |> i)
  inspect(m.size(), content="3")
  inspect(m.debug_entries(), content="_,(0,a),(0,ab),(0,abc),_,_,_,_")
}

///|
test "grow" {
  let m : HashSet[MyString] = new()
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
  assert_eq(
    m.debug_entries(),
    "_,(0,C),(0,Go),(0,C++),(0,Java),(0,Scala),(1,Julia),(2,Cobol),(2,Python),(2,Haskell),(2,Rescript),_,_,_,_,_",
  )
}

///|
test "clear" {
  let m : HashSet[MyString] = new()
  m.clear()
  inspect(m.size(), content="0")
  inspect(m.capacity(), content="8")
  for i in 0..<m.capacity() {
    @test.same_object(m.entries[i], None)
  }
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
/// ```moonbit
///   let set : @hashset.HashSet[String] = @hashset.new()
///   inspect(set.add_and_check("key"), content="true")  // First insertion
///   inspect(set.add_and_check("key"), content="false") // Already exists
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] add_and_check(self : HashSet[K], key : K) -> Bool {
  let old_size = self.size
  self.add(key)
  self.size > old_size
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
/// ```moonbit
///   let set = @hashset.of(["a", "b"])
///   inspect(set.remove_and_check("a"), content="true")  // Successfully removed
///   inspect(set.remove_and_check("a"), content="false") // Already removed
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] remove_and_check(self : HashSet[K], key : K) -> Bool {
  let old_size = self.size
  self.remove(key)
  self.size < old_size
}

///|
/// Copy the set, creating a new set with the same keys.
pub fn[K] copy(self : HashSet[K]) -> HashSet[K] {
  let other = {
    capacity: self.capacity,
    entries: FixedArray::make(self.capacity, None),
    size: self.size,
    capacity_mask: self.capacity_mask,
    grow_at: self.grow_at,
  }
  for i in 0..<self.capacity {
    other.entries[i] = self.entries[i]
  }
  other
}

///|
/// ToJson implementation for hashset
pub impl[X : ToJson] ToJson for HashSet[X] with to_json(self) {
  let res = Array::new(capacity=self.size)
  for entry in self.entries {
    if entry is Some({ key, .. }) {
      res.push(key.to_json())
    }
  }
  Json::array(res)
}

///|
/// Default implementation for hashset
pub impl[K] Default for HashSet[K] with default() {
  new()
}

///|
