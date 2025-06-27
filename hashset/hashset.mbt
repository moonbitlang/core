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

///|
// Default initial capacity
let default_init_capacity = 8

///|
/// Create new hash set.
pub fn[K] new(capacity~ : Int = default_init_capacity) -> T[K] {
  {
    size: 0,
    capacity,
    grow_at: calc_grow_threshold(capacity),
    entries: FixedArray::make(capacity, None),
  }
}

///|
/// Create new hash set from array.
pub fn[K : Hash + Eq] from_array(arr : Array[K]) -> T[K] {
  let m = new()
  arr.each(e => m.add(e))
  m
}

///|
pub fn[K : Hash + Eq] of(arr : FixedArray[K]) -> T[K] {
  let m = new()
  arr.each(e => m.add(e))
  m
}

///|
/// Insert a key into hash set.

///|
/// Insert a key into hash set.
pub fn[K : Hash + Eq] add(self : T[K], key : K) -> Unit {
  if self.capacity == 0 || self.size >= self.grow_at {
    self.grow()
  }
  let hash = key.hash()
  let entry = { psl: 0, hash, key }
  loop (0, self.index(hash), entry) {
    (i, idx, entry) => {
      if i == self.capacity {
        panic()
      }
      match self.entries[idx] {
        None => {
          self.entries[idx] = Some(entry)
          self.size += 1
          break
        }
        Some(curr_entry) => {
          if curr_entry.hash == entry.hash && curr_entry.key == entry.key {
            self.entries[idx] = Some(entry)
            break
          }
          if entry.psl > curr_entry.psl {
            self.entries[idx] = Some(entry)
            curr_entry.psl += 1
            continue (i + 1, self.next_index(idx), curr_entry)
          }
          entry.psl += 1
          continue (i + 1, self.next_index(idx), entry)
        }
      }
    }
  }
}

///|
/// Check if the hash set contains a key.
pub fn[K : Hash + Eq] contains(self : T[K], key : K) -> Bool {
  let hash = key.hash()
  for i = 0, idx = self.index(hash)
      i < self.capacity
      i = i + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          return true
        }
        if i > entry.psl {
          return false
        }
      }
      None => return false
    }
  }
  false
}

///|
/// Remove a key from hash set.
pub fn[K : Hash + Eq] remove(self : T[K], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = self.index(hash)
      i < self.capacity
      i = i + 1, idx = self.next_index(idx) {
    if self.entries[idx] is Some(entry) &&
      entry.hash == hash &&
      entry.key == key {
      self.entries[idx] = None
      self.shift_back(idx)
      self.size -= 1
      break
    }
  }
}

///|
/// Get the number of keys in the set.
pub fn[K] size(self : T[K]) -> Int {
  self.size
}

///|
/// Get the capacity of the set.
pub fn[K] capacity(self : T[K]) -> Int {
  self.capacity
}

///|
/// Check if the hash set is empty.
pub fn[K] is_empty(self : T[K]) -> Bool {
  self.size == 0
}

///|
/// Iterate over all keys of the set.
pub fn[K] each(self : T[K], f : (K) -> Unit) -> Unit {
  self.eachi((_i, k) => f(k))
}

