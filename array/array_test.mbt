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
test "to_string" {
  let empty : Array[Int] = []
  inspect(empty, content="[]")
  let a0 = [0]
  inspect(a0, content="[0]")
  a0.push(1)
  inspect(a0, content="[0, 1]")
  a0.push(2)
  inspect(a0, content="[0, 1, 2]")
}

///|
test "push_iter" {
  let u = [1, 2, 3]
  let v = [4, 5, 6]
  u.push_iter(v.iter())
  inspect(u, content="[1, 2, 3, 4, 5, 6]")
}

///|
test "shuffle_in_place" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  fn rand(upper : Int) -> Int {
    let rng = @random.Rand::new()
    rng.int() % upper
  }

  let shuffled = Array::shuffle(arr, rand~)
  Array::shuffle_in_place(arr, rand~)
  assert_eq(shuffled, arr)
  inspect(arr, content="[3, 2, 1, 5, 6, 7, 4]")
}

///|
test "copy" {
  let arr = [1, 2, 3, 4, 5]
  let copied = arr.copy()
  assert_eq(copied, [1, 2, 3, 4, 5])
  @test.is_not(arr, copied)
  inspect(([] : Array[Int]).copy(), content="[]")
}

///|
test "Array::makei with positive length" {
  let arr = Array::makei(5, i => i * 2)
  assert_eq(arr, [0, 2, 4, 6, 8])
}

///|
test "Array::makei with zero length" {
  let arr = Array::makei(0, i => i * 2)
  assert_eq(arr, [])
}

///|
test "Array::makei with negative length" {
  let arr = Array::makei(-1, i => i * 2)
  assert_eq(arr, [])
}

///|
test "filter_map" {
  let arr = [1, 2, 3, 4, 5]
  let mapped = arr.filter_map(x => if x % 2 == 0 { Some(x) } else { None })
  inspect(mapped, content="[2, 4]")
}

///|
test "from_iter" {
  let arr : Array[Int] = []
  inspect(Array::from_iter(arr.iter()), content="[]")
  let arr = [1, 2, 3, 4, 5]
  inspect(Array::from_iter(arr.iter()), content="[1, 2, 3, 4, 5]")
}

///|
test "Array::last" {
  // Test with a random array of integers
  inspect([1, 2, 3, 4, 5].last(), content="Some(5)")

  // Test with a random array of strings
  inspect(["a", "b", "c"].last(), content="Some(\"c\")")

  // Test with a large array
  let large_array = Array::make(10, 0)
  inspect(large_array.last(), content="Some(0)")

  // Test with an empty array
  inspect(([] : Array[Unit]).last(), content="None")

  // Test with a single-element array
  inspect([1].last(), content="Some(1)")
}

///|
test "zip" {
  // Test with two non-empty arrays
  let arr1 = [1, 2, 3]
  let arr2 = ['a', 'b', 'c']
  inspect(arr1.zip(arr2), content="[(1, 'a'), (2, 'b'), (3, 'c')]")

  // Test with arrays of different lengths
  let arr3 = [1, 2]
  let arr4 = ["a", "b", "c"]
  inspect(
    arr3.zip(arr4),
    content=
      #|[(1, "a"), (2, "b")]
    ,
  )

  // Test with an empty array
  let arr5 : Array[Int] = []
  let arr6 = ["a", "b", "c"]
  inspect(arr5.zip(arr6), content="[]")
}

///|
test "unzip" {
  // Test with a non-empty array of tuples
  let arr = [(1, "a"), (2, "b"), (3, "c")]
  let (nums, strs) = arr.unzip()
  assert_eq(nums, [1, 2, 3])
  assert_eq(strs, ["a", "b", "c"])

  // Test with an empty array
  let empty : Array[(Int, String)] = []
  let (e1, e2) = empty.unzip()
  assert_eq(e1, [])
  assert_eq(e2, [])
}

///|
test "zip_with" {
  // Test with two non-empty arrays and a function
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  let add = (a, b) => a + b
  inspect(zip_with(arr1, arr2, add), content="[5, 7, 9]")

  // Test with arrays of different lengths and a function
  let arr3 = [1, 2]
  let arr4 = [4, 5, 6]
  inspect(zip_with(arr3, arr4, add), content="[5, 7]")

  // Test with an empty array and a function
  let arr5 : Array[Int] = []
  let arr6 = [4, 5, 6]
  inspect(zip_with(arr5, arr6, add), content="[]")
}

///|
test "zip_to_iter2" {
  // Test with two non-empty arrays
  let arr1 = [1, 2, 3]
  let arr2 = ['a', 'b', 'c']
  inspect(
    arr1.zip_to_iter2(arr2).to_array(),
    content="[(1, 'a'), (2, 'b'), (3, 'c')]",
  )

  // Test with arrays of different lengths
  let arr3 = [1, 2]
  let arr4 = ["a", "b", "c"]
  inspect(
    arr3.zip_to_iter2(arr4).to_array(),
    content=
      #|[(1, "a"), (2, "b")]
    ,
  )

  // Test with an empty array
  let arr5 : Array[Int] = []
  let arr6 = ["a", "b", "c"]
  inspect(arr5.zip_to_iter2(arr6), content="[]")
}

///|
test "zip_to_iter2 current behavior" {
  // Only for recording what can be done, but not what should be done
  let arr = [1, 2, 3]
  let arr2 = ['a', 'b', 'c']
  let iter = arr.zip_to_iter2(arr2)
  arr.push(4)
  arr2.push('d')
  inspect(iter.to_array(), content="[(1, 'a'), (2, 'b'), (3, 'c'), (4, 'd')]")
  arr.clear()
  inspect(iter.to_array(), content="[]")
}

///|
test "arbitrary" {
  let arr : Array[Array[Int]] = @quickcheck.samples(20)
  inspect(arr[5:9], content="[[], [], [0], [0, 0]]")
  inspect(
    arr[10:15],
    content="[[0, 0, 1, 0, -2], [0, 0, 0, -1, -2], [0, 0, 0, 0, 0, -2, -5, 4, 0, 8], [0, 0, -1, 2], [0, 0]]",
  )
}

///|
test "Array[String]::join" {
  let arr = ["a", "b", "c"]
  inspect(arr.join(","), content="a,b,c")
  inspect(["a", "b", "c"].join(","), content="a,b,c")
  inspect(["a", "b", "c"].join(""), content="abc")
  inspect(["a", "b", "c"].join(" "), content="a b c")
  inspect(["123", "456"].join(""), content="123456")
  inspect(["aaa", "bbb", "ccc"].join(" "), content="aaa bbb ccc")
  inspect([].join(" "))
}

///|
test "Array[View]::join" {
  let arr = ["a", "b", "c"][:]
  inspect(arr.join(","), content="a,b,c")
  inspect(["a", "b", "c"][:].join(","), content="a,b,c")
  inspect(["a", "b", "c"][:].join(""), content="abc")
  inspect(["a", "b", "c"][:].join(" "), content="a b c")
  inspect(["123", "456"][:].join(""), content="123456")
  inspect(["aaa", "bbb", "ccc"][:].join(" "), content="aaa bbb ccc")
  inspect([][:].join(" "))
}
