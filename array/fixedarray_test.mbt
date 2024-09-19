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

test "FixedArray::from_array with empty array" {
  let array : Array[Int] = []
  let fixedArray = FixedArray::from_array(array)
  assert_eq!(fixedArray.length(), 0)
}

test "FixedArray::from_array with non-empty array" {
  let array : Array[Int] = [1, 2, 3, 4, 5]
  let fixedArray = FixedArray::from_array(array)
  assert_eq!(fixedArray.length(), 5)
  for i in 0..<5 {
    assert_eq!(fixedArray[i], array[i])
  }
}

test "FixedArray::from_array with array of different type" {
  let array : Array[String] = ["a", "b", "c"]
  let fixedArray = FixedArray::from_array(array)
  assert_eq!(fixedArray.length(), 3)
  for i in 0..<3 {
    assert_eq!(fixedArray[i], array[i])
  }
}

test "FixedArray::from_iter with multiple elements iterator" {
  let iter = [1, 2, 3, 4, 5].iter()
  let result = FixedArray::from_iter(iter)
  assert_eq!(result, [1, 2, 3, 4, 5])
}

test "FixedArray::from_iter with single element iterator" {
  let iter = [1].iter()
  let result = FixedArray::from_iter(iter)
  assert_eq!(result, [1])
}

test "FixedArray::from_iter with empty iterator" {
  let iter : Iter[Int] = Iter::empty()
  let result = FixedArray::from_iter(iter)
  assert_eq!(result, [])
}

test "FixedArray::last" {
  inspect!(FixedArray::last([1, 2, 3]), content="Some(3)")
  inspect!(
    FixedArray::last(["a", "b", "c"]),
    content=
      #|Some("c")
    ,
  )
  inspect!(FixedArray::last([1]), content="Some(1)")
  inspect!(
    FixedArray::last(["single"]),
    content=
      #|Some("single")
    ,
  )
}

test "FixedArray::arbitrary" {
  let samples : Array[FixedArray[Int]] = @quickcheck.samples(15)
  inspect!(
    samples[0:10],
    content="[[], [], [0], [0], [0], [0], [0], [0], [0, 0, 0], [0, 0, 0, 0, 3]]",
  )
  inspect!(
    samples[10:15],
    content="[[0, 0, 0, 1, 0, -1, 0, -1], [0, 0, 0, 1], [0, 0, 0, -1, -1, -1, 4], [0, 0], [0, 0, -1, 2]]",
  )
}
