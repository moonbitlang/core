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
/// Creates a new dynamic array from a fixed-size array.
///
/// Parameters:
///
/// * `arr` : The fixed-size array to convert. The elements of this array will be
/// copied to the new array.
///
/// Returns a new dynamic array containing all elements from the input fixed-size
/// array.
///
/// Example:
///
/// ```moonbit
/// test "Array::from_fixed_array" {
///   let fixed = FixedArray::make(3, 42)
///   let dynamic = Array::from_fixed_array(fixed)
///   inspect!(dynamic, content="[42, 42, 42]")
/// }
/// ```
pub fn Array::from_fixed_array[T](arr : FixedArray[T]) -> Array[T] {
  let len = arr.length()
  let arr2 = Array::make_uninit(len)
  UninitializedArray::unsafe_blit_fixed(arr2.buffer(), 0, arr, 0, len)
  arr2
}

///|
/// Creates a new array with a specified length and initializes all elements with
/// the given value.
///
/// Parameters:
///
/// * `length` : The length of the array to create. Must be a non-negative
/// integer.
/// * `initial_value` : The value used to initialize all elements in the array.
///
/// Returns a new array of type `Array[T]` with `length` elements, where each
/// element is initialized to `initial_value`.
///
/// Throws an error if `length` is negative.
///
/// Example:
///
/// ```moonbit
/// test "Array::make" {
///   let arr = Array::make(3, 42)
///   inspect!(arr, content="[42, 42, 42]")
/// }
///
/// test "panic Array::make/negative_length" {
///   ignore(Array::make(-1, 0))
/// }
/// ```
pub fn Array::make[T](len : Int, elem : T) -> Array[T] {
  let arr = Array::make_uninit(len)
  for i = 0; i < len; i = i + 1 {
    arr.unsafe_set(i, elem)
  }
  arr
}

///|
/// Returns the total capacity of the array, which is the number of elements that
/// the array can hold without requiring reallocation of its internal buffer.
///
/// Parameters:
///
/// * `array` : The array whose capacity is to be determined.
///
/// Returns the current capacity of the array as an integer.
///
/// Example:
///
/// ```moonbit
/// test "Array::capacity" {
///   let arr = Array::new(capacity=10)
///   arr.push(1)
///   arr.push(2)
///   inspect!(arr.capacity(), content="10")
/// }
/// ```
pub fn capacity[T](self : Array[T]) -> Int {
  self.buffer()._.length()
}

///|
/// Retrieves the element at the specified index from an array without bounds
/// checking.
///
/// Parameters:
///
/// * `array` : The array from which to retrieve the element.
/// * `index` : The position in the array from which to retrieve the element.
///
/// Returns the element at the specified index.
///
/// Example:
///
/// ```moonbit
/// test "Array::unsafe_get/basic" {
///   let arr = [1, 2, 3]
///   inspect!(arr.unsafe_get(1), content="2")
/// }
/// ```
///
/// @alert unsafe "Panic if index is out of bounds"
pub fn unsafe_get[T](self : Array[T], idx : Int) -> T {
  self.buffer()[idx]
}

///|
/// Retrieves an element from the array at the specified index.
///
/// Parameters:
///
/// * `array` : The array to get the element from.
/// * `index` : The position in the array from which to retrieve the element.
///
/// Returns the element at the specified index.
///
/// Throws a panic if the index is negative or greater than or equal to the
/// length of the array.
///
/// Example:
///
/// ```moonbit
/// test "Array::op_get" {
///   let arr = [1, 2, 3]
///   inspect!(arr[1], content="2")
/// }
///
/// test "panic Array::op_get/out_of_bounds" {
///   let arr = [1, 2, 3]
///   ignore(arr[3]) // Index out of bounds
/// }
/// ```
///
/// @alert unsafe "Panic if index is out of bounds"
/// @intrinsic %array.get
pub fn op_get[T](self : Array[T], index : Int) -> T {
  let len = self.length()
  guard index >= 0 && index < len
  self.buffer()[index]
}

