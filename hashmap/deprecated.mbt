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
/// Creates a new empty hash map with the specified capacity. This is a
/// deprecated static method of type `T`.
///
/// Parameters:
///
/// * `capacity` : The initial capacity of the hash map. Must be a positive
/// integer. The actual capacity will be rounded up to the nearest power of 2
/// that is greater than or equal to this value. Defaults to 8 if not specified.
///
/// Returns a new empty hash map of type `T[K, V]` where `K` is the key type and
/// `V` is the value type.
///
/// Example:
///
/// ```moonbit
/// test "T::new" {
///   let map : @hashmap.T[String, Int] = @hashmap.new()
///   inspect!(map.size(), content="0")
///   inspect!(map.capacity(), content="8")
/// }
/// ```
///
/// @alert deprecated "use `@hashmap.new` instead"
/// @coverage.skip
pub fn T::new[K, V](capacity~ : Int = 8) -> T[K, V] {
  new(capacity~)
}

///|
/// Creates a new hash map from an array of key-value pairs.
///
/// Parameters:
///
/// * `arr` : An array of tuples, where each tuple contains a key and its
/// corresponding value.
///  * Keys must implement both `Hash` and `Eq` traits
///  * Values can be of any type
///
/// Returns a new hash map containing all the key-value pairs from the array.
///
/// Example:
///
/// ```moonbit
/// test "T::from_array" {
///   let map = @hashmap.from_array([(1, "one"), (2, "two")])
///   inspect!(map.get(1), content="Some(\"one\")")
///   inspect!(map.get(2), content="Some(\"two\")")
/// }
/// ```
///
/// @alert deprecated "use `@hashmap.from_array` instead"
/// @coverage.skip
pub fn T::from_array[K : Hash + Eq, V](arr : Array[(K, V)]) -> T[K, V] {
  from_array(arr)
}

///|
/// Creates a new hash map from a fixed array of key-value pairs.
///
/// Parameters:
///
/// * `arr` : A fixed array of key-value pairs. Each pair contains a hashable and
/// equatable key of type `K` and a value of type `V`.
///
/// Returns a new hash map containing all key-value pairs from the input array.
///
/// Example:
///
/// ```moonbit
/// test "T::of" {
///   let map = @hashmap.of([(1, "one"), (2, "two")])
///   inspect!(map.get(1), content="Some(\"one\")")
///   inspect!(map.get(2), content="Some(\"two\")")
/// }
/// ```
///
/// @alert deprecated "use `@hashmap.of` instead"
/// @coverage.skip
pub fn T::of[K : Eq + Hash, V](arr : FixedArray[(K, V)]) -> T[K, V] {
  of(arr)
}
