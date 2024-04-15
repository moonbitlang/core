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
fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%array_get"

priv enum SliceData[T] {
  Arr(Array[T])
  UninitArr(UninitializedArray[T])
}

fn op_get[T](self: SliceData[T], index: Int) -> T {
  match self {
    SliceData :: Arr(arr) => arr[index]
    SliceData :: UninitArr(arr) => arr[index]
  }
}

struct Slice[T] {
  start: Int
  len: Int
  data: SliceData[T]
}

pub fn length[T](self: Slice[T]) -> Int {
  self.len
}

pub fn op_get[T](self: Slice[T], index: Int) -> T {
  self.data[self.start + index]
}

pub fn op_as_slice[T](self: Slice[T], ~start: Int, ~end: Int) -> Slice[T] {
  if start < 0 {
    abort("Slice start index out of bounds")
  } else if end > self.length() {
    abort("Slice end index out of bounds")
  } else if start > end {
    abort("Slice start index greater than end index")
  }
  Slice :: {
    start: start + self.start,
    len: end - start,
    data: self.data,
  }
}