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
/// Removes all key-value pairs from the map while retaining the allocated
/// capacity. After calling this method, the size of the map will be zero but the
/// capacity remains unchanged.
///
/// Parameters:
///
/// * `self` : The hash map to be cleared.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2)])
///   map.clear()
///   inspect(map.length(), content="0")
///   debug_inspect(map.get("a"), content="None")
/// }
/// ```
pub fn[K, V] HashMap::clear(self : HashMap[K, V]) -> Unit {
  self.entries.fill(None)
  self.size = 0
}

///|
/// Returns an iterator over the key-value pairs in the map.
///
/// Parameters:
///
/// * `map` : The hash map to iterate over.
///
/// Returns an iterator that yields tuples of `(key, value)` for each entry in
/// the map, in unspecified order.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([(1, "one"), (2, "two")])
///   let pairs = map.iter().to_array()
///   inspect(pairs.length(), content="2")
///   inspect(pairs.contains((1, "one")), content="true")
///   inspect(pairs.contains((2, "two")), content="true")
/// }
/// ```
#alias(iterator, deprecated)
pub fn[K, V] HashMap::iter(self : HashMap[K, V]) -> Iter[(K, V)] {
  let mut i = 0
  let len = self.entries.length()
  Iter::new(
    fn() {
      while i < len {
        let entry = self.entries.unsafe_get(i)
        i += 1
        if entry is Some({ key, value, .. }) {
          return Some((key, value))
        }
      } nobreak {
        None
      }
    },
    size_hint=self.size,
  )
}

///|
/// Returns an iterator over the key-value pairs in the map.
///
/// Parameters:
///
/// * `map` : The hash map to iterate over.
///
/// Returns an iterator that yields tuples of `(key, value)` for each entry in
/// the map, in unspecified order.
/// This is mainly used for `for _, _ in ..` loops.
#alias(iterator2, deprecated)
pub fn[K, V] HashMap::iter2(self : HashMap[K, V]) -> Iter2[K, V] {
  self.iter()
}

///|
/// Creates a new hash map from an iterator of key-value pairs.
///
/// Parameters:
///
/// * `iter` : An iterator that yields key-value pairs. The key type must
/// implement both `Hash` and `Eq` traits.
///
/// Returns a new hash map containing all key-value pairs from the iterator. If
/// the iterator yields multiple pairs with the same key, the later value will
/// overwrite the earlier one.
///
/// Example:
///
/// ```mbt check
/// test {
///   let iter = [|(1, "one"), (2, "two")|]
///   let map = @hashmap.from_iter(iter)
///   debug_inspect(map.get(1), content="Some(\"one\")")
///   debug_inspect(map.get(2), content="Some(\"two\")")
/// }
/// ```
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Hash + Eq, V] HashMap::from_iter(
  iter : Iter[(K, V)],
) -> HashMap[K, V] {
  let m = new_hashmap(default_init_capacity)
  while iter.next() is Some((k, v)) {
    m[k] = v
  }
  m
}

///|
/// Converts the hash map into an array of key-value pairs. The order of elements
/// in the resulting array follows the internal storage order of the hash map.
///
/// Parameters:
///
/// * `self` : The hash map to be converted.
///
/// Returns an array containing tuples of key-value pairs from the hash map.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([(1, "one"), (2, "two")])
///   let arr = map.to_array()
///   arr.sort()
///   debug_inspect(
///     arr,
///     content=(
///       #|[(1, "one"), (2, "two")]
///     ),
///   )
/// }
/// ```
pub fn[K, V] HashMap::to_array(self : HashMap[K, V]) -> Array[(K, V)] {
  if self.size == 0 {
    return []
  }
  let res = Array::unsafe_make_uninit(self.size)
  let mut n = 0
  for i in 0..<self.capacity {
    if self.entries[i] is Some({ key, value, .. }) {
      let pair = (key, value)
      res.unsafe_set(n, pair)
      n += 1
      if n == self.size {
        break
      }
    }
  }
  res
}

///|
/// Returns the number of key-value pairs currently stored in the hash map.
///
/// Parameters:
///
/// * `self` : The hash map to get the size from.
///
/// Returns the number of key-value pairs in the hash map.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
///   inspect(map.length(), content="3")
/// }
/// ```
#alias(size, deprecated)
pub fn[K, V] HashMap::length(self : HashMap[K, V]) -> Int {
  self.size
}

