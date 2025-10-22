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
test "ReadOnlyArray constructors" {
  // Test from_array - keep this test as it specifically tests from_array
  let arr1 = ReadOnlyArray::from_array([1, 2, 3])
  inspect(arr1[0], content="1")
  inspect(arr1[2], content="3")

  // Test from_iter
  let arr2 = ReadOnlyArray::from_iter([4, 5, 6].iter())
  inspect(arr2[1], content="5")

  // Test from_iterator
  let arr2 = ReadOnlyArray::from_iterator([4, 5, 6].iterator())
  inspect(arr2[1], content="5")

  // Test makei
  let arr3 = ReadOnlyArray::makei(3, fn(i) { i * 10 })
  inspect(arr3[0], content="0")
  inspect(arr3[2], content="20")
}

///|
test "ReadOnlyArray access methods" {
  let arr : ReadOnlyArray[Int] = [10, 20, 30]

  // Test get
  inspect(arr.get(1), content="Some(20)")
  inspect(arr.get(5), content="None")

  // Test length
  inspect(arr.length(), content="3")

  // Test is_empty
  inspect(arr.is_empty(), content="false")
  let empty : ReadOnlyArray[Int] = []
  inspect(empty.is_empty(), content="true")

  // Test last
  inspect(arr.last(), content="Some(30)")
  inspect(empty.last(), content="None")
}

///|
test "ReadOnlyArray functional methods" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]

  // Test map
  let doubled = arr.map(fn(x) { x * 2 })
  inspect(doubled[0], content="2")
  inspect(doubled[2], content="6")

  // Test fold
  let sum = arr.fold(init=0, fn(acc, x) { acc + x })
  inspect(sum, content="6")

  // Test rev
  let reversed = arr.rev()
  inspect(reversed[0], content="3")
  inspect(reversed[2], content="1")
}

///|
test "ReadOnlyArray search methods" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3, 2, 4]

  // Test search
  inspect(arr.search(2), content="Some(1)")
  inspect(arr.search(5), content="None")

  // Test contains
  inspect(arr.contains(3), content="true")
  inspect(arr.contains(5), content="false")

  // Test all/any
  let even_arr : ReadOnlyArray[Int] = [2, 4, 6]
  inspect(even_arr.all(fn(x) { x % 2 == 0 }), content="true")
  inspect(arr.any(fn(x) { x % 2 == 0 }), content="true")
}

///|
test "ReadOnlyArray trait implementations" {
  // Test Default
  let empty : ReadOnlyArray[Int] = ReadOnlyArray::default()
  inspect(empty.length(), content="0")

  // Test Show
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  inspect(arr.to_string(), content="[1, 2, 3]")

  // Test join for strings
  let str_arr : ReadOnlyArray[String] = ["a", "b", "c"]
  inspect(str_arr.join(","), content="a,b,c")
}