///|
/// Retrieves the element at the specified index from the array.
///
/// Parameters:
///
/// * `self` : The array to get the element from.
/// * `index` : The position in the array from which to retrieve the element.
///
/// Returns `Some(element)` if the index is within bounds, or `None` if the index
/// is out of bounds.
///
/// Example:
///
/// ```moonbit
/// test "Array::get" {
///   let arr = [1, 2, 3]
///   inspect!(arr.get(-1), content="None")
///   inspect!(arr.get(0), content="Some(1)")
///   inspect!(arr.get(3), content="None")
/// }
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
/// Sets the element at the specified index in the array to a new value. The
/// original value at that index is overwritten.
///
/// Parameters:
///
/// * `array` : The array to modify.
/// * `index` : The position in the array where the value will be set.
/// * `value` : The new value to assign at the specified index.
///
/// Throws an error if `index` is negative or greater than or equal to the length
/// of the array.
///
/// Example:
///
/// ```moonbit
/// test "Array::op_set" {
///   let arr = [1, 2, 3]
///   arr[1] = 42
///   inspect!(arr, content="[1, 42, 3]")
/// }
///
/// test "panic Array::op_set/out_of_bounds" {
///   let arr = [1, 2, 3]
///   arr[3] = 42 // Index out of bounds
/// }
/// ```
///
/// @alert unsafe "Panic if index is out of bounds."
/// @intrinsic %array.set
pub fn op_set[T](self : Array[T], index : Int, value : T) -> Unit {
  let len = self.length()
  guard index >= 0 && index < len
  self.buffer()[index] = value
}

///|
/// Compares two arrays for equality. Returns true if both arrays have the same
/// length and contain equal elements in the same order.
///
/// Parameters:
///
/// * `self` : The first array to compare.
/// * `other` : The second array to compare.
///
/// Returns true if the arrays are equal, false otherwise.
///
/// Example:
///
/// ```moonbit
/// test "Array::op_equal" {
///   let arr1 = [1, 2, 3]
///   let arr2 = [1, 2, 3]
///   let arr3 = [1, 2, 4]
///   inspect!(arr1 == arr2, content="true")
///   inspect!(arr1 == arr3, content="false")
/// }
/// ```
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
/// Compares two arrays lexicographically.
///
/// First compares the lengths of the arrays. If they differ, returns -1 if the
/// first array is shorter, 1 if it's longer. If the lengths are equal, compares
/// elements pairwise until a difference is found or all elements have been
/// compared.
///
/// Parameters:
///
/// * `self` : The first array to compare.
/// * `other` : The second array to compare.
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
/// test "Array::compare" {
///   let arr1 = [1, 2, 3]
///   let arr2 = [1, 2, 4]
///   let arr3 = [1, 2]
///   inspect!(arr1.compare(arr2), content="-1") // arr1 < arr2
///   inspect!(arr2.compare(arr1), content="1") // arr2 > arr1
///   inspect!(arr1.compare(arr3), content="1") // arr1 > arr3 (longer)
///   inspect!(arr1.compare(arr1), content="0") // arr1 = arr1
/// }
/// ```
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
/// Concatenates two arrays into a new array. The resulting array contains all
/// elements from the first array followed by all elements from the second array.
///
/// Parameters:
///
/// * `self` : The first array to concatenate.
/// * `other` : The second array to concatenate.
///
/// Returns a new array containing all elements from both arrays in order.
///
/// Example:
///
/// ```moonbit
/// test "Array::op_add" {
///   let a = [1, 2, 3]
///   let b = [4, 5]
///   inspect!(a + b, content="[1, 2, 3, 4, 5]")
/// }
/// ```
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

///|
/// Appends all elements from one array to the end of another array. The elements
/// are added in-place, modifying the original array.
///
/// Parameters:
///
/// * `self` : The array to append to.
/// * `other` : The array whose elements will be appended.
///
/// Example:
///
/// ```moonbit
/// test "Array::append" {
///   let v1 = [1, 2, 3]
///   let v2 = [4, 5, 6]
///   v1.append(v2)
///   inspect!(v1, content="[1, 2, 3, 4, 5, 6]")
/// }
///
/// test "Array::append/empty" {
///   let v1 = [1, 2, 3]
///   let v2 : Array[Int] = []
///   v1.append(v2)
///   inspect!(v1, content="[1, 2, 3]")
/// }
/// ```
pub fn append[T](self : Array[T], other : Array[T]) -> Unit {
  other.blit_to(
    self,
    len=other.length(),
    src_offset=0,
    dst_offset=self.length(),
  )
}

