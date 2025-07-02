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
type UninitializedArray[T] FixedArray[UnsafeMaybeUninit[T]]

///|
/// Creates an uninitialized array of the specified size.
///
/// Parameters:
///
/// - `size` : The number of elements the array should hold.
///
/// Returns an uninitialized array of type `T` with the specified size.
pub fn[T] UninitializedArray::make(size : Int) -> UninitializedArray[T] = "%fixedarray.make_uninit"

///|
/// Retrieves the element at the specified index from an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array from which to retrieve the element.
/// - `index` : The index of the element to retrieve.
///
/// Returns the element at the specified index.
pub fn[T] UninitializedArray::op_get(
  self : UninitializedArray[T],
  index : Int
) -> T = "%fixedarray.get"

///|
/// Sets the value at the specified index in an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array where the value will be set.
/// - `index` : The position in the array where the value will be set.
/// - `value` : The value to be set at the specified index.
pub fn[T] UninitializedArray::op_set(
  self : UninitializedArray[T],
  index : Int,
  value : T
) = "%fixedarray.set"

///|
/// Creates a view into a portion of the uninitialized array.
///
/// Parameters:
///
/// * `array` : The uninitialized array to create a view from.
/// * `start` : The starting index of the view (inclusive). Defaults to 0.
/// * `end` : The ending index of the view (exclusive). If not provided, defaults
/// to the length of the array.
///
/// Returns an `ArrayView` that provides a window into the specified portion of
/// the array.
///
/// Throws an error if the indices are out of bounds or if `start` is greater
/// than `end`.
pub fn[T] UninitializedArray::op_as_view(
  self : UninitializedArray[T],
  start~ : Int = 0,
  end? : Int
) -> ArrayView[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => end
  }
  guard start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  { buf: self, start, len: end - start }
}

///|
/// Returns the length of an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array whose length is to be determined.
///
/// Returns the length of the uninitialized array as an integer.
pub fn[A] UninitializedArray::length(self : UninitializedArray[A]) -> Int {
  let UninitializedArray(self) = self
  self.length()
}

///|
#internal(unsafe, "For internal use only.")
pub fn[T] UninitializedArray::unsafe_blit(
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : UninitializedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  FixedArray::unsafe_blit(dst.inner(), dst_offset, src.inner(), src_offset, len)
}

///|
/// Copies a range of elements from one `UninitializedArray` to another, ensuring the destination array has enough space.
///
/// If the destination array is not large enough to hold the copied elements at the specified offset, a new larger array is created and returned.
///
/// Parameters:
///
/// * `self` : The source array (not modified).
/// * `dst` : The destination array. May be modified in-place or replaced by a new array.
/// * `len` : Number of elements to copy.
/// * `src_offset` : Start index in the source array (default: 0).
/// * `dst_offset` : Start index in the destination array (default: 0).
///
/// Returns:
///   A new array if reallocation was necessary, otherwise the original `dst`.
///
/// Important:
///   - Requires: `len >= 0`
///   - Requires: `src_offset >= 0`
///   - Requires: `dst_offset >= 0`
///   - Requires: `src_offset + len <= self.length()`
///   - Ensures: `dst_offset + len <= dst.length()` after call (either by expanding `dst` or using a new array)
///   - Does not initialize or drop values; assumes caller handles memory safety.
///
pub fn[A] UninitializedArray::blit(
  self : UninitializedArray[A],
  dst : UninitializedArray[A],
  len~ : Int,
  src_offset~ : Int = 0,
  dst_offset~ : Int = 0
) -> UninitializedArray[A] {
  guard len >= 0 &&
    dst_offset >= 0 &&
    src_offset >= 0 &&
    dst_offset <= dst.length() &&
    src_offset + len <= self.length()
  if dst_offset + len > dst.length() {
    let new_dst = UninitializedArray::make(dst_offset + len)
    UninitializedArray::unsafe_blit(new_dst, 0, dst, 0, dst.length())
    UninitializedArray::unsafe_blit(new_dst, dst_offset, self, src_offset, len)
    new_dst
  } else {
    UninitializedArray::unsafe_blit(dst, dst_offset, self, src_offset, len)
    dst
  }
}

///|
test "op_as_view with valid_range" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  let view = arr[1:4]
  inspect(view.start, content="1")
  inspect(view.len, content="3")
}

///|
test "panic op_as_view with invalid_start" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  ignore(arr[-1:])
}

///|
test "panic op_as_view with invalid_end" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  ignore(arr[2:10])
}
