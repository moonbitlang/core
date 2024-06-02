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
  mut prev : Option[Entry[K, V]]
  mut next : Option[Entry[K, V]]
}

/// Mutable linked hash map that maintains the order of insertion, not thread safe. 
///  
/// # Example
/// 
/// ```
/// let map = HashMap::[(3, "three"), (8, "eight"), (1, "one")]
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
struct LinkedHashMap[K, V] {
  mut entries : FixedArray[Option[Entry[K, V]]]
  mut list : FixedArray[ListNode[K, V]] // list of (prev, next)
  mut size : Int // active key-value pairs count
  mut capacity : Int // current capacity 
  mut growAt : Int // threshold that triggers grow
  mut head : Option[Entry[K, V]] // head of linked list
  mut tail : Option[Entry[K, V]] // tail of linked list
}

// Implementations

fn power_2_above(x : Int, n : Int) -> Int {
  let n = n.to_int64()
  for i = x.to_int64() {
    if i > 2147483647L {
      break 2147483647
    }
    if i >= n {
      break i.to_int()
    }
    continue i.lsl(1)
  }
}

test "power_2_above" {
  inspect(power_2_above(1, 15), content="16")?
  inspect(power_2_above(1, 16), content="16")?
  inspect(power_2_above(1, 17), content="32")?
  inspect(power_2_above(1, 32), content="32")?
  inspect(power_2_above(128, 33), content="128")?
  inspect(power_2_above(1, 2147483647), content="2147483647")?
}

/// Create a hash map.
pub fn LinkedHashMap::new[K, V](~capacity : Int = 8) -> LinkedHashMap[K, V] {
  let capacity = power_2_above(8, capacity)
  {
    size: 0,
    capacity,
    growAt: calc_grow_threshold(capacity),
    entries: FixedArray::make(capacity, None),
    list: FixedArray::make(capacity, { prev: None, next: None }),
    head: None,
    tail: None,
  }
}

/// Create a hash map from array.
pub fn LinkedHashMap::from_array[K : Hash + Eq, V](
  arr : Array[(K, V)]
) -> LinkedHashMap[K, V] {
  let m = LinkedHashMap::new(capacity=arr.length())
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
  if self.size >= self.growAt {
    self.grow()
  }
  let hash = key.hash()
  let insert_entry = { idx: -1, psl: 0, hash, key, value }
  loop
    0,
    hash.land(self.capacity - 1),
    insert_entry,
    { prev: None, next: None } {
    i, idx, entry, node => {
      if i == self.capacity {
        panic()
      }
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
              (idx + 1).land(self.capacity - 1),
              curr_entry,
              curr_node
          } else {
            entry.psl += 1
            continue i + 1, (idx + 1).land(self.capacity - 1), entry, node
          }
        }
      }
    }
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
  let hash = key.hash()
  for i = 0, idx = hash.land(self.capacity - 1) {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          break Some(entry.value)
        }
        if i > entry.psl {
          break None
        }
        continue i + 1, (idx + 1).land(self.capacity - 1)
      }
      None => break None
    }
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
  let hash = key.hash()
  for i = 0, idx = hash.land(self.capacity - 1) {
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
        continue i + 1, (idx + 1).land(self.capacity - 1)
      }
      None => break
    }
  }
}

