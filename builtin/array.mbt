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

/// Creates a new array from an array.
pub fn Array::from_fixed_array[T](arr : FixedArray[T]) -> Array[T] {
  let len = arr.length()
  let arr2 = Array::make_uninit(len)
  UninitializedArray::unsafe_blit_fixed(arr2.buffer(), 0, arr, 0, len)
  arr2
}

/// Creates a new array, with the specified length [len] and element [elem].
pub fn Array::make[T](len : Int, elem : T) -> Array[T] {
  let arr = Array::make_uninit(len)
  for i = 0; i < len; i = i + 1 {
    arr.buffer()[i] = elem
  }
  arr
}

/// Returns the total number of elements the array can hold without reallocating.
pub fn capacity[T](self : Array[T]) -> Int {
  self.buffer()._.length()
}

/// Reallocate the array with a new capacity.
fn realloc[T](self : Array[T]) -> Unit {
  let old_cap = self.length()
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  self.resize_buffer(new_cap)
}

/// Retrieves the element at the specified index from the array.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds"
pub fn op_get[T](self : Array[T], index : Int) -> T {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  self.buffer()[index]
}

/// Retrieves the element at the specified index from the array, or `None` if index is out of bounds
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// println(v.get(0)) // Some(3)
/// ```
pub fn get[T](self : Array[T], index : Int) -> T? {
  if index < 0 || index >= self.length() {
    return None
  }
  Some(self.buffer()[index])
}

/// Sets the value of the element at the specified index.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn op_set[T](self : Array[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  self.buffer()[index] = value
}

/// Compares two arrays for equality.
pub fn op_equal[T : Eq](self : Array[T], other : Array[T]) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i = 0 {
    // CR: format issue
    if i >= self.length() {
      break true
    }
    if self[i] != other[i] {
      break false
    }
    continue i + 1
  }
}

pub fn op_add[T](self : Array[T], other : Array[T]) -> Array[T] {
  let result = Array::make_uninit(self.length() + other.length())
  UninitializedArray::unsafe_blit(
    result.buffer(),
    0,
    self.buffer(),
    0,
    self.length(),
  )
  UninitializedArray::unsafe_blit(
    result.buffer(),
    self.length(),
    other.buffer(),
    0,
    other.length(),
  )
  result
}

/// Removes the last element from a array and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let v = [1, 2, 3]
/// v.pop()
/// ```
pub fn pop[T](self : Array[T]) -> T? {
  if self.length() == 0 {
    None
  } else {
    let index = self.length() - 1
    let v = self.buffer()[index]
    self.set_length(index)
    Some(v)
  }
}

/// @alert deprecated "Use `unsafe_pop` instead"
pub fn pop_exn[T](self : Array[T]) -> T {
  self.unsafe_pop()
}

/// Removes the last element from a array and returns it.
/// 
/// @alert unsafe "Panic if the array is empty."
pub fn unsafe_pop[T](self : Array[T]) -> T {
  if self.length() == 0 {
    abort("pop from an empty Array")
  }
  let index = self.length() - 1
  let v = self.buffer()[index]
  self.set_length(index)
  v
}

/// Adds an element to the end of the array.
///
/// If the array is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// ```
pub fn push[T](self : Array[T], value : T) -> Unit {
  if self.length() == self.buffer()._.length() {
    self.realloc()
  }
  let length = self.length()
  self.buffer()[length] = value
  self.set_length(length + 1)
}

/// Removes the specified range from the array and returns it.
///
/// This functions returns a array range from `begin` to `end` `[begin, end)`
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let vv = v.drain(1, 2) // vv = [4], v = [3, 5]
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn drain[T](self : Array[T], begin : Int, end : Int) -> Array[T] {
  if begin < 0 ||
    begin >= self.length() ||
    end < 0 ||
    end > self.length() ||
    begin > end {
    let len = self.length()
    abort(
      "index out of bounds: the len is \{len} but the index is (\{begin}, \{end})",
    )
  }
  let num = end - begin
  let v = Array::make_uninit(num)
  UninitializedArray::unsafe_blit(v.buffer(), 0, self.buffer(), begin, num)
  UninitializedArray::unsafe_blit(
    self.buffer(),
    begin,
    self.buffer(),
    end,
    self.length() - end,
  )
  self.set_length(self.length() - num)
  v
}

/// Appends all the elements of other array into self
///
/// # Example
/// ```
/// let v1 = [3, 4, 5]
/// let v2 = [6, 7, 8]
/// v1.append(v2)
/// ```
/// TODO: could be made more efficient doing direct mem.copy
pub fn append[T](self : Array[T], other : Array[T]) -> Unit {
  self.reserve_capacity(self.length() + other.length())
  for v in other {
    self.push(v)
  }
}

