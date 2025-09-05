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
fn[K : Show, V : Show] debug_entries(self : HashMap[K, V]) -> String {
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
///   let map = @hashmap.of([("a", 1), ("b", 2)])
///   map.clear()
///   inspect(map.size(), content="0")
///   inspect(map.get("a"), content="None")
/// ```
pub fn[K, V] clear(self : HashMap[K, V]) -> Unit {
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
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let pairs = map.iter().to_array()
///   inspect(pairs.length(), content="2")
///   inspect(pairs.contains((1, "one")), content="true")
///   inspect(pairs.contains((2, "two")), content="true")
/// ```
pub fn[K, V] iter(self : HashMap[K, V]) -> Iter[(K, V)] {
  Iter::new(yield_ => for entry in self.entries {
    if entry is Some({ key, value, .. }) {
      guard yield_((key, value)) is IterContinue else { break IterEnd }
    }
  } else {
    IterContinue
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
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let mut sum = 0
///   map.iter2().each((k, _) => { sum = sum + k })
///   inspect(sum, content="3")
/// ```
pub fn[K, V] iter2(self : HashMap[K, V]) -> Iter2[K, V] {
  Iter2::new(yield_ => for entry in self.entries {
    if entry is Some({ key, value, .. }) {
      guard yield_(key, value) is IterContinue else { break IterEnd }
    }
  } else {
    IterContinue
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
///   let arr = [(1, "one"), (2, "two")]
///   let iter = Iter::new((yield_) => {
///     for pair in arr {
///       if yield_(pair) is IterEnd {
///         break IterEnd
///       }
///     } else {
///       IterContinue
///     }
///   })
///   let map = @hashmap.from_iter(iter)
///   inspect(map.get(1), content="Some(\"one\")")
///   inspect(map.get(2), content="Some(\"two\")")
/// ```
#as_free_fn
pub fn[K : Hash + Eq, V] HashMap::from_iter(
  iter : Iter[(K, V)],
) -> HashMap[K, V] {
  let m = new()
  iter.each(e => m[e.0] = e.1)
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
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let arr = map.to_array()
///   inspect(
///     arr, 
///     content=(
///       #|[(2, "two"), (1, "one")]
///     ),
///   )
/// ```
pub fn[K, V] to_array(self : HashMap[K, V]) -> Array[(K, V)] {
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
  if !res.is_empty() {
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
///   let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
///   inspect(map.size(), content="3")
/// ```
pub fn[K, V] size(self : HashMap[K, V]) -> Int {
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
///   let map : @hashmap.HashMap[Int, String] = @hashmap.new(capacity=16)
///   inspect(map.capacity(), content="16")
/// ```
pub fn[K, V] capacity(self : HashMap[K, V]) -> Int {
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
///   let map : @hashmap.HashMap[String, Int] = @hashmap.new()
///   inspect(map.is_empty(), content="true")
///   map.set("key", 42)
///   inspect(map.is_empty(), content="false")
/// ```
pub fn[K, V] is_empty(self : HashMap[K, V]) -> Bool {
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
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   let mut result = ""
///   map.each((k, v) => { result = result + "\{k}:\{v}," })
///   inspect(result, content="2:two,1:one,")
/// ```
#locals(f)
pub fn[K, V] each(
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
///   let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
///   let mut result = 0
///   map.eachi((i, k, _) => { if k == "b" { result = i } })
///   // "b" is at index 1
///   inspect(result, content="2")
/// ```
#locals(f)
pub fn[K, V] eachi(
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
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   inspect(
///     map, 
///     content=(
///       #|HashMap::of([(2, "two"), (1, "one")])
///     ),
/// )
/// ```
pub impl[K : Show, V : Show] Show for HashMap[K, V] with output(self, logger) {
  logger.write_string("HashMap::of([")
  self.eachi((i, k, v) => {
    if i > 0 {
      logger.write_string(", ")
    }
    logger
    ..write_string("(")
    ..write_object(k)
    ..write_string(", ")
    ..write_object(v)
    ..write_string(")")
  })
  logger.write_string("])")
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
/// ```moonbit
///   let map = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
///   let keys = map.keys().to_array()
///   inspect(keys.length(), content="3")
///   inspect(keys.contains(1), content="true")
///   inspect(keys.contains(2), content="true")
///   inspect(keys.contains(3), content="true")
/// ```
pub fn[K, V] HashMap::keys(self : HashMap[K, V]) -> Iter[K] {
  Iter::new(yield_ => for entry in self.entries {
    if entry is Some({ key, .. }) {
      guard yield_(key) is IterContinue else { break IterEnd }
    }
  } else {
    IterContinue
  })
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
/// ```moonbit
///   let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
///   let values = map.values().to_array()
///   inspect(values.length(), content="3")
///   inspect(values.contains(1), content="true")
///   inspect(values.contains(2), content="true")
///   inspect(values.contains(3), content="true")
/// ```
pub fn[K, V] HashMap::values(self : HashMap[K, V]) -> Iter[V] {
  Iter::new(yield_ => for entry in self.entries {
    if entry is Some({ value, .. }) {
      guard yield_(value) is IterContinue else { break IterEnd }
    }
  } else {
    IterContinue
  })
}

///|
/// Retains only the key-value pairs that satisfy the given predicate function.
/// This method modifies the hash map in-place, removing all entries for which
/// the predicate returns `false`.
///
/// Parameters:
///
/// * `self` : The hash map to be filtered.
/// * `predicate` : A function that takes a key and value as arguments and returns
/// `true` if the key-value pair should be kept, `false` if it should be removed.
///
/// Example:
///
/// ```moonbit
///   let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3), ("d", 4)])
///   map.retain((_k, v) => v % 2 == 0)  // Keep only even values
///   inspect(map.size(), content="2")
///   inspect(map.get("a"), content="None")
///   inspect(map.get("b"), content="Some(2)")
///   inspect(map.get("c"), content="None")
///   inspect(map.get("d"), content="Some(4)")
/// ```
#locals(f)
pub fn[K, V] retain(self : HashMap[K, V], f : (K, V) -> Bool) -> Unit {
  let last = self.capacity - 1
  while self.entries[last] is Some(entry) && !f(entry.key, entry.value) {
    self.shift_back(last)
    self.size -= 1
  }
  for i = last - 1; i >= 0; i = i - 1 {
    if self.entries[i] is Some(entry) {
      if !f(entry.key, entry.value) {
        self.shift_back(i)
        self.size -= 1
      }
    }
  }
}
