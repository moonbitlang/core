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
#deprecated("Use `keys_iterator` instead. `keys` will return `Iterator[K]` instead of `Array[K]` in the future.")
#coverage.skip
pub fn[K, V] SortedMap::keys(self : SortedMap[K, V]) -> Array[K] {
  let keys = Array::new(capacity=self.size)
  self.each(fn(k, _v) { keys.push(k) })
  keys
}

///|
#deprecated("Use `values_iterator` instead. `values` will return `Iterator[V]` instead of `Array[V]` in the future.")
#coverage.skip
pub fn[K, V] SortedMap::values(self : SortedMap[K, V]) -> Array[V] {
  let values = Array::new(capacity=self.size)
  self.each(fn(_k, v) { values.push(v) })
  values
}

///|
#warnings("-deprecated")
#deprecated("Use `SortedMap::keys_iterator()` to get an external iterator.")
pub fn[K, V] SortedMap::keys_as_iter(self : SortedMap[K, V]) -> Iter[K] {
  self.keys_iterator().iter()
}

///|
#warnings("-deprecated")
#deprecated("Use `SortedMap::values_iterator()` to get an external iterator.")
pub fn[K, V] SortedMap::values_as_iter(self : SortedMap[K, V]) -> Iter[V] {
  self.values_iterator().iter()
}

///|
#warnings("-deprecated")
#deprecated("Use `SortedMap::iterator()` to get an external iterator.")
pub fn[K, V] SortedMap::iter(self : SortedMap[K, V]) -> Iter[(K, V)] {
  self.iterator().iter()
}

///|
#warnings("-deprecated")
#deprecated("Use `SortedMap::iterator2()` to get an external iterator.")
pub fn[K, V] SortedMap::iter2(self : SortedMap[K, V]) -> Iter2[K, V] {
  self.iterator2().iter2()
}

///|
#warnings("-deprecated")
#deprecated("Use `SortedMap::from_iterator()` with an external iterator.")
#as_free_fn
pub fn[K : Compare, V] SortedMap::from_iter(
  iter : Iter[(K, V)],
) -> SortedMap[K, V] {
  let m = new()
  iter.each(e => m[e.0] = e.1)
  m
}

///|
#warnings("-deprecated")
#deprecated("Use `SortedMap::range_iterator2()` to get an external iterator.")
pub fn[K : Compare, V] SortedMap::range(
  self : SortedMap[K, V],
  low : K,
  high : K,
) -> Iter2[K, V] {
  self.range_iterator2(low, high).iter2()
}
