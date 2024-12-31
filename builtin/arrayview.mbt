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
/// A `ArrayView` is a slice of a `Array`.
struct ArrayView[T] {
  buf : UninitializedArray[T]
  start : Int
  len : Int
}

///|
pub fn length[T](self : ArrayView[T]) -> Int {
  self.len
}

///|
pub fn op_get[T](self : ArrayView[T], index : Int) -> T {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.buf[self.start + index]
}

///| 
/// @intrinsic %arrayview.unsafe_get
/// @alert unsafe "Panic if index is out of bounds"
pub fn unsafe_get[T](self : ArrayView[T], index : Int) -> T {
  self.buf[self.start + index]
}

///|
pub fn op_set[T](self : ArrayView[T], index : Int, value : T) -> Unit {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.buf[self.start + index] = value
}

///|
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
pub fn op_as_view[T](
  self : Array[T],
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
  ArrayView::{ buf: self.buffer(), start, len: end - start }
}

///|
pub fn op_as_view[T](
  self : ArrayView[T],
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
  ArrayView::{ buf: self.buf, start: self.start + start, len: end - start }
}

///|
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
