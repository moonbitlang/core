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

enum Entry[K, V] {
  Empty
  // (Probe Sequence Length, Hash, Key, Value)
  Valid(Int, Int, K, V)
} derive(Debug)

/// A mutable hash map implements with Robin Hood hashing.
/// 
/// reference:
/// - <https://programming.guide/robin-hood-hashing.html>
/// - <https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf>

/// Mutable hash map, not thread safe. 
///  
/// # Example
/// 
/// ```
/// let map = HashMap::[(3, "three"), (8, "eight"), (1, "one")]
/// println(map.get(2)) // output: None
/// println(map.get(3)) // output: Some("three")
/// map.set(3, "updated")
/// println(map.get(3)) // output: Some("updated")
/// ```
struct HashMap[K, V] {
  mut entries : Array[Entry[K, V]]
  mut size : Int // active key-value pairs count
  mut capacity : Int // current capacity 
  mut growAt : Int // threshold that triggers grow
  hasher : Option[(K) -> Int] // custom hasher
}

/// Create new hash map.
pub fn HashMap::new[K, V](
  ~capacity : Int = default_init_capacity,
  ~hasher : Option[(K) -> Int] = None
) -> HashMap[K, V] {
  if capacity != 0 && not(is_power_of_two(capacity)) {
    abort("The capacity is not a zero or a power of 2.")
  }
  {
    size: 0,
    capacity,
    growAt: calc_grow_threshold(capacity),
    hasher,
    entries: @array.new(capacity, fn() { Empty }),
  }
}

fn is_power_of_two(n : Int) -> Bool {
  n > 0 && n.land(n - 1) == 0
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
          self.entries[idx] = Entry::Valid(psl, hash, key, value)
          self.size += 1
          break
        }
        Valid(d, h, k, v) => {
          if h == hash && k == key {
            self.entries[idx] = Valid(d, h, k, value)
            break
          }
          if psl > d {
            self.entries[idx] = Entry::Valid(psl, hash, key, value)
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
  for distance = 0, idx = self.index(hash);
      distance < self.capacity;
      distance = distance + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Valid(d, h, k, v) => {
        if h == hash && k == key {
          return Some(v)
        }
        if distance > d {
          return None
        }
      }
      Empty => return None
    }
  }
  None
}

pub fn op_get[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Option[V] {
  self.get(key)
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
  for distance = 0, idx = self.index(hash);
      distance < self.capacity;
      distance = distance + 1, idx = self.next_index(idx) {
    match self.entries[idx] {
      Valid(d, h, k, _) => {
        if h == hash && k == key {
          self.entries[idx] = Empty
          self.shift_back(idx)
          self.size -= 1
          break
        }
        if distance > d {
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
  let mut idx = 0
  for i = 0; i < self.capacity; i = i + 1 {
    match self.entries[i] {
      Valid(_, _, k, v) => {
        f(idx, k, v)
        idx += 1
      }
      _ => ()
    }
  }
}

// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn clear[K, V](self : HashMap[K, V]) -> Unit {
  for i = 0; i < self.capacity; i = i + 1 {
    self.entries[i] = Empty
  }
  self.size = 0
}

fn shift_back[K : Hash, V](self : HashMap[K, V], start_index : Int) -> Unit {
  for i = 0, prev = start_index, curr = self.next_index(start_index);
      i < self.entries.length();
      i = i + 1, prev = curr, curr = self.next_index(curr) {
    match self.entries[curr] {
      Valid(d, h, k, v) => {
        if d == 0 {
          break
        }
        self.entries[prev] = Valid(d - 1, h, k, v)
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
      Valid(_, _, k, v) => self.set(k, v)
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
  let mut s = ""
  for i = 0; i < self.entries.length(); i = i + 1 {
    if i > 0 {
      s += ","
    }
    match self.entries[i] {
      Empty => s += "_"
      Valid(d, _h, k, v) => s += "(\(d),\(k),\(v))"
    }
  }
  s
}

test "new" {
  let m : HashMap[Int, Int] = HashMap::new()
  @assertion.assert_eq(m.capacity, default_init_capacity)?
  @assertion.assert_eq(m.size, 0)?
}

test "set" {
  let m : HashMap[String, Int] = HashMap::new(
    ~hasher=Some(fn(k) { k.length() }),
    ~capacity=16,
  )
  m.set("a", 1)
  m.set("b", 1)
  m.set("bc", 2)
  m.set("abc", 3)
  m.set("cd", 2)
  m.set("c", 1)
  m.set("d", 1)
  @assertion.assert_eq(m.size, 7)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )?
}

test "get" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
  @assertion.assert_eq(m.get("d"), None)?
}

test "op_set" {
  let m : HashMap[String, Int] = HashMap::new()
  m["a"] = 1
  m["b"] = 2
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
}

test "op_get" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m["a"], Some(1))?
  @assertion.assert_eq(m["b"], Some(2))?
  @assertion.assert_eq(m["c"], None)?
}

test "set_update" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m.get("a"), Some(1))?
  m.set("a", 2)
  @assertion.assert_eq(m.get("a"), Some(2))?
}

test "contains" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  @assertion.assert_eq(m.contains("a"), true)?
  @assertion.assert_eq(m.contains("b"), false)?
}

