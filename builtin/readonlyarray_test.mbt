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
test "ReadOnlyArray constructors" {
  // Test from_array - keep this test as it specifically tests from_array
  let arr1 = ReadOnlyArray::from_array([1, 2, 3])
  inspect(arr1[0], content="1")
  inspect(arr1[2], content="3")

  // Test from_iter
  let arr2 = ReadOnlyArray::from_iter([4, 5, 6].iter())
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

///|
test "ReadOnlyArray equal" {
  // Test equal arrays
  let arr1 : ReadOnlyArray[Int] = [1, 2, 3]
  let arr2 : ReadOnlyArray[Int] = [1, 2, 3]
  inspect(arr1 == arr2, content="true")

  // Test unequal arrays with different values
  let arr3 : ReadOnlyArray[Int] = [1, 3, 3]
  inspect(arr1 == arr3, content="false")

  // Test arrays of different lengths
  let arr4 : ReadOnlyArray[Int] = [1, 2]
  inspect(arr1 == arr4, content="false")

  // Test empty arrays
  let empty1 : ReadOnlyArray[Int] = []
  let empty2 : ReadOnlyArray[Int] = []
  inspect(empty1 == empty2, content="true")

  // Test empty vs non-empty
  inspect(empty1 == arr1, content="false")
}

///|
test "ReadOnlyArray compare" {
  let arr1 : ReadOnlyArray[Int] = [1, 2, 3]
  let arr2 : ReadOnlyArray[Int] = [1, 2, 4]
  let arr3 : ReadOnlyArray[Int] = [1, 2]

  // Test lexicographic comparison
  inspect(arr1.compare(arr2), content="-1") // arr1 < arr2
  inspect(arr2.compare(arr1), content="1") // arr2 > arr1

  // Test length comparison when prefixes are equal
  inspect(arr1.compare(arr3), content="1") // arr1 > arr3 (longer)
  inspect(arr3.compare(arr1), content="-1") // arr3 < arr1 (shorter)

  // Test equal arrays
  inspect(arr1.compare(arr1), content="0") // arr1 = arr1

  // Test empty arrays
  let empty1 : ReadOnlyArray[Int] = []
  let empty2 : ReadOnlyArray[Int] = []
  inspect(empty1.compare(empty2), content="0") // empty = empty
  inspect(empty1.compare(arr1), content="-1") // empty < non-empty
  inspect(arr1.compare(empty1), content="1") // non-empty > empty
}

///|
test "ReadOnlyArray iter and sub" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  inspect(arr.iter().to_array(), content="[1, 2, 3]")
  inspect(arr[1:], content="[2, 3]")
}

///|
test "ReadOnlyArray json and hash" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  @json.inspect(arr, content=[1, 2, 3])
  let hasher = Hasher::new(seed=0)
  hasher.combine(arr)
  inspect(hasher.finalize() != 0, content="true")
}
