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

// Default initial capacity
let default_init_capacity = 8

/// Create new hash set.
pub fn HashSet::new[K](~hasher : Option[(K) -> Int] = None) -> HashSet[K] {
  {
    size: 0,
    capacity: default_init_capacity,
    growAt: calc_grow_threshold(default_init_capacity),
    hasher,
    entries: @array.new(default_init_capacity, fn() { Empty }),
  }
}

/// Create new hash set from array.
pub fn HashSet::from_array[K : Hash + Eq](arr : Array[K]) -> HashSet[K] {
  let m = new()
  arr.iter(fn(e) { m.insert(e) })
  m
}

/// Insert a key into hash set.
/// @alert unsafe "Panic if the hash set is full."
pub fn insert[K : Hash + Eq](self : HashSet[K], key : K) -> Unit {
  if self.capacity == 0 || self.size >= self.growAt {
    self.grow()
  }
  let hash = self.make_hash(key)
  loop 0, self.index(hash), 0, hash, key {
    i, idx, psl, hash, key => {
      if i == self.capacity {
        abort("HashSet is full")
      }
      match self.entries[idx] {
        Empty => {
          self.entries[idx] = Valid(psl, hash, key)
          self.size += 1
          break
        }
        Valid(d, h, k) => {
          if h == hash && k == key {
            self.entries[idx] = Valid(d, h, key)
            break
          }
          if psl > d {
            self.entries[idx] = Valid(psl, hash, key)
            continue i + 1, self.next_index(idx), d + 1, h, k
          }
          continue i + 1, self.next_index(idx), psl + 1, hash, key
        }
      }
    }
  }
}

/// Check if the hash set contains a key.
pub fn contains[K : Hash + Eq](self : HashSet[K], key : K) -> Bool {
  let hash = self.make_hash(key)
  for distance = 0, idx = self.index(hash)
      distance < self.capacity
      distance = distance + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Valid(d, h, k) => {
        if h == hash && k == key {
          return true
        }
        if distance > d {
          return false
        }
      }
      Empty => return false
    }
  }
  false
}

/// Remove a key from hash set.
pub fn remove[K : Hash + Eq](self : HashSet[K], key : K) -> Unit {
  let hash = self.make_hash(key)
  for distance = 0, idx = self.index(hash)
      distance < self.capacity
      distance = distance + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Valid(d, h, k) => {
        if h == hash && k == key {
          self.entries[idx] = Empty
          self.shift_back(idx)
          self.size -= 1
          break
        }
        if distance > d {
          return
        }
      }
      Empty => ()
    }
  }
}

/// Get the number of keys in the set.
pub fn size[K](self : HashSet[K]) -> Int {
  self.size
}

/// Get the capacity of the set.
pub fn capacity[K](self : HashSet[K]) -> Int {
  self.capacity
}

/// Check if the hash set is empty.
pub fn is_empty[K](self : HashSet[K]) -> Bool {
  self.size == 0
}

/// Iterate over all keys of the set.
pub fn iter[K](self : HashSet[K], f : (K) -> Unit) -> Unit {
  self.iteri(fn(_i, k) { f(k) })
}

/// Iterate over all keys of the set, with index.
pub fn iteri[K](self : HashSet[K], f : (Int, K) -> Unit) -> Unit {
  let mut idx = 0
  for i = 0; i < self.capacity; i = i + 1 {
    match self.entries[i] {
      Valid(_, _, k) => {
        f(idx, k)
        idx += 1
      }
      _ => ()
    }
  }
}

/// Clears the set, removing all keys. Keeps the allocated space.
pub fn clear[K](self : HashSet[K]) -> Unit {
  for i = 0; i < self.capacity; i = i + 1 {
    self.entries[i] = Empty
  }
  self.size = 0
}

/// Union of two hash sets.
/// @alert unsafe "Panic if the hash set is full."
pub fn union[K : Hash + Eq](self : HashSet[K], other : HashSet[K]) -> HashSet[K] {
  let m = HashSet::new(~hasher=self.hasher)
  self.iter(fn(k) { m.insert(k) })
  other.iter(fn(k) { m.insert(k) })
  m
}

