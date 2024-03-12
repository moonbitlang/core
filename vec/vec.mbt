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

priv type UninitializedArray[T] Array[UnsafeMaybeUninit[T]]

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%make_array_maybe_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%array_get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%array_set"

fn length[T](self : UninitializedArray[T]) -> Int {
  self.0.length()
}

/// A `Vec` is a generic vector (dynamic array) that can grow in size.
struct Vec[T] {
  mut buf : UninitializedArray[T]
  mut len : Int
}

/// Creates a new, empty vector.
pub fn Vec::new[T]() -> Vec[T] {
  Vec::{ buf: UninitializedArray::make(0), len: 0 }
}

/// Creates a new, empty vector with a specified initial capacity.
pub fn Vec::with_capacity[T](cap : Int) -> Vec[T] {
  Vec::{ buf: UninitializedArray::make(cap), len: 0 }
}

/// Adds an element to the end of the vector.
pub fn push[T](self : Vec[T], value : T) {
  if self.len == self.buf.length() {
    let old_cap = self.len
    let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
    let new_buf = UninitializedArray::make(new_cap)
    for i = 0; i < old_cap; i = i + 1 {
      new_buf[i] = self.buf[i]
    }
    new_buf[old_cap] = value
    self.buf = new_buf
    self.len = old_cap + 1
  } else {
    self.buf[self.len] = value
    self.len += 1
  }
}

/// Retrieves the element at the specified index from the vector.
/// 
/// If you try to access an index which isn’t in the Vec, it will panic.
pub fn op_get[T](self : Vec[T], index : Int) -> T {
  if index >= self.len {
    let len = self.len
    abort("index out of bounds: the len is \(len) but the index is \(index)")
  }
  self.buf[index]
}

/// Sets the value of the element at the specified index.
/// 
/// If you try to access an index which isn’t in the Vec, it will panic.
pub fn op_set[T](self : Vec[T], index : Int, value : T) {
  if index >= self.len {
    let len = self.len
    abort("index out of bounds: the len is \(len) but the index is \(index)")
  }
  self.buf[index] = value
}

test "push" {
  let v = Vec::new()
  v.push(3)
  v.push(4)
  v.push(5)
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 4)?
  @assertion.assert_eq(v[2], 5)?
  v[0] = 6
  @assertion.assert_eq(v[0], 6)?
}
