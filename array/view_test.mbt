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

test "slice" {
  let v = [1, 2, 3, 4, 5]
  let s = v[1:4]
  assert_eq!(s.length(), 3)
  assert_eq!(s[0], 2)
  assert_eq!(s[1], 3)
}

test "each" {
  let v = [1, 2, 3, 4, 5]
  let s = v[2:5]
  let mut sum = 0
  s.each(fn(x) { sum = sum + x })
  assert_eq!(sum, 12)
}

test "eachi" {
  let v = [3, 4, 5][:]
  let mut sum = 0
  for i, x in v {
    sum = sum + x + i
  }
  assert_eq!(sum, 15)
}

test "all" {
  let nums = [1, 2, 3, 4, 6, 8]
  assert_false!(nums[0:4].all(fn(x) { x % 2 == 0 }))
  assert_true!(nums[3:].all(fn(x) { x % 2 == 0 }))
}

test "any" {
  let v = [1, 2, 3, 4, 5, 6]
  assert_true!(v[:].any(fn(ele) { ele < 6 }))
  assert_true!(v[:].any(fn(ele) { ele < 5 }))
  assert_false!(v[4:].any(fn(ele) { ele < 5 }))
}

test "contains" {
  let v = [2, 3, 4, 5][:]
  assert_true!(v.contains(2))
  assert_true!(v.contains(3))
  assert_true!(v.contains(4))
  assert_false!(v.contains(6))
}

test "op_equal" {
  let v1 = [1, 2, 3][:]
  let v2 = [1, 2, 3][:]
  assert_true!(v1 == v2)
  let v3 = [1, 2, 4, 6, 10][1:3]
  let v4 = [0, 1, 2, 4, 6, 10, 12][2:4]
  assert_true!(v3 == v4)
  assert_false!(v1 == v3)
}

test "compare" {
  assert_eq!([1, 2, 4][:].compare([1, 2, 3][:]), 1)
  assert_eq!([-1, 2, 4][:].compare([1, 2, 4][:]), -1)
  assert_eq!([1, 2, 3][:].compare([1, 2, 3][:]), 0)
  assert_eq!([1, 2, 0][:].compare([1, 2][:]), 1)
  assert_eq!([1, 2][:].compare([1, 2, 0][:]), -1)
}
