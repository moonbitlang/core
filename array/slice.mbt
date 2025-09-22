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
fn[T] FixedArraySlice::length(self : FixedArraySlice[T]) -> Int {
  self.end - self.start
}

///|
#alias("_[_]")
fn[T] FixedArraySlice::at(self : FixedArraySlice[T], index : Int) -> T {
  self.array[self.start + index]
}

///|
#alias("_[_]=_")
fn[T] FixedArraySlice::set(
  self : FixedArraySlice[T],
  index : Int,
  value : T,
) -> Unit {
  self.array[self.start + index] = value
}

///|
fn[T] FixedArraySlice::swap(
  self : FixedArraySlice[T],
  a : Int,
  b : Int,
) -> Unit {
  self.array.swap(self.start + a, self.start + b)
}

///|
fn[T] FixedArraySlice::rev_inplace(self : FixedArraySlice[T]) -> Unit {
  let len = self.length()
  let mid_len = len / 2
  for i in 0..<mid_len {
    let j = len - i - 1
    self.swap(i, j)
  }
}

///|
fn[T] FixedArraySlice::slice(
  self : FixedArraySlice[T],
  start : Int,
  end : Int,
) -> FixedArraySlice[T] {
  { array: self.array, start: self.start + start, end: self.start + end }
}

///|
/// TODO: use specific type for non-js backend
/// Notice: may need to move to builtin
priv struct ArraySlice[T] {
  array : Array[T]
  start : Int
  end : Int
}

///|
fn[T] ArraySlice::length(self : ArraySlice[T]) -> Int {
  self.end - self.start
}

///|
#alias("_[_]")
fn[T] ArraySlice::at(self : ArraySlice[T], index : Int) -> T {
  self.array[self.start + index]
}

///|
fn[T] ArraySlice::swap(self : ArraySlice[T], a : Int, b : Int) -> Unit {
  let i = a + self.start
  let j = b + self.start
  if i >= self.end || j >= self.end || i < self.start || j < self.start {
    let len = self.length()
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is (\{a}, \{b})",
    )
  }
  let temp = self.array.unsafe_get(i)
  self.array.unsafe_set(i, self.array.unsafe_get(j))
  self.array.unsafe_set(j, temp)
}

///|
fn[T] ArraySlice::rev_inplace(self : ArraySlice[T]) -> Unit {
  let len = self.length()
  let mid_len = len / 2
  for i in 0..<mid_len {
    let j = len - i - 1
    self.swap(i, j)
  }
}

///|
#alias("_[_:_]")
fn[T] ArraySlice::sub(
  self : ArraySlice[T],
  start? : Int = 0,
  end? : Int = self.length(),
) -> ArraySlice[T] {
  { array: self.array, start: self.start + start, end: self.start + end }
}