/// Intersection of two hash sets.
pub fn intersection[K : Hash + Eq](self : HashSet[K], other : HashSet[K]) -> HashSet[K] {
  let m = HashSet::new(~hasher=self.hasher)
  self.iter(fn(k) {
    if other.contains(k) {
      m.insert(k)
    }
  })
  m
}

/// Difference of two hash sets.
pub fn difference[K : Hash + Eq](self : HashSet[K], other : HashSet[K]) -> HashSet[K] {
  let m = HashSet::new(~hasher=self.hasher)
  self.iter(fn(k) {
    if not(other.contains(k)) {
      m.insert(k)
    }
  })
  m
}

/// Symmetric difference of two hash sets.
pub fn symmetric_difference[K : Hash + Eq](self : HashSet[K], other : HashSet[K]) -> HashSet[K] {
  let m = HashSet::new(~hasher=self.hasher)
  self.iter(fn(k) {
    if not(other.contains(k)) {
      m.insert(k)
    }
  })
  other.iter(fn(k) {
    if not(self.contains(k)) {
      m.insert(k)
    }
  })
  m
}

fn shift_back[K : Hash](self : HashSet[K], start_index : Int) -> Unit {
  for i = 0, prev = start_index, curr = self.next_index(start_index)
      i < self.entries.length()
      i = i + 1, prev = curr, curr = self.next_index(curr) {
    match self.entries[curr] {
      Valid(d, h, k) => {
        if d == 0 {
          break
        }
        self.entries[prev] = Valid(d - 1, h, k)
        self.entries[curr] = Empty
      }
      Empty => break
    }
  }
}

fn grow[K : Hash + Eq](self : HashSet[K]) -> Unit {
  // handle zero capacity
  if self.capacity == 0 {
    self.capacity = default_init_capacity
    self.growAt = calc_grow_threshold(self.capacity)
    self.size = 0
    self.entries = @array.new(self.capacity, fn() { Empty })
    return
  }
  let old_entries = self.entries
  self.entries = @array.new(self.capacity * 2, fn() { Empty })
  self.capacity = self.capacity * 2
  self.growAt = calc_grow_threshold(self.capacity)
  self.size = 0
  for i = 0; i < old_entries.length(); i = i + 1 {
    match old_entries[i] {
      Valid(_, _, k) => self.insert(k)
      _ => ()
    }
  }
}

fn make_hash[K : Hash](self : HashSet[K], key : K) -> Int {
  let hash : Int = match self.hasher {
    Some(hasher) => hasher(key)
    None => key.hash()
  }
  // Let higher 16 bits of the hash value participate in the calculation
  hash.lxor(hash.lsr(16))
}

fn index[K : Hash](self : HashSet[K], hash : Int) -> Int {
  hash.abs().land(self.capacity - 1)
}

fn next_index[K : Hash](self : HashSet[K], index : Int) -> Int {
  (index + 1).land(self.capacity - 1)
}

fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

fn debug_entries[K : Show](self : HashSet[K]) -> String {
  let mut s = ""
  for i = 0; i < self.entries.length(); i = i + 1 {
    if i > 0 {
      s += ","
    }
    match self.entries[i] {
      Empty => s += "_"
      Valid(d, _h, k) => s += "(\(d),\(k))"
    }
  }
  s
}

test "new" {
  let m : HashSet[Int] = HashSet::new()
  @assertion.assert_eq(m.capacity, default_init_capacity)?
  @assertion.assert_eq(m.size, 0)?
}

test "set" {
  let m : HashSet[String] = HashSet::new(~hasher=Some(fn(k) { k.length() }))
  m.insert("a")
  m.insert("b")
  m.insert("bc")
  m.insert("abc")
  m.insert("cd")
  m.insert("c")
  m.insert("d")
  @assertion.assert_eq(m.size, 7)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a),(1,b),(2,c),(3,d),(3,bc),(4,cd),(4,abc),_,_,_,_,_,_,_,_",
  )?
}

test "insert" {
  let m : HashSet[String] = HashSet::new()
  m.insert("a")
  m.insert("b")
  m.insert("c")
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_true(m.contains("b"))?
  @assertion.assert_true(m.contains("c"))?
  @assertion.assert_false(m.contains("d"))?
}

