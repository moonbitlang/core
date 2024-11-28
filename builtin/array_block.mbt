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

///|
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

///|
/// when `dst_off_set + len > dst.length()`, 
/// `dst` will grow its capacity to `dst_off_set + len`
pub fn Array::blit_to[A](
  self : Array[A],
  dst : Array[A],
  len~ : Int,
  src_offset~ : Int = 0,
  dst_offset~ : Int = 0
) -> Unit {
  guard len >= 0 &&
    dst_offset >= 0 &&
    src_offset >= 0 &&
    src_offset + len <= self.length()
  if dst_offset + len > dst.length() {
    // dst.reserve_capacity(dst_offset + len)
    // println("resized.. \{dst.length()} -> \{dst_offset + len}")
    // dst.resize_buffer(dst_offset + len)
    // dst.len = dst_offset + len 
    // this is needed, otherwise dst will not be displayed correctly
    // FIXME: resize_buffer does not change length
    // our FixedArray::unsafe_blit use intrinscs called %fixedarray.copy
    // its semantics need be carfully documented
    // println("resized.. \{dst.length()}")
    let new_cap = dst_offset + len
    let new_buf = UninitializedArray::make(new_cap)
    let old_buf = dst.buf
    // let old_cap = old_buf._.length()
    UninitializedArray::unsafe_blit(new_buf, 0, old_buf, 0, dst_offset)
    UninitializedArray::unsafe_blit(
      new_buf,
      dst_offset,
      self.buf,
      src_offset,
      len,
    )
    dst.buf = new_buf
    dst.len = new_cap
  } else {
    Array::unsafe_blit(dst, dst_offset, self, src_offset, len)
  }
}

test "Array::blit_to/basic" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  Array::blit_to(src, dst, len=3, src_offset=1, dst_offset=2)
  inspect!(dst, content="[0, 0, 2, 3, 4]")
}

test "Array::blit_to/zero_length" {
  let src = [1, 2, 3]
  let dst = [4, 5, 6]
  Array::blit_to(src, dst, len=0)
  inspect!(dst, content="[4, 5, 6]")
}

test "Array::blit_to/grow_destination" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0]
  Array::blit_to(src, dst, len=3, dst_offset=1)
  inspect!(dst, content="[0, 1, 2, 3]")
}

test "Array::blit_to" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  Array::blit_to(src, dst, len=3)
  inspect!(dst, content="[1, 2, 3, 0, 0]")
}

test "Array::blit_to/edge_cases" {
  // Test with src_offset and dst_offset
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  Array::blit_to(src, dst, len=2, src_offset=1, dst_offset=2)
  inspect!(dst, content="[0, 0, 2, 3, 0]")

  // Test when src and dst are the same array
  Array::blit_to(src, src, len=2, src_offset=0, dst_offset=3)
  inspect!(src, content="[1, 2, 3, 1, 2]")

  // Test with len equal to 0
  Array::blit_to(src, dst, len=0, src_offset=0, dst_offset=0)
  inspect!(dst, content="[0, 0, 2, 3, 0]")

  // Test with len equal to the length of src
  Array::blit_to(src, dst, len=5)
  inspect!(dst, content="[1, 2, 3, 1, 2]")
}

test "panic Array::blit_to/boundary_cases" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]

  // Invalid len
  ignore(Array::blit_to(src, dst, len=-1))

  // Invalid src_offset
  ignore(Array::blit_to(src, dst, len=2, src_offset=-1))

  // Invalid dst_offset
  ignore(Array::blit_to(src, dst, len=2, dst_offset=-1))

  // len exceeding src length
  ignore(Array::blit_to(src, dst, len=6))

  // len exceeding dst length
  ignore(Array::blit_to(src, dst, len=5, dst_offset=1))
}

test "Array::blit_to - basic functionality" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  Array::blit_to(src, dst, len=3)
  inspect!(dst, content="[1, 2, 3, 0, 0]")
}

test "Array::blit_to - edge cases" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]

  // Test with src_offset and dst_offset
  Array::blit_to(src, dst, len=2, src_offset=1, dst_offset=2)
  inspect!(dst, content="[0, 0, 2, 3, 0]")

  // Test with len equal to the length of src
  Array::blit_to(src, dst, len=5, src_offset=0, dst_offset=0)
  inspect!(dst, content="[1, 2, 3, 4, 5]")

  // Test with len equal to 0
  Array::blit_to(src, dst, len=0, src_offset=0, dst_offset=0)
  inspect!(dst, content="[1, 2, 3, 4, 5]")
}

/// TODO
/// 1. allow skip
/// 2. verify test
/// 3. concurrency test
test "Array::blit_to - random cases" {
  let src = [10, 20, 30, 40, 50]
  let dst = [0, 0, 0, 0, 0]

  // Random len, src_offset, and dst_offset
  Array::blit_to(src, dst, len=2, src_offset=2, dst_offset=1)
  inspect!(dst, content="[0, 30, 40, 0, 0]")

  // Another random case
  Array::blit_to(src, dst, len=3, src_offset=1, dst_offset=2)
  inspect!(dst, content="[0, 30, 20, 30, 40]")

  // Yet another random case
  Array::blit_to(src, dst, len=1, src_offset=4, dst_offset=4)
  inspect!(dst, content="[0, 30, 20, 30, 50]")
}

test "Array::blit_to - boundary cases" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]

  // Test with src_offset at the end of src
  Array::blit_to(src, dst, len=1, src_offset=4, dst_offset=0)
  inspect!(dst, content="[5, 0, 0, 0, 0]")

  // Test with dst_offset at the end of dst
  Array::blit_to(src, dst, len=1, src_offset=0, dst_offset=4)
  inspect!(dst, content="[5, 0, 0, 0, 1]")

  // Test with len equal to the remaining length of src
  Array::blit_to(src, dst, len=2, src_offset=3, dst_offset=3)
  inspect!(dst, content="[5, 0, 0, 4, 5]")
}

// test "Array::blit_to - invalid cases" {
//   let src = [1, 2, 3, 4, 5]
//   let dst = [0, 0, 0, 0, 0]

//   // Invalid len
//   Array::blit_to(src, dst, len=-1)
//   inspect!(dst, content="[0, 0, 0, 0, 0]")

//   // Invalid src_offset
//   Array::blit_to(src, dst, len=2, src_offset=-1)
//   inspect!(dst, content="[0, 0, 0, 0, 0]")

//   // Invalid dst_offset
//   Array::blit_to(src, dst, len=2, dst_offset=-1)
//   inspect!(dst, content="[0, 0, 0, 0, 0]")

//   // len exceeding src length
//   Array::blit_to(src, dst, len=6)
//   inspect!(dst, content="[0, 0, 0, 0, 0]")

//   // len exceeding dst length
//   Array::blit_to(src, dst, len=5, dst_offset=1)
//   inspect!(dst, content="[0, 0, 0, 0, 0]")
// }
