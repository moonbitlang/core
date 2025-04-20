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
  mut idx : Int
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
priv struct ListNode[K, V] {
  mut prev : Entry[K, V]?
  mut next : Entry[K, V]?
}

///|
/// Mutable linked hash map that maintains the order of insertion, not thread safe.
///
/// # Example
///
/// ```
/// let map = { 3: "three", 8 :  "eight", 1 :  "one"}
/// assert_eq!(map.get(2), None)
/// assert_eq!(map.get(3), Some("three"))
/// map.set(3, "updated")
/// assert_eq!(map.get(3), Some("updated"))
/// ```
struct Map[K, V] {
  mut entries : FixedArray[Entry[K, V]?]
  mut list : FixedArray[ListNode[K, V]] // list of (prev, next)
  mut size : Int // active key-value pairs count
  mut capacity : Int // current capacity
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  mut growAt : Int // threshold that triggers grow
  mut head : Entry[K, V]? // head of linked list
  mut tail : Entry[K, V]? // tail of linked list
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
  inspect!(power_2_above(1, 15), content="16")
  inspect!(power_2_above(1, 16), content="16")
  inspect!(power_2_above(1, 17), content="32")
  inspect!(power_2_above(1, 32), content="32")
  inspect!(power_2_above(128, 33), content="128")
  inspect!(power_2_above(1, 2147483647), content="1073741824")
}

///|
/// Create a hash map.
/// The capacity of the map will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
pub fn Map::new[K, V](capacity~ : Int = 8) -> Map[K, V] {
  let capacity = power_2_above(8, capacity)
  {
    size: 0,
    capacity,
    capacity_mask: capacity - 1,
    growAt: calc_grow_threshold(capacity),
    entries: FixedArray::make(capacity, None),
    list: FixedArray::make(capacity, { prev: None, next: None }),
    head: None,
    tail: None,
  }
}

///|
/// Create a hash map from array.
pub fn Map::from_array[K : Hash + Eq, V](arr : Array[(K, V)]) -> Map[K, V] {
  let m = Map::new(capacity=arr.length())
  arr.each(fn(e) { m.set(e.0, e.1) })
  m
}

///|
/// Set a key-value pair into the hash map.
/// @alert unsafe "Panic if the hash map is full."
pub fn Map::set[K : Hash + Eq, V](self : Map[K, V], key : K, value : V) -> Unit {
  if self.size >= self.growAt {
    self.grow()
  }
  let hash = key.hash()
  let insert_entry = { idx: -1, psl: 0, hash, key, value }
  let list_node : ListNode[K, V] = { prev: None, next: None }
  loop 0, hash & self.capacity_mask, insert_entry, list_node {
    i, idx, entry, node =>
      match self.entries[idx] {
        None => {
          self.entries[idx] = Some(entry)
          self.list[idx] = node
          entry.idx = idx
          self.add_entry_to_tail(insert_entry)
          self.size += 1
          break
        }
        Some(curr_entry) => {
          let curr_node = self.list[curr_entry.idx]
          if curr_entry.hash == entry.hash && curr_entry.key == entry.key {
            curr_entry.value = entry.value
            break
          }
          if entry.psl > curr_entry.psl {
            self.entries[idx] = Some(entry)
            self.list[idx] = node
            entry.idx = idx
            curr_entry.psl += 1
            continue i + 1,
              (idx + 1) & self.capacity_mask,
              curr_entry,
              curr_node
          } else {
            entry.psl += 1
            continue i + 1, (idx + 1) & self.capacity_mask, entry, node
          }
        }
      }
  }
}

///|
pub fn Map::op_set[K : Hash + Eq, V](
  self : Map[K, V],
  key : K,
  value : V
) -> Unit {
  self.set(key, value)
}

