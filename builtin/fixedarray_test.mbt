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
  assert_eq(emptyArray.to_string(), "[]")
}

///|
test "to_string with non-empty FixedArray" {
  let array : FixedArray[Int] = [1, 2, 3]
  assert_eq(array.to_string(), "[1, 2, 3]")
}

///|
test "compare" {
  let arr1 : FixedArray[Int] = [1, 2, 3]
  let arr2 : FixedArray[Int] = [1, 2, 4]
  let arr3 : FixedArray[Int] = [1, 2]
  inspect(arr1.compare(arr2), content="-1")
  inspect(arr1.compare(arr3), content="1")
  inspect(arr3.compare(arr1), content="-1")
  inspect(arr1.compare(arr1), content="0")
}

///|
test "is_empty" {
  let arr : FixedArray[Int] = []
  assert_true(arr.is_empty())
}

///|
test "fixed array iter with early termination" {
  let arr : FixedArray[Int] = [1, 2, 3]
  let mut count = 0
  let iter = arr.iter()
  let _ = iter.run(x => {
    count = count + 1
    if x == 2 {
      IterEnd
    } else {
      IterContinue
    }
  })
  inspect(count, content="2")
}

///|
test "FixedArray::iter2 with empty array" {
  let arr : FixedArray[Int] = []
  let mut count = 0
  arr.iter2().each((_, _) => count = count + 1)
  inspect(count, content="0")
}

///|
test "FixedArray::iter2 with single element" {
  let arr = FixedArray::make(1, 42)
  let pairs : Array[(Int, Int)] = []
  arr.iter2().each((i, x) => pairs.push((i, x)))
  inspect(pairs, content="[(0, 42)]")
}

///|
test "fixedarray_binary_search_int_test" {
  let arr : FixedArray[Int] = [1, 2, 3, 4]
  assert_eq(arr.binary_search(-100), Err(0))
  assert_eq(arr.binary_search(-1), Err(0))
  assert_eq(arr.binary_search(1), Ok(0))
  assert_eq(arr.binary_search(3), Ok(2))
  assert_eq(arr.binary_search(4), Ok(3))
  assert_eq(arr.binary_search(5), Err(4))
  assert_eq(arr.binary_search(60), Err(4))
}

///|
test "fixedarray_binary_search_duplicate_int_test" {
  let arr : FixedArray[Int] = [1, 2, 3, 3, 4, 4, 4, 5]
  assert_eq(arr.binary_search(3), Ok(2))
  assert_eq(arr.binary_search(4), Ok(4))
  assert_eq(arr.binary_search(5), Ok(7))
  let arr = [0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
  assert_eq(arr.binary_search(1), Ok(1))
}

///|
test "fixedarray_binary_search_float_test" {
  let arr : FixedArray[Float] = [-0.25, 0.0, 1.5]
  assert_eq(arr.binary_search(-0.25), Ok(0))
  assert_eq(arr.binary_search(0.0), Ok(1))
  assert_eq(arr.binary_search(1.5), Ok(2))
  assert_eq(arr.binary_search(1.6), Err(3))
}

///|
test "fixedarray_binary_search_str_test" {
  let arr : FixedArray[String] = ["hello", "world", "moon", "bit"]
  arr.sort()
  assert_eq(arr.binary_search("bit"), Ok(0))
  assert_eq(arr.binary_search("moon"), Ok(1))
  assert_eq(arr.binary_search("hello"), Ok(2))
  assert_eq(arr.binary_search("world"), Ok(3))
}

///|
struct TestStruct2 {
  num2 : Int
}

///|
test "fixedarray_binary_search_by_test" {
  let arr : FixedArray[TestStruct2] = [
    { num2: 10 },
    { num2: 22 },
    { num2: 35 },
    { num2: 48 },
  ]
  let mut target : TestStruct2 = { num2: 22 }
  fn cmp(val : TestStruct2) {
    if val.num2 < target.num2 {
      -1
    } else if val.num2 == target.num2 {
      0
    } else {
      1
    }
  }

  assert_eq(arr.binary_search_by(cmp), Ok(1))
  target = { num2: 48 }
  assert_eq(arr.binary_search_by(cmp), Ok(3))
  target = { num2: -8 }
  assert_eq(arr.binary_search_by(cmp), Err(0))
  target = { num2: 49 }
  assert_eq(arr.binary_search_by(cmp), Err(4))
}