/// Iterates over the elements of the array.
///
/// # Example
/// ```
/// let v = Array::new(capacity=3)
/// v.push(3)
/// v.push(4)
/// v.push(5)
/// let mut sum = 0
/// v.each(fn (x) {sum = sum + x})
/// ```
pub fn each[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for v in self {
    f(v)
  }
}

pub fn rev_each[T](self : Array[T], f : (T) -> Unit) -> Unit {
  let len = self.length()
  for i in 0..<len {
    f(self[len - i - 1])
  }
}

/// Iterates over the elements of the array with index.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let mut sum = 0
/// v.eachi(fn (i, x) {sum = sum + x + i})
/// ```
pub fn eachi[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  for i, v in self {
    f(i, v)
  }
}

/// Iterates over the elements of the array with index in reversed order.
/// 
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let mut sum = 0
/// v.rev_eachi(fn(i, x) { sum = sum + x + i })
/// assert_eq!(sum, 15)
/// ```
pub fn rev_eachi[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  let len = self.length()
  for i in 0..<len {
    f(i, self[len - i - 1])
  }
}

/// Clears the array, removing all values.
///
/// This method has no effect on the allocated capacity of the array, only setting the length to 0.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.clear()
/// ```
pub fn clear[T](self : Array[T]) -> Unit {
  self.set_length(0)
}

