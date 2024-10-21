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

///-----------------------------------------------------------------------------
pub fn Array::unsafe_blit[A](
  dst : Array[A],
  dst_offset : Int,
  src : Array[A],
  src_offset : Int,
  len : Int
) -> Unit {
  FixedArray::unsafe_blit(
    dst.buffer()._,
    dst_offset,
    src.buffer()._,
    src_offset,
    len,
  )
}

///-----------------------------------------------------------------------------
pub fn Array::unsafe_blit_fixed[A](
  dst : Array[A],
  dst_offset : Int,
  src : FixedArray[A],
  src_offset : Int,
  len : Int
) -> Unit {
  UninitializedArray::unsafe_blit_fixed(
    dst.buffer(),
    dst_offset,
    src,
    src_offset,
    len,
  )
}

///-----------------------------------------------------------------------------
pub fn Array::blit_to[A](
  self : Array[A],
  dst : Array[A],
  ~len : Int,
  ~src_offset : Int = 0,
  ~dst_offset : Int = 0
) -> Unit {
  guard len >= 0 &&
    dst_offset >= 0 &&
    src_offset >= 0 &&
    dst_offset + len <= dst.length() &&
    src_offset + len <= self.length()
  Array::unsafe_blit(dst, dst_offset, self, src_offset, len)
}
