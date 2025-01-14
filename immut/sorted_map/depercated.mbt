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
/// @alert deprecated "Use `add` instead"
/// @coverage.skip
pub fn insert[K : Compare, V](self : T[K, V], key : K, value : V) -> T[K, V] {
  self.add(key, value)
}

///|
/// @alert deprecated "use `@immut/sorted_map.new` instead"
/// @coverage.skip
pub fn T::new[K, V]() -> T[K, V] {
  Empty
}

///|
/// @alert deprecated "use `@immut/sorted_map.singleton` instead"
/// @coverage.skip
pub fn T::singleton[K, V](key : K, value : V) -> T[K, V] {
  singleton(key, value)
}

///|
/// @alert deprecated "use `@immut/sorted_map.from_array` instead"
/// @coverage.skip
pub fn T::from_array[K : Compare, V](array : Array[(K, V)]) -> T[K, V] {
  from_array(array)
}

///|
/// @alert deprecated "use `@immut/sorted_map.from_iter` instead"
/// @coverage.skip
pub fn T::from_iter[K : Compare, V](iter : Iter[(K, V)]) -> T[K, V] {
  from_iter(iter)
}

///|
/// @alert deprecated "use `@immut/sorted_map.of` instead"
/// @coverage.skip
pub fn T::of[K : Compare, V](array : FixedArray[(K, V)]) -> T[K, V] {
  of(array)
}

///|
/// @alert deprecated "use `@immut/sorted_map.from_json` instead"
/// @coverage.skip
pub fn T::from_json[V : @json.FromJson](
  json : Json
) -> T[String, V]!@json.JsonDecodeError {
  @json.from_json!(json)
}