/// Maps a function over the elements of the array.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.map(fn (x) {x + 1})
/// ```
pub fn map[T, U](self : Array[T], f : (T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let arr = Array::make_uninit(self.length())
  for i, v in self {
    arr.buffer()[i] = f(v)
  }
  arr
}

/// Maps a function over the elements of the array in place.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.map_inplace(fn (x) {x + 1})
/// ```
pub fn map_inplace[T](self : Array[T], f : (T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(v)
  }
}

/// Maps a function over the elements of the array with index.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.mapi(fn (i, x) {x + i})
/// ```
pub fn mapi[T, U](self : Array[T], f : (Int, T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let arr = Array::make_uninit(self.length())
  for i, v in self {
    arr.buffer()[i] = f(i, v)
  }
  arr
}

/// Maps a function over the elements of the array with index in place.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.mapi_inplace(fn (i, x) {x + i})
/// ```
pub fn mapi_inplace[T](self : Array[T], f : (Int, T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(i, v)
  }
}

/// Filters the array with a predicate function.
///
/// # Example
/// ```
/// let arr = [1, 2, 3, 4, 5, 6]
/// arr.filter(fn (x) { x % 2 == 0 }) // [2, 4, 6]
/// ```
pub fn filter[T](self : Array[T], f : (T) -> Bool) -> Array[T] {
  let arr = []
  for v in self {
    if f(v) {
      arr.push(v)
    }
  }
  arr
}

/// Test if the array is empty.
///
/// # Example
/// ```
/// let v = []
/// v.is_empty()
/// ```
pub fn is_empty[T](self : Array[T]) -> Bool {
  self.length() == 0
}

/// Test if the array is sorted.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.is_sorted() // true
/// ```
pub fn is_sorted[T : Compare](self : Array[T]) -> Bool {
  for i = 1 {
    if i >= self.length() {
      break true
    }
    if self[i - 1] > self[i] {
      break false
    }
    continue i + 1
  }
}

/// Reverses the order of elements in the Array, in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.rev_inplace()
/// ```
pub fn rev_inplace[T](self : Array[T]) -> Unit {
  for i = 0; i < self.length() / 2; i = i + 1 {
    let temp = self.buffer()[i]
    self.buffer()[i] = self.buffer()[self.length() - i - 1]
    self.buffer()[self.length() - i - 1] = temp
  }
}

/// Reverses the order of elements in the Array and returns a new Array.
pub fn rev[T](self : Array[T]) -> Array[T] {
  let arr = Array::make_uninit(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    arr.buffer()[i] = self.buffer()[self.length() - i - 1]
  }
  arr
}

/// Split the array into two at the given index.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let (v1, v2) = v.split_at(1)
/// ```
/// TODO: perf could be optimized
/// @alert unsafe "Panic if index is out of bounds."
pub fn split_at[T](self : Array[T], index : Int) -> (Array[T], Array[T]) {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  let v1 = Array::make_uninit(index)
  let v2 = Array::make_uninit(self.length() - index)
  UninitializedArray::unsafe_blit(v1.buffer(), 0, self.buffer(), 0, index)
  UninitializedArray::unsafe_blit(
    v2.buffer(),
    0,
    self.buffer(),
    index,
    self.length() - index,
  )
  (v1, v2)
}

/// Checks if the array contains an element.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.contains(3)
/// ```
pub fn contains[T : Eq](self : Array[T], value : T) -> Bool {
  for v in self {
    if v == value {
      break true
    }
  } else {
    false
  }
}

/// Check if the array starts with a given prefix.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.starts_with([3, 4])
/// ```
pub fn starts_with[T : Eq](self : Array[T], prefix : Array[T]) -> Bool {
  if prefix.length() > self.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if self.buffer()[i] != prefix.buffer()[i] {
      break false
    }
  } else {
    true
  }
}

/// Check if the array ends with a given suffix.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.ends_with([5])
/// ```
pub fn ends_with[T : Eq](self : Array[T], suffix : Array[T]) -> Bool {
  if suffix.length() > self.length() {
    return false
  }
  for i = 0; i < suffix.length(); i = i + 1 {
    if self.buffer()[self.length() - suffix.length() + i] != suffix.buffer()[i] {
      break false
    }
  } else {
    true
  }
}

/// Strip a prefix from the array.
///
/// If the array starts with the prefix, return the array after the prefix, otherwise return None.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.strip_prefix([3]) // Some([4, 5])
/// ```
pub fn strip_prefix[T : Eq](self : Array[T], prefix : Array[T]) -> Array[T]? {
  if self.starts_with(prefix) {
    let v = Array::make_uninit(self.length() - prefix.length())
    UninitializedArray::unsafe_blit(
      v.buffer(),
      0,
      self.buffer(),
      prefix.length(),
      self.length() - prefix.length(),
    )
    Some(v)
  } else {
    None
  }
}

/// Strip a suffix from the array.
///
/// If the array ends with the suffix, return the array before the suffix, otherwise return None.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.strip_suffix([5]) // Some([3, 4])
/// ```
pub fn strip_suffix[T : Eq](self : Array[T], suffix : Array[T]) -> Array[T]? {
  if self.ends_with(suffix) {
    let v = Array::make_uninit(self.length() - suffix.length())
    let len = self.length() - suffix.length()
    UninitializedArray::unsafe_blit(v.buffer(), 0, self.buffer(), 0, len)
    Some(v)
  } else {
    None
  }
}

/// Search the array index for a given element.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.search(3)
/// ```
pub fn search[T : Eq](self : Array[T], value : T) -> Int? {
  for i, v in self {
    if v == value {
      break Some(i)
    }
  } else {
    None
  }
}

/// @alert deprecated "Use `search_by` instead."
pub fn find_index[T](self : Array[T], f : (T) -> Bool) -> Int? {
  search_by(self, f)
}

/// Search the index of the first element that satisfies the predicate.
//
/// # Example
/// 
/// ```
/// let v = [1, 2, 3, 4, 5]
/// match v.search_by(fn(x) { x == 3 }) {
///   Some(index) => println(index) // 2
///   None => println("Not found")
/// }
/// ```
pub fn search_by[T](self : Array[T], f : (T) -> Bool) -> Int? {
  for i, v in self {
    if f(v) {
      break Some(i)
    }
  } else {
    None
  }
}

/// Performs a binary search on a sorted array to find the index of a given element.
/// 
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let result = v.binary_search(3)
/// assert_eq!(result, Ok(0)) // The element 3 is found at index 0
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
pub fn binary_search[T : Compare](
  self : Array[T],
  value : T
) -> Result[Int, Int] {
  let len = self.length()
  for i = 0, j = len; i < j; {
    let h = i + (j - i) / 2
    // Note even if self.buffer()[h] == value, we still continue the search
    // because we want to find the leftmost match
    if self.buffer()[h] < value {
      continue h + 1, j
    } else {
      continue i, h
    }
  } else {
    if i < len && self.buffer()[i] == value {
      Ok(i)
    } else {
      Err(i)
    }
  }
}

/// Performs a binary search on a sorted array using a custom comparator function, and returns the index of the given element.
/// 
/// The comparator function should return an `Int` that indicates whether the argument is less than `(-1)`, equal to `(0)`, or greater than `(1)` 
/// the target element.
/// 
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let result = v.binary_search_by(
///   fn(v : T) { if v < 3 { -1 } else if v == 3 { 0 } else { 1 } },
/// )
/// assert_eq!(result, Ok(0)) // The element 3 is found at index 0
/// ```
/// # Type Parameters
/// - `T`: The type of elements in the array.
/// 
/// # Arguments
/// - `self`: The array in which to perform the search.
/// - `cmp`: A closure that defines the comparator function, taking an element of type `T` and returning an `Int`.
/// 
/// # Returns
/// - `Result[Int, Int]`: If the element is found, `Ok` is returned with the index of the element.
/// If the element is not found, `Err` is returned with the index where the element could be inserted to maintain sorted order.
/// 
/// # Notes
/// - The array must be sorted, and the comparator function should be consistent with the sorted order of the array.
/// - If not, the returned result is undefined and should not be relied on.
pub fn binary_search_by[T](
  self : Array[T],
  cmp : (T) -> Int
) -> Result[Int, Int] {
  let len = self.length()
  for i = 0, j = len; i < j; {
    let h = i + (j - i) / 2
    // Note even if self.buffer()[h] == value, we still continue the search
    // because we want to find the leftmost match
    if cmp(self.buffer()[h]) < 0 {
      continue h + 1, j
    } else {
      continue i, h
    }
  } else {
    if i < len && cmp(self.buffer()[i]) == 0 {
      Ok(i)
    } else {
      Err(i)
    }
  }
}

/// Swap two elements in the array.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.swap(1, 2)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn swap[T](self : Array[T], i : Int, j : Int) -> Unit {
  if i >= self.length() || j >= self.length() || i < 0 || j < 0 {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is (\{i}, \{j})",
    )
  }
  let temp = self.buffer()[i]
  self.buffer()[i] = self.buffer()[j]
  self.buffer()[j] = temp
}

