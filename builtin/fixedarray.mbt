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
/// Retrieves an element at the specified index from a fixed-size array. 
///
/// Parameters:
///
/// * `array` : The fixed-size array to access.
/// * `index` : The position in the array from which to retrieve the element.
///
/// Returns `Some(element)` if the index is within bounds, or `None` if the index
/// is out of bounds.
///
/// Example:
///
/// ```moonbit
///   let arr : FixedArray[Int] = [1, 2, 3]
///   inspect(arr.get(1), content="Some(2)")
///
///   let arr : FixedArray[Int] = [1, 2, 3]
///   inspect(arr.get(3), content="None")
/// ```
pub fn[T] FixedArray::get(self : FixedArray[T], idx : Int) -> T? {
  let len = self.length()
  guard idx >= 0 && idx < len else { None }
  Some(self.unsafe_get(idx))
}

///|
///
/// Creates an iterator over the elements of a fixed-size array, providing
/// sequential access to each element.
///
/// Parameters:
///
/// * `array` : The fixed-size array to iterate over.
///
/// Returns an iterator that yields each element of the array in order from first
/// to last.
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 42)
///   let mut sum = 0
///   arr.iter().each((x) => { sum = sum + x })
///   inspect(sum, content="126")
/// ```
#intrinsic("%iter.from_array")
pub fn[T] FixedArray::iter(self : FixedArray[T]) -> Iter[T] {
  Iter::new(yield_ => for v in self {
    guard yield_(v) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
/// Returns an iterator that yields both indices and values from the fixed array.
/// The iterator provides pairs of `(index, value)` where indices start from 0
/// and increment sequentially.
///
/// Parameters:
///
/// * `array` : The fixed array to iterate over.
///
/// Returns an iterator of type `Iter2[Int, T]` that yields tuples of indices and
/// values from the array.
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 10)
///   let mut sum = 0
///   arr.iter2().each((i, x) => { sum = sum + i + x })
///   inspect(sum, content="33") // (0 + 10) + (1 + 10) + (2 + 10) = 33
/// ```
pub fn[T] FixedArray::iter2(self : FixedArray[T]) -> Iter2[Int, T] {
  Iter2::new(yield_ => for i, v in self {
    guard yield_(i, v) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
/// Returns an empty fixed-size array of the specified type.
///
/// Parameters:
///
/// * `X` : The type parameter specifying the element type of the array.
///
/// Returns an empty fixed-size array of type `FixedArray[X]`.
///
/// Example:
///
/// ```moonbit
///   let arr : FixedArray[Int] = FixedArray::default()
///   inspect(arr.length(), content="0")
///   inspect(arr.is_empty(), content="true")
/// ```
pub impl[X] Default for FixedArray[X] with default() {
  []
}

///|
/// Fill the array with a given value.
/// 
/// This method fills all or part of a FixedArray with the given value.
/// 
/// # Parameters
/// - `value`: The value to fill the array with
/// - `start`: The starting index (inclusive, default: 0)
/// - `end`: The ending index (exclusive, optional)
/// 
/// If `end` is not provided, fills from `start` to the end of the array.
/// If `start` equals `end`, no elements are modified.
/// 
/// # Panics
/// - Panics if `start` is negative or greater than or equal to the array length
/// - Panics if `end` is provided and is less than `start` or greater than array length
/// - Does nothing if the array is empty
/// 
/// # Example
/// ```moonbit
/// // Fill entire array
/// let fa : FixedArray[Int] = [0, 0, 0, 0, 0]
/// fa.fill(3)
/// inspect(fa, content="[3, 3, 3, 3, 3]")
/// 
/// // Fill from index 1 to 3 (exclusive)
/// let fa2 : FixedArray[Int] = [0, 0, 0, 0, 0]
/// fa2.fill(9, start=1, end=3)
/// inspect(fa2, content="[0, 9, 9, 0, 0]")
/// 
/// // Fill from index 2 to end
/// let fa3 : FixedArray[String] = ["a", "b", "c", "d"]
/// fa3.fill("x", start=2)
/// inspect(fa3, content=(
///   #|["a", "b", "x", "x"]
/// ))
/// ```
pub fn[T] FixedArray::fill(
  self : FixedArray[T],
  value : T,
  start? : Int = 0,
  end? : Int,
) -> Unit {
  let array_length = self.length()
  guard array_length > 0 else { return }
  guard start >= 0 && start < array_length
  let length = match end {
    None => array_length - start
    Some(e) => {
      guard e >= start && e <= array_length
      e - start
    }
  }
  self.unchecked_fill(start, value, length)
}

///|
#intrinsic("%fixedarray.fill")
fn[T] FixedArray::unchecked_fill(
  self : FixedArray[T],
  start : Int,
  value : T,
  len : Int,
) -> Unit {
  for i in start..<(start + len) {
    self[i] = value
  }
}

///|
/// Tests whether the FixedArray contains no elements.
///
/// Parameters:
///
/// * `FixedArray` : The FixedArray to check.
///
/// Returns `true` if the FixedArray has no elements, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let empty : FixedArray[Int] = []
///   inspect(empty.is_empty(), content="true")
///   let non_empty = [1, 2, 3]
///   inspect(non_empty.is_empty(), content="false")
/// ```
pub fn[T] FixedArray::is_empty(self : FixedArray[T]) -> Bool {
  self.length() == 0
}

///|
/// 
/// Performs a binary search on a sorted array to find the index of a given element.
///
/// # Example
/// ```mbt
///   let v : FixedArray[Int] = [3, 4, 5]
///   let result = v.binary_search(3)
///   assert_eq(result, Ok(0)) // The element 3 is found at index 0
/// ```
///
/// # Arguments
/// - `self`: The array in which to perform the search.
/// - `value`: The element to search for in the array.
///
/// # Returns
/// - `Result[Int, Int]`:
/// If the element is found, an `Ok` variant is returned, containing the index of the matching element in the array.
/// If there are multiple matches, the leftmost match will be returned.
/// If the element is not found, an `Err` variant is returned, containing the index where the element could be inserted to maintain the sorted order.
///
/// # Notes
/// - Ensure that the array is sorted in increasing order before calling this function.
/// - If the array is not sorted, the returned result is undefined and should not be relied on.
pub fn[T : Compare] FixedArray::binary_search(
  self : FixedArray[T],
  value : T,
) -> Result[Int, Int] {
  let len = self.length()
  for i = 0, j = len; i < j; {
    let h = i + (j - i) / 2
    // Note even if self[h] == value, we still continue the search
    // because we want to find the leftmost match
    if self.unsafe_get(h) < value {
      continue h + 1, j
    } else {
      continue i, h
    }
  } else {
    if i < len && self.unsafe_get(i) == value {
      Ok(i)
    } else {
      Err(i)
    }
  }
}

///|
/// Performs a binary search on a sorted array using a custom comparison
/// function. Returns the position of the matching element if found, or the
/// position where the element could be inserted while maintaining the sorted
/// order.
///
/// Parameters:
///
/// * `array` : The sorted array to search in.
/// * `comparator` : A function that compares each element with the target value,
/// returning:
///  * A negative integer if the element is less than the target
///  * Zero if the element equals the target
///  * A positive integer if the element is greater than the target
///
/// Returns a `Result` containing either:
///
/// * `Ok(index)` if a matching element is found at position `index`
/// * `Err(index)` if no match is found, where `index` is the position where the
/// element could be inserted
///
/// Example:
///
/// ```moonbit
///   let arr : FixedArray[Int] = [1, 3, 5, 7, 9]
///   let find_3 = arr.binary_search_by((x) => {
///     x.compare(3)
///   })
///   inspect(find_3, content="Ok(1)")
///   let find_4 = arr.binary_search_by((x) => {
///     x.compare(4)
///   })
///   inspect(find_4, content="Err(2)")
/// ```
///
/// Notes:
///
/// * Assumes the array is sorted according to the ordering implied by the
/// comparison function
/// * For multiple matches, returns the leftmost matching position
/// * Returns an insertion point that maintains the sort order when no match is
/// found
#locals(cmp)
pub fn[T] FixedArray::binary_search_by(
  self : FixedArray[T],
  cmp : (T) -> Int raise?,
) -> Result[Int, Int] raise? {
  let len = self.length()
  for i = 0, j = len; i < j; {
    let h = i + (j - i) / 2
    // Note even if self[h] == value, we still continue the search
    // because we want to find the leftmost match
    if cmp(self.unsafe_get(h)) < 0 {
      continue h + 1, j
    } else {
      continue i, h
    }
  } else {
    if i < len && cmp(self.unsafe_get(i)) == 0 {
      Ok(i)
    } else {
      Err(i)
    }
  }
}

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
/// ```mbt
///   let arr = []
///   [1, 2, 3, 4, 5].each(x => arr.push(x))
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[T] FixedArray::each(
  self : FixedArray[T],
  f : (T) -> Unit raise?,
) -> Unit raise? {
  for v in self {
    f(v)
  }
}

///|
test "each" {
  let mut i = 0
  let mut failed = false
  let f = elem => {
    if elem != i + 1 {
      failed = true
    }
    i = i + 1
  }
  {
    i = 0
    ([] : FixedArray[_]).each(f)
    assert_false(failed)
    inspect(i, content="0")
  }
  {
    i = 0
    ([1] : FixedArray[_]).each(f)
    assert_false(failed)
    inspect(i, content="1")
  }
  i = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).each(f)
  assert_false(failed)
  inspect(i, content="5")
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
/// ```mbt
///   let arr = []
///   [1, 2, 3, 4, 5].eachi((index, elem) => arr.push((index, elem)))
///   assert_eq(arr, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)])
/// ```
pub fn[T] FixedArray::eachi(
  self : FixedArray[T],
  f : (Int, T) -> Unit raise?,
) -> Unit raise? {
  for i, v in self {
    f(i, v)
  }
}

///|
test "eachi" {
  let mut i = 0
  let mut failed = false
  let f = (index, elem) => {
    if index != i || elem != i + 1 {
      failed = true
    }
    i = i + 1
  }
  {
    i = 0
    ([] : FixedArray[_]).eachi(f)
    assert_false(failed)
    inspect(i, content="0")
  }
  {
    i = 0
    ([1] : FixedArray[_]).eachi(f)
    assert_false(failed)
    inspect(i, content="1")
  }
  i = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).eachi(f)
  assert_false(failed)
  inspect(i, content="5")
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
/// ```mbt
///   let arr = []
///   [1, 2, 3, 4, 5].rev_each((x) => arr.push(x))
///   assert_eq(arr, [5, 4, 3, 2, 1])
/// ```
pub fn[T] FixedArray::rev_each(
  self : FixedArray[T],
  f : (T) -> Unit raise?,
) -> Unit raise? {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

///|
test "rev_each" {
  let mut i = 6
  let mut failed = false
  let f = elem => {
    if elem != i - 1 {
      failed = true
    }
    i = i - 1
  }
  {
    i = 1
    ([] : FixedArray[_]).rev_each(f)
    assert_false(failed)
    inspect(i, content="1")
  }
  {
    i = 2
    ([1] : FixedArray[_]).rev_each(f)
    assert_false(failed)
    inspect(i, content="1")
  }
  i = 6
  ([1, 2, 3, 4, 5] : FixedArray[_]).rev_each(f)
  assert_false(failed)
  inspect(i, content="1")
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
/// ```mbt
///   let arr = []
///   [1, 2, 3, 4, 5].rev_eachi((index, elem) => arr.push((index, elem)))
///   assert_eq(arr, [(0, 5), (1, 4), (2, 3), (3, 2), (4, 1)])
/// ```
pub fn[T] FixedArray::rev_eachi(
  self : FixedArray[T],
  f : (Int, T) -> Unit raise?,
) -> Unit raise? {
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
  let f = (index, elem) => {
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
    assert_false(failed)
    inspect(i, content="1")
    inspect(j, content="0")
  }
  {
    i = 2
    j = 0
    ([1] : FixedArray[_]).rev_eachi(f)
    assert_false(failed)
    inspect(i, content="1")
    inspect(j, content="1")
  }
  i = 6
  j = 0
  ([1, 2, 3, 4, 5] : FixedArray[_]).rev_eachi(f)
  assert_false(failed)
  inspect(i, content="1")
  inspect(j, content="5")
}

///|
/// Applies a function to each element of the array and returns a new array with the results.
///
/// # Example
///
/// ```mbt
///   let arr = [1, 2, 3, 4, 5]
///   let doubled = arr.map(x => x * 2)
///   assert_eq(doubled, [2, 4, 6, 8, 10])
/// ```
pub fn[T, U] FixedArray::map(
  self : FixedArray[T],
  f : (T) -> U raise?,
) -> FixedArray[U] raise? {
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
  let empty : FixedArray[Unit] = FixedArray::default().map(x => x)
  assert_eq(empty, [])
  let simple_arr : FixedArray[_] = [6]
  let simple_doubled = simple_arr.map(x => x * 2)
  assert_eq(simple_doubled, [12])
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let doubled = arr.map(x => x * 2)
  assert_eq(doubled, [2, 4, 6, 8, 10])
}

///|
/// Maps a function over the elements of the arr with index.
///
/// # Example
/// ```mbt
///   let arr = [3, 4, 5]
///   let added = arr.mapi((i, x) => { x + i })
///   assert_eq(added, [3, 5, 7])
/// ```
pub fn[T, U] FixedArray::mapi(
  self : FixedArray[T],
  f : (Int, T) -> U raise?,
) -> FixedArray[U] raise? {
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
  let empty : FixedArray[Int] = FixedArray::default().mapi((i, x) => x + i)
  assert_eq(empty, [])
  let simple_arr : FixedArray[_] = [6]
  let simple_doubled = simple_arr.mapi((i, x) => x * 2 + i)
  assert_eq(simple_doubled, [12])
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let doubled = arr.mapi((i, x) => x * 2 + i)
  assert_eq(doubled, [2, 5, 8, 11, 14])
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
///   let arr = FixedArray::makei(3, i => i * 2)
///   inspect(arr, content="[0, 2, 4]")
/// ```
#locals(value)
pub fn[T] FixedArray::makei(
  length : Int,
  value : (Int) -> T raise?,
) -> FixedArray[T] raise? {
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
  let empty = FixedArray::makei(0, i => i)
  inspect(empty.length(), content="0")
  let simple_arr = FixedArray::makei(1, i => i)
  inspect(simple_arr.length(), content="1")
  inspect(simple_arr[0], content="0")
  let arr = FixedArray::makei(2, i => i)
  inspect(arr.length(), content="2")
  inspect(arr[0], content="0")
  inspect(arr[1], content="1")
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
///   let dynamic_array = [1, 2, 3, 4, 5]
///   let fixed_array = FixedArray::from_array(dynamic_array)
///   inspect(fixed_array, content="[1, 2, 3, 4, 5]")
/// ```
pub fn[T] FixedArray::from_array(array : ArrayView[T]) -> FixedArray[T] {
  FixedArray::makei(array.length(), i => array.unsafe_get(i))
}

///|
test "from_array" {
  let array = FixedArray::from_array([1, 2, 3, 4, 5])
  assert_eq(array, [1, 2, 3, 4, 5])
}

///|
/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5].fold(init=0, (sum, elem) => sum + elem)
///   inspect(sum, content="15")
/// ```
pub fn[A, B] FixedArray::fold(
  self : FixedArray[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
test "fold" {
  let sum = ([] : FixedArray[_]).fold(init=1, (sum, elem) => sum + elem)
  inspect(sum, content="1")
  let sum = ([1] : FixedArray[_]).fold(init=2, (sum, elem) => sum + elem)
  inspect(sum, content="3")
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).fold(init=0, (sum, elem) => sum +
    elem)
  inspect(sum, content="15")
}

///|
/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5].rev_fold(init=0, (sum, elem) => sum + elem)
///   inspect(sum, content="15")
/// ```
pub fn[A, B] FixedArray::rev_fold(
  self : FixedArray[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
test "rev_fold" {
  let sum = ([] : FixedArray[_]).rev_fold(init=1, (sum, elem) => sum + elem)
  inspect(sum, content="1")
  let sum = ([1] : FixedArray[_]).rev_fold(init=2, (sum, elem) => sum + elem)
  inspect(sum, content="3")
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).rev_fold(init=0, (sum, elem) => sum +
    elem)
  inspect(sum, content="15")
}

///|
/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5].foldi(init=0, (index, sum, _elem) => sum + index)
///   inspect(sum, content="10")
/// ```
pub fn[A, B] FixedArray::foldi(
  self : FixedArray[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

///|
test "fold_lefti" {
  let f = (index, sum, elem) => index + sum + elem
  {
    let sum = ([] : FixedArray[_]).foldi(init=1, f)
    inspect(sum, content="1")
  }
  {
    let sum = ([1] : FixedArray[_]).foldi(init=2, f)
    inspect(sum, content="3")
  }
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).foldi(init=0, f)
  inspect(sum, content="25")
}

///|
/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5].rev_foldi(init=0, (index, sum, _elem) => sum + index)
///   inspect(sum, content="10")
/// ```
pub fn[A, B] FixedArray::rev_foldi(
  self : FixedArray[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
  let len = self.length()
  for i = len - 1, acc = init; i >= 0; {
    continue i - 1, f(len - i - 1, acc, self[i])
  } else {
    acc
  }
}

///|
test "rev_foldi" {
  let f = (index, sum, elem) => index + sum + elem
  {
    let sum = ([] : FixedArray[_]).rev_foldi(init=1, f)
    inspect(sum, content="1")
  }
  {
    let sum = ([1] : FixedArray[_]).rev_foldi(init=2, f)
    inspect(sum, content="3")
  }
  let sum = ([1, 2, 3, 4, 5] : FixedArray[_]).rev_foldi(init=0, f)
  inspect(sum, content="25")
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
///   let arr : FixedArray[_] = [1, 2, 3, 4, 5]
///   arr.rev_inplace()
///   inspect(arr, content="[5, 4, 3, 2, 1]")
/// ```
pub fn[T] FixedArray::rev_inplace(self : FixedArray[T]) -> Unit {
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
///   let arr : FixedArray[Int] = [1, 2, 3, 4, 5]
///   inspect(arr.rev(), content="[5, 4, 3, 2, 1]")
///   // Original array remains unchanged
///   inspect(arr, content="[1, 2, 3, 4, 5]")
/// ```
pub fn[T] FixedArray::rev(self : FixedArray[T]) -> FixedArray[T] {
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
    assert_eq(arr, [])
  }
  {
    let arr : FixedArray[_] = [1]
    arr.rev_inplace()
    assert_eq(arr, [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    arr.rev_inplace()
    assert_eq(arr, [2, 1])
  }
  {
    let arr : FixedArray[_] = [1, 2, 3, 4, 5]
    arr.rev_inplace()
    assert_eq(arr, [5, 4, 3, 2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6]
  arr.rev_inplace()
  assert_eq(arr, [6, 5, 4, 3, 2, 1])
}

///|
test "rev" {
  {
    let arr : FixedArray[Int] = []
    assert_eq(arr.rev(), [])
  }
  {
    let arr : FixedArray[_] = [1]
    assert_eq(arr.rev(), [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    assert_eq(arr.rev(), [2, 1])
  }
  {
    let arr : FixedArray[_] = [1, 2, 3, 4, 5]
    assert_eq(arr.rev(), [5, 4, 3, 2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6]
  assert_eq(arr.rev(), [6, 5, 4, 3, 2, 1])
}

///|
/// Swap two elements in the array.
///
/// # Example
///
/// ```mbt
///   let arr = [1, 2, 3, 4, 5]
///   arr.swap(0, 1)
///   assert_eq(arr, [2, 1, 3, 4, 5])
/// ```
pub fn[T] FixedArray::swap(self : FixedArray[T], i : Int, j : Int) -> Unit {
  let temp = self[i]
  self[i] = self[j]
  self[j] = temp
}

///|
test "swap" {
  {
    let arr : FixedArray[Int] = [1]
    arr.swap(0, 0)
    assert_eq(arr, [1])
  }
  {
    let arr : FixedArray[_] = [1, 2]
    arr.swap(0, 0)
    assert_eq(arr, [1, 2])
    arr.swap(0, 1)
    assert_eq(arr, [2, 1])
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  arr.swap(3, 3)
  assert_eq(arr, [1, 2, 3, 4, 5])
  arr.swap(1, 3)
  assert_eq(arr, [1, 4, 3, 2, 5])
}

///|
/// Check if all the elements in the array match the condition.
///
/// # Example
///
/// ```mbt
///   let arr: FixedArray[Int] = [1, 2, 3, 4, 5]
///   assert_true(arr.all(ele => ele < 6))
///   assert_false(arr.all(ele => ele < 5))
/// ```
pub fn[T] FixedArray::all(
  self : FixedArray[T],
  f : (T) -> Bool raise?,
) -> Bool raise? {
  for i in 0..<self.length() {
    if !f(self[i]) {
      return false
    }
  }
  true
}

///|
test "all" {
  {
    let arr : FixedArray[Int] = []
    assert_true(arr.all(ele => ele < 6))
    assert_true(arr.all(ele => ele < 5))
  }
  {
    let arr : FixedArray[_] = [5]
    assert_true(arr.all(ele => ele < 6))
    assert_false(arr.all(ele => ele < 5))
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  assert_true(arr.all(ele => ele < 6))
  assert_false(arr.all(ele => ele < 5))
}

///|
/// Check if any of the elements in the array match the condition.
///
/// # Example
///
/// ```mbt
///   let arr: FixedArray[Int] = [1, 2, 3, 4, 5]
///   assert_true(arr.any((ele)=> { ele < 6 }))
///   assert_true(arr.any((ele)=> { ele < 5 }))
/// ```
pub fn[T] FixedArray::any(
  self : FixedArray[T],
  f : (T) -> Bool raise?,
) -> Bool raise? {
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
    assert_false(arr.any(ele => ele < 6))
    assert_false(arr.any(ele => ele < 5))
  }
  {
    let arr : FixedArray[_] = [5]
    assert_true(arr.any(ele => ele < 6))
    assert_false(arr.any(ele => ele < 5))
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  assert_true(arr.any(ele => ele < 6))
  assert_true(arr.any(ele => ele < 5))
}

///|
test "fill" {
  {
    let arr : FixedArray[Int] = []
    arr.fill(3)
    assert_eq(arr, [])
  }
  {
    let arr : FixedArray[_] = [6]
    arr.fill(5)
    assert_eq(arr, [5])
  }
  let arr : FixedArray[_] = [0, 0, 0, 0, 0]
  arr.fill(3)
  assert_eq(arr, [3, 3, 3, 3, 3])
}

///|
/// Search the array index for a given element.
///
/// # Example
/// ```mbt
///   let arr: FixedArray[Int] = [3, 4, 5]
///   assert_eq(arr.search(3), Some(0))
/// ```
pub fn[T : Eq] FixedArray::search(self : FixedArray[T], value : T) -> Int? {
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
    assert_eq(arr.search(3), None)
    assert_eq(arr.search(-1), None)
  }
  {
    let arr : FixedArray[_] = [3]
    assert_eq(arr.search(3), Some(0))
    assert_eq(arr.search(-1), None)
  }
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  assert_eq(arr.search(1), Some(0))
  assert_eq(arr.search(5), Some(4))
  assert_eq(arr.search(3), Some(2))
  assert_eq(arr.search(-1), None)
}

///|
/// Checks if the array contains an element.
///
/// # Example
/// ```mbt
///   let arr: FixedArray[Int] = [3, 4, 5]
///   assert_true(arr.contains(3))
/// ```
pub fn[T : Eq] FixedArray::contains(self : FixedArray[T], value : T) -> Bool {
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
    assert_false(arr.contains(3))
    assert_false(arr.contains(-1))
  }
  {
    let arr : FixedArray[_] = [3]
    assert_true(arr.contains(3))
    assert_false(arr.contains(-1))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  assert_true(arr.contains(3))
  assert_true(arr.contains(4))
  assert_true(arr.contains(5))
  assert_false(arr.contains(6))
}

///|
/// Check if the array starts with a given prefix.
///
/// # Example
/// ```mbt
///   let arr: FixedArray[Int] = [3, 4, 5]
///   assert_true(arr.starts_with([3, 4]))
/// ```
pub fn[T : Eq] FixedArray::starts_with(
  self : FixedArray[T],
  prefix : FixedArray[T],
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
    assert_true(arr.starts_with([]))
    assert_false(arr.starts_with([1]))
  }
  {
    let arr : FixedArray[_] = [3]
    assert_true(arr.starts_with([]))
    assert_true(arr.starts_with([3]))
    assert_false(arr.starts_with([2]))
    assert_false(arr.starts_with([3, 1]))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  assert_true(arr.starts_with([]))
  assert_true(arr.starts_with([3]))
  assert_false(arr.starts_with([2]))
  assert_true(arr.starts_with([3, 4]))
  assert_false(arr.starts_with([3, 2]))
  assert_true(arr.starts_with([3, 4, 5]))
  assert_false(arr.starts_with([3, 4, 2]))
  assert_false(arr.starts_with([3, 4, 5, 6]))
}

///|
/// Check if the array ends with a given suffix.
///
/// # Example
/// ```mbt
///   let v: FixedArray[Int] = [3, 4, 5]
///   assert_true(v.ends_with([5]))
/// ```
pub fn[T : Eq] FixedArray::ends_with(
  self : FixedArray[T],
  suffix : FixedArray[T],
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
    assert_true(arr.ends_with([]))
    assert_false(arr.ends_with([1]))
  }
  {
    let arr : FixedArray[_] = [3]
    assert_true(arr.ends_with([]))
    assert_true(arr.ends_with([3]))
    assert_false(arr.ends_with([2]))
    assert_false(arr.ends_with([3, 1]))
  }
  let arr : FixedArray[_] = [3, 4, 5]
  assert_true(arr.ends_with([]))
  assert_true(arr.ends_with([5]))
  assert_false(arr.ends_with([2]))
  assert_true(arr.ends_with([4, 5]))
  assert_false(arr.ends_with([4, 2]))
  assert_false(arr.ends_with([2, 5]))
  assert_true(arr.ends_with([3, 4, 5]))
  assert_false(arr.ends_with([3, 4, 2]))
  assert_false(arr.ends_with([3, 2, 5]))
  assert_false(arr.ends_with([2, 4, 5]))
  assert_false(arr.ends_with([3, 4, 5, 6]))
  assert_false(arr.ends_with([2, 3, 4, 5]))
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
///   let arr1 : FixedArray[Int] = [1, 2, 3]
///   let arr2 : FixedArray[Int] = [1, 2, 3]
///   let arr3 : FixedArray[Int] = [1, 2, 4]
///   inspect(arr1 == arr2, content="true")
///   inspect(arr1 == arr3, content="false")
/// ```
pub impl[T : Eq] Eq for FixedArray[T] with equal(
  self : FixedArray[T],
  that : FixedArray[T],
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
test "equal" {
  {
    inspect(([] : FixedArray[Int]) == [], content="true")
    inspect(([] : FixedArray[_]) == [1], content="false")
    inspect(([1, 2] : FixedArray[_]) == [], content="false")
  }
  {
    inspect(([1] : FixedArray[_]) == [1], content="true")
    inspect(([1] : FixedArray[_]) == [2], content="false")
    inspect(([1, 2] : FixedArray[_]) == [1], content="false")
    inspect(([1] : FixedArray[_]) == [1, 2], content="false")
  }
  inspect(([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 3, 4, 5], content="true")
  inspect(([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 3, 4], content="false")
  inspect(([1, 2, 3, 4] : FixedArray[_]) == [1, 2, 3, 4, 5], content="false")
  inspect(([1, 2, 3, 4, 5] : FixedArray[_]) == [6, 2, 3, 4, 5], content="false")
  inspect(([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 6, 4, 5], content="false")
  inspect(([1, 2, 3, 4, 5] : FixedArray[_]) == [1, 2, 3, 4, 6], content="false")
}

///|
/// Compares two fixed arrays based on shortlex order by their elements. First
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
///   let arr1 = [1, 2, 3]
///   let arr2 = [1, 2, 4]
///   let arr3 = [1, 2]
///   inspect(arr1.compare(arr2), content="-1") // arr1 < arr2
///   inspect(arr2.compare(arr1), content="1") // arr2 > arr1
///   inspect(arr1.compare(arr3), content="1") // arr1 > arr3 (longer)
///   inspect(arr1.compare(arr1), content="0") // arr1 = arr1
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
///   let arr1 : FixedArray[Int] = [1, 2, 3]
///   let arr2 : FixedArray[Int] = [4, 5, 6]
///   inspect(arr1 + arr2, content="[1, 2, 3, 4, 5, 6]")
/// ```
pub impl[T] Add for FixedArray[T] with add(self, other) {
  let slen = self.length()
  let nlen = other.length()
  FixedArray::makei(slen + nlen, i => if i < slen {
    self[i]
  } else {
    other[i - slen]
  })
}

///|
test "add" {
  {
    inspect(([] : FixedArray[Int]) + [], content="[]")
    inspect(([] : FixedArray[_]) + [1, 2, 3, 4, 5], content="[1, 2, 3, 4, 5]")
    inspect(([1, 2, 3, 4, 5] : FixedArray[_]) + [], content="[1, 2, 3, 4, 5]")
  }
  {
    inspect(([1] : FixedArray[_]) + [2], content="[1, 2]")
    inspect(
      ([1] : FixedArray[_]) + [1, 2, 3, 4, 5],
      content="[1, 1, 2, 3, 4, 5]",
    )
    inspect(
      ([1, 2, 3, 4, 5] : FixedArray[_]) + [1],
      content="[1, 2, 3, 4, 5, 1]",
    )
  }
  inspect(
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
  iter.each(x => {
    exb.write_string(x.to_string())
    exb.write_char('\n')
    i = i + 1
  })
  assert_eq(i, arr.length())
  inspect(
    exb,
    content=(
      #|1
      #|2
      #|3
      #|4
      #|5
      #|
    ),
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
///   let arr = [1, 2, 3]
///   let fixed_arr = FixedArray::from_iter(arr.iter())
///   inspect(fixed_arr, content="[1, 2, 3]")
/// ```
pub fn[T] FixedArray::from_iter(iter : Iter[T]) -> FixedArray[T] {
  FixedArray::from_array(iter.collect())
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
///   let arr = [1, 2, 3]
///   let fixed_arr = FixedArray::from_iterator(arr.iterator())
///   inspect(fixed_arr, content="[1, 2, 3]")
/// ```
pub fn[T] FixedArray::from_iterator(iter : Iterator[T]) -> FixedArray[T] {
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
///   let array : FixedArray[Int] = [1, 2, 3]
///   inspect(array.last(), content="Some(3)")
///   let empty : FixedArray[Int] = []
///   inspect(empty.last(), content="None")
/// ```
pub fn[A] FixedArray::last(self : FixedArray[A]) -> A? {
  match self {
    [] => None
    [.., last] => Some(last)
  }
}

///|
/// Concatenate strings within an array into a single complete string.
///
/// Example:
/// 
/// ```moonbit
///   let fixed_array : FixedArray[String] = ["1", "2", "3"]
///   inspect(fixed_array.join(","), content="1,2,3")
/// ```
pub fn FixedArray::join(
  self : FixedArray[String],
  separator : StringView,
) -> String {
  let len = self.length()
  if len == 0 {
    return ""
  }
  let first = self[0]
  let mut size_hint = first.length()
  for i in 1..<len {
    size_hint += separator.length() + self[i].length()
  }
  let string = StringBuilder::new(size_hint~)
  if separator.length() == 0 {
    for i in 0..<len {
      string.write_string(self[i])
    }
  } else {
    string.write_string(self[0])
    for i in 1..<len {
      string.write_substring(
        separator.data(),
        separator.start_offset(),
        separator.length(),
      )
      string.write_string(self[i])
    }
  }
  string.to_string()
}

///|
test "FixedArray::last/empty" {
  let empty : FixedArray[Int] = []
  inspect(empty.last(), content="None")
}

///|
test "FixedArray::last/non_empty" {
  let array : FixedArray[_] = [1, 2, 3]
  inspect(array.last(), content="Some(3)")
  let single : FixedArray[_] = [42]
  inspect(single.last(), content="Some(42)")
}

///|
test "FixedArray::last/empty_array" {
  let empty_array : FixedArray[Int] = []
  inspect(FixedArray::last(empty_array), content="None")
}

///|
test "FixedArray::last/single_element" {
  let single_element_array : FixedArray[Int] = [42]
  inspect(FixedArray::last(single_element_array), content="Some(42)")
}

///|
test "FixedArray::last/multiple_elements" {
  let multiple_elements_array : FixedArray[Int] = [1, 2, 3, 4, 5]
  inspect(FixedArray::last(multiple_elements_array), content="Some(5)")
}

///|
test "FixedArray::join" {
  let fixed_array : FixedArray[String] = ["1", "2", "3"]
  inspect(fixed_array.join(","), content="1,2,3")
  inspect(fixed_array.join(""), content="123")
  inspect(fixed_array.join(" "), content="1 2 3")
  let fixed_array_empty : FixedArray[String] = []
  inspect(fixed_array_empty.join(","), content="")
}

///|
pub fn[X] FixedArray::iterator(self : FixedArray[X]) -> Iterator[X] {
  self[:].iterator()
}
