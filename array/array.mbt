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

pub fn as_iter[T](self : Array[T]) -> @iter.Iter[T] {
  @iter.Iter::_unstable_internal_make(
    fn(yield) {
      for i = 0, len = self.length(); i < len; i = i + 1 {
        if yield(self[i]).not() {
          break false
        }
      } else {
        true
      }
    },
  )
}

fn unsafe_blit[A](
  dst : Array[A],
  dst_offset : Int,
  src : Array[A],
  src_offset : Int,
  len : Int
) -> Unit {
  if physical_equal(dst, src) && dst_offset < src_offset {
    for i = 0; i < len; i = i + 1 {
      dst[dst_offset + i] = src[src_offset + i]
    }
  } else {
    for i = len - 1; i >= 0; i = i - 1 {
      dst[dst_offset + i] = src[src_offset + i]
    }
  }
}

pub fn blit_to[A](
  self : Array[A],
  dst : Array[A],
  ~len : Int,
  ~src_offset : Int = 0,
  ~dst_offset : Int = 0
) -> Unit {
  if dst_offset + len > dst.length() || src_offset + len > self.length() {
    abort("invalid argument in blit")
  }
  unsafe_blit(dst, dst_offset, self, src_offset, len)
}

pub fn copy[T](self : Array[T]) -> Array[T] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let arr = Array::make(len, self[0])
    unsafe_blit(arr, 0, self, 0, len)
    arr
  }
}

pub fn new_with_index[T](length : Int, value : (Int) -> T) -> Array[T] {
  if length <= 0 {
    []
  } else {
    let array = Array::make(length, value(0))
    for i = 1; i < length; i = i + 1 {
      array[i] = value(i)
    }
    array
  }
}