///|
/// Iterates through each element of the array in order, applying the given
/// function to each element.
///
/// Parameters:
///
/// * `array` : The array to iterate over.
/// * `function` : A function that takes a single element of type `T` as input
/// and returns `Unit`. This function is applied to each element of the array in
/// order.
///
/// Example:
///
/// ```moonbit
/// test "Array::each" {
///   let arr = [1, 2, 3]
///   let mut sum = 0
///   arr.each(fn(x) { sum = sum + x })
///   inspect!(sum, content="6")
/// }
/// ```
pub fn each[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for v in self {
    f(v)
  }
}

///|
/// Iterates over the elements of the array in reverse order, applying the given
/// function to each element.
///
/// Parameters:
///
/// * `array` : The array to iterate over.
/// * `f` : A function that takes an element of type `T` and returns `Unit`. This
/// function is applied to each element of the array in reverse order.
///
/// Example:
///
/// ```
/// let v = [3, 4, 5]
/// let mut sum = 0
/// v.rev_each(fn(x) { sum = sum - x })
/// @json.inspect!(sum, content=-12)
/// ```
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
/// Creates a new array containing all elements from the input array that satisfy
/// the given predicate function.
///
/// Parameters:
///
/// * `array` : The array to filter.
/// * `predicate` : A function that takes an element and returns a boolean
/// indicating whether the element should be included in the result.
///
/// Returns a new array containing only the elements for which the predicate
/// function returns `true`. The relative order of the elements is preserved.
///
/// Example:
///
/// ```moonbit
/// test "Array::filter" {
///   let arr = [1, 2, 3, 4, 5]
///   let evens = arr.filter(fn(x) { x % 2 == 0 })
///   inspect!(evens, content="[2, 4]")
/// }
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
/// Tests whether the array contains no elements.
///
/// Parameters:
///
/// * `array` : The array to check.
///
/// Returns `true` if the array has no elements, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "Array::is_empty" {
///   let empty : Array[Int] = []
///   inspect!(empty.is_empty(), content="true")
///   let non_empty = [1, 2, 3]
///   inspect!(non_empty.is_empty(), content="false")
/// }
/// ```
pub fn is_empty[T](self : Array[T]) -> Bool {
  self.length() == 0
}

///|
/// Tests whether the array is sorted in ascending order.
///
/// Parameters:
///
/// * `self` : The array to be tested.
/// * `T` : The type of elements in the array. Must implement the `Compare`
/// trait.
///
/// Returns a boolean value indicating whether the array is sorted in ascending
/// order:
///
/// * `true` if the array is empty, contains only one element, or all elements
/// are in ascending order.
/// * `false` if any element is greater than the element that follows it.
///
/// Example:
///
/// ```moonbit
/// test "Array::is_sorted/basic" {
///   let ascending = [1, 2, 3, 4, 5]
///   let descending = [5, 4, 3, 2, 1]
///   let unsorted = [1, 3, 2, 4, 5]
///   inspect!(ascending.is_sorted(), content="true")
///   inspect!(descending.is_sorted(), content="false")
///   inspect!(unsorted.is_sorted(), content="false")
/// }
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
/// Reverses the order of elements in an array in place, modifying the original
/// array.
///
/// Parameters:
///
/// * `self` : The array to be reversed.
///
/// Example:
///
/// ```moonbit
/// test "Array::rev_inplace" {
///   let arr = [1, 2, 3, 4, 5]
///   arr.rev_inplace()
///   inspect!(arr, content="[5, 4, 3, 2, 1]")
/// }
///
/// test "Array::rev_inplace/empty" {
///   let arr : Array[Int] = []
///   arr.rev_inplace()
///   inspect!(arr, content="[]")
/// }
/// ```
pub fn rev_inplace[T](self : Array[T]) -> Unit {
  for i = 0; i < self.length() / 2; i = i + 1 {
    let temp = self.unsafe_get(i)
    self.unsafe_set(i, self.unsafe_get(self.length() - i - 1))
    self.unsafe_set(self.length() - i - 1, temp)
  }
}

