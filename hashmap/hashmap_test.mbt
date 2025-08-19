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
test "new" {
  let m : @hashmap.T[Int, Int] = @hashmap.new()
  inspect(m.capacity(), content="8")
  inspect(m.size(), content="0")
}

///|
test "get" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  inspect(m.get("a"), content="Some(1)")
  inspect(m.get("b"), content="Some(2)")
  inspect(m.get("c"), content="Some(3)")
  inspect(m.get("d"), content="None")

  // pattern
  guard m is { "a": 1, "b": 2, "c": 3, "d"? : None, .. }
}

///|
test "get_or_default" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  inspect(m.get_or_default("a", 42), content="1")
  inspect(m.get_or_default("b", 42), content="2")
  inspect(m.get_or_default("c", 42), content="3")
  inspect(m.get_or_default("d", 42), content="42")
}

///|
test "get_or_init" {
  let m : @hashmap.T[String, Array[Int]] = @hashmap.new()
  m.get_or_init("a", () => Array::new()).push(1)
  m.get_or_init("b", () => Array::new()).push(2)
  m.get_or_init("a", () => Array::new()).push(3)
  assert_eq(m.get("a"), Some([1, 3]))
  assert_eq(m.get("b"), Some([2]))
  assert_eq(m.size(), 2)
}

///|
test "get_or_init full" {
  let m = @hashmap.new(capacity=2)
  m.get_or_init("a", () => 0) |> ignore
  m.get_or_init("b", () => 0) |> ignore
  m.get_or_init("c", () => 0) |> ignore
  assert_eq(m.size(), 3)
}

///|
test "op_set" {
  let m = @hashmap.new()
  m["a"] = 1
  m["b"] = 2
  assert_eq(m.get("a"), Some(1))
  assert_eq(m.get("b"), Some(2))
}

///|
test "op_get" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  assert_eq(m["a"], 1)
  assert_eq(m["b"], 2)
}

///|
test "panic op_get" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m["c"] |> ignore
}

///|
test "set_update" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  assert_eq(m.get("a"), Some(1))
  m.set("a", 2)
  assert_eq(m.get("a"), Some(2))
}

///|
test "contains" {
  let m = @hashmap.new()
  m.set("a", 1)
  inspect(m.contains("a"), content="true")
  inspect(m.contains("b"), content="false")
}

///|
test "from_array" {
  let m = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(m.get("a"), Some(1))
  assert_eq(m.get("b"), Some(2))
  assert_eq(m.get("c"), Some(3))
}

///|
test "size" {
  let m = @hashmap.new()
  inspect(m.size(), content="0")
  m.set("a", 1)
  inspect(m.size(), content="1")
}

///|
test "is_empty" {
  let m = @hashmap.new()
  inspect(m.is_empty(), content="true")
  m.set("a", 1)
  inspect(m.is_empty(), content="false")
  m.remove("a")
  inspect(m.is_empty(), content="true")
}

///|
test "iter" {
  let m = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
  let mut sum = 0
  m.each((_k, v) => sum += v)
  inspect(sum, content="6")
}

///|
test "iteri" {
  let m = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
  let mut sum = 0
  let mut s = ""
  m.eachi((i, _k, v) => {
    s += i.to_string()
    sum += v
  })
  inspect(s, content="012")
  inspect(sum, content="6")
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let map = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
  map
  .iter()
  .each(e => {
    let (k, v) = e
    buf.write_string("[\{k}-\{v}]")
  })
  inspect(buf, content="[2-two][1-one][3-three]")
  buf.reset()
  map
  .iter()
  .take(2)
  .each(e => {
    let (k, v) = e
    buf.write_string("[\{k}-\{v}]")
  })
  inspect(buf, content="[2-two][1-one]")
}

///|
test "iter2" {
  let buf = StringBuilder::new(size_hint=20)
  let map = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
  for k, v in map {
    buf.write_string("[\{k}-\{v}]")
  }
  inspect(buf, content="[2-two][1-one][3-three]")
}

