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
priv struct FixedArraySlice[T] {
  array : FixedArray[T]
  start : Int
  end : Int
}

///|
fn FixedArraySlice::length[T](self : FixedArraySlice[T]) -> Int {
  self.end - self.start
}

///|
fn FixedArraySlice::op_get[T](self : FixedArraySlice[T], index : Int) -> T {
  self.array[self.start + index]
}

///|
fn FixedArraySlice::op_set[T](
  self : FixedArraySlice[T],
  index : Int,
  value : T
) -> Unit {
  self.array[self.start + index] = value
}

///|
fn FixedArraySlice::swap[T](
  self : FixedArraySlice[T],
  a : Int,
  b : Int
) -> Unit {
  self.array.swap(self.start + a, self.start + b)
}

///|
fn FixedArraySlice::rev_inplace[T](self : FixedArraySlice[T]) -> Unit {
  let len = self.length()
  let mid_len = len / 2
  for i in 0..<mid_len {
    let j = len - i - 1
    self.swap(i, j)
  }
}

///|
fn FixedArraySlice::slice[T](
  self : FixedArraySlice[T],
  start : Int,
  end : Int
) -> FixedArraySlice[T] {
  { array: self.array, start: self.start + start, end: self.start + end }
}
