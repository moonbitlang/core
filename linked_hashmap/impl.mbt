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

/// Create a hash map.
pub fn LinkedHashMap::new[K, V](
  ~hasher : Option[(K) -> Int] = None
) -> LinkedHashMap[K, V] {
  {
    size: 0,
    capacity: default_init_capacity,
    growAt: calc_grow_threshold(default_init_capacity),
    hasher,
    entries: @array.new(default_init_capacity, fn() { Empty }),
    head: None,
    tail: None,
  }
}

/// Create a hash map from array.
pub fn LinkedHashMap::from_array[K : Hash + Eq, V](
  arr : Array[(K, V)]
) -> LinkedHashMap[K, V] {
  let m = new()
  arr.iter(fn(e) { m.set(e.0, e.1) })
  m
}

/// Set a key-value pair into the hash map.
/// @alert unsafe "Panic if the hash map is full."
pub fn set[K : Hash + Eq, V](
  self : LinkedHashMap[K, V],
  key : K,
  value : V
) -> Unit {
  if self.capacity == 0 || self.size >= self.growAt {
    self.grow()
  }
  let hash = self.make_hash(key)
  let insert_entry = Entry::Valid(
    psl=0,
    ~hash,
    ~key,
    ~value,
    prev=None,
    next=None,
  )
  loop 0, self.index(hash), insert_entry {
    i, idx, Valid(~psl, ~hash, ~key, ~value, ..) as entry => {
      if i == self.capacity {
        abort("HashMap is full")
      }
      match self.entries[idx] {
        Empty => {
          self.entries[idx] = entry
          self.size += 1
          self.add_entry_to_tail(insert_entry)
          break
        }
        Valid(_) as curr_entry => {
          if curr_entry.hash == hash && curr_entry.key == key {
            curr_entry.value = value
            break
          }
          if psl > curr_entry.psl {
            self.entries[idx] = entry
            curr_entry.psl += 1
            continue i + 1, self.next_index(idx), curr_entry
          } else {
            entry.psl += 1
            continue i + 1, self.next_index(idx), entry
          }
        }
      }
    }
    _, _, _ => break
  }
}

pub fn op_set[K : Hash + Eq, V](
  self : LinkedHashMap[K, V],
  key : K,
  value : V
) -> Unit {
  self.set(key, value)
}

/// Get the value associated with a key.
pub fn get[K : Hash + Eq, V](self : LinkedHashMap[K, V], key : K) -> Option[V] {
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

pub fn op_get[K : Hash + Eq, V](
  self : LinkedHashMap[K, V],
  key : K
) -> Option[V] {
  self.get(key)
}

/// Get the value associated with a key, 
/// returns the provided default value if the key does not exist.
pub fn get_or_default[K : Hash + Eq, V](
  self : LinkedHashMap[K, V],
  key : K,
  default : V
) -> V {
  match self.get(key) {
    Some(v) => v
    None => default
  }
}

/// Check if the hash map contains a key.
pub fn contains[K : Hash + Eq, V](self : LinkedHashMap[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

/// Remove a key-value pair from hash map.
pub fn remove[K : Hash + Eq, V](self : LinkedHashMap[K, V], key : K) -> Unit {
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
          self.remove_entry(entry)
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

fn add_entry_to_tail[K : Eq, V](
  self : LinkedHashMap[K, V],
  entry : Entry[K, V]
) -> Unit {
  match entry {
    Valid(_) as e =>
      if self.tail.is_empty() {
        self.head = Some(entry)
        self.tail = Some(entry)
      } else {
        match self.tail.unwrap() {
          Valid(_) as tail => {
            tail.next = Some(entry)
            e.prev = Some(tail)
            self.tail = Some(entry)
          }
          _ => ()
        }
      }
    _ => ()
  }
}

fn remove_entry[K : Eq, V](
  self : LinkedHashMap[K, V],
  entry : Entry[K, V]
) -> Unit {
  match entry {
    Valid(_) as e => {
      if self.is_empty() {
        self.head = None
        self.tail = None
      } else {
        if e == self.head.unwrap() {
          self.head = e.next
        }
        if e == self.tail.unwrap() {
          self.tail = e.prev
        }
        match e.prev {
          Some(Valid(_) as prev) => prev.next = e.next
          _ => ()
        }
        match e.next {
          Some(Valid(_) as next) => next.prev = e.prev
          _ => ()
        }
      }
      e.prev = None
      e.next = None
    }
    _ => ()
  }
}

fn shift_back[K : Hash, V](
  self : LinkedHashMap[K, V],
  start_index : Int
) -> Unit {
  for i = 0, prev = start_index, curr = self.next_index(start_index)
      i < self.entries.length()
      i = i + 1, prev = curr, curr = self.next_index(curr) {
    match self.entries[curr] {
      Valid(~psl, ..) as entry => {
        if psl == 0 {
          break
        }
        entry.psl -= 1
        self.entries[prev] = entry
        self.entries[curr] = Empty
      }
      Empty => break
    }
  }
}

fn grow[K : Hash + Eq, V](self : LinkedHashMap[K, V]) -> Unit {
  // handle zero capacity
  if self.capacity == 0 {
    self.capacity = default_init_capacity
    self.growAt = calc_grow_threshold(self.capacity)
    self.size = 0
    self.entries = @array.new(self.capacity, fn() { Empty })
    return
  }
  let old_head = self.head
  self.entries = @array.new(self.capacity * 2, fn() { Empty })
  self.capacity = self.capacity * 2
  self.growAt = calc_grow_threshold(self.capacity)
  self.size = 0
  self.head = None
  loop old_head {
    Some(Valid(~key, ~value, ~next, ..)) => {
      self.set(key, value)
      continue next
    }
    _ => break
  }
}

fn make_hash[K : Hash, V](self : LinkedHashMap[K, V], key : K) -> Int {
  let hash : Int = match self.hasher {
    Some(hasher) => hasher(key)
    None => key.hash()
  }
  // Let higher 16 bits of the hash value participate in the calculation
  hash.lxor(hash.lsr(16))
}

fn index[K : Hash, V](self : LinkedHashMap[K, V], hash : Int) -> Int {
  hash.abs().land(self.capacity - 1)
}

fn next_index[K : Hash, V](self : LinkedHashMap[K, V], index : Int) -> Int {
  (index + 1).land(self.capacity - 1)
}

fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}
