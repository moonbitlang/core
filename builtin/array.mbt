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
/// Creates a new array from an array.
pub fn Array::from_fixed_array[T](arr : FixedArray[T]) -> Array[T] {
  let len = arr.length()
  let arr2 = Array::make_uninit(len)
  UninitializedArray::unsafe_blit_fixed(arr2.buffer(), 0, arr, 0, len)
  arr2
}

///|
/// Creates a new array, with the specified length [len] and element [elem].
pub fn Array::make[T](len : Int, elem : T) -> Array[T] {
  let arr = Array::make_uninit(len)
  for i = 0; i < len; i = i + 1 {
    arr.unsafe_set(i, elem)
  }
  arr
}

///|
/// Returns the total number of elements the array can hold without reallocating.
pub fn capacity[T](self : Array[T]) -> Int {
  self.buffer()._.length()
}

///|
/// @intrinsic %array.unsafe_get
fn unsafe_get[T](self : Array[T], idx : Int) -> T {
  self.buffer()[idx]
}

///|
/// Retrieves the element at the specified index from the array.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// assert_eq!(v[0], 3)
/// ```
/// @alert unsafe "Panic if index is out of bounds"
/// @intrinsic %array.get
pub fn op_get[T](self : Array[T], index : Int) -> T {
  let len = self.length()
  guard index >= 0 && index < len
  self.buffer()[index]
}

///|
/// Retrieves the element at the specified index from the array, or `None` if index is out of bounds
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// assert_eq!(v.get(0), Some(3))
/// ```
pub fn get[T](self : Array[T], index : Int) -> T? {
  let len = self.length()
  guard index >= 0 && index < len else { None }
  Some(self.unsafe_get(index))
}

///|
/// @intrinsic %array.unsafe_set
fn unsafe_set[T](self : Array[T], idx : Int, val : T) -> Unit {
  self.buffer()[idx] = val
}

///|
/// Sets the value of the element at the specified index.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// assert_eq!(v[0], 3)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
/// @intrinsic %array.set
pub fn op_set[T](self : Array[T], index : Int, value : T) -> Unit {
  let len = self.length()
  guard index >= 0 && index < len
  self.buffer()[index] = value
}

