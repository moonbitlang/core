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

// Types

priv struct SEntry[K] {
  mut idx : Int
  mut psl : Int
  hash : Int
  key : K
} derive(Show)

fn op_equal[K : Eq](self : SEntry[K], other : SEntry[K]) -> Bool {
  self.hash == other.hash && self.key == other.key
}

priv struct SListNode[K] {
  mut prev : SEntry[K]?
  mut next : SEntry[K]?
}

/// Mutable linked hash set that maintains the order of insertion, not thread safe. 
struct Set[K] {
  mut entries : FixedArray[SEntry[K]?]
  mut list : FixedArray[SListNode[K]]
  mut size : Int
  mut capacity : Int
  mut capacity_mask : Int
  mut growAt : Int
  mut head : SEntry[K]?
  mut tail : SEntry[K]?
}

// Implementations

/// Create a hash set.
/// The capacity of the set will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
pub fn Set::new[K](~capacity : Int = 8) -> Set[K] {
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

/// Create a hash set from array.
pub fn Set::from_array[K : Hash + Eq](arr : Array[K]) -> Set[K] {
  let m = Set::new(capacity=arr.length())
  arr.each(fn(e) { m.insert(e) })
  m
}

/// Insert a key into the hash set.
/// @alert unsafe "Panic if the hash set is full."
pub fn insert[K : Hash + Eq](self : Set[K], key : K) -> Unit {
  if self.size >= self.growAt {
    self.grow()
  }
  let hash = key.hash()
  let insert_entry = { idx: -1, psl: 0, hash, key }
  let list_node : SListNode[K] = { prev: None, next: None }
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

/// Check if the hash set contains a key.
pub fn contains[K : Hash + Eq](self : Set[K], key : K) -> Bool {
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

/// Remove a key from hash set.
pub fn remove[K : Hash + Eq](self : Set[K], key : K) -> Unit {
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

fn add_entry_to_tail[K : Eq](self : Set[K], entry : SEntry[K]) -> Unit {
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

fn remove_entry[K : Eq](self : Set[K], entry : SEntry[K]) -> Unit {
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
    match node.prev {
      Some(prev) => self.list[prev.idx].next = node.next
      None => ()
    }
    match node.next {
      Some(next) => self.list[next.idx].prev = node.prev
      None => ()
    }
  }
  node.prev = None
  node.next = None
}

fn shift_back[K : Hash](self : Set[K], start_index : Int) -> Unit {
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

fn grow[K : Hash + Eq](self : Set[K]) -> Unit {
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
    Some({ idx, key, .. }) => {
      self.insert(key)
      continue old_list[idx].next
    }
    None => break
  }
}

// Utils

fn debug_entries[K : Show](self : Set[K]) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < self.entries.length(); i = i + 1 {
    if i > 0 {
      buf.write_char(',')
    }
    match self.entries[i] {
      None => buf.write_char('_')
      Some({ psl, key, .. }) => buf.write_string("(\{psl},\{key})")
    }
  }
  buf.to_string()
}

pub impl[K : Show] Show for Set[K] with output(self, logger) {
  logger.write_string("{")
  loop 0, self.head {
    _, None => logger.write_string("}")
    i, Some({ key, idx, .. }) => {
      if i > 0 {
        logger.write_string(", ")
      }
      logger.write_object(key)
      continue i + 1, self.list[idx].next
    }
  }
}

pub fn to_string[K : Show](self : Set[K]) -> String {
  Show::to_string(self)
}

/// Get the number of keys in the set.
pub fn size[K](self : Set[K]) -> Int {
  self.size
}

/// Get the capacity of the set.
pub fn capacity[K](self : Set[K]) -> Int {
  self.capacity
}

/// Check if the hash set is empty.
pub fn is_empty[K](self : Set[K]) -> Bool {
  self.size == 0
}

/// Iterate over all keys of the set in the order of insertion.
pub fn each[K](self : Set[K], f : (K) -> Unit) -> Unit {
  loop self.head {
    Some({ key, idx, .. }) => {
      f(key)
      continue self.list[idx].next
    }
    None => break
  }
}

/// Iterate over all keys of the set in the order of insertion, with index.
pub fn eachi[K](self : Set[K], f : (Int, K) -> Unit) -> Unit {
  loop 0, self.head {
    i, Some({ key, idx, .. }) => {
      f(i, key)
      continue i + 1, self.list[idx].next
    }
    _, None => break
  }
}

/// Clears the set, removing all keys. Keeps the allocated space.
pub fn clear[K](self : Set[K]) -> Unit {
  self.entries.fill(None)
  self.size = 0
  self.head = None
  self.tail = None
}

/// Returns the iterator of the hash set, provide elements in the order of insertion.
pub fn iter[K](self : Set[K]) -> Iter[K] {
  Iter::new(
    fn(yield) {
      loop self.head {
        Some({ key, idx, .. }) => {
          if yield(key) == IterEnd {
            break IterEnd
          }
          continue self.list[idx].next
        }
        None => break IterContinue
      }
    },
  )
}

/// Converts the hash set to an array.
pub fn to_array[K](self : Set[K]) -> Array[K] {
  let arr = Array::new(capacity=self.size)
  loop self.head {
    Some({ key, idx, .. }) => {
      arr.push(key)
      continue self.list[idx].next
    }
    None => break
  }
  arr
}

pub fn op_equal[K : Eq](self : Set[K], that : Set[K]) -> Bool {
  if self.size != that.size {
    return false
  }
  loop self.head, that.head {
    None, None => true
    Some({ key: k1, idx: i1, .. }), Some({ key: k2, idx: i2, .. }) => {
      if k1 != k2 {
        return false
      }
      continue self.list[i1].next, that.list[i2].next
    }
    _, _ => false
  }
}

pub fn Set::of[K : Hash + Eq](arr : FixedArray[K]) -> Set[K] {
  let length = arr.length()
  let m = Set::new(capacity=length)
  // arr.iter(fn(e) { m.set(e.0, e.1) })
  for i = 0; i < length; i = i + 1 {
    let e = arr[i]
    m.insert(e)
  }
  m
}

pub fn Set::from_iter[K : Hash + Eq](iter : Iter[K]) -> Set[K] {
  let m = Set::new()
  iter.each(fn(e) { m.insert(e) })
  m
}

pub fn difference[K : Hash + Eq](self : Set[K], other : Set[K]) -> Set[K] {
  let m = Set::new()
  self.each(fn(k) { if not(other.contains(k)) { m.insert(k) } })
  m
}

pub fn symmetric_difference[K : Hash + Eq](
  self : Set[K],
  other : Set[K]
) -> Set[K] {
  let m = Set::new()
  self.each(fn(k) { if not(other.contains(k)) { m.insert(k) } })
  other.each(fn(k) { if not(self.contains(k)) { m.insert(k) } })
  m
}

pub fn union[K : Hash + Eq](self : Set[K], other : Set[K]) -> Set[K] {
  let m = Set::new()
  self.each(fn(k) { m.insert(k) })
  other.each(fn(k) { m.insert(k) })
  m
}

pub fn intersection[K : Hash + Eq](self : Set[K], other : Set[K]) -> Set[K] {
  let m = Set::new()
  self.each(fn(k) { if other.contains(k) { m.insert(k) } })
  m
}