///|
/// Creates a new array with elements in reversed order.
///
/// Parameters:
///
/// * `self` : The array to be reversed.
///
/// Returns a new array containing the same elements as the input array but in
/// reverse order. The original array remains unchanged.
///
/// Example:
///
/// ```moonbit
/// test "Array::rev" {
///   let arr = [1, 2, 3, 4, 5]
///   inspect!(arr.rev(), content="[5, 4, 3, 2, 1]")
///   inspect!(arr, content="[1, 2, 3, 4, 5]") // original array unchanged
/// }
/// ```
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
/// Checks whether the array contains an element equal to the given value.
///
/// Parameters:
///
/// * `array` : The array to search in.
/// * `value` : The value to search for.
///
/// Returns `true` if the array contains an element equal to the given value,
/// `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "Array::contains" {
///   let arr = [1, 2, 3, 4, 5]
///   inspect!(arr.contains(3), content="true")
///   inspect!(arr.contains(6), content="false")
/// }
///
/// test "Array::contains/empty" {
///   let arr : Array[Int] = []
///   inspect!(arr.contains(1), content="false")
/// }
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
/// Checks if the array begins with all elements of the provided prefix array in
/// order.
///
/// Parameters:
///
/// * `self` : The array to check against.
/// * `prefix` : The array containing the sequence of elements to look for at the
/// beginning.
///
/// Returns `true` if the array starts with all elements in `prefix` in the same
/// order, `false` otherwise. An empty prefix array always returns `true`, and a
/// prefix longer than the array always returns `false`.
///
/// Example:
///
/// ```moonbit
/// test "Array::starts_with" {
///   let arr = [1, 2, 3, 4, 5]
///   inspect!(arr.starts_with([1, 2]), content="true")
///   inspect!(arr.starts_with([2, 3]), content="false")
///   inspect!(arr.starts_with([]), content="true")
///   inspect!(arr.starts_with([1, 2, 3, 4, 5, 6]), content="false")
/// }
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
/// Tests if an array ends with the given suffix.
///
/// Parameters:
///
/// * `self` : The array to check.
/// * `suffix` : The array to test against.
///
/// Returns `true` if the array ends with the given suffix, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "Array::ends_with/basic" {
///   let arr = [1, 2, 3, 4, 5]
///   inspect!(arr.ends_with([4, 5]), content="true")
///   inspect!(arr.ends_with([3, 4]), content="false")
///   inspect!(arr.ends_with([]), content="true")
/// }
///
/// test "Array::ends_with/empty" {
///   let arr : Array[Int] = []
///   inspect!(arr.ends_with([]), content="true")
///   inspect!(arr.ends_with([1]), content="false")
/// }
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
/// Removes a prefix from an array if it exists.
///
/// Parameters:
///
/// * `array` : The array to remove the prefix from.
/// * `prefix` : The array to be removed from the beginning of `array`.
///
/// Returns `Some(array)` containing the remaining elements after removing the
/// prefix if the array starts with the prefix, or `None` if the array doesn't
/// start with the prefix.
///
/// Example:
///
/// ```moonbit
/// test "strip_prefix" {
///   let arr = [1, 2, 3, 4, 5]
///   inspect!(arr.strip_prefix([1, 2]), content="Some([3, 4, 5])")
///   inspect!(arr.strip_prefix([2, 3]), content="None")
/// }
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
/// Searches for the first occurrence of a value in the array and returns its
/// index.
///
/// Parameters:
///
/// * `self` : The array to search in.
/// * `value` : The value to search for.
///
/// Returns an `Option` containing the index of the first occurrence of `value`
/// if found, or `None` if the value is not present in the array.
///
/// Example:
///
/// ```moonbit
/// test "Array::search" {
///   let arr = [1, 2, 3, 2, 4]
///   inspect!(arr.search(2), content="Some(1)") // first occurrence
///   inspect!(arr.search(5), content="None") // not found
/// }
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
/// Searches the array for the first element that satisfies the predicate
/// function.
///
/// Parameters:
///
/// * `array` : The array to search in.
/// * `predicate` : A function that takes an element and returns a boolean
/// indicating whether the element satisfies the search condition.
///
/// Returns the index of the first element that satisfies the predicate, or
/// `None` if no such element is found.
///
/// Example:
///
/// ```moonbit
/// test "find_index" {
///   let arr = [1, 2, 3, 4, 5]
///   inspect!(arr.search_by(fn(x) { x > 3 }), content="Some(3)")
///   inspect!(arr.search_by(fn(x) { x > 10 }), content="None")
/// }
/// ```
///
/// @alert deprecated "Use `search_by` instead."
/// @coverage.skip
pub fn find_index[T](self : Array[T], f : (T) -> Bool) -> Int? {
  search_by(self, f)
}

