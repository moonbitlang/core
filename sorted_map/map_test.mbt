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
  let map : @sorted_map.SortedMap[Int, String] = SortedMap([])
  map.remove(1)
  inspect(map.length(), content="0")
}

///|
test "SortedMap constructor" {
  let map = @sorted_map.SortedMap([(3, "c"), (2, "b"), (1, "a")])
  assert_eq(map.length(), 3)
  debug_inspect(map.get(1), content="Some(\"a\")")
}

///|
test "get" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  debug_inspect(map.get(1), content="Some(\"a\")")
  debug_inspect(map.get(2), content="Some(\"b\")")
  debug_inspect(
    map.get(3),
    content=(
      #|Some("c")
    ),
  )
  debug_inspect(map.get(4), content="None")

  // pattern
  guard! map is { 1: "a", 2: "b", 3: "c", 4? : None, .. }
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
  let map : @sorted_map.SortedMap[Int, String] = SortedMap([])
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
  let buf = StringBuilder()
  map.each((k, v) => buf <+ "\{k}\{v}")
  inspect(buf.to_string(), content="1a2b3c")
}

///|
test "eachi" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder()
  map.eachi((i, k, v) => buf <+ "[\{i}]\{k}\{v}")
  inspect(buf.to_string(), content="[0]1a[1]2b[2]3c")
}

///|
test "keys" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  debug_inspect(
    map.keys().to_array(),
    content=(
      #|[1, 2, 3]
    ),
  )
}

///|
test "values" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  debug_inspect(
    [..map.values()],
    content=(
      #|["a", "b", "c"]
    ),
  )
}

