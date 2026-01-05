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
test "default" {
  let map : @sorted_map.SortedMap[Int, Int] = Default::default()
  inspect(map.length(), content="0")
}

///|
test "iter2" {
  let map = @sorted_map.from_array([(2, "two"), (1, "one")])
  inspect(map.iter2().to_array(), content="[(1, \"one\"), (2, \"two\")]")
}

///|
test "rev_keys returns keys in descending order" {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let keys = map.rev_keys().collect()
  inspect(keys, content="[\"c\", \"b\", \"a\"]")
}

///|
test "rev_values returns values in descending key order" {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let values = map.rev_values().collect()
  inspect(values, content="[3, 2, 1]")
}

///|
test "rev_keys on empty map" {
  let map : @sorted_map.SortedMap[String, Int] = @sorted_map.new()
  inspect(map.rev_keys().collect(), content="[]")
}

///|
test "rev_values on empty map" {
  let map : @sorted_map.SortedMap[String, Int] = @sorted_map.new()
  inspect(map.rev_values().collect(), content="[]")
}

///|
test "rev_keys on single element map" {
  let map = @sorted_map.singleton("a", 1)
  let keys = map.rev_keys().collect()
  inspect(keys, content="[\"a\"]")
}

///|
test "rev_values on single element map" {
  let map = @sorted_map.singleton("a", 1)
  let values = map.rev_values().collect()
  inspect(values, content="[1]")
}

///|
test "rev_keys early termination" {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  let result = map.rev_keys().take(2).collect()
  inspect(result, content="[3, 2]")
}

///|
test "rev_values early termination" {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  let result = map.rev_values().take(2).collect()
  inspect(result, content="[\"three\", \"two\"]")
}

///|
test "rev_keys is reverse of keys" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let forward = map.keys_as_iter().collect()
  let reverse = map.rev_keys().collect()
  assert_eq(reverse, forward.rev())
}

///|
test "rev_keys is reverse of keys (quickcheck)" {
  for xs in (@quickcheck.samples(50) : Array[@sorted_map.SortedMap[Int, Int]]) {
    let forward = xs.keys_as_iter().collect()
    let reverse = xs.rev_keys().collect()
    assert_eq(reverse, forward.rev())
  }
}

///|
test "rev_values is reverse of values" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let forward = map.values().collect()
  let reverse = map.rev_values().collect()
  assert_eq(reverse, forward.rev())
}

///|
test "rev_keys with complex tree" {
  let map = @sorted_map.from_array([
    (15, "15"),
    (10, "10"),
    (20, "20"),
    (5, "5"),
    (12, "12"),
    (18, "18"),
    (25, "25"),
  ])
  let keys = map.rev_keys().collect()
  inspect(keys, content="[25, 20, 18, 15, 12, 10, 5]")
}

///|
test "rev_values with complex tree" {
  let map = @sorted_map.from_array([
    (15, "15"),
    (10, "10"),
    (20, "20"),
    (5, "5"),
    (12, "12"),
    (18, "18"),
    (25, "25"),
  ])
  let values = map.rev_values().collect()
  inspect(
    values,
    content="[\"25\", \"20\", \"18\", \"15\", \"12\", \"10\", \"5\"]",
  )
}

///|
test "from_json free function" {
  let json : Json = { "a": 1, "b": 2 }
  let map : @sorted_map.SortedMap[String, Int] = @sorted_map.from_json(json)
  @json.inspect(map.to_json(), content={ "a": 1, "b": 2 })
}

///|
test "from_json rejects non-object" {
  let bad_json : Json = [1, 2, 3]
  let result : Result[@sorted_map.SortedMap[String, Int], @json.JsonDecodeError] = try? @sorted_map.from_json(
    bad_json,
  )
  inspect(result is Err(_), content="true")
}