fn add_entry_to_tail[K : Eq, V](
  self : LinkedHashMap[K, V],
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

fn remove_entry[K : Eq, V](
  self : LinkedHashMap[K, V],
  entry : Entry[K, V]
) -> Unit {
  let node = self.list[entry.idx]
  if self.is_empty() {
    self.head = None
    self.tail = None
  } else {
    match self.head {
      Some(head) => if head == entry { self.head = node.next }
      None => ()
    }
    match self.tail {
      Some(tail) => if tail == entry { self.tail = node.prev }
      None => ()
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

fn shift_back[K : Hash, V](
  self : LinkedHashMap[K, V],
  start_index : Int
) -> Unit {
  for prev = start_index, curr = (start_index + 1).land(self.capacity - 1) {
    match self.entries[curr] {
      Some(entry) => {
        if entry.psl == 0 {
          break
        }
        entry.psl -= 1
        entry.idx = prev
        self.entries[prev] = Some(entry)
        self.entries[curr] = None
        continue curr, (curr + 1).land(self.capacity - 1)
      }
      None => break
    }
  }
}

fn grow[K : Hash + Eq, V](self : LinkedHashMap[K, V]) -> Unit {
  let old_head = self.head
  let old_list = self.list
  let new_capacity = self.capacity.lsl(1)
  self.entries = FixedArray::make(new_capacity, None)
  self.list = FixedArray::make(new_capacity, { prev: None, next: None })
  self.capacity = new_capacity
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

fn debug_entries[K : Show, V : Show](self : LinkedHashMap[K, V]) -> String {
  let buf = Buffer::make(0)
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

fn debug_linked_list[K : Show, V : Show](self : LinkedHashMap[K, V]) -> String {
  let buf = Buffer::make(0)
  loop self.head {
    Some({ idx, key, value, hash, .. }) => {
      buf.write_char('(')
      buf.write_string("\(hash),\(key),\(value)")
      buf.write_string(",prev:")
      let node = self.list[idx]
      match node.prev {
        Some({ hash, .. }) => buf.write_string(hash.to_string())
        None => buf.write_char('_')
      }
      buf.write_string(",next:")
      match node.next {
        Some({ hash, .. }) => buf.write_string(hash.to_string())
        None => buf.write_char('_')
      }
      buf.write_char(')')
      buf.write_char('\n')
      continue node.next
    }
    None => buf.write_string("end")
  }
  buf.to_string()
}

/// Get the number of key-value pairs in the map.
pub fn size[K, V](self : LinkedHashMap[K, V]) -> Int {
  self.size
}

/// Get the capacity of the map.
pub fn capacity[K, V](self : LinkedHashMap[K, V]) -> Int {
  self.capacity
}

/// Check if the hash map is empty.
pub fn is_empty[K, V](self : LinkedHashMap[K, V]) -> Bool {
  self.size == 0
}

/// Iterate over all key-value pairs of the map in the order of insertion.
pub fn iter[K, V](self : LinkedHashMap[K, V], f : (K, V) -> Unit) -> Unit {
  loop self.head {
    Some({ key, value, idx, .. }) => {
      f(key, value)
      continue self.list[idx].next
    }
    None => break
  }
}

/// Iterate over all key-value pairs of the map in the order of insertion, with index.
pub fn iteri[K, V](self : LinkedHashMap[K, V], f : (Int, K, V) -> Unit) -> Unit {
  loop 0, self.head {
    i, Some({ key, value, idx, .. }) => {
      f(i, key, value)
      continue i + 1, self.list[idx].next
    }
    _, None => break
  }
}

/// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn clear[K, V](self : LinkedHashMap[K, V]) -> Unit {
  self.entries.fill(None)
  self.size = 0
  self.head = None
  self.tail = None
}

/// Returns the iterator of the hash map, provide elements in the order of insertion.
pub fn as_iter[K, V](self : LinkedHashMap[K, V]) -> Iter[(K, V)] {
  Iter::_unstable_internal_make(
    fn(yield) {
      loop self.head {
        Some({ key, value, idx, .. }) => {
          if yield((key, value)).not() {
            break false
          }
          continue self.list[idx].next
        }
        None => break true
      }
    },
  )
}

/// Converts the hash map to an array.
pub fn to_array[K, V](self : LinkedHashMap[K, V]) -> Array[(K, V)] {
  let arr = []
  loop self.head {
    Some({ key, value, idx, .. }) => {
      arr.push((key, value))
      continue self.list[idx].next
    }
    None => break
  }
  arr
}
