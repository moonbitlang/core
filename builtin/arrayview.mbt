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

/// A `ArrayView` is a slice of a `Array`.
struct ArrayView[T] {
  buf : UninitializedArray[T]
  start : Int
  len : Int
}

pub fn length[T](self : ArrayView[T]) -> Int {
  self.len
}

pub fn op_get[T](self : ArrayView[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[self.start + index]
}

pub fn op_set[T](self : ArrayView[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[self.start + index] = value
}

pub fn swap[T](self : ArrayView[T], i : Int, j : Int) -> Unit {
  if i >= self.len || j >= self.len || i < 0 || j < 0 {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is (\(i), \(j))",
    )
  }
  let temp = self.buf[self.start + i]
  self.buf[self.start + i] = self.buf[self.start + j]
  self.buf[self.start + j] = temp
}

pub fn op_as_view[T](self : Array[T], ~start : Int, ~end : Int) -> ArrayView[T] {
  if start < 0 {
    abort("Slice start index out of bounds")
  } else if end > self.length() {
    abort("Slice end index out of bounds")
  } else if start > end {
    abort("Slice start index greater than end index")
  }
  ArrayView::{ buf: self.buf, start, len: end - start }
}

pub fn op_as_view[T](self : ArrayView[T], ~start : Int, ~end : Int) -> ArrayView[T] {
  if start < 0 {
    abort("Slice start index out of bounds")
  } else if end > self.length() {
    abort("Slice end index out of bounds")
  } else if start > end {
    abort("Slice start index greater than end index")
  }
  ArrayView::{ buf: self.buf, start: self.start + start, len: end - start }
}
