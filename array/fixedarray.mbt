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
/// let arr = []
/// [1, 2, 3, 4, 5].each(fn(x){ arr.push(x) })
/// assert_eq!(arr, [1, 2, 3, 4, 5])
/// ```
/// TODO: change the intrinsic to match the function name
#intrinsic("%fixedarray.iter")
pub fn FixedArray::each[T](self : FixedArray[T], f : (T) -> Unit) -> Unit {
  for v in self {
    f(v)
  }
}

///|
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
    assert_false!(failed)
    assert_eq!(i, 0)
  }
  {
    i = 0
    ([1] : FixedArray[_]).each(f)
    assert_false!(failed)
    assert_eq!(i, 1)
  }
  i = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).each(f)
  assert_false!(failed)
  assert_eq!(i, 5)
}

///|
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
/// let arr = []
/// [1, 2, 3, 4, 5].eachi(fn(index, elem){
///   arr.push((index, elem))
/// })
/// assert_eq!(arr, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)])
/// ```
pub fn FixedArray::eachi[T](self : FixedArray[T], f : (Int, T) -> Unit) -> Unit {
  for i, v in self {
    f(i, v)
  }
}

///|
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
    assert_false!(failed)
    assert_eq!(i, 0)
  }
  {
    i = 0
    ([1] : FixedArray[_]).eachi(f)
    assert_false!(failed)
    assert_eq!(i, 1)
  }
  i = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).eachi(f)
  assert_false!(failed)
  assert_eq!(i, 5)
}

///|
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
/// let arr = []
/// [1, 2, 3, 4, 5].rev_each(fn(x){ arr.push(x) })
/// assert_eq!(arr, [5, 4, 3, 2, 1])
/// ```
pub fn FixedArray::rev_each[T](self : FixedArray[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

///|
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
    assert_false!(failed)
    assert_eq!(i, 1)
  }
  {
    i = 2
    ([1] : FixedArray[_]).rev_each(f)
    assert_false!(failed)
    assert_eq!(i, 1)
  }
  i = 6
  ([1, 2, 3, 4, 5] : FixedArray[_]).rev_each(f)
  assert_false!(failed)
  assert_eq!(i, 1)
}

///|
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
/// let arr = []
/// [1, 2, 3, 4, 5].rev_eachi(fn(index, elem){
///   arr.push((index, elem))
/// })
/// assert_eq!(arr, [(0, 5), (1, 4), (2, 3), (3, 2), (4, 1)])
/// ```
pub fn FixedArray::rev_eachi[T](
  self : FixedArray[T],
  f : (Int, T) -> Unit
) -> Unit {
  let len = self.length()
  for i in 0..<len {
    f(i, self[len - i - 1])
  }
}

///|
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
    assert_false!(failed)
    assert_eq!(i, 1)
    assert_eq!(j, 0)
  }
  {
    i = 2
    j = 0
    ([1] : FixedArray[_]).rev_eachi(f)
    assert_false!(failed)
    assert_eq!(i, 1)
    assert_eq!(j, 1)
  }
  i = 6
  j = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).rev_eachi(f)
  assert_false!(failed)
  assert_eq!(i, 1)
  assert_eq!(j, 5)
}

///|
/// Applies a function to each element of the array and returns a new array with the results.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// let doubled = arr.map(fn(x){ x * 2 })
/// assert_eq!(doubled, [2, 4, 6, 8, 10])
/// ```
pub fn FixedArray::map[T, U](
  self : FixedArray[T],
  f : (T) -> U
) -> FixedArray[U] {
  if self.length() == 0 {
    return []
  }
  let res = FixedArray::make(self.length(), f(self[0]))
  for i in 1..<self.length() {
    res[i] = f(self[i])
  }
  res
}

