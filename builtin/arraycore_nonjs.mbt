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
fn[T] set_null(self : UninitializedArray[T], index : Int) = "%fixedarray.set_null"

///|
/// An `Array` is a collection of values that supports random access and can
/// grow in size.
struct Array[T] {
  mut buf : UninitializedArray[T]
  mut len : Int
}

///|
fn[T] Array::make_uninit(len : Int) -> Array[T] {
  { buf: UninitializedArray::make(len), len }
}

///|
/// Creates a new empty array with an optional initial capacity.
///
/// Parameters:
///
/// * `capacity` : The initial capacity of the array. If 0 (default), creates an
/// array with minimum capacity. Must be non-negative.
///
/// Returns a new empty array of type `Array[T]` with the specified initial
/// capacity.
///
/// Example:
///
/// ```moonbit
///   let arr : Array[Int] = Array::new(capacity=10)
///   inspect(arr.length(), content="0")
///   inspect(arr.capacity(), content="10")
///
///   let arr : Array[Int] = Array::new()
///   inspect(arr.length(), content="0")
/// ```
pub fn[T] Array::new(capacity? : Int = 0) -> Array[T] {
  if capacity == 0 {
    []
  } else {
    { buf: UninitializedArray::make(capacity), len: 0 }
  }
}

///|
/// Returns the number of elements in the array.
///
/// Parameters:
///
/// * `array` : The array whose length is to be determined.
///
/// Returns the number of elements in the array as an integer.
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3]
///   inspect(arr.length(), content="3")
///   let empty : Array[Int] = []
///   inspect(empty.length(), content="0")
/// ```
#intrinsic("%array.length")
pub fn[T] Array::length(self : Array[T]) -> Int {
  self.len
}

///|
/// Truncates the array to the specified length. This function is marked as
/// `unsafe` because it directly manipulates the internal buffer of the array,
/// which can lead to undefined behavior if not used carefully.
///
/// # Parameters
///
/// - `self` : The array to be truncated.
/// - `new_len` : The new length to which the array should be truncated. Must be
/// less than or equal to the current length of the array.
///
/// # Returns
///
/// - `Unit` : This function does not return a value.
///
/// # Errors
///
/// - This function does not explicitly raise errors, but improper use (e.g.,
/// setting `new_len` greater than the current length) can lead to undefined
/// behavior.
///
/// TODO: this can be optimized by using the intrinsic to null out the range
fn[T] Array::unsafe_truncate_to_length(self : Array[T], new_len : Int) -> Unit {
  let len = self.length()
  guard new_len <= len
  for i in new_len..<len {
    self.buf.set_null(i)
  }
  self.len = new_len
}

///|
test "unsafe_truncate_to_length" {
  let arr = [1, 2, 3, 4, 5]
  arr.unsafe_truncate_to_length(3)
  inspect(arr, content="[1, 2, 3]")
}

///|
fn[T] Array::buffer(self : Array[T]) -> UninitializedArray[T] {
  self.buf
}

///|
fn[T] Array::resize_buffer(self : Array[T], new_capacity : Int) -> Unit {
  let new_buf = UninitializedArray::make(new_capacity)
  let old_buf = self.buf
  let old_cap = old_buf.0.length()
  let copy_len = if old_cap < new_capacity { old_cap } else { new_capacity }
  UninitializedArray::unsafe_blit(new_buf, 0, old_buf, 0, copy_len)
  self.buf = new_buf
}

///|
test "array_unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq(dst[i], src[i])
  }
}

///|
test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq(dst[i], src[i])
  }
}

///|
test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq(dst[i], src[i])
  }
}

///|
test "Array::resize_buffer" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.resize_buffer(4)
  assert_eq(arr.buffer().0.length() >= 4, true)
  arr.push(3)
  arr.push(4)
  assert_eq(arr.length(), 4)
  assert_eq(arr[0], 1)
  assert_eq(arr[1], 2)
  assert_eq(arr[2], 3)
  assert_eq(arr[3], 4)
}

///|
/// Reallocate the array with a new capacity.
fn[T] Array::realloc(self : Array[T]) -> Unit {
  let old_cap = self.length()
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  self.resize_buffer(new_cap)
}

///|
/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// # Example
///
/// ```mbt
///   let v = [1]
///   v.reserve_capacity(10)
///   assert_eq(v.capacity(), 10)
/// ```
pub fn[T] Array::reserve_capacity(self : Array[T], capacity : Int) -> Unit {
  if self.capacity() >= capacity {
    return
  }
  self.resize_buffer(capacity)
}

///|
/// Shrinks the capacity of the array as much as possible.
///
/// # Example
///
/// ```mbt
///   let v = Array::new(capacity=10)
///   v.push(1)
///   v.push(2)
///   v.push(3)
///   v.shrink_to_fit()
///   assert_eq(v.capacity(), 3)
/// ```
pub fn[T] Array::shrink_to_fit(self : Array[T]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  self.resize_buffer(self.length())
}

