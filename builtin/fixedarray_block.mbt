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
pub fn FixedArray::unsafe_blit[A](
  dst : FixedArray[A],
  dst_offset : Int,
  src : FixedArray[A],
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

pub fn FixedArray::blit_to[A](
  self : FixedArray[A],
  dst : FixedArray[A],
  ~len : Int,
  ~src_offset : Int = 0,
  ~dst_offset : Int = 0
) -> Unit {
  if dst_offset + len > dst.length() || src_offset + len > self.length() {
    panic()
  }
  FixedArray::unsafe_blit(dst, dst_offset, self, src_offset, len)
}
