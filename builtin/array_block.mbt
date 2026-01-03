// Copyright 2026 International Digital Economy Academy
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
/// Copies elements from one array to another array. Works correctly even when
/// the source and destination arrays overlap.
///
/// Parameters:
///
/// * `dst` : The destination array where elements will be copied to.
/// * `dst_offset` : The starting index in the destination array where elements
/// should be copied.
/// * `src` : The source array from which elements will be copied.
/// * `src_offset` : The starting index in the source array from which elements
/// should be copied.
/// * `len` : The number of elements to copy.
///
/// The behavior is undefined if any of the following conditions are met:
///
/// * `len` is negative
/// * `dst_offset` is negative
/// * `src_offset` is negative
/// * `dst_offset + len` exceeds the length of destination array
/// * `src_offset + len` exceeds the length of source array
///
/// Example:
///
/// ```mbt check
/// test {
///   let src = [1, 2, 3, 4, 5]
///   let dst = [0, 0, 0, 0, 0]
///   Array::unsafe_blit(dst, 1, src, 2, 2)
///   inspect(dst, content="[0, 3, 4, 0, 0]")
/// }
/// ```
///
#internal(unsafe, "Panic if the indices or length are out of bounds")
#doc(hidden)
pub fn[A] Array::unsafe_blit(
  dst : Array[A],
  dst_offset : Int,
  src : Array[A],
  src_offset : Int,
  len : Int,
) -> Unit {
  FixedArray::unsafe_blit(
    dst.buffer().0,
    dst_offset,
    src.buffer().0,
    src_offset,
    len,
  )
}

///|
/// Copies elements from a fixed-size array to a dynamic array. The arrays may
/// overlap, in which case the copy is performed in a way that preserves the
/// data.
///
/// Parameters:
///
/// * `dst` : The destination dynamic array where elements will be copied to.
/// * `dst_offset` : The starting index in the destination array where copying
/// begins.
/// * `src` : The source fixed-size array from which elements will be copied.
/// * `src_offset` : The starting index in the source array from which copying
/// begins.
/// * `len` : The number of elements to copy.
///
/// Example:
///
/// ```mbt check
/// test {
///   let src = FixedArray::make(5, 0)
///   let dst = Array::make(5, 0)
///   for i in 0..<5 {
///     src[i] = i + 1
///   }
///   Array::unsafe_blit_fixed(dst, 1, src, 0, 2)
///   inspect(dst, content="[0, 1, 2, 0, 0]")
/// }
/// ```
pub fn[A] Array::unsafe_blit_fixed(
  dst : Array[A],
  dst_offset : Int,
  src : FixedArray[A],
  src_offset : Int,
  len : Int,
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
/// Copies elements from one array to another array, with support for growing the
/// destination array if needed. The arrays may overlap, in which case the copy
/// is performed in a way that preserves the data.
///
/// Parameters:
///
/// * `self` : The array to copy elements from.
/// * `dst` : The array to copy elements to. Will be automatically grown
/// if needed to accommodate the copied elements.
/// * `len` : The number of elements to copy.
/// * `src_offset` : Starting index in the source array. Defaults to 0.
/// * `dst_offset` : Starting index in the destination array. Defaults to
/// 0.
///
/// Example:
///
/// ```mbt check
/// test {
///   let src = [1, 2, 3, 4, 5]
///   let dst = [0, 0]
///   src[:3].blit_to(dst, dst_offset=1)
///   inspect(dst, content="[0, 1, 2, 3]")
/// }
/// ```
///
/// Panics if:
///
/// * `len` is negative
/// * `src_offset` is negative
/// * `dst_offset` is negative
/// * `dst_offset` exceeds the length of destination array
/// * `src_offset + len` exceeds the length of source array
// TODO: make len optional and deprecate it
#label_migration(src_offset, fill=false, msg="Use ArrayView::blit_to instead")
#label_migration(len, fill=false, msg="Use ArrayView::blit_to instead")
pub fn[A] Array::blit_to(
  self : Array[A],
  dst : Array[A],
  len? : Int = self.length(),
  src_offset? : Int = 0,
  dst_offset? : Int = 0,
) -> Unit {
  guard len >= 0 &&
    dst_offset >= 0 &&
    src_offset >= 0 &&
    dst_offset <= dst.length() &&
    src_offset + len <= self.length()
  if dst_offset + len > dst.length() {
    dst.unsafe_grow_to_length(dst_offset + len)
  }
  Array::unsafe_blit(dst, dst_offset, self, src_offset, len)
}

///|
/// Copies all elements from an array view to a destination array, with support
/// for growing the destination array if needed.
///
/// Parameters:
///
/// * `self` : The array view to copy elements from.
/// * `dst` : The array to copy elements to. Will be automatically grown
/// if needed to accommodate the copied elements.
/// * `dst_offset` : Starting index in the destination array. Defaults to 0.
///
/// Example:
///
/// ```mbt check
/// test {
///   let src = [1, 2, 3, 4, 5]
///   let view = src[1:4] // view = [2, 3, 4]
///   let dst = [0, 0]
///   view.blit_to(dst, dst_offset=1)
///   inspect(dst, content="[0, 2, 3, 4]")
/// }
/// ```
///
/// Panics if:
///
/// * `dst_offset` is negative
/// * `dst_offset` exceeds the length of destination array
pub fn[A] ArrayView::blit_to(
  self : ArrayView[A],
  dst : Array[A],
  dst_offset? : Int = 0,
) -> Unit {
  let len = self.len()
  guard dst_offset >= 0 && dst_offset <= dst.length()
  if dst_offset + len > dst.length() {
    dst.unsafe_grow_to_length(dst_offset + len)
  }
  UninitializedArray::unsafe_blit(
    dst.buffer(),
    dst_offset,
    self.buf(),
    self.start(),
    len,
  )
}

///|
test "Array::blit_to/basic" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  src[1:4].blit_to(dst, dst_offset=2)
  inspect(dst, content="[0, 0, 2, 3, 4]")
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  src[0:3].blit_to(dst)
  inspect(dst, content="[1, 2, 3, 0, 0]")
}

