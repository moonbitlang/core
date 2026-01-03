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

// #region MutArrayView

///|
/// Sorts the array with a custom comparison function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [5, 3, 2, 4, 1]
///   arr.mut_view().sort_by((a, b) => a - b)
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[T] MutArrayView::sort_by(self : Self[T], cmp : (T, T) -> Int) -> Unit {
  fixed_quick_sort_by(self, cmp, None, fixed_get_limit(self.length()))
}

///|
/// Sorts the array in place.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [5, 4, 3, 2, 1]
///   arr.mut_view().sort()
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[T : Compare] MutArrayView::sort(self : MutArrayView[T]) -> Unit {
  fixed_quick_sort(self, None, fixed_get_limit(self.length()))
}

///|
/// Sorts the array
/// 
/// It's an stable sort(it will not reorder equal elements). The time complexity is *O*(*n* \* log(*n*)) in the worst case.
/// 
/// # Example
/// 
/// ```mbt check
/// test {
///   let arr : FixedArray[Int] = [5, 4, 3, 2, 1]
///   arr.mut_view().stable_sort()
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[T : Compare] MutArrayView::stable_sort(self : MutArrayView[T]) -> Unit {
  timsort(self)
}

///|
/// Sorts the array with a key extraction function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [5, 3, 2, 4, 1]
///   arr.mut_view().sort_by_key(x => -x)
///   assert_eq(arr, [5, 4, 3, 2, 1])
/// }
/// ```
pub fn[T, K : Compare] MutArrayView::sort_by_key(
  self : Self[T],
  map : (T) -> K,
) -> Unit {
  fixed_quick_sort_by(
    self,
    (a, b) => map(a).compare(map(b)),
    None,
    fixed_get_limit(self.length()),
  )
}

// #endregion

// #region ArrayView

///|
/// Tests whether the array view is sorted in ascending order.
///
/// Parameters:
///
/// * `self` : The array view to be tested.
/// * `T` : The type of elements in the array view. Must implement the `Compare`
/// trait.
///
/// Returns a boolean value indicating whether the array view is sorted in ascending
/// order:
///
/// * `true` if the array view is empty, contains only one element, or all elements
/// are in ascending order.
/// * `false` if any element is greater than the element that follows it.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4]
///   inspect(view.is_sorted(), content="true")
///   let descending = [5, 4, 3, 2, 1]
///   inspect(descending[:].is_sorted(), content="false")
/// }
/// ```
pub fn[T : Compare] ArrayView::is_sorted(self : ArrayView[T]) -> Bool {
  for i in 1..<self.length() {
    if self[i - 1] > self[i] {
      break false
    }
  } else {
    true
  }
}

// #endregion

// #region Array

///|
/// Tests whether the array is sorted in ascending order.
///
/// Parameters:
///
/// * `self` : The array to be tested.
/// * `T` : The type of elements in the array. Must implement the `Compare`
/// trait.
///
/// Returns a boolean value indicating whether the array is sorted in ascending
/// order:
///
/// * `true` if the array is empty, contains only one element, or all elements
/// are in ascending order.
/// * `false` if any element is greater than the element that follows it.
///
/// Example:
///
/// ```mbt check
/// test {
///   let ascending = [1, 2, 3, 4, 5]
///   let descending = [5, 4, 3, 2, 1]
///   let unsorted = [1, 3, 2, 4, 5]
///   inspect(ascending.is_sorted(), content="true")
///   inspect(descending.is_sorted(), content="false")
///   inspect(unsorted.is_sorted(), content="false")
/// }
/// ```
pub fn[T : Compare] Array::is_sorted(self : Array[T]) -> Bool {
  self[:].is_sorted()
}

///|
/// Sorts the array in place.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [5, 4, 3, 2, 1]
///   arr.sort()
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[T : Compare] Array::sort(self : Array[T]) -> Unit {
  self.mut_view().sort()
}

