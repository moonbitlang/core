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
test "basic case with common suffix" {
  let old : ReadOnlyArray[Char] = ['1', '2', '3', '4', '5']
  let new : ReadOnlyArray[Char] = ['3', '4', '5', '6', '7']
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0], [3, 1], [4, 2]])
}

///|
test "reordered elements" {
  let old : ReadOnlyArray[Char] = ['1', '2', '3']
  let new : ReadOnlyArray[Char] = ['3', '2', '1']
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0]])
}

///|
test "string array reordering" {
  let old : ReadOnlyArray[String] = ["foo", "bar", "baz", "qux"]
  let new : ReadOnlyArray[String] = ["baz", "qux", "foo", "bar"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0], [3, 1]])
}

///|
test "partial reordering with common elements" {
  let old : ReadOnlyArray[String] = ["apple", "banana", "cherry", "date"]
  let new : ReadOnlyArray[String] = ["apple", "cherry", "banana", "date"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [2, 1], [3, 3]])
}

///|
test "empty sequences" {
  let old : ReadOnlyArray[String] = []
  let new : ReadOnlyArray[String] = []
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "one empty sequence" {
  let old : ReadOnlyArray[String] = ["a", "b", "c"]
  let new : ReadOnlyArray[String] = []
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "other empty sequence" {
  let old : ReadOnlyArray[String] = []
  let new : ReadOnlyArray[String] = ["x", "y", "z"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "identical sequences" {
  let old : ReadOnlyArray[String] = ["a", "b", "c", "d"]
  let new : ReadOnlyArray[String] = ["a", "b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[
    [0, 0],
    [1, 1],
    [2, 2],
    [3, 3],
  ])
}

///|
test "completely different sequences" {
  let old : ReadOnlyArray[String] = ["a", "b", "c"]
  let new : ReadOnlyArray[String] = ["x", "y", "z"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "single element match" {
  let old : ReadOnlyArray[String] = ["a", "b", "c"]
  let new : ReadOnlyArray[String] = ["x", "b", "y"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 1]])
}

///|
test "duplicate elements in old sequence" {
  let old : ReadOnlyArray[String] = ["a", "b", "a", "c"]
  let new : ReadOnlyArray[String] = ["x", "a", "y", "c"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[3, 3]])
}

///|
test "duplicate elements in new sequence" {
  let old : ReadOnlyArray[String] = ["a", "b", "c"]
  let new : ReadOnlyArray[String] = ["x", "b", "b", "y"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "duplicate elements in both sequences" {
  let old : ReadOnlyArray[String] = ["a", "b", "b", "c"]
  let new : ReadOnlyArray[String] = ["x", "b", "b", "y"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "long common subsequence" {
  let old : ReadOnlyArray[String] = [
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
  ]
  let new : ReadOnlyArray[String] = ["0", "2", "4", "6", "8", "10", "11"]
  @json.json_inspect(unique_lcs(old~, new~), content=[
    [1, 1],
    [3, 2],
    [5, 3],
    [7, 4],
    [9, 5],
  ])
}

///|
test "reverse order" {
  let old : ReadOnlyArray[String] = ["a", "b", "c", "d"]
  let new : ReadOnlyArray[String] = ["d", "c", "b", "a"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[3, 0]])
}

///|
test "single character sequences" {
  let old : ReadOnlyArray[String] = ["a"]
  let new : ReadOnlyArray[String] = ["a"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0]])
}

///|
test "single character no match" {
  let old : ReadOnlyArray[String] = ["a"]
  let new : ReadOnlyArray[String] = ["b"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "prefix and suffix overlap" {
  let old : ReadOnlyArray[String] = ["start", "middle1", "middle2", "end"]
  let new : ReadOnlyArray[String] = ["start", "new1", "new2", "end"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [3, 3]])
}

///|
test "interleaved unique elements" {
  let old : ReadOnlyArray[String] = ["a1", "b1", "a2", "b2", "a3"]
  let new : ReadOnlyArray[String] = ["b1", "a1", "b2", "a2", "a3"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 0], [3, 2], [4, 4]])
}

///|
test "numeric sequences" {
  let old : ReadOnlyArray[Int] = [1, 3, 5, 7, 9]
  let new : ReadOnlyArray[Int] = [2, 3, 4, 7, 8, 9]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 1], [3, 3], [4, 5]])
}

///|
test "mixed types - booleans" {
  let old : ReadOnlyArray[Bool] = [true, false, true, false]
  let new : ReadOnlyArray[Bool] = [false, true, false, true]
  // TODO: check this
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "large gap in middle" {
  let old : ReadOnlyArray[String] = [
    "start", "gap1", "gap2", "gap3", "gap4", "end",
  ]
  let new : ReadOnlyArray[String] = ["start", "different", "end"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [5, 2]])
}

///|
test "insertion at beginning" {
  let old : ReadOnlyArray[String] = ["b", "c", "d"]
  let new : ReadOnlyArray[String] = ["a", "b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 1], [1, 2], [2, 3]])
}

///|
test "insertion at end" {
  let old : ReadOnlyArray[String] = ["a", "b", "c"]
  let new : ReadOnlyArray[String] = ["a", "b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [1, 1], [2, 2]])
}

///|
test "deletion from beginning" {
  let old : ReadOnlyArray[String] = ["a", "b", "c", "d"]
  let new : ReadOnlyArray[String] = ["b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 0], [2, 1], [3, 2]])
}

///|
test "deletion from end" {
  let old : ReadOnlyArray[String] = ["a", "b", "c", "d"]
  let new : ReadOnlyArray[String] = ["a", "b", "c"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [1, 1], [2, 2]])
}

///|
test "complex pattern with multiple unique matches" {
  let old : ReadOnlyArray[String] = [
    "alpha", "beta", "gamma", "delta", "epsilon", "zeta",
  ]
  let new : ReadOnlyArray[String] = [
    "gamma", "alpha", "theta", "epsilon", "beta", "eta",
  ]
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0], [4, 3]])
}
