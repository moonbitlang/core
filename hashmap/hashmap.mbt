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

fn power_2_above(x : Int, n : Int) -> Int {
  for i = x {
    if i >= n {
      break i
    }
    let next = i.lsl(1)
    if next < 0 {
      // overflow happend  
      break i
    }
    continue next
  }
}

test "power_2_above" {
  inspect!(power_2_above(1, 15), content="16")
  inspect!(power_2_above(1, 16), content="16")
  inspect!(power_2_above(1, 17), content="32")
  inspect!(power_2_above(1, 32), content="32")
  inspect!(power_2_above(128, 33), content="128")
  inspect!(power_2_above(1, 2147483647), content="1073741824")
}

/// Create new hash map.
pub fn T::new[K, V](~capacity : Int = 8) -> T[K, V] {
  let capacity = power_2_above(8, capacity)
  { size: 0, capacity, entries: FixedArray::make(capacity, None) }
}

/// Create new hash map from array.
pub fn T::from_array[K : Hash + Eq, V](arr : Array[(K, V)]) -> T[K, V] {
  let m = new(capacity=arr.length())
  arr.each(fn(e) { m.set(e.0, e.1) })
  m
}

/// Set a key-value pair into hash map.
/// @alert unsafe "Panic if the hash map is full."
pub fn set[K : Hash + Eq, V](self : T[K, V], key : K, value : V) -> Unit {
  if self.size >= self.capacity.lsr(1) {
    self.grow()
  }
  let hash = key.hash()
  for idx = hash & (self.capacity - 1), entry = { psl: 0, hash, key, value } {
    match self.entries[idx] {
      None => {
        self.entries[idx] = Some(entry)
        self.size += 1
        break
      }
      Some(curr_entry) => {
        if curr_entry.hash == entry.hash && curr_entry.key == entry.key {
          curr_entry.value = entry.value
          break
        }
        let curr_entry = if entry.psl > curr_entry.psl {
          self.entries[idx] = Some(entry)
          curr_entry
        } else {
          entry
        }
        curr_entry.psl += 1
        continue (idx + 1) & (self.capacity - 1), curr_entry
      }
    }
  }
}

pub fn op_set[K : Hash + Eq, V](self : T[K, V], key : K, value : V) -> Unit {
  self.set(key, value)
}

/// Get the value associated with a key.
pub fn get[K : Hash + Eq, V](self : T[K, V], key : K) -> V? {
  let hash = key.hash()
  for i = 0, idx = hash & (self.capacity - 1) {
    // if i == self.capacity {
    //   panic()
    // }
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          break Some(entry.value)
        }
        if i > entry.psl {
          break None
        }
        continue i + 1, (idx + 1) & (self.capacity - 1)
      }
      None => break None
    }
  }
}

pub fn op_get[K : Hash + Eq, V](self : T[K, V], key : K) -> V? {
  self.get(key)
}

/// Get the value associated with a key, 
/// returns the provided default value if the key does not exist.
pub fn get_or_default[K : Hash + Eq, V](
  self : T[K, V],
  key : K,
  default : V
) -> V {
  match self.get(key) {
    Some(v) => v
    None => default
  }
}

/// Check if the hash map contains a key.
pub fn contains[K : Hash + Eq, V](self : T[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

/// Remove a key-value pair from hash map.
pub fn remove[K : Hash + Eq, V](self : T[K, V], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash & (self.capacity - 1) {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          self.entries[idx] = None
          self.shift_back(idx)
          self.size -= 1
          break
        }
        if i > entry.psl {
          break
        }
        continue i + 1, (idx + 1) & (self.capacity - 1)
      }
      None => break
    }
  }
}

fn shift_back[K : Hash, V](self : T[K, V], start_index : Int) -> Unit {
  for prev = start_index, curr = (start_index + 1) & (self.capacity - 1) {
    match self.entries[curr] {
      Some({ psl, hash, key, value, .. }) => {
        if psl == 0 {
          break
        }
        self.entries[prev] = Some({ psl: psl - 1, hash, key, value })
        self.entries[curr] = None
        continue curr, (curr + 1) & (self.capacity - 1)
      }
      None => break
    }
  }
}

// TODO: this could be further optimized
fn grow[K : Hash + Eq, V](self : T[K, V]) -> Unit {
  let old_entries = self.entries
  let new_capacity = self.capacity.lsl(1)
  self.entries = FixedArray::make(new_capacity, None)
  self.capacity = new_capacity
  self.size = 0
  for i = 0; i < old_entries.length(); i = i + 1 {
    match old_entries[i] {
      Some({ key, value, .. }) => self.set(key, value)
      None => ()
    }
  }
}

pub fn T::of[K : Eq + Hash, V](arr : FixedArray[(K, V)]) -> T[K, V] {
  let m = new(capacity=arr.length())
  arr.each(fn(e) { m.set(e.0, e.1) })
  m
}

test "of" {
  let m = of([(1, 2), (3, 4)])
  inspect!(m.get(1), content="Some(2)")
  inspect!(m.get(3), content="Some(4)")
}

priv type MyString String derive(Eq)

impl Hash for MyString with hash(self) { self._.length() }

impl Hash for MyString with hash_combine(self, hasher) {
  hasher.combine_string(self._)
}

impl Show for MyString with output(self, logger) { logger.write_string(self._) }

test "set" {
  let m : T[MyString, Int] = new()
  m.set("a", 1)
  m.set("b", 1)
  m.set("bc", 2)
  m.set("abc", 3)
  m.set("cd", 2)
  m.set("c", 1)
  m.set("d", 1)
  assert_eq!(m.size(), 7)
  inspect!(
    m.debug_entries(),
    content="_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )
}

test "remove" {
  let m : T[MyString, Int] = new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("bc", 2)
  m.set("cd", 2)
  m.set("abc", 3)
  m.set("abcdef", 6)
  m.remove("ab")
  assert_eq!(m.size(), 5)
  inspect!(
    m.debug_entries(),
    content="_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_,_,_,_,_,_,_,_,_",
  )
}

test "remove_unexist_key" {
  let m : T[MyString, Int] = new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  assert_eq!(m.size(), 3)
  inspect!(m.debug_entries(), content="_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_")
}

test "clear" {
  let m : T[MyString, Int] = of([("a", 1), ("b", 2), ("c", 3)])
  m.clear()
  assert_eq!(m.size(), 0)
  assert_eq!(m.capacity(), 8)
  for i = 0; i < m.capacity(); i = i + 1 {
    @test.is!(m.entries[i], None)
  }
}

test "grow" {
  let m : T[MyString, Int] = new()
  m.set("C", 1)
  m.set("Go", 2)
  m.set("C++", 3)
  m.set("Java", 4)
  m.set("Scala", 5)
  m.set("Julia", 5)
  assert_eq!(m.size(), 6)
  inspect!(m.capacity(), content="16")
  m.set("Cobol", 5)
  assert_eq!(m.size(), 7)
  inspect!(m.capacity(), content="16")
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  assert_eq!(m.size(), 10)
  inspect!(m.capacity(), content="32")
  inspect!(
    m.debug_entries(),
    content="_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_",
  )
}
