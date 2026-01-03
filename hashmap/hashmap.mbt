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
/// ```mbt check
/// test {
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new(capacity=16)
///   inspect(map.capacity(), content="16")
///   inspect(map.is_empty(), content="true")
/// }
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
/// ```mbt check
/// test {
///   let arr = [(1, "one"), (2, "two"), (1, "ONE")]
///   let map = @hashmap.from_array(arr)
///   inspect(map.get(1), content="Some(\"ONE\")")
///   inspect(map.get(2), content="Some(\"two\")")
/// }
/// ```
#as_free_fn
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[K : Hash + Eq, V] HashMap::from_array(
  arr : ArrayView[(K, V)],
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
/// ```mbt check
/// test {
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new()
///   map.set("key", 42)
///   inspect(map.get("key"), content="Some(42)")
///   map.set("key", 24) // update existing key
///   inspect(map.get("key"), content="Some(24)")
/// }
/// ```
#alias("_[_]=_")
pub fn[K : Hash + Eq, V] HashMap::set(
  self : HashMap[K, V],
  key : K,
  value : V,
) -> Unit {
  self.set_with_hash(key, value, key.hash())
}

///|
fn[K : Eq, V] HashMap::set_with_hash(
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
///   let map = @hashmap.from_array([("key", 42)])
///   inspect(map.get("key"), content="Some(42)")
///   inspect(map.get("nonexistent"), content="None")
/// }
/// ```
pub fn[K : Hash + Eq, V] HashMap::get(self : HashMap[K, V], key : K) -> V? {
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
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("key", 42)])
///   inspect(map["key"], content="42")
/// }
/// ```
#alias("_[_]")
pub fn[K : Hash + Eq, V] HashMap::at(self : HashMap[K, V], key : K) -> V {
  let hash = key.hash()
  for i = 0, idx = hash & self.capacity_mask {
    guard self.entries[idx] is Some(entry)
    if entry.hash == hash && entry.key == key {
      break entry.value
    }
    guard i <= entry.psl
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
/// ```mbt check
/// test {
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new()
///   let value = map.get_or_init("key", () => 42)
///   inspect(value, content="42")
///   inspect(map.get("key"), content="Some(42)")
/// }
/// ```
pub fn[K : Hash + Eq, V] HashMap::get_or_init(
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
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2)])
///   inspect(map.get_or_default("a", 0), content="1")
///   inspect(map.get_or_default("c", 0), content="0")
/// }
/// ```
pub fn[K : Hash + Eq, V] HashMap::get_or_default(
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
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2)])
///   inspect(map.contains("a"), content="true")
///   inspect(map.contains("c"), content="false")
/// }
/// ```
pub fn[K : Hash + Eq, V] HashMap::contains(
  self : HashMap[K, V],
  key : K,
) -> Bool {
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
/// ```mbt check
/// test {
///   let map = @hashmap.new()
///   map..set("a", 1)..set("b", 2)
///   inspect(map.contains_kv("a", 1), content="true")
///   inspect(map.contains_kv("a", 2), content="false")
///   inspect(map.contains_kv("c", 3), content="false")
/// }
/// ```
pub fn[K : Hash + Eq, V : Eq] HashMap::contains_kv(
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
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2)])
///   map.remove("a")
///   inspect(map.get("a"), content="None")
///   inspect(map.length(), content="1")
/// }
/// ```
pub fn[K : Hash + Eq, V] HashMap::remove(self : HashMap[K, V], key : K) -> Unit {
  self.remove_with_hash(key, key.hash())
}

