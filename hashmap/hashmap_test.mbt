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
test "new" {
  let m : @hashmap.HashMap[Int, Int] = @hashmap.new()
  inspect(m.capacity(), content="8")
  inspect(m.length(), content="0")
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
test "_[_]" {
  let m = @hashmap.new()
  m.set("a", 1)
  m.set("b", 2)
  assert_eq(m["a"], 1)
  assert_eq(m["b"], 2)
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
  let m : @hashmap.HashMap[String, Array[Int]] = @hashmap.new()
  m.get_or_init("a", () => Array::new()).push(1)
  m.get_or_init("b", () => Array::new()).push(2)
  m.get_or_init("a", () => Array::new()).push(3)
  assert_eq(m.get("a"), Some([1, 3]))
  assert_eq(m.get("b"), Some([2]))
  assert_eq(m.length(), 2)
}

///|
test "get_or_init full" {
  let m = @hashmap.new(capacity=2)
  m.get_or_init("a", () => 0) |> ignore
  m.get_or_init("b", () => 0) |> ignore
  m.get_or_init("c", () => 0) |> ignore
  assert_eq(m.length(), 3)
}

///|
test "_[_]=_" {
  let m = @hashmap.new()
  m["a"] = 1
  m["b"] = 2
  assert_eq(m.get("a"), Some(1))
  assert_eq(m.get("b"), Some(2))
}

///|
test "panic get" {
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
  let m = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(m.get("a"), Some(1))
  assert_eq(m.get("b"), Some(2))
  assert_eq(m.get("c"), Some(3))
}

///|
test "size" {
  let m = @hashmap.new()
  inspect(m.length(), content="0")
  m.set("a", 1)
  inspect(m.length(), content="1")
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
test "each" {
  let m = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  let mut sum = 0
  m.each((_k, v) => sum += v)
  inspect(sum, content="6")
}

///|
test "iter_collect" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let array = map.iter().collect()
  array.sort()
  inspect(
    array,
    content=(
      #|[(1, "one"), (2, "two"), (3, "three")]
    ),
  )
}

///|
test "iteri" {
  let m = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
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
test "iter2" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let array = map.iter2().to_array()
  array.sort()
  inspect(
    array,
    content=(
      #|[(1, "one"), (2, "two"), (3, "three")]
    ),
  )
}

///|
test "iter" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let array = map.iter().collect()
  array.sort()
  inspect(
    array,
    content=(
      #|[(1, "one"), (2, "two"), (3, "three")]
    ),
  )
}

///|
test "to_array" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let array = map.to_array()
  array.sort()
  inspect(
    array,
    content=(
      #|[(1, "one"), (2, "two"), (3, "three")]
    ),
  )
}

///|
test "to_array empty" {
  let map : @hashmap.HashMap[Int, String] = @hashmap.new()
  inspect(map.to_array(), content="[]")
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
  inspect(m.length(), content="2")
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
  let map = @hashmap.from_iter([(1, 1), (2, 2), (3, 3)].iter())
  guard map is { 1: 1, 2: 2, 3: 3, .. } else {
    fail("Map is not expected: \{map}")
  }
  inspect(map.length(), content="3")
}

///|
test "from_iter single element iter" {
  inspect(
    @hashmap.from_iter([(1, 1)].iter()),
    content="HashMap::from_array([(1, 1)])",
  )
}

///|
test "from_iter empty iter" {
  let map : @hashmap.HashMap[Int, Int] = @hashmap.from_iter(Iter::empty())
  inspect(map, content="HashMap::from_array([])")
}

///|
test "@hashmap.contains/empty" {
  let map : @hashmap.HashMap[Int, String] = @hashmap.new()
  inspect(map.contains(42), content="false")
}

///|
test "@hashmap.contains/basic" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  inspect(map.contains(2), content="true")
  inspect(map.contains(4), content="false")
}

///|
test "@hashmap.contains/after_operations" {
  let map = @hashmap.from_array([(1, "one"), (2, "two")])
  map.remove(1)
  inspect(map.contains(1), content="false")
  map.set(1, "ONE")
  inspect(map.contains(1), content="true")
  map.clear()
  inspect(map.contains(2), content="false")
}

///|
test "@hashmap.from_array" {
  let array = [("a", 1), ("b", 2), ("c", 3)]
  let map = @hashmap.from_array(array)
  for k, v in map {
    assert_eq(map.get(k), Some(v))
  }
  assert_eq(map.length(), array.length())
}

///|
test "@hashmap.from_array with int key" {
  let array = [(1, "one"), (2, "two"), (3, "three")]
  let map = @hashmap.from_array(array)
  for k, v in map {
    assert_eq(map.get(k), Some(v))
  }
  assert_eq(map.length(), array.length())
}

///|
test "@hashmap.contains_kv" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  inspect(map.contains_kv(1, "one"), content="true")
  inspect(map.contains_kv(1, "two"), content="false")
  inspect(map.contains_kv(4, "four"), content="false")
}

