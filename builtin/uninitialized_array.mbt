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
struct UninitializedArray[T](FixedArray[UnsafeMaybeUninit[T]])

///|
/// Creates an uninitialized array of the specified size.
///
/// Parameters:
///
/// - `size` : The number of elements the array should hold.
///
/// Returns an uninitialized array of type `T` with the specified size.
pub fn[T] UninitializedArray::make(size : Int) -> UninitializedArray[T] = "%fixedarray.make_uninit"

///|
/// Retrieves the element at the specified index from an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array from which to retrieve the element.
/// - `index` : The index of the element to retrieve.
///
/// Returns the element at the specified index.
#alias("_[_]")
pub fn[T] UninitializedArray::at(
  self : UninitializedArray[T],
  index : Int,
) -> T = "%fixedarray.get"

///|
#internal(unsafe, "For internal use only.")
fn[T] UninitializedArray::unsafe_get(
  self : UninitializedArray[T],
  index : Int,
) -> T = "%fixedarray.unsafe_get"

///|
/// Sets the value at the specified index in an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array where the value will be set.
/// - `index` : The position in the array where the value will be set.
/// - `value` : The value to be set at the specified index.
#alias("_[_]=_")
pub fn[T] UninitializedArray::set(
  self : UninitializedArray[T],
  index : Int,
  value : T,
) = "%fixedarray.set"

///|
#internal(unsafe, "For internal use only.")
fn[T] UninitializedArray::unsafe_set(
  self : UninitializedArray[T],
  index : Int,
  value : T,
) -> Unit = "%fixedarray.unsafe_set"

///|
/// Creates a view into a portion of the uninitialized array.
///
/// Parameters:
///
/// * `array` : The uninitialized array to create a view from.
/// * `start` : The starting index of the view (inclusive). Defaults to 0.
/// * `end` : The ending index of the view (exclusive). If not provided, defaults
/// to the length of the array.
///
/// Returns an `ArrayView` that provides a window into the specified portion of
/// the array.
///
/// Throws an error if the indices are out of bounds or if `start` is greater
/// than `end`.
#alias("_[_:_]")
pub fn[T] UninitializedArray::sub(
  self : UninitializedArray[T],
  start? : Int = 0,
  end? : Int,
) -> ArrayView[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => end
  }
  guard start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  ArrayView::make(self, start, end - start)
}

///|
/// Returns the length of an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array whose length is to be determined.
///
/// Returns the length of the uninitialized array as an integer.
pub fn[A] UninitializedArray::length(self : UninitializedArray[A]) -> Int {
  self.0.length()
}

///|
/// Unsafe variant of `blit`.
#internal(unsafe, "For internal use only.")
#doc(hidden)
pub fn[T] UninitializedArray::unsafe_blit(
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : UninitializedArray[T],
  src_offset : Int,
  len : Int,
) -> Unit {
  FixedArray::unsafe_blit(dst.0, dst_offset, src.0, src_offset, len)
}

///|
/// Unsafe variant of `make` followed by `unsafe_blit`.
#intrinsic("%fixedarray.make_with_blit")
#owned(src)
fn[T] UninitializedArray::unsafe_make_and_blit(
  src : UninitializedArray[T],
  allocate_len : Int,
  src_offset : Int,
  dst_offset : Int,
  blit_len : Int,
) -> UninitializedArray[T] {
  let dst = UninitializedArray::make(allocate_len)
  UninitializedArray::unsafe_blit(dst, dst_offset, src, src_offset, blit_len)
  dst
}

///|
/// Unsafe variant of `make` with `init` followed by `unsafe_blit`.
#cfg(not(target="js"))
#intrinsic("%fixedarray.make_with_init_blit")
#owned(src, init)
fn[T] UninitializedArray::unsafe_make_and_blit_with_init(
  src : UninitializedArray[T],
  allocate_len : Int,
  init : T,
  src_offset : Int,
  dst_offset : Int,
  blit_len : Int,
) -> UninitializedArray[T] {
  let dst = UninitializedArray::make(allocate_len)
  dst.unchecked_fill(0, init, allocate_len)
  UninitializedArray::unsafe_blit(dst, dst_offset, src, src_offset, blit_len)
  dst
}

///|
/// Checked variant of `unsafe_make_and_blit`.
pub fn[T] UninitializedArray::make_and_blit(
  src : UninitializedArray[T],
  allocate_len~ : Int,
  len~ : Int,
  src_offset? : Int = 0,
  dst_offset? : Int = 0,
) -> UninitializedArray[T] {
  guard allocate_len >= 0 &&
    len >= 0 &&
    src_offset >= 0 &&
    dst_offset >= 0 &&
    src_offset + len <= src.length() &&
    dst_offset + len <= allocate_len else {
    abort(
      "bounds check failed: allocate_len = \{allocate_len}, src_offset = \{src_offset}, dst_offset = \{dst_offset}, len = \{len}, src.length = \{src.length()}",
    )
  }
  UninitializedArray::unsafe_make_and_blit(
    src, allocate_len, src_offset, dst_offset, len,
  )
}

///|
/// Unsafe variant of `make` followed by `unsafe_blit_fixed`.
#cfg(not(target="js"))
#intrinsic("%fixedarray.make_with_blit")
#owned(src)
fn[T] UninitializedArray::unsafe_make_and_blit_from_fixed(
  src : FixedArray[T],
  allocate_len : Int,
  src_offset : Int,
  dst_offset : Int,
  blit_len : Int,
) -> UninitializedArray[T] {
  let dst = UninitializedArray::make(allocate_len)
  UninitializedArray::unsafe_blit_fixed(
    dst, dst_offset, src, src_offset, blit_len,
  )
  dst
}

///|
test "as_view with valid_range" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  let view = arr[1:4]
  inspect(view.start(), content="1")
  inspect(view.len(), content="3")
}

///|
test "panic as_view with invalid_start" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  ignore(arr[-1:])
}

///|
test "panic as_view with invalid_end" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  ignore(arr[2:10])
}

///|
#coverage.skip
#intrinsic("%fixedarray.fill")
#cfg(not(target="js"))
fn[T] UninitializedArray::unchecked_fill(
  self : UninitializedArray[T],
  start : Int,
  value : T,
  len : Int,
) -> Unit {
  for i in start..<(start + len) {
    self[i] = value
  }
}
