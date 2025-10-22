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
test "FixedArray::from_iterator with multiple elements iterator" {
  let iter = [1, 2, 3, 4, 5].iterator()
  let result = FixedArray::from_iterator(iter)
  assert_eq(result, [1, 2, 3, 4, 5])
}

///|
test "FixedArray::from_iterator with single element iterator" {
  let iter = [1].iterator()
  let result = FixedArray::from_iterator(iter)
  assert_eq(result, [1])
}

///|
test "FixedArray::from_iterator with empty iterator" {
  let iter : Iterator[Int] = Iterator::empty()
  let result = FixedArray::from_iterator(iter)
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
