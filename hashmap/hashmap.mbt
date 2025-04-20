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
/// Creates a new empty hash map with the specified initial capacity. The actual
/// capacity will be rounded up to the next power of 2 that is greater than or
/// equal to the requested capacity, with a minimum of 8.
///
/// Parameters:
///
/// * `capacity` : The desired minimum capacity of the hash map. Must be a
/// non-negative integer. Defaults to 8 if not specified.
///
/// Returns a new empty hash map of type `T[K, V]`, where `K` is the key type and
/// `V` is the value type.
///
/// Example:
///
/// ```moonbit
/// test "new" {
///   let map : @hashmap.T[String, Int] = @hashmap.new(capacity=16)
///   inspect!(map.capacity(), content="16")
///   inspect!(map.is_empty(), content="true")
/// }
/// ```
pub fn new[K, V](capacity~ : Int = 8) -> T[K, V] {
  let capacity = power_2_above(8, capacity)
  {
    size: 0,
    capacity,
    entries: FixedArray::make(capacity, None),
    capacity_mask: capacity - 1,
  }
}

///|
/// Creates a new hash map from an array of key-value pairs. Pairs with duplicate
/// keys will keep the latest value, overwriting the previous ones.
///
/// Parameters:
///
/// * `arr` : An array of key-value tuples. Each tuple contains a hashable and
/// comparable key of type `K`, and an associated value of type `V`.
///
/// Returns a new hash map containing all the key-value pairs from the input
/// array.
///
/// Example:
///
/// ```moonbit
/// test "from_array" {
///   let arr = [(1, "one"), (2, "two"), (1, "ONE")]
///   let map = @hashmap.from_array(arr)
///   inspect!(map.get(1), content="Some(\"ONE\")")
///   inspect!(map.get(2), content="Some(\"two\")")
/// }
/// ```
pub fn from_array[K : Hash + Eq, V](arr : Array[(K, V)]) -> T[K, V] {
  let m = new(capacity=arr.length())
  arr.each(fn(e) { m.set(e.0, e.1) })
  m
}

///|
/// Sets a key-value pair into the hash map. If the key already exists, updates
/// its value. If the hash map is near full capacity (>= 50%), automatically
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
/// ```moonbit
/// test "set" {
///   let map : @hashmap.T[String, Int] = @hashmap.new()
///   map.set("key", 42)
///   inspect!(map.get("key"), content="Some(42)")
///   map.set("key", 24) // update existing key
///   inspect!(map.get("key"), content="Some(24)")
/// }
/// ```
///
/// @alert unsafe "Panic if the hash map is full."
pub fn set[K : Hash + Eq, V](self : T[K, V], key : K, value : V) -> Unit {
  self.set_with_hash(key, value, key.hash())
}

///|
fn set_with_hash[K : Eq, V](
  self : T[K, V],
  key : K,
  value : V,
  hash : Int
) -> Unit {
  if self.size >= self.capacity / 2 {
    self.grow()
  }
  for idx = hash & self.capacity_mask, entry = { psl: 0, hash, key, value } {
    match self.entries[idx] {
      None => {
        self.entries[idx] = Some(entry)
        self.size += 1
        break
      }
      Some(curr_entry) => {
        if curr_entry.hash == entry.hash && curr_entry.key == entry.key {
          curr_entry.value = entry.value
          break
        }
        let curr_entry = if entry.psl > curr_entry.psl {
          self.entries[idx] = Some(entry)
          curr_entry
        } else {
          entry
        }
        curr_entry.psl += 1
        continue (idx + 1) & self.capacity_mask, curr_entry
      }
    }
  }
}