///|
/// Compares two arrays for equality.
pub fn op_equal[T : Eq](self : Array[T], other : Array[T]) -> Bool {
  guard self.length() == other.length() else { return false }
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

///|
pub fn compare[T : Compare](self : Array[T], other : Array[T]) -> Int {
  let len_self = self.length()
  let len_other = other.length()
  if len_self < len_other {
    -1
  } else if len_self > len_other {
    1
  } else {
    for i in 0..<len_self {
      let cmp = self[i].compare(other[i])
      if cmp != 0 {
        break cmp
      }
    } else {
      0
    }
  }
}

///|
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

/// TODO: could be made more efficient doing direct mem.copy
// pub fn append[T](self : Array[T], other : Array[T]) -> Unit {
//   self.reserve_capacity(self.length() + other.length())
//   for v in other {
//     self.push(v)
//   }
// }

///|
/// Appends all the elements of other array into self
///
/// # Example
/// ```
/// let v1 = [3, 4, 5]
/// let v2 = [6, 7, 8]
/// v1.append(v2)
/// ```
pub fn append[T](
  self : Array[T],
  other : Array[T],
  from~ : Int = 0,
  len~ : Int = 0
) -> Unit {
  if from < 0 {
    return
  }
  let len = if len <= 0 { other.len } else { len }
  let remain = {
    let l = other.len - from
    if l > len {
      len
    } else {
      l
    }
  }
  if remain <= 0 {
    return
  }
  let oldlen = self.len
  let newLen = oldlen + remain
  self.resize_buffer(newLen)
  self.len = newLen
  Array::unsafe_blit(self, oldlen, other, from, remain)
}

///|
/// like blit
/// copy the data of length len from the 'from' position of 'other' to the offset position of 'self' and overwrite it, 
/// which will automatically expand the size
pub fn set[T](
  self : Array[T],
  offset : Int,
  other : Array[T],
  from : Int,
  len : Int
) -> Unit {
  other.blit_to(self, len~, src_offset=from, dst_offset=offset)
}

///|
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

///|
pub fn rev_each[T](self : Array[T], f : (T) -> Unit) -> Unit {
  let len = self.length()
  for i in 0..<len {
    f(self[len - i - 1])
  }
}

///|
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

///|
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

///|
/// Clears the array, removing all values.
///
/// This method has no effect on the allocated capacity of the array, only setting the length to 0.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.clear()
/// assert_eq!(v.length(), 0)
/// ```
pub fn clear[T](self : Array[T]) -> Unit {
  self.unsafe_truncate_to_length(0)
}

///|
/// Maps a function over the elements of the array.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v.map(fn (x) {x + 1})
/// assert_eq!(v2, [4, 5, 6])
/// ```
pub fn map[T, U](self : Array[T], f : (T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let arr = Array::make_uninit(self.length())
  for i, v in self {
    arr.unsafe_set(i, f(v))
  }
  arr
}

///|
/// Maps a function over the elements of the array in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.map_inplace(fn (x) {x + 1})
/// assert_eq!(v, [4, 5, 6])
/// ```
pub fn map_inplace[T](self : Array[T], f : (T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(v)
  }
}

///|
/// Maps a function over the elements of the array with index.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v.mapi(fn (i, x) {x + i})
/// assert_eq!(v2, [3, 5, 7])
/// ```
pub fn mapi[T, U](self : Array[T], f : (Int, T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let arr = Array::make_uninit(self.length())
  for i, v in self {
    arr.unsafe_set(i, f(i, v))
  }
  arr
}

///|
/// Maps a function over the elements of the array with index in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.mapi_inplace(fn (i, x) {x + i})
/// assert_eq!(v, [3, 5, 7])
/// ```
pub fn mapi_inplace[T](self : Array[T], f : (Int, T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(i, v)
  }
}

///|
/// Filters the array with a predicate function.
///
/// # Example
/// ```
/// let arr = [1, 2, 3, 4, 5, 6]
/// let v = arr.filter(fn (x) { x % 2 == 0 })
/// assert_eq!(v, [2, 4, 6])
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

///|
/// Test if the array is empty.
///
/// # Example
/// ```
/// let v : Array[Int] = []
/// assert_true!(v.is_empty())
/// ```
pub fn is_empty[T](self : Array[T]) -> Bool {
  self.length() == 0
}

///|
/// Test if the array is sorted.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// assert_true!(v.is_sorted())
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

///|
/// Reverses the order of elements in the Array, in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.rev_inplace()
/// ```
pub fn rev_inplace[T](self : Array[T]) -> Unit {
  for i = 0; i < self.length() / 2; i = i + 1 {
    let temp = self.unsafe_get(i)
    self.unsafe_set(i, self.unsafe_get(self.length() - i - 1))
    self.unsafe_set(self.length() - i - 1, temp)
  }
}

///|
/// Reverses the order of elements in the Array and returns a new Array.
pub fn rev[T](self : Array[T]) -> Array[T] {
  let arr = Array::make_uninit(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    arr.unsafe_set(i, self.unsafe_get(self.length() - i - 1))
  }
  arr
}

///|
/// Split the array into two at the given index.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let (v1, v2) = v.split_at(1)
/// assert_eq!(v1, [3])
/// assert_eq!(v2, [4, 5])
/// ```
/// TODO: perf could be optimized
/// @alert unsafe "Panic if index is out of bounds."
pub fn split_at[T](self : Array[T], index : Int) -> (Array[T], Array[T]) {
  if index < 0 || index > self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  let v1 = Array::make_uninit(index)
  let v2 = Array::make_uninit(self.length() - index)
  UninitializedArray::unsafe_blit(v1.buffer(), 0, self.buffer(), 0, index)
  if index != self.length() {
    UninitializedArray::unsafe_blit(
      v2.buffer(),
      0,
      self.buffer(),
      index,
      self.length() - index,
    )
  }
  (v1, v2)
}

///|
/// Checks if the array contains an element.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// assert_true!(v.contains(3))
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

///|
/// Check if the array starts with a given prefix.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// assert_true!(v.starts_with([3, 4]))
/// ```
pub fn starts_with[T : Eq](self : Array[T], prefix : Array[T]) -> Bool {
  if prefix.length() > self.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if self.unsafe_get(i) != prefix.unsafe_get(i) {
      break false
    }
  } else {
    true
  }
}

///|
/// Check if the array ends with a given suffix.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// assert_true!(v.ends_with([5]))
/// ```
pub fn ends_with[T : Eq](self : Array[T], suffix : Array[T]) -> Bool {
  if suffix.length() > self.length() {
    return false
  }
  for i = 0; i < suffix.length(); i = i + 1 {
    if self.unsafe_get(self.length() - suffix.length() + i) !=
      suffix.unsafe_get(i) {
      break false
    }
  } else {
    true
  }
}

///|
/// Strip a prefix from the array.
///
/// If the array starts with the prefix, return the array after the prefix, otherwise return None.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v.strip_prefix([3])
/// assert_eq!(v2, Some([4, 5]))
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

///|
/// Strip a suffix from the array.
///
/// If the array ends with the suffix, return the array before the suffix, otherwise return None.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v.strip_suffix([5])
/// assert_eq!(v2, Some([3, 4]))
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

///|
/// Search the array index for a given element.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let index = v.search(3)
/// assert_eq!(index, Some(0))
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

///|
/// @alert deprecated "Use `search_by` instead."
pub fn find_index[T](self : Array[T], f : (T) -> Bool) -> Int? {
  search_by(self, f)
}

///|
/// Search the index of the first element that satisfies the predicate.
//
/// # Example
/// 
/// ```
/// let v = [1, 2, 3, 4, 5]
/// match v.search_by(fn(x) { x == 3 }) {
///   Some(index) => assert_eq!(index, 2) // 2
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

///|
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
/// Performs a binary search on a sorted array using a custom comparator function, and returns the index of the given element.
/// 
/// The comparator function should return an `Int` that indicates whether the argument is less than `(-1)`, equal to `(0)`, or greater than `(1)` 
/// the target element.
/// 
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let result = v.binary_search_by(
///   fn(v : Int) { if v < 3 { -1 } else if v == 3 { 0 } else { 1 } },
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
  let temp = self.unsafe_get(i)
  self.unsafe_set(i, self.unsafe_get(j))
  self.unsafe_set(j, temp)
}

///|
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
    if f(self.unsafe_get(i)) {
      self.unsafe_set(j, self.unsafe_get(i))
      continue i + 1, j + 1
    }
    continue i + 1, j
  } else {
    // we use `else` here to capture `j`  
    self.unsafe_truncate_to_length(j)
  }
}