///|
test "map" {
  let empty : FixedArray[Unit] = FixedArray::default().map(fn(x) { x })
  assert_eq!(empty, [])
  let simple_arr : FixedArray[_] = [6]
  let simple_doubled = simple_arr.map(fn(x) { x * 2 })
  assert_eq!(simple_doubled, [12])
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let doubled = arr.map(fn(x) { x * 2 })
  assert_eq!(doubled, [2, 4, 6, 8, 10])
}

///|
/// Maps a function over the elements of the arr with index.
///
/// # Example
/// ```
/// let arr = [3, 4, 5]
/// let added = arr.mapi(fn (i, x) { x + i })
/// assert_eq!(added, [3, 5, 7])
/// ```
pub fn FixedArray::mapi[T, U](
  self : FixedArray[T],
  f : (Int, T) -> U
) -> FixedArray[U] {
  if self.length() == 0 {
    return []
  }
  let res = FixedArray::make(self.length(), f(0, self[0]))
  for i in 1..<self.length() {
    res[i] = f(i, self[i])
  }
  res
}

///|
test "mapi" {
  let empty : FixedArray[Int] = FixedArray::default().mapi(fn(i, x) { x + i })
  assert_eq!(empty, [])
  let simple_arr : FixedArray[_] = [6]
  let simple_doubled = simple_arr.mapi(fn(i, x) { x * 2 + i })
  assert_eq!(simple_doubled, [12])
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let doubled = arr.mapi(fn(i, x) { x * 2 + i })
  assert_eq!(doubled, [2, 5, 8, 11, 14])
}

///|
/// Creates a new fixed-size array of the specified length, where each element is
/// initialized using a function that maps indices to values.
///
/// Parameters:
///
/// * `length` : The length of the array to create. If `length` is less than or
/// equal to 0, returns an empty array.
/// * `initializer` : A function that takes an index (from 0 to `length - 1`) and
/// returns a value of type `T` for that position.
///
/// Returns a new fixed array containing the values produced by applying the
/// initializer function to each index.
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::makei" {
///   let arr = FixedArray::makei(3, fn(i) { i * 2 })
///   inspect!(arr, content="[0, 2, 4]")
/// }
/// ```
pub fn FixedArray::makei[T](length : Int, value : (Int) -> T) -> FixedArray[T] {
  if length <= 0 {
    []
  } else {
    let array = FixedArray::make(length, value(0))
    for i in 1..<length {
      array[i] = value(i)
    }
    array
  }
}

///|
test "fixedarray_new_with_index" {
  let empty = FixedArray::makei(0, fn { i => i })
  assert_eq!(empty.length(), 0)
  let simple_arr = FixedArray::makei(1, fn { i => i })
  assert_eq!(simple_arr.length(), 1)
  assert_eq!(simple_arr[0], 0)
  let arr = FixedArray::makei(2, fn { i => i })
  assert_eq!(arr.length(), 2)
  assert_eq!(arr[0], 0)
  assert_eq!(arr[1], 1)
}

///|
/// Creates a new fixed-size array from a dynamic array. The resulting fixed
/// array will have the same length and elements as the input array.
///
/// Parameters:
///
/// * `array` : A dynamic array containing elements of type `T` that will be
/// converted to a fixed array.
///
/// Returns a new fixed array containing the same elements as the input array.
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::from_array" {
///   let dynamic_array = [1, 2, 3, 4, 5]
///   let fixed_array = FixedArray::from_array(dynamic_array)
///   inspect!(fixed_array, content="[1, 2, 3, 4, 5]")
/// }
/// ```
pub fn FixedArray::from_array[T](array : Array[T]) -> FixedArray[T] {
  FixedArray::makei(array.length(), fn(i) { array[i] })
}

///|
test "from_array" {
  let array = FixedArray::from_array([1, 2, 3, 4, 5])
  assert_eq!(array, [1, 2, 3, 4, 5])
}