///|
test "@hashmap.eq" {
  let map1 = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let map2 = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  inspect(map1 == map2, content="true")
}

///|
test "@hashmap.map" {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  let v = map.map((k, v) => k + v.to_string())
  verify_content(v, [("a", "a1"), ("b", "b2"), ("c", "c3")])
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let v = map.map((k, v) => k + v.to_string())
  verify_content(v, [("a", "a1"), ("b", "b2"), ("d", "d10"), ("e", "e20")])
  let v : @hashmap.HashMap[String, String] = @hashmap.new().map((k, v) => k + v)
  inspect(v, content="HashMap::from_array([])")
}

///|
test "@hashmap.copy" {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  let copy = map.copy()
  verify_content(copy, [("a", 1), ("b", 2), ("c", 3)])
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let copy = map.copy()
  verify_content(copy, [("e", 20), ("a", 1), ("b", 2), ("d", 10)])
  let copy : @hashmap.HashMap[String, String] = @hashmap.new().copy()
  inspect(copy, content="HashMap::from_array([])")
}

///|
fn[K : Hash + Eq + Show, V : Eq + Show] verify_content(
  map : @hashmap.HashMap[K, V],
  expected : Array[(K, V)],
) -> Unit raise {
  for entry in expected {
    let (k, v) = entry
    assert_true(
      map.contains_kv(k, v),
      msg="Key \{k} with value \{v} not found in map \{map}",
    )
  }
  assert_eq(map.length(), expected.length())
}

///|
test "hashmap.to_json" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let json : Json = { "1": "one", "2": "two", "3": "three" }
  assert_eq(map.to_json(), json)
}

///|
test "@hashmap.merge" {
  let map1 = @hashmap.from_array([("a", 1), ("b", 2)])
  let map2 = @hashmap.from_array([("b", 3), ("c", 4)])
  let merged = map1.merge(map2)
  inspect(merged.get("a"), content="Some(1)")
  inspect(merged.get("b"), content="Some(3)")
  inspect(merged.get("c"), content="Some(4)")
  inspect(merged.length(), content="3")
  // Verify original maps are unchanged
  inspect(map1.get("b"), content="Some(2)")
  inspect(map1.length(), content="2")
}

///|
test "@hashmap.merge empty maps" {
  let map1 : @hashmap.HashMap[String, Int] = @hashmap.new()
  let map2 = @hashmap.from_array([("a", 1), ("b", 2)])
  let merged1 = map1.merge(map2)
  verify_content(merged1, [("a", 1), ("b", 2)])
  let merged2 = map2.merge(map1)
  verify_content(merged2, [("a", 1), ("b", 2)])
  let merged3 = map1.merge(map1)
  inspect(merged3.length(), content="0")
}

///|
test "@hashmap.merge_in_place" {
  let map1 = @hashmap.from_array([("a", 1), ("b", 2)])
  let map2 = @hashmap.from_array([("b", 3), ("c", 4)])
  map1.merge_in_place(map2)
  inspect(map1.get("a"), content="Some(1)")
  inspect(map1.get("b"), content="Some(3)")
  inspect(map1.get("c"), content="Some(4)")
  inspect(map1.length(), content="3")
  // Verify second map is unchanged
  inspect(map2.length(), content="2")
}

///|
test "@hashmap.merge_in_place empty maps" {
  let map1 : @hashmap.HashMap[String, Int] = @hashmap.new()
  let map2 = @hashmap.from_array([("a", 1), ("b", 2)])
  map1.merge_in_place(map2)
  verify_content(map1, [("a", 1), ("b", 2)])
  map1.merge_in_place(map1)
  verify_content(map1, [("a", 1), ("b", 2)])
}

///|
priv struct Key(Int, Int) derive(Eq)

///|
impl Hash for Key with hash(self) {
  let Key(_, hash) = self
  hash
}

///|
impl Hash for Key with hash_combine(self, hasher) {
  let Key(_, hash) = self
  hasher.combine_int(hash)
}

///|
test "hashmap collision probe paths" {
  let map : @hashmap.HashMap[Key, Int] = @hashmap.new()
  let k0 = Key::Key(0, 0)
  let k1 = Key::Key(1, 1)
  map.set(k0, 10)
  map.set(k1, 20)
  inspect(map.get_or_default(Key::Key(2, 0), 99), content="99")
  inspect(map.contains(Key::Key(3, 0)), content="false")
}

///|
test "hashmap get_or_init push_away" {
  let map : @hashmap.HashMap[Key, Int] = @hashmap.new()
  map.set(Key::Key(1, 1), 10)
  map.set(Key::Key(2, 2), 20)
  inspect(map.get_or_init(Key::Key(3, 1), () => 30), content="30")
  inspect(map.get(Key::Key(3, 1)), content="Some(30)")
}

///|
test "hashmap default" {
  let map : @hashmap.HashMap[Int, Int] = Default::default()
  inspect(map.length(), content="0")
}