///|
test "to_array" {
  let map = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
  inspect(
    map.to_array(),
    content=(
      #|[(2, "two"), (1, "one"), (3, "three")]
    ),
  )
}

///|
test "get_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")
}

///|
test "remove_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  inspect(m.size(), content="2")
}

///|
test "get_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")
}

///|
test "remove_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  inspect(m.size(), content="2")
}

///|
test "get_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")
}

///|
test "remove_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  inspect(m.size(), content="2")
}

///|
test "get_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")
}

///|
test "remove_nonexistent_key" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  inspect(m.size(), content="2")
}

///|
test "get_nonexistent_key_with_psl" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("d", 4)
  m.set("e", 5)
  m.set("f", 6)
  m.set("g", 7)
  m.set("h", 8)
  m.set("i", 9)
  m.set("j", 10)
  m.set("k", 11)
  m.set("l", 12)
  m.set("m", 13)
  m.set("n", 14)
  m.set("o", 15)
  m.set("p", 16)
  m.set("q", 17)
  m.set("r", 18)
  m.set("s", 19)
  m.set("t", 20)
  m.set("u", 21)
  m.set("v", 22)
  m.set("w", 23)
  m.set("x", 24)
  m.set("y", 25)
  m.set("z", 26)
  inspect(m.get("A"), content="None")
  inspect(m.get("B"), content="None")
  inspect(m.get("C"), content="None")
  inspect(m.get("D"), content="None")
  inspect(m.get("E"), content="None")
  inspect(m.get("F"), content="None")
  inspect(m.get("G"), content="None")
  inspect(m.get("H"), content="None")
  inspect(m.get("I"), content="None")
  inspect(m.get("J"), content="None")
  inspect(m.get("K"), content="None")
  inspect(m.get("L"), content="None")
  inspect(m.get("M"), content="None")
  inspect(m.get("N"), content="None")
  inspect(m.get("O"), content="None")
  inspect(m.get("P"), content="None")
  inspect(m.get("Q"), content="None")
  inspect(m.get("R"), content="None")
  inspect(m.get("S"), content="None")
  inspect(m.get("T"), content="None")
  inspect(m.get("U"), content="None")
  inspect(m.get("V"), content="None")
  inspect(m.get("W"), content="None")
  inspect(m.get("X"), content="None")
  inspect(m.get("Y"), content="None")
  inspect(m.get("Z"), content="None")
}

///|
test "from_iter multiple elements iter" {
  inspect(
    @hashmap.from_iter([(1, 1), (2, 2), (3, 3)].iter()),
    content="HashMap::of([(2, 2), (1, 1), (3, 3)])",
  )
}

///|
test "from_iter single element iter" {
  inspect(@hashmap.from_iter([(1, 1)].iter()), content="HashMap::of([(1, 1)])")
}

///|
test "from_iter empty iter" {
  let map : @hashmap.T[Int, Int] = @hashmap.from_iter(Iter::empty())
  inspect(map, content="HashMap::of([])")
}

///|
test "@hashmap.contains/empty" {
  let map : @hashmap.T[Int, String] = @hashmap.new()
  inspect(map.contains(42), content="false")
}

///|
test "@hashmap.contains/basic" {
  let map = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
  inspect(map.contains(2), content="true")
  inspect(map.contains(4), content="false")
}

///|
test "@hashmap.contains/after_operations" {
  let map = @hashmap.of([(1, "one"), (2, "two")])
  map.remove(1)
  inspect(map.contains(1), content="false")
  map.set(1, "ONE")
  inspect(map.contains(1), content="true")
  map.clear()
  inspect(map.contains(2), content="false")
}

///|
test "@hashmap.from_array" {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  @json.inspect(map, content={ "a": 1, "c": 3, "b": 2 })
}

///|
test "@hashmap.from_array with int key" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  @json.inspect(map, content={ "2": "two", "1": "one", "3": "three" })
}

///|
test "@hashmap.contains_kv" {
  let map = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
  inspect(map.contains_kv(1, "one"), content="true")
  inspect(map.contains_kv(1, "two"), content="false")
  inspect(map.contains_kv(4, "four"), content="false")
}

