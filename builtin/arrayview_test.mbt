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

///-----------------------------------------------------------------------------
test "array_as_view" {
  inspect!([1, 2, 3][:].length(), content="3")
}

///-----------------------------------------------------------------------------
test "view_as_view" {
  inspect!([1, 2, 3][:][:].length(), content="3")
}

///-----------------------------------------------------------------------------
test "op_get" {
  inspect!([1, 2, 3][:][1], content="2")
  inspect!([1, 2, 3][:][2], content="3")
}

///-----------------------------------------------------------------------------
test "op_set" {
  let v = [1, 2, 3][:]
  inspect!(v[1], content="2")
  v[1] = 4
  inspect!(v[1], content="4")
}

///-----------------------------------------------------------------------------
test "swap" {
  let v = [1, 2, 3][:]
  inspect!(v[1], content="2")
  v.swap(1, 2)
  inspect!(v[1], content="3")
}

///-----------------------------------------------------------------------------
test "iter" {
  let array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  @json.inspect!(
    array[:].iter().to_array(),
    content=[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  )
  @json.inspect!(array[5:].iter().to_array(), content=[5, 6, 7, 8, 9, 10])
  @json.inspect!(array[5:9].iter().to_array(), content=[5, 6, 7, 8])
}

///-----------------------------------------------------------------------------
test "to_string" {
  let arr = [0, 1, 2, 3, 4]
  @json.inspect!(arr[1:3], content=[1, 2])
  @json.inspect!("\{arr[1:3]}!", content="[1, 2]!")
}

///-----------------------------------------------------------------------------
test "arrayview_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.fold(fn(acc, x) { acc + x }, init=0)
  inspect!(sum, content="6")
}

///-----------------------------------------------------------------------------
test "arrayview_rev_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_fold(fn(acc, x) { acc + x }, init=0)
  inspect!(sum, content="6")
}

///-----------------------------------------------------------------------------
test "arrayview_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.foldi(fn(i, acc, x) { acc + i + x }, init=0)
  inspect!(sum, content="9")
}

///-----------------------------------------------------------------------------
test "arrayview_rev_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_foldi(fn(i, acc, x) { acc + i + x }, init=0)
  inspect!(sum, content="9")
}
