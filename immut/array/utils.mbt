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

/// Utils for `FixedArray`s in the immutable array implementation.
/// Typically utility functions that are not related with trees.

///|
/// Set the value at the given index. This operation is O(n).
fn immutable_set[T](arr : FixedArray[T], i : Int, v : T) -> FixedArray[T] {
  let arr = arr.copy()
  arr[i] = v
  arr
}

///|
/// Add an element to the end of the array. This operation is O(n).
fn immutable_push[T](arr : FixedArray[T], val : T) -> FixedArray[T] {
  let len = arr.length()
  let new_arr = FixedArray::make(len + 1, val)
  arr.blit_to(new_arr, len~)
  new_arr[len] = val
  new_arr
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
  let mut lo = 0
  let mut hi = sizes.length()
  while LINEAR_THRESHOLD < hi - lo {
    let mid = (lo + hi) / 2
    if sizes[mid] <= index {
      lo = mid
    } else {
      hi = mid
    }
  }
  while sizes[lo] <= index {
    lo += 1
  }
  lo
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
