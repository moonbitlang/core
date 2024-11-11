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
priv struct FixedArraySlice[T] {
  array : FixedArray[T]
  start : Int
  end : Int
}

///|
fn length[T](self : FixedArraySlice[T]) -> Int {
  self.end - self.start
}

///|
fn op_get[T](self : FixedArraySlice[T], index : Int) -> T {
  self.array[self.start + index]
}

///|
fn op_set[T](self : FixedArraySlice[T], index : Int, value : T) -> Unit {
  self.array[self.start + index] = value
}

///|
fn swap[T](self : FixedArraySlice[T], a : Int, b : Int) -> Unit {
  self.array.swap(self.start + a, self.start + b)
}

///|
fn rev_inplace[T](self : FixedArraySlice[T]) -> Unit {
  let mid_len = self.length() / 2
  for i = 0; i < mid_len; i = i + 1 {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

///|
fn slice[T](
  self : FixedArraySlice[T],
  start : Int,
  end : Int
) -> FixedArraySlice[T] {
  { array: self.array, start: self.start + start, end: self.start + end }
}
