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
test "panic blit_to with dst_offset out of bounds" {
  let src = FixedArray::make(3, 1)
  let dst = FixedArray::make(3, 0)
  // dst_offset + len > dst.length()
  let _ = src.blit_to(dst, len=2, dst_offset=2)

}

///|
test "unsafe_blit with physical_equal and dst_offset < src_offset" {
  // Create a single array that we'll use for both src and dst
  let arr = FixedArray::from_array([1, 2, 3, 4, 5])

  // Use the same array for src and dst with dst_offset < src_offset
  FixedArray::unsafe_blit(arr, 0, arr, 2, 3)
  inspect!(arr, content="[3, 4, 5, 4, 5]")
}

///|
test "unsafe_blit with different arrays" {
  let src = FixedArray::from_array([1, 2, 3, 4, 5])
  let dst = FixedArray::make(5, 0)
  FixedArray::unsafe_blit(dst, 0, src, 0, 5)
  inspect!(dst, content="[1, 2, 3, 4, 5]")
}

///|
test "unsafe_blit from back to front" {
  let arr = FixedArray::from_array([1, 2, 3, 4, 5])

  // This will trigger the else branch with backward copying
  FixedArray::unsafe_blit(arr, 1, arr, 0, 4)
  inspect!(arr, content="[1, 1, 2, 3, 4]")
}
