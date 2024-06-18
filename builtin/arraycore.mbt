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
struct Array[T] {
  mut buf : UninitializedArray[T]
  mut len : Int
}

fn Array::make_uninit[T](len : Int) -> Array[T] {
  { buf: UninitializedArray::make(len), len }
}

/// Creates a new, empty vector with a specified initial capacity.
pub fn Array::with_capacity[T](cap : Int) -> Array[T] {
  { buf: UninitializedArray::make(cap), len: 0 }
}

/// Returns the number of elements in the vector.
pub fn length[T](self : Array[T]) -> Int {
  self.len
}

fn set_length[T](self : Array[T], new_len : Int) -> Unit {
  // assert new_len >= 0 && new_len <= self.buf.len
  if new_len < self.len {
    for i = new_len; i < self.len; i = i + 1 {
      self.buf.set_null(i)
    }
  }
  self.len = new_len
}

fn buffer[T](self : Array[T]) -> UninitializedArray[T] {
  self.buf
}

fn resize_buffer[T](self : Array[T], new_capacity : Int) -> Unit {
  let new_buf = UninitializedArray::make(new_capacity)
  let old_buf = self.buf
  let old_cap = old_buf.0.length()
  let copy_len = if old_cap < new_capacity { old_cap } else { new_capacity }
  UninitializedArray::unsafe_blit(new_buf, 0, old_buf, 0, copy_len)
  self.buf = new_buf
}