///|
test "Array::blit_to/zero_length" {
  let src = [1, 2, 3]
  let dst = [4, 5, 6]
  src[0:0].blit_to(dst)
  inspect(dst, content="[4, 5, 6]")
}

///|
test "Array::blit_to/grow_destination" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0]
  src[0:3].blit_to(dst, dst_offset=1)
  inspect(dst, content="[0, 1, 2, 3]")
}

///|
test "Array::blit_to/edge_cases" {
  // Test with src_offset and dst_offset
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  src[1:3].blit_to(dst, dst_offset=2)
  inspect(dst, content="[0, 0, 2, 3, 0]")

  // Test when src and dst are the same array
  src[0:2].blit_to(src, dst_offset=3)
  inspect(src, content="[1, 2, 3, 1, 2]")

  // Test with len equal to 0
  src[0:0].blit_to(dst, dst_offset=0)
  inspect(dst, content="[0, 0, 2, 3, 0]")

  // Test with len equal to the length of src
  src[0:5].blit_to(dst)
  inspect(dst, content="[1, 2, 3, 1, 2]")
}

///|
test "panic Array::blit_to/boundary_cases1" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]

  // Invalid range (start > end will panic)
  ignore(src[3:1].blit_to(dst))
}

///|
test "panic Array::blit_to/boundary_cases2" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  // Invalid src_offset (negative index in view creation will panic)
  ignore(src[-1:1].blit_to(dst))
}

///|
test "panic Array::blit_to/boundary_cases3" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  // len exceeding src length
  ignore(src[0:6].blit_to(dst))
}

///|
test "panic Array::blit_to/boundary_cases4" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  // dst offset exceeding dst length
  ignore(src[0:5].blit_to(dst, dst_offset=6))
}

///|
/// TODO
/// 1. allow skip
/// 2. verify test
/// 3. concurrency test
test "Array::blit_to - random cases" {
  let src = [10, 20, 30, 40, 50]
  let dst = [0, 0, 0, 0, 0]

  // Random len, src_offset, and dst_offset
  src[2:4].blit_to(dst, dst_offset=1)
  inspect(dst, content="[0, 30, 40, 0, 0]")

  // Another random case
  src[1:4].blit_to(dst, dst_offset=2)
  inspect(dst, content="[0, 30, 20, 30, 40]")

  // Yet another random case
  src[4:5].blit_to(dst, dst_offset=4)
  inspect(dst, content="[0, 30, 20, 30, 50]")
}

