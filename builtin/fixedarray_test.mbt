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
test "to_string with empty FixedArray" {
  let emptyArray : FixedArray[Int] = FixedArray::default()
  assert_eq!(emptyArray.to_string(), "[]")
}

///|
test "to_string with non-empty FixedArray" {
  let array : FixedArray[Int] = [1, 2, 3]
  assert_eq!(array.to_string(), "[1, 2, 3]")
}

///|
test "compare" {
  let arr1 : FixedArray[Int] = [1, 2, 3]
  let arr2 : FixedArray[Int] = [1, 2, 4]
  let arr3 : FixedArray[Int] = [1, 2]
  inspect!(arr1.compare(arr2), content="-1")
  inspect!(arr1.compare(arr3), content="1")
  inspect!(arr3.compare(arr1), content="-1")
  inspect!(arr1.compare(arr1), content="0")
}

///|
test "is_empty" {
  let arr : FixedArray[Int] = []
  assert_true!(arr.is_empty())
}

///|
test "fixed array iter with early termination" {
  let arr : FixedArray[Int] = [1, 2, 3]
  let mut count = 0
  let iter = arr.iter()
  let _ = iter.run(fn(x) {
    count = count + 1
    if x == 2 {
      IterEnd
    } else {
      IterContinue
    }
  })
  inspect!(count, content="2")
}

///|
test "FixedArray::iter2 with empty array" {
  let arr : FixedArray[Int] = []
  let mut count = 0
  arr.iter2().each(fn(_, _) { count = count + 1 })
  inspect!(count, content="0")
}

///|
test "FixedArray::iter2 with single element" {
  let arr = FixedArray::make(1, 42)
  let pairs : Array[(Int, Int)] = []
  arr.iter2().each(fn(i, x) { pairs.push((i, x)) })
  inspect!(pairs, content="[(0, 42)]")
}
