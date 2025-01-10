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
/// A `ArrayView` is a slice of a `Array`.
struct ArrayView[T] {
  buf : UninitializedArray[T]
  start : Int
  len : Int
}

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
/// test "ArrayView::length" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[2:4]
///   inspect!(view.length(), content="2")
/// }
/// ```
pub fn length[T](self : ArrayView[T]) -> Int {
  self.len
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
/// test "ArrayView::op_get" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[2:4]
///   inspect!(view[0], content="3")
///   inspect!(view[1], content="4")
/// }
///
/// test "panic ArrayView::op_get/out_of_bounds" {
///   let arr = [1, 2, 3]
///   let view = arr[1:]
///   ignore(view[2]) // Index out of bounds
/// }
/// ```
pub fn op_get[T](self : ArrayView[T], index : Int) -> T {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.buf[self.start + index]
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
/// test "ArrayView::unsafe_get" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4]
///   inspect!(view.unsafe_get(1), content="3")
/// }
///
/// test "panic ArrayView::unsafe_get/out_of_bounds" {
///   let arr = [1, 2, 3]
///   let view = arr[1:]
///   ignore(view.unsafe_get(5)) // Index out of bounds
/// }
/// ```
///
/// @intrinsic %arrayview.unsafe_get
/// @alert unsafe "Panic if index is out of bounds"
pub fn unsafe_get[T](self : ArrayView[T], index : Int) -> T {
  self.buf[self.start + index]
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
/// Example:
///
/// ```moonbit
/// test "ArrayView::op_set" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4] // view contains [2, 3, 4]
///   view.op_set(1, 42)
///   inspect!(arr, content="[1, 2, 42, 4, 5]")
/// }
///
/// test "panic ArrayView::op_set/out_of_bounds" {
///   let arr = [1, 2, 3]
///   let view = arr[1:]
///   ignore(view.op_set(2, 42)) // Index out of bounds
/// }
/// ```
///
/// @alert unsafe "Panic if index is out of bounds."
pub fn op_set[T](self : ArrayView[T], index : Int, value : T) -> Unit {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.buf[self.start + index] = value
}

///|
/// Swaps two elements in the array view at the specified indices.
///
/// Parameters:
///
/// * `self` : The array view in which to swap elements.
/// * `i` : The index of the first element to be swapped.
/// * `j` : The index of the second element to be swapped.
///
/// Throws a panic if either index is negative or greater than or equal to the
/// length of the array view.
///
/// Example:
///
/// ```moonbit
/// test "ArrayView::swap" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4] // view = [2, 3, 4]
///   view.swap(0, 2) // view = [4, 3, 2]
///   inspect!(view, content="[4, 3, 2]")
/// }
///
/// test "panic ArrayView::swap/out_of_bounds" {
///   let view = [1, 2, 3][:]
///   ignore(view.swap(0, 3)) // Index out of bounds
/// }
/// ```
///
/// @alert unsafe "Panic if index is out of bounds"
pub fn swap[T](self : ArrayView[T], i : Int, j : Int) -> Unit {
  guard i >= 0 && i < self.len && j >= 0 && j < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is (\{i}, \{j})",
    )
  }
  let temp = self.buf[self.start + i]
  self.buf[self.start + i] = self.buf[self.start + j]
  self.buf[self.start + j] = temp
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
/// test "op_as_view" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4] // Create a view of elements at indices 1, 2, and 3
///   inspect!(view[0], content="2") // First element of view is arr[1]
///   inspect!(view.length(), content="3") // View contains 3 elements
/// }
///
/// test "panic op_as_view/invalid_range" {
///   let arr = [1, 2, 3]
///   ignore(arr[2:1]) // Panic: start index greater than end index
/// }
/// ```
pub fn op_as_view[T](
  self : Array[T],
  start~ : Int = 0,
  end? : Int
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
  ArrayView::{ buf: self.buffer(), start, len: end - start }
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
/// test "ArrayView::op_as_view" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4] // view = [2, 3, 4]
///   let subview = view[1:2] // subview = [3]
///   inspect!(subview[0], content="3")
/// }
/// ```
///
/// ```moonbit
/// test "panic ArrayView::op_as_view/invalid_range" {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4]
///   ignore(view[2:5]) // Panic: end index out of bounds
/// }
/// ```
pub fn op_as_view[T](
  self : ArrayView[T],
  start~ : Int = 0,
  end? : Int
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
  ArrayView::{ buf: self.buf, start: self.start + start, len: end - start }
}

///|
/// Returns an iterator that yields each element of the array view in sequence
/// from start to end.
///
/// Parameters:
///
/// * `array_view` : The array view to iterate over.
///
/// Returns an iterator that yields elements of type `A` from the array view.
///
/// Example:
///
/// ```moonbit
/// test "ArrayView::iter" {
///   let arr = [1, 2, 3]
///   let view = arr[1:]
///   let mut sum = 0
///   view.iter().each(fn(x) { sum = sum + x })
///   inspect!(sum, content="5")
/// }
/// ```
pub fn iter[A](self : ArrayView[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    for v in self {
      guard let IterContinue = yield_(v) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///|
/// Fold out values from an arrayview according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn fold[A, B](self : ArrayView[A], init~ : B, f : (B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an arrayview according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].rev_fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn rev_fold[A, B](self : ArrayView[A], init~ : B, f : (B, A) -> B) -> B {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an arrayview according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn foldi[A, B](self : ArrayView[A], init~ : B, f : (Int, B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an arrayview according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].rev_foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn rev_foldi[A, B](
  self : ArrayView[A],
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
/// Maps a function over the elements of the array view.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v[1:].map(fn (x) {x + 1})
/// assert_eq!(v2, [5, 6])
/// ```
pub fn map[T, U](self : ArrayView[T], f : (T) -> U) -> Array[U] {
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
/// Maps a function over the elements of the array view in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v[1:].map_inplace(fn (x) {x + 1})
/// assert_eq!(v, [3, 5, 6])
/// ```
pub fn map_inplace[T](self : ArrayView[T], f : (T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(v)
  }
}

///|
/// Maps a function over the elements of the array view with index.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v[1:].mapi(fn (i, x) {x + i})
/// assert_eq!(v2, [4, 6])
/// ```
pub fn mapi[T, U](self : ArrayView[T], f : (Int, T) -> U) -> Array[U] {
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
/// Maps a function over the elements of the array view with index in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v[1:].mapi_inplace(fn (i, x) {x + i})
/// assert_eq!(v, [3, 4, 6])
/// ```
pub fn mapi_inplace[T](self : ArrayView[T], f : (Int, T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(i, v)
  }
}

///|
/// Filters the array view with a predicate function.
///
/// # Example
/// ```
/// let arr = [1, 2, 3, 4, 5, 6]
/// let v = arr[2:].filter(fn (x) { x % 2 == 0 })
/// assert_eq!(v, [4, 6])
/// ```
pub fn filter[T](self : ArrayView[T], f : (T) -> Bool) -> Array[T] {
  let arr = []
  for v in self {
    if f(v) {
      arr.push(v)
    }
  }
  arr
}

///|
pub impl[T : Eq] Eq for ArrayView[T] with op_equal(self, other) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i in 0..<self.length() {
    if not(self[i] == other[i]) {
      return false
    }
  } else {
    true
  }
}

///|
pub impl[T : Compare] Compare for ArrayView[T] with compare(self, other) -> Int {
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
