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

///|
test "fixedarray_fill - basic functionality" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  fa.fill(42)
  inspect(fa, content="[42, 42, 42, 42, 42]")
}

///|
test "fixedarray_fill - with start parameter only" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  fa.fill(99, start=2)
  inspect(fa, content="[1, 2, 99, 99, 99]")
}

///|
test "fixedarray_fill - with start and end parameters" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  fa.fill(77, start=1, end=3)
  inspect(fa, content="[1, 77, 77, 4, 5]")
}

///|
test "fixedarray_fill - start equals end" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  fa.fill(88, start=2, end=2)
  inspect(fa, content="[1, 2, 3, 4, 5]") // No change expected
}

///|
test "fixedarray_fill - start at beginning" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  fa.fill(10, start=0, end=2)
  inspect(fa, content="[10, 10, 3, 4, 5]")
}

///|
test "fixedarray_fill - end at array length" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  fa.fill(20, start=3, end=5)
  inspect(fa, content="[1, 2, 3, 20, 20]")
}

///|
test "fixedarray_fill - single element" {
  let fa : FixedArray[Int] = [100]
  fa.fill(50)
  inspect(fa, content="[50]")
}

///|
test "fixedarray_fill - empty array" {
  let fa : FixedArray[Int] = []
  fa.fill(123)
  inspect(fa, content="[]") // Should remain empty
}

///|
test "fixedarray_fill - with different types" {
  let str_fa : FixedArray[String] = ["a", "b", "c", "d"]
  str_fa.fill("x", start=1, end=3)
  inspect(str_fa, content="[\"a\", \"x\", \"x\", \"d\"]")
  let bool_fa : FixedArray[Bool] = [true, false, true, false]
  bool_fa.fill(true, start=0, end=2)
  inspect(bool_fa, content="[true, true, true, false]")
}

///|
test "fixedarray_fill - boundary conditions start" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  // Test with start at last valid index
  fa.fill(555, start=4, end=5)
  inspect(fa, content="[1, 2, 3, 4, 555]")
}

///|
test "fixedarray_fill - boundary conditions end" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  // Test with end at array length
  fa.fill(666, start=2, end=5)
  inspect(fa, content="[1, 2, 666, 666, 666]")
}

///|
test "fixedarray_fill - full range explicit" {
  let fa : FixedArray[Int] = [1, 2, 3, 4, 5]
  fa.fill(777, start=0, end=5)
  inspect(fa, content="[777, 777, 777, 777, 777]")
}

///|
test "fixedarray_fill - test with FixedArray::make" {
  let fa = FixedArray::make(4, 0)
  fa.fill(42, start=1, end=3)
  inspect(fa, content="[0, 42, 42, 0]")
}

///|
test "fixedarray_fill - existing documentation example" {
  let fa : FixedArray[Int] = [0, 0, 0, 0, 0]
  fa.fill(3)
  assert_eq(fa[0], 3)
  assert_eq(fa[1], 3)
  assert_eq(fa[2], 3)
  assert_eq(fa[3], 3)
  assert_eq(fa[4], 3)
}
