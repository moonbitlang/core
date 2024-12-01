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

test "map" {
  let v = [1, 2, 3, 4, 5]
  let s = v[2:5]
  let s2 = s.map(fn(x) { x * 2 })
  assert_eq!(s2.length(), 3)
  assert_eq!(s2, [6, 8, 10][:])
}

test "mapi" {
  let v = [3, 4, 5]
  let e = [][:]
  inspect!(v.mapi(fn(i, x) { x + i }), content="[3, 5, 7]")
  inspect!(
    v.mapi(fn(i, x) { (x + i).to_string() }),
    content=
      #|["3", "5", "7"]
    ,
  )
  inspect!(e.mapi(fn(_i, x) { x + 1 }), content="[]")
}

test "filter" {
  let arr = [1, 2, 3, 4, 5]
  let slice = arr[1:5].filter(fn(x) { x % 2 == 0 })
  inspect!(slice, content="[2, 4]")
}

test "all" {
  let nums = [1, 2, 3, 5, 7, 9][:]
  assert_eq!(nums.all(fn(x) { x % 2 == 0 }), false)
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

test "contains" {
  let v = [2, 3, 4, 5][:]
  assert_true!(v.contains(2))
  assert_true!(v.contains(3))
  assert_true!(v.contains(4))
  assert_false!(v.contains(6))
}

test "starts_with" {
  let v = [3, 4, 5][:]
  assert_true!(v.starts_with([3, 4][:]))
  assert_true!(v.starts_with([3, 4, 5][:]))
  assert_false!(v.starts_with([3, 4, 6][:]))
  assert_false!(v.starts_with([3, 4, 5, 6][:]))
}

test "ends_with" {
  let v = [3, 4, 5][:]
  assert_true!(v.ends_with([4, 5][:]))
  assert_true!(v.ends_with([3, 4, 5][:]))
  assert_false!(v.ends_with([3, 4, 6][:]))
  assert_false!(v.ends_with([2, 3, 4, 5][:]))
}

test "search" {
  let v = [3, 4, 5][:]
  assert_eq!(v.search(3), Some(0))
  assert_eq!(v.search(4), Some(1))
  assert_eq!(v.search(5), Some(2))
  assert_eq!(v.search(6), None)
}

test "fold" {
  let sum = [1, 2, 3, 4, 5].fold(init=0, fn { sum, elem => sum + elem })
  assert_eq!(sum, 15)
}

test "foldi" {
  let sum = [1, 2, 3, 4, 5][:].foldi(
    init=0,
    fn { index, sum, _elem => sum + index },
  )
  assert_eq!(sum, 10)
}

test "search_by" {
  let arr = [1, 2, 3, 4, 5, 6, 7][:]
  let index = arr.search_by(fn(x) { x == 3 })
  assert_eq!(index, Some(2))
}

test "is_empty" {
  let v = []
  assert_true!(v.is_empty())
  v.push(3)
  assert_false!(v.is_empty())
}

test "is_sorted" {
  let v : ArrayView[Int] = [][:]
  assert_true!(v.is_sorted())
  let v = [3, 4, 5][:]
  assert_true!(v.is_sorted())
  let v2 = [3, 5, 4][:]
  assert_false!(v2.is_sorted())
}
