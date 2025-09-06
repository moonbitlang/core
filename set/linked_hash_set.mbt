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

// Types

///|
priv struct Entry[K] {
  mut prev : Int
  mut next : Entry[K]?
  mut psl : Int
  hash : Int
  key : K
} derive(Show)

///|
/// Mutable linked hash set that maintains the order of insertion, not thread safe.
///
/// # Example
///
/// ```mbt
///   let set = @set.Set::of(["three", "eight", "one"])
///   assert_eq(set.contains("two"), false)
///   assert_eq(set.contains("three"), true)
///   set.add("three") // no effect since it already exists
///   set.add("two")
///   assert_eq(set.contains("two"), true)
/// ```
struct Set[K] {
  mut entries : FixedArray[Entry[K]?]
  mut size : Int // active keys count
  mut capacity : Int // current capacity
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  mut grow_at : Int // threshold that triggers grow
  mut head : Entry[K]? // head of linked list
  mut tail : Int // tail of linked list
}

// Implementations

///|
/// Create a hash set.
/// The capacity of the set will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
#as_free_fn
pub fn[K] Set::new(capacity? : Int = 8) -> Set[K] {
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
/// Create a hash set from array.
#as_free_fn
pub fn[K : Hash + Eq] Set::from_array(arr : Array[K]) -> Set[K] {
  let m = Set::new(capacity=arr.length())
  arr.each(e => m.add(e))
  m
}

///|
/// Insert a key into the hash set.
///
/// Parameters:
///
/// * `set` : The hash set to modify.
/// * `key` : The key to insert. Must implement `Hash` and `Eq` traits.
///
/// Example:
///
/// ```moonbit
///   let set : @set.Set[String] = @set.Set::new()
///   set.add("key")
///   inspect(set.contains("key"), content="true")
///   set.add("key") // no effect since it already exists
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] add(self : Set[K], key : K) -> Unit {
  self.add_with_hash(key, key.hash())
}

///|
fn[K : Eq] add_with_hash(self : Set[K], key : K, hash : Int) -> Unit {
  if self.size >= self.grow_at {
    self.grow()
  }
  let (idx, psl) = for psl = 0, idx = hash & self.capacity_mask {
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
  let entry = { prev: self.tail, next: None, psl, key, hash }
  self.add_entry_to_tail(idx, entry)
}

///|
fn[K] push_away(self : Set[K], idx : Int, entry : Entry[K]) -> Unit {
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
fn[K] set_entry(self : Set[K], entry : Entry[K], new_idx : Int) -> Unit {
  self.entries[new_idx] = Some(entry)
  match entry.next {
    None => self.tail = new_idx
    Some(next) => next.prev = new_idx
  }
}

///|
/// Insert a key into the hash set and returns whether the key was successfully added.
///
/// Parameters:
///
/// * `set` : The hash set to modify.
/// * `key` : The key to insert. Must implement `Hash` and `Eq` traits.
///
/// Returns `true` if the key was successfully added (i.e., it wasn't already present),
/// `false` if the key already existed in the set.
///
/// Example:
///
/// ```moonbit
///   let set : @set.Set[String] = @set.Set::new()
///   inspect(set.add_and_check("key"), content="true")  // First insertion
///   inspect(set.add_and_check("key"), content="false") // Already exists
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] add_and_check(self : Set[K], key : K) -> Bool {
  if self.size >= self.grow_at {
    self.grow()
  }
  let hash = key.hash()
  let (idx, psl, added) = for psl = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      None => break (idx, psl, true)
      Some(curr_entry) => {
        if curr_entry.hash == hash && curr_entry.key == key {
          break (idx, psl, false)
        }
        if psl > curr_entry.psl {
          self.push_away(idx, curr_entry)
          break (idx, psl, true)
        }
        continue psl + 1, (idx + 1) & self.capacity_mask
      }
    }
  }
  if added {
    let entry = { prev: self.tail, next: None, psl, key, hash }
    self.add_entry_to_tail(idx, entry)
  }
  added
}

