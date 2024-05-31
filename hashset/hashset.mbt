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
pub fn HashSet::new[K]() -> HashSet[K] {
  {
    size: 0,
    capacity: default_init_capacity,
    growAt: calc_grow_threshold(default_init_capacity),
    entries: FixedArray::make(default_init_capacity, None),
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
  let hash = make_hash(key)
  let entry = { psl: 0, hash, key }
  loop 0, self.index(hash), entry {
    i, idx, entry => {
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
            continue i + 1, self.next_index(idx), curr_entry
          }
          entry.psl += 1
          continue i + 1, self.next_index(idx), entry
        }
      }
    }
  }
}

/// Check if the hash set contains a key.
pub fn contains[K : Hash + Eq](self : HashSet[K], key : K) -> Bool {
  let hash = make_hash(key)
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

/// Remove a key from hash set.
pub fn remove[K : Hash + Eq](self : HashSet[K], key : K) -> Unit {
  let hash = make_hash(key)
  for i = 0, idx = self.index(hash)
      i < self.capacity
      i = i + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          self.entries[idx] = None
          self.shift_back(idx)
          self.size -= 1
          break
        }
        if i > entry.psl {
          return
        }
      }
      None => ()
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
      Some({ key, .. }) => {
        f(idx, key)
        idx += 1
      }
      None => ()
    }
  }
}

/// Clears the set, removing all keys. Keeps the allocated space.
pub fn clear[K](self : HashSet[K]) -> Unit {
  for i = 0; i < self.capacity; i = i + 1 {
    self.entries[i] = None
  }
  self.size = 0
}

/// Union of two hash sets.
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
pub fn intersection[K : Hash + Eq](
  self : HashSet[K],
  other : HashSet[K]
) -> HashSet[K] {
  let m = HashSet::new()
  self.iter(fn(k) { if other.contains(k) { m.insert(k) } })
  m
}

/// Difference of two hash sets.
pub fn difference[K : Hash + Eq](
  self : HashSet[K],
  other : HashSet[K]
) -> HashSet[K] {
  let m = HashSet::new()
  self.iter(fn(k) { if not(other.contains(k)) { m.insert(k) } })
  m
}

/// Symmetric difference of two hash sets.
pub fn symmetric_difference[K : Hash + Eq](
  self : HashSet[K],
  other : HashSet[K]
) -> HashSet[K] {
  let m = HashSet::new()
  self.iter(fn(k) { if not(other.contains(k)) { m.insert(k) } })
  other.iter(fn(k) { if not(self.contains(k)) { m.insert(k) } })
  m
}

pub fn as_iter[K](self : HashSet[K]) -> Iter[K] {
  Iter::_unstable_internal_make(
    fn(yield) {
      for i = 0, len = self.entries.length(); i < len; i = i + 1 {
        match self.entries[i] {
          Some({ key, .. }) => if yield(key).not() { break false }
          None => continue
        }
      } else {
        true
      }
    },
  )
}

fn shift_back[K : Hash](self : HashSet[K], start_index : Int) -> Unit {
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

fn grow[K : Hash + Eq](self : HashSet[K]) -> Unit {
  // handle zero capacity
  if self.capacity == 0 {
    self.capacity = default_init_capacity
    self.growAt = calc_grow_threshold(self.capacity)
    self.size = 0
    self.entries = FixedArray::make(self.capacity, None)
    return
  }
  let old_entries = self.entries
  self.entries = FixedArray::make(self.capacity * 2, None)
  self.capacity = self.capacity * 2
  self.growAt = calc_grow_threshold(self.capacity)
  self.size = 0
  for i = 0; i < old_entries.length(); i = i + 1 {
    match old_entries[i] {
      Some({ key, .. }) => self.insert(key)
      None => ()
    }
  }
}

fn make_hash[K : Hash](key : K) -> Int {
  let hash = key.hash()
  // Let higher 16 bits of the hash value participate in the calculation
  hash.lxor(hash.lsr(16))
}

fn index[K : Hash](self : HashSet[K], hash : Int) -> Int {
  abs(hash).land(self.capacity - 1)
}

fn abs(n : Int) -> Int {
  if n < 0 {
    -n
  } else {
    n
  }
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
      None => s += "_"
      Some({ psl, key, .. }) => s += "(\(psl),\(key))"
    }
  }
  s
}
