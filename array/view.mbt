// Copyright 2024 International Digital Economy Academy
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
pub fn rev_inplace[T](self : ArrayView[T]) -> Unit {
  let mid_len = self.length() / 2
  for i = 0; i < mid_len; i = i + 1 {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

///|
/// Iterates over each element in the array view and applies a function to it.
///
/// Parameters:
///
/// * `self` : The array view to iterate over.
/// * `function` : A function that takes an element of type `T` and returns
/// nothing. This function will be applied to each element in the array view.
///
/// Example:
///
/// ```moonbit
/// test "array_view/each" {
///   let arr = [1, 2, 3][:]
///   let mut sum = 0
///   arr.each(fn(x) { sum = sum + x })
///   inspect!(sum, content="6")
/// }
/// ```
pub fn each[T](self : ArrayView[T], f : (T) -> Unit) -> Unit {
  for v in self {
    f(v)
  }
}

///|
/// Iterates over the elements of the array view with index.
///
/// # Example
/// 
/// ```
/// let v = [3, 4, 5][:]
/// let mut sum = 0
/// v.eachi(fn (i, x) { sum = sum + x + i })
/// assert_eq!(sum, 15)
/// ```
pub fn eachi[T](self : ArrayView[T], f : (Int, T) -> Unit) -> Unit {
  for i, v in self {
    f(i, v)
  }
}

///|
/// Checks if all elements in the array view match the condition.
/// 
/// # Example
/// 
/// ```
/// let v = [1, 4, 6, 8, 9]
/// assert_false!(v[:].all(fn(elem) { elem % 2 == 0 }))
/// assert_true!(v[1:4].all(fn(elem) { elem % 2 == 0 }))
/// ```
pub fn all[T](self : ArrayView[T], f : (T) -> Bool) -> Bool {
  for v in self {
    if not(f(v)) {
      return false
    }
  }
  true
}

///|
/// Check if any of the elements in the array view match the condition.
///
/// # Example
///
/// ```
/// let v = [1, 2, 3, 4, 5][:]
/// assert_true!(v.any(fn(ele) { ele < 6 }))
/// assert_false!(v.any(fn(ele) { ele < 1 }))
/// ```
pub fn any[T](self : ArrayView[T], f : (T) -> Bool) -> Bool {
  for v in self {
    if f(v) {
      return true
    }
  }
  false
}

///|
/// Checks if the array view contains an element.
///
/// # Example
/// ```
/// let v = [3, 4, 5][:]
/// assert_true!(v.contains(3))
/// ```
pub fn contains[T : Eq](self : ArrayView[T], value : T) -> Bool {
  for v in self {
    if v == value {
      break true
    }
  } else {
    false
  }
}