///|
/// Check if the hash set contains a key.
pub fn[K : Hash + Eq] Set::contains(self : Set[K], key : K) -> Bool {
  // inline lookup to avoid unnecessary allocations
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
/// Remove a key from the hash set. If the key exists in the set, removes it
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
///   let set = @set.Set::of(["a", "b"])
///   set.remove("a")
///   inspect(set.contains("a"), content="false")
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] remove(self : Set[K], key : K) -> Unit {
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
/// Remove a key from the hash set and returns whether the key was successfully removed.
///
/// Parameters:
///
/// * `set` : The hash set to modify.
/// * `key` : The key to remove. Must implement `Hash` and `Eq` traits.
///
/// Returns `true` if the key was successfully removed (i.e., it was present),
/// `false` if the key didn't exist in the set.
///
/// Example:
///
/// ```moonbit
///   let set = @set.Set::of(["a", "b"])
///   inspect(set.remove_and_check("a"), content="true")  // Successfully removed
///   inspect(set.remove_and_check("a"), content="false") // Already removed
///   inspect(set.size(), content="1")
/// ```
pub fn[K : Hash + Eq] remove_and_check(self : Set[K], key : K) -> Bool {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break false }
    if entry.hash == hash && entry.key == key {
      self.remove_entry(entry)
      self.shift_back(idx)
      self.size -= 1
      break true
    }
    if i > entry.psl {
      break false
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
fn[K] add_entry_to_tail(self : Set[K], idx : Int, entry : Entry[K]) -> Unit {
  match self.tail {
    -1 => self.head = Some(entry)
    tail => self.entries[tail].unwrap().next = Some(entry)
  }
  self.tail = idx
  self.entries[idx] = Some(entry)
  self.size += 1
}

///|
fn[K] remove_entry(self : Set[K], entry : Entry[K]) -> Unit {
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
fn[K] shift_back(self : Set[K], idx : Int) -> Unit {
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
fn[K : Eq] grow(self : Set[K]) -> Unit {
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
    Some({ next, key, hash, .. }) => {
      self.add_with_hash(key, hash)
      continue next
    }
    None => break
  }
}

// Utils

///|
pub impl[K : Show] Show for Set[K] with output(self, logger) {
  logger.write_string("{")
  loop (0, self.head) {
    (_, None) => logger.write_string("}")
    (i, Some({ key, next, .. })) => {
      if i > 0 {
        logger.write_string(", ")
      }
      logger.write_object(key)
      continue (i + 1, next)
    }
  }
}

///|
/// Get the number of keys in the set.
pub fn[K] size(self : Set[K]) -> Int {
  self.size
}

///|
/// Get the capacity of the set.
pub fn[K] capacity(self : Set[K]) -> Int {
  self.capacity
}

///|
/// Check if the hash set is empty.
pub fn[K] is_empty(self : Set[K]) -> Bool {
  self.size == 0
}

///|
/// Iterate over all keys of the set in the order of insertion.
#locals(f)
pub fn[K] each(self : Set[K], f : (K) -> Unit raise?) -> Unit raise? {
  loop self.head {
    Some({ key, next, .. }) => {
      f(key)
      continue next
    }
    None => break
  }
}

///|
/// Iterate over all keys of the set in the order of insertion, with index.
#locals(f)
pub fn[K] eachi(self : Set[K], f : (Int, K) -> Unit raise?) -> Unit raise? {
  loop (0, self.head) {
    (i, Some({ key, next, .. })) => {
      f(i, key)
      continue (i + 1, next)
    }
    (_, None) => break
  }
}

///|
/// Clears the set, removing all keys. Keeps the allocated space.
pub fn[K] clear(self : Set[K]) -> Unit {
  self.entries.fill(None)
  self.size = 0
  self.head = None
  self.tail = -1
}

///|
/// Returns the iterator of the hash set, provide elements in the order of insertion.
pub fn[K] iter(self : Set[K]) -> Iter[K] {
  Iter::new(yield_ => loop self.head {
    Some({ key, next, .. }) => {
      guard yield_(key) is IterContinue else { break IterEnd }
      continue next
    }
    None => break IterContinue
  })
}

///|
/// Converts the hash set to an array.
pub fn[K] to_array(self : Set[K]) -> Array[K] {
  let arr = Array::new(capacity=self.size)
  loop self.head {
    Some({ key, next, .. }) => {
      arr.push(key)
      continue next
    }
    None => break
  }
  arr
}

///|
pub impl[K : Hash + Eq] Eq for Set[K] with equal(self, other) {
  guard self.size == other.size else { return false }
  for k in self {
    guard other.contains(k) else { return false }
  } else {
    true
  }
}

///|
#as_free_fn
pub fn[K : Hash + Eq] Set::of(arr : FixedArray[K]) -> Set[K] {
  let length = arr.length()
  let m = Set::new(capacity=length)
  for i in 0..<length {
    let e = arr[i]
    m.add(e)
  }
  m
}

///|
#as_free_fn
pub fn[K : Hash + Eq] Set::from_iter(iter : Iter[K]) -> Set[K] {
  let m = Set::new()
  for e in iter {
    m.add(e)
  }
  m
}

///|
pub impl[K] Default for Set[K] with default() {
  Set::new()
}

///|
/// Copy the set, creating a new set with the same keys and order of insertion.
pub fn[K] copy(self : Set[K]) -> Set[K] {
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
    ({ prev, psl, hash, key, .. }, idx, next) => {
      let new_entry = { prev, next, psl, hash, key }
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
pub fn[K : Hash + Eq] difference(self : Set[K], other : Set[K]) -> Set[K] {
  let m = Set::new()
  self.each(k => if !other.contains(k) { m.add(k) })
  m
}

///|
pub fn[K : Hash + Eq] symmetric_difference(
  self : Set[K],
  other : Set[K],
) -> Set[K] {
  let m = Set::new()
  self.each(k => if !other.contains(k) { m.add(k) })
  other.each(k => if !self.contains(k) { m.add(k) })
  m
}

///|
pub fn[K : Hash + Eq] union(self : Set[K], other : Set[K]) -> Set[K] {
  let m = Set::new()
  self.each(k => m.add(k))
  other.each(k => m.add(k))
  m
}

///|
pub fn[K : Hash + Eq] intersection(self : Set[K], other : Set[K]) -> Set[K] {
  let m = Set::new()
  self.each(k => if other.contains(k) { m.add(k) })
  m
}

///|
pub impl[X : ToJson] ToJson for Set[X] with to_json(self) {
  let res = Array::new(capacity=self.size)
  for v in self {
    res.push(v.to_json())
  }
  Json::array(res)
}

///|
/// Check if two sets have no common elements.
pub fn[K : Hash + Eq] is_disjoint(self : Set[K], other : Set[K]) -> Bool {
  if self.size() <= other.size() {
    for k in self {
      if other.contains(k) {
        return false
      }
    }
  } else {
    for k in other {
      if self.contains(k) {
        return false
      }
    }
  }
  true
}

///|
/// Check if the current set is a subset of another set.
pub fn[K : Hash + Eq] is_subset(self : Set[K], other : Set[K]) -> Bool {
  if self.size() <= other.size() {
    for k in self {
      if !other.contains(k) {
        return false
      }
    }
    true
  } else {
    false
  }
}

///|
/// Check if the current set is a superset of another set.
pub fn[K : Hash + Eq] is_superset(self : Set[K], other : Set[K]) -> Bool {
  other.is_subset(self)
}

///|
/// Intersection of two hash sets.
pub impl[K : Hash + Eq] BitAnd for Set[K] with land(self, other) {
  self.intersection(other)
}

///|
/// Union of two hash sets.
pub impl[K : Hash + Eq] BitOr for Set[K] with lor(self, other) {
  self.union(other)
}

///|
/// Symmetric difference of two hash sets.
pub impl[K : Hash + Eq] BitXOr for Set[K] with lxor(self, other) {
  self.symmetric_difference(other)
}

///|
/// Difference of two hash sets.
pub impl[K : Hash + Eq] Sub for Set[K] with sub(self, other) {
  self.difference(other)
}

///|
