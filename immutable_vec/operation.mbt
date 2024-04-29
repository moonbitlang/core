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

pub fn immutable_copy[T](arr : Array[T]) -> Array[T] {
  let n = arr.length()
  let a = Array::make(n, arr[0])
  array_blit(src=arr, dst=a, 0, 0, n)
  a
}

pub fn immutable_set[T](arr : Array[T], i : Int, v : T) -> Array[T] {
  let arr = immutable_copy(arr)
  arr[i] = v
  arr
}

pub fn immutable_push[T](arr : Array[T], val : T) -> Array[T] {
  let len = arr.length()
  let new_arr = Array::make(len + 1, val)
  array_blit(src=arr, dst=new_arr, 0, 0, len)
  new_arr[len] = val
  new_arr
}

pub fn array_blit[T](
  ~src : Array[T],
  ~dst : Array[T],
  srcPos : Int,
  dstPos : Int,
  len : Int
) -> Unit {
  for i = 0; i < len; i = i + 1 {
    dst[dstPos + i] = src[srcPos + i]
  }
}
