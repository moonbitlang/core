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
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new(capacity=16)
///   inspect(map.capacity(), content="16")
///   inspect(map.is_empty(), content="true")
/// ```
#as_free_fn
pub fn[K, V] HashMap::new(capacity? : Int = 8) -> HashMap[K, V] {
  let capacity = capacity.next_power_of_two()
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
///   let arr = [(1, "one"), (2, "two"), (1, "ONE")]
///   let map = @hashmap.from_array(arr)
///   inspect(map.get(1), content="Some(\"ONE\")")
///   inspect(map.get(2), content="Some(\"two\")")
/// ```
#as_free_fn
pub fn[K : Hash + Eq, V] HashMap::from_array(
  arr : Array[(K, V)],
) -> HashMap[K, V] {
  let m = new(capacity=arr.length())
  arr.each(e => m.set(e.0, e.1))
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
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new()
///   map.set("key", 42)
///   inspect(map.get("key"), content="Some(42)")
///   map.set("key", 24) // update existing key
///   inspect(map.get("key"), content="Some(24)")
/// ```
pub fn[K : Hash + Eq, V] set(self : HashMap[K, V], key : K, value : V) -> Unit {
  self.set_with_hash(key, value, key.hash())
}

///|
fn[K : Eq, V] set_with_hash(
  self : HashMap[K, V],
  key : K,
  value : V,
  hash : Int,
) -> Unit {
  if self.size >= self.capacity / 2 {
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
  let entry = { psl, key, value, hash }
  self.entries[idx] = Some(entry)
  self.size += 1
}

///|
fn[K, V] HashMap::push_away(
  self : HashMap[K, V],
  idx : Int,
  entry : Entry[K, V],
) -> Unit {
  for psl = entry.psl + 1, idx = (idx + 1) & self.capacity_mask, entry = entry {
    match self.entries[idx] {
      None => {
        entry.psl = psl
        self.entries[idx] = Some(entry)
        break
      }
      Some(curr_entry) =>
        if psl > curr_entry.psl {
          entry.psl = psl
          self.entries[idx] = Some(entry)
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
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new()
///   map["key"] = 42
///   inspect(map.get("key"), content="Some(42)")
/// ```
pub fn[K : Hash + Eq, V] op_set(
  self : HashMap[K, V],
  key : K,
  value : V,
) -> Unit {
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
///   let map = @hashmap.of([("key", 42)])
///   inspect(map.get("key"), content="Some(42)")
///   inspect(map.get("nonexistent"), content="None")
/// ```
pub fn[K : Hash + Eq, V] get(self : HashMap[K, V], key : K) -> V? {
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
/// Retrieves the value associated with a given key in the hash map.
///
/// Parameters:
///
/// * `self` : The hash map to search in.
/// * `key` : The key to look up in the map.
///
/// Returns `value` if the key exists in the map, panic otherwise.
///
/// Example:
///
/// ```moonbit
///   let map = @hashmap.of([("key", 42)])
///   inspect(map["key"], content="42")
/// ```
pub fn[K : Hash + Eq, V] op_get(self : HashMap[K, V], key : K) -> V {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry)
    if entry.hash == hash && entry.key == key {
      break entry.value
    }
    guard entry.psl <= i
    continue i + 1, (idx + 1) & self.capacity_mask
  }
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
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new()
///   let value = map.get_or_init("key", () => { 42 })
///   inspect(value, content="42")
///   inspect(map.get("key"), content="Some(42)")
/// ```
pub fn[K : Hash + Eq, V] get_or_init(
  self : HashMap[K, V],
  key : K,
  init : () -> V,
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
          let new_value = init()
          break (idx, psl, new_value, Some(entry))
        }
        continue psl + 1, (idx + 1) & self.capacity_mask
      }
      None => {
        let new_value = init()
        break (idx, psl, new_value, None)
      }
    }
  }
  if self.size >= self.capacity / 2 {
    // Slow path, we need to resize
    self.grow()
    self.set_with_hash(key, new_value, hash)
  } else {
    if push_away is Some(entry) {
      self.push_away(idx, entry)
    }
    let entry = { psl, hash, key, value: new_value }
    self.entries[idx] = Some(entry)
    self.size += 1
  }
  new_value
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
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   inspect(map.get_or_default("a", 0), content="1")
///   inspect(map.get_or_default("c", 0), content="0")
/// ```
pub fn[K : Hash + Eq, V] get_or_default(
  self : HashMap[K, V],
  key : K,
  default : V,
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
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   inspect(map.contains("a"), content="true")
///   inspect(map.contains("c"), content="false")
/// ```
pub fn[K : Hash + Eq, V] contains(self : HashMap[K, V], key : K) -> Bool {
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
/// Checks if a map contains a specific key-value pair.
///
/// Parameters:
///
/// * `map` : A map of type `@hashmap.HashMap[K, V]` to search in.
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
///   let map = @hashmap.new()
///   map..set("a", 1)..set("b", 2)
///   inspect(map.contains_kv("a", 1), content="true")
///   inspect(map.contains_kv("a", 2), content="false")
///   inspect(map.contains_kv("c", 3), content="false")
/// ```
pub fn[K : Hash + Eq, V : Eq] contains_kv(
  self : HashMap[K, V],
  key : K,
  value : V,
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
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   map.remove("a")
///   inspect(map.get("a"), content="None")
///   inspect(map.size(), content="1")
/// ```
pub fn[K : Hash + Eq, V] remove(self : HashMap[K, V], key : K) -> Unit {
  self.remove_with_hash(key, key.hash())
}

///|
fn[K : Eq, V] remove_with_hash(
  self : HashMap[K, V],
  key : K,
  hash : Int,
) -> Unit {
  for i = 0, idx = hash & self.capacity_mask {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
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
fn[K, V] shift_back(self : HashMap[K, V], idx : Int) -> Unit {
  let next = (idx + 1) & self.capacity_mask
  match self.entries[next] {
    None | Some({ psl: 0, .. }) => self.entries[idx] = None
    Some(entry) => {
      entry.psl -= 1
      self.entries[idx] = Some(entry)
      self.shift_back(next)
    }
  }
}

///|
fn[K : Eq, V] grow(self : HashMap[K, V]) -> Unit {
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
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   inspect(map.get(1), content="Some(\"one\")")
///   inspect(map.get(2), content="Some(\"two\")")
/// ```
#as_free_fn
pub fn[K : Eq + Hash, V] HashMap::of(arr : FixedArray[(K, V)]) -> HashMap[K, V] {
  let m = new(capacity=arr.length())
  arr.each(e => m.set(e.0, e.1))
  m
}

///|
test "of" {
  let m = of([(1, 2), (3, 4)])
  inspect(m.get(1), content="Some(2)")
  inspect(m.get(3), content="Some(4)")
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
///   let samples : Array[@hashmap.HashMap[Int, String]] = @quickcheck.samples(5)
///   inspect(samples.length(), content="5")
/// ```
pub impl[K : @quickcheck.Arbitrary + Hash + Eq, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for HashMap[
  K,
  V,
] with arbitrary(size, rs) {
  let m = new()
  (@quickcheck.Arbitrary::arbitrary(size, rs) : Iter[(K, V)]).each(kv => m.set(
    kv.0,
    kv.1,
  ))
  m
}

///|
pub impl[K, V] Default for HashMap[K, V] with default() {
  new()
}

///|
/// Applies a function to each key-value pair in the map and 
/// returns a new map with the results, using the original keys.
pub fn[K, V, V2] HashMap::map(
  self : HashMap[K, V],
  f : (K, V) -> V2,
) -> HashMap[K, V2] {
  let other = {
    capacity: self.capacity,
    entries: FixedArray::make(self.capacity, None),
    size: self.size,
    capacity_mask: self.capacity_mask,
  }
  if self.size == 0 {
    return other
  }
  for i in 0..<self.capacity {
    if self.entries[i] is Some({ key, value, hash, psl }) {
      other.entries[i] = Some({ psl, key, value: f(key, value), hash })
    }
  }
  other
}

///|
/// Copy the map, creating a new map with the same key-value pairs.
pub fn[K, V] HashMap::copy(self : HashMap[K, V]) -> HashMap[K, V] {
  let other = {
    capacity: self.capacity,
    entries: FixedArray::make(self.capacity, None),
    size: self.size,
    capacity_mask: self.capacity_mask,
  }
  if self.size == 0 {
    return other
  }
  for i in 0..<self.capacity {
    if self.entries[i] is Some({ key, value, hash, psl }) {
      other.entries[i] = Some({ psl, key, value, hash })
    }
  }
  other
}

///|
priv struct MyString(String) derive(Eq)

///|
#coverage.skip
impl Hash for MyString with hash(self) {
  let MyString(self) = self
  self.length()
}

///|
#coverage.skip
impl Hash for MyString with hash_combine(self, hasher) {
  hasher.combine_string(self.0)
}

///|
#coverage.skip
impl Show for MyString with output(self, logger) {
  logger.write_string(self.0)
}

///|
test "arbitrary" {
  let samples : Array[HashMap[String, Int]] = @quickcheck.samples(20)
  inspect(
    samples[5:10],
    content=(
      #|[HashMap::of([]), HashMap::of([]), HashMap::of([("", 0)]), HashMap::of([("", 0)]), HashMap::of([("", 0)])]
    ),
  )
  inspect(
    samples[11:15],
    content=(
      #|[HashMap::of([("Q", 1), ("", 0), ("\u{1e}", 0)]), HashMap::of([("", 0)]), HashMap::of([("F:", 0), ("A&", 2), ("v\b", 0), ("", 0), ("#", 0)]), HashMap::of([("p(", -2), ("^\u{1e}", 3), ("2x", 1), ("", 3)])]
    ),
  )
}

///|
test "set" {
  let m : HashMap[MyString, Int] = new()
  m.set("a", 1)
  m.set("b", 1)
  m.set("bc", 2)
  m.set("abc", 3)
  m.set("cd", 2)
  m.set("c", 1)
  m.set("d", 1)
  inspect(m.size(), content="7")
  inspect(
    m.debug_entries(),
    content="_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )
}

///|
test "remove" {
  let m : HashMap[MyString, Int] = new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("bc", 2)
  m.set("cd", 2)
  m.set("abc", 3)
  m.set("abcdef", 6)
  m.remove("ab")
  inspect(m.size(), content="5")
  inspect(
    m.debug_entries(),
    content="_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_,_,_,_,_,_,_,_,_",
  )
}

///|
test "remove_unexist_key" {
  let m : HashMap[MyString, Int] = new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  inspect(m.size(), content="3")
  inspect(m.debug_entries(), content="_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_")
}

///|
test "clear" {
  let m : HashMap[MyString, Int] = of([("a", 1), ("b", 2), ("c", 3)])
  m.clear()
  inspect(m.size(), content="0")
  inspect(m.capacity(), content="8")
  for i in 0..<m.capacity() {
    @test.same_object(m.entries[i], None)
  }
}

///|
test "grow" {
  let m : HashMap[MyString, Int] = new()
  m.set("C", 1)
  m.set("Go", 2)
  m.set("C++", 3)
  m.set("Java", 4)
  m.set("Scala", 5)
  m.set("Julia", 5)
  inspect(m.size(), content="6")
  inspect(m.capacity(), content="16")
  m.set("Cobol", 5)
  inspect(m.size(), content="7")
  inspect(m.capacity(), content="16")
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  inspect(m.size(), content="10")
  inspect(m.capacity(), content="32")
  inspect(
    m.debug_entries(),
    content="_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_",
  )
}

///|
test "get_or_init" {
  let m : HashMap[MyString, Int] = new()
  inspect(m.get_or_init("a", () => 1), content="1")
  inspect(m.get("a"), content="Some(1)")
  inspect(m.get_or_init("a", () => 2), content="1")
  inspect(m.get("a"), content="Some(1)")
}
