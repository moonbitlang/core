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

/// Utils for `FixedArray`s in the immutable array implementation.
/// Typically utility functions that are not related with trees.

///|
/// Set the value at the given index. This operation is O(n).
fn[T] immutable_set(arr : FixedArray[T], i : Int, v : T) -> FixedArray[T] {
  let arr = arr.copy()
  arr[i] = v
  arr
}

///|
/// Add an element to the end of the array. This operation is O(n).
fn[T] immutable_push(arr : FixedArray[T], val : T) -> FixedArray[T] {
  let len = arr.length()
  let new_arr = FixedArray::make(len + 1, val)
  arr.blit_to(new_arr, len~)
  new_arr[len] = val
  new_arr
}

///|
fn[T] immutable_concat(
  left : FixedArray[T],
  right : FixedArray[T],
) -> FixedArray[T] {
  let left_len = left.length()
  let right_len = right.length()
  if left_len == 0 {
    right.copy()
  } else if right_len == 0 {
    left.copy()
  } else {
    FixedArray::makei(left_len + right_len, i => {
      if i < left_len {
        left[i]
      } else {
        right[i - left_len]
      }
    })
  }
}

///|
fn[T] immutable_slice(
  arr : FixedArray[T],
  start : Int,
  end : Int,
) -> FixedArray[T] {
  let len = end - start
  if len <= 0 {
    []
  } else {
    FixedArray::makei(len, i => arr[start + i])
  }
}

///|
/// x >> y as unsigned integers, then reinterpret as signed integers.
fn shr_as_uint(x : Int, y : Int) -> Int {
  (x.reinterpret_as_uint() >> y).reinterpret_as_int()
}

///|
/// Given an index and a shift, return the index of the branch that contains the given index.
fn radix_indexing(index : Int, shift : Int) -> Int {
  shr_as_uint(index, shift) & bitmask
}

///|
/// Get the index of the branch that contains the given index.
/// For example, if the sizes are [0, 3, 6, 10] and the index is 5, the function should return 2.
fn get_branch_index(sizes : FixedArray[Int], index : Int) -> Int {
  let lo = for lo = 0, hi = sizes.length(); LINEAR_THRESHOLD < hi - lo; {
    let mid = (lo + hi) / 2
    if sizes[mid] <= index {
      continue mid, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  }
  for lo = lo; sizes[lo] <= index; {
    continue lo + 1
  } nobreak {
    lo
  }
}

///|
/// Copy the sizes array.
fn copy_sizes(sizes : FixedArray[Int]?) -> FixedArray[Int]? {
  match sizes {
    Some(sizes) => Some(sizes.copy())
    None => None
  }
}

///|
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}