///|
/// Get the value associated with a key.
pub fn Map::get[K : Hash + Eq, V](self : Map[K, V], key : K) -> V? {
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
pub fn Map::op_get[K : Hash + Eq, V](self : Map[K, V], key : K) -> V? {
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
/// test "get_or_default" {
///   let map = { "a": 1, "b": 2 }
///   inspect!(map.get_or_default("a", 0), content="1")
///   inspect!(map.get_or_default("c", 42), content="42")
/// }
/// ```
pub fn Map::get_or_default[K : Hash + Eq, V](
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
pub fn Map::get_or_init[K : Hash + Eq, V](
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
pub fn Map::contains[K : Hash + Eq, V](self : Map[K, V], key : K) -> Bool {
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
/// test "Map::contains_kv" {
///   let map = { "a": 1, "b": 2 }
///   inspect!(map.contains_kv("a", 1), content="true")
///   inspect!(map.contains_kv("a", 2), content="false")
///   inspect!(map.contains_kv("c", 3), content="false")
/// }
/// ```
pub fn Map::contains_kv[K : Hash + Eq, V : Eq](
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
pub fn Map::remove[K : Hash + Eq, V](self : Map[K, V], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break }
    if entry.hash == hash && entry.key == key {
      self.entries[idx] = None
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
fn Map::add_entry_to_tail[K : Eq, V](
  self : Map[K, V],
  entry : Entry[K, V]
) -> Unit {
  match self.tail {
    None => {
      self.head = Some(entry)
      self.tail = Some(entry)
    }
    Some(tail) => {
      self.list[tail.idx].next = Some(entry)
      self.list[entry.idx].prev = Some(tail)
      self.tail = Some(entry)
    }
  }
}

///|
fn Map::remove_entry[K : Eq, V](self : Map[K, V], entry : Entry[K, V]) -> Unit {
  let node = self.list[entry.idx]
  if self.is_empty() {
    self.head = None
    self.tail = None
  } else {
    if self.head.unwrap() == entry {
      self.head = node.next
    }
    if self.tail.unwrap() == entry {
      self.tail = node.prev
    }
    if node.prev is Some(prev) {
      self.list[prev.idx].next = node.next
    }
    if node.next is Some(next) {
      self.list[next.idx].prev = node.prev
    }
  }
  node.prev = None
  node.next = None
}

///|
fn Map::shift_back[K : Hash, V](self : Map[K, V], start_index : Int) -> Unit {
  for prev = start_index, curr = (start_index + 1) & self.capacity_mask {
    match (self.entries[curr], self.list[curr]) {
      (Some(entry), currNode) => {
        if entry.psl == 0 {
          break
        }
        entry.psl -= 1
        entry.idx = prev
        self.entries[prev] = Some(entry)
        self.entries[curr] = None
        self.list[prev].prev = currNode.prev
        self.list[prev].next = currNode.next
        currNode.prev = None
        currNode.next = None
        continue curr, (curr + 1) & self.capacity_mask
      }
      (None, _) => break
    }
  }
}

///|
fn Map::grow[K : Hash + Eq, V](self : Map[K, V]) -> Unit {
  let old_head = self.head
  let old_list = self.list
  let new_capacity = self.capacity << 1
  self.entries = FixedArray::make(new_capacity, None)
  self.list = FixedArray::make(new_capacity, { prev: None, next: None })
  self.capacity = new_capacity
  self.capacity_mask = new_capacity - 1
  self.growAt = calc_grow_threshold(self.capacity)
  self.size = 0
  self.head = None
  self.tail = None
  loop old_head {
    Some({ idx, key, value, .. }) => {
      self.set(key, value)
      continue old_list[idx].next
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
fn Map::debug_entries[K : Show, V : Show](self : Map[K, V]) -> String {
  let buf = StringBuilder::new()
  for i in 0..<self.entries.length() {
    if i > 0 {
      buf.write_char(',')
    }
    match self.entries[i] {
      None => buf.write_char('_')
      Some({ psl, key, value, .. }) =>
        buf.write_string("(\{psl},\{key},\{value})")
    }
  }
  buf.to_string()
}

///|
pub impl[K : Show, V : Show] Show for Map[K, V] with output(self, logger) {
  logger.write_string("{")
  loop 0, self.head {
    _, None => logger.write_string("}")
    i, Some({ key, value, idx, .. }) => {
      if i > 0 {
        logger.write_string(", ")
      }
      logger..write_object(key)..write_string(": ").write_object(value)
      continue i + 1, self.list[idx].next
    }
  }
}

///|
/// Get the number of key-value pairs in the map.
pub fn Map::size[K, V](self : Map[K, V]) -> Int {
  self.size
}

///|
/// Get the capacity of the map.
pub fn Map::capacity[K, V](self : Map[K, V]) -> Int {
  self.capacity
}

///|
/// Check if the hash map is empty.
pub fn Map::is_empty[K, V](self : Map[K, V]) -> Bool {
  self.size == 0
}

///|
/// Iterate over all key-value pairs of the map in the order of insertion.
pub fn Map::each[K, V](self : Map[K, V], f : (K, V) -> Unit) -> Unit {
  loop self.head {
    Some({ key, value, idx, .. }) => {
      f(key, value)
      continue self.list[idx].next
    }
    None => break
  }
}

///|
/// Iterate over all key-value pairs of the map in the order of insertion, with index.
pub fn Map::eachi[K, V](self : Map[K, V], f : (Int, K, V) -> Unit) -> Unit {
  loop 0, self.head {
    i, Some({ key, value, idx, .. }) => {
      f(i, key, value)
      continue i + 1, self.list[idx].next
    }
    _, None => break
  }
}

///|
/// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn Map::clear[K, V](self : Map[K, V]) -> Unit {
  self.entries.fill(None)
  self.size = 0
  self.head = None
  self.tail = None
}

///|
/// Returns the iterator of the hash map, provide elements in the order of insertion.
pub fn Map::iter[K, V](self : Map[K, V]) -> Iter[(K, V)] {
  Iter::new(fn(yield_) {
    loop self.head {
      Some({ key, value, idx, .. }) => {
        guard yield_((key, value)) is IterContinue else { break IterEnd }
        continue self.list[idx].next
      }
      None => break IterContinue
    }
  })
}

///|
pub fn Map::iter2[K, V](self : Map[K, V]) -> Iter2[K, V] {
  Iter2::new(fn(yield_) {
    loop self.head {
      Some({ key, value, idx, .. }) => {
        guard yield_(key, value) is IterContinue else { break IterEnd }
        continue self.list[idx].next
      }
      None => IterContinue
    }
  })
}

///|
pub fn Map::keys[K, V](self : Map[K, V]) -> Iter[K] {
  Iter::new(fn(yield_) {
    loop self.head {
      Some({ key, idx, .. }) => {
        guard yield_(key) is IterContinue else { break IterEnd }
        continue self.list[idx].next
      }
      None => IterContinue
    }
  })
}

///|
pub fn Map::values[K, V](self : Map[K, V]) -> Iter[V] {
  Iter::new(fn(yield_) {
    loop self.head {
      Some({ value, idx, .. }) => {
        guard yield_(value) is IterContinue else { break IterEnd }
        continue self.list[idx].next
      }
      None => IterContinue
    }
  })
}

///|
/// Converts the hash map to an array.
pub fn Map::to_array[K, V](self : Map[K, V]) -> Array[(K, V)] {
  let arr = Array::make_uninit(self.size)
  let mut i = 0
  loop self.head {
    Some({ key, value, idx, .. }) => {
      arr.unsafe_set(i, (key, value))
      i += 1
      continue self.list[idx].next
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
pub fn Map::of[K : Hash + Eq, V](arr : FixedArray[(K, V)]) -> Map[K, V] {
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
pub fn Map::from_iter[K : Hash + Eq, V](iter : Iter[(K, V)]) -> Map[K, V] {
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
