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
test "SparseArray" {
  let arr0 = @sparse_array.singleton(1, 1)
  inspect([arr0[0], arr0[1], arr0[2]], content="[None, Some(1), None]")
  let arr1 = arr0.add(2, 2)
  inspect([arr1[0], arr1[1], arr1[2]], content="[None, Some(1), Some(2)]")
  let arr2 = arr1.add(0, 0)
  inspect([arr2[0], arr2[1], arr2[2]], content="[Some(0), Some(1), Some(2)]")
  let arr3 = arr2.replace(1, 42)
  inspect([arr3[0], arr3[1], arr3[2]], content="[Some(0), Some(42), Some(2)]")
}

///|
test "SparseArray::union" {
  let arr1 = @sparse_array.singleton(0, 0)
    .add(1, 1)
    .add(3, 3)
    .add(4, 4)
    .add(5, 5)
  let arr2 = @sparse_array.singleton(1, 10).add(2, 2).add(4, 40).add(31, 31)
  let arr3 = arr1.union(arr2, (_x, y) => y)
  inspect(
    [arr3[0], arr3[1], arr3[2], arr3[3], arr3[4], arr3[5], arr3[31]],
    content="[Some(0), Some(10), Some(2), Some(3), Some(40), Some(5), Some(31)]",
  )
}

///|
test "SparseArray::iter" {
  let arr = @sparse_array.singleton(0, 0).add(1, 1).add(3, 3).add(31, 31)
  let buf = StringBuilder::new(size_hint=0)
  let mut is_first = true
  arr.each(x => {
    if is_first {
      is_first = false
    } else {
      buf.write_string(", ")
    }
    buf.write_string(x.to_string())
  })
  inspect(buf, content="0, 1, 3, 31")
}