/// Remove an element from the array at a given index.
///
/// Removes and returns the element at position index within the array, shifting all elements after it to the left.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.remove(1)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn remove[T](self : Array[T], index : Int) -> T {
  if index < 0 || index >= self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  let value = self.buffer()[index]
  UninitializedArray::unsafe_blit(
    self.buffer(),
    index,
    self.buffer(),
    index + 1,
    self.length() - index - 1,
  )
  self.set_length(self.length() - 1)
  value
}

/// Retains only the elements specified by the predicate.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.retain(fn(x) { x > 3 })
/// ```
/// TODO: perf could be improved
pub fn retain[T](self : Array[T], f : (T) -> Bool) -> Unit {
  for i = 0, j = 0; i < self.length(); {
    if f(self.buffer()[i]) {
      self.buffer()[j] = self.buffer()[i]
      continue i + 1, j + 1
    }
    continue i + 1, j
  } else {
    self.set_length(j)
  }
}

/// Resize the array to a new length with a default value.
///
/// # Example
/// ```
/// [3, 4, 5].resize(1)
/// ```
/// @alert unsafe "Panic if new length is negative."
pub fn resize[T](self : Array[T], new_len : Int, f : T) -> Unit {
  if new_len < 0 {
    abort("negative new length")
  }
  if new_len < self.length() {
    self.set_length(new_len)
  } else {
    for i = self.length(); i < new_len; i = i + 1 {
      self.push(f)
    }
  }
}

/// Inserts an element at a given index within the array.
///
/// # Example
/// ```
/// [3, 4, 5].insert(1, 6)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn insert[T](self : Array[T], index : Int, value : T) -> Unit {
  if index < 0 || index > self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  if self.length() == self.buffer()._.length() {
    self.realloc()
  }
  UninitializedArray::unsafe_blit(
    self.buffer(),
    index + 1,
    self.buffer(),
    index,
    self.length() - index,
  )
  let length = self.length()
  self.buffer()[index] = value
  self.set_length(length + 1)
}

/// Flattens a array of arrays into a array.
///
/// # Example
/// ```
/// [[3, 4], [5, 6]].flatten()
/// ```
/// TODO: perf could be improved by pre-allocated
pub fn flatten[T](self : Array[Array[T]]) -> Array[T] {
  let v = []
  for arr in self {
    v.append(arr)
  }
  v
}

/// Create a array by repeat a given array for a given times.
///
/// # Example
/// ```
/// [3, 4].repeat(2)
/// ```
pub fn repeat[T](self : Array[T], times : Int) -> Array[T] {
  let v = Array::new(capacity=self.length() * times)
  for i = 0; i < times; i = i + 1 {
    v.append(self)
  }
  v
}

