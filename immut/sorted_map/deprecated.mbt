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
/// Create an empty map.
#deprecated("Use `new()` instead")
#coverage.skip
pub fn[K, V] SortedMap::empty() -> SortedMap[K, V] {
  Empty
}

///|
/// Get the value associated with a key.
/// O(log n).
#deprecated("Use `get` instead")
#coverage.skip
pub fn[K : Compare, V] lookup(self : SortedMap[K, V], key : K) -> V? {
  self.get(key)
}

///|
/// Ts over the values in the map.
#deprecated("Use `map_with_key` instead. `map` will accept `(K, X) -> Y` in the future.")
#coverage.skip
pub fn[K, X, Y] map(self : SortedMap[K, X], f : (X) -> Y) -> SortedMap[K, Y] {
  match self {
    Empty => Empty
    Tree(k, value~, size~, l, r) =>
      Tree(k, value=f(value), size~, l.map(f), r.map(f))
  }
}

///|
/// Fold the values in the map.
/// O(n).
#deprecated("Use `foldl_with_key` instead. `fold` will accept `(A, K, V) -> A` in the future.")
pub fn[K, V, A] fold(self : SortedMap[K, V], init~ : A, f : (A, V) -> A) -> A {
  self.foldl_with_key((acc, _k, v) => f(acc, v), init~)
}

///|
/// Return all keys of the map in ascending order.
#deprecated("Use `keys_as_iter` instead. `keys` will return `Iter[K]` instead of `Array[K]` in the future.")
#coverage.skip
pub fn[K, V] keys(self : SortedMap[K, V]) -> Array[K] {
  self.iter().map(p => p.0).collect()
}

///|
#deprecated("Use `values` instead")
#coverage.skip
pub fn[K, V] elems(self : SortedMap[K, V]) -> Array[V] {
  self.values().collect()
}

///|
/// Filter values that satisfy the predicate
#deprecated("Use `filter_with_key` instead. `filter` will accept `(K, V) -> Bool` in the future.")
#coverage.skip
pub fn[K, V] filter(
  self : SortedMap[K, V],
  pred : (V) -> Bool raise?,
) -> SortedMap[K, V] raise? {
  self.filter_with_key((_, v) => pred(v))
}

///|
#deprecated("Use `SortedMap` instead of `T`")
pub typealias SortedMap as T
