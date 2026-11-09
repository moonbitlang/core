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
test "empty constructor" {
  let m : Set[Int32] = Set([])
  @test.assert_eq(m.capacity, default_init_capacity)
  @test.assert_eq(m.length(), 0)
}

///|
test "constructor capacity" {
  // `capacity` counts elements: 16 elements need 32 buckets at a 13/16 load.
  let empty : Set[Int32] = Set([], capacity=16)
  @test.assert_eq(empty.capacity, 32)
  @test.assert_eq(empty.length(), 0)
  let below_length = Set([1, 2, 3], capacity=2)
  @test.assert_eq(below_length.capacity, 4)
  @test.assert_eq(below_length.length(), 3)
  let above_length = Set([1, 2, 3], capacity=16)
  @test.assert_eq(above_length.capacity, 32)
  @debug.debug_inspect(above_length.to_array(), content="[1, 2, 3]")
}

///|
test "insert_and_grow" {
  let m = Set([])
  for i in 0..<10 {
    m.add(i.to_string())
  }
  @test.assert_eq(m.length(), 10)
  @test.assert_eq(m.capacity, 16)
  @json.json_inspect(m, content=[
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  ])
}

///|
test "capacity_and_size" {
  let m = Set([])
  @test.assert_eq(m.capacity, default_init_capacity)
  @test.assert_eq(m.length(), 0)
  m.add("a")
  @test.assert_eq(m.length(), 1)
}

///|
test "filter sizes the result for the kept elements" {
  let s : Set[Int32] = Set([ for i in 0..<10000 => i ])
  for keep in [0, 1, 10, 5000, 10000] {
    let kept = s.filter(k => k < keep)
    let rebuilt = Set([ for k in s if k < keep => k ])
    @test.assert_eq(kept.length(), keep)
    @test.assert_eq(kept.capacity, rebuilt.capacity)
  }
}

///|
test "from_json keeps array order and drops repeated elements" {
  let set : Set[String] = @json.from_json(["b", "a", "b", "c", "a"])
  @test.assert_eq(set.to_array(), ["b", "a", "c"])
  let empty : Set[Int32] = @json.from_json([])
  @test.assert_eq(empty.length(), 0)
  @test.assert_eq(empty.capacity, (Set([]) : Set[Int32]).capacity)
  let nested : Set[Array[Int32]] = @json.from_json([[1, 2], [], [1, 2]])
  @test.assert_eq(nested.to_array(), [[1, 2], []])
}

///|
test "from_json sizes the set like the constructor" {
  for n in [1, 2, 13, 100, 1000] {
    let set : Set[Int32] = @json.from_json([ for i in 0..<n => @json.Json(i) ])
    @test.assert_eq(set.capacity, Set([ for i in 0..<n => i ]).capacity)
  }
}

///|
test "union_in_place with itself is a no-op" {
  // Six elements fill a capacity-8 set exactly to its grow threshold, so one
  // more insertion attempt would grow it: without the self check, absorbing
  // itself would resize the set while walking its own list.
  let s = Set([ for i in 0..<6 => i ])
  let capacity = s.capacity
  s.union_in_place(s)
  @test.assert_eq(s.to_array(), [0, 1, 2, 3, 4, 5])
  @test.assert_eq(s.capacity, capacity)
}
