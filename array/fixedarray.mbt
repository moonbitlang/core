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
/// [1, 2, 3, 4, 5].each(fn(x){ print("\(x) ") }) //output: 1 2 3 4 5
/// ```
/// TODO: change the intrinsic to match the function name
/// @intrinsic %fixedarray.iter
pub fn each[T](self : FixedArray[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

test "each" {
  let mut i = 0
  let mut failed = false
  let f = fn(elem) {
    if elem != i + 1 {
      failed = true
    }
    i = i + 1
  }
  {
    i = 0
    ([] : FixedArray[_]).each(f)
    @test.is_false!(failed)
    @test.eq!(i, 0)
  }
  {
    i = 0
    ([1] : FixedArray[_]).each(f)
    @test.is_false!(failed)
    @test.eq!(i, 1)
  }
  i = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).each(f)
  @test.is_false!(failed)
  @test.eq!(i, 5)
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
/// [1, 2, 3, 4, 5].eachi(fn(index, elem){
///   print("(\(index),\(elem)) ")
/// }) //output: (0,1) (1,2) (2,3) (3,4) (4,5)
/// ```
pub fn eachi[T](self : FixedArray[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(i, self[i])
  }
}

test "eachi" {
  let mut i = 0
  let mut failed = false
  let f = fn(index, elem) {
    if index != i || elem != i + 1 {
      failed = true
    }
    i = i + 1
  }
  {
    i = 0
    ([] : FixedArray[_]).eachi(f)
    @test.is_false!(failed)
    @test.eq!(i, 0)
  }
  {
    i = 0
    ([1] : FixedArray[_]).eachi(f)
    @test.is_false!(failed)
    @test.eq!(i, 1)
  }
  i = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).eachi(f)
  @test.is_false!(failed)
  @test.eq!(i, 5)
}

/// Iterates over each element in reversed turn.
///
/// # Arguments
///
/// - `self`: The array to iterate over.
/// - `f`: The function to apply to each element.
///
/// # Example
///
/// ```
/// [1, 2, 3, 4, 5].each(fn(x){ print("\(x) ") }) //output: 5 4 3 2 1
/// ```
pub fn rev_each[T](self : FixedArray[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

test "rev_each" {
  let mut i = 6
  let mut failed = false
  let f = fn(elem) {
    if elem != i - 1 {
      failed = true
    }
    i = i - 1
  }
  {
    i = 1
    ([] : FixedArray[_]).rev_each(f)
    @test.is_false!(failed)
    @test.eq!(i, 1)
  }
  {
    i = 2
    ([1] : FixedArray[_]).rev_each(f)
    @test.is_false!(failed)
    @test.eq!(i, 1)
  }
  i = 6
  ([1, 2, 3, 4, 5] : FixedArray[_]).rev_each(f)
  @test.is_false!(failed)
  @test.eq!(i, 1)
}

/// Iterates over the array with index in reversed turn.
///
/// # Arguments
///
/// - `self`: The array to iterate over.
/// - `f`: A function that takes an `Int` representing the index and a `T` representing the element of the array, and returns `Unit`.
///
/// # Example
///
/// ```
/// [1, 2, 3, 4, 5].rev_eachi(fn(index, elem){
///   print("(\(index),\(elem)) ")
/// }) //output: (4,5) (3,4) (2,3) (1,2) (0,1)
/// ```
pub fn rev_eachi[T](self : FixedArray[T], f : (Int, T) -> Unit) -> Unit {
  let len = self.length()
  for i = 0; i < len; i = i + 1 {
    f(i, self[len - i - 1])
  }
}

test "rev_eachi" {
  let mut i = 6
  let mut j = 0
  let mut failed = false
  let f = fn(index, elem) {
    if index != j || elem != i - 1 {
      failed = true
    }
    i = i - 1
    j = j + 1
  }
  {
    i = 1
    j = 0
    ([] : FixedArray[_]).rev_eachi(f)
    @test.is_false!(failed)
    @test.eq!(i, 1)
    @test.eq!(j, 0)
  }
  {
    i = 2
    j = 0
    ([1] : FixedArray[_]).rev_eachi(f)
    @test.is_false!(failed)
    @test.eq!(i, 1)
    @test.eq!(j, 1)
  }
  i = 6
  j = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).rev_eachi(f)
  @test.is_false!(failed)
  @test.eq!(i, 1)
  @test.eq!(j, 5)
}

/// Applies a function to each element of the array and returns a new array with the results.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// let doubled = arr.map(fn(x){ x * 2 })
/// println(doubled) //output: [2, 4, 6, 8, 10]
/// ```
pub fn map[T, U](self : FixedArray[T], f : (T) -> U) -> FixedArray[U] {
  if self.length() == 0 {
    return []
  }
  let res = FixedArray::make(self.length(), f(self[0]))
  for i = 1; i < self.length(); i = i + 1 {
    res[i] = f(self[i])
  }
  res
}

test "map" {
  let empty : FixedArray[Unit] = FixedArray::default().map(fn(x) { x })
  @test.eq!(empty, [])
  let simple_arr : FixedArray[_] = [6]
  let simple_doubled = simple_arr.map(fn(x) { x * 2 })
  @test.eq!(simple_doubled, [12])
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let doubled = arr.map(fn(x) { x * 2 })
  @test.eq!(doubled, [2, 4, 6, 8, 10])
}

/// Maps a function over the elements of the arr with index.
///
/// # Example
/// ```
/// let arr = [3, 4, 5]
/// let added = arr.mapi(fn (i, x) { x + i })
/// println(added) //output: [3, 5, 7]
/// ```
pub fn mapi[T, U](self : FixedArray[T], f : (Int, T) -> U) -> FixedArray[U] {
  if self.length() == 0 {
    return []
  }
  let res = FixedArray::make(self.length(), f(0, self[0]))
  for i = 1; i < self.length(); i = i + 1 {
    res[i] = f(i, self[i])
  }
  res
}

test "mapi" {
  let empty : FixedArray[Int] = FixedArray::default().mapi(fn(i, x) { x + i })
  @test.eq!(empty, [])
  let simple_arr : FixedArray[_] = [6]
  let simple_doubled = simple_arr.mapi(fn(i, x) { x * 2 + i })
  @test.eq!(simple_doubled, [12])
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let doubled = arr.mapi(fn(i, x) { x * 2 + i })
  @test.eq!(doubled, [2, 5, 8, 11, 14])
}

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

test "makei" {
  let empty = FixedArray::makei(0, fn(_i) { { val: 3 } })
  @test.eq!(empty.length(), 0)
  let simple_arr = FixedArray::makei(1, fn(_i) { { val: 2 } })
  @test.eq!(simple_arr.length(), 1)
  @test.eq!(simple_arr[0].val, 2)
  let arr = FixedArray::makei(2, fn(_i) { { val: 1 } })
  @test.eq!(arr.length(), 2)
  @test.is_not!(arr[0], arr[1])
  @test.eq!(arr[0].val, 1)
  @test.eq!(arr[1].val, 1)
}

/// Create a new array. Values are built from indexes.
/// @alert deprecated "Use `FixedArray::makei` instead"
pub fn FixedArray::new_with_index[T](
  length : Int,
  value : (Int) -> T
) -> FixedArray[T] {
  FixedArray::makei(length, value)
}

/// Create a new array. Values are built from indexes.
pub fn FixedArray::makei[T](length : Int, value : (Int) -> T) -> FixedArray[T] {
  if length <= 0 {
    []
  } else {
    let array = FixedArray::make(length, value(0))
    for i = 1; i < length; i = i + 1 {
      array[i] = value(i)
    }
    array
  }
}

test "fixedarray_new_with_index" {
  let empty = FixedArray::makei(0, fn { i => i })
  @test.eq!(empty.length(), 0)
  let simple_arr = FixedArray::makei(1, fn { i => i })
  @test.eq!(simple_arr.length(), 1)
  @test.eq!(simple_arr[0], 0)
  let arr = FixedArray::makei(2, fn { i => i })
  @test.eq!(arr.length(), 2)
  @test.eq!(arr[0], 0)
  @test.eq!(arr[1], 1)
}

/// Create a new array with given values.
pub fn FixedArray::from_array[T](array : Array[T]) -> FixedArray[T] {
  FixedArray::makei(array.length(), fn(i) { array[i] })
}

test "from_array" {
  let array : FixedArray[_] = [1, 2, 3, 4, 5]
  @test.eq!(array, [1, 2, 3, 4, 5])
}

/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_left(init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_left[T, U](self : FixedArray[T], f : (U, T) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

test "fold_left" {
  let sum = ([] : FixedArray[_]).fold_left(
    init=1,
    fn { sum, elem => sum + elem },
  )
  @test.eq!(sum, 1)
  let sum = ([1] : FixedArray[_]).fold_left(
    init=2,
    fn { sum, elem => sum + elem },
  )
  @test.eq!(sum, 3)
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).fold_left(
    init=0,
    fn { sum, elem => sum + elem },
  )
  @test.eq!(sum, 15)
}

/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_right(init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_right[T, U](self : FixedArray[T], f : (U, T) -> U, ~init : U) -> U {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

test "fold_right" {
  let sum = ([] : FixedArray[_]).fold_right(
    init=1,
    fn { sum, elem => sum + elem },
  )
  @test.eq!(sum, 1)
  let sum = ([1] : FixedArray[_]).fold_right(
    init=2,
    fn { sum, elem => sum + elem },
  )
  @test.eq!(sum, 3)
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).fold_right(
    init=0,
    fn { sum, elem => sum + elem },
  )
  @test.eq!(sum, 15)
}

/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_lefti(init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_lefti[T, U](
  self : FixedArray[T],
  f : (Int, U, T) -> U,
  ~init : U
) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

test "fold_lefti" {
  let f = fn { index, sum, elem => index + sum + elem }
  {
    let sum = ([] : FixedArray[_]).fold_lefti(init=1, f)
    @test.eq!(sum, 1)
  }
  {
    let sum = ([1] : FixedArray[_]).fold_lefti(init=2, f)
    @test.eq!(sum, 3)
  }
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).fold_lefti(init=0, f)
  @test.eq!(sum, 25)
}

/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_righti(init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_righti[T, U](
  self : FixedArray[T],
  f : (Int, U, T) -> U,
  ~init : U
) -> U {
  let len = self.length()
  for i = len - 1, acc = init; i >= 0; {
    continue i - 1, f(len - i - 1, acc, self[i])
  } else {
    acc
  }
}

test "fold_righti" {
  let f = fn { index, sum, elem => index + sum + elem }
  {
    let sum = ([] : FixedArray[_]).fold_lefti(init=1, f)
    @test.eq!(sum, 1)
  }
  {
    let sum = ([1] : FixedArray[_]).fold_lefti(init=2, f)
    @test.eq!(sum, 3)
  }
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).fold_righti(init=0, f)
  @test.eq!(sum, 25)
}

pub fn rev_inplace[T](self : FixedArray[T]) -> Unit {
  let mid_len = self.length() / 2
  for i = 0; i < mid_len; i = i + 1 {
    let j = self.length() - i - 1
    let temp = self[i]
    self[i] = self[j]
    self[j] = temp
  }
}

pub fn rev[T](self : FixedArray[T]) -> FixedArray[T] {
  match self {
    [] => []
    [.., first] => {
      let res = FixedArray::make(self.length(), first)
      let len = self.length()
      for i = 1; i < len; i = i + 1 {
        res[i] = self[len - 1 - i]
      }
      res
    }
  }
}

test "rev in place" {
  {
    let arr : FixedArray[Int] = []
    arr.rev_inplace()
    @test.eq!(arr, [])
  }
  {
    let arr : FixedArray[_] = [1]
    arr.rev_inplace()
    @test.eq!(arr, [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    arr.rev_inplace()
    @test.eq!(arr, [2, 1])
  }
  {
    let arr : FixedArray[_] = [1, 2, 3, 4, 5]
    arr.rev_inplace()
    @test.eq!(arr, [5, 4, 3, 2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6]
  arr.rev_inplace()
  @test.eq!(arr, [6, 5, 4, 3, 2, 1])
}

test "rev" {
  {
    let arr : FixedArray[Int] = []
    @test.eq!(arr.rev(), [])
  }
  {
    let arr : FixedArray[_] = [1]
    @test.eq!(arr.rev(), [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    @test.eq!(arr.rev(), [2, 1])
  }
  {
    let arr : FixedArray[_] = [1, 2, 3, 4, 5]
    @test.eq!(arr.rev(), [5, 4, 3, 2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6]
  @test.eq!(arr.rev(), [6, 5, 4, 3, 2, 1])
}

/// Swap two elements in the array.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// arr.swap(0, 1)
/// println(arr) //output: [2, 1, 3, 4, 5]
/// ```
fn swap[T](self : FixedArray[T], i : Int, j : Int) -> Unit {
  let temp = self[i]
  self[i] = self[j]
  self[j] = temp
}

test "swap" {
  {
    let arr : FixedArray[Int] = [1]
    arr.swap(0, 0)
    @test.eq!(arr, [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    arr.swap(0, 0)
    @test.eq!(arr, [1, 2])
    arr.swap(0, 1)
    @test.eq!(arr, [2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  arr.swap(3, 3)
  @test.eq!(arr, [1, 2, 3, 4, 5])
  arr.swap(1, 3)
  @test.eq!(arr, [1, 4, 3, 2, 5])
}

/// Check if all the elements in the array match the condition.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// arr.all(fn(ele) { ele < 6 }) // true
/// arr.all(fn(ele) { ele < 5 }) // false
/// ```
pub fn all[T](self : FixedArray[T], f : (T) -> Bool) -> Bool {
  for i = 0; i < self.length(); i = i + 1 {
    if f(self[i]).not() {
      return false
    }
  }
  true
}

test "all" {
  {
    let arr : FixedArray[Int] = []
    @test.is_true!(arr.all(fn(ele) { ele < 6 }))
    @test.is_true!(arr.all(fn(ele) { ele < 5 }))
  }
  {
    let arr : FixedArray[_] = [5]
    @test.is_true!(arr.all(fn(ele) { ele < 6 }))
    @test.is_false!(arr.all(fn(ele) { ele < 5 }))
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  @test.is_true!(arr.all(fn(ele) { ele < 6 }))
  @test.is_false!(arr.all(fn(ele) { ele < 5 }))
}

/// Check if any of the elements in the array match the condition.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// arr.any(fn(ele) { ele < 6 }) // true
/// arr.any(fn(ele) { ele < 5 }) // true
/// ```
pub fn any[T](self : FixedArray[T], f : (T) -> Bool) -> Bool {
  for i = 0; i < self.length(); i = i + 1 {
    if f(self[i]) {
      return true
    }
  }
  false
}

test "any" {
  {
    let arr : FixedArray[Int] = []
    @test.is_false!(arr.any(fn(ele) { ele < 6 }))
    @test.is_false!(arr.any(fn(ele) { ele < 5 }))
  }
  {
    let arr : FixedArray[_] = [5]
    @test.is_true!(arr.any(fn(ele) { ele < 6 }))
    @test.is_false!(arr.any(fn(ele) { ele < 5 }))
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  @test.is_true!(arr.any(fn(ele) { ele < 6 }))
  @test.is_true!(arr.any(fn(ele) { ele < 5 }))
}

test "fill" {
  {
    let arr : FixedArray[Int] = []
    arr.fill(3)
    @test.eq!(arr, [])
  }
  {
    let arr : FixedArray[_] = [6]
    arr.fill(5)
    @test.eq!(arr, [5])
  }
  let arr : FixedArray[_] = [0, 0, 0, 0, 0]
  arr.fill(3)
  @test.eq!(arr, [3, 3, 3, 3, 3])
}

/// Search the array index for a given element.
///
/// # Example
/// ```
/// let arr = [3, 4, 5]
/// arr.search(3) // 0
/// ```
pub fn search[T : Eq](self : FixedArray[T], value : T) -> Int? {
  for i = 0; i < self.length(); i = i + 1 {
    if self[i] == value {
      return Some(i)
    }
  }
  None
}

test "search" {
  {
    let arr : FixedArray[Int] = []
    @test.eq!(arr.search(3), None)
    @test.eq!(arr.search(-1), None)
  }
  {
    let arr : FixedArray[_] = [3]
    @test.eq!(arr.search(3), Some(0))
    @test.eq!(arr.search(-1), None)
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  @test.eq!(arr.search(1), Some(0))
  @test.eq!(arr.search(5), Some(4))
  @test.eq!(arr.search(3), Some(2))
  @test.eq!(arr.search(-1), None)
}

/// Checks if the array contains an element.
///
/// # Example
/// ```
/// let arr = [3, 4, 5]
/// arr.contains(3)
/// ```
pub fn contains[T : Eq](self : FixedArray[T], value : T) -> Bool {
  for i = 0; i < self.length(); i = i + 1 {
    if self[i] == value {
      return true
    }
  }
  false
}

test "contains" {
  {
    let arr : FixedArray[Int] = []
    @test.is_false!(arr.contains(3))
    @test.is_false!(arr.contains(-1))
  }
  {
    let arr : FixedArray[_] = [3]
    @test.is_true!(arr.contains(3))
    @test.is_false!(arr.contains(-1))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  @test.is_true!(arr.contains(3))
  @test.is_true!(arr.contains(4))
  @test.is_true!(arr.contains(5))
  @test.is_false!(arr.contains(6))
}

/// Check if the array starts with a given prefix.
///
/// # Example
/// ```
/// let arr = [3, 4, 5]
/// arr.starts_with([3, 4]) // true
/// ```
pub fn starts_with[T : Eq](
  self : FixedArray[T],
  prefix : FixedArray[T]
) -> Bool {
  if prefix.length() > self.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if self[i] != prefix[i] {
      return false
    }
  }
  true
}

test "starts_with" {
  {
    let arr : FixedArray[Int] = []
    @test.is_true!(arr.starts_with([]))
    @test.is_false!(arr.starts_with([1]))
  }
  {
    let arr : FixedArray[_] = [3]
    @test.is_true!(arr.starts_with([]))
    @test.is_true!(arr.starts_with([3]))
    @test.is_false!(arr.starts_with([2]))
    @test.is_false!(arr.starts_with([3, 1]))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  @test.is_true!(arr.starts_with([]))
  @test.is_true!(arr.starts_with([3]))
  @test.is_false!(arr.starts_with([2]))
  @test.is_true!(arr.starts_with([3, 4]))
  @test.is_false!(arr.starts_with([3, 2]))
  @test.is_true!(arr.starts_with([3, 4, 5]))
  @test.is_false!(arr.starts_with([3, 4, 2]))
  @test.is_false!(arr.starts_with([3, 4, 5, 6]))
}

/// Check if the array ends with a given suffix.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.ends_with([5]) // true
/// ```
pub fn ends_with[T : Eq](self : FixedArray[T], suffix : FixedArray[T]) -> Bool {
  let self_len = self.length()
  let suf_len = suffix.length()
  if suf_len > self_len {
    return false
  }
  for i = 0; i < suf_len; i = i + 1 {
    if self[self_len - suf_len + i] != suffix[i] {
      return false
    }
  }
  true
}

test "ends_with" {
  {
    let arr : FixedArray[Int] = []
    @test.is_true!(arr.ends_with([]))
    @test.is_false!(arr.ends_with([1]))
  }
  {
    let arr : FixedArray[_] = [3]
    @test.is_true!(arr.ends_with([]))
    @test.is_true!(arr.ends_with([3]))
    @test.is_false!(arr.ends_with([2]))
    @test.is_false!(arr.ends_with([3, 1]))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  @test.is_true!(arr.ends_with([]))
  @test.is_true!(arr.ends_with([5]))
  @test.is_false!(arr.ends_with([2]))
  @test.is_true!(arr.ends_with([4, 5]))
  @test.is_false!(arr.ends_with([4, 2]))
  @test.is_false!(arr.ends_with([2, 5]))
  @test.is_true!(arr.ends_with([3, 4, 5]))
  @test.is_false!(arr.ends_with([3, 4, 2]))
  @test.is_false!(arr.ends_with([3, 2, 5]))
  @test.is_false!(arr.ends_with([2, 4, 5]))
  @test.is_false!(arr.ends_with([3, 4, 5, 6]))
  @test.is_false!(arr.ends_with([2, 3, 4, 5]))
}

pub fn op_equal[T : Eq](self : FixedArray[T], that : FixedArray[T]) -> Bool {
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

test "op_equal" {
  {
    inspect!(([] : FixedArray[Int]) == [], content="true")
    inspect!(([] : FixedArray[_]) == [1], content="false")
    inspect!(([1, 2] : FixedArray[_]) == [], content="false")
  }
  {
    inspect!(([1] : FixedArray[_]) == [1], content="true")
    inspect!(([1] : FixedArray[_]) == [2], content="false")
    inspect!(([1, 2] : FixedArray[_]) == [1], content="false")
    inspect!(([1] : FixedArray[_]) == [1, 2], content="false")
  }
  inspect!(([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 3, 4, 5], content="true")
  inspect!(([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 3, 4], content="false")
  inspect!(([1, 2, 3, 4] : FixedArray[_]) == [1, 2, 3, 4, 5], content="false")
  inspect!(
    ([1, 2, 3, 4, 5] : FixedArray[_]) == [6, 2, 3, 4, 5],
    content="false",
  )
  inspect!(
    ([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 6, 4, 5],
    content="false",
  )
  inspect!(
    ([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 3, 4, 6],
    content="false",
  )
}

fn deep_clone[T](arr : FixedArray[T]) -> FixedArray[T] {
  let len = arr.length()
  if len == 0 {
    []
  } else {
    let result = FixedArray::make(len, arr[0])
    for i = 0; i < len; i = i + 1 {
      result[i] = arr[i]
    }
    result
  }
}

test "deep_clone" {
  {
    let pre : FixedArray[Int] = []
    let arr = deep_clone(pre)
    @test.is_not!(arr, pre)
    @test.eq!(arr, [])
  }
  {
    let pre : FixedArray[_] = [3]
    let arr = deep_clone(pre)
    @test.is_not!(arr, pre)
    @test.eq!(arr, [3])
  }
  let pre : FixedArray[_] = [1, 2, 3, 4, 5]
  let arr = deep_clone(pre)
  @test.is_not!(arr, pre)
  @test.eq!(arr, [1, 2, 3, 4, 5])
}

pub fn op_add[T](self : FixedArray[T], other : FixedArray[T]) -> FixedArray[T] {
  let slen = self.length()
  let nlen = other.length()
  if slen == 0 {
    deep_clone(other)
  } else if nlen == 0 {
    deep_clone(self)
  } else {
    let result = FixedArray::make(slen + nlen, self[0])
    for i = 1; i < slen; i = i + 1 {
      result[i] = self[i]
    }
    for i = 0; i < nlen; i = i + 1 {
      result[i + slen] = other[i]
    }
    result
  }
}

test "op_add" {
  {
    inspect!(([] : FixedArray[Int]) + [], content="[]")
    inspect!(([] : FixedArray[_]) + [1, 2, 3, 4, 5], content="[1, 2, 3, 4, 5]")
    inspect!(([1, 2, 3, 4, 5] : FixedArray[_]) + [], content="[1, 2, 3, 4, 5]")
  }
  {
    inspect!(([1] : FixedArray[_]) + [2], content="[1, 2]")
    inspect!(
      ([1] : FixedArray[_]) + [1, 2, 3, 4, 5],
      content="[1, 1, 2, 3, 4, 5]",
    )
    inspect!(
      ([1, 2, 3, 4, 5] : FixedArray[_]) + [1],
      content="[1, 2, 3, 4, 5, 1]",
    )
  }
  inspect!(
    ([1, 2, 3, 4, 5] : FixedArray[_]) + [6, 7, 8, 9, 10],
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
  )
}

/// @intrinsic %iter.from_array
pub fn iter[T](self : FixedArray[T]) -> Iter[T] {
  Iter::new(
    fn(yield) {
      for i = 0, len = self.length(); i < len; i = i + 1 {
        if yield(self[i]) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

test "iter" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let iter = arr.iter()
  let exb = Buffer::new()
  let mut i = 0
  iter.each(
    fn(x) {
      exb.write_string(x.to_string())
      exb.write_char('\n')
      i = i + 1
    },
  )
  @test.eq!(i, arr.length())
  exb.expect!(
    content=
      #|1
      #|2
      #|3
      #|4
      #|5
      #|
    ,
  )
}

pub fn FixedArray::from_iter[T](iter : Iter[T]) -> FixedArray[T] {
  FixedArray::from_array(iter.collect())
}
