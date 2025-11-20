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
  fixed_quick_sort_by(
    self.mut_view(),
    (a, b) => map(a).compare(map(b)),
    None,
    fixed_get_limit(self.length()),
  )
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
  fixed_quick_sort_by(
    self.mut_view(),
    cmp,
    None,
    fixed_get_limit(self.length()),
  )
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
///   arr.mut_view().sort_by_key((x) => {-x})
///   assert_eq(arr, [5, 4, 3, 2, 1])
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

///|
/// Sorts the array with a custom comparison function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 3, 2, 4, 1]
///   arr.mut_view().sort_by((a, b) => { a - b })
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[T] MutArrayView::sort_by(self : Self[T], cmp : (T, T) -> Int) -> Unit {
  fixed_quick_sort_by(self, cmp, None, fixed_get_limit(self.length()))
}
