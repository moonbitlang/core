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

test "array_as_view" {
  inspect!([1, 2, 3][:].length(), content="3")
}

test "view_as_view" {
  inspect!([1, 2, 3][:][:].length(), content="3")
}

test "op_get" {
  inspect!([1, 2, 3][:][1], content="2")
  inspect!([1, 2, 3][:][2], content="3")
}

test "op_set" {
  let v = [1, 2, 3][:]
  inspect!(v[1], content="2")
  v[1] = 4
  inspect!(v[1], content="4")
}

test "swap" {
  let v = [1, 2, 3][:]
  inspect!(v[1], content="2")
  v.swap(1, 2)
  inspect!(v[1], content="3")
}

test "iter" {
  let array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  @json.inspect!(
    array[:].iter().to_array(),
    content=[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  )
  @json.inspect!(array[5:].iter().to_array(), content=[5, 6, 7, 8, 9, 10])
  @json.inspect!(array[5:9].iter().to_array(), content=[5, 6, 7, 8])
}

test "to_string" {
  let arr = [0, 1, 2, 3, 4]
  @json.inspect!(arr[1:3], content=[1, 2])
  @json.inspect!("\{arr[1:3]}!", content="[1, 2]!")
}

test "arrayview_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.fold(fn(acc, x) { acc + x }, init=0)
  inspect!(sum, content="6")
}

test "arrayview_rev_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_fold(fn(acc, x) { acc + x }, init=0)
  inspect!(sum, content="6")
}

test "arrayview_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.foldi(fn(i, acc, x) { acc + i + x }, init=0)
  inspect!(sum, content="9")
}

test "arrayview_rev_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_foldi(fn(i, acc, x) { acc + i + x }, init=0)
  inspect!(sum, content="9")
}

test "arrayview_binary_search_int_test" {
  let arr = [1, 2, 3, 4][:]
  assert_eq!(arr.binary_search(-100), Err(0))
  assert_eq!(arr.binary_search(-1), Err(0))
  assert_eq!(arr.binary_search(1), Ok(0))
  assert_eq!(arr.binary_search(3), Ok(2))
  assert_eq!(arr.binary_search(4), Ok(3))
  assert_eq!(arr.binary_search(5), Err(4))
  assert_eq!(arr.binary_search(60), Err(4))
}

test "arrayview_binary_search_duplicate_int_test" {
  let arr = [1, 2, 3, 3, 4, 4, 4, 5][:]
  assert_eq!(arr.binary_search(3), Ok(2))
  assert_eq!(arr.binary_search(4), Ok(4))
  assert_eq!(arr.binary_search(5), Ok(7))
  let arr = [0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
  assert_eq!(arr.binary_search(1), Ok(1))
}

test "arrayview_binary_search_float_test" {
  let arr = [-0.25, 0.0, 1.5][:]
  assert_eq!(arr.binary_search(-0.25), Ok(0))
  assert_eq!(arr.binary_search(0.0), Ok(1))
  assert_eq!(arr.binary_search(1.5), Ok(2))
  assert_eq!(arr.binary_search(1.6), Err(3))
}

test "arrayview_binary_search_str_test" {
  let arr = ["hello", "world", "moon", "bit"][:]
  arr.sort()
  assert_eq!(arr.binary_search("bit"), Ok(0))
  assert_eq!(arr.binary_search("moon"), Ok(1))
  assert_eq!(arr.binary_search("hello"), Ok(2))
  assert_eq!(arr.binary_search("world"), Ok(3))
}