///|
/// Adds an element to the end of the array.
///
/// If the array is at capacity, it will be reallocated.
///
/// # Example
/// ```mbt
///   let v = []
///   v.push(3)
/// ```
pub fn[T] Array::push(self : Array[T], value : T) -> Unit {
  if self.length() == self.buffer().0.length() {
    self.realloc()
  }
  let length = self.length()
  self.unsafe_set(length, value)
  self.len = length + 1
}

///|
/// Removes the last element from a array and returns it, or `None` if it is empty.
///
/// # Example
/// ```mbt
///   let v = [1, 2, 3]
///   assert_eq(v.pop(), Some(3))
///   assert_eq(v, [1, 2])
/// ```
pub fn[T] Array::pop(self : Array[T]) -> T? {
  let len = self.length()
  if len == 0 {
    None
  } else {
    let index = len - 1
    let v = self.unsafe_get(index)
    self.buf.set_null(index)
    self.len = index
    Some(v)
  }
}

///|
/// Removes and returns the last element from the array.
///
/// Parameters:
///
/// * `array` : The array from which to remove and return the last element.
///
/// Returns the last element of the array before removal.
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3]
///   inspect(arr.unsafe_pop(), content="3")
///   inspect(arr, content="[1, 2]")
/// ```
///
#internal(unsafe, "Panic if the array is empty.")
#alias(pop_exn, deprecated)
pub fn[T] Array::unsafe_pop(self : Array[T]) -> T {
  let len = self.length()
  guard len != 0
  let index = len - 1
  let v = self.unsafe_get(index)
  self.buf.set_null(index)
  self.len = index
  v
}

///|
/// Removes and returns the element at position index within the array, 
/// shifting all elements after it to the left.
/// 
/// This function will panic if the index is out of bounds.
///
/// # Example
/// ```mbt
///   let v = [3, 4, 5]
///   assert_eq(v.remove(1), 4)
///   assert_eq(v, [3, 5])
/// ```
pub fn[T] Array::remove(self : Array[T], index : Int) -> T {
  guard index >= 0 && index < self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  let value = self.unsafe_get(index)
  UninitializedArray::unsafe_blit(
    self.buffer(),
    index,
    self.buffer(),
    index + 1,
    self.length() - index - 1,
  )
  self.unsafe_truncate_to_length(self.length() - 1)
  value
}

///|
/// Removes the specified range from the array and returns it.
///
/// This functions returns a array range from `begin` to `end` `[begin, end)`
/// 
/// This function will panic if the index is out of bounds.
///
/// # Example
/// ```mbt
///   let v = [3, 4, 5]
///   let vv = v.drain(1, 2) // vv = [4], v = [3, 5]
///   assert_eq(vv, [4])
///   assert_eq(v, [3, 5])
/// ```
pub fn[T] Array::drain(self : Array[T], begin : Int, end : Int) -> Array[T] {
  guard begin >= 0 && end <= self.length() && begin <= end
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
  self.unsafe_truncate_to_length(self.length() - num)
  v
}

///|
/// Inserts an element at a given index within the array.
/// This function will panic if the index is out of bounds.
///
/// # Example
/// ```mbt
///   [3, 4, 5].insert(1, 6)
/// ```
pub fn[T] Array::insert(self : Array[T], index : Int, value : T) -> Unit {
  guard index >= 0 && index <= self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  if self.length() == self.buffer().0.length() {
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
  self.unsafe_set(index, value)
  self.len = length + 1
}

///|
/// Resize the array in-place so that `len` is equal to `new_len`.
///
/// If `new_len` is greater than `len`, the array will be extended by the
/// difference, and the values in the new slots are left uninitialized.
///  If `new_len` is less than `len`, it will panic
///
fn[T] Array::unsafe_grow_to_length(self : Array[T], new_len : Int) -> Unit {
  guard new_len >= self.length()
  let new_buf = UninitializedArray::make(new_len)
  UninitializedArray::unsafe_blit(new_buf, 0, self.buf, 0, self.len)
  self.len = new_len
  self.buf = new_buf
}

///|
/// Fills an Array with a specified value.
/// 
/// This method fills all or part of an Array with the given value.
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
/// let arr = [1, 2, 3, 4, 5]
/// arr.fill(0)
/// inspect(arr, content="[0, 0, 0, 0, 0]")
/// 
/// // Fill from index 1 to 3 (exclusive)
/// let arr2 = [1, 2, 3, 4, 5]
/// arr2.fill(99, start=1, end=3)
/// inspect(arr2, content="[1, 99, 99, 4, 5]")
/// 
/// // Fill from index 2 to end
/// let arr3 = ["a", "b", "c", "d"]
/// arr3.fill("x", start=2)
/// inspect(arr3, content=(
///   #|["a", "b", "x", "x"]
/// ))
/// ```
pub fn[A] Array::fill(
  self : Array[A],
  value : A,
  start? : Int = 0,
  end? : Int,
) -> Unit {
  let array_length = self.length()
  guard array_length > 0 else { return }
  guard start >= 0 && start < array_length
  let length = match end {
    None => array_length
    Some(e) => {
      guard e >= start && e <= array_length
      e
    }
  }
  self.buf.unchecked_fill(start, value, length - start)
}