///|
/// Resize the array to a new length with a default value.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.resize(1, 0)
/// assert_eq!(v, [3])
/// ```
/// @alert unsafe "Panic if new length is negative."
pub fn resize[T](self : Array[T], new_len : Int, f : T) -> Unit {
  if new_len < 0 {
    abort("negative new length")
  }
  if new_len < self.length() {
    self.unsafe_truncate_to_length(new_len)
  } else {
    for i = self.length(); i < new_len; i = i + 1 {
      self.push(f)
    }
  }
}

///|
/// Flattens a array of arrays into a array.
///
/// # Example
/// ```
/// let v = [[3, 4], [5, 6]].flatten()
/// assert_eq!(v, [3, 4, 5, 6])
/// ```
/// TODO: perf could be improved by pre-allocated
pub fn flatten[T](self : Array[Array[T]]) -> Array[T] {
  let v = []
  for arr in self {
    v.append(arr)
  }
  v
}

///|
/// Create a array by repeat a given array for a given times.
///
/// # Example
/// ```
/// let v = [3, 4].repeat(2)
/// assert_eq!(v, [3, 4, 3, 4])
/// ```
pub fn repeat[T](self : Array[T], times : Int) -> Array[T] {
  let v = Array::new(capacity=self.length() * times)
  for i = 0; i < times; i = i + 1 {
    v.append(self)
  }
  v
}

