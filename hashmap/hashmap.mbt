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

/// Create new hash map.
pub fn HashMap::new[K, V](~hasher : Option[(K) -> Int] = None) -> HashMap[K, V] {
  {
    size: 0,
    capacity: default_init_capacity,
    growAt: calc_grow_threshold(default_init_capacity),
    hasher,
    entries: @array.new(default_init_capacity, fn() { Empty }),
  }
}

/// Create new hash map from array.
pub fn HashMap::from_array[K : Hash + Eq, V](
  arr : Array[(K, V)]
) -> HashMap[K, V] {
  let m = new()
  arr.iter(fn(e) { m.set(e.0, e.1) })
  m
}

/// Set a key-value pair into hash map.
/// @alert unsafe "Panic if the hash map is full."
pub fn set[K : Hash + Eq, V](self : HashMap[K, V], key : K, value : V) -> Unit {
  if self.capacity == 0 || self.size >= self.growAt {
    self.grow()
  }
  let hash = self.make_hash(key)
  loop 0, self.index(hash), 0, hash, key, value {
    i, idx, psl, hash, key, value => {
      if i == self.capacity {
        abort("HashMap is full")
      }
      match self.entries[idx] {
        Empty => {
          self.entries[idx] = Entry::Valid(~psl, ~hash, ~key, ~value)
          self.size += 1
          break
        }
        Valid(psl=d, hash=h, key=k, value=v) => {
          if h == hash && k == key {
            self.entries[idx] = Valid(psl=d, hash=h, key=k, ~value)
            break
          }
          if psl > d {
            self.entries[idx] = Entry::Valid(~psl, ~hash, ~key, ~value)
            continue i + 1, self.next_index(idx), d + 1, h, k, v
          }
          continue i + 1, self.next_index(idx), psl + 1, hash, key, value
        }
      }
    }
  }
}

pub fn op_set[K : Hash + Eq, V](
  self : HashMap[K, V],
  key : K,
  value : V
) -> Unit {
  self.set(key, value)
}

/// Get the value associated with a key.
pub fn get[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Option[V] {
  let hash = self.make_hash(key)
  for i = 0, idx = self.index(hash)
      i < self.capacity
      i = i + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Valid(_) as entry => {
        if entry.hash == hash && entry.key == key {
          break Some(entry.value)
        }
        if i > entry.psl {
          break None
        }
      }
      Empty => break None
    }
  } else {
    None
  }
}

pub fn op_get[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Option[V] {
  self.get(key)
}

/// Get the value associated with a key, 
/// returns the provided default value if the key does not exist.
pub fn get_or_default[K : Hash + Eq, V](
  self : HashMap[K, V],
  key : K,
  default : V
) -> V {
  match self.get(key) {
    Some(v) => v
    None => default
  }
}

/// Check if the hash map contains a key.
pub fn contains[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

/// Remove a key-value pair from hash map.
pub fn remove[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Unit {
  let hash = self.make_hash(key)
  for i = 0, idx = self.index(hash)
      i < self.capacity
      i = i + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Valid(_) as entry => {
        if entry.hash == hash && entry.key == key {
          self.entries[idx] = Empty
          self.shift_back(idx)
          self.size -= 1
          break
        }
        if i > entry.psl {
          return
        }
      }
      Empty => ()
    }
  }
}

/// Get the number of key-value pairs in the map.
pub fn size[K, V](self : HashMap[K, V]) -> Int {
  self.size
}

/// Get the capacity of the map.
pub fn capacity[K, V](self : HashMap[K, V]) -> Int {
  self.capacity
}

/// Check if the hash map is empty.
pub fn is_empty[K, V](self : HashMap[K, V]) -> Bool {
  self.size == 0
}

// Iterate over all key-value pairs of the map.
pub fn iter[K, V](self : HashMap[K, V], f : (K, V) -> Unit) -> Unit {
  self.iteri(fn(_i, k, v) { f(k, v) })
}

// Iterate over all key-value pairs of the map, with index.
pub fn iteri[K, V](self : HashMap[K, V], f : (Int, K, V) -> Unit) -> Unit {
  for i = 0, idx = 0; i < self.capacity; {
    match self.entries[i] {
      Valid(_) as entry => {
        f(idx, entry.key, entry.value)
        continue i + 1, idx + 1
      }
      Empty => continue i + 1, idx
    }
  }
}

// TODO: add %array.fill entry
// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn clear[K, V](self : HashMap[K, V]) -> Unit {
  for i = 0; i < self.capacity; i = i + 1 {
    self.entries[i] = Empty
  }
  self.size = 0
}

pub fn as_iter[K, V](self : HashMap[K, V]) -> @iter.Iter[(K, V)] {
  @iter.Iter::_unstable_internal_make(
    fn(yield) {
      for i = 0, len = self.entries.length(); i < len; i = i + 1 {
        match self.entries[i] {
          Valid(~key, ~value, ..) =>
            if yield((key, value)).not() {
              break false
            }
          _ => continue
        }
      } else {
        true
      }
    },
  )
}

fn shift_back[K : Hash, V](self : HashMap[K, V], start_index : Int) -> Unit {
  for i = 0, prev = start_index, curr = self.next_index(start_index)
      i < self.entries.length()
      i = i + 1, prev = curr, curr = self.next_index(curr) {
    match self.entries[curr] {
      Valid(~psl, ~hash, ~key, ~value) => {
        if psl == 0 {
          break
        }
        self.entries[prev] = Valid(psl=psl - 1, ~hash, ~key, ~value)
        self.entries[curr] = Empty
      }
      Empty => break
    }
  }
}

fn grow[K : Hash + Eq, V](self : HashMap[K, V]) -> Unit {
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
      Valid(~key, ~value, ..) => self.set(key, value)
      _ => ()
    }
  }
}

fn make_hash[K : Hash, V](self : HashMap[K, V], key : K) -> Int {
  let hash : Int = match self.hasher {
    Some(hasher) => hasher(key)
    None => key.hash()
  }
  // Let higher 16 bits of the hash value participate in the calculation
  hash.lxor(hash.lsr(16))
}

fn index[K : Hash, V](self : HashMap[K, V], hash : Int) -> Int {
  hash.abs().land(self.capacity - 1)
}

fn next_index[K : Hash, V](self : HashMap[K, V], index : Int) -> Int {
  (index + 1).land(self.capacity - 1)
}

fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

fn debug_entries[K : Show, V : Show](self : HashMap[K, V]) -> String {
  for s = "", i = 0; i < self.entries.length(); {
    let s = if i > 0 { s + "," } else { s }
    match self.entries[i] {
      Empty => continue s + "_", i + 1
      Valid(~psl, ~key, ~value, ..) =>
        continue s + "(\(psl),\(key),\(value))", i + 1
    }
  } else {
    s
  }
}
