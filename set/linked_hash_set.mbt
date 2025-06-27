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
priv struct SEntry[K] {
  mut idx : Int
  mut psl : Int
  hash : Int
  key : K
}

///|
impl[K : Eq] Eq for SEntry[K] with op_equal(self, other) {
  self.hash == other.hash && self.key == other.key
}

///|
priv struct SListNode[K] {
  mut prev : SEntry[K]?
  mut next : SEntry[K]?
}

///|
/// Mutable linked hash set that maintains the order of insertion, not thread safe.
struct Set[K] {
  mut entries : FixedArray[SEntry[K]?]
  mut list : FixedArray[SListNode[K]]
  mut size : Int
  mut capacity : Int
  mut capacity_mask : Int
  mut grow_at : Int
  mut head : SEntry[K]?
  mut tail : SEntry[K]?
}

// Implementations

///|
/// Create a hash set.
/// The capacity of the set will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
pub fn[K] Set::new(capacity~ : Int = 8) -> Set[K] {
  let capacity = power_2_above(8, capacity)
  {
    size: 0,
    capacity,
    capacity_mask: capacity - 1,
    grow_at: calc_grow_threshold(capacity),
    entries: FixedArray::make(capacity, None),
    list: FixedArray::make(capacity, { prev: None, next: None }),
    head: None,
    tail: None,
  }
}

///|
/// Create a hash set from array.
pub fn[K : Hash + Eq] Set::from_array(arr : Array[K]) -> Set[K] {
  let m = Set::new(capacity=arr.length())
  arr.each(e => m.add(e))
  m
}

///|
/// Insert a key into the hash set.
///

///|
/// Insert a key into the hash set.if the key exists return false
pub fn[K : Hash + Eq] add_and_check(self : Set[K], key : K) -> Bool {
  if self.size >= self.grow_at {
    self.grow()
  }
  let hash = key.hash()
  let insert_entry = { idx: -1, psl: 0, hash, key }
  let list_node : SListNode[K] = { prev: None, next: None }
  for i = 0, idx = hash & self.capacity_mask, entry = insert_entry, node = list_node {
    match self.entries[idx] {
      None => {
        self.entries[idx] = Some(entry)
        self.list[idx] = node
        entry.idx = idx
        self.add_entry_to_tail(insert_entry)
        self.size += 1
        break true
      }
      Some(curr_entry) => {
        let curr_node = self.list[curr_entry.idx]
        if curr_entry.hash == entry.hash && curr_entry.key == entry.key {
          break false
        }
        if entry.psl > curr_entry.psl {
          self.entries[idx] = Some(entry)
          self.list[idx] = node
          entry.idx = idx
          curr_entry.psl += 1
          continue i + 1, (idx + 1) & self.capacity_mask, curr_entry, curr_node
        } else {
          entry.psl += 1
          continue i + 1, (idx + 1) & self.capacity_mask, entry, node
        }
      }
    }
  }
}

///|
/// Insert a key into the hash set.
pub fn[K : Hash + Eq] add(self : Set[K], key : K) -> Unit {
  if self.size >= self.grow_at {
    self.grow()
  }
  let hash = key.hash()
  let insert_entry = { idx: -1, psl: 0, hash, key }
  let list_node : SListNode[K] = { prev: None, next: None }
  for i = 0, idx = hash & self.capacity_mask, entry = insert_entry, node = list_node {
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
          break
        }
        if entry.psl > curr_entry.psl {
          self.entries[idx] = Some(entry)
          self.list[idx] = node
          entry.idx = idx
          curr_entry.psl += 1
          continue i + 1, (idx + 1) & self.capacity_mask, curr_entry, curr_node
        } else {
          entry.psl += 1
          continue i + 1, (idx + 1) & self.capacity_mask, entry, node
        }
      }
    }
  }
}

///|
/// Check if the hash set contains a key.
pub fn[K : Hash + Eq] contains(self : Set[K], key : K) -> Bool {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          break true
        }
        if i > entry.psl {
          break false
        }
        continue i + 1, (idx + 1) & self.capacity_mask
      }
      None => break false
    }
  }
}

///|
/// Remove a key from hash set.
pub fn[K : Hash + Eq] remove(self : Set[K], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
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
      None => break
    }
  }
}