///|
/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn fold[A, B](self : Array[A], init~ : B, f : (B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn rev_fold[A, B](self : Array[A], init~ : B, f : (B, A) -> B) -> B {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn foldi[A, B](self : Array[A], init~ : B, f : (Int, B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].rev_foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn rev_foldi[A, B](self : Array[A], init~ : B, f : (Int, B, A) -> B) -> B {
  let len = self.length()
  for i = len - 1, acc = init; i >= 0; {
    continue i - 1, f(len - i - 1, acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
/// @alert deprecated "Use `fold` instead."
pub fn fold_left[T, U](self : Array[T], f : (U, T) -> U, init~ : U) -> U {
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
/// @alert deprecated "Use `rev_fold` instead."
pub fn fold_right[T, U](self : Array[T], f : (U, T) -> U, init~ : U) -> U {
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
/// @alert deprecated "Use `foldi` instead."
pub fn fold_lefti[T, U](self : Array[T], f : (Int, U, T) -> U, init~ : U) -> U {
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
/// @alert deprecated "Use `rev_foldi` instead."
pub fn fold_righti[T, U](self : Array[T], f : (Int, U, T) -> U, init~ : U) -> U {
  self.rev_foldi(init~, f)
}

///|
/// Removes consecutive repeated elements in the array according to the Eq trait.
///
/// # Example
///
/// ```
/// let v = [3, 4, 4, 5, 5, 5]
/// v.dedup() // v = [3, 4, 5]
/// ```
///
/// # Notes
///
/// Usually, you might want to sort the array before calling this function. For example:
///
/// ```
/// let v = [3, 4, 5, 4, 5, 5]
/// v.sort()
/// v.dedup() // v = [3, 4, 5]
/// ```
pub fn dedup[T : Eq](self : Array[T]) -> Unit {
  if self.is_empty() {
    return
  }
  let mut w = 1
  for i = 1; i < self.length(); i = i + 1 {
    if self[i] != self[w - 1] {
      self[w] = self[i]
      w = w + 1
    }
  }
  self.unsafe_truncate_to_length(w)
}

///|
/// Extract elements from the array according to the given function.
///
/// This function will remove the elements from the original array and return a new array.
/// # Example
/// ```
/// let 
/// v = [3, 4, 5]
/// let vv = v.extract_if(fn(x) { x > 3 })
/// assert_eq!(vv, [4, 5])
/// assert_eq!(v, [3])
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

///|
/// Group the elements of the array into sized chunks.
///
/// If the elements of the array cannot be divided into equal-sized chunks, the last chunk will be smaller.
///
/// # Example
/// ```
/// let v = [1, 2, 3, 4, 5, 6, 7, 8, 9]
/// let chunks = v.chunks(3)
/// assert_eq!(chunks, [[1, 2, 3], [4, 5, 6], [7, 8, 9]])
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

///|
/// Group the elements of the array into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
/// let chunks = v.chunk_by(fn(x, y) { x <= y })
/// assert_eq!(chunks, [[1, 1, 2, 3], [2, 3], [2, 3, 4]])
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

///|
/// Split the array into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = [1, 0, 2, 0, 3, 0, 4]
/// let chunks = v.split(fn(x) { x == 0 })
/// assert_eq!(chunks, [[1], [2], [3], [4]])
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

///|
/// Converts the array to a string.
pub fn to_string[T : Show](self : Array[T]) -> String {
  Show::to_string(self)
}

///|
pub fn iter[T](self : Array[T]) -> Iter[T] {
  Iter::new(
    fn(yield_) {
      for v in self {
        guard let IterContinue = yield_(v) else { x => break x }

      } else {
        IterContinue
      }
    },
  )
}

///|
pub fn iter2[A](self : Array[A]) -> Iter2[Int, A] {
  Iter2::new(
    fn(yield_) {
      for i, v in self {
        guard let IterContinue = yield_(i, v) else { x => break x }

      } else {
        IterContinue
      }
    },
  )
}

///|
pub fn Array::default[T]() -> Array[T] {
  []
}
