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
/// Copies a slice of elements from one fixed array to another.
///
/// This function copies `len` elements from `src` starting at `src_offset` to `dst` starting at `dst_offset`.
/// The arrays may overlap, in which case the copy is performed in a way that preserves the data.
///
/// # Example
/// ```mbt check
/// test {
///   let src = FixedArray::from_array([1, 2, 3, 4, 5])
///   let dst = FixedArray::from_array([0, 0, 0, 0, 0])
///   FixedArray::unsafe_blit(dst, 0, src, 0, 3)
///   assert_eq(dst, FixedArray::from_array([1, 2, 3, 0, 0]))
/// }
/// ```
///
/// The behavior is undefined and platform-specific if:
/// - `len < 0`
/// - `src_offset < 0`
/// - `dst_offset < 0`
/// - `dst_offset + len > dst.length()`
/// - `src_offset + len > src.length()`
///
#intrinsic("%fixedarray.copy")
#coverage.skip
pub fn[A] FixedArray::unsafe_blit(
  dst : FixedArray[A],
  dst_offset : Int,
  src : FixedArray[A],
  src_offset : Int,
  len : Int,
) -> Unit {
  if physical_equal(dst, src) && dst_offset < src_offset {
    for i in 0..<len {
      dst[dst_offset + i] = src[src_offset + i]
    }
  } else {
    for i = len - 1; i >= 0; i = i - 1 {
      dst[dst_offset + i] = src[src_offset + i]
    }
  }
}

///|
/// This is the same as `unsafe_blit`, but it is used when the source array is
/// FixedArray[T] instead of UninitializedArray[T].
#intrinsic("%fixedarray.copy")
#coverage.skip
fn[T] UninitializedArray::unsafe_blit_fixed(
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : FixedArray[T],
  src_offset : Int,
  len : Int,
) -> Unit {
  for i = len - 1; i >= 0; i = i - 1 {
    dst[dst_offset + i] = src[src_offset + i]
  }
}

///|
/// Copies a sequence of elements from the source fixed array to a destination
/// fixed array. The arrays may overlap, in which case the copy is performed in a
/// way that preserves the data.
///
/// Parameters:
///
/// * `self` : The source fixed array from which elements will be copied.
/// * `dst` : The destination fixed array where elements will be copied to.
/// * `len` : The number of elements to copy.
/// * `src_offset` : The starting position in the source array. Defaults to 0.
/// * `dst_offset` : The starting position in the destination array. Defaults to
/// 0.
///
/// Throws a panic if:
///
/// * `src_offset + len` exceeds the length of the source array
/// * `dst_offset + len` exceeds the length of the destination array
///
/// Example:
///
/// ```mbt check
/// test {
///   let src = FixedArray::make(5, 1)
///   let dst = FixedArray::make(5, 0)
///   src.blit_to(dst, len=3, src_offset=1, dst_offset=2)
///   inspect(dst, content="[0, 0, 1, 1, 1]")
/// }
/// ```
pub fn[A] FixedArray::blit_to(
  self : FixedArray[A],
  dst : FixedArray[A],
  len~ : Int,
  src_offset? : Int = 0,
  dst_offset? : Int = 0,
) -> Unit {
  guard dst_offset >= 0 &&
    src_offset >= 0 &&
    dst_offset + len <= dst.length() &&
    src_offset + len <= self.length() else {
    abort(
      "bounds check failed: dst_offset = \{dst_offset}, src_offset = \{src_offset}, len = \{len}, dst.length = \{dst.length()}, self.length = \{self.length()}",
    )
  }
  FixedArray::unsafe_blit(dst, dst_offset, self, src_offset, len)
}