test "from_array" {
  let m = HashMap::[("a", 1), ("b", 2), ("c", 3)]
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
}

test "remove" {
  let m : HashMap[String, Int] = HashMap::new(
    ~hasher=Some(fn(k) { k.length() }),
    ~capacity=16,
  )
  m.set("a", 1)
  m.set("ab", 2)
  m.set("bc", 2)
  m.set("cd", 2)
  m.set("abc", 3)
  m.set("abcdef", 6)
  m.remove("ab")
  @assertion.assert_eq(m.size(), 5)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_,_,_,_,_,_,_,_,_",
  )?
}

test "remove_unexist_key" {
  let m : HashMap[String, Int] = HashMap::new(
    ~hasher=Some(fn(k) { k.length() }),
  )
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_",
  )?
}

test "size" {
  let m : HashMap[String, Int] = HashMap::new()
  @assertion.assert_eq(m.size(), 0)?
  m.set("a", 1)
  @assertion.assert_eq(m.size(), 1)?
}

test "capacity" {
  let m : HashMap[String, Int] = HashMap::new(~capacity=128)
  @assertion.assert_eq(m.capacity(), 128)?
}

test "is_empty" {
  let m : HashMap[String, Int] = HashMap::new()
  @assertion.assert_eq(m.is_empty(), true)?
  m.set("a", 1)
  @assertion.assert_eq(m.is_empty(), false)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
}

test "iter" {
  let m : HashMap[String, Int] = HashMap::[("a", 1), ("b", 2), ("c", 3)]
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : HashMap[String, Int] = HashMap::[("a", 1), ("b", 2), ("c", 3)]
  let mut sum = 0
  let mut s = ""
  m.iteri(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  @assertion.assert_eq(s, "012")?
  @assertion.assert_eq(sum, 6)?
}

test "clear" {
  let m : HashMap[String, Int] = HashMap::[("a", 1), ("b", 2), ("c", 3)]
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], Empty)?
  }
}

test "grow" {
  let m : HashMap[String, Int] = HashMap::new(
    ~hasher=Some(fn(k) { k.length() }),
  )
  m.set("C", 1)
  m.set("Go", 2)
  m.set("C++", 3)
  m.set("Java", 4)
  m.set("Scala", 5)
  m.set("Julia", 5)
  @assertion.assert_eq(m.size, 6)?
  @assertion.assert_eq(m.capacity, 8)?
  m.set("Cobol", 5)
  @assertion.assert_eq(m.size, 7)?
  @assertion.assert_eq(m.capacity, 16)?
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  @assertion.assert_eq(m.size, 10)?
  @assertion.assert_eq(m.capacity, 16)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_",
  )?
}

test "zero_capacity_grow" {
  let m : HashMap[String, Int] = HashMap::new(~capacity=0)
  @assertion.assert_eq(m.capacity(), 0)?
  m.set("a", 1)
  @assertion.assert_eq(m.size(), 1)?
  @assertion.assert_eq(m.capacity(), 8)?
}
