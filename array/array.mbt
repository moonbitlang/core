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
/// Zips two arrays into a single array by applying a function to each pair of elements.
///
/// Parameters:
///
/// * `l` : The first array.
/// * `r` : The second array.
/// * `merge` : A function that takes two arguments, one from each array, and returns a value.
///
/// Returns an array containing the results of applying the function to each pair of elements.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr1 = [1, 2, 3]
///   let arr2 = [4, 5, 6]
///   let add = (a, b) => a + b
///   inspect(@array.zip_with(arr1, arr2, add), content="[5, 7, 9]")
/// }
/// ```
pub fn[A, B, C] zip_with(
  l : Array[A],
  r : Array[B],
  merge : (A, B) -> C raise?,
) -> Array[C] raise? {
  let length = if l.length() < r.length() { l.length() } else { r.length() }
  Array::makei(length, i => merge(l[i], r[i]))
}