///|
/// Iterate over all keys of the set, with index.
pub fn[K] eachi(self : T[K], f : (Int, K) -> Unit) -> Unit {
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
pub fn[K] clear(self : T[K]) -> Unit {
  for i in 0..<self.capacity {
    self.entries[i] = None
  }
  self.size = 0
}

///|
/// Union of two hash sets.
pub fn[K : Hash + Eq] union(self : T[K], other : T[K]) -> T[K] {
  let m = new()
  self.each(k => m.add(k))
  other.each(k => m.add(k))
  m
}

///|
/// Intersection of two hash sets.
pub fn[K : Hash + Eq] intersection(self : T[K], other : T[K]) -> T[K] {
  let m = new()
  self.each(k => if other.contains(k) { m.add(k) })
  m
}

///|
/// Difference of two hash sets.
pub fn[K : Hash + Eq] difference(self : T[K], other : T[K]) -> T[K] {
  let m = new()
  self.each(k => if not(other.contains(k)) { m.add(k) })
  m
}

///|
/// Symmetric difference of two hash sets.
pub fn[K : Hash + Eq] symmetric_difference(self : T[K], other : T[K]) -> T[K] {
  let m = new()
  self.each(k => if not(other.contains(k)) { m.add(k) })
  other.each(k => if not(self.contains(k)) { m.add(k) })
  m
}

///|
/// Check if two sets have no common elements.
pub fn[K : Hash + Eq] is_disjoint(self : T[K], other : T[K]) -> Bool {
  if self.size() <= other.size() {
    self.iter().all(k => not(other.contains(k)))
  } else {
    other.iter().all(k => not(self.contains(k)))
  }
}

///|
/// Check if the current set is a subset of another set.
pub fn[K : Hash + Eq] is_subset(self : T[K], other : T[K]) -> Bool {
  if self.size() <= other.size() {
    self.iter().all(k => other.contains(k))
  } else {
    false
  }
}

///|
/// Check if the current set is a superset of another set.
pub fn[K : Hash + Eq] is_superset(self : T[K], other : T[K]) -> Bool {
  other.is_subset(self)
}

///|
/// Intersection of two hash sets.
pub impl[K : Hash + Eq] BitAnd for T[K] with land(self, other) {
  self.intersection(other)
}

///|
/// Union of two hash sets.
pub impl[K : Hash + Eq] BitOr for T[K] with lor(self, other) {
  self.union(other)
}

///|
/// Symmetric difference of two hash sets.
pub impl[K : Hash + Eq] BitXOr for T[K] with lxor(self, other) {
  self.symmetric_difference(other)
}

///|
/// Difference of two hash sets.
pub impl[K : Hash + Eq] Sub for T[K] with op_sub(self, other) {
  self.difference(other)
}

///|
pub fn[K] iter(self : T[K]) -> Iter[K] {
  Iter::new(yield_ => for entry in self.entries {
    if entry is Some({ key, .. }) {
      guard yield_(key) is IterContinue else { break IterEnd }
    }
  } else {
    IterContinue
  })
}

///|
pub fn[K : Hash + Eq] from_iter(iter : Iter[K]) -> T[K] {
  let s = new()
  iter.each(e => s.add(e))
  s
}

///|
pub impl[X : @quickcheck.Arbitrary + Eq + Hash] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|
fn[K] shift_back(self : T[K], start_index : Int) -> Unit {
  for i = 0, prev = start_index, curr = self.next_index(start_index)
      i < self.entries.length()
      i = i + 1, prev = curr, curr = self.next_index(curr) {
    match self.entries[curr] {
      Some(entry) => {
        if entry.psl == 0 {
          break
        }
        entry.psl -= 1
        self.entries[prev] = Some(entry)
        self.entries[curr] = None
      }
      None => break
    }
  }
}

///|
fn[K : Hash + Eq] grow(self : T[K]) -> Unit {
  // handle zero capacity
  if self.capacity == 0 {
    self.capacity = default_init_capacity
    self.grow_at = calc_grow_threshold(self.capacity)
    self.size = 0
    self.entries = FixedArray::make(self.capacity, None)
    return
  }
  let old_entries = self.entries
  self.entries = FixedArray::make(self.capacity * 2, None)
  self.capacity = self.capacity * 2
  self.grow_at = calc_grow_threshold(self.capacity)
  self.size = 0
  for i in 0..<old_entries.length() {
    if old_entries[i] is Some({ key, .. }) {
      self.add(key)
    }
  }
}

///|
fn[K] index(self : T[K], hash : Int) -> Int {
  abs(hash) & (self.capacity - 1)
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
fn[K] next_index(self : T[K], index : Int) -> Int {
  (index + 1) & (self.capacity - 1)
}

///|
fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

///|
fn[K : Show] debug_entries(self : T[K]) -> String {
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
pub impl[K : Show] Show for T[K] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@hashset.of([", suffix="])")
}

///|
priv type MyString String derive(Eq)

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
  let m : T[MyString] = new()
  m.add("a")
  m.add("b")
  m.add("bc")
  m.add("abc")
  m.add("cd")
  m.add("c")
  m.add("d")
  assert_eq(m.size, 7)
  assert_eq(
    m.debug_entries(),
    "_,(0,a),(1,b),(2,c),(3,d),(3,bc),(4,cd),(4,abc),_,_,_,_,_,_,_,_",
  )
}

///|
test "remove" {
  let m : T[MyString] = new()
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
  assert_eq(m.size(), 5)
  assert_eq(m.debug_entries(), "_,(0,a),(0,bc),(1,cd),(1,abc),_,(0,abcdef),_")
}

///|
test "remove_unexist_key" {
  let m : T[MyString] = new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.add("a" |> i)
  m.add("ab" |> i)
  m.add("abc" |> i)
  m.remove("d" |> i)
  assert_eq(m.size(), 3)
  assert_eq(m.debug_entries(), "_,(0,a),(0,ab),(0,abc),_,_,_,_")
}

///|
test "grow" {
  let m : T[MyString] = new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.add("C" |> i)
  m.add("Go" |> i)
  m.add("C++" |> i)
  m.add("Java" |> i)
  m.add("Scala" |> i)
  m.add("Julia" |> i)
  assert_eq(m.size, 6)
  assert_eq(m.capacity, 8)
  m.add("Cobol" |> i)
  assert_eq(m.size, 7)
  assert_eq(m.capacity, 16)
  m.add("Python" |> i)
  m.add("Haskell" |> i)
  m.add("Rescript" |> i)
  assert_eq(m.size, 10)
  assert_eq(m.capacity, 16)
  assert_eq(
    m.debug_entries(),
    "_,(0,C),(0,Go),(0,C++),(0,Java),(0,Scala),(1,Julia),(2,Cobol),(2,Python),(2,Haskell),(2,Rescript),_,_,_,_,_",
  )
}

///|
test "clear" {
  let m : T[MyString] = new()
  m.clear()
  assert_eq(m.size(), 0)
  assert_eq(m.capacity(), 8)
  for i in 0..<m.capacity() {
    @test.same_object(m.entries[i], None)
  }
}

///|
pub fn[K] to_array(self : T[K]) -> Array[K] {
  let mut i = 0
  let res = while i < self.capacity {
    if self.entries[i] is Some({ key, .. }) {
      i += 1
      break Array::make(self.size, key)
    }
    i += 1
  } else {
    []
  }
  if not(res.is_empty()) {
    let mut res_idx = 1
    while res_idx < res.length() && i < self.capacity {
      if self.entries[i] is Some({ key, .. }) {
        res[res_idx] = key
        res_idx += 1
      }
      i += 1
    }
  }
  res
}
