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

// #region type definition and intrinsics

///|
/// An `ArrayView` represents a view into a section of an array without copying the data.
///
/// # Example
///
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[1:4] // Creates a view of elements at indices 1,2,3
/// assert_eq(view[0], 2)
/// assert_eq(view.length(), 3)
/// ```
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

// #endregion

// #region methods

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
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[2:4]
/// inspect(view.length(), content="2")
/// ```
pub fn[T] ArrayView::length(self : ArrayView[T]) -> Int {
  self.len()
}

///|
pub fn[T] ArrayView::start_offset(self : Self[T]) -> Int {
  self.start()
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
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[2:4]
/// inspect(view[0], content="3")
/// inspect(view[1], content="4")
/// ```
#alias("_[_]")
pub fn[T] ArrayView::at(self : ArrayView[T], index : Int) -> T {
  guard index >= 0 && index < self.len() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len()} but the index is \{index}",
    )
  }
  self.buf()[self.start() + index]
}

///|
/// Retrieves an element from the array view at the specified index.
///
/// Parameters:
///
/// * `self` : The array view to retrieve the element from.
/// * `index` : The position in the array view from which to retrieve the
/// element.
///
/// Returns `Some(element)` if the index is within bounds, or `None` if the index
/// is out of bounds.
///
/// Example:
///
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[1:4]
/// inspect(view.get(0), content="Some(2)")
/// inspect(view.get(1), content="Some(3)")
/// inspect(view.get(2), content="Some(4)")
/// inspect(view.get(5), content="None")
/// ```
pub fn[T] ArrayView::get(self : ArrayView[T], index : Int) -> T? {
  let len = self.length()
  guard index >= 0 && index < len else { None }
  Some(self.buf()[self.start() + index])
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
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[1:4]
/// inspect(view.unsafe_get(1), content="3")
/// ```
#intrinsic("%arrayview.unsafe_get")
#internal(unsafe, "Panic if index is out of bounds")
#doc(hidden)
pub fn[T] ArrayView::unsafe_get(self : ArrayView[T], index : Int) -> T {
  self.buf()[self.start() + index]
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
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[1:4] // Create a view of elements at indices 1, 2, and 3
/// inspect(view[0], content="2") // First element of view is arr[1]
/// inspect(view.length(), content="3") // View contains 3 elements
/// ```
#alias("_[_:_]")
pub fn[T] Array::sub(
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
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[1:4] // view = [2, 3, 4]
/// let subview = view[1:2] // subview = [3]
/// inspect(subview[0], content="3")
/// ```
#alias("_[_:_]")
pub fn[T] ArrayView::sub(
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
fn[T] unsafe_cast_fixedarray_to_uninitializedarray(
  arr : FixedArray[T],
) -> UninitializedArray[T] = "%identity"

///|
/// Creates a new `ArrayView` from a `FixedArray`.
///
/// Parameters:
///
/// * `self` : The fixed array to create a new view from.
/// * `start` : The starting index in the array (inclusive). Defaults to 0.
/// * `end` : The ending index in the array (exclusive). Defaults to the
/// length of the array.
///
/// Returns a new `ArrayView` that provides a window into the specified portion
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
/// ```mbt test
/// let arr : FixedArray[Int] = [1, 2, 3, 4, 5]
/// let view = arr[1:4] // view = [2, 3, 4]
/// inspect(view[0], content="2")
/// ```
#alias("_[_:_]")
pub fn[T] FixedArray::sub(
  self : FixedArray[T],
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
  ArrayView::make(
    unsafe_cast_fixedarray_to_uninitializedarray(self),
    start,
    end - start,
  )
}

///|
pub fn[T] ArrayView::suffixes(
  self : Self[T],
  include_empty? : Bool = false,
) -> Iterator[ArrayView[T]] {
  let len = self.length()
  let mut i = 0
  Iterator::new(fn() -> ArrayView[T]? {
    if i < len {
      let suffix = self[i:]
      i += 1
      Some(suffix)
    } else if i == len {
      i += 1
      if include_empty {
        Some(self[len:])
      } else {
        None
      }
    } else {
      None
    }
  })
}

///|
pub fn[X] ArrayView::iterator(self : ArrayView[X]) -> Iterator[X] {
  let mut i = 0
  Iterator::new(fn() {
    guard i < self.length() else { None }
    let elem = self.unsafe_get(i)
    i += 1
    Some(elem)
  })
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
/// ```mbt test
/// let arr = [1, 2, 3]
/// let view = arr[1:]
/// let mut sum = 0
/// view.iter().each(x => sum = sum + x)
/// inspect(sum, content="5")
/// ```
pub fn[A] ArrayView::iter(self : ArrayView[A]) -> Iter[A] {
  Iter::new(yield_ => for v in self {
    guard yield_(v) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
pub fn[X] ArrayView::rev_iterator(self : ArrayView[X]) -> Iterator[X] {
  let mut i = self.length()
  Iterator::new(fn() {
    guard i > 0 else { None }
    i -= 1
    Some(self.unsafe_get(i))
  })
}

///|
pub fn[X] ArrayView::iterator2(self : ArrayView[X]) -> Iterator2[Int, X] {
  let mut i = 0
  Iterator2::new(fn() {
    guard i < self.length() else { None }
    let result = Some((i, self.unsafe_get(i)))
    i += 1
    result
  })
}

///|
/// Returns an iterator that yields tuples of index and value
/// indices start from 0.
/// 
/// Example:
/// ```mbt test
/// let arr = [1, 2, 3]
/// let view = arr[1:]
/// let mut sum = 0
/// let mut sum_keys = 0
/// view
/// .iter2()
/// .each((i, x) => {
///   sum = sum + x
///   sum_keys = sum_keys + i
/// })
/// inspect(sum, content="5")
/// inspect(sum_keys, content="1")
/// ```
pub fn[A] ArrayView::iter2(self : ArrayView[A]) -> Iter2[Int, A] {
  Iter2::new(yield_ => for i, v in self {
    guard yield_(i, v) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
/// Iterates over each element in the array view and applies a function to it.
///
/// Parameters:
///
/// * `self` : The array view to iterate over.
/// * `function` : A function that takes an element of type `T` and returns
/// nothing. This function will be applied to each element in the array view.
///
/// Example:
///
/// ```mbt test
/// let arr = [1, 2, 3][:]
/// let mut sum = 0
/// arr.each(x => sum = sum + x)
/// inspect(sum, content="6")
/// ```
pub fn[T] ArrayView::each(
  self : ArrayView[T],
  f : (T) -> Unit raise?,
) -> Unit raise? {
  for v in self {
    f(v)
  }
}

///|
/// Iterates over the elements of the array view with index.
///
/// # Example
/// 
/// ```mbt
///   let v = [3, 4, 5][:]
///   let mut sum = 0
///   v.eachi((i, x) => { sum = sum + x + i })
///   inspect(sum, content="15")
/// ```
pub fn[T] ArrayView::eachi(
  self : ArrayView[T],
  f : (Int, T) -> Unit raise?,
) -> Unit raise? {
  for i, v in self {
    f(i, v)
  }
}

///|
/// Checks if all elements in the array view match the condition.
/// 
/// # Example
/// 
/// ```mbt
///   let v = [1, 4, 6, 8, 9]
///   assert_false(v[:].all(elem => elem % 2 == 0))
///   assert_true(v[1:4].all(elem => elem % 2 == 0))
/// ```
pub fn[T] ArrayView::all(
  self : ArrayView[T],
  f : (T) -> Bool raise?,
) -> Bool raise? {
  for v in self {
    if !f(v) {
      return false
    }
  }
  true
}

///|
/// Check if any of the elements in the array view match the condition.
///
/// # Example
///
/// ```mbt
///   let v = [1, 2, 3, 4, 5][:]
///   assert_true(v.any(ele => ele < 6))
///   assert_false(v.any(ele => ele < 1))
/// ```
pub fn[T] ArrayView::any(
  self : ArrayView[T],
  f : (T) -> Bool raise?,
) -> Bool raise? {
  for v in self {
    if f(v) {
      return true
    }
  }
  false
}

///|
/// Checks whether the array view contains a specific element by comparing each
/// element with the target value using the equality operator.
///
/// Parameters:
///
/// * `view` : The array view to search in.
/// * `target` : The value to search for in the array view.
///
/// Returns a boolean value indicating whether the target value exists in the
/// array view.
///
/// Example:
///
/// ```mbt test
/// let arr = [1, 2, 3, 4, 5][:]
/// inspect(arr.contains(3), content="true")
/// inspect(arr.contains(6), content="false")
/// ```
pub fn[T : Eq] ArrayView::contains(self : ArrayView[T], value : T) -> Bool {
  for v in self {
    if v == value {
      break true
    }
  } else {
    false
  }
}

///|
/// Fold out values from an ArrayView according to certain rules.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].fold(init=0, (sum, elem) => sum + elem)
///   inspect(sum, content="15")
/// ```
pub fn[A, B] ArrayView::fold(
  self : ArrayView[A],
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
/// Fold out values from an ArrayView according to certain rules in reversed turn.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].rev_fold(init=0, (sum, elem) => sum + elem)
///   inspect(sum, content="15")
/// ```
pub fn[A, B] ArrayView::rev_fold(
  self : ArrayView[A],
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
/// Fold out values from an ArrayView according to certain rules with index.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].foldi(init=0, (index, sum, _elem) => sum + index)
///   inspect(sum, content="10")
/// ```
pub fn[A, B] ArrayView::foldi(
  self : ArrayView[A],
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
/// Fold out values from an ArrayView according to certain rules in reversed turn with index.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].rev_foldi(init=0, (index, sum, _elem)=> { sum + index })
///   inspect(sum, content="10")
/// ```
pub fn[A, B] ArrayView::rev_foldi(
  self : ArrayView[A],
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
/// Maps a function over the elements of the array view.
///
/// # Example
/// ```mbt
///   let v = [3, 4, 5]
///   let v2 = v[1:].map((x) => {x + 1})
///   assert_eq(v2, [5, 6])
/// ```
pub fn[T, U] ArrayView::map(
  self : ArrayView[T],
  f : (T) -> U raise?,
) -> Array[U] raise? {
  if self.length() == 0 {
    return []
  }
  Array::makei(self.length(), i => f(self[i]))
}

///|
/// Maps a function over the elements of the array view with index.
///
/// # Example
/// ```mbt
///   let v = [3, 4, 5]
///   let v2 = v[1:].mapi((i, x) => {x + i})
///   assert_eq(v2, [4, 6])
/// ```
pub fn[T, U] ArrayView::mapi(
  self : ArrayView[T],
  f : (Int, T) -> U raise?,
) -> Array[U] raise? {
  if self.length() == 0 {
    return []
  }
  Array::makei(self.length(), i => f(i, self[i]))
}

///|
/// Filters the array view with a predicate function.
///
/// # Example
/// ```mbt
///   let arr = [1, 2, 3, 4, 5, 6]
///   let v = arr[2:].filter((x) => { x % 2 == 0 })
///   assert_eq(v, [4, 6])
/// ```
pub fn[T] ArrayView::filter(
  self : ArrayView[T],
  f : (T) -> Bool raise?,
) -> Array[T] raise? {
  let arr = []
  for v in self {
    if f(v) {
      arr.push(v)
    }
  }
  arr
}

///|
/// Copy the view elements to a new array
///
/// # Example
/// ```mbt
///   let view = [1, 2, 3, 4, 5, 6][2:4]
///   let arr = view.to_array()
///   assert_eq(arr, [3, 4])
/// ```
pub fn[T] ArrayView::to_array(self : ArrayView[T]) -> Array[T] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let arr = Array::make(len, self[0])
    for i, v in self {
      arr[i] = v
    }
    arr
  }
}

///|
/// Concatenate strings within an array into a single complete string.
///
/// Example:
///
/// ```mbt test
/// let a : Array[String] = ["1", "2", "3"]
/// let array_view = a[:]
/// inspect(array_view.join(","), content="1,2,3")
/// ```
pub fn[A : ToStringView] ArrayView::join(
  self : ArrayView[A],
  separator : StringView,
) -> String {
  match self {
    [] => ""
    [hd, .. tl] => {
      let hd = hd.to_string_view()
      let mut size_hint = hd.length()
      for s in tl {
        size_hint += s.to_string_view().length() + separator.length()
      }
      size_hint = size_hint << 1
      let buf = StringBuilder::new(size_hint~)
      // buf.write_string(hd)
      buf.write_view(hd)
      if separator is "" {
        for s in tl {
          // buf.write_string(s)
          let s = s.to_string_view()
          buf.write_view(s)
        }
      } else {
        for s in tl {
          let s = s.to_string_view()
          buf.write_view(separator)
          // buf.write_string(s)
          buf.write_view(s)
        }
      }
      buf.to_string()
    }
  }
}

// #endregion

// #region trait impls

///|
pub impl[X : Show] Show for ArrayView[X] with output(self, logger) {
  logger.write_iter(self.iter())
}

///|
pub impl[T : Eq] Eq for ArrayView[T] with equal(self, other) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i in 0..<self.length() {
    if !(self[i] == other[i]) {
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
  let cmp = len_self.compare(len_other)
  guard cmp == 0 else { return cmp }
  for i in 0..<len_self {
    let cmp = self[i].compare(other[i])
    guard cmp == 0 else { break cmp }
  } else {
    0
  }
}

///|
pub impl[A : Hash] Hash for ArrayView[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

// #endregion
