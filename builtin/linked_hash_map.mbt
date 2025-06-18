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
// Types
priv struct Entry[K, V] {
  mut prev : Int
  mut next : Entry[K, V]?
  mut psl : Int
  hash : Int
  key : K
  mut value : V
} derive(Show)

///|
impl[K : Eq, V] Eq for Entry[K, V] with op_equal(self, other) {
  self.hash == other.hash && self.key == other.key
}

///|
/// Mutable linked hash map that maintains the order of insertion, not thread safe.
///
/// # Example
///
/// ```mbt
///   let map = { 3: "three", 8 :  "eight", 1 :  "one"}
///   assert_eq(map.get(2), None)
///   assert_eq(map.get(3), Some("three"))
///   map.set(3, "updated")
///   assert_eq(map.get(3), Some("updated"))
/// ```
struct Map[K, V] {
  mut entries : FixedArray[Entry[K, V]?]
  mut size : Int // active key-value pairs count
  mut capacity : Int // current capacity
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  mut grow_at : Int // threshold that triggers grow
  mut head : Entry[K, V]? // head of linked list
  mut tail : Int // tail of linked list
}

// Implementations

///|
fn power_2_above(x : Int, n : Int) -> Int {
  for i = x {
    if i >= n {
      break i
    }
    let next = i << 1
    if next < 0 {
      // overflow happened
      break i
    }
    continue next
  }
}

///|
test "power_2_above" {
  inspect(power_2_above(1, 15), content="16")
  inspect(power_2_above(1, 16), content="16")
  inspect(power_2_above(1, 17), content="32")
  inspect(power_2_above(1, 32), content="32")
  inspect(power_2_above(128, 33), content="128")
  inspect(power_2_above(1, 2147483647), content="1073741824")
}

///|
/// Create a hash map.
/// The capacity of the map will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
pub fn[K, V] Map::new(capacity~ : Int = 8) -> Map[K, V] {
  let capacity = power_2_above(8, capacity)
  {
    size: 0,
    capacity,
    capacity_mask: capacity - 1,
    grow_at: calc_grow_threshold(capacity),
    entries: FixedArray::make(capacity, None),
    head: None,
    tail: -1,
  }
}

///|
/// Create a hash map from array.
pub fn[K : Hash + Eq, V] Map::from_array(arr : Array[(K, V)]) -> Map[K, V] {
  let m = Map::new(capacity=arr.length())
  arr.each(fn(e) { m.set(e.0, e.1) })
  m
}

///|
/// Set a key-value pair into the hash map.
pub fn[K : Hash + Eq, V] Map::set(self : Map[K, V], key : K, value : V) -> Unit {
  if self.size >= self.grow_at {
    self.grow()
  }
  let hash = key.hash()
  let (idx, psl) = for psl = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      None => break (idx, psl)
      Some(curr_entry) => {
        if curr_entry.hash == hash && curr_entry.key == key {
          curr_entry.value = value
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
  let entry = { prev: self.tail, next: None, psl, key, value, hash }
  self.add_entry_to_tail(idx, entry)
}

///|
fn[K, V] Map::push_away(
  self : Map[K, V],
  idx : Int,
  entry : Entry[K, V]
) -> Unit {
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
fn[K, V] Map::set_entry(
  self : Map[K, V],
  entry : Entry[K, V],
  new_idx : Int
) -> Unit {
  self.entries[new_idx] = Some(entry)
  match entry.next {
    None => self.tail = new_idx
    Some(next) => next.prev = new_idx
  }
}

///|
pub fn[K : Hash + Eq, V] Map::op_set(
  self : Map[K, V],
  key : K,
  value : V
) -> Unit {
  self.set(key, value)
}

///|
/// Get the value associated with a key.
pub fn[K : Hash + Eq, V] Map::get(self : Map[K, V], key : K) -> V? {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break None }
    if entry.hash == hash && entry.key == key {
      break Some(entry.value)
    }
    if i > entry.psl {
      break None
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
#deprecated("Use `get` instead. `op_get` will return `V` instead of `Option[V]` in the future.")
pub fn[K : Hash + Eq, V] Map::op_get(self : Map[K, V], key : K) -> V? {
  self.get(key)
}

///|
/// Returns the value associated with the key in the map, or computes and returns
/// a default value if the key does not exist.
///
/// Parameters:
///
/// * `map` : The map to search in.
/// * `key` : The key to look up in the map.
/// * `default` : A function that returns a default value when the key is not
/// found.
///
/// Returns either the value associated with the key if it exists, or the result
/// of calling the default function.
///
/// Example:
///
/// ```moonbit
///   let map = { "a": 1, "b": 2 }
///   inspect(map.get_or_default("a", 0), content="1")
///   inspect(map.get_or_default("c", 42), content="42")
/// ```
pub fn[K : Hash + Eq, V] Map::get_or_default(
  self : Map[K, V],
  key : K,
  default : V
) -> V {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          break entry.value
        }
        if i > entry.psl {
          break default
        }
        continue i + 1, (idx + 1) & self.capacity_mask
      }
      None => break default
    }
  }
}