test "from_array" {
  let m = HashSet::["a", "b", "c"]
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_true(m.contains("b"))?
  @assertion.assert_true(m.contains("c"))?
  @assertion.assert_false(m.contains("d"))?
}

test "remove" {
  let m : HashSet[String] = HashSet::new(~hasher=Some(fn(k) { k.length() }))
  m.insert("a")
  m.insert("ab")
  m.insert("bc")
  m.insert("cd")
  m.insert("abc")
  m.insert("abcdef")
  m.remove("ab")
  @assertion.assert_eq(m.size(), 5)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a),(0,bc),(1,cd),(1,abc),_,(0,abcdef),_",
  )?
}

test "remove_unexist_key" {
  let m : HashSet[String] = HashSet::new(~hasher=Some(fn(k) { k.length() }))
  m.insert("a")
  m.insert("ab")
  m.insert("abc")
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
  @assertion.assert_eq(m.debug_entries(), "_,(0,a),(0,ab),(0,abc),_,_,_,_")?
}

test "size" {
  let m : HashSet[String] = HashSet::new()
  @assertion.assert_eq(m.size(), 0)?
  m.insert("a")
  @assertion.assert_eq(m.size(), 1)?
}

test "is_empty" {
  let m : HashSet[String] = HashSet::new()
  @assertion.assert_eq(m.is_empty(), true)?
  m.insert("a")
  @assertion.assert_eq(m.is_empty(), false)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
}

test "iter" {
  let m : HashSet[String] = HashSet::["a", "b", "c"]
  let mut sum = ""
  m.iter(fn(k) { sum += k })
  @assertion.assert_eq(sum, "cab")?
}

test "iteri" {
  let m : HashSet[String] = HashSet::["1", "2", "3"]
  let mut s = ""
  let mut sum = 0
  m.iteri(
    fn(i, k) {
      s += k
      sum += i
    },
  )
  @assertion.assert_eq(s, "321")?
  @assertion.assert_eq(sum, 3)?
}

test "clear" {
  let m : HashSet[String] = HashSet::["a", "b", "c"]
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], Empty)?
  }
}

test "grow" {
  let m : HashSet[String] = HashSet::new(~hasher=Some(fn(k) { k.length() }))
  m.insert("C")
  m.insert("Go")
  m.insert("C++")
  m.insert("Java")
  m.insert("Scala")
  m.insert("Julia")
  @assertion.assert_eq(m.size, 6)?
  @assertion.assert_eq(m.capacity, 8)?
  m.insert("Cobol")
  @assertion.assert_eq(m.size, 7)?
  @assertion.assert_eq(m.capacity, 16)?
  m.insert("Python")
  m.insert("Haskell")
  m.insert("Rescript")
  @assertion.assert_eq(m.size, 10)?
  @assertion.assert_eq(m.capacity, 16)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,C),(0,Go),(0,C++),(0,Java),(0,Scala),(1,Julia),(2,Cobol),(2,Python),(2,Haskell),(2,Rescript),_,_,_,_,_",
  )?
}

test "union" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.union(m2)
  @assertion.assert_eq(m.size, 4)?
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_true(m.contains("b"))?
  @assertion.assert_true(m.contains("c"))?
  @assertion.assert_true(m.contains("d"))?
}

test "intersection" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.intersection(m2)
  @assertion.assert_eq(m.size, 2)?
  @assertion.assert_false(m.contains("a"))?
  @assertion.assert_true(m.contains("b"))?
  @assertion.assert_true(m.contains("c"))?
  @assertion.assert_false(m.contains("d"))?
}

test "difference" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.difference(m2)
  @assertion.assert_eq(m.size, 1)?
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_false(m.contains("b"))?
  @assertion.assert_false(m.contains("c"))?
  @assertion.assert_false(m.contains("d"))?
}

test "symmetric_difference" {
  let m1 : HashSet[String] = HashSet::["a", "b", "c"]
  let m2 : HashSet[String] = HashSet::["b", "c", "d"]
  let m = m1.symmetric_difference(m2)
  @assertion.assert_eq(m.size, 2)?
  @assertion.assert_true(m.contains("a"))?
  @assertion.assert_false(m.contains("b"))?
  @assertion.assert_false(m.contains("c"))?
  @assertion.assert_true(m.contains("d"))?
}