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
test "remove2" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b")])
  inspect(map.length(), content="2")
  map.remove(1)
  inspect(map.length(), content="1")
}

///|
test "remove3" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c")])
  map.remove(0)
  inspect(map.length(), content="3")
  map.remove(4)
  inspect(map.length(), content="3")
}

///|
test "remove on empty map" {
  let map : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  map.remove(1)
  inspect(map.length(), content="0")
}

///|
test "get" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.get(1),
    content=(
      #|Some("a")
    ),
  )
  inspect(
    map.get(2),
    content=(
      #|Some("b")
    ),
  )
  inspect(
    map.get(3),
    content=(
      #|Some("c")
    ),
  )
  inspect(map.get(4), content="None")

  // pattern
  guard map is { 1: "a", 2: "b", 3: "c", 4? : None, .. }
}

///|
test "contains" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.contains(1), content="true")
  inspect(map.contains(2), content="true")
  inspect(map.contains(3), content="true")
  inspect(map.contains(4), content="false")
}

///|
test "at" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map[1], content="a")
  inspect(map[2], content="b")
  inspect(map[3], content="c")
}

///|
test "panic at" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  map[4] |> ignore
}

///|
test "equal" {
  let a = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let b = @sorted_map.from_array([(4, "d"), (5, "e"), (6, "f")])
  inspect(a == a, content="true")
  inspect(b == b, content="true")
  inspect(a == b, content="false")
  inspect(b == a, content="false")
}

///|
test "is_empty" {
  let map : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  inspect(map.is_empty(), content="true")
  map[1] = "a"
  inspect(map.is_empty(), content="false")
}

///|
test "size" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.length() == map.length(), content="true")
}

///|
test "each" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  map.each((k, v) => buf.write_string("\{k}\{v}"))
  inspect(buf.to_string(), content="1a2b3c")
}

///|
test "eachi" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  map.eachi((i, k, v) => buf.write_string("[\{i}]\{k}\{v}"))
  inspect(buf.to_string(), content="[0]1a[1]2b[2]3c")
}

///|
test "keys" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.keys_as_iter(), content="[1, 2, 3]")
}

///|
test "values" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.values_as_iter(),
    content=(
      #|["a", "b", "c"]
    ),
  )
}

///|
test "to_array" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.to_array(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
}

///|
test "iter_collect" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.iter().collect(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
  inspect(
    map.iter().take(2).collect(),
    content=(
      #|[(1, "a"), (2, "b")]
    ),
  )
}

///|
test "from_iter multiple elements iter" {
  inspect(
    @sorted_map.from_iter([(1, 1), (2, 2), (3, 3)].iter()),
    content="@sorted_map.from_array([(1, 1), (2, 2), (3, 3)])",
  )
}

///|
test "from_iter single element iter" {
  inspect(
    @sorted_map.from_iter([(1, 1)].iter()),
    content="@sorted_map.from_array([(1, 1)])",
  )
}

///|
test "from_iter empty iter" {
  let pq : @sorted_map.SortedMap[Int, Int] = @sorted_map.from_iter(
    Iter::empty(),
  )
  inspect(pq, content="@sorted_map.from_array([])")
}

///|
test "arbitrary" {
  let map : Array[@sorted_map.SortedMap[Int, UInt]] = @quickcheck.samples(20)
  inspect(
    map[5:10],
    content="[@sorted_map.from_array([]), @sorted_map.from_array([]), @sorted_map.from_array([(0, 0)]), @sorted_map.from_array([(0, 0)]), @sorted_map.from_array([(0, 0)])]",
  )
  inspect(
    map[11:15],
    content="[@sorted_map.from_array([(-3, 2), (-1, 1), (0, 0), (2, 1)]), @sorted_map.from_array([(0, 0)]), @sorted_map.from_array([(-8, 1), (-2, 5), (0, 3), (3, 6), (7, 6)]), @sorted_map.from_array([(0, 0)])]",
  )
}

///|
test "iter2" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  for k, v in map {
    buf.write_string("[\{k}\{v}]")
  }
  inspect(buf, content="[1a][2b][3c]")
}

///|
test "range" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  inspect(
    map.range(2, 4),
    content=(
      #|[(2, "b"), (3, "c"), (4, "d")]
    ),
  )
  inspect(
    map.range(1, 1),
    content=(
      #|[(1, "a")]
    ),
  )
  inspect(
    map.range(5, 5),
    content=(
      #|[(5, "e")]
    ),
  )
}

///|
test "to_json with non-empty map" {
  let map = @sorted_map.from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
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
test "default" {
  let map : @sorted_map.SortedMap[Int, Int] = Default::default()
  inspect(map.length(), content="0")
}

///|
test "from_json" {
  for
    xs in (@quickcheck.samples(20) : Array[@sorted_map.SortedMap[String, Int]]) {
    assert_eq(xs, @json.from_json(xs.to_json()))
  }
}

///|
test "from_json rejects non-object" {
  let bad_json : Json = 1
  let result : Result[@sorted_map.SortedMap[String, Int], @json.JsonDecodeError] = try? @json.from_json(
    bad_json,
  )
  inspect(result is Err(_), content="true")
}

///|
test "json roundtrip verification" {
  let original : Json = { "key1": 42, "key2": 100, "key3": -5 }
  let restored : @sorted_map.SortedMap[String, Int] = @json.from_json(original)
  @json.inspect(restored, content={ "key1": 42, "key2": 100, "key3": -5 })
}

///|
test "@sorted_map.merge" {
  let map1 = @sorted_map.from_array([(1, "a"), (2, "b")])
  let map2 = @sorted_map.from_array([(2, "c"), (3, "d")])
  let merged = map1.merge(map2)
  inspect(merged.get(1), content="Some(\"a\")")
  inspect(merged.get(2), content="Some(\"c\")")
  inspect(merged.get(3), content="Some(\"d\")")
  inspect(merged.length(), content="3")
  // Verify original maps are unchanged
  inspect(map1.get(2), content="Some(\"b\")")
  inspect(map1.length(), content="2")
}

///|
test "@sorted_map.merge empty maps" {
  let map1 : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  let map2 = @sorted_map.from_array([(1, "a"), (2, "b")])
  let merged1 = map1.merge(map2)
  inspect(merged1.to_array(), content="[(1, \"a\"), (2, \"b\")]")
  let merged2 = map2.merge(map1)
  inspect(merged2.to_array(), content="[(1, \"a\"), (2, \"b\")]")
  let merged3 = map1.merge(map1)
  inspect(merged3.length(), content="0")
}

///|
test "@sorted_map.merge_in_place" {
  let map1 = @sorted_map.from_array([(1, "a"), (2, "b")])
  let map2 = @sorted_map.from_array([(2, "c"), (3, "d")])
  map1.merge_in_place(map2)
  inspect(map1.get(1), content="Some(\"a\")")
  inspect(map1.get(2), content="Some(\"c\")")
  inspect(map1.get(3), content="Some(\"d\")")
  inspect(map1.length(), content="3")
  // Verify second map is unchanged
  inspect(map2.length(), content="2")
}

///|
test "@sorted_map.merge_in_place empty maps" {
  let map1 : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  let map2 = @sorted_map.from_array([(1, "a"), (2, "b")])
  map1.merge_in_place(map2)
  inspect(map1.to_array(), content="[(1, \"a\"), (2, \"b\")]")
  map1.merge_in_place(map1)
  inspect(map1.to_array(), content="[(1, \"a\"), (2, \"b\")]")
}
