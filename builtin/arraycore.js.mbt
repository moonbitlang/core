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

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%make_array_maybe_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%array_get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%array_set"

fn set_null[T](self : UninitializedArray[T], index : Int) = "%array_set_null"

/// An `Array` is a collection of values that supports random access and can
/// grow in size.
type Array[T] UninitializedArray[T]

fn Array::make_uninit[T](len : Int) -> Array[T] {
  UninitializedArray::make(len)
}

/// Creates a new, empty vector with a specified initial capacity.
pub fn Array::with_capacity[T](_cap : Int) -> Array[T] {
  UninitializedArray::make(0)
}

fn set_length[T](self : Array[T], new_len : Int) -> Unit = "%array_truncate_length"

/// Returns the number of elements in the vector.
pub fn length[T](self : Array[T]) -> Int {
  self.0.0.length()
}

fn buffer[T](self : Array[T]) -> UninitializedArray[T] {
  self.0
}

fn resize_buffer[T](self : Array[T], _new_capacity : Int) -> Unit {
  ignore(self)
}
