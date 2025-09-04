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
/// An `ArrayView` represents a view into a section of an array without copying the data.
///
/// # Example
///
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4]  // Creates a view of elements at indices 1,2,3
///   assert_eq(view[0], 2)
///   assert_eq(view.length(), 3)
/// ```
#deprecated("use @array.View instead")
#builtin.valtype
type ArrayView[T]

///|
fn[T] ArrayView::buf(self : ArrayView[T]) -> UninitializedArray[T] = "%arrayview.buf"

///|
fn[T] ArrayView::start(self : ArrayView[T]) -> Int = "%arrayview.start"

///|
fn[T] ArrayView::len(self : ArrayView[T]) -> Int = "%arrayview.len"

///|
fn[T] ArrayView::make(
  buf : UninitializedArray[T],
  start : Int,
  len : Int,
) -> ArrayView[T] = "%arrayview.make"

///|
/// Returns the length (number of elements) of an array view.
///
/// Parameters:
///
/// * `array_view` : The array view whose length is to be determined.
///
/// Returns an integer representing the number of elements in the array view.
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[2:4]
///   inspect(view.length(), content="2")
/// ```
pub fn[T] ArrayView::length(self : ArrayView[T]) -> Int {
  self.len()
}

///|
/// Retrieves an element at the specified index from the array view.
///
/// Parameters:
///
/// * `self` : The array view to access.
/// * `index` : The position in the array view from which to retrieve the
/// element.
///
/// Returns the element at the specified index.
///
/// Throws a runtime error if the index is out of bounds (less than 0 or greater
/// than or equal to the length of the array view).
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[2:4]
///   inspect(view[0], content="3")
///   inspect(view[1], content="4")
/// ```
pub fn[T] ArrayView::op_get(self : ArrayView[T], index : Int) -> T {
  guard index >= 0 && index < self.len() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len()} but the index is \{index}",
    )
  }
  self.buf()[self.start() + index]
}

///|
/// Retrieves an element from the array view at the specified index without
/// performing bounds checking.
///
/// Parameters:
///
/// * `array_view` : The array view to retrieve the element from.
/// * `index` : The position in the array view from which to retrieve the
/// element.
///
/// Returns the element at the specified index in the array view.
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4]
///   inspect(view.unsafe_get(1), content="3")
/// ```
#intrinsic("%arrayview.unsafe_get")
#internal(unsafe, "Panic if index is out of bounds")
pub fn[T] ArrayView::unsafe_get(self : ArrayView[T], index : Int) -> T {
  self.buf()[self.start() + index]
}

///|
/// Sets the value at the specified index in the array view.
///
/// Parameters:
///
/// * `array_view` : The array view to modify.
/// * `index` : The position in the array view where the value will be set.
/// * `value` : The value to be assigned at the specified index.
///
/// Throws a panic if `index` is negative or greater than or equal to the length
/// of the array view.
///
///
#deprecated("ArrayView will be immutable, use array if you need mutation")
pub fn[T] ArrayView::op_set(
  self : ArrayView[T],
  index : Int,
  value : T,
) -> Unit {
  guard index >= 0 && index < self.len() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len()} but the index is \{index}",
    )
  }
  self.buf()[self.start() + index] = value
}

///|
#deprecated("ArrayView will be immutable, use array if you need mutation")
pub fn[T] ArrayView::swap(self : ArrayView[T], i : Int, j : Int) -> Unit {
  guard i >= 0 && i < self.len() && j >= 0 && j < self.len() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len()} but the index is (\{i}, \{j})",
    )
  }
  let temp = self.buf()[self.start() + i]
  self.buf()[self.start() + i] = self.buf()[self.start() + j]
  self.buf()[self.start() + j] = temp
}

///|
/// Creates a view of a portion of the array. The view provides read-write access
/// to the underlying array without copying the elements.
///
/// Parameters:
///
/// * `array` : The array to create a view from.
/// * `start` : The starting index of the view (inclusive). Defaults to 0.
/// * `end` : The ending index of the view (exclusive). If not provided, defaults
/// to the length of the array.
///
/// Returns an `ArrayView` that provides a window into the specified portion of
/// the array.
///
/// Throws a panic if the indices are invalid (i.e., `start` is negative, `end`
/// is greater than the array length, or `start` is greater than `end`).
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4] // Create a view of elements at indices 1, 2, and 3
///   inspect(view[0], content="2") // First element of view is arr[1]
///   inspect(view.length(), content="3") // View contains 3 elements
/// ```
pub fn[T] Array::op_as_view(
  self : Array[T],
  start? : Int = 0,
  end? : Int,
) -> ArrayView[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("View index out of bounds")
  }
  ArrayView::make(self.buffer(), start, end - start)
}

///|
/// Creates a new view into a portion of the array view.
///
/// Parameters:
///
/// * `self` : The array view to create a new view from.
/// * `start` : The starting index in the current view (inclusive). Defaults to
/// 0.
/// * `end` : The ending index in the current view (exclusive). Defaults to the
/// length of the current view.
///
/// Returns a new `ArrayView` that provides a window into the specified portion
/// of the original array view. The indices are relative to the start of the
/// current view.
///
/// Throws a panic if:
///
/// * `start` is negative
/// * `end` is greater than the length of the current view
/// * `start` is greater than `end`
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4] // view = [2, 3, 4]
///   let subview = view[1:2] // subview = [3]
///   inspect(subview[0], content="3")
/// ```
pub fn[T] ArrayView::op_as_view(
  self : ArrayView[T],
  start? : Int = 0,
  end? : Int,
) -> ArrayView[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("View index out of bounds")
  }
  ArrayView::make(self.buf(), self.start() + start, end - start)
}

///|
#deprecated("ArrayView will be immutable, use array if you need mutation")
pub fn[T] ArrayView::blit_to(self : ArrayView[T], dst : ArrayView[T]) -> Unit {
  let src_len = self.length()
  let dst_len = dst.length()
  guard dst_len >= src_len
  UninitializedArray::unsafe_blit(
    dst.buf(),
    dst.start(),
    self.buf(),
    self.start(),
    src_len,
  )
}
