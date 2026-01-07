// Copyright 2026 International Digital Economy Academy
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
test "fill with range" {
  let arr : FixedArray[Int] = [0, 0, 0, 0]
  arr.fill(5, start=1, end=3)
  inspect(arr, content="[0, 5, 5, 0]")
}

///|
test "stable_sort short run" {
  let arr : FixedArray[Int] = [
    1, 2, 3, 0, 9, 8, 7, 6, 5, 4, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23,
  ]
  arr.stable_sort()
  assert_true(FixedArray::is_sorted(arr))
}

///|
test "fixed array iter with early termination" {
  let arr : FixedArray[Int] = [1, 2, 3]
  let mut count = 0
  let iter = arr.iter()
  for x in iter {
    count = count + 1
    if x == 2 {
      break
    }
  }
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
  @json.inspect(str_fa, content=["a", "x", "x", "d"])
  let bool_fa : FixedArray[Bool] = [true, false, true, false]
  bool_fa.fill(true, start=0, end=2)
  @json.inspect(bool_fa, content=[true, true, true, false])
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
  inspect(fa[:], content="[3, 3, 3, 3, 3]")
}

///|
test "FixedArray::sub" {
  let arr = FixedArray::makei(10, i => i * i)
  let sub = arr[:]
  inspect(sub, content="[0, 1, 4, 9, 16, 25, 36, 49, 64, 81]")
  inspect(sum(sub), content="285")
}

///|
fn sum(xs : ArrayView[Int]) -> Int {
  xs.fold(init=0, (acc, x) => acc + x)
}

///|
// TODO: fix(upstream) later
#cfg(false)
test "FixedArray::sub - sum" {
  let arr = FixedArray::makei(10, i => i * i)
  inspect(sum(arr), content="385")
}

///|
test "FixedArray::from_array with empty array" {
  let array : Array[Int] = []
  let fixedArray = FixedArray::from_array(array)
  inspect(fixedArray.length(), content="0")
}

///|
test "FixedArray::from_array with non-empty array" {
  let array : Array[Int] = [1, 2, 3, 4, 5]
  let fixedArray = FixedArray::from_array(array)
  inspect(fixedArray.length(), content="5")
  for i in 0..<5 {
    assert_eq(fixedArray[i], array[i])
  }
}

///|
test "FixedArray::from_array with array of different type" {
  let array : Array[String] = ["a", "b", "c"]
  let fixedArray = FixedArray::from_array(array)
  inspect(fixedArray.length(), content="3")
  for i in 0..<3 {
    assert_eq(fixedArray[i], array[i])
  }
}

///|
test "FixedArray::from_iter with multiple elements iterator" {
  let iter = [1, 2, 3, 4, 5].iter()
  let result = FixedArray::from_iter(iter)
  assert_eq(result, [1, 2, 3, 4, 5])
}

///|
test "FixedArray::from_iter with single element iterator" {
  let iter = [1].iter()
  let result = FixedArray::from_iter(iter)
  assert_eq(result, [1])
}

///|
test "FixedArray::from_iter with empty iterator" {
  let iter : Iter[Int] = Iter::empty()
  let result = FixedArray::from_iter(iter)
  assert_eq(result, [])
}

///|
test "FixedArray::last" {
  inspect(FixedArray::last([1, 2, 3]), content="Some(3)")
  inspect(
    FixedArray::last(["a", "b", "c"]),
    content=(
      #|Some("c")
    ),
  )
  inspect(FixedArray::last([1]), content="Some(1)")
  inspect(
    FixedArray::last(["single"]),
    content=(
      #|Some("single")
    ),
  )
}

///|
test "FixedArray::arbitrary" {
  let samples : Array[FixedArray[Int]] = @quickcheck.samples(15)
  inspect(
    samples[0:10],
    content="[[], [], [], [0], [0], [], [], [0], [0, 0], [0, 0, 0, 0, 2, 3, 1]]",
  )
  inspect(
    samples[10:15],
    content="[[0, 0, 1, 0, -2], [0, 0, 0, -1, -2], [0, 0, 0, 0, 0, -2, -5, 4, 0, 8], [0, 0, -1, 2], [0, 0]]",
  )
}

///|
test "FixedArray::makei" {
  let empty = FixedArray::makei(0, _i => Ref::{ val: 3 })
  inspect(empty.length(), content="0")
  let simple_arr = FixedArray::makei(1, _i => Ref::{ val: 2 })
  inspect(simple_arr.length(), content="1")
  inspect(simple_arr[0].val, content="2")
  let arr = FixedArray::makei(2, _i => Ref::{ val: 1 })
  inspect(arr.length(), content="2")
  @test.not_same_object(arr[0], arr[1])
  inspect(arr[0].val, content="1")
  inspect(arr[1].val, content="1")
}

///|
test "FixedArray compare" {
  let arr1 : FixedArray[Int] = [1, 2, 3]
  let arr2 : FixedArray[Int] = [1, 2, 4]
  let arr3 : FixedArray[Int] = [1, 2]
  inspect(arr1.compare(arr2), content="-1") // arr1 < arr2
  inspect(arr2.compare(arr1), content="1") // arr2 > arr1
  inspect(arr1.compare(arr3), content="1") // arr1 > arr3 (longer)
  inspect(arr1.compare(arr1), content="0") // arr1 = arr1

  // Test empty arrays
  let empty1 : FixedArray[Int] = []
  let empty2 : FixedArray[Int] = []
  inspect(empty1.compare(empty2), content="0")
  inspect(empty1.compare(arr1), content="-1")
  inspect(arr1.compare(empty1), content="1")
}

///|
test "panic FixedArray blit" {
  let a : FixedArray[Int] = [1, 2, 3, 4]
  let b : FixedArray[Int] = [1, 2, 3, 4]
  a.blit_to(b, len=13)
}

///|
test "copy" {
  let a : FixedArray[_] = [1, 2, 3, 4]
  let b = a.copy()
  inspect(b, content="[1, 2, 3, 4]")
  inspect(physical_equal(b, a), content="false")
  let c = FixedArray::make(8, 0)
  a.blit_to(c, len=4, dst_offset=3)
  inspect(c, content="[0, 0, 0, 1, 2, 3, 4, 0]")
  inspect(([] : FixedArray[Int]).copy(), content="[]")
  a.blit_to(a, len=2, src_offset=1)
  inspect(a, content="[2, 3, 3, 4]")
}
