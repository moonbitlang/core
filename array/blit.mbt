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
pub fn copy[T](self : FixedArray[T]) -> FixedArray[T] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let arr = FixedArray::make(len, self[0])
    FixedArray::unsafe_blit(arr, 0, self, 0, len)
    arr
  }
}

test "copy" {
  let a : FixedArray[_] = [1, 2, 3, 4]
  let b = a.copy()
  inspect!(b, content="[1, 2, 3, 4]")
  inspect!(physical_equal(b, a), content="false")
  let c = FixedArray::make(8, 0)
  a.blit_to(c, len=4, dst_offset=3)
  inspect!(c, content="[0, 0, 0, 1, 2, 3, 4, 0]")
  inspect!(([] : FixedArray[Int]).copy(), content="[]")
  a.blit_to(a, len=2, src_offset=1)
  inspect!(a, content="[2, 3, 3, 4]")
}