///|
/// Search the index of the first element that satisfies the predicate.
///
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
/// test "binary_search_by" {
///   let arr = [1, 3, 5, 7, 9]
///   let find_3 = arr.binary_search_by(fn(x) {
///     if x < 3 {
///       -1
///     } else if x > 3 {
///       1
///     } else {
///       0
///     }
///   })
///   inspect!(find_3, content="Ok(1)")
///   let find_4 = arr.binary_search_by(fn(x) {
///     if x < 4 {
///       -1
///     } else if x > 4 {
///       1
///     } else {
///       0
///     }
///   })
///   inspect!(find_4, content="Err(2)")
/// }
/// ```
///
/// Notes:
///
/// * Assumes the array is sorted according to the ordering implied by the
/// comparison function
/// * For multiple matches, returns the leftmost matching position
/// * Returns an insertion point that maintains the sort order when no match is
/// found
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
/// Swaps the values at two positions in the array.
///
/// Parameters:
///
/// * `array` : The array in which to swap elements.
/// * `index1` : The index of the first element to be swapped.
/// * `index2` : The index of the second element to be swapped.
///
/// Throws an error if either index is negative or greater than or equal to the
/// length of the array.
///
/// Example:
///
/// ```moonbit
/// test "Array::swap" {
///   let arr = [1, 2, 3]
///   arr.swap(0, 2)
///   inspect!(arr, content="[3, 2, 1]")
/// }
///
/// test "panic Array::swap/out_of_bounds" {
///   let arr = [1, 2, 3]
///   ignore(arr.swap(0, 3)) // Index out of bounds
/// }
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
/// Removes all elements from the array that do not satisfy the predicate
/// function, modifying the array in place. The order of remaining elements is
/// preserved.
///
/// Parameters:
///
/// * `array` : The array to be filtered.
/// * `predicate` : A function that takes an element and returns `true` if the
/// element should be kept, `false` if it should be removed.
///
/// Example:
///
/// ```moonbit
/// test "retain" {
///   let arr = [1, 2, 3, 4, 5]
///   arr.retain(fn(x) { x % 2 == 0 })
///   inspect!(arr, content="[2, 4]")
/// }
///
/// test "retain/empty_result" {
///   let arr = [1, 2, 3]
///   arr.retain(fn(x) { x > 10 })
///   inspect!(arr, content="[]")
/// }
///
/// test "retain/keep_all" {
///   let arr = [1, 2, 3]
///   arr.retain(fn { _ => true })
///   inspect!(arr, content="[1, 2, 3]")
/// }
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
/// Resizes an array to a specified length, either by truncating if the new
/// length is smaller, or by appending copies of a default value if the new
/// length is larger.
///
/// Parameters:
///
/// * `array` : The array to be resized.
/// * `new_length` : The desired length of the array after resizing.
/// * `default_value` : The value to append when extending the array.
///
/// Throws a panic if `new_length` is negative.
///
/// Examples:
///
/// ```moonbit
/// test "Array::resize/shrink" {
///   let arr = [1, 2, 3, 4, 5]
///   arr.resize(3, 0)
///   inspect!(arr, content="[1, 2, 3]")
/// }
///
/// test "Array::resize/extend" {
///   let arr = [1, 2, 3]
///   arr.resize(5, 0)
///   inspect!(arr, content="[1, 2, 3, 0, 0]")
/// }
///
/// test "panic Array::resize/negative_length" {
///   let arr = [1, 2, 3]
///   ignore(arr.resize(-1, 0))
/// }
/// ```
///
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
/// Example:
///
/// ```moonbit
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
/// Example:
///
/// ```moonbit
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
/// Example:
///
/// ```moonbit
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
/// Example:
///
/// ```moonbit
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
/// Example:
///
/// ```moonbit
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
/// Example:
///
/// ```moonbit
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
/// Example:
///
/// ```moonbit
/// let sum = [1, 2, 3, 4, 5].fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
/// @alert deprecated "Use `fold` instead."
/// @coverage.skip
pub fn fold_left[T, U](self : Array[T], f : (U, T) -> U, init~ : U) -> U {
  self.fold(init~, f)
}

