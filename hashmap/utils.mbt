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

fn debug_entries[K : Show, V : Show](self : HashMap[K, V]) -> String {
  for s = "", i = 0; i < self.entries.length(); {
    let s = if i > 0 { s + "," } else { s }
    match self.entries[i] {
      None => continue s + "_", i + 1
      Some({ psl, key, value, .. }) =>
        continue s + "(\(psl),\(key),\(value))", i + 1
    }
  } else {
    s
  }
}

/// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn clear[K, V](self : HashMap[K, V]) -> Unit {
  self.entries.fill(None)
  self.size = 0
}

/// Returns an iterator of the map.
pub fn as_iter[K, V](self : HashMap[K, V]) -> @iter.Iter[(K, V)] {
  @iter.Iter::_unstable_internal_make(
    fn(yield) {
      for i = 0, len = self.entries.length(); i < len; i = i + 1 {
        match self.entries[i] {
          Some({ key, value, .. }) =>
            if yield((key, value)).not() {
              break false
            }
          None => continue
        }
      } else {
        true
      }
    },
  )
}

/// Converts the map to an array.
pub fn to_array[K, V](self : HashMap[K, V]) -> Array[(K, V)] {
  let arr = []
  for i = 0, len = self.entries.length(); i < len; i = i + 1 {
    match self.entries[i] {
      Some({ key, value, .. }) => arr.push((key, value))
      None => continue
    }
  }
  arr
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

/// Iterate over all key-value pairs of the map.
pub fn iter[K, V](self : HashMap[K, V], f : (K, V) -> Unit) -> Unit {
  for i = 0; i < self.capacity; i = i + 1 {
    match self.entries[i] {
      Some({ key, value, .. }) => f(key, value)
      None => ()
    }
  }
}

/// Iterate over all key-value pairs of the map, with index.
pub fn iteri[K, V](self : HashMap[K, V], f : (Int, K, V) -> Unit) -> Unit {
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
