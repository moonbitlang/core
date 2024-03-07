// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

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
pub fn iter[T](self : Array[T], f : (T) -> Unit) {
  let mut i = 0
  while i < self.length() {
    f(self[i])
    i = i + 1
  }
}

test "iter" {
  let mut i = 0
  let mut failed = false
  [1, 2, 3, 4, 5].iter(
    fn(elem) { 
      if elem != i + 1 { failed = true }
      i = i + 1
    }
  )
  if failed { return Err("iter test failed") }
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
pub fn iteri[T](self : Array[T], f : (Int, T) -> Unit) {
  let mut i = 0
  while i < self.length() {
    f(i, self[i])
    i = i + 1
  }
}

test "iteri" {
  let mut i = 0
  let mut failed = false
  [1, 2, 3, 4, 5].iteri(
    fn(index, elem) {
      if index != i || elem != i + 1 { failed = true } 
      i = i + 1
    },
  )
  if failed { return Err("iteri test failed") }
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
  let res = Array::make(self.length(), f(self[0]))
  let mut i = 0
  while i < self.length() {
    res[i] = f(self[i])
    i = i + 1
  }
  res
}

test "map" {
  let arr = [1, 2, 3, 4, 5]
  let doubled = arr.map(fn(x) { x * 2 })
  @assertion.assert_eq(doubled, [2, 4, 6, 8, 10])?
}

pub fn map_with_index[T, U](self : Array[T], f : (T, Int) -> U) -> Array[U] {
  let res = Array::make(self.length(), f(self[0], 0))
  loop 1 {
    i => if i < self.length() {
      res[i] = f(self[i], i)
      continue i + 1
    }
  }
  res
}

test "map with index" {
  let arr = [1, 2, 3, 4, 5]
  let doubled = arr.map_with_index(fn(x, i) { x * 2 + i })
  @assertion.assert_eq(doubled, [2, 5, 8, 11, 14])?
}

pub fn op_equal[T : Eq](self : Array[T], that : Array[T]) -> Bool {
  if self.length() != that.length() {
    return false
  }
  let mut i = 0
  while i < self.length() {
    if self[i] != that[i] {
      return false
    }
    i = i + 1
  }
  true
}

/// Create a new array. Values are lazily built.
pub fn new[T](length : Int, value : () -> T) -> Array[T] {
  if length <= 0 {
    Array::default()
  } else {
    let array = Array::make(length, value())
    loop 1 {
      i => if i < length {
        array[i] = value()
        continue i + 1
      }
    }
    array
  }
}

test "new" {
  let arr = new(2, fn() { { val: 1 } })
  @assertion.assert_false(arr[0] === arr[1])?
}

/// Create a new array. Values are built from indexes.
pub fn new_with_index[T](length : Int, value : (Int) -> T) -> Array[T] {
  if length <= 0 {
    Array::default()
  } else {
    let array = Array::make(length, value(0))
    loop 1 {
      i => if i < length {
        array[i] = value(i)
        continue i + 1
      }
    }
    array
  }
}

test "new index" {
  let arr = new_with_index(2, fn { i => i })
  @assertion.assert_eq(arr[0], 0)?
  @assertion.assert_eq(arr[1], 1)?
}
