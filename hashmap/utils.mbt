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
fn debug_entries[K : Show, V : Show](self : T[K, V]) -> String {
  for s = "", i = 0; i < self.entries.length(); {
    let s = if i > 0 { s + "," } else { s }
    match self.entries[i] {
      None => continue s + "_", i + 1
      Some({ psl, key, value, .. }) =>
        continue s + "(\{psl},\{key},\{value})", i + 1
    }
  } else {
    s
  }
}

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
/// ```moonbit
/// test "clear" {
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   map.clear()
///   inspect!(map.size(), content="0")
///   inspect!(map.get("a"), content="None")
/// }
/// ```
pub fn clear[K, V](self : T[K, V]) -> Unit {
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
/// ```moonbit
/// test "iter" {
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let pairs = map.iter().to_array()
///   inspect!(pairs.length(), content="2")
///   inspect!(pairs.contains((1, "one")), content="true")
///   inspect!(pairs.contains((2, "two")), content="true")
/// }
/// ```
pub fn iter[K, V](self : T[K, V]) -> Iter[(K, V)] {
  Iter::new(fn(yield_) {
    for entry in self.entries {
      if entry is Some({ key, value, .. }) {
        guard yield_((key, value)) is IterContinue else { break IterEnd }

      }
    } else {
      IterContinue
    }
  })
}

///|
/// Creates an iterator over the key-value pairs in the map, where the key and
/// value are passed as separate arguments to the yielding function.
///
/// Parameters:
///
/// * `map` : The hash map to iterate over.
///
/// Returns an iterator `Iter2[K, V]` that yields each key-value pair in the map
/// as separate arguments. This differs from `iter()` which yields tuples of
/// key-value pairs.
///
/// Example:
///
/// ```moonbit
/// test "iter2" {
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let mut sum = 0
///   map.iter2().each(fn(k, _) { sum = sum + k })
///   inspect!(sum, content="3")
/// }
/// ```
pub fn iter2[K, V](self : T[K, V]) -> Iter2[K, V] {
  Iter2::new(fn(yield_) {
    for entry in self.entries {
      if entry is Some({ key, value, .. }) {
        guard yield_(key, value) is IterContinue else { break IterEnd }

      }
    } else {
      IterContinue
    }
  })
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
/// ```moonbit
/// test "from_iter" {
///   let arr = [(1, "one"), (2, "two")]
///   let iter = Iter::new(fn(yield_) {
///     for pair in arr {
///       if yield_(pair) == IterEnd {
///         break IterEnd
///       }
///     } else {
///       IterContinue
///     }
///   })
///   let map = @hashmap.from_iter(iter)
///   inspect!(map.get(1), content="Some(\"one\")")
///   inspect!(map.get(2), content="Some(\"two\")")
/// }
/// ```
pub fn from_iter[K : Hash + Eq, V](iter : Iter[(K, V)]) -> T[K, V] {
  let m = new()
  iter.each(fn(e) { m[e.0] = e.1 })
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
/// ```moonbit
/// test "to_array" {
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let arr = map.to_array()
///   inspect!(arr, content=
///   #|[(2, "two"), (1, "one")]
/// )
/// }
/// ```
pub fn to_array[K, V](self : T[K, V]) -> Array[(K, V)] {
  let mut i = 0
  let res = while i < self.capacity {
    if self.entries[i] is Some({ key, value, .. }) {
      i += 1
      break Array::make(self.size, (key, value))
    }
    i += 1
  } else {
    []
  }
  if not(res.is_empty()) {
    let mut res_idx = 1
    while res_idx < res.length() && i < self.capacity {
      if self.entries[i] is Some({ key, value, .. }) {
        res[res_idx] = (key, value)
        res_idx += 1
      }
      i += 1
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
/// ```moonbit
/// test "size" {
///   let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
///   inspect!(map.size(), content="3")
/// }
/// ```
pub fn size[K, V](self : T[K, V]) -> Int {
  self.size
}

///|
/// Returns the current capacity of the hash map. The capacity is the number of
/// key-value pairs the hash map can hold before it needs to reallocate its
/// internal storage.
///
/// Parameters:
///
/// * `map` : The hash map whose capacity is to be queried.
///
/// Returns the number of key-value pairs that can be stored in the hash map
/// before triggering a reallocation.
///
/// Example:
///
/// ```moonbit
/// test "capacity" {
///   let map : @hashmap.T[Int, String] = @hashmap.new(capacity=16)
///   inspect!(map.capacity(), content="16")
/// }
/// ```
pub fn capacity[K, V](self : T[K, V]) -> Int {
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
/// ```moonbit
/// test "is_empty" {
///   let map : @hashmap.T[String, Int] = @hashmap.new()
///   inspect!(map.is_empty(), content="true")
///   map.set("key", 42)
///   inspect!(map.is_empty(), content="false")
/// }
/// ```
pub fn is_empty[K, V](self : T[K, V]) -> Bool {
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
/// ```moonbit
/// test "each" {
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let mut result = ""
///   map.each(fn(k, v) { result = result + "\{k}:\{v}," })
///   inspect!(result, content="2:two,1:one,")
/// }
/// ```
pub fn each[K, V](self : T[K, V], f : (K, V) -> Unit) -> Unit {
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
/// Parameters:
///
/// * `self` : The hash map to iterate over.
/// * `callback` : A function that takes three arguments:
///  * An integer representing the index of the current key-value pair
///  * The key of the current entry
///  * The value of the current entry
///
/// Example:
///
/// ```moonbit
/// test "eachi" {
///   let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
///   let mut result = 0
///   map.eachi(fn(i, k, _) { if k == "b" { result = i } })
///   // "b" is at index 1
///   inspect!(result, content="2")
/// }
/// ```
pub fn eachi[K, V](self : T[K, V], f : (Int, K, V) -> Unit) -> Unit {
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
/// Provides string representation for hash maps.
///
/// Parameters:
///
/// * `self` : The hash map to be converted to string.
/// * `logger` : The buffer to write the string representation to.
///
/// Example:
///
/// ```moonbit
/// test "show" {
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   inspect!(map, content=
///   #|HashMap::of([(2, "two"), (1, "one")])
/// )
/// }
/// ```
pub impl[K : Show, V : Show] Show for T[K, V] with output(self, logger) {
  logger.write_string("HashMap::of([")
  self.eachi(fn(i, k, v) {
    if i > 0 {
      logger.write_string(", ")
    }
    logger
    ..write_string("(")
    ..write_object(k)
    ..write_string(", ")
    ..write_object(v)
    .write_string(")")
  })
  logger.write_string("])")
}
