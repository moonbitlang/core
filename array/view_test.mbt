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
test "slice" {
  let v = [1, 2, 3, 4, 5]
  let s = v[1:4]
  assert_eq!(s.length(), 3)
  assert_eq!(s[0], 2)
  assert_eq!(s[1], 3)
}

///|
test "each" {
  let v = [1, 2, 3, 4, 5]
  let s = v[2:5]
  let mut sum = 0
  s.each(fn(x) { sum = sum + x })
  assert_eq!(sum, 12)
}

///|
test "eachi" {
  let v = [3, 4, 5][:]
  let mut sum = 0
  v.eachi(fn(i, x) { sum = sum + x + i })
  inspect!(sum, content="15")
}

///|
test "all" {
  let nums = [1, 2, 3, 4, 6, 8]
  assert_false!(nums[0:4].all(fn(x) { x % 2 == 0 }))
  assert_true!(nums[3:].all(fn(x) { x % 2 == 0 }))
}

///|
test "any" {
  let v = [1, 2, 3, 4, 5, 6]
  assert_true!(v[:].any(fn(ele) { ele < 6 }))
  assert_true!(v[:].any(fn(ele) { ele < 5 }))
  assert_false!(v[4:].any(fn(ele) { ele < 5 }))
}

///|
test "contains" {
  let v = [2, 3, 4, 5][:]
  assert_true!(v.contains(2))
  assert_true!(v.contains(3))
  assert_true!(v.contains(4))
  assert_false!(v.contains(6))
}

///|
test "op_equal" {
  let v1 = [1, 2, 3][:]
  let v2 = [1, 2, 3][:]
  assert_true!(v1 == v2)
  let v3 = [1, 2, 4, 6, 10][1:3]
  let v4 = [0, 1, 2, 4, 6, 10, 12][2:4]
  assert_true!(v3 == v4)
  assert_false!(v1 == v3)
}

///|
test "compare" {
  assert_eq!([1, 2, 4][:].compare([1, 2, 3][:]), 1)
  assert_eq!([-1, 2, 4][:].compare([1, 2, 4][:]), -1)
  assert_eq!([1, 2, 3][:].compare([1, 2, 3][:]), 0)
  assert_eq!([1, 2, 0][:].compare([1, 2][:]), 1)
  assert_eq!([1, 2][:].compare([1, 2, 0][:]), -1)
}

///|
test "iter" {
  let array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  @json.inspect!(array[:].iter().to_array(), content=[
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  ])
  @json.inspect!(array[5:].iter().to_array(), content=[5, 6, 7, 8, 9, 10])
  @json.inspect!(array[5:9].iter().to_array(), content=[5, 6, 7, 8])
}

///|
test "to_string" {
  let arr = [0, 1, 2, 3, 4]
  @json.inspect!(arr[1:3], content=[1, 2])
  @json.inspect!("\{arr[1:3]}!", content="[1, 2]!")
}

///|
test "arrayview_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.fold(fn(acc, x) { acc + x }, init=0)
  inspect!(sum, content="6")
}

///|
test "arrayview_rev_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_fold(fn(acc, x) { acc + x }, init=0)
  inspect!(sum, content="6")
}

///|
test "arrayview_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.foldi(fn(i, acc, x) { acc + i + x }, init=0)
  inspect!(sum, content="9")
}

///|
test "arrayview_rev_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_foldi(fn(i, acc, x) { acc + i + x }, init=0)
  inspect!(sum, content="9")
}

///|
test "arrayview_map" {
  let arr = [1, 2, 3]
  let mapped = arr[1:].map(fn(x) { x * 2 })
  assert_eq!(mapped.length(), 2)
  assert_eq!(mapped[0], 4)
  assert_eq!(mapped[1], 6)
  @json.inspect!(([1] : Array[Int])[1:].map(fn(x) { x }), content=[])
}

///|
test "arrayview_map_inplace" {
  let arr = [1, 2, 3]
  arr[1:].map_inplace(fn(x) { x * 2 })
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 4)
  assert_eq!(arr[2], 6)
}

///|
test "arrayview_mapi" {
  let arr = [1, 2, 3]
  let mapped = arr[1:].mapi(fn(i, x) { i + x })
  assert_eq!(mapped.length(), 2)
  assert_eq!(mapped[0], 2)
  assert_eq!(mapped[1], 4)
  inspect!(([1] : Array[Int])[1:].mapi(fn(_idx, x) { x }), content="[]")
}

///|
test "arrayview_mapi_inplace" {
  let arr = [1, 2, 3]
  arr[1:].mapi_inplace(fn(i, x) { i + x })
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 4)
}

///|
test "arrayview_filter" {
  let arr = [1, 2, 3, 4, 5]
  let filtered = arr[2:].filter(fn(x) { x % 2 == 0 })
  assert_eq!(filtered.length(), 1)
  assert_eq!(filtered[0], 4)
}
