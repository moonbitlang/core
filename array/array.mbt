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

/// Iterates over each element.
///
/// # Arguments
///
/// - `self`: The array to iterate over.
/// - `f`: The function to apply to each element.
///
/// # Example
///
/// ```
/// [1, 2, 3, 4, 5].iter(fn(x){ print("\(x) ") }) //output: 1 2 3 4 5
/// ```
pub fn iter[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

test "iter" {
  let mut i = 0
  let mut failed = false
  [1, 2, 3, 4, 5].iter(
    fn(elem) { if elem != i + 1 { failed = true }; i = i + 1 },
  )
  @assertion.assert_false(failed)?
}

/// Iterates over the array with index. 
///
/// # Arguments
///
/// - `self`: The array to iterate over.
/// - `f`: A function that takes an `Int` representing the index and a `T` representing the element of the array, and returns `Unit`.
///
/// # Example
///
/// ```
/// [1, 2, 3, 4, 5].iteri(fn(index, elem){
///   print("(\(index),\(elem)) ")
/// }) //output: (0,1) (1,2) (2,3) (3,4) (4,5)
/// ```
pub fn iteri[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(i, self[i])
  }
}

test "iteri" {
  let mut i = 0
  let mut failed = false
  [1, 2, 3, 4, 5].iteri(
    fn(index, elem) {
      if index != i || elem != i + 1 {
        failed = true
      }
      i = i + 1
    },
  )
  @assertion.assert_false(failed)?
}

pub fn iter_rev[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

test "iter rev" {
  let mut i = 6
  let mut failed = false
  [1, 2, 3, 4, 5].iter_rev(
    fn(elem) { if elem != i - 1 { failed = true }; i = i - 1 },
  )
  @assertion.assert_false(failed)?
}

pub fn iteri_rev[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(i, self[i])
  }
}

test "iteri_rev" {
  let mut i = 6
  let mut failed = false
  [1, 2, 3, 4, 5].iteri_rev(
    fn(index, elem) {
      if index != i - 2 || elem != i - 1 {
        failed = true
      }
      i = i - 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Applies a function to each element of the array and returns a new array with the results.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// let doubled = arr.map(fn(x){ x * 2 })
/// debug(doubled) //output: [2, 4, 6, 8, 10]
/// ```
pub fn map[T, U](self : Array[T], f : (T) -> U) -> Array[U] {
  if self.length() == 0 {
    return Array::default()
  }
  let res = Array::make(self.length(), f(self[0]))
  for i = 1; i < self.length(); i = i + 1 {
    res[i] = f(self[i])
  }
  res
}

test "map" {
  let arr = [1, 2, 3, 4, 5]
  let doubled = arr.map(fn(x) { x * 2 })
  let empty : Array[Unit] = Array::default().map(fn(x) { x })
  @assertion.assert_eq(empty, [])?
  @assertion.assert_eq(doubled, [2, 4, 6, 8, 10])?
}

pub fn map_with_index[T, U](self : Array[T], f : (T, Int) -> U) -> Array[U] {
  if self.length() == 0 {
    return Array::default()
  }
  let res = Array::make(self.length(), f(self[0], 0))
  for i = 1; i < self.length(); i = i + 1 {
    res[i] = f(self[i], i)
  }
  res
}

test "map with index" {
  let arr = [1, 2, 3, 4, 5]
  let doubled = arr.map_with_index(fn(x, i) { x * 2 + i })
  let empty : Array[Int] = Array::default().map_with_index(fn(x, i) { x + i })
  @assertion.assert_eq(empty, [])?
  @assertion.assert_eq(doubled, [2, 5, 8, 11, 14])?
}

pub fn op_equal[T : Eq](self : Array[T], that : Array[T]) -> Bool {
  if self.length() != that.length() {
    return false
  }
  for i = 0; i < self.length(); i = i + 1 {
    if self[i] != that[i] {
      return false
    }
  }
  true
}

/// Create a new array. Values are lazily built.
pub fn new[T](length : Int, value : () -> T) -> Array[T] {
  if length <= 0 {
    Array::default()
  } else {
    let array = Array::make(length, value())
    for i = 1; i < length; i = i + 1 {
      array[i] = value()
    }
    array
  }
}

test "new" {
  let arr = new(2, fn() { { val: 1 } })
  @assertion.assert_is_not(arr[0], arr[1])?
}

/// Create a new array. Values are built from indexes.
pub fn new_with_index[T](length : Int, value : (Int) -> T) -> Array[T] {
  if length <= 0 {
    Array::default()
  } else {
    let array = Array::make(length, value(0))
    for i = 1; i < length; i = i + 1 {
      array[i] = value(i)
    }
    array
  }
}

test "new index" {
  let arr = new_with_index(2, fn { i => i })
  @assertion.assert_eq(arr[0], 0)?
  @assertion.assert_eq(arr[1], 1)?
}

/// Create a new array with given values.
pub fn Array::from_array[T](array : Array[T]) -> Array[T] {
  array
}

test "from_array" {
  let array = Array::[1, 2, 3, 4, 5]
  @assertion.assert_eq(array, [1, 2, 3, 4, 5])?
}

pub fn fold[T, U](self : Array[T], f : (T, U) -> U, init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1,
      f(self[i], acc)
  } else {
    acc
  }
}

test "fold" {
  let sum = [1, 2, 3, 4, 5].fold(fn(elem, sum : Int) { sum + elem }, 0)
  @assertion.assert_eq(sum, 15)?
}