///|
test "@hashmap.eq" {
  let map1 = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
  let map2 = @hashmap.of([(1, "one"), (2, "two"), (3, "three")])
  inspect(map1 == map2, content="true")
}

///|
test "@hashmap.map" {
  let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
  let v = map.map((k, v) => k + v.to_string())
  inspect(
    v,
    content=(
      #|HashMap::of([("a", "a1"), ("c", "c3"), ("b", "b2")])
    ),
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let v = map.map((k, v) => k + v.to_string())
  inspect(
    v,
    content=(
      #|HashMap::of([("e", "e20"), ("a", "a1"), ("b", "b2"), ("d", "d10")])
    ),
  )
  let v : T[String, String] = @hashmap.new().map((k, v) => k + v)
  inspect(v, content="HashMap::of([])")
}

///|
test "@hashmap.copy" {
  let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
  let copy = map.copy()
  inspect(
    copy,
    content=(
      #|HashMap::of([("a", 1), ("c", 3), ("b", 2)])
    ),
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let copy = map.copy()
  inspect(
    copy,
    content=(
      #|HashMap::of([("e", 20), ("a", 1), ("b", 2), ("d", 10)])
    ),
  )
  let copy : T[String, String] = @hashmap.new().copy()
  inspect(copy, content="HashMap::of([])")
}

///|
test "filter" {
  let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3), ("d", 4)])
  let filtered = map.filter((_, v) => v > 2)
  inspect(filtered.size(), content="2")
  inspect(filtered.contains("c"), content="true")
  inspect(filtered.contains("d"), content="true")
  inspect(filtered.contains("a"), content="false")
  inspect(filtered.contains("b"), content="false")
}

///|
test "retain" {
  let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3), ("d", 4)])
  map.retain((_, v) => v > 2)
  inspect(map.size(), content="2")
  inspect(map.contains("c"), content="true")
  inspect(map.contains("d"), content="true")
  inspect(map.contains("a"), content="false")
  inspect(map.contains("b"), content="false")
}

///|
test "filter_map" {
  let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3)])
  let result = map.filter_map((_, v) => if v > 1 { Some(v * 2) } else { None })
  inspect(result.get("a"), content="None")
  inspect(result.get("b"), content="Some(4)")
  inspect(result.get("c"), content="Some(6)")
  inspect(result.size(), content="2")
}

///|
test "partition" {
  let map = @hashmap.of([("a", 1), ("b", 2), ("c", 3), ("d", 4)])
  let (evens, odds) = map.partition((_, v) => v % 2 == 0)
  inspect(evens.size(), content="2")
  inspect(odds.size(), content="2")
  inspect(evens.contains("b"), content="true")
  inspect(evens.contains("d"), content="true")
  inspect(odds.contains("a"), content="true")
  inspect(odds.contains("c"), content="true")
}

///|
test "union_with" {
  let map1 = @hashmap.of([("a", 1), ("b", 2)])
  let map2 = @hashmap.of([("b", 3), ("c", 4)])
  let merged = map1.union_with(map2, (_, v1, v2) => v1 + v2)
  inspect(merged.get("a"), content="Some(1)")
  inspect(merged.get("b"), content="Some(5)")
  inspect(merged.get("c"), content="Some(4)")
  inspect(merged.size(), content="3")
}

///|
test "update" {
  let map = @hashmap.of([("a", 1), ("b", 2)])

  // Update existing value
  map.update("a", fn(v) {
    match v {
      Some(x) => Some(x + 10)
      None => Some(0)
    }
  })
  inspect(map.get("a"), content="Some(11)")

  // Insert new value
  map.update("c", fn(v) {
    match v {
      Some(x) => Some(x)
      None => Some(3)
    }
  })
  inspect(map.get("c"), content="Some(3)")

  // Remove existing value
  map.update("b", fn(_) { None })
  inspect(map.get("b"), content="None")

  // Try to update non-existent key and return None (no-op)
  let old_size = map.size()
  map.update("d", fn(_) { None })
  inspect(map.size(), content=old_size.to_string())
}
