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
type UninitializedArray[T] FixedArray[UnsafeMaybeUninit[T]]

///|
/// Creates an uninitialized array of the specified size.
///
/// Parameters:
///
/// - `size` : The number of elements the array should hold.
///
/// Returns an uninitialized array of type `T` with the specified size.
pub fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%fixedarray.make_uninit"

///|
/// Retrieves the element at the specified index from an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array from which to retrieve the element.
/// - `index` : The index of the element to retrieve.
///
/// Returns the element at the specified index.
pub fn UninitializedArray::op_get[T](
  self : UninitializedArray[T],
  index : Int
) -> T = "%fixedarray.get"

///|
/// Sets the value at the specified index in an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array where the value will be set.
/// - `index` : The position in the array where the value will be set.
/// - `value` : The value to be set at the specified index.
pub fn UninitializedArray::op_set[T](
  self : UninitializedArray[T],
  index : Int,
  value : T
) = "%fixedarray.set"

///|
/// Returns the length of an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array whose length is to be determined.
///
/// Returns the length of the uninitialized array as an integer.
pub fn UninitializedArray::length[A](self : UninitializedArray[A]) -> Int {
  self._.length()
}

///|
fn UninitializedArray::unsafe_blit[T](
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : UninitializedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  FixedArray::unsafe_blit(dst._, dst_offset, src._, src_offset, len)
}

///|
test "op_as_view with valid_range" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  let view = arr[1:4]
  inspect!(view.start, content="1")
  inspect!(view.len, content="3")
}

///|
test "panic op_as_view with invalid_start" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  ignore(arr[-6:])
}

///|
test "panic op_as_view with invalid_end" {
  let arr : UninitializedArray[Int] = UninitializedArray::make(5)
  ignore(arr[2:10])
}
