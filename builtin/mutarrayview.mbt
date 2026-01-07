// Copyright 2026 International Digital Economy Academy
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
/// A `MutArrayView` represents a view into a section of an array without copying the data.
/// The view provides read-write access to elements of the underlying array.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=1, end=4) // Creates a view of elements at indices 1,2,3
///   assert_eq(view[0], 2)
///   assert_eq(view.length(), 3)
/// }
/// ```
#builtin.valtype
type MutArrayView[T]

///|
fn[T] MutArrayView::buf(self : MutArrayView[T]) -> UninitializedArray[T] = "%arrayview.buf"

///|
fn[T] MutArrayView::start(self : MutArrayView[T]) -> Int = "%arrayview.start"

///|
fn[T] MutArrayView::len(self : MutArrayView[T]) -> Int = "%arrayview.len"

///|
fn[T] MutArrayView::make(
  buf : UninitializedArray[T],
  start : Int,
  len : Int,
) -> MutArrayView[T] = "%arrayview.make"

///|
/// Returns the length (number of elements) of a mutable array view.
///
/// Parameters:
///
/// * `array_view` : The mutable array view whose length is to be determined.
///
/// Returns an integer representing the number of elements in the mutable array view.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=2, end=4)
///   inspect(view.length(), content="2")
/// }
/// ```
pub fn[T] MutArrayView::length(self : MutArrayView[T]) -> Int {
  self.len()
}

///|
/// Retrieves an element at the specified index from the mutable array view.
///
/// Parameters:
///
/// * `self` : The mutable array view to access.
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
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=2, end=4)
///   inspect(view[0], content="3")
///   inspect(view[1], content="4")
/// }
/// ```
#alias("_[_]")
pub fn[T] MutArrayView::at(self : MutArrayView[T], index : Int) -> T {
  guard index >= 0 && index < self.len() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len()} but the index is \{index}",
    )
  }
  self.buf()[self.start() + index]
}

///|
/// Retrieves an element from the mutable array view at the specified index without
/// performing bounds checking.
///
/// Parameters:
///
/// * `array_view` : The mutable array view to retrieve the element from.
/// * `index` : The position in the array view from which to retrieve the
/// element.
///
/// Returns the element at the specified index in the array view.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=1, end=4)
///   inspect(view.unsafe_get(1), content="3")
/// }
/// ```
#intrinsic("%arrayview.unsafe_get")
#internal(unsafe, "Panic if index is out of bounds")
pub fn[T] MutArrayView::unsafe_get(self : MutArrayView[T], index : Int) -> T {
  self.buf()[self.start() + index]
}

///|
/// Sets an element at the specified index in the mutable array view.
///
/// Parameters:
///
/// * `self` : The mutable array view to modify.
/// * `index` : The position in the array view at which to set the element.
/// * `value` : The value to set at the specified index.
///
/// Throws a runtime error if the index is out of bounds (less than 0 or greater
/// than or equal to the length of the array view).
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=2, end=4)
///   view[0] = 10
///   inspect(view[0], content="10")
///   inspect(arr[2], content="10")
/// }
/// ```
#alias("_[_]=_")
pub fn[T] MutArrayView::set(
  self : MutArrayView[T],
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
/// Sets an element at the specified index in the mutable array view without
/// performing bounds checking.
///
/// Parameters:
///
/// * `self` : The mutable array view to modify.
/// * `index` : The position in the array view at which to set the element.
/// * `value` : The value to set at the specified index.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=1, end=4)
///   view.unsafe_set(1, 10)
///   inspect(view[1], content="10")
/// }
/// ```
#intrinsic("%arrayview.unsafe_set")
#internal(unsafe, "Panic if index is out of bounds")
pub fn[T] MutArrayView::unsafe_set(
  self : MutArrayView[T],
  index : Int,
  value : T,
) -> Unit {
  self.buf()[self.start() + index] = value
}

///|
/// Creates a mutable view of a portion of the array. The view provides read-write access
/// to the underlying array without copying the elements.
///
/// Parameters:
///
/// * `array` : The array to create a view from.
/// * `start` : The starting index of the view (inclusive). Defaults to 0.
/// * `end` : The ending index of the view (exclusive). If not provided, defaults
/// to the length of the array.
///
/// Returns a `MutArrayView` that provides a window into the specified portion of
/// the array.
///
/// Throws a panic if the indices are invalid (i.e., `start` is negative, `end`
/// is greater than the array length, or `start` is greater than `end`).
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=1, end=4) // Create a view of elements at indices 1, 2, and 3
///   inspect(view[0], content="2") // First element of view is arr[1]
///   inspect(view.length(), content="3") // View contains 3 elements
/// }
/// ```
pub fn[T] Array::mut_view(
  self : Array[T],
  start? : Int = 0,
  end? : Int,
) -> MutArrayView[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("View index out of bounds")
  }
  MutArrayView::make(self.buffer(), start, end - start)
}

