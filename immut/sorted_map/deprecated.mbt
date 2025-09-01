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
/// Create a new map with a key-value pair inserted.
/// O(log n).
///
#deprecated("Use `add` instead")
#coverage.skip
pub fn[K : Compare, V] insert(
  self : SortedMap[K, V],
  key : K,
  value : V,
) -> SortedMap[K, V] {
  self.add(key, value)
}

///|
#deprecated("use `@immut/sorted_map.new` instead")
#coverage.skip
pub fn[K, V] SortedMap::new() -> SortedMap[K, V] {
  Empty
}

///|
#deprecated("use `@immut/sorted_map.singleton` instead")
#coverage.skip
pub fn[K, V] SortedMap::singleton(key : K, value : V) -> SortedMap[K, V] {
  singleton(key, value)
}

///|
#deprecated("use `@immut/sorted_map.from_array` instead")
#coverage.skip
pub fn[K : Compare, V] SortedMap::from_array(
  array : Array[(K, V)],
) -> SortedMap[K, V] {
  from_array(array)
}

///|
#deprecated("use `@immut/sorted_map.from_iter` instead")
#coverage.skip
pub fn[K : Compare, V] SortedMap::from_iter(
  iter : Iter[(K, V)],
) -> SortedMap[K, V] {
  from_iter(iter)
}

///|
#deprecated("use `@immut/sorted_map.of` instead")
#coverage.skip
pub fn[K : Compare, V] SortedMap::of(
  array : FixedArray[(K, V)],
) -> SortedMap[K, V] {
  of(array)
}

///|
#deprecated("use `@immut/sorted_map.from_json` instead")
#coverage.skip
pub fn[V : @json.FromJson] SortedMap::from_json(
  json : Json,
) -> SortedMap[String, V] raise @json.JsonDecodeError {
  @json.from_json(json)
}