///|
/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn FixedArray::fold[A, B](
  self : FixedArray[A],
  init~ : B,
  f : (B, A) -> B
) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
test "fold" {
  let sum = ([] : FixedArray[_]).fold(init=1, fn { sum, elem => sum + elem })
  assert_eq!(sum, 1)
  let sum = ([1] : FixedArray[_]).fold(init=2, fn { sum, elem => sum + elem })
  assert_eq!(sum, 3)
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).fold(init=0, fn {
    sum, elem => sum + elem
  })
  assert_eq!(sum, 15)
}

///|
/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn FixedArray::rev_fold[A, B](
  self : FixedArray[A],
  init~ : B,
  f : (B, A) -> B
) -> B {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
test "rev_fold" {
  let sum = ([] : FixedArray[_]).rev_fold(init=1, fn { sum, elem => sum + elem })
  assert_eq!(sum, 1)
  let sum = ([1] : FixedArray[_]).rev_fold(init=2, fn {
    sum, elem => sum + elem
  })
  assert_eq!(sum, 3)
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).rev_fold(init=0, fn {
    sum, elem => sum + elem
  })
  assert_eq!(sum, 15)
}

///|
/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn FixedArray::foldi[A, B](
  self : FixedArray[A],
  init~ : B,
  f : (Int, B, A) -> B
) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

///|
test "fold_lefti" {
  let f = fn { index, sum, elem => index + sum + elem }
  {
    let sum = ([] : FixedArray[_]).foldi(init=1, f)
    assert_eq!(sum, 1)
  }
  {
    let sum = ([1] : FixedArray[_]).foldi(init=2, f)
    assert_eq!(sum, 3)
  }
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).foldi(init=0, f)
  assert_eq!(sum, 25)
}

///|
/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn FixedArray::rev_foldi[A, B](
  self : FixedArray[A],
  init~ : B,
  f : (Int, B, A) -> B
) -> B {
  let len = self.length()
  for i = len - 1, acc = init; i >= 0; {
    continue i - 1, f(len - i - 1, acc, self[i])
  } else {
    acc
  }
}

///|
test "rev_foldi" {
  let f = fn { index, sum, elem => index + sum + elem }
  {
    let sum = ([] : FixedArray[_]).rev_foldi(init=1, f)
    assert_eq!(sum, 1)
  }
  {
    let sum = ([1] : FixedArray[_]).rev_foldi(init=2, f)
    assert_eq!(sum, 3)
  }
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).rev_foldi(init=0, f)
  assert_eq!(sum, 25)
}

///|
/// Reverses the array in place by swapping elements from both ends until
/// reaching the middle.
///
/// Parameters:
///
/// * `array` : The array to be reversed. The array will be modified in place.
///
/// Example:
///
/// ```moonbit
/// test "rev_inplace" {
///   let arr : FixedArray[_] = [1, 2, 3, 4, 5]
///   arr.rev_inplace()
///   inspect!(arr, content="[5, 4, 3, 2, 1]")
/// }
/// ```
pub fn FixedArray::rev_inplace[T](self : FixedArray[T]) -> Unit {
  let mid_len = self.length() / 2
  for i in 0..<mid_len {
    let j = self.length() - i - 1
    let temp = self[i]
    self[i] = self[j]
    self[j] = temp
  }
}

///|
/// Returns a new array containing all elements in reverse order. The original
/// array remains unchanged.
///
/// Parameters:
///
/// * `self` : The array to be reversed.
///
/// Returns a new array with the same elements but in reverse order.
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::rev" {
///   let arr : FixedArray[Int] = [1, 2, 3, 4, 5]
///   inspect!(arr.rev(), content="[5, 4, 3, 2, 1]")
///   // Original array remains unchanged
///   inspect!(arr, content="[1, 2, 3, 4, 5]")
/// }
/// ```
pub fn FixedArray::rev[T](self : FixedArray[T]) -> FixedArray[T] {
  match self {
    [] => []
    [.., first] => {
      let res = FixedArray::make(self.length(), first)
      let len = self.length()
      for i in 1..<len {
        res[i] = self[len - 1 - i]
      }
      res
    }
  }
}

