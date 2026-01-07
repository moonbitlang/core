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

// Types

///|
priv struct Entry[K, V] {
  mut prev : Int
  mut next : Entry[K, V]?
  mut psl : Int
  hash : Int
  key : K
  mut value : V
} derive(Show)

///|
/// Mutable linked hash map that maintains the order of insertion, not thread safe.
///
/// # Example
///
/// ```mbt check
/// test {
///   let map = { 3: "three", 8: "eight", 1: "one" }
///   assert_eq(map.get(2), None)
///   assert_eq(map.get(3), Some("three"))
///   map.set(3, "updated")
///   assert_eq(map.get(3), Some("updated"))
/// }
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
/// Create a hash map.
/// The capacity of the map will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
pub fn[K, V] Map::new(capacity? : Int = 8) -> Map[K, V] {
  let capacity = capacity.next_power_of_two()
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
pub fn[K : Hash + Eq, V] Map::from_array(arr : ArrayView[(K, V)]) -> Map[K, V] {
  let length = arr.length()
  let mut capacity = length.next_power_of_two()
  if length > calc_grow_threshold(capacity) {
    capacity *= 2
  }
  let m = Map::new(capacity~)
  for e in arr {
    m.set(e.0, e.1)
  }
  m
}

///|
/// Sets a key-value pair into the hash map. If the key already exists, updates
/// its value. If the hash map is near full capacity, automatically
/// grows the internal storage to accommodate more entries.
///
/// Parameters:
///
/// * `map` : The hash map to modify.
/// * `key` : The key to insert or update. Must implement `Hash` and `Eq` traits.
/// * `value` : The value to associate with the key.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map : Map[String, Int] = Map::new()
///   map.set("key", 42)
///   inspect(map.get("key"), content="Some(42)")
///   map.set("key", 24) // update existing key
///   inspect(map.get("key"), content="Some(24)")
/// }
/// ```
#alias("_[_]=_")
pub fn[K : Hash + Eq, V] Map::set(self : Map[K, V], key : K, value : V) -> Unit {
  self.set_with_hash(key, value, key.hash())
}

///|
fn[K : Eq, V] Map::set_with_hash(
  self : Map[K, V],
  key : K,
  value : V,
  hash : Int,
) -> Unit {
  if self.size >= self.grow_at {
    self.grow()
  }
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
  entry : Entry[K, V],
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
  new_idx : Int,
) -> Unit {
  self.entries[new_idx] = Some(entry)
  match entry.next {
    None => self.tail = new_idx
    Some(next) => next.prev = new_idx
  }
}

///|
/// Retrieves the value associated with a given key in the hash map.
///
/// Parameters:
///
/// * `self` : The hash map to search in.
/// * `key` : The key to look up in the map.
///
/// Returns `Some(value)` if the key exists in the map, `None` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = { "key": 42 }
///   inspect(map.get("key"), content="Some(42)")
///   inspect(map.get("nonexistent"), content="None")
/// }
/// ```
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
#alias("_[_]")
pub fn[K : Hash + Eq, V] Map::at(self : Map[K, V], key : K) -> V {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry)
    if entry.hash == hash && entry.key == key {
      return entry.value
    }
    guard i <= entry.psl
    continue i + 1, (idx + 1) & self.capacity_mask
  }
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
/// ```mbt check
/// test {
///   let map = { "a": 1, "b": 2 }
///   inspect(map.get_or_default("a", 0), content="1")
///   inspect(map.get_or_default("c", 42), content="42")
/// }
/// ```
pub fn[K : Hash + Eq, V] Map::get_or_default(
  self : Map[K, V],
  key : K,
  default : V,
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
  default : () -> V,
) -> V {
  let hash = key.hash()
  let (idx, psl, new_value, push_away) = for psl = 0, idx = hash &
                                               self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          return entry.value
        }
        if psl > entry.psl {
          let new_value = default()
          break (idx, psl, new_value, Some(entry))
        }
        continue psl + 1, (idx + 1) & self.capacity_mask
      }
      None => {
        let new_value = default()
        break (idx, psl, new_value, None)
      }
    }
  }
  if self.size >= self.grow_at {
    // Slow path, we need to resize
    self.grow()
    self.set_with_hash(key, new_value, hash)
  } else {
    if push_away is Some(entry) {
      self.push_away(idx, entry)
    }
    let entry = {
      prev: self.tail,
      next: None,
      psl,
      hash,
      key,
      value: new_value,
    }
    self.add_entry_to_tail(idx, entry)
  }
  new_value
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
/// ```mbt check
/// test {
///   let map = { "a": 1, "b": 2 }
///   inspect(map.contains_kv("a", 1), content="true")
///   inspect(map.contains_kv("a", 2), content="false")
///   inspect(map.contains_kv("c", 3), content="false")
/// }
/// ```
pub fn[K : Hash + Eq, V : Eq] Map::contains_kv(
  self : Map[K, V],
  key : K,
  value : V,
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
/// Removes the entry for the specified key from the hash map. If the key exists
/// in the map, removes its entry and adjusts the probe sequence length (PSL) of
/// subsequent entries to maintain the Robin Hood hashing invariant. If the key
/// does not exist, the map remains unchanged.
///
/// Parameters:
///
/// * `self` : The hash map to remove the entry from.
/// * `key` : The key to remove from the map.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = { "a": 1, "b": 2 }
///   map.remove("a")
///   inspect(map.get("a"), content="None")
///   inspect(map.length(), content="1")
/// }
/// ```
pub fn[K : Hash + Eq, V] Map::remove(self : Map[K, V], key : K) -> Unit {
  self.remove_with_hash(key, key.hash())
}

///|
fn[K : Eq, V] Map::remove_with_hash(
  self : Map[K, V],
  key : K,
  hash : Int,
) -> Unit {
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
  entry : Entry[K, V],
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
fn[K : Eq, V] Map::grow(self : Map[K, V]) -> Unit {
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
    Some({ next, key, value, hash, .. }) => {
      self.set_with_hash(key, value, hash)
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
#alias(size, deprecated)
pub fn[K, V] Map::length(self : Map[K, V]) -> Int {
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
  f : (K, V) -> Unit raise?,
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
  f : (Int, K, V) -> Unit raise?,
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
#alias(iterator, deprecated)
pub fn[K, V] Map::iter(self : Map[K, V]) -> Iter[(K, V)] {
  let mut curr_entry = self.head
  Iter::new(fn() {
    match curr_entry {
      Some({ key, value, next, .. }) => {
        curr_entry = next
        Some((key, value))
      }
      None => None
    }
  })
}

///|
#alias(iterator2, deprecated)
pub fn[K, V] Map::iter2(self : Map[K, V]) -> Iter2[K, V] {
  self.iter()
}

///|
pub fn[K, V] Map::keys(self : Map[K, V]) -> Iter[K] {
  let mut curr_entry = self.head
  Iter::new(fn() {
    match curr_entry {
      Some({ key, next, .. }) => {
        curr_entry = next
        Some(key)
      }
      None => None
    }
  })
}

///|
pub fn[K, V] Map::values(self : Map[K, V]) -> Iter[V] {
  let mut curr_entry = self.head
  Iter::new(fn() {
    match curr_entry {
      Some({ value, next, .. }) => {
        curr_entry = next
        Some(value)
      }
      None => None
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
pub impl[K : Hash + Eq, V : Eq] Eq for Map[K, V] with equal(
  self : Map[K, V],
  that : Map[K, V],
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
  let mut capacity = length.next_power_of_two()
  if length > calc_grow_threshold(capacity) {
    capacity *= 2
  }
  let m = Map::new(capacity~)
  // arr.iter((e) => { m.set(e.0, e.1) })
  for i in 0..<length {
    let e = arr[i]
    m.set(e.0, e.1)
  }
  m
}

///|
#alias(from_iterator, deprecated)
pub fn[K : Hash + Eq, V] Map::from_iter(iter : Iter[(K, V)]) -> Map[K, V] {
  let m = {}
  while iter.next() is Some((k, v)) {
    m.set(k, v)
  }
  m
}

///|
pub impl[K, V] Default for Map[K, V] with default() {
  Map::new()
}

///|
/// Applies a function to each key-value pair in the map and returns a new map with the results, using the original keys.
pub fn[K, V, V2] Map::map(self : Map[K, V], f : (K, V) -> V2) -> Map[K, V2] {
  // copy structure
  let other = {
    capacity: self.capacity,
    entries: FixedArray::make(self.capacity, None),
    size: self.size,
    capacity_mask: self.capacity_mask,
    grow_at: self.grow_at,
    head: None,
    tail: self.tail,
  }
  if self.size == 0 {
    return other
  }
  guard self.entries[self.tail] is Some(last)
  loop (last, self.tail, None) {
    ({ prev, psl, hash, key, value, .. }, idx, next) => {
      let new_value = f(key, value)
      let new_entry = { prev, next, psl, hash, key, value: new_value }
      other.entries[idx] = Some(new_entry)
      if prev != -1 {
        continue (self.entries[prev].unwrap(), prev, Some(new_entry))
      } else {
        other.head = Some(new_entry)
      }
    }
  }
  other
}

///|
/// Copy the map, creating a new map with the same key-value pairs and order of insertion.
pub fn[K, V] Map::copy(self : Map[K, V]) -> Map[K, V] {
  // copy structure
  let other = {
    capacity: self.capacity,
    entries: FixedArray::make(self.capacity, None),
    size: self.size,
    capacity_mask: self.capacity_mask,
    grow_at: self.grow_at,
    head: None,
    tail: self.tail,
  }
  if self.size == 0 {
    return other
  }
  guard self.entries[self.tail] is Some(last)
  loop (last, self.tail, None) {
    ({ prev, psl, hash, key, value, .. }, idx, next) => {
      let new_entry = { prev, next, psl, hash, key, value }
      other.entries[idx] = Some(new_entry)
      if prev != -1 {
        continue (self.entries[prev].unwrap(), prev, Some(new_entry))
      } else {
        other.head = Some(new_entry)
      }
    }
  }
  other
}

///|
/// Merges two maps into a new map. Returns a new map containing all key-value
/// pairs from both maps. When both maps contain the same key, the value from
/// `other` takes precedence. The iteration order follows the order of `self`
/// followed by new entries from `other`.
///
/// This is a pure operation - it does not modify either of the input maps.
///
/// Parameters:
///
/// * `self` : The first map.
/// * `other` : The second map whose values take precedence in case of key
/// conflicts.
///
/// Returns a new linked hash map containing all entries from both maps.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map1 : Map[String, Int] = { "a": 1, "b": 2 }
///   let map2 : Map[String, Int] = { "b": 3, "c": 4 }
///   let merged = map1.merge(map2)
///   @json.inspect(merged, content={ "a": 1, "b": 3, "c": 4 })
/// }
/// ```
pub fn[K : Eq, V] Map::merge(self : Map[K, V], other : Map[K, V]) -> Map[K, V] {
  let result = self.copy()
  result.merge_in_place(other)
  result
}

///|
/// Merges another map into this map in-place. Updates the current map by adding
/// all key-value pairs from `other`. When both maps contain the same key, the
/// value from `other` overwrites the value in this map. New entries from `other`
/// are added at the end, preserving the original order of `self` and appending
/// new keys from `other`.
///
/// This is a mutating operation - it modifies the receiver map.
///
/// Parameters:
///
/// * `self` : The map to be modified.
/// * `other` : The map whose entries will be added to `self`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map1 : Map[String, Int] = { "a": 1, "b": 2 }
///   let map2 : Map[String, Int] = { "b": 3, "c": 4 }
///   map1.merge_in_place(map2)
///   @json.inspect(map1, content={ "a": 1, "b": 3, "c": 4 })
/// }
/// ```
pub fn[K : Eq, V] Map::merge_in_place(
  self : Map[K, V],
  other : Map[K, V],
) -> Unit {
  loop other.head {
    Some({ key, value, next, hash, .. }) => {
      self.set_with_hash(key, value, hash)
      continue next
    }
    None => break
  }
}

///|
/// Retains only the key-value pairs that satisfy the given predicate function.
/// This method modifies the map in-place, removing all entries for which
/// the predicate returns `false`. The order of remaining elements is preserved.
///
/// Parameters:
///
/// * `self` : The map to be filtered.
/// * `predicate` : A function that takes a key and value as arguments and returns
/// `true` if the key-value pair should be kept, `false` if it should be removed.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = { "a": 1, "b": 2, "c": 3, "d": 4 }
///   map.retain((_k, v) => v % 2 == 0) // Keep only even values
///   inspect(map.length(), content="2")
///   inspect(map.get("a"), content="None")
///   inspect(map.get("b"), content="Some(2)")
///   inspect(map.get("c"), content="None")
///   inspect(map.get("d"), content="Some(4)")
/// }
/// ```
#locals(f)
pub fn[K, V] Map::retain(self : Map[K, V], f : (K, V) -> Bool) -> Unit {
  loop (self.head, false) {
    (Some({ key, value, next, prev: idx, .. }), remove_prev) => {
      if remove_prev {
        guard self.entries[idx] is Some(entry)
        self.remove_entry(entry)
        self.shift_back(idx)
        self.size -= 1
      }
      continue (next, !f(key, value))
    }
    (None, remove_prev) =>
      if remove_prev {
        let idx = self.tail
        guard self.entries[idx] is Some(entry)
        self.remove_entry(entry)
        self.shift_back(idx)
        self.size -= 1
      }
  }
}

///|
/// Updates a value in the map based on the existing value.
///
/// This method allows you to conditionally update, insert, or remove a key-value pair
/// based on whether the key already exists in the map. The provided function `f` is
/// called with `Some(current_value)` if the key exists, or `None` if it doesn't.
///
/// Parameters:
///
/// * `self` : The map to update.
/// * `key` : The key to update.
/// * `f` : A function that takes the current value (wrapped in `Option`) and returns
///   the new value (wrapped in `Option`). Returning `None` will remove the key-value
///   pair from the map.
///
/// Behavior:
///
/// * If the key exists and `f` returns `Some(new_value)`, the value is updated.
/// * If the key exists and `f` returns `None`, the key-value pair is removed.
/// * If the key doesn't exist and `f` returns `Some(new_value)`, a new pair is inserted.
/// * If the key doesn't exist and `f` returns `None`, no operation is performed.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = { "a": 1, "b": 2 }
///
///   // Update existing value
///   map.update("a", fn(v) {
///     match v {
///       Some(x) => Some(x + 10)
///       None => Some(0)
///     }
///   })
///   inspect(
///     map,
///     content=(
///       #|{"a": 11, "b": 2}
///     ),
///   )
///
///   // Insert new value
///   map.update("c", fn(v) {
///     match v {
///       Some(x) => Some(x)
///       None => Some(3)
///     }
///   })
///   inspect(
///     map,
///     content=(
///       #|{"a": 11, "b": 2, "c": 3}
///     ),
///   )
///
///   // Remove existing value
///   map.update("b", fn(_) { None })
///   inspect(
///     map,
///     content=(
///       #|{"a": 11, "c": 3}
///     ),
///   )
/// }
/// ```
pub fn[K : Hash + Eq, V] Map::update(
  self : Map[K, V],
  key : K,
  f : (V?) -> V?,
) -> Unit {
  let hash = key.hash()
  let (idx, psl, new_value, push_away) = for psl = 0, idx = hash &
                                               self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          // Found the entry, update its value
          if f(Some(entry.value)) is Some(new_value) {
            entry.value = new_value
          } else {
            // Remove the entry since the new value is None
            self.remove_entry(entry)
            self.shift_back(idx)
            self.size -= 1
          }
          return
        }
        if psl > entry.psl {
          guard f(None) is Some(new_value) else { return }
          break (idx, psl, new_value, Some(entry))
        }
        continue psl + 1, (idx + 1) & self.capacity_mask
      }
      None => {
        guard f(None) is Some(new_value) else { return }
        break (idx, psl, new_value, None)
      }
    }
  }
  if self.size >= self.grow_at {
    // Slow path, we need to resize
    self.grow()
    self.set(key, new_value)
  } else {
    if push_away is Some(entry) {
      self.push_away(idx, entry)
    }
    let entry = {
      prev: self.tail,
      next: None,
      psl,
      hash,
      key,
      value: new_value,
    }
    self.add_entry_to_tail(idx, entry)
  }
}

// Special handling for Views as accessors

///|
fn StringView::equal_to_string(self : Self, other : String) -> Bool {
  let str = self.str()
  let start = self.start()
  let end = self.end()
  let len = end - start
  guard len == other.length() else { return false }
  if physical_equal(str, other) && self.start() == 0 {
    return true
  }
  for i in 0..<len {
    guard str.unsafe_charcode_at(self.start() + i) ==
      other.unsafe_charcode_at(i) else {
      return false
    }
  }
  true
}

///|
fn BytesView::equal_to_bytes(self : Self, other : Bytes) -> Bool {
  let self_len = self.len()
  let start = self.start()
  guard self_len == other.length() else { return false }
  for i in 0..<self_len {
    guard self.bytes().unsafe_get(i + start) == other.unsafe_get(i) else {
      return false
    }
  }
  true
}

///|
/// Retrieves the value associated with a `BytesView` key in a map with `Bytes` keys.
///
/// This function allows efficient lookups using `BytesView` without creating a new `Bytes` object.
/// It's particularly useful when working with byte slices or subranges of existing byte arrays.
///
/// Parameters:
///
/// * `map` : The hash map with `Bytes` keys to search in.
/// * `key` : A `BytesView` representing the key to look up.
///
/// Returns `Some(value)` if a matching key exists in the map, `None` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = { b"hello": 1, b"world": 2 }
///   let bytes = b"prefix_hello_suffix"
///   let view = bytes[7:12] // view of "hello"
///   inspect(map.get_from_bytes(view), content="Some(1)")
/// }
/// ```
pub fn[V] Map::get_from_bytes(map : Self[Bytes, V], key : BytesView) -> V? {
  let hash = key.hash()
  for i = 0, idx = hash & map.capacity_mask {
    guard map.entries[idx] is Some(entry) else { break None }
    if entry.hash == hash && key.equal_to_bytes(entry.key) {
      break Some(entry.value)
    }
    if i > entry.psl {
      break None
    }
    continue i + 1, (idx + 1) & map.capacity_mask
  }
}

///|
/// Retrieves the value associated with a `StringView` key in a map with `String` keys.
///
/// This function allows efficient lookups using `StringView` without creating a new `String` object.
/// It's particularly useful when working with substrings or string slices.
///
/// Parameters:
///
/// * `map` : The hash map with `String` keys to search in.
/// * `key` : A `StringView` representing the key to look up.
///
/// Returns `Some(value)` if a matching key exists in the map, `None` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = { "hello": 1, "world": 2 }
///   let str = "say hello to everyone"
///   let view = str.view(start_offset=4, end_offset=9) // view of "hello"
///   inspect(map.get_from_string(view), content="Some(1)")
/// }
/// ```
pub fn[V] Map::get_from_string(map : Self[String, V], key : StringView) -> V? {
  let hash = key.hash()
  for i = 0, idx = hash & map.capacity_mask {
    guard map.entries[idx] is Some(entry) else { break None }
    if entry.hash == hash && key.equal_to_string(entry.key) {
      break Some(entry.value)
    }
    if i > entry.psl {
      break None
    }
    continue i + 1, (idx + 1) & map.capacity_mask
  }
}