///|
/// Fold out values from an array according to certain rules in reversed turn.
///
/// Example:
///
/// ```moonbit
/// let sum = [1, 2, 3, 4, 5].rev_fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
/// @alert deprecated "Use `rev_fold` instead."
/// @coverage.skip
pub fn fold_right[T, U](self : Array[T], f : (U, T) -> U, init~ : U) -> U {
  self.rev_fold(init~, f)
}

///|
/// Fold out values from an array according to certain rules with index.
///
/// Example:
///
/// ```moonbit
/// let sum = [1, 2, 3, 4, 5].foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
/// @alert deprecated "Use `foldi` instead."
/// @coverage.skip
pub fn fold_lefti[T, U](self : Array[T], f : (Int, U, T) -> U, init~ : U) -> U {
  self.foldi(init~, f)
}

///|
/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// Example:
///
/// ```moonbit
/// let sum = [1, 2, 3, 4, 5].rev_foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
/// @alert deprecated "Use `rev_foldi` instead."
/// @coverage.skip
pub fn fold_righti[T, U](self : Array[T], f : (Int, U, T) -> U, init~ : U) -> U {
  self.rev_foldi(init~, f)
}

///|
/// Removes consecutive duplicate elements from an array in-place, using equality
/// comparison. The first occurrence of each element is retained while subsequent
/// equal elements are removed.
///
/// Parameters:
///
/// * `array` : The array to remove duplicates from. Must contain elements that
/// implement the `Eq` trait for equality comparison.
///
/// Example:
///
/// ```moonbit
/// test "dedup" {
///   let arr = [1, 2, 2, 3, 3, 3, 2]
///   arr.dedup()
///   inspect!(arr, content="[1, 2, 3, 2]")
/// }
///
/// test "dedup/sorted" {
///   let arr = [1, 2, 2, 2, 3, 3]
///   arr.dedup()
///   inspect!(arr, content="[1, 2, 3]")
/// }
///
/// test "dedup/empty" {
///   let arr : Array[Int] = []
///   arr.dedup()
///   inspect!(arr, content="[]")
/// }
/// ```
///
/// Note: For best results when removing all duplicates regardless of position,
/// sort the array before calling this function. When used on an unsorted array,
/// this function only removes consecutive duplicates.
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
/// Extracts elements from an array that satisfy a given predicate function. The
/// extracted elements are removed from the original array and returned as a new
/// array. The relative order of the extracted elements is preserved.
///
/// Parameters:
///
/// * `array` : The array to extract elements from.
/// * `predicate` : A function that takes an element and returns `true` if the
/// element should be extracted, `false` otherwise.
///
/// Returns a new array containing all elements that satisfy the predicate
/// function, in the order they appeared in the original array.
///
/// Example:
///
/// ```moonbit
/// test "extract_if" {
///   let arr = [1, 2, 3, 4, 5]
///   let extracted = arr.extract_if(fn(x) { x % 2 == 0 })
///   inspect!(extracted, content="[2, 4]")
///   inspect!(arr, content="[1, 3, 5]")
/// }
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
/// Divides an array into smaller arrays (chunks) of the specified size.
///
/// Parameters:
///
/// * `array` : The array to be divided into chunks.
/// * `size` : The size of each chunk. Must be a positive integer.
///
/// Returns an array of arrays, where each inner array is a chunk containing
/// elements from the original array. If the length of the original array is not
/// divisible by the chunk size, the last chunk will contain fewer elements.
///
/// Example:
///
/// ```moonbit
/// test "chunks" {
///   let arr = [1, 2, 3, 4, 5]
///   let chunks = arr.chunks(2)
///   inspect!(chunks, content="[[1, 2], [3, 4], [5]]")
/// }
///
/// test "chunks/empty" {
///   let arr : Array[Int] = []
///   inspect!(arr.chunks(3), content="[]")
/// }
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
/// Groups consecutive elements of the array into chunks where adjacent elements
/// satisfy the given predicate function.
///
/// Parameters:
///
/// * `array` : The array to be chunked.
/// * `predicate` : A function that takes two adjacent elements and returns
/// `true` if they should be in the same chunk, `false` otherwise.
///
/// Returns an array of arrays, where each inner array is a chunk of consecutive
/// elements that satisfy the predicate with their adjacent elements.
///
/// Example:
///
/// ```moonbit
/// test "chunk_by" {
///   let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
///   let chunks = v.chunk_by(fn(x, y) { x <= y })
///   inspect!(chunks, content="[[1, 1, 2, 3], [2, 3], [2, 3, 4]]")
/// }
///
/// test "chunk_by/empty" {
///   let v : Array[Int] = []
///   inspect!(v.chunk_by(fn(x, y) { x <= y }), content="[]")
/// }
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
/// Splits an array into chunks using a predicate function. Creates chunks by
/// grouping consecutive elements that do not satisfy the predicate function.
/// Elements that satisfy the predicate function are excluded from the resulting
/// chunks and act as delimiters.
///
/// Parameters:
///
/// * `array` : The array to be split into chunks.
/// * `predicate` : A function that takes an element and returns `true` if the
/// element should be used as a delimiter.
///
/// Returns an array of arrays, where each inner array is a chunk of consecutive
/// elements that do not satisfy the predicate.
///
/// Example:
///
/// ```moonbit
/// test "split/basic" {
///   let arr = [1, 0, 2, 0, 3, 0, 4]
///   inspect!(arr.split(fn(x) { x == 0 }), content="[[1], [2], [3], [4]]")
/// }
///
/// test "split/empty_chunks" {
///   let arr = [0, 1, 0, 0, 2, 0]
///   inspect!(arr.split(fn(x) { x == 0 }), content="[[], [1], [], [2]]")
/// }
/// ```
pub fn split[T](self : Array[T], pred : (T) -> Bool) -> Array[Array[T]] {
  let chunks = []
  let mut i = 0
  while i < self.length() {
    let chunk = []
    while i < self.length() && not(pred(self[i])) {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
    i = i + 1
  }
  chunks
}

///|
/// Creates an iterator over the elements of the array.
///
/// Parameters:
///
/// * `array` : The array to create an iterator from.
///
/// Returns an iterator that yields each element of the array in order.
///
/// Example:
///
/// ```moonbit
/// test "Array::iter" {
///   let arr = [1, 2, 3]
///   let mut sum = 0
///   arr.iter().each(fn(x) { sum = sum + x })
///   inspect!(sum, content="6")
/// }
/// ```
pub fn iter[T](self : Array[T]) -> Iter[T] {
  Iter::new(fn(yield_) {
    for v in self {
      guard let IterContinue = yield_(v) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///|
/// Returns an iterator that yields elements from the array in reverse order,
/// from the last element to the first.
///
/// Parameters:
///
/// * `array` : The array to iterate over in reverse order.
///
/// Returns an iterator that yields each element of the array, starting from the
/// last element and moving towards the first.
///
/// Example:
///
/// ```moonbit
/// test "Array::rev_iter" {
///   let arr = [1, 2, 3]
///   let result = []
///   arr.rev_iter().each(fn(x) { result.push(x) })
///   inspect!(result, content="[3, 2, 1]")
/// }
/// ```
pub fn rev_iter[T](self : Array[T]) -> Iter[T] {
  Iter::new(fn(yield_) {
    for i = self.length() - 1; i >= 0; i = i - 1 {
      guard let IterContinue = yield_(self.unsafe_get(i)) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///|
/// Returns an iterator that provides both indices and values of the array in
/// order.
///
/// Parameters:
///
/// * `self` : The array to iterate over.
///
/// Returns an iterator that yields tuples of index and value pairs, where
/// indices start from 0.
///
/// Example:
///
/// ```moonbit
/// test "Array::iter2" {
///   let arr = [10, 20, 30]
///   let mut sum = 0
///   arr.iter2().each(fn(i, x) { sum = sum + i + x })
///   inspect!(sum, content="63") // (0 + 10) + (1 + 20) + (2 + 30) = 63
/// }
/// ```
pub fn iter2[A](self : Array[A]) -> Iter2[Int, A] {
  Iter2::new(fn(yield_) {
    for i, v in self {
      guard let IterContinue = yield_(i, v) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///|
/// Creates a new empty array.
///
/// Returns an empty array of type `Array[T]`.
///
/// Example:
///
/// ```moonbit
/// test "Array::default" {
///   let arr : Array[Int] = Array::default()
///   inspect!(arr.length(), content="0")
///   inspect!(arr.is_empty(), content="true")
/// }
/// ```
pub fn Array::default[T]() -> Array[T] {
  []
}