///|
test "rev in place" {
  {
    let arr : FixedArray[Int] = []
    arr.rev_inplace()
    assert_eq!(arr, [])
  }
  {
    let arr : FixedArray[_] = [1]
    arr.rev_inplace()
    assert_eq!(arr, [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    arr.rev_inplace()
    assert_eq!(arr, [2, 1])
  }
  {
    let arr : FixedArray[_] = [1, 2, 3, 4, 5]
    arr.rev_inplace()
    assert_eq!(arr, [5, 4, 3, 2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6]
  arr.rev_inplace()
  assert_eq!(arr, [6, 5, 4, 3, 2, 1])
}

///|
test "rev" {
  {
    let arr : FixedArray[Int] = []
    assert_eq!(arr.rev(), [])
  }
  {
    let arr : FixedArray[_] = [1]
    assert_eq!(arr.rev(), [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    assert_eq!(arr.rev(), [2, 1])
  }
  {
    let arr : FixedArray[_] = [1, 2, 3, 4, 5]
    assert_eq!(arr.rev(), [5, 4, 3, 2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6]
  assert_eq!(arr.rev(), [6, 5, 4, 3, 2, 1])
}

///|
/// Swap two elements in the array.
///
/// # Example
///
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// arr.swap(0, 1)
/// assert_eq!(arr, [2, 1, 3, 4, 5])
/// ```
pub fn FixedArray::swap[T](self : FixedArray[T], i : Int, j : Int) -> Unit {
  let temp = self[i]
  self[i] = self[j]
  self[j] = temp
}

///|
test "swap" {
  {
    let arr : FixedArray[Int] = [1]
    arr.swap(0, 0)
    assert_eq!(arr, [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    arr.swap(0, 0)
    assert_eq!(arr, [1, 2])
    arr.swap(0, 1)
    assert_eq!(arr, [2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  arr.swap(3, 3)
  assert_eq!(arr, [1, 2, 3, 4, 5])
  arr.swap(1, 3)
  assert_eq!(arr, [1, 4, 3, 2, 5])
}

///|
/// Check if all the elements in the array match the condition.
///
/// # Example
///
/// ```
/// let arr: FixedArray[Int] = [1, 2, 3, 4, 5]
/// assert_true!(arr.all(fn(ele) { ele < 6 }))
/// assert_false!(arr.all(fn(ele) { ele < 5 }))
/// ```
pub fn FixedArray::all[T](self : FixedArray[T], f : (T) -> Bool) -> Bool {
  for i in 0..<self.length() {
    if not(f(self[i])) {
      return false
    }
  }
  true
}

///|
test "all" {
  {
    let arr : FixedArray[Int] = []
    assert_true!(arr.all(fn(ele) { ele < 6 }))
    assert_true!(arr.all(fn(ele) { ele < 5 }))
  }
  {
    let arr : FixedArray[_] = [5]
    assert_true!(arr.all(fn(ele) { ele < 6 }))
    assert_false!(arr.all(fn(ele) { ele < 5 }))
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  assert_true!(arr.all(fn(ele) { ele < 6 }))
  assert_false!(arr.all(fn(ele) { ele < 5 }))
}

///|
/// Check if any of the elements in the array match the condition.
///
/// # Example
///
/// ```
/// let arr: FixedArray[Int] = [1, 2, 3, 4, 5]
/// assert_true!(arr.any(fn(ele) { ele < 6 }))
/// assert_true!(arr.any(fn(ele) { ele < 5 }))
/// ```
pub fn FixedArray::any[T](self : FixedArray[T], f : (T) -> Bool) -> Bool {
  for i in 0..<self.length() {
    if f(self[i]) {
      return true
    }
  }
  false
}

///|
test "any" {
  {
    let arr : FixedArray[Int] = []
    assert_false!(arr.any(fn(ele) { ele < 6 }))
    assert_false!(arr.any(fn(ele) { ele < 5 }))
  }
  {
    let arr : FixedArray[_] = [5]
    assert_true!(arr.any(fn(ele) { ele < 6 }))
    assert_false!(arr.any(fn(ele) { ele < 5 }))
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  assert_true!(arr.any(fn(ele) { ele < 6 }))
  assert_true!(arr.any(fn(ele) { ele < 5 }))
}

///|
test "fill" {
  {
    let arr : FixedArray[Int] = []
    arr.fill(3)
    assert_eq!(arr, [])
  }
  {
    let arr : FixedArray[_] = [6]
    arr.fill(5)
    assert_eq!(arr, [5])
  }
  let arr : FixedArray[_] = [0, 0, 0, 0, 0]
  arr.fill(3)
  assert_eq!(arr, [3, 3, 3, 3, 3])
}

///|
/// Search the array index for a given element.
///
/// # Example
/// ```
/// let arr: FixedArray[Int] = [3, 4, 5]
/// assert_eq!(arr.search(3), Some(0))
/// ```
pub fn FixedArray::search[T : Eq](self : FixedArray[T], value : T) -> Int? {
  for i in 0..<self.length() {
    if self[i] == value {
      return Some(i)
    }
  }
  None
}

///|
test "search" {
  {
    let arr : FixedArray[Int] = []
    assert_eq!(arr.search(3), None)
    assert_eq!(arr.search(-1), None)
  }
  {
    let arr : FixedArray[_] = [3]
    assert_eq!(arr.search(3), Some(0))
    assert_eq!(arr.search(-1), None)
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  assert_eq!(arr.search(1), Some(0))
  assert_eq!(arr.search(5), Some(4))
  assert_eq!(arr.search(3), Some(2))
  assert_eq!(arr.search(-1), None)
}

///|
/// Checks if the array contains an element.
///
/// # Example
/// ```
/// let arr: FixedArray[Int] = [3, 4, 5]
/// assert_true!(arr.contains(3))
/// ```
pub fn FixedArray::contains[T : Eq](self : FixedArray[T], value : T) -> Bool {
  for i in 0..<self.length() {
    if self[i] == value {
      return true
    }
  }
  false
}

///|
test "contains" {
  {
    let arr : FixedArray[Int] = []
    assert_false!(arr.contains(3))
    assert_false!(arr.contains(-1))
  }
  {
    let arr : FixedArray[_] = [3]
    assert_true!(arr.contains(3))
    assert_false!(arr.contains(-1))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  assert_true!(arr.contains(3))
  assert_true!(arr.contains(4))
  assert_true!(arr.contains(5))
  assert_false!(arr.contains(6))
}

///|
/// Check if the array starts with a given prefix.
///
/// # Example
/// ```
/// let arr: FixedArray[Int] = [3, 4, 5]
/// assert_true!(arr.starts_with([3, 4]))
/// ```
pub fn FixedArray::starts_with[T : Eq](
  self : FixedArray[T],
  prefix : FixedArray[T]
) -> Bool {
  if prefix.length() > self.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if self[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
test "starts_with" {
  {
    let arr : FixedArray[Int] = []
    assert_true!(arr.starts_with([]))
    assert_false!(arr.starts_with([1]))
  }
  {
    let arr : FixedArray[_] = [3]
    assert_true!(arr.starts_with([]))
    assert_true!(arr.starts_with([3]))
    assert_false!(arr.starts_with([2]))
    assert_false!(arr.starts_with([3, 1]))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  assert_true!(arr.starts_with([]))
  assert_true!(arr.starts_with([3]))
  assert_false!(arr.starts_with([2]))
  assert_true!(arr.starts_with([3, 4]))
  assert_false!(arr.starts_with([3, 2]))
  assert_true!(arr.starts_with([3, 4, 5]))
  assert_false!(arr.starts_with([3, 4, 2]))
  assert_false!(arr.starts_with([3, 4, 5, 6]))
}

///|
/// Check if the array ends with a given suffix.
///
/// # Example
/// ```
/// let v: FixedArray[Int] = [3, 4, 5]
/// assert_true!(v.ends_with([5]))
/// ```
pub fn FixedArray::ends_with[T : Eq](
  self : FixedArray[T],
  suffix : FixedArray[T]
) -> Bool {
  let self_len = self.length()
  let suf_len = suffix.length()
  if suf_len > self_len {
    return false
  }
  for i in 0..<suf_len {
    if self[self_len - suf_len + i] != suffix[i] {
      return false
    }
  }
  true
}

///|
test "ends_with" {
  {
    let arr : FixedArray[Int] = []
    assert_true!(arr.ends_with([]))
    assert_false!(arr.ends_with([1]))
  }
  {
    let arr : FixedArray[_] = [3]
    assert_true!(arr.ends_with([]))
    assert_true!(arr.ends_with([3]))
    assert_false!(arr.ends_with([2]))
    assert_false!(arr.ends_with([3, 1]))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  assert_true!(arr.ends_with([]))
  assert_true!(arr.ends_with([5]))
  assert_false!(arr.ends_with([2]))
  assert_true!(arr.ends_with([4, 5]))
  assert_false!(arr.ends_with([4, 2]))
  assert_false!(arr.ends_with([2, 5]))
  assert_true!(arr.ends_with([3, 4, 5]))
  assert_false!(arr.ends_with([3, 4, 2]))
  assert_false!(arr.ends_with([3, 2, 5]))
  assert_false!(arr.ends_with([2, 4, 5]))
  assert_false!(arr.ends_with([3, 4, 5, 6]))
  assert_false!(arr.ends_with([2, 3, 4, 5]))
}

///|
/// Checks if two fixed arrays are equal.
///
/// Two arrays are considered equal if they have the same length and all
/// corresponding elements are equal. The elements in the arrays must implement
/// the `Eq` trait.
///
/// Parameters:
///
/// * `self` : The first fixed array to compare.
/// * `other` : The second fixed array to compare.
///
/// Returns `true` if the arrays are equal, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::op_equal" {
///   let arr1 : FixedArray[Int] = [1, 2, 3]
///   let arr2 : FixedArray[Int] = [1, 2, 3]
///   let arr3 : FixedArray[Int] = [1, 2, 4]
///   inspect!(arr1 == arr2, content="true")
///   inspect!(arr1 == arr3, content="false")
/// }
/// ```
pub impl[T : Eq] Eq for FixedArray[T] with op_equal(
  self : FixedArray[T],
  that : FixedArray[T]
) -> Bool {
  if self.length() != that.length() {
    return false
  }
  for i in 0..<self.length() {
    if self[i] != that[i] {
      return false
    }
  }
  true
}

///|
pub impl[T : Hash] Hash for FixedArray[T] with hash_combine(self, hasher) {
  for v in self {
    v.hash_combine(hasher)
  }
}

///|
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

///|
/// Compares two fixed arrays lexicographically based on their elements. First
/// compares the lengths of the arrays, then compares elements pairwise until a
/// difference is found or all elements have been compared.
///
/// Parameters:
///
/// * `self` : The first fixed array to compare.
/// * `other` : The second fixed array to compare.
///
/// Returns an integer that indicates the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::compare" {
///   let arr1 = [1, 2, 3]
///   let arr2 = [1, 2, 4]
///   let arr3 = [1, 2]
///   inspect!(arr1.compare(arr2), content="-1") // arr1 < arr2
///   inspect!(arr2.compare(arr1), content="1") // arr2 > arr1
///   inspect!(arr1.compare(arr3), content="1") // arr1 > arr3 (longer)
///   inspect!(arr1.compare(arr1), content="0") // arr1 = arr1
/// }
/// ```
pub impl[T : Compare] Compare for FixedArray[T] with compare(self, other) {
  let len_self = self.length()
  let len_other = other.length()
  let cmp = len_self.compare(len_other)
  guard cmp == 0 else { return cmp }
  for i in 0..<len_self {
    let cmp = self.unsafe_get(i).compare(other.unsafe_get(i))
    guard cmp == 0 else { break cmp }

  } else {
    0
  }
}

///|
/// Concatenates two arrays and returns a new array containing all elements from
/// both arrays in order.
///
/// Parameters:
///
/// * `self` : The first array to concatenate.
/// * `other` : The second array to concatenate.
///
/// Returns a new array that contains all elements from the first array followed
/// by all elements from the second array. The returned array is independent of
/// both input arrays.
///
/// Example:
///
/// ```moonbit
/// test "op_add" {
///   let arr1 : FixedArray[Int] = [1, 2, 3]
///   let arr2 : FixedArray[Int] = [4, 5, 6]
///   inspect!(arr1 + arr2, content="[1, 2, 3, 4, 5, 6]")
/// }
/// ```
pub impl[T] Add for FixedArray[T] with op_add(self, other) {
  let slen = self.length()
  let nlen = other.length()
  FixedArray::makei(slen + nlen, fn(i) {
    if i < slen {
      self[i]
    } else {
      other[i - slen]
    }
  })
}

///|
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

///|
test "iter" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let iter = arr.iter()
  let exb = StringBuilder::new()
  let mut i = 0
  iter.each(fn(x) {
    exb.write_string(x.to_string())
    exb.write_char('\n')
    i = i + 1
  })
  assert_eq!(i, arr.length())
  inspect!(
    exb,
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

///|
/// Creates a new fixed array from an iterator.
///
/// Parameters:
///
/// * `iterator` : An iterator of type `Iter[T]` from which elements will be
/// collected into a fixed array.
///
/// Returns a new fixed array containing all elements from the iterator.
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::from_iter" {
///   let arr = [1, 2, 3]
///   let fixed_arr = FixedArray::from_iter(arr.iter())
///   inspect!(fixed_arr, content="[1, 2, 3]")
/// }
/// ```
pub fn FixedArray::from_iter[T](iter : Iter[T]) -> FixedArray[T] {
  FixedArray::from_array(iter.collect())
}

///|
/// Returns the last element of a fixed array if it exists.
///
/// Parameters:
///
/// * `self` : The fixed array to get the last element from.
///
/// Returns `Some(element)` containing the last element if the array is not
/// empty, or `None` if the array is empty.
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::last" {
///   let array : FixedArray[Int] = [1, 2, 3]
///   inspect!(array.last(), content="Some(3)")
///   let empty : FixedArray[Int] = []
///   inspect!(empty.last(), content="None")
/// }
/// ```
pub fn FixedArray::last[A](self : FixedArray[A]) -> A? {
  match self {
    [] => None
    [.., last] => Some(last)
  }
}

///|
test "FixedArray::last/empty" {
  let empty : FixedArray[Int] = []
  inspect!(empty.last(), content="None")
}

///|
test "FixedArray::last/non_empty" {
  let array : FixedArray[_] = [1, 2, 3]
  inspect!(array.last(), content="Some(3)")
  let single : FixedArray[_] = [42]
  inspect!(single.last(), content="Some(42)")
}

///|
test "FixedArray::last/empty_array" {
  let empty_array : FixedArray[Int] = []
  inspect!(FixedArray::last(empty_array), content="None")
}

///|
test "FixedArray::last/single_element" {
  let single_element_array : FixedArray[Int] = [42]
  inspect!(FixedArray::last(single_element_array), content="Some(42)")
}

///|
test "FixedArray::last/multiple_elements" {
  let multiple_elements_array : FixedArray[Int] = [1, 2, 3, 4, 5]
  inspect!(FixedArray::last(multiple_elements_array), content="Some(5)")
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for FixedArray[X] with arbitrary(
  size,
  rs
) {
  let len = if size == 0 { 0 } else { rs.next_positive_int() % size }
  FixedArray::makei(len, fn(x) { X::arbitrary(x, rs) })
}
