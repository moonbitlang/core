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
/// Sorts the array with a key extraction function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by_key((x) => {-x})
///   assert_eq(arr, [5, 4, 3, 2, 1])
/// ```
pub fn[T, K : Compare] Array::sort_by_key(
  self : Array[T],
  map : (T) -> K,
) -> Unit {
  self.mut_view().sort_by_key(map)
}

///|
/// Sorts the array with a custom comparison function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by((a, b) => { a - b })
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[T] Array::sort_by(self : Array[T], cmp : (T, T) -> Int) -> Unit {
  self.mut_view().sort_by(cmp)
}

///|
/// Sorts the array with a key extraction function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by_key((x) => {-x})
///   assert_eq(arr, [5, 4, 3, 2, 1])
/// ```
pub fn[T, K : Compare] FixedArray::sort_by_key(
  self : FixedArray[T],
  map : (T) -> K,
) -> Unit {
  self.mut_view().sort_by_key(map)
}

///|
test "@array.sort_by_key/basic" {
  let arr : FixedArray[_] = [3, 1, 4, 1, 5]
  arr.sort_by_key(x => x)
  inspect(arr, content="[1, 1, 3, 4, 5]")
  let arr2 : FixedArray[_] = [3, 1, 4, 1, 5]
  arr2.sort_by_key(x => -x)
  inspect(arr2, content="[5, 4, 3, 1, 1]")
}

///|
/// Sorts the array with a custom comparison function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by((a, b) => { a - b })
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[T] FixedArray::sort_by(
  self : FixedArray[T],
  cmp : (T, T) -> Int,
) -> Unit {
  self.mut_view().sort_by(cmp)
}

///|
test "sort_by: basic functionality" {
  let arr : FixedArray[_] = [5, 3, 2, 4, 1]
  arr.sort_by((a, b) => a - b)
  inspect(arr, content="[1, 2, 3, 4, 5]")
}

///|
test "sort_by: edge cases" {
  let empty_arr : FixedArray[Int] = []
  empty_arr.sort_by((a, b) => a - b)
  inspect(empty_arr, content="[]")
  let single_element_arr : FixedArray[_] = [1]
  single_element_arr.sort_by((a, b) => a - b)
  inspect(single_element_arr, content="[1]")
}

///|
test "sort_by: random cases" {
  let random_arr1 : FixedArray[_] = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
  random_arr1.sort_by((a, b) => a - b)
  inspect(random_arr1, content="[1, 1, 2, 3, 3, 4, 5, 5, 5, 6, 9]")
  let random_arr2 : FixedArray[_] = [7, 1, 8, 2, 8, 1, 8, 2, 8, 4, 5, 9]
  random_arr2.sort_by((a, b) => a - b)
  inspect(random_arr2, content="[1, 1, 2, 2, 4, 5, 7, 8, 8, 8, 8, 9]")
  let random_arr3 : FixedArray[_] = [10, -1, 0, 10, -1, 0, 10, -1, 0]
  random_arr3.sort_by((a, b) => a - b)
  inspect(random_arr3, content="[-1, -1, -1, 0, 0, 0, 10, 10, 10]")
}

///|
test "sort_by: large array" {
  let large_arr = FixedArray::makei(1000, i => 1000 - i)
  large_arr.sort_by((a, b) => a - b)
  let expected = FixedArray::makei(1000, i => i + 1)
  inspect(large_arr, content=expected.to_string())
}

///|
test "sort_by: negative numbers" {
  let negative_arr : FixedArray[_] = [-5, -3, -2, -4, -1]
  negative_arr.sort_by((a, b) => a - b)
  inspect(negative_arr, content="[-5, -4, -3, -2, -1]")
}

///|
test "sort_by: mixed positive and negative numbers" {
  let mixed_arr : FixedArray[_] = [-5, 3, -2, 4, -1]
  mixed_arr.sort_by((a, b) => a - b)
  inspect(mixed_arr, content="[-5, -2, -1, 3, 4]")
}