///|
/// Sorts the array with a key extraction function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by_key(x => -x)
///   assert_eq(arr, [5, 4, 3, 2, 1])
/// }
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
/// ```mbt check
/// test {
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by((a, b) => a - b)
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[T] Array::sort_by(self : Array[T], cmp : (T, T) -> Int) -> Unit {
  self.mut_view().sort_by(cmp)
}

// #endregion

// #region FixedArray

///|
/// Checks if the elements in the array are sorted in ascending order according
/// to their natural ordering.
///
/// Parameters:
///
/// * `array` : A fixed array of type `T`, where `T` must implement the `Compare`
/// trait.
///
/// Returns `true` if the array is sorted in ascending order, `false` otherwise.
/// An empty array or an array with a single element is considered sorted.
///
/// Example:
///
/// ```mbt check
/// test {
///   let sorted : FixedArray[Int] = [1, 2, 3, 4, 5]
///   let unsorted : FixedArray[Int] = [5, 4, 3, 2, 1]
///   inspect(FixedArray::is_sorted(sorted), content="true")
///   inspect(FixedArray::is_sorted(unsorted), content="false")
/// }
/// ```
pub fn[T : Compare] FixedArray::is_sorted(arr : FixedArray[T]) -> Bool {
  arr[:].is_sorted()
}

///|
/// Sorts the array
/// 
/// It's a stable sort(it will not reorder equal elements). The time complexity is *O*(*n* \* log(*n*)) in the worst case.
/// 
/// # Example
/// 
/// ```mbt check
/// test {
///   let arr : FixedArray[Int] = [5, 4, 3, 2, 1]
///   arr.stable_sort()
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[T : Compare] FixedArray::stable_sort(self : FixedArray[T]) -> Unit {
  self.mut_view().stable_sort()
}

///|
/// Sorts the array with a key extraction function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by_key(x => -x)
///   assert_eq(arr, [5, 4, 3, 2, 1])
/// }
/// ```
pub fn[T, K : Compare] FixedArray::sort_by_key(
  self : FixedArray[T],
  map : (T) -> K,
) -> Unit {
  self.mut_view().sort_by_key(map)
}

///|
test "FixedArray::sort_by_key/basic" {
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
/// ```mbt check
/// test {
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by((a, b) => a - b)
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[T] FixedArray::sort_by(
  self : FixedArray[T],
  cmp : (T, T) -> Int,
) -> Unit {
  self.mut_view().sort_by(cmp)
}

///|
test "FixedArray::sort_by: basic functionality" {
  let arr : FixedArray[_] = [5, 3, 2, 4, 1]
  arr.sort_by((a, b) => a - b)
  inspect(arr, content="[1, 2, 3, 4, 5]")
}

///|
test "FixedArray::sort_by: edge cases" {
  let empty_arr : FixedArray[Int] = []
  empty_arr.sort_by((a, b) => a - b)
  inspect(empty_arr, content="[]")
  let single_element_arr : FixedArray[_] = [1]
  single_element_arr.sort_by((a, b) => a - b)
  inspect(single_element_arr, content="[1]")
}

///|
test "FixedArray::sort_by: random cases" {
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
test "FixedArray::sort_by: large array" {
  let large_arr = FixedArray::makei(1000, i => 1000 - i)
  large_arr.sort_by((a, b) => a - b)
  let expected = FixedArray::makei(1000, i => i + 1)
  inspect(large_arr, content=expected.to_string())
}

///|
test "FixedArray::sort_by: negative numbers" {
  let negative_arr : FixedArray[_] = [-5, -3, -2, -4, -1]
  negative_arr.sort_by((a, b) => a - b)
  inspect(negative_arr, content="[-5, -4, -3, -2, -1]")
}

///|
test "FixedArray::sort_by: mixed positive and negative numbers" {
  let mixed_arr : FixedArray[_] = [-5, 3, -2, 4, -1]
  mixed_arr.sort_by((a, b) => a - b)
  inspect(mixed_arr, content="[-5, -2, -1, 3, 4]")
}

// #endregion
