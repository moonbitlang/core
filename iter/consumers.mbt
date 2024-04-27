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

/// Iterates over each element in the iterator, applying the function `f` to each element.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an element of type `T` and returns `Unit`. This function is applied to each element of the iterator.
/// @intrinsic %iter.iter
pub fn iter[T](self : Iter[T], f : (T) -> Unit) -> Unit {
  (self.0)(
    fn {
      yield => {
        f(yield)
        true
      }
    },
  )
  |> ignore
}

/// Folds the elements of the iterator using the given function, starting with the given initial value.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
/// - `B`: The type of the accumulator value.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an accumulator of type `B` and an element of type `T`, and returns a new accumulator value.
/// - `init`: The initial value for the fold operation.
///
/// # Returns
///
/// Returns the final accumulator value after folding all elements of the iterator.
/// @intrinsic %iter.reduce
pub fn fold[T, B](self : Iter[T], f : (B, T) -> B, init : B) -> B {
  let mut acc = init
  let _ = (self.0)(
    fn {
      yield => {
        acc = f(acc, yield)
        true
      }
    },
  )
  acc
}

/// Counts the number of elements in the iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
///
/// # Returns
///
/// Returns the number of elements in the iterator.
pub fn count[T](self : Iter[T]) -> Int {
  self.fold(fn { acc, _ => acc + 1 }, 0)
}

/// Calculates the sum of elements in the iterator.
///
/// Only available if the elements implements the `Default` trait and have the
/// `op_add()` function. The result is simply adding all elements sequentially
/// to the default value of the element type, which means the `sum()` of an
/// empty iterator is the default value itself.
///
/// # Examples
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// print(arr.as_iter().sum())  // output: 15
///
/// let empty_arr: Array[Int] = []
/// print(empty_arr.as_iter().sum())  // output: 0
/// ```
pub fn sum[T : Default + @math.Add](self : Iter[T]) -> T {
  self.fold(fn { acc, x => acc + x }, T::default())
}

/// Calculates the product of elements in the iterator.
///
/// Only available if the elements implements the `Unity` trait and have the
/// `op_mul()` function. The result is simply multiplying all elements
/// sequentially to the unity value of the element type, which means the
/// `product()` of an empty iterator is the unity value itself.
///
/// # Examples
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// print(arr.as_iter().product())  // output: 120
///
/// let empty_arr: Array[Int] = []
/// print(empty_arr.as_iter().product())  // output: 1
/// ```
pub fn product[T : @math.Unity + @math.Multiply](self : Iter[T]) -> T {
  self.fold(fn { acc, x => acc * x }, T::unity())
}