/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold[A, B](self : Array[A], ~init : B, f : (B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_fold(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn rev_fold[A, B](self : Array[A], ~init : B, f : (B, A) -> B) -> B {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].foldi(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn foldi[A, B](self : Array[A], ~init : B, f : (Int, B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_foldi(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn rev_foldi[A, B](self : Array[A], ~init : B, f : (Int, B, A) -> B) -> B {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(self.length() - i - 1, acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_left(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
/// @alert deprecated "Use `fold` instead."
pub fn fold_left[T, U](self : Array[T], f : (U, T) -> U, ~init : U) -> U {
  self.fold(~init, f)
}

/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_right(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
/// @alert deprecated "Use `rev_fold` instead."
pub fn fold_right[T, U](self : Array[T], f : (U, T) -> U, ~init : U) -> U {
  self.rev_fold(~init, f)
}

/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_lefti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
/// @alert deprecated "Use `foldi` instead."
pub fn fold_lefti[T, U](self : Array[T], f : (Int, U, T) -> U, ~init : U) -> U {
  self.foldi(~init, f)
}

/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_righti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
/// @alert deprecated "Use `rev_foldi` instead."
pub fn fold_righti[T, U](self : Array[T], f : (Int, U, T) -> U, ~init : U) -> U {
  self.rev_foldi(~init, f)
}

/// Removes consecutive repeated elements in the array according to the Eq trait.
///
/// # Example
/// ```
/// let v = [3, 4, 4, 5, 5, 5]
/// v.dedup() // v = [3, 4, 5]
/// ```
pub fn dedup[T : Eq](self : Array[T]) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    let mut j = i + 1
    while j < self.length() {
      if self[i] == self[j] {
        self.remove(j) |> ignore
      } else {
        j = j + 1
      }
    }
  }
}

/// Extract elements from the array according to the given function.
///
/// This function will remove the elements from the original array and return a new array.
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let vv = v.extract_if(fn(x) { x > 3 }) // vv = [4, 5], v = [3]
/// ```
pub fn extract_if[T](self : Array[T], f : (T) -> Bool) -> Array[T] {
  let v = []
  let indices = []
  for i = 0; i < self.length(); i = i + 1 {
    if f(self[i]) {
      v.push(self[i])
      indices.push(i)
    }
  }
  for i = 0; i < indices.length(); i = i + 1 {
    self.remove(indices[i] - i) |> ignore
  }
  v
}

/// Group the elements of the array into sized chunks.
///
/// If the elements of the array cannot be divided into equal-sized chunks, the last chunk will be smaller.
///
/// # Example
/// ```
/// let v = [1, 2, 3, 4, 5, 6, 7, 8, 9]
/// let chunks = v.chunks(3) // chunks = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
/// ```
pub fn chunks[T](self : Array[T], size : Int) -> Array[Array[T]] {
  let chunks = []
  let mut i = 0
  while i < self.length() {
    let chunk = Array::new(capacity=size)
    for j = 0; j < size && i < self.length(); j = j + 1 {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
  }
  chunks
}

/// Group the elements of the array into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
/// let chunks = v.chunk_by(fn(x, y) { x <= y })
/// // chunks = [[1, 1, 2, 3], [2, 3], [2, 3, 4]]
/// ```
pub fn chunk_by[T](self : Array[T], pred : (T, T) -> Bool) -> Array[Array[T]] {
  let chunks = []
  let mut i = 0
  while i < self.length() {
    let chunk = []
    chunk.push(self[i])
    i = i + 1
    while i < self.length() && pred(self[i - 1], self[i]) {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
  }
  chunks
}

/// Split the array into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = [1, 0, 2, 0, 3, 0, 4]
/// let chunks = v.split(fn(x) { x == 0 })
/// ```
pub fn split[T](self : Array[T], pred : (T) -> Bool) -> Array[Array[T]] {
  let chunks = []
  let mut i = 0
  while i < self.length() {
    let chunk = []
    while i < self.length() && pred(self[i]).not() {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
    i = i + 1
  }
  chunks
}

/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// # Example
///
/// ```
/// let v = [1]
/// v.reserve_capacity(10)
/// println(v.capacity()) // 10
/// ```
pub fn reserve_capacity[T](self : Array[T], capacity : Int) -> Unit {
  if self.capacity() >= capacity {
    return
  }
  self.resize_buffer(capacity)
}

/// Shrinks the capacity of the array as much as possible.
///
/// # Example
///
/// ```
/// let v = Array::new(capacity=10)
/// v.push(1)
/// v.push(2)
/// v.push(3)
/// println(v.capacity()) // >= 10
/// v.shrink_to_fit()
/// println(v.capacity()) // >= 3
/// ```
pub fn shrink_to_fit[T](self : Array[T]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  self.resize_buffer(self.length())
}

/// Converts the array to a string.
pub fn to_string[T : Show](self : Array[T]) -> String {
  Show::to_string(self)
}
