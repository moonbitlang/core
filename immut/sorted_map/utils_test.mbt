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

test "op_get with existing key" {
  let map = Map::of([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  @test.eq(map[3], Some("three"))!
}

test "op_get with non-existing key" {
  let map = Map::of([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  @test.eq(map[4], None)!
}

test "op_get after insertion" {
  let map = Map::of([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let map = map.insert(4, "four")
  @test.eq(map[4], Some("four"))!
}

test "op_get after removal" {
  let map = Map::of([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let map = map.remove(3)
  @test.eq(map[3], None)!
}

test "op_get with empty map" {
  let map : Map[Int, String] = empty()
  @test.eq(map[3], None)!
}