///|
/// Returns the current capacity of the hash map, that is, the length of its
/// internal storage array. The map grows once it is half full, so it can hold
/// at most `capacity / 2` key-value pairs before it reallocates.
///
/// Parameters:
///
/// * `map` : The hash map whose capacity is to be queried.
///
/// Returns the length of the hash map's internal storage array.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map : @hashmap.HashMap[Int, String] = HashMap([], capacity=16)
///   inspect(map.capacity(), content="16")
/// }
/// ```
pub fn[K, V] HashMap::capacity(self : HashMap[K, V]) -> Int {
  self.capacity
}

///|
/// Returns whether the hash map contains no key-value pairs.
///
/// Parameters:
///
/// * `map` : The hash map to check.
///
/// Returns `true` if the hash map contains no key-value pairs, `false`
/// otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map : @hashmap.HashMap[String, Int] = HashMap([])
///   inspect(map.is_empty(), content="true")
///   map.set("key", 42)
///   inspect(map.is_empty(), content="false")
/// }
/// ```
pub fn[K, V] HashMap::is_empty(self : HashMap[K, V]) -> Bool {
  self.size == 0
}

///|
/// Iterates over all key-value pairs in the hash map and applies the given
/// function to each pair.
///
/// Parameters:
///
/// * `map` : The hash map to iterate over.
/// * `action` : A function that takes a key and a value as arguments and
/// performs some action. The function should not return any value.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([(1, "one"), (2, "two")])
///   let array = []
///   map.each((k, v) => array.push((k, v)))
///   array.sort()
///   debug_inspect(
///     array,
///     content=(
///       #|[(1, "one"), (2, "two")]
///     ),
///   )
/// }
/// ```
#locals(f)
pub fn[K, V] HashMap::each(
  self : HashMap[K, V],
  f : (K, V) -> Unit raise?,
) -> Unit raise? {
  for i in 0..<self.capacity {
    if self.entries[i] is Some({ key, value, .. }) {
      f(key, value)
    }
  }
}

///|
/// Iterates over all key-value pairs in the map with their index, applying the
/// given function to each element. The index starts from 0 and only counts
/// non-empty entries.
/// 
/// Notice that the order of iteration is not guaranteed.
///
/// Parameters:
///
/// * `self` : The hash map to iterate over.
/// * `callback` : A function that takes three arguments:
///  * An integer representing the index of the current key-value pair
///  * The key of the current entry
///  * The value of the current entry
///
#locals(f)
pub fn[K, V] HashMap::eachi(
  self : HashMap[K, V],
  f : (Int, K, V) -> Unit raise?,
) -> Unit raise? {
  for i = 0, idx = 0; i < self.capacity; {
    match self.entries[i] {
      Some({ key, value, .. }) => {
        f(idx, key, value)
        continue i + 1, idx + 1
      }
      None => continue i + 1, idx
    }
  }
}

///|
/// Returns an iterator over all keys in the hash map.
///
/// Parameters:
///
/// * `self` : The hash map to iterate over.
///
/// Returns an iterator that yields each key in the hash map in unspecified order.
/// The keys are yielded in the same order as they appear in the internal storage.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
///   let keys = map.keys().to_array()
///   inspect(keys.length(), content="3")
///   inspect(keys.contains(1), content="true")
///   inspect(keys.contains(2), content="true")
///   inspect(keys.contains(3), content="true")
/// }
/// ```
pub fn[K, V] HashMap::keys(self : HashMap[K, V]) -> Iter[K] {
  let mut i = 0
  Iter::new(
    () => {
      while i < self.entries.length() {
        let entry = self.entries[i]
        i += 1
        if entry is Some({ key, .. }) {
          break Some(key)
        }
      } nobreak {
        None
      }
    },
    size_hint=self.size,
  )
}

///|
/// Returns an iterator over all values in the hash map.
///
/// Parameters:
///
/// * `self` : The hash map to iterate over.
///
/// Returns an iterator that yields each value in the hash map in unspecified order.
/// The values are yielded in the same order as they appear in the internal storage.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
///   let values = map.values().to_array()
///   inspect(values.length(), content="3")
///   inspect(values.contains(1), content="true")
///   inspect(values.contains(2), content="true")
///   inspect(values.contains(3), content="true")
/// }
/// ```
pub fn[K, V] HashMap::values(self : HashMap[K, V]) -> Iter[V] {
  let mut i = 0
  Iter::new(
    () => {
      while i < self.entries.length() {
        let entry = self.entries[i]
        i += 1
        if entry is Some({ value, .. }) {
          break Some(value)
        }
      } nobreak {
        None
      }
    },
    size_hint=self.size,
  )
}