///|
test "to_array" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  debug_inspect(
    map.to_array(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
}

///|
test "iter_collect" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  debug_inspect(
    map.iter().collect(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
  debug_inspect(
    map.iter().take(2).collect(),
    content=(
      #|[(1, "a"), (2, "b")]
    ),
  )
}

///|
test "from_iter multiple elements iter" {
  debug_inspect(
    @sorted_map.from_iter([|(1, 1), (2, 2), (3, 3)|]),
    content=(
      #|<SortedMap: { 1: 1, 2: 2, 3: 3 }>
    ),
  )
}

///|
test "from_iter single element iter" {
  debug_inspect(
    @sorted_map.from_iter([|(1, 1)|]),
    content=(
      #|<SortedMap: { 1: 1 }>
    ),
  )
}

///|
test "from_iter empty iter" {
  let pq : @sorted_map.SortedMap[Int, Int] = @sorted_map.from_iter([||])
  debug_inspect(
    pq,
    content=(
      #|<SortedMap: {}>
    ),
  )
}

///|
test "iter2" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder()
  for k, v in map {
    buf <+ "[\{k}\{v}]"
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
  debug_inspect(
    map.range(2, 4).to_array(),
    content=(
      #|[(2, "b"), (3, "c"), (4, "d")]
    ),
  )
  debug_inspect(
    map.range(1, 1).to_array(),
    content=(
      #|[(1, "a")]
    ),
  )
  debug_inspect(
    map.range(5, 5).to_array(),
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
  @json.json_inspect(@json.to_json(map), content={
    "0": "zero",
    "1": "one",
    "2": "two",
    "3": "three",
    "8": "eight",
  })
}

///|
test "to_json with empty map" {
  let map : @sorted_map.SortedMap[Int, String] = SortedMap([])
  @json.json_inspect(@json.to_json(map), content=Json::empty_object())
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
    @debug.assert_eq(xs, @json.from_json(@json.to_json(xs)))
  }
}

///|
test "from_json rejects non-object" {
  let bad_json : Json = 1
  try (@json.from_json(bad_json) : @sorted_map.SortedMap[String, Int]) catch {
    _ => ()
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "json roundtrip verification" {
  let original : Json = { "key1": 42, "key2": 100, "key3": -5 }
  let restored : @sorted_map.SortedMap[String, Int] = @json.from_json(original)
  @json.json_inspect(restored, content={ "key1": 42, "key2": 100, "key3": -5 })
}

///|
test "@sorted_map.merge" {
  let map1 = @sorted_map.from_array([(1, "a"), (2, "b")])
  let map2 = @sorted_map.from_array([(2, "c"), (3, "d")])
  let merged = map1.merge(map2)
  debug_inspect(merged.get(1), content="Some(\"a\")")
  debug_inspect(merged.get(2), content="Some(\"c\")")
  debug_inspect(merged.get(3), content="Some(\"d\")")
  inspect(merged.length(), content="3")
  // Verify original maps are unchanged
  debug_inspect(map1.get(2), content="Some(\"b\")")
  inspect(map1.length(), content="2")
}

///|
test "@sorted_map.merge empty maps" {
  let map1 : @sorted_map.SortedMap[Int, String] = SortedMap([])
  let map2 = @sorted_map.from_array([(1, "a"), (2, "b")])
  let merged1 = map1.merge(map2)
  debug_inspect(merged1.to_array(), content="[(1, \"a\"), (2, \"b\")]")
  let merged2 = map2.merge(map1)
  debug_inspect(merged2.to_array(), content="[(1, \"a\"), (2, \"b\")]")
  let merged3 = map1.merge(map1)
  inspect(merged3.length(), content="0")
}

///|
test "@sorted_map.merge_in_place" {
  let map1 = @sorted_map.from_array([(1, "a"), (2, "b")])
  let map2 = @sorted_map.from_array([(2, "c"), (3, "d")])
  map1.merge_in_place(map2)
  debug_inspect(map1.get(1), content="Some(\"a\")")
  debug_inspect(map1.get(2), content="Some(\"c\")")
  debug_inspect(map1.get(3), content="Some(\"d\")")
  inspect(map1.length(), content="3")
  // Verify second map is unchanged
  inspect(map2.length(), content="2")
}

///|
test "@sorted_map.merge_in_place empty maps" {
  let map1 : @sorted_map.SortedMap[Int, String] = SortedMap([])
  let map2 = @sorted_map.from_array([(1, "a"), (2, "b")])
  map1.merge_in_place(map2)
  debug_inspect(map1.to_array(), content="[(1, \"a\"), (2, \"b\")]")
  map1.merge_in_place(map1)
  debug_inspect(map1.to_array(), content="[(1, \"a\"), (2, \"b\")]")
}

///|
test "get_or_init inserts when absent" {
  let map = @sorted_map.from_array([(1, "a"), (3, "c")])
  let v = map.get_or_init(2, fn() { "b" })
  inspect(v, content="b")
  debug_inspect(map.get(2), content="Some(\"b\")")
  inspect(map.length(), content="3")
}

///|
test "get_or_init returns existing value" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b")])
  let mut called = false
  let v = map.get_or_init(2, fn() {
    called = true
    "c"
  })
  inspect(v, content="b")
  // init function should not be called when key exists
  inspect(called, content="false")
  debug_inspect(map.get(2), content="Some(\"b\")")
}

///|
test "get_or_default returns default when absent" {
  let map = @sorted_map.from_array([(1, "a"), (3, "c")])
  inspect(map.get_or_default(2, "x"), content="x")
  // map should not be modified
  inspect(map.contains(2), content="false")
  inspect(map.length(), content="2")
}

///|
test "get_or_default returns existing value" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b")])
  inspect(map.get_or_default(2, "x"), content="b")
}

///|
test "update_or_default inserts default when absent" {
  let map = @sorted_map.from_array([(1, "a"), (3, "c")])
  map.update_or_default(2, "b", x => x + "!")
  // f is NOT applied to default on first insert
  debug_inspect(map.get(2), content="Some(\"b\")")
  inspect(map.length(), content="3")
}

///|
test "update_or_default applies f when present" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b")])
  // default is ignored when key is present; f is applied to the existing value
  map.update_or_default(2, "z", x => x + "!")
  debug_inspect(map.get(2), content="Some(\"b!\")")
  inspect(map.length(), content="2")
}

///|
test "update_or_default counter pattern" {
  let counts : @sorted_map.SortedMap[String, Int] = SortedMap([])
  for label in ["a", "b", "a", "c", "a", "b"] {
    counts.update_or_default(label, 1, x => x + 1)
  }
  debug_inspect(
    counts.to_array(),
    content=(
      #|[("a", 3), ("b", 2), ("c", 1)]
    ),
  )
}

///|
test "range with inverted bounds returns empty" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  debug_inspect(
    map.range(5, 1).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "range with out-of-bounds keys" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  debug_inspect(
    map.range(0, 10).to_array(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c"), (4, "d"), (5, "e")]
    ),
  )
}

///|
test "range on empty map" {
  let map : @sorted_map.SortedMap[Int, String] = SortedMap([])
  debug_inspect(
    map.range(1, 5).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "copy independence" {
  let map1 = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c")])
  let map2 = map1.copy()
  // Modify the copy
  map2.set(4, "d")
  map2.remove(1)
  map2.set(2, "x")
  // Original should be unchanged
  inspect(map1.length(), content="3")
  debug_inspect(map1.get(1), content="Some(\"a\")")
  debug_inspect(map1.get(2), content="Some(\"b\")")
  inspect(map1.contains(4), content="false")
  // Copy should reflect modifications
  inspect(map2.length(), content="3")
  inspect(map2.contains(1), content="false")
  debug_inspect(map2.get(2), content="Some(\"x\")")
  debug_inspect(map2.get(4), content="Some(\"d\")")
}

///|
/// Returns `(length, keys in order, keys that get can find)`.
fn map_state(
  m : @sorted_map.SortedMap[Int, Int],
) -> (Int, Array[Int], Array[Int]) {
  let keys = m.keys().to_array()
  (m.length(), keys, [ for k in keys if m.get(k) is Some(_) => k ])
}

///|
test "update_or_default: f inserts keys into the same map" {
  let m = @sorted_map.from_array([(150, 0)])
  m.update_or_default(150, 0, v => {
    for i in 0..<10 {
      m.set(i, i)
    }
    v + 1
  })
  debug_inspect(
    map_state(m),
    content=(
      #|(
      #|  11,
      #|  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 150],
      #|  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 150],
      #|)
    ),
  )
  debug_inspect(m.get(150), content="Some(1)")
}

///|
test "update_or_default: f inserts keys on both sides of the present key" {
  let m = @sorted_map.from_array([(10, 0)])
  m.update_or_default(10, 0, v => {
    for k in [5, 3, 15, 20, 1] {
      m.set(k, k)
    }
    v + 1
  })
  debug_inspect(
    map_state(m),
    content=(
      #|(6, [1, 3, 5, 10, 15, 20], [1, 3, 5, 10, 15, 20])
    ),
  )
}

///|
test "update_or_default: f removes other keys from the same map" {
  let m = @sorted_map.from_array([ for i in 0..<8 => (i, i) ])
  m.update_or_default(7, 0, v => {
    for i in 0..<6 {
      m.remove(i)
    }
    v + 10
  })
  debug_inspect(map_state(m), content="(2, [6, 7], [6, 7])")
  debug_inspect(m.get(7), content="Some(17)")
}

///|
test "update_or_default: f removes the present key" {
  let m = @sorted_map.from_array([(1, 1), (2, 2), (3, 3)])
  m.update_or_default(2, 0, v => {
    m.remove(2)
    v + 10
  })
  debug_inspect(m.to_array(), content="[(1, 1), (2, 12), (3, 3)]")
  inspect(m.length(), content="3")
}

///|
test "update_or_default: f sets the present key" {
  let m = @sorted_map.from_array([(1, 1), (2, 2)])
  m.update_or_default(1, 0, v => {
    m.set(1, 100)
    v + 10
  })
  debug_inspect(m.to_array(), content="[(1, 11), (2, 2)]")
}

///|
test "update_or_default: f removes the key whose successor is the present key" {
  // Built from 0..<5, the tree is 1(0, 3(2, 4)). Removing 1 moves key 2 into
  // the root node and unlinks the node that held 2 when `f` was called.
  let m = @sorted_map.from_array([ for i in 0..<5 => (i, i) ])
  m.update_or_default(2, 0, v => {
    m.remove(1)
    v + 10
  })
  debug_inspect(
    m.to_array(),
    content=(
      #|[(0, 0), (2, 12), (3, 3), (4, 4)]
    ),
  )
  inspect(m.length(), content="4")
}

///|
test "update_or_default: f removes and re-inserts the present key" {
  let m = @sorted_map.from_array([ for i in 0..<5 => (i, i) ])
  m.update_or_default(3, 0, v => {
    m.remove(3)
    m.set(3, 100)
    v + 10
  })
  debug_inspect(
    map_state(m),
    content=(
      #|(5, [0, 1, 2, 3, 4], [0, 1, 2, 3, 4])
    ),
  )
  debug_inspect(m.get(3), content="Some(13)")
}

///|
test "update_or_default: f clears the map" {
  let m = @sorted_map.from_array([ for i in 0..<5 => (i, i) ])
  m.update_or_default(2, 0, v => {
    m.clear()
    v + 10
  })
  debug_inspect(m.to_array(), content="[(2, 12)]")
  inspect(m.length(), content="1")
}

///|
fn sorted_map_fib(memo : @sorted_map.SortedMap[Int, Int], n : Int) -> Int {
  if n < 2 {
    return n
  }
  memo.get_or_init(n, () => {
    sorted_map_fib(memo, n - 1) + sorted_map_fib(memo, n - 2)
  })
}

///|
test "get_or_init: init may write to the same map (memoization)" {
  let memo : @sorted_map.SortedMap[Int, Int] = SortedMap([])
  inspect(sorted_map_fib(memo, 30), content="832040")
  let missing = [ for k in 2..<=30 if memo.get(k) is None => k ]
  debug_inspect(
    (memo.length(), memo.to_array().length(), missing),
    content=(
      #|(29, 29, [])
    ),
  )
}

///|
test "get_or_init: init inserts the same key" {
  let m = @sorted_map.from_array([(1, 1)])
  let v = m.get_or_init(3, () => {
    m.set(3, 30)
    m.set(2, 20)
    300
  })
  inspect(v, content="300")
  debug_inspect(m.to_array(), content="[(1, 1), (2, 20), (3, 300)]")
}
