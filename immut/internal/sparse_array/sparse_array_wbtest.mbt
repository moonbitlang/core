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

test "SparseArray" {
  let arr0 = singleton(1, 1)
  inspect!(
    (arr0.has(0), arr0[0], arr0.has(1), arr0[1], arr0.has(2), arr0[2]),
    content="(false, None, true, Some(1), false, None)",
  )
  let arr1 = arr0.add(2, 2)
  inspect!(
    (arr1.has(0), arr1[0], arr1.has(1), arr1[1], arr1.has(2), arr1[2]),
    content="(false, None, true, Some(1), true, Some(2))",
  )
  let arr2 = arr1.add(0, 0)
  inspect!(
    (arr2.has(0), arr2[0], arr2.has(1), arr2[1], arr2.has(2), arr2[2]),
    content="(true, Some(0), true, Some(1), true, Some(2))",
  )
  let arr3 = arr2.replace(1, 42)
  inspect!(
    (arr3.has(0), arr3[0], arr3.has(1), arr3[1], arr3.has(2), arr3[2]),
    content="(true, Some(0), true, Some(42), true, Some(2))",
  )
}

test "SparseArray::iter" {
  let arr = singleton(0, 0).add(1, 1).add(3, 3).add(31, 31)
  let buf = Buffer::new(size_hint=0)
  let mut is_first = true
  arr.each(
    fn(x) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      buf.write_string(x.to_string())
    },
  )
  inspect!(buf, content="0, 1, 3, 31")
}
