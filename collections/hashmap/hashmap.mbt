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

/// Create new hash map.
pub fn HashMap::new[K, V](~hasher : Option[(K) -> Int] = None) -> HashMap[K, V] {
  HashMap(@robinhood_hash.new(~hasher))
}

/// Create new hash map from array.
pub fn HashMap::from_array[K : Hash + Eq, V](
  arr : Array[(K, V)]
) -> HashMap[K, V] {
  HashMap(@robinhood_hash.from_array(arr))
}

/// Set a key-value pair into hash map.
/// @alert unsafe "Panic if the hash map is full."
pub fn set[K : Hash + Eq, V](self : HashMap[K, V], key : K, value : V) -> Unit {
  self.0.set(key, value)
}

pub fn op_set[K : Hash + Eq, V](
  self : HashMap[K, V],
  key : K,
  value : V
) -> Unit {
  self.0[key] = value
}

/// Get the value associated with a key.
pub fn get[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Option[V] {
  self.0.get(key)
}

pub fn op_get[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Option[V] {
  self.0[key]
}

/// Get the value associated with a key, 
/// returns the provided default value if the key does not exist.
pub fn get_or_default[K : Hash + Eq, V](
  self : HashMap[K, V],
  key : K,
  default : V
) -> V {
  self.0.get_or_default(key, default)
}

/// Check if the hash map contains a key.
pub fn contains[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Bool {
  self.0.contains(key)
}

/// Remove a key-value pair from hash map.
pub fn remove[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Unit {
  self.0.remove(key)
}

/// Get the number of key-value pairs in the map.
pub fn size[K, V](self : HashMap[K, V]) -> Int {
  self.0.size()
}

/// Get the capacity of the map.
pub fn capacity[K, V](self : HashMap[K, V]) -> Int {
  self.0.capacity()
}

/// Check if the hash map is empty.
pub fn is_empty[K, V](self : HashMap[K, V]) -> Bool {
  self.0.is_empty()
}

// Iterate over all key-value pairs of the map.
pub fn iter[K, V](self : HashMap[K, V], f : (K, V) -> Unit) -> Unit {
  self.0.iter(f)
}

// Iterate over all key-value pairs of the map, with index.
pub fn iteri[K, V](self : HashMap[K, V], f : (Int, K, V) -> Unit) -> Unit {
  self.0.iteri(f)
}

// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn clear[K, V](self : HashMap[K, V]) -> Unit {
  self.0.clear()
}
