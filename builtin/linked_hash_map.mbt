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
priv struct Entry[K, V] {
  mut idx : Int
  mut psl : Int
  hash : Int
  key : K
  mut value : V
} derive(Debug)

fn op_equal[K : Eq, V](self : Entry[K, V], other : Entry[K, V]) -> Bool {
  self.hash == other.hash && self.key == other.key
}

priv struct ListNode[K, V] {
  mut prev : Entry[K, V]?
  mut next : Entry[K, V]?
}

/// Mutable linked hash map that maintains the order of insertion, not thread safe. 
///  
/// # Example
/// 
/// ```
/// let map = { 3: "three", 8 :  "eight", 1 :  "one"}
/// println(map.get(2)) // output: None
/// println(map.get(3)) // output: Some("three")
/// map.set(3, "updated")
/// println(map.get(3)) // output: Some("updated")
/// map.iter(fn(k, v) { println("\(k)-\(v)") })
/// // output:
/// // 3-three
/// // 8-eight
/// // 1-one
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
  inspect(power_2_above(1, 15), content="16")?
  inspect(power_2_above(1, 16), content="16")?
  inspect(power_2_above(1, 17), content="32")?
  inspect(power_2_above(1, 32), content="32")?
  inspect(power_2_above(128, 33), content="128")?
  inspect(power_2_above(1, 2147483647), content="1073741824")?
}

/// Create a hash map.
/// The capacity of the map will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
pub fn Map::new[K, V](~capacity : Int = 8) -> Map[K, V] {
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

/// Create a hash map from array.
pub fn Map::from_array[K : Hash + Eq, V](arr : Array[(K, V)]) -> Map[K, V] {
  let m = Map::new(capacity=arr.length())
  arr.iter(fn(e) { m.set(e.0, e.1) })
  m
}

/// Set a key-value pair into the hash map.
/// @alert unsafe "Panic if the hash map is full."
pub fn set[K : Hash + Eq, V](self : Map[K, V], key : K, value : V) -> Unit {
  if self.size >= self.growAt {
    self.grow()
  }
  let hash = key.hash()
  let insert_entry = { idx: -1, psl: 0, hash, key, value }
  loop
    0,
    hash.land(self.capacity_mask),
    insert_entry,
    { prev: None, next: None } {
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
              (idx + 1).land(self.capacity_mask),
              curr_entry,
              curr_node
          } else {
            entry.psl += 1
            continue i + 1, (idx + 1).land(self.capacity_mask), entry, node
          }
        }
      }
  }
}

pub fn op_set[K : Hash + Eq, V](self : Map[K, V], key : K, value : V) -> Unit {
  self.set(key, value)
}

/// Get the value associated with a key.
pub fn get[K : Hash + Eq, V](self : Map[K, V], key : K) -> V? {
  let hash = key.hash()
  for i = 0, idx = hash.land(self.capacity_mask) {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          break Some(entry.value)
        }
        if i > entry.psl {
          break None
        }
        continue i + 1, (idx + 1).land(self.capacity_mask)
      }
      None => break None
    }
  }
}

pub fn op_get[K : Hash + Eq, V](self : Map[K, V], key : K) -> V? {
  self.get(key)
}

/// Get the value associated with a key, 
/// returns the provided default value if the key does not exist.
pub fn get_or_default[K : Hash + Eq, V](
  self : Map[K, V],
  key : K,
  default : V
) -> V {
  match self.get(key) {
    Some(v) => v
    None => default
  }
}

/// Check if the hash map contains a key.
pub fn contains[K : Hash + Eq, V](self : Map[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

/// Remove a key-value pair from hash map.
pub fn remove[K : Hash + Eq, V](self : Map[K, V], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash.land(self.capacity_mask) {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          self.entries[idx] = None
          self.shift_back(idx)
          self.size -= 1
          self.remove_entry(entry)
          break
        }
        if i > entry.psl {
          break
        }
        continue i + 1, (idx + 1).land(self.capacity_mask)
      }
      None => break
    }
  }
}

