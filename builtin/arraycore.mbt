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

priv type UninitializedArray[T] FixedArray[UnsafeMaybeUninit[T]]

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%fixedarray.make_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%fixedarray.get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%fixedarray.set"

fn set_null[T](self : UninitializedArray[T], index : Int) = "%fixedarray.set_null"

fn UninitializedArray::unsafe_blit[T](
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : UninitializedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  FixedArray::unsafe_blit(dst.0, dst_offset, src.0, src_offset, len)
}

/// @intrinsic %fixedarray.copy
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

/// An `Array` is a collection of values that supports random access and can
/// grow in size.
// type Array

fn Array::make_uninit[T](len : Int, ~capacity: Int = len) -> Array[T] = "%array.make_uninit"

/// Creates a new array.
pub fn Array::new[T](~capacity : Int = 0) -> Array[T] {
  if capacity == 0 {
    []
  } else {
    Array::make_uninit(0, ~capacity)
  }
}

/// Returns the number of elements in the array.
pub fn length[T](self : Array[T]) -> Int = "%array.length"

fn set_length[T](self : Array[T], new_len : Int) -> Unit = "%array.set_length"

fn buffer[T](self : Array[T]) -> UninitializedArray[T] = "%array.buffer"

fn resize_buffer[T](self : Array[T], new_capacity : Int) -> Unit = "%array.resize_buffer"