///|
/// Sets the value associated with a key in the hash map. If the key already
/// exists, updates its value; otherwise, adds a new key-value pair. This
/// function is automatically called when using the index assignment syntax
/// `map[key] = value`.
///
/// Parameters:
///
/// * `map` : The hash map to modify.
/// * `key` : The key to associate with the value. Must implement `Hash` and `Eq`
/// traits.
/// * `value` : The value to associate with the key.
///
/// Example:
///
/// ```moonbit
/// test "op_set" {
///   let map : @hashmap.T[String, Int] = @hashmap.new()
///   map["key"] = 42
///   inspect!(map.get("key"), content="Some(42)")
/// }
/// ```
pub fn op_set[K : Hash + Eq, V](self : T[K, V], key : K, value : V) -> Unit {
  self.set(key, value)
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
/// ```moonbit
/// test "get" {
///   let map = @hashmap.of([("key", 42)])
///   inspect!(map.get("key"), content="Some(42)")
///   inspect!(map.get("nonexistent"), content="None")
/// }
/// ```
pub fn get[K : Hash + Eq, V](self : T[K, V], key : K) -> V? {
  // self.get_with_hash(key, key.hash())
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
fn get_with_hash[K : Hash + Eq, V](self : T[K, V], key : K, hash : Int) -> V? {
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
/// Retrieves a value from the hash map using the index operator syntax. This
/// method is automatically called when using the square bracket notation
/// `map[key]`.
///
/// Parameters:
///
/// * `map` : The hash map to retrieve the value from.
/// * `key` : The key to look up in the map. Must implement both `Hash` and `Eq`
/// traits.
///
/// Returns `Some(value)` if the key exists in the map, `None` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "op_get" {
///   let map = @hashmap.of([("key", 42)])
///   inspect!(map["key"], content="Some(42)")
///   inspect!(map["nonexistent"], content="None")
/// }
/// ```
pub fn op_get[K : Hash + Eq, V](self : T[K, V], key : K) -> V? {
  self.get(key)
}

///|
/// Gets the value associated with the given key. If the key doesn't exist in the
/// map, initializes it with the result of calling the provided initialization
/// function.
///
/// Parameters:
///
/// * `self` : The hash map.
/// * `key` : The key to look up in the map.
/// * `init` : A function that takes no arguments and returns a value to be
/// associated with the key if it doesn't exist.
///
/// Returns the value associated with the key, either existing or newly
/// initialized.
///
/// Example:
///
/// ```moonbit
/// test "get_or_init" {
///   let map : @hashmap.T[String, Int] = @hashmap.new()
///   let value = map.get_or_init("key", fn() { 42 })
///   inspect!(value, content="42")
///   inspect!(map.get("key"), content="Some(42)")
/// }
/// ```
/// TODO: improve performance to avoid calling `get_with_hash` twice
pub fn get_or_init[K : Hash + Eq, V](
  self : T[K, V],
  key : K,
  init : () -> V
) -> V {
  let hash = key.hash()
  match self.get_with_hash(key, hash) {
    Some(v) => v
    None => {
      let v = init()
      self.set_with_hash(key, v, hash)
      v
    }
  }
}

///|
/// Gets the value associated with a given key from the hash map. If the key
/// doesn't exist, returns the provided default value instead.
///
/// Parameters:
///
/// * `map` : The hash map to retrieve the value from.
/// * `key` : The key to look up in the map.
/// * `default` : The value to return if the key is not found in the map.
///
/// Returns the value associated with the key if it exists, otherwise returns the
/// default value.
///
/// Example:
///
/// ```moonbit
/// test "get_or_default" {
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   inspect!(map.get_or_default("a", 0), content="1")
///   inspect!(map.get_or_default("c", 0), content="0")
/// }
/// ```
pub fn get_or_default[K : Hash + Eq, V](
  self : T[K, V],
  key : K,
  default : V
) -> V {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { break default }
    if entry.hash == hash && entry.key == key {
      break entry.value
    }
    if i > entry.psl {
      break default
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
/// Checks if a key exists in the hash map.
///
/// Parameters:
///
/// * `self` : The hash map to search in.
/// * `key` : The key to look for in the hash map.
///
/// Returns `true` if the key exists in the hash map, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "contains" {
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   inspect!(map.contains("a"), content="true")
///   inspect!(map.contains("c"), content="false")
/// }
/// ```
pub fn contains[K : Hash + Eq, V](self : T[K, V], key : K) -> Bool {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { return false }
    if entry.hash == hash && entry.key == key {
      return true
    }
    if i > entry.psl {
      return false
    }
    continue i + 1, (idx + 1) & self.capacity_mask
  }
}

///|
pub fn contains_kv[K : Hash + Eq, V : Eq](
  self : T[K, V],
  key : K,
  value : V
) -> Bool {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry) else { return false }
    if entry.hash == hash && entry.key == key && entry.value == value {
      return true
    }
    if i > entry.psl {
      return false
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
/// ```moonbit
/// test "remove" {
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   map.remove("a")
///   inspect!(map.get("a"), content="None")
///   inspect!(map.size(), content="1")
/// }
/// ```
pub fn remove[K : Hash + Eq, V](self : T[K, V], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          self.entries[idx] = None
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
fn shift_back[K : Hash, V](self : T[K, V], start_index : Int) -> Unit {
  for prev = start_index, curr = (start_index + 1) & self.capacity_mask {
    match self.entries[curr] {
      Some({ psl, hash, key, value }) => {
        if psl == 0 {
          break
        }
        self.entries[prev] = Some({ psl: psl - 1, hash, key, value })
        self.entries[curr] = None
        continue curr, (curr + 1) & self.capacity_mask
      }
      None => break
    }
  }
}

///|
fn grow[K : Eq, V](self : T[K, V]) -> Unit {
  let old_entries = self.entries
  let new_capacity = self.capacity << 1
  self.entries = FixedArray::make(new_capacity, None)
  self.capacity = new_capacity
  self.capacity_mask = new_capacity - 1
  self.size = 0
  for i in 0..<old_entries.length() {
    if old_entries[i] is Some({ key, value, hash, .. }) {
      self.set_with_hash(key, value, hash)
    }
  }
}

///|
/// Creates a new hash map from a fixed array of key-value pairs.
///
/// Parameters:
///
/// * `pairs` : A fixed array of tuples, where each tuple contains a key of type
/// `K` and a value of type `V`. The key type must implement both `Eq` and `Hash`
/// traits.
///
/// Returns a new hash map containing all the key-value pairs from the input
/// array.
///
/// Example:
///
/// ```moonbit
/// test "of" {
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   inspect!(map.get(1), content="Some(\"one\")")
///   inspect!(map.get(2), content="Some(\"two\")")
/// }
/// ```
pub fn of[K : Eq + Hash, V](arr : FixedArray[(K, V)]) -> T[K, V] {
  let m = new(capacity=arr.length())
  arr.each(fn(e) { m.set(e.0, e.1) })
  m
}

///|
test "of" {
  let m = of([(1, 2), (3, 4)])
  inspect!(m.get(1), content="Some(2)")
  inspect!(m.get(3), content="Some(4)")
}

///|
/// Implements random generation of hashmaps for property-based testing through
/// the `Arbitrary` trait.
///
/// Parameters:
///
/// * `size` : The size hint for generating random key-value pairs. Larger values
/// typically result in larger hashmaps.
/// * `random_state` : The random state used for generating key-value pairs.
///
/// Returns a randomly generated hashmap containing arbitrary key-value pairs.
///
/// Example:
///
/// ```moonbit
/// test "arbitrary" {
///   let samples : Array[@hashmap.T[Int, String]] = @quickcheck.samples(5)
///   inspect!(samples.length(), content="5")
/// }
/// ```
pub impl[K : @quickcheck.Arbitrary + Hash + Eq, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[
  K,
  V,
] with arbitrary(size, rs) {
  let m = new()
  (@quickcheck.Arbitrary::arbitrary(size, rs) : Iter[(K, V)]).each(fn {
    (k, v) => m.set(k, v)
  })
  m
}

///|
priv type MyString String derive(Eq)

///|
impl Hash for MyString with hash(self) {
  self._.length()
}

///|
impl Hash for MyString with hash_combine(self, hasher) {
  hasher.combine_string(self._)
}

///|
impl Show for MyString with output(self, logger) {
  logger.write_string(self._)
}

///|
test "arbitrary" {
  let samples : Array[T[String, Int]] = @quickcheck.samples(20)
  inspect!(
    samples[5:10],
    content=
      #|[HashMap::of([]), HashMap::of([]), HashMap::of([("", 0)]), HashMap::of([("", 0)]), HashMap::of([("", 0)])]
    ,
  )
  inspect!(
    samples[11:15],
    content=
      #|[HashMap::of([("Q", 1), ("", 0), ("\x1e", 0)]), HashMap::of([("", 0)]), HashMap::of([("F:", 0), ("A&", 2), ("v\b", 0), ("", 0), ("#", 0)]), HashMap::of([("p(", -2), ("^\x1e", 3), ("2x", 1), ("", 3)])]
    ,
  )
}

///|
test "set" {
  let m : T[MyString, Int] = new()
  m.set("a", 1)
  m.set("b", 1)
  m.set("bc", 2)
  m.set("abc", 3)
  m.set("cd", 2)
  m.set("c", 1)
  m.set("d", 1)
  assert_eq!(m.size(), 7)
  inspect!(
    m.debug_entries(),
    content="_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )
}

///|
test "remove" {
  let m : T[MyString, Int] = new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("bc", 2)
  m.set("cd", 2)
  m.set("abc", 3)
  m.set("abcdef", 6)
  m.remove("ab")
  assert_eq!(m.size(), 5)
  inspect!(
    m.debug_entries(),
    content="_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_,_,_,_,_,_,_,_,_",
  )
}

///|
test "remove_unexist_key" {
  let m : T[MyString, Int] = new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  assert_eq!(m.size(), 3)
  inspect!(m.debug_entries(), content="_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_")
}

///|
test "clear" {
  let m : T[MyString, Int] = of([("a", 1), ("b", 2), ("c", 3)])
  m.clear()
  assert_eq!(m.size(), 0)
  assert_eq!(m.capacity(), 8)
  for i in 0..<m.capacity() {
    @test.same_object!(m.entries[i], None)
  }
}

///|
test "grow" {
  let m : T[MyString, Int] = new()
  m.set("C", 1)
  m.set("Go", 2)
  m.set("C++", 3)
  m.set("Java", 4)
  m.set("Scala", 5)
  m.set("Julia", 5)
  assert_eq!(m.size(), 6)
  inspect!(m.capacity(), content="16")
  m.set("Cobol", 5)
  assert_eq!(m.size(), 7)
  inspect!(m.capacity(), content="16")
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  assert_eq!(m.size(), 10)
  inspect!(m.capacity(), content="32")
  inspect!(
    m.debug_entries(),
    content="_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_",
  )
}