///|
/// Creates a new mutable view into a portion of the mutable array view.
///
/// Parameters:
///
/// * `self` : The mutable array view to create a new view from.
/// * `start` : The starting index in the current view (inclusive). Defaults to
/// 0.
/// * `end` : The ending index in the current view (exclusive). Defaults to the
/// length of the current view.
///
/// Returns a new `MutArrayView` that provides a window into the specified portion
/// of the original mutable array view. The indices are relative to the start of the
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
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=1, end=4) // view = [2, 3, 4]
///   let subview = view.mut_view(start=1, end=2) // subview = [3]
///   inspect(subview[0], content="3")
/// }
/// ```
// TODO: rename does not work with docstring test
pub fn[T] MutArrayView::mut_view(
  self : MutArrayView[T],
  start? : Int = 0,
  end? : Int,
) -> MutArrayView[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("View index out of bounds")
  }
  MutArrayView::make(self.buf(), self.start() + start, end - start)
}

///|
/// Creates a new mutable `ArrayView` from a `FixedArray`.
///
/// Parameters:
///
/// * `self` : The fixed array to create a new view from.
/// * `start` : The starting index in the array (inclusive). Defaults to 0.
/// * `end` : The ending index in the array (exclusive). Defaults to the
/// length of the array.
///
/// Returns a new `MutArrayView` that provides a window into the specified portion
/// of the original fixed array.
///
/// Throws a panic if:
///
/// * `start` is negative
/// * `end` is greater than the length of the array
/// * `start` is greater than `end`
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr : FixedArray[Int] = [1, 2, 3, 4, 5]
///   let view = arr.mut_view(start=1, end=4) // view = [2, 3, 4]
///   inspect(view[0], content="2")
/// }
/// ```
pub fn[T] FixedArray::mut_view(
  self : FixedArray[T],
  start? : Int = 0,
  end? : Int,
) -> MutArrayView[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("View index out of bounds")
  }
  MutArrayView::make(
    unsafe_cast_fixedarray_to_uninitializedarray(self),
    start,
    end - start,
  )
}

///|
/// Creates a new `ArrayView` from a `MutArrayView`.
///
/// Parameters:
///
/// * `self` : The mutable array view to create a new view from.
/// * `start` : The starting index in the array (inclusive). Defaults to 0.
/// * `end` : The ending index in the array (exclusive). Defaults to the
/// length of the array.
#alias("_[_:_]")
pub fn[T] MutArrayView::sub(
  self : MutArrayView[T],
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

// Copyright 2026 International Digital Economy Academy
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
#alias(iterator, deprecated)
pub fn[X] MutArrayView::iter(self : MutArrayView[X]) -> Iter[X] {
  let mut i = 0
  Iter::new(fn() {
    guard i < self.length() else { None }
    let elem = self.unsafe_get(i)
    i += 1
    Some(elem)
  })
}

///|
#alias(rev_iterator, deprecated)
pub fn[X] MutArrayView::rev_iter(self : MutArrayView[X]) -> Iter[X] {
  let mut i = self.length()
  Iter::new(fn() {
    guard i > 0 else { None }
    i -= 1
    Some(self.unsafe_get(i))
  })
}

///|
#alias(iterator2, deprecated)
pub fn[X] MutArrayView::iter2(self : MutArrayView[X]) -> Iter2[Int, X] {
  let mut i = 0
  Iter2::new(fn() {
    guard i < self.length() else { None }
    let result = Some((i, self.unsafe_get(i)))
    i += 1
    result
  })
}

///|
pub impl[X : Show] Show for MutArrayView[X] with output(self, logger) {
  self[:].output(logger)
}

///|
pub impl[T : Eq] Eq for MutArrayView[T] with equal(self, other) -> Bool {
  self[:] == other[:]
}

///|
pub impl[T : Compare] Compare for MutArrayView[T] with compare(self, other) -> Int {
  self[:].compare(other[:])
}

///|
pub impl[A : Hash] Hash for MutArrayView[A] with hash_combine(self, hasher) {
  self[:].hash_combine(hasher)
}