///|
/// Remove a key from hash set.if the key exists, delete it and return true
pub fn[K : Hash + Eq] remove_and_check(self : Set[K], key : K) -> Bool {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          self.entries[idx] = None
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
      None => break false
    }
  }
}

///|
fn[K] add_entry_to_tail(self : Set[K], entry : SEntry[K]) -> Unit {
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
fn[K : Eq] remove_entry(self : Set[K], entry : SEntry[K]) -> Unit {
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
fn[K] shift_back(self : Set[K], start_index : Int) -> Unit {
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
fn[K : Hash + Eq] grow(self : Set[K]) -> Unit {
  let old_head = self.head
  let old_list = self.list
  let new_capacity = self.capacity << 1
  self.entries = FixedArray::make(new_capacity, None)
  self.list = FixedArray::make(new_capacity, { prev: None, next: None })
  self.capacity = new_capacity
  self.capacity_mask = new_capacity - 1
  self.grow_at = calc_grow_threshold(self.capacity)
  self.size = 0
  self.head = None
  self.tail = None
  loop old_head {
    Some({ idx, key, .. }) => {
      self.add(key)
      continue old_list[idx].next
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
    (i, Some({ key, idx, .. })) => {
      if i > 0 {
        logger.write_string(", ")
      }
      logger.write_object(key)
      continue (i + 1, self.list[idx].next)
    }
  }
}

///|
pub impl[K] Default for Set[K] with default() {
  Set::new()
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
pub fn[K] each(self : Set[K], f : (K) -> Unit raise?) -> Unit raise? {
  loop self.head {
    Some({ key, idx, .. }) => {
      f(key)
      continue self.list[idx].next
    }
    None => break
  }
}

///|
/// Iterate over all keys of the set in the order of insertion, with index.
pub fn[K] eachi(self : Set[K], f : (Int, K) -> Unit raise?) -> Unit raise? {
  loop (0, self.head) {
    (i, Some({ key, idx, .. })) => {
      f(i, key)
      continue (i + 1, self.list[idx].next)
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
  self.tail = None
}

///|
/// Returns the iterator of the hash set, provide elements in the order of insertion.
pub fn[K] iter(self : Set[K]) -> Iter[K] {
  Iter::new(yield_ => loop self.head {
    Some({ key, idx, .. }) => {
      if yield_(key) == IterEnd {
        break IterEnd
      }
      continue self.list[idx].next
    }
    None => break IterContinue
  })
}

///|
/// Converts the hash set to an array.
pub fn[K] to_array(self : Set[K]) -> Array[K] {
  let res = Array::new(capacity=self.size)
  loop self.head {
    Some({ key, idx, .. }) => {
      res.push(key)
      continue self.list[idx].next
    }
    None => break
  }
  res
}

///|
pub impl[K : Hash + Eq] Eq for Set[K] with op_equal(self, other) {
  if self.size != other.size {
    return false
  }
  loop self.head {
    None => true
    Some({ key, idx, .. }) => {
      if not(other.contains(key)) {
        return false
      }
      continue self.list[idx].next
    }
  }
}

///|
pub fn[K : Hash + Eq] Set::of(arr : FixedArray[K]) -> Set[K] {
  let length = arr.length()
  let m = Set::new(capacity=length)
  // arr.iter((e) => { m.set(e.0, e.1) })
  for i in 0..<length {
    let e = arr[i]
    m.add(e)
  }
  m
}

///|
pub fn[K : Hash + Eq] Set::from_iter(iter : Iter[K]) -> Set[K] {
  let m = Set::new()
  iter.each(e => m.add(e))
  m
}

///|
pub fn[K : Hash + Eq] difference(self : Set[K], other : Set[K]) -> Set[K] {
  let m = Set::new()
  self.each(k => if not(other.contains(k)) { m.add(k) })
  m
}

///|
pub fn[K : Hash + Eq] symmetric_difference(
  self : Set[K],
  other : Set[K]
) -> Set[K] {
  let m = Set::new()
  self.each(k => if not(other.contains(k)) { m.add(k) })
  other.each(k => if not(self.contains(k)) { m.add(k) })
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