///|
/// Returns the value for the given key, or sets and returns a default value if the key does not exist.
pub fn[K : Hash + Eq, V] Map::get_or_init(
  self : Map[K, V],
  key : K,
  default : () -> V
) -> V {
  match self.get(key) {
    Some(v) => v
    None => {
      let v = default()
      self.set(key, v)
      v
    }
  }
}

///|
/// Check if the hash map contains a key.
pub fn[K : Hash + Eq, V] Map::contains(self : Map[K, V], key : K) -> Bool {
  // inline Map::get to avoid boxing
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
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
/// Checks if a map contains a specific key-value pair.
///
/// Parameters:
///
/// * `map` : A map of type `Map[K, V]` to search in.
/// * `key` : The key to look up in the map.
/// * `value` : The value to be compared with the value associated with the key.
///
/// Returns `true` if the map contains the specified key and its associated value
/// equals the given value, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// 
///   let map = { "a": 1, "b": 2 }
///   inspect(map.contains_kv("a", 1), content="true")
///   inspect(map.contains_kv("a", 2), content="false")
///   inspect(map.contains_kv("c", 3), content="false")
/// ```
pub fn[K : Hash + Eq, V : Eq] Map::contains_kv(
  self : Map[K, V],
  key : K,
  value : V
) -> Bool {
  // inline Map::get to avoid boxing
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break false }
    if entry.hash == hash && entry.key == key && entry.value == value {
      break true
    }
    if i > entry.psl {
      break false
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
/// Remove a key-value pair from hash map.
pub fn[K : Hash + Eq, V] Map::remove(self : Map[K, V], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break }
    if entry.hash == hash && entry.key == key {
      self.remove_entry(entry)
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
fn[K, V] Map::add_entry_to_tail(
  self : Map[K, V],
  idx : Int,
  entry : Entry[K, V]
) -> Unit {
  match self.tail {
    -1 => self.head = Some(entry)
    tail => self.entries[tail].unwrap().next = Some(entry)
  }
  self.tail = idx
  self.entries[idx] = Some(entry)
  self.size += 1
}

///|
fn[K, V] Map::remove_entry(self : Map[K, V], entry : Entry[K, V]) -> Unit {
  match entry.prev {
    -1 => self.head = entry.next
    idx => self.entries[idx].unwrap().next = entry.next
  }
  match entry.next {
    None => self.tail = entry.prev
    Some(next) => next.prev = entry.prev
  }
}

///|
fn[K, V] Map::shift_back(self : Map[K, V], idx : Int) -> Unit {
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
fn[K : Hash + Eq, V] Map::grow(self : Map[K, V]) -> Unit {
  let old_head = self.head
  let new_capacity = self.capacity << 1
  self.entries = FixedArray::make(new_capacity, None)
  self.capacity = new_capacity
  self.capacity_mask = new_capacity - 1
  self.grow_at = calc_grow_threshold(self.capacity)
  self.size = 0
  self.head = None
  self.tail = -1
  loop old_head {
    Some({ next, key, value, .. }) => {
      self.set(key, value)
      continue next
    }
    None => break
  }
}

///|
fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

// Utils

///|
pub impl[K : Show, V : Show] Show for Map[K, V] with output(self, logger) {
  logger.write_string("{")
  loop (0, self.head) {
    (_, None) => logger.write_string("}")
    (i, Some({ key, value, next, .. })) => {
      if i > 0 {
        logger.write_string(", ")
      }
      logger..write_object(key)..write_string(": ")..write_object(value)
      continue (i + 1, next)
    }
  }
}

///|
/// Get the number of key-value pairs in the map.
pub fn[K, V] Map::size(self : Map[K, V]) -> Int {
  self.size
}

///|
/// Get the capacity of the map.
pub fn[K, V] Map::capacity(self : Map[K, V]) -> Int {
  self.capacity
}

///|
/// Check if the hash map is empty.
pub fn[K, V] Map::is_empty(self : Map[K, V]) -> Bool {
  self.size == 0
}

///|
/// Iterate over all key-value pairs of the map in the order of insertion.
#locals(f)
pub fn[K, V] Map::each(
  self : Map[K, V],
  f : (K, V) -> Unit raise?
) -> Unit raise? {
  loop self.head {
    Some({ key, value, next, .. }) => {
      f(key, value)
      continue next
    }
    None => break
  }
}

///|
/// Iterate over all key-value pairs of the map in the order of insertion, with index.
#locals(f)
pub fn[K, V] Map::eachi(
  self : Map[K, V],
  f : (Int, K, V) -> Unit raise?
) -> Unit raise? {
  loop (0, self.head) {
    (i, Some({ key, value, next, .. })) => {
      f(i, key, value)
      continue (i + 1, next)
    }
    (_, None) => break
  }
}

///|
/// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn[K, V] Map::clear(self : Map[K, V]) -> Unit {
  self.entries.fill(None)
  self.size = 0
  self.head = None
  self.tail = -1
}

///|
/// Returns the iterator of the hash map, provide elements in the order of insertion.
pub fn[K, V] Map::iter(self : Map[K, V]) -> Iter[(K, V)] {
  Iter::new(fn(yield_) {
    loop self.head {
      Some({ key, value, next, .. }) => {
        guard yield_((key, value)) is IterContinue else { break IterEnd }
        continue next
      }
      None => break IterContinue
    }
  })
}

///|
pub fn[K, V] Map::iter2(self : Map[K, V]) -> Iter2[K, V] {
  Iter2::new(fn(yield_) {
    loop self.head {
      Some({ key, value, next, .. }) => {
        guard yield_(key, value) is IterContinue else { break IterEnd }
        continue next
      }
      None => IterContinue
    }
  })
}

///|
pub fn[K, V] Map::keys(self : Map[K, V]) -> Iter[K] {
  Iter::new(fn(yield_) {
    loop self.head {
      Some({ key, next, .. }) => {
        guard yield_(key) is IterContinue else { break IterEnd }
        continue next
      }
      None => IterContinue
    }
  })
}

///|
pub fn[K, V] Map::values(self : Map[K, V]) -> Iter[V] {
  Iter::new(fn(yield_) {
    loop self.head {
      Some({ value, next, .. }) => {
        guard yield_(value) is IterContinue else { break IterEnd }
        continue next
      }
      None => IterContinue
    }
  })
}

///|
/// Converts the hash map to an array.
pub fn[K, V] Map::to_array(self : Map[K, V]) -> Array[(K, V)] {
  let arr = Array::make_uninit(self.size)
  let mut i = 0
  loop self.head {
    Some({ key, value, next, .. }) => {
      arr.unsafe_set(i, (key, value))
      i += 1
      continue next
    }
    None => break
  }
  arr
}

///|
pub impl[K : Hash + Eq, V : Eq] Eq for Map[K, V] with op_equal(
  self : Map[K, V],
  that : Map[K, V]
) -> Bool {
  guard self.size == that.size else { return false }
  for k, v in self {
    guard that.contains_kv(k, v) else { return false }
  } else {
    true
  }
}

///|
pub fn[K : Hash + Eq, V] Map::of(arr : FixedArray[(K, V)]) -> Map[K, V] {
  let length = arr.length()
  let m = Map::new(capacity=length)
  // arr.iter(fn(e) { m.set(e.0, e.1) })
  for i in 0..<length {
    let e = arr[i]
    m.set(e.0, e.1)
  }
  m
}

///|
pub fn[K : Hash + Eq, V] Map::from_iter(iter : Iter[(K, V)]) -> Map[K, V] {
  let m = {}
  for e in iter {
    m.set(e.0, e.1)
  }
  m
}

///|
pub impl[K, V] Default for Map[K, V] with default() {
  Map::new()
}