///|
fn[K : Eq, V] HashMap::remove_with_hash(
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
fn[K, V] HashMap::shift_back(self : HashMap[K, V], idx : Int) -> Unit {
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
fn[K : Eq, V] HashMap::grow(self : HashMap[K, V]) -> Unit {
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

///|
test "of" {
  let m = from_array([(1, 2), (3, 4)])
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
/// ```mbt check
/// test {
///   let samples : Array[@hashmap.HashMap[Int, String]] = @quickcheck.samples(5)
///   inspect(samples.length(), content="5")
/// }
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
/// Merges two maps into a new map. Returns a new map containing all key-value
/// pairs from both maps. When both maps contain the same key, the value from
/// `other` takes precedence.
///
/// This is a pure operation - it does not modify either of the input maps.
///
/// Parameters:
///
/// * `self` : The first map.
/// * `other` : The second map whose values take precedence in case of key
/// conflicts.
///
/// Returns a new hash map containing all entries from both maps.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map1 = @hashmap.from_array([("a", 1), ("b", 2)])
///   let map2 = @hashmap.from_array([("b", 3), ("c", 4)])
///   let merged = map1.merge(map2).to_array()
///   merged.sort()
///   @json.inspect(merged, content=[["a", 1], ["b", 3], ["c", 4]])
/// }
/// ```
pub fn[K : Eq, V] HashMap::merge(
  self : HashMap[K, V],
  other : HashMap[K, V],
) -> HashMap[K, V] {
  let result = self.copy()
  result.merge_in_place(other)
  result
}

///|
/// Merges another map into this map in-place. Updates the current map by adding
/// all key-value pairs from `other`. When both maps contain the same key, the
/// value from `other` overwrites the value in this map.
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
///   let map1 = @hashmap.from_array([("a", 1), ("b", 2)])
///   let map2 = @hashmap.from_array([("b", 3), ("c", 4)])
///   map1.merge_in_place(map2)
///   let merged = map1.to_array()
///   merged.sort()
///   @json.inspect(merged, content=[["a", 1], ["b", 3], ["c", 4]])
/// }
/// ```
pub fn[K : Eq, V] HashMap::merge_in_place(
  self : HashMap[K, V],
  other : HashMap[K, V],
) -> Unit {
  for entry in other.entries {
    if entry is Some({ key, value, hash, .. }) {
      self.set_with_hash(key, value, hash)
    }
  }
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
fn[K : Hash + Eq, V : Eq] verify_content(
  map : HashMap[K, V],
  expected : Array[(K, V)],
) -> Unit raise {
  for entry in expected {
    let (k, v) = entry
    assert_true(map.contains_kv(k, v))
  }
  assert_eq(map.length(), expected.length())
}

///|
test "arbitrary" {
  let samples : Array[HashMap[String, Int]] = @quickcheck.samples(20)
  let data = [
    [],
    [],
    [],
    [("", 0)],
    [("", 0)],
    [],
    [],
    [("", 0)],
    [("", 0)],
    [("", 0)],
    [("}\u{11}e", -1), ("", 0), ("0f", -1), ("k", -2)],
    [("Q", 1), ("", 0), ("\u{1e}", 0)],
    [("", 0)],
    [("F:", 0), ("A&", 2), ("v\b", 0), ("", 0), ("#", 0)],
    [("p(", -2), ("^\u{1e}", 3), ("2x", 1), ("", 3)],
    [("A", -3), ("", 0), ("/w", 0), ("lD", 0), ("jlF0", 3)],
    [
      ("zd", 2),
      ("[z\r]j", 4),
      ("\u{1d}r", -3),
      ("", 0),
      ("p=61s\u{14}", -7),
      ("t|,7X4\"\u{14}", -10),
      ("HeH\b\u{15}d", 1),
      ("LC\u{19}", 1),
      ("\u{0b}", 0),
      ("\n", 0),
      ("3", -9),
      ("v", -1),
    ],
    [
      ("", -1),
      ("&\b", -4),
      ("ob%>j\bD?xboR5", 0),
      (";:B", -3),
      ("`", 1),
      ("OwQCP+@", -1),
      ("O]k", -3),
      ("\n^", -3),
      ("U_-*\u{1c}x\u{18}", -11),
      ("shU^\u{1d}hd8\u{1d}", 0),
      ("!\u{1b}63p", 3),
      ("q", 1),
      ("R@", 4),
    ],
    [("", -4), ("v", -2), (")xh", 1), ("C\u{10}\u{0e}", -3), ("|", 0)],
    [("", 1), ("b", -1)],
  ]
  for i in 0..<samples.length() {
    verify_content(samples[i], data[i])
  }
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
  inspect(m.length(), content="7")
  // inspect(
  //   m._debug_entries(),
  //   content="_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  // )
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
  inspect(m.length(), content="5")
  // inspect(
  //   m._debug_entries(),
  //   content="_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_,_,_,_,_,_,_,_,_",
  // )
}

///|
test "remove_unexist_key" {
  let m : HashMap[MyString, Int] = new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  inspect(m.length(), content="3")
  // inspect(m._debug_entries(), content="_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_")
}

///|
test "clear" {
  let m : HashMap[MyString, Int] = from_array([("a", 1), ("b", 2), ("c", 3)])
  m.clear()
  inspect(m.length(), content="0")
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
  inspect(m.length(), content="6")
  inspect(m.capacity(), content="16")
  m.set("Cobol", 5)
  inspect(m.length(), content="7")
  inspect(m.capacity(), content="16")
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  inspect(m.length(), content="10")
  inspect(m.capacity(), content="32")
  inspect(m.get("C"), content="Some(1)")
  inspect(m.get("Go"), content="Some(2)")
  inspect(m.get("C++"), content="Some(3)")
  inspect(m.get("Java"), content="Some(4)")
  inspect(m.get("Scala"), content="Some(5)")
  inspect(m.get("Julia"), content="Some(5)")
  inspect(m.get("Cobol"), content="Some(5)")
  inspect(m.get("Python"), content="Some(6)")
  inspect(m.get("Haskell"), content="Some(7)")
  inspect(m.get("Rescript"), content="Some(8)")
  // Only for debugging
  // inspect(
  //   m._debug_entries(),
  //   content="_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_",
  // )
}

///|
test "_[_]" {
  let m : HashMap[MyString, Int] = new()
  m.set("a", 1)
  m.set("b", 1)
  m.set("cc", 2)
  inspect(m["a"], content="1")
  inspect(m["b"], content="1")
  inspect(m["cc"], content="2")
  // inspect(m._debug_entries(), content="_,(0,a,1),(1,b,1),(1,cc,2),_,_,_,_")
}

///|
test "get_or_init" {
  let m : HashMap[MyString, Int] = new()
  inspect(m.get_or_init("a", () => 1), content="1")
  inspect(m.get("a"), content="Some(1)")
  inspect(m.get_or_init("a", () => 2), content="1")
  inspect(m.get("a"), content="Some(1)")
}
