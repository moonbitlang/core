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
pub fn op_as_view[T](self : Array[T], start~ : Int, end? : Int) -> ArrayView[T] {
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
  start~ : Int,
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

pub fn map[T, U](self : ArrayView[T], f : (T) -> U) -> ArrayView[U] {
  if self.length() == 0 {
    return [][:]
  }
  let arr = Array::make_uninit(self.length())
  for i, v in self {
    arr.unsafe_set(i, f(v))
  }
  arr[:]
}

pub fn mapi[T, U](self : ArrayView[T], f : (Int, T) -> U) -> ArrayView[U] {
  if self.length() == 0 {
    return [][:]
  }
  let arr = Array::make_uninit(self.length())
  for i, v in self {
    arr.unsafe_set(i, f(i, v))
  }
  arr[:]
}

pub fn is_empty[T](self : ArrayView[T]) -> Bool {
  self.length() == 0
}

pub fn starts_with[T : Eq](self : ArrayView[T], prefix : ArrayView[T]) -> Bool {
  if prefix.length() > self.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if self[i] != prefix[i] {
      break false
    }
  } else {
    true
  }
}

pub fn ends_with[T : Eq](self : ArrayView[T], suffix : ArrayView[T]) -> Bool {
  if suffix.length() > self.length() {
    return false
  }
  for i in 0..<suffix.length() {
    if self[self.length() - suffix.length() + i] != suffix[i] {
      break false
    }
  } else {
    true
  }
}

/// TODO: perf could be optimized
pub fn rev[T](self : ArrayView[T]) -> ArrayView[T] {
  let arr = []
  for i in 0..<self.length() {
    arr.push(self[self.length() - i - 1])
  }
  arr[:]
}

/// TODO: perf could be optimized
/// @alert unsafe "Panic if index is out of bounds."
pub fn split_at[T](self : ArrayView[T], index : Int) -> (ArrayView[T], ArrayView[T]) {
  if index < 0 || index > self.length() {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  (self[0:index], self[index:])
}

pub fn strip_prefix[T : Eq](self : ArrayView[T], prefix : ArrayView[T]) -> ArrayView[T]? {
  if self.starts_with(prefix) {
    let v = Array::make_uninit(self.length() - prefix.length())[:]
    UninitializedArray::unsafe_blit(
      v.buf,
      0,
      self.buf,
      prefix.length(),
      self.length() - prefix.length(),
    )
    Some(v)
  } else {
    None
  }
}

pub fn strip_suffix[T : Eq](self : ArrayView[T], suffix : ArrayView[T]) -> ArrayView[T]? {
  if self.ends_with(suffix) {
    let v = Array::make_uninit(self.length() - suffix.length())
    let len = self.length() - suffix.length()
    UninitializedArray::unsafe_blit(v.buffer(), 0, self.buf, 0, len)
    Some(v[:])
  } else {
    None
  }
}
