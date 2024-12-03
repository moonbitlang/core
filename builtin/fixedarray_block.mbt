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
/// Copies a slice of elements from one fixed array to another.
///
/// This function copies `len` elements from `src` starting at `src_offset` to `dst` starting at `dst_offset`.
/// The arrays may overlap, in which case the copy is performed in a way that preserves the data.
///
/// # Example
/// ```
/// let src = FixedArray::from_array([1, 2, 3, 4, 5])
/// let dst = FixedArray::from_array([0, 0, 0, 0, 0])
/// FixedArray::unsafe_blit(dst, 0, src, 0, 3)
/// assert_eq!(dst, FixedArray::from_array([1, 2, 3, 0, 0]))
/// ```
///
/// The behavior is undefined and platform-specific if:
/// - `len < 0`
/// - `src_offset < 0`
/// - `dst_offset < 0`
/// - `dst_offset + len > dst.length()`
/// - `src_offset + len > src.length()`
///
/// @intrinsic %fixedarray.copy
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

///|
/// @intrinsic %fixedarray.copy
/// This is the same as `unsafe_blit`, but it is used when the source array is
/// FixedArray[T] instead of UninitializedArray[T].
fn UninitializedArray::unsafe_blit_fixed[T](
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : FixedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  for i = len - 1; i >= 0; i = i - 1 {
    dst[dst_offset + i] = src[src_offset + i]
  }
}

///|
pub fn FixedArray::blit_to[A](
  self : FixedArray[A],
  dst : FixedArray[A],
  len~ : Int,
  src_offset~ : Int = 0,
  dst_offset~ : Int = 0
) -> Unit {
  if dst_offset + len > dst.length() || src_offset + len > self.length() {
    panic()
  }
  FixedArray::unsafe_blit(dst, dst_offset, self, src_offset, len)
}
