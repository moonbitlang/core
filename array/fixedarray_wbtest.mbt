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
  @test.eq(fixedArray.length(), 0)!
}

test "FixedArray::from_array with non-empty array" {
  let array : Array[Int] = [1, 2, 3, 4, 5]
  let fixedArray = FixedArray::from_array(array)
  @test.eq(fixedArray.length(), 5)!
  for i = 0; i < 5; i = i + 1 {
    @test.eq(fixedArray[i], array[i])!
  }
}

test "FixedArray::from_array with array of different type" {
  let array : Array[String] = ["a", "b", "c"]
  let fixedArray = FixedArray::from_array(array)
  @test.eq(fixedArray.length(), 3)!
  for i = 0; i < 3; i = i + 1 {
    @test.eq(fixedArray[i], array[i])!
  }
}
