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
/// Sorts the array in place.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 4, 3, 2, 1]
///   arr.sort()
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[T : Compare] Array::sort(self : Array[T]) -> Unit {
  fixed_quick_sort(self.mut_view(), None, fixed_get_limit(self.length()))
}