fn add_entry_to_tail[K : Eq, V](self : Map[K, V], entry : Entry[K, V]) -> Unit {
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

fn remove_entry[K : Eq, V](self : Map[K, V], entry : Entry[K, V]) -> Unit {
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

fn shift_back[K : Hash, V](self : Map[K, V], start_index : Int) -> Unit {
  for prev = start_index, curr = (start_index + 1).land(self.capacity_mask) {
    match self.entries[curr] {
      Some(entry) => {
        if entry.psl == 0 {
          break
        }
        entry.psl -= 1
        entry.idx = prev
        self.entries[prev] = Some(entry)
        self.entries[curr] = None
        continue curr, (curr + 1).land(self.capacity_mask)
      }
      None => break
    }
  }
}

fn grow[K : Hash + Eq, V](self : Map[K, V]) -> Unit {
  let old_head = self.head
  let old_list = self.list
  let new_capacity = self.capacity.lsl(1)
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

fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

// Utils

fn debug_entries[K : Show, V : Show](self : Map[K, V]) -> String {
  let buf = Buffer::new()
  for i = 0; i < self.entries.length(); i = i + 1 {
    if i > 0 {
      buf.write_char(',')
    }
    match self.entries[i] {
      None => buf.write_char('_')
      Some({ psl, key, value, .. }) =>
        buf.write_string("(\(psl),\(key),\(value))")
    }
  }
  buf.to_string()
}

pub fn to_string[K : Show, V : Show](self : Map[K, V]) -> String {
  if self.size == 0 {
    return "{}"
  }
  loop 0, self.head, "{" {
    _, None, _ as acc => return acc + "}"
    i, Some({ key, value, idx, .. }), acc => {
      let nxt = self.list[idx].next
      if i > 0 {
        // To remove the last comma
        continue i + 1, nxt, acc + ", \(key):\(value)"
      }
      continue i + 1, nxt, acc + "\(key):\(value)"
    }
  }
}

/// Get the number of key-value pairs in the map.
pub fn size[K, V](self : Map[K, V]) -> Int {
  self.size
}

/// Get the capacity of the map.
pub fn capacity[K, V](self : Map[K, V]) -> Int {
  self.capacity
}

/// Check if the hash map is empty.
pub fn is_empty[K, V](self : Map[K, V]) -> Bool {
  self.size == 0
}

/// Iterate over all key-value pairs of the map in the order of insertion.
pub fn iter[K, V](self : Map[K, V], f : (K, V) -> Unit) -> Unit {
  loop self.head {
    Some({ key, value, idx, .. }) => {
      f(key, value)
      continue self.list[idx].next
    }
    None => break
  }
}

/// Iterate over all key-value pairs of the map in the order of insertion, with index.
pub fn iteri[K, V](self : Map[K, V], f : (Int, K, V) -> Unit) -> Unit {
  loop 0, self.head {
    i, Some({ key, value, idx, .. }) => {
      f(i, key, value)
      continue i + 1, self.list[idx].next
    }
    _, None => break
  }
}

/// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn clear[K, V](self : Map[K, V]) -> Unit {
  self.entries.fill(None)
  self.size = 0
  self.head = None
  self.tail = None
}

/// Returns the iterator of the hash map, provide elements in the order of insertion.
pub fn as_iter[K, V](self : Map[K, V]) -> Iter[(K, V)] {
  Iter::_unstable_internal_make(
    fn(yield) {
      loop self.head {
        Some({ key, value, idx, .. }) => {
          if yield((key, value)) == IterEnd {
            break IterEnd
          }
          continue self.list[idx].next
        }
        None => break IterContinue
      }
    },
  )
}

/// Converts the hash map to an array.
pub fn to_array[K, V](self : Map[K, V]) -> Array[(K, V)] {
  let arr = Array::new(capacity=self.size)
  loop self.head {
    Some({ key, value, idx, .. }) => {
      arr.push((key, value))
      continue self.list[idx].next
    }
    None => break
  }
  arr
}

pub fn op_equal[K : Eq, V : Eq](self : Map[K, V], that : Map[K, V]) -> Bool {
  if self.size != that.size {
    return false
  }
  loop self.head, that.head {
    None, None => true
    Some({ key: k1, value: v1, idx: i1, .. }),
    Some({ key: k2, value: v2, idx: i2, .. }) => {
      if k1 != k2 || v1 != v2 {
        return false
      }
      continue self.list[i1].next, that.list[i2].next
    }
    _, _ => false
  }
}
