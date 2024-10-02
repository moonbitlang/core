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

priv type UninitializedArray[T] FixedArray[UnsafeMaybeUninit[T]]

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%fixedarray.make_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%fixedarray.get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%fixedarray.set"

fn set_null[T](self : UninitializedArray[T], index : Int) = "%fixedarray.set_null"

fn UninitializedArray::unsafe_blit[T](
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : UninitializedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  FixedArray::unsafe_blit(dst._, dst_offset, src._, src_offset, len)
}

/// @intrinsic %fixedarray.copy
fn UninitializedArray::unsafe_blit_fixed[T](
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : FixedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  for i = len - 1; i >= 0; i = i - 1 {
    dst[dst_offset + i] = src[src_offset + i]
  }
}

/// An `Array` is a collection of values that supports random access and can
/// grow in size.
struct Array[T] {
  mut buf : UninitializedArray[T]
  mut len : Int
}

fn Array::make_uninit[T](len : Int) -> Array[T] {
  { buf: UninitializedArray::make(len), len }
}

/// Creates a new array.
pub fn Array::new[T](~capacity : Int = 0) -> Array[T] {
  if capacity == 0 {
    []
  } else {
    { buf: UninitializedArray::make(capacity), len: 0 }
  }
}

/// Returns the number of elements in the array.
pub fn length[T](self : Array[T]) -> Int {
  self.len
}

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
/// # Examples
///
/// ```moonbit
/// test "unsafe_truncate_to_length example" {
///  let mut arr = [1, 2, 3, 4, 5]
///  unsafe_truncate_to_length(arr, 3)
///  inspect!(arr, content="[1, 2, 3]")
/// }
/// ```
fn unsafe_truncate_to_length[T](self : Array[T], new_len : Int) -> Unit {
  let len = self.length()
  guard new_len <= len
  for i in new_len..<len {
    self.buf.set_null(i)
  }
  self.len = new_len
}

test "unsafe_truncate_to_length" {
  let arr = [1, 2, 3, 4, 5]
  unsafe_truncate_to_length(arr, 3)
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
}

fn buffer[T](self : Array[T]) -> UninitializedArray[T] {
  self.buf
}

fn resize_buffer[T](self : Array[T], new_capacity : Int) -> Unit {
  let new_buf = UninitializedArray::make(new_capacity)
  let old_buf = self.buf
  let old_cap = old_buf._.length()
  let copy_len = if old_cap < new_capacity { old_cap } else { new_capacity }
  UninitializedArray::unsafe_blit(new_buf, 0, old_buf, 0, copy_len)
  self.buf = new_buf
}

test "array_unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq!(dst[i], src[i])
  }
}

test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq!(dst[i], src[i])
  }
}

test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq!(dst[i], src[i])
  }
}

test "Array::resize_buffer" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.resize_buffer(4)
  assert_eq!(arr.buffer()._.length() >= 4, true)
  arr.push(3)
  arr.push(4)
  assert_eq!(arr.length(), 4)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
  assert_eq!(arr[3], 4)
}

/// Reallocate the array with a new capacity.
fn realloc[T](self : Array[T]) -> Unit {
  let old_cap = self.length()
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  self.resize_buffer(new_cap)
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
  self.len = length + 1
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
    self.unsafe_truncate_to_length(index)
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
  guard self.length() != 0
  let index = self.length() - 1
  let v = self.buffer()[index]
  self.unsafe_truncate_to_length(index)
  v
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
  self.unsafe_truncate_to_length(self.length() - 1)
  value
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
  self.unsafe_truncate_to_length(self.length() - num)
  v
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
  self.len = length + 1
}
