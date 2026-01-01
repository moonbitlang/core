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
test "get with existing key" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  assert_eq(map.get(3), Some("three"))
}

///|
test "_[_] with existing key" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  assert_eq(map[3], "three")
}

///|
test "get with non-existing key" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  assert_eq(map.get(4), None)
}

///|
test "get with pattern" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  guard map
    is { 3: "three", 8: "eight", 1: "one", 2: "two", 0: "zero", 4? : None, .. }
}

///|
test "get after insertion" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let map = map.add(4, "four")
  assert_eq(map.get(4), Some("four"))
}

///|
test "_[_] after insertion" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let map = map.add(4, "four")
  assert_eq(map[4], "four")
}

///|
test "get after removal" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let map = map.remove(3)
  assert_eq(map.get(3), None)
}

///|
test "panic get with non-existing key" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  map[4] |> ignore
}

///|
test "panic get after removal" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let map = map.remove(3)
  map[3] |> ignore
}

///|
test "iter" {
  let map = [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
    |> @sorted_map.from_array
  let buf = StringBuilder::new()
  for k, v in map {
    buf.write_object(k)
    buf.write_string(": ")
    buf.write_object(v)
    buf.write_string("\n")
  }
  for kv in map {
    buf.write_object(kv)
    buf.write_string("\n")
  }
  inspect(
    buf,
    content=(
      #|0: "zero"
      #|1: "one"
      #|2: "two"
      #|3: "three"
      #|8: "eight"
      #|(0, "zero")
      #|(1, "one")
      #|(2, "two")
      #|(3, "three")
      #|(8, "eight")
      #|
    ),
  )
}

///|
test "get with empty map" {
  let map : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  assert_eq(map.get(3), None)
}

///|
test "panic get with empty map" {
  let map : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  map[3] |> ignore
}

///|
test "to_json with non-empty map" {
  let map = [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
    |> @sorted_map.from_array
  @json.inspect(map.to_json(), content={
    "0": "zero",
    "1": "one",
    "2": "two",
    "3": "three",
    "8": "eight",
  })
}

///|
test "to_json with empty map" {
  let map : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  @json.inspect(map.to_json(), content={})
}

///|
test "from_json" {
  for
    xs in (@quickcheck.samples(20) : Array[@sorted_map.SortedMap[String, Int]]) {
    assert_eq(xs, @json.from_json(xs.to_json()))
  }
}

///|
test "range on empty map" {
  let empty : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  let mut count = 0
  for _, _ in empty.range(1, 5) {
    count = count + 1
  }
  inspect(count, content="0")
}

///|
test "range with no matches" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c")])
  let mut count = 0
  for _, _ in map.range(10, 20) {
    count = count + 1
  }
  inspect(count, content="0")
}

///|
test "range matching all elements" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c")])
  let buf = StringBuilder::new()
  for k, v in map.range(0, 10) {
    buf.write_string("[\{k},\{v}]")
  }
  inspect(buf, content="[1,a][2,b][3,c]")
}

///|
test "range partial match" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  let buf = StringBuilder::new()
  for k, v in map.range(2, 4) {
    buf.write_string("[\{k},\{v}]")
  }
  inspect(buf, content="[2,b][3,c][4,d]")
}

///|
test "range with single element" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  let buf = StringBuilder::new()
  for k, v in map.range(3, 3) {
    buf.write_string("[\{k},\{v}]")
  }
  inspect(buf, content="[3,c]")
}

///|
test "range at left boundary" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  let buf = StringBuilder::new()
  for k, v in map.range(1, 2) {
    buf.write_string("[\{k},\{v}]")
  }
  inspect(buf, content="[1,a][2,b]")
}

///|
test "range at right boundary" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  let buf = StringBuilder::new()
  for k, v in map.range(4, 5) {
    buf.write_string("[\{k},\{v}]")
  }
  inspect(buf, content="[4,d][5,e]")
}

///|
test "range with gaps in data" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (3, "c"),
    (5, "e"),
    (7, "g"),
    (9, "i"),
  ])
  let buf = StringBuilder::new()
  for k, v in map.range(2, 8) {
    buf.write_string("[\{k},\{v}]")
  }
  inspect(buf, content="[3,c][5,e][7,g]")
}

///|
test "range with inverted bounds" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  let mut count = 0
  for _, _ in map.range(5, 2) {
    count = count + 1
  }
  inspect(count, content="0")
}

///|
test "range with early termination" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  let mut count = 0
  for _, _ in map.range(1, 5) {
    count = count + 1
    if count == 2 {
      break
    }
  }
  inspect(count, content="2")
}

///|
test "range on large dataset" {
  let arr = Array::makei(100, fn(i) { (i, "val\{i}") })
  let map = @sorted_map.from_array(arr[:])
  let mut count = 0
  for _, _ in map.range(25, 75) {
    count = count + 1
  }
  inspect(count, content="51")
}

///|
test "range with non-existent boundaries" {
  let map = @sorted_map.from_array([(2, "b"), (4, "d"), (6, "f"), (8, "h")])
  let buf = StringBuilder::new()
  for k, v in map.range(3, 7) {
    buf.write_string("[\{k},\{v}]")
  }
  inspect(buf, content="[4,d][6,f]")
}
