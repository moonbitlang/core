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
/// Ts over the values in the map.
#deprecated("Use `map_with_key` instead. `map` will accept `(K, X) -> Y` in the future.")
#coverage.skip
pub fn[K, X, Y] SortedMap::map(
  self : SortedMap[K, X],
  f : (X) -> Y,
) -> SortedMap[K, Y] {
  self.map_with_key((_, value) => f(value))
}

///|
/// Fold the values in the map.
/// O(n).
#deprecated("Use `foldl_with_key` instead. `fold` will accept `(A, K, V) -> A` in the future.")
pub fn[K, V, A] SortedMap::fold(
  self : SortedMap[K, V],
  init~ : A,
  f : (A, V) -> A,
) -> A {
  self.foldl_with_key((acc, _k, v) => f(acc, v), init~)
}

///|
/// Return all keys of the map in ascending order.
#deprecated("Use `keys_iterator` instead. `keys` will return `Iterator[K]` instead of `Array[K]` in the future.")
#coverage.skip
pub fn[K, V] SortedMap::keys(self : SortedMap[K, V]) -> Array[K] {
  self.iterator().map(p => p.0).collect()
}

///|
#deprecated("Use `values_iterator` instead")
#coverage.skip
pub fn[K, V] SortedMap::elems(self : SortedMap[K, V]) -> Array[V] {
  self.values_iterator().collect()
}

///|
/// Filter values that satisfy the predicate
#deprecated("Use `filter_with_key` instead. `filter` will accept `(K, V) -> Bool` in the future.")
#coverage.skip
pub fn[K, V] SortedMap::filter(
  self : SortedMap[K, V],
  pred : (V) -> Bool raise?,
) -> SortedMap[K, V] raise? {
  self.filter_with_key((_, v) => pred(v))
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
  iter.fold(init=new(), (m, e) => m.add(e.0, e.1))
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
pub fn[K, V] SortedMap::values(self : SortedMap[K, V]) -> Iter[V] {
  self.values_iterator().iter()
}
