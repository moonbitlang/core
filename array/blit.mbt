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

/// @intrinsic %array.copy
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

test "copy" {
  let a = [1, 2, 3, 4]
  let b = a.copy()
  inspect(b, content="[1, 2, 3, 4]")?
  inspect(physical_equal(b, a), content="false")?
  let c = Array::make(8, 0)
  a.blit_to(c, len=4, dst_offset=3)
  inspect(c, content="[0, 0, 0, 1, 2, 3, 4, 0]")?
  inspect(([] : Array[Int]).copy(), content="[]")?
  a.blit_to(a, len=2, src_offset=1)
  inspect(a, content="[2, 3, 3, 4]")?
}
