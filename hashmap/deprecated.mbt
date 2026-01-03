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
/// Returns an internal iterator over the key-value pairs in the map.
#warnings("-deprecated")
#deprecated("Use `HashMap::iterator()` to get an external iterator.")
pub fn[K, V] HashMap::iter(self : HashMap[K, V]) -> Iter[(K, V)] {
  self.iterator().iter()
}

///|
/// Returns an internal iterator over the key-value pairs in the map.
#warnings("-deprecated")
#deprecated("Use `HashMap::iterator2()` to get an external iterator.")
pub fn[K, V] HashMap::iter2(self : HashMap[K, V]) -> Iter2[K, V] {
  self.iterator2().iter2()
}

///|
#warnings("-deprecated")
#deprecated("Use `HashMap::from_iterator()` with an external iterator.")
#as_free_fn
pub fn[K : Hash + Eq, V] HashMap::from_iter(
  iter : Iter[(K, V)],
) -> HashMap[K, V] {
  let m = new()
  iter.each(e => m[e.0] = e.1)
  m
}

///|
/// Returns an internal iterator over all keys in the hash map.
#warnings("-deprecated")
#deprecated("Use `HashMap::keys_iterator()` to get an external iterator.")
pub fn[K, V] HashMap::keys(self : HashMap[K, V]) -> Iter[K] {
  self.keys_iterator().iter()
}

///|
/// Returns an internal iterator over all values in the hash map.
#warnings("-deprecated")
#deprecated("Use `HashMap::values_iterator()` to get an external iterator.")
pub fn[K, V] HashMap::values(self : HashMap[K, V]) -> Iter[V] {
  self.values_iterator().iter()
}
