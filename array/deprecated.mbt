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
/// Create a new array. Values are lazily built.
/// @alert deprecated "Use `FixedArray::makei` instead"
pub fn FixedArray::new[T](length : Int, value : () -> T) -> FixedArray[T] {
  if length <= 0 {
    []
  } else {
    let array = FixedArray::make(length, value())
    for i = 1; i < length; i = i + 1 {
      array[i] = value()
    }
    array
  }
}

///|
/// Create a new array. Values are built from indexes.
/// @alert deprecated "Use `FixedArray::makei` instead"
pub fn FixedArray::new_with_index[T](
  length : Int,
  value : (Int) -> T
) -> FixedArray[T] {
  FixedArray::makei(length, value)
}

///|
/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
/// @alert deprecated "Use `fold` instead"
pub fn fold_left[T, U](self : FixedArray[T], f : (U, T) -> U, init~ : U) -> U {
  self.fold(init~, f)
}

///|
/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
/// @alert deprecated "Use `rev_fold` instead"
pub fn fold_right[T, U](self : FixedArray[T], f : (U, T) -> U, init~ : U) -> U {
  self.rev_fold(init~, f)
}

///|
/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
/// @alert deprecated "Use `foldi` instead"
pub fn fold_lefti[T, U](
  self : FixedArray[T],
  f : (Int, U, T) -> U,
  init~ : U
) -> U {
  self.foldi(init~, f)
}

///|
/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
/// @alert deprecated "Use `rev_foldi` instead"
pub fn fold_righti[T, U](
  self : FixedArray[T],
  f : (Int, U, T) -> U,
  init~ : U
) -> U {
  let len = self.length()
  for i = len - 1, acc = init; i >= 0; {
    continue i - 1, f(len - i - 1, acc, self[i])
  } else {
    acc
  }
}