///|
/// Keeps only the key-value pairs for which `f` returns `true`, removing the
/// rest in place.
///
/// `true` means *keep*, as with `HashMap::filter`, which returns a new map
/// and leaves `self` unchanged; use `retain` when the original is no longer
/// needed. `f` must not modify the map.
///
/// Parameters:
///
/// * `self` : The hash map to be filtered.
/// * `f` : A function that takes a key and value as arguments and returns
/// `true` if the key-value pair should be kept, `false` if it should be removed.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3), ("d", 4)])
///   map.retain((_k, v) => v % 2 == 0) // Keep only even values
///   inspect(map.length(), content="2")
///   debug_inspect(map.get("a"), content="None")
///   debug_inspect(map.get("b"), content="Some(2)")
///   debug_inspect(map.get("c"), content="None")
///   debug_inspect(map.get("d"), content="Some(4)")
/// }
/// ```
#locals(f)
pub fn[K, V] HashMap::retain(self : HashMap[K, V], f : (K, V) -> Bool) -> Unit {
  guard self.size > 0 else { return }
  // Scan the table once, starting just after an empty slot. `shift_back`
  // moves entries back only within a cluster, and a cluster never spans an
  // empty slot, so an entry is never shifted from an already-visited slot
  // into one still to be visited. Starting at slot 0 instead breaks when a
  // cluster wraps around the end of the table: removing the entry in the last
  // slot shifts the wrapped entry from slot 0 back into it, and `f` sees that
  // entry twice. The load factor stays below 1, so an empty slot exists.
  let mask = self.capacity_mask
  let start = for i = 0 {
    if self.entries[i] is None {
      break i
    }
    continue i + 1
  }
  for k in 1..<=mask {
    let i = (start + k) & mask
    while self.entries[i] is Some(entry) {
      if f(entry.key, entry.value) {
        break
      } else {
        self.shift_back(i)
        self.size -= 1
      }
    }
  }
}

///|
/// Returns a new hash map holding the key-value pairs for which `f` returns
/// `true`. `self` is unchanged.
///
/// `true` means *keep*, as with `Array::filter`. To filter in place instead,
/// use `HashMap::retain`.
///
/// The result is sized for the entries kept, like `@hashmap.from_array`. It is
/// faster than rebuilding from a comprehension such as
/// `@hashmap.from_array([for k, v in m if f(k, v) => (k, v)])` because each
/// entry's stored hash is reused: keys are never hashed again and no tuples
/// are allocated.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3), ("d", 4)])
///   let even = map.filter((_k, v) => v % 2 == 0)
///   inspect(even.length(), content="2")
///   debug_inspect(even.get("b"), content="Some(2)")
///   debug_inspect(even.get("c"), content="None")
///   inspect(map.length(), content="4")
/// }
/// ```
pub fn[K, V] HashMap::filter(
  self : HashMap[K, V],
  f : (K, V) -> Bool raise?,
) -> HashMap[K, V] raise? {
  // Collect first so the result can be sized for exactly the kept entries:
  // a stored hash fits a table of any size. The entries are fresh because
  // `psl` belongs to the table an entry sits in.
  let kept : Array[Entry[K, V]] = []
  for entry in self.entries {
    if entry is Some({ key, value, hash, .. }) && f(key, value) {
      kept.push({ psl: 0, key, value, hash, })
    }
  }
  let other = new_hashmap(
    if kept.is_empty() {
      default_init_capacity
    } else {
      capacity_for_length(kept.length())
    },
  )
  for entry in kept {
    other.rehash_place_entry(entry)
  }
  other.size = kept.length()
  other
}

///|
test "retain" {
  // seed = 1827982181
  let hashmap : HashMap[String, Int] = {
    capacity: 8,
    capacity_mask: 7,
    size: 4,
    entries: [
      Some({ psl: 2, hash: 448974246, key: "c", value: 3, }),
      Some({ psl: 2, hash: -136509641, key: "d", value: 4, }),
      None,
      None,
      None,
      None,
      Some({ psl: 0, hash: 1614946358, key: "a", value: 1, }),
      Some({ psl: 1, hash: -765931946, key: "b", value: 2, }),
    ],
  }
  hashmap.retain((_k, v) => v % 2 == 0)
  @debug.debug_inspect(
    hashmap.entries,
    content=(
      #|<FixedArray:
      #|  [
      #|    None,
      #|    None,
      #|    None,
      #|    None,
      #|    None,
      #|    None,
      #|    Some({ psl: 0, hash: -765931946, key: "b", value: 2 }),
      #|    Some({ psl: 0, hash: -136509641, key: "d", value: 4 }),
      #|  ]>
    ),
  )
}
