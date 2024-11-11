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
pub fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%fixedarray.get"

///|
/// Sets the value at the specified index in an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array where the value will be set.
/// - `index` : The position in the array where the value will be set.
/// - `value` : The value to be set at the specified index.
pub fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%fixedarray.set"

///|
/// Returns the length of an uninitialized array.
///
/// Parameters:
///
/// - `array` : The uninitialized array whose length is to be determined.
///
/// Returns the length of the uninitialized array as an integer.
pub fn length[A](self : UninitializedArray[A]) -> Int {
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
