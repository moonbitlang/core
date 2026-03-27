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
  let old = ['1', '2', '3', '4', '5']
  let new = ['3', '4', '5', '6', '7']
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0], [3, 1], [4, 2]])
}

///|
test "reordered elements" {
  let old = ['1', '2', '3']
  let new = ['3', '2', '1']
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0]])
}

///|
test "string array reordering" {
  let old = ["foo", "bar", "baz", "qux"]
  let new = ["baz", "qux", "foo", "bar"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0], [3, 1]])
}

///|
test "partial reordering with common elements" {
  let old = ["apple", "banana", "cherry", "date"]
  let new = ["apple", "cherry", "banana", "date"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [2, 1], [3, 3]])
}

///|
test "empty sequences" {
  let old : Array[String] = []
  let new : Array[String] = []
  @json.json_inspect(unique_lcs(old=old[:], new=new[:]), content=[])
}

///|
test "one empty sequence" {
  let old = ["a", "b", "c"]
  let new : Array[String] = []
  @json.json_inspect(unique_lcs(old=old[:], new=new[:]), content=[])
}

///|
test "other empty sequence" {
  let old : Array[String] = []
  let new = ["x", "y", "z"]
  @json.json_inspect(unique_lcs(old=old[:], new=new[:]), content=[])
}

///|
test "identical sequences" {
  let old = ["a", "b", "c", "d"]
  let new = ["a", "b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[
    [0, 0],
    [1, 1],
    [2, 2],
    [3, 3],
  ])
}

///|
test "completely different sequences" {
  let old = ["a", "b", "c"]
  let new = ["x", "y", "z"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "single element match" {
  let old = ["a", "b", "c"]
  let new = ["x", "b", "y"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 1]])
}

///|
test "duplicate elements in old sequence" {
  let old = ["a", "b", "a", "c"]
  let new = ["x", "a", "y", "c"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[3, 3]])
}

///|
test "duplicate elements in new sequence" {
  let old = ["a", "b", "c"]
  let new = ["x", "b", "b", "y"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "duplicate elements in both sequences" {
  let old = ["a", "b", "b", "c"]
  let new = ["x", "b", "b", "y"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "long common subsequence" {
  let old = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
  let new = ["0", "2", "4", "6", "8", "10", "11"]
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
  let old = ["a", "b", "c", "d"]
  let new = ["d", "c", "b", "a"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[3, 0]])
}

///|
test "single character sequences" {
  let old = ["a"]
  let new = ["a"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0]])
}

///|
test "single character no match" {
  let old = ["a"]
  let new = ["b"]
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "prefix and suffix overlap" {
  let old = ["start", "middle1", "middle2", "end"]
  let new = ["start", "new1", "new2", "end"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [3, 3]])
}

///|
test "interleaved unique elements" {
  let old = ["a1", "b1", "a2", "b2", "a3"]
  let new = ["b1", "a1", "b2", "a2", "a3"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 0], [3, 2], [4, 4]])
}

///|
test "numeric sequences" {
  let old = [1, 3, 5, 7, 9]
  let new = [2, 3, 4, 7, 8, 9]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 1], [3, 3], [4, 5]])
}

///|
test "mixed types - booleans" {
  let old = [true, false, true, false]
  let new = [false, true, false, true]
  // TODO: check this
  @json.json_inspect(unique_lcs(old~, new~), content=[])
}

///|
test "large gap in middle" {
  let old = ["start", "gap1", "gap2", "gap3", "gap4", "end"]
  let new = ["start", "different", "end"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [5, 2]])
}

///|
test "insertion at beginning" {
  let old = ["b", "c", "d"]
  let new = ["a", "b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 1], [1, 2], [2, 3]])
}

///|
test "insertion at end" {
  let old = ["a", "b", "c"]
  let new = ["a", "b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [1, 1], [2, 2]])
}

///|
test "deletion from beginning" {
  let old = ["a", "b", "c", "d"]
  let new = ["b", "c", "d"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[1, 0], [2, 1], [3, 2]])
}

///|
test "deletion from end" {
  let old = ["a", "b", "c", "d"]
  let new = ["a", "b", "c"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[0, 0], [1, 1], [2, 2]])
}

///|
test "complex pattern with multiple unique matches" {
  let old = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta"]
  let new = ["gamma", "alpha", "theta", "epsilon", "beta", "eta"]
  @json.json_inspect(unique_lcs(old~, new~), content=[[2, 0], [4, 3]])
}