///|
test "Array::blit_to - boundary cases" {
  let src = [1, 2, 3, 4, 5]
  let dst = [0, 0, 0, 0, 0]

  // Test with src_offset at the end of src
  src[4:5].blit_to(dst, dst_offset=0)
  inspect(dst, content="[5, 0, 0, 0, 0]")

  // Test with dst_offset at the end of dst
  src[0:1].blit_to(dst, dst_offset=4)
  inspect(dst, content="[5, 0, 0, 0, 1]")

  // Test with len equal to the remaining length of src
  src[3:5].blit_to(dst, dst_offset=3)
  inspect(dst, content="[5, 0, 0, 4, 5]")
}

///|
test "Array::unsafe_blit_fixed" {
  let src = FixedArray::make(3, 1) // Create a FixedArray with 3 elements of value 1
  let dst = Array::make(5, 0) // Create an Array with 5 elements of value 0
  Array::unsafe_blit_fixed(dst, 1, src, 0, 2) // Copy 2 elements from src[0] to dst[1]
  inspect(dst, content="[0, 1, 1, 0, 0]")
}

///|
test "ArrayView::blit_to/basic" {
  let src = [1, 2, 3, 4, 5]
  let view = src[1:4] // view = [2, 3, 4]
  let dst = [0, 0, 0, 0, 0]
  view.blit_to(dst)
  inspect(dst, content="[2, 3, 4, 0, 0]")
}

///|
test "ArrayView::blit_to/with_offset" {
  let src = [1, 2, 3, 4, 5]
  let view = src[1:4] // view = [2, 3, 4]
  let dst = [0, 0, 0, 0, 0]
  view.blit_to(dst, dst_offset=2)
  inspect(dst, content="[0, 0, 2, 3, 4]")
}

///|
test "ArrayView::blit_to/grow_destination" {
  let src = [1, 2, 3, 4, 5]
  let view = src[1:4] // view = [2, 3, 4]
  let dst = [0, 0]
  view.blit_to(dst, dst_offset=1)
  inspect(dst, content="[0, 2, 3, 4]")
}

///|
test "ArrayView::blit_to/empty_view" {
  let src = [1, 2, 3, 4, 5]
  let view = src[2:2] // empty view
  let dst = [0, 0, 0]
  view.blit_to(dst)
  inspect(dst, content="[0, 0, 0]")
}

///|
test "ArrayView::blit_to/nested_view" {
  let src = [1, 2, 3, 4, 5, 6, 7]
  let view1 = src[1:6] // [2, 3, 4, 5, 6]
  let view2 = view1[1:4] // [3, 4, 5]
  let dst = [0, 0, 0, 0, 0]
  view2.blit_to(dst, dst_offset=1)
  inspect(dst, content="[0, 3, 4, 5, 0]")
}

///|
test "panic ArrayView::blit_to/invalid_offset" {
  let src = [1, 2, 3, 4, 5]
  let view = src[1:4]
  let dst = [0, 0, 0]
  ignore(view.blit_to(dst, dst_offset=-1))
}

///|
test "panic ArrayView::blit_to/offset_exceeds_length" {
  let src = [1, 2, 3, 4, 5]
  let view = src[1:4]
  let dst = [0, 0, 0]
  ignore(view.blit_to(dst, dst_offset=4))
}

// test "Array::blit_to - invalid cases" {
//   let src = [1, 2, 3, 4, 5]
//   let dst = [0, 0, 0, 0, 0]

//   // Invalid len
//   Array::blit_to(src, dst, len=-1)
//   inspect(dst, content="[0, 0, 0, 0, 0]")

//   // Invalid src_offset
//   Array::blit_to(src, dst, len=2, src_offset=-1)
//   inspect(dst, content="[0, 0, 0, 0, 0]")

//   // Invalid dst_offset
//   Array::blit_to(src, dst, len=2, dst_offset=-1)
//   inspect(dst, content="[0, 0, 0, 0, 0]")

//   // len exceeding src length
//   Array::blit_to(src, dst, len=6)
//   inspect(dst, content="[0, 0, 0, 0, 0]")

//   // len exceeding dst length
//   Array::blit_to(src, dst, len=5, dst_offset=1)
//   inspect(dst, content="[0, 0, 0, 0, 0]")
// }
