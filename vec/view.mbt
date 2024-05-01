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

pub fn length[T](self : VecView[T]) -> Int {
  self.len
}

pub fn op_get[T](self : VecView[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[self.start + index]
}

pub fn op_set[T](self : VecView[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[self.start + index] = value
}

pub fn swap[T](self : VecView[T], i : Int, j : Int) -> Unit {
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

pub fn reverse[T](self : VecView[T]) -> Unit {
  let mid_len = self.length() / 2
  for i = 0; i < mid_len; i = i + 1 {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

pub fn op_as_view[T](self : Vec[T], ~start : Int, ~end : Int) -> VecView[T] {
  if start < 0 {
    abort("Slice start index out of bounds")
  } else if end > self.length() {
    abort("Slice end index out of bounds")
  } else if start > end {
    abort("Slice start index greater than end index")
  }
  VecView::{ buf: self.buf, start, len: end - start }
}

pub fn op_as_view[T](self : VecView[T], ~start : Int, ~end : Int) -> VecView[T] {
  if start < 0 {
    abort("Slice start index out of bounds")
  } else if end > self.length() {
    abort("Slice end index out of bounds")
  } else if start > end {
    abort("Slice start index greater than end index")
  }
  VecView::{ buf: self.buf, start: self.start + start, len: end - start }
}
