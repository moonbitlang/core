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
test "Map keys iter" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.keys()
  inspect(
    v,
    content=
      #|["a", "b", "c"]
    ,
  )
  inspect(map.values(), content="[1, 2, 3]")
  inspect(({} : Map[String, Int]).keys(), content="[]")
  inspect(({} : Map[String, Int]).values(), content="[]")
}

///|
test "Map::from_iter" {
  let iter = [("a", 1), ("b", 2), ("c", 3)].iter()
  let map = Map::from_iter(iter)
  inspect(
    map,
    content=
      #|{"a": 1, "b": 2, "c": 3}
    ,
  )
}

///|
test "Map:: iter2" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.iter2()
  let mut res = ""
  v.each(fn(k, v) { res = res + k + v.to_string() })
  inspect(res, content="a1b2c3")
}

///|
test "map::contains_kv" {
  let map = { "a": 1, "b": 2, "c": 3 }
  // contains_kv will be used in the pattern matching
  // to avoid boxing
  inspect(map.contains_kv("a", 1), content="true")
  inspect(map.contains_kv("a", 2), content="false")
  guard map is { "a": 1, "b": 2, "c": 3, .. } else {
    fail("map is not { \"a\": 1, \"b\": 2, \"c\": 3 }")
  }
}

///|
test "Map::map - transform values preserving order" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let doubled = map.map(fn(_k, v) { v * 2 })
  
  // Check transformed values
  inspect(doubled.get("a"), content="Some(2)")
  inspect(doubled.get("b"), content="Some(4)")
  inspect(doubled.get("c"), content="Some(6)")
  
  // Check size is preserved
  inspect(doubled.size(), content="3")
  
  // Check order is preserved
  let order = []
  doubled.each(fn(k, v) { order.push((k, v)) })
  inspect(
    order,
    content=
      #|[("a", 2), ("b", 4), ("c", 6)]
    ,
  )
  
  // Original map should be unchanged
  inspect(map.get("a"), content="Some(1)")
  inspect(map.get("b"), content="Some(2)")
  inspect(map.get("c"), content="Some(3)")
}

///|
test "Map::map - empty map" {
  let empty : Map[String, Int] = {}
  let result = empty.map(fn(_k, v) { v.to_string() })
  inspect(result.size(), content="0")
  inspect(result.is_empty(), content="true")
}

///|
test "Map::map - change type" {
  let map = { 1: 10, 2: 20, 3: 30 }
  let string_map = map.map(fn(k, v) { k.to_string() + ":" + v.to_string() })
  
  inspect(string_map.get(1), content="Some(\"1:10\")")
  inspect(string_map.get(2), content="Some(\"2:20\")")
  inspect(string_map.get(3), content="Some(\"3:30\")")
  
  // Check order is preserved
  let vals = []
  string_map.values().each(fn(v) { vals.push(v) })
  inspect(
    vals,
    content=
      #|["1:10", "2:20", "3:30"]
    ,
  )
}

///|
test "Map::copy - basic functionality" {
  let map1 = { "a": 1, "b": 2, "c": 3 }
  let map2 = map1.copy()
  
  // Check copied values
  inspect(map2.get("a"), content="Some(1)")
  inspect(map2.get("b"), content="Some(2)")
  inspect(map2.get("c"), content="Some(3)")
  
  // Check size and structure
  inspect(map2.size(), content="3")
  inspect(map1.size(), content="3")
  
  // Check order is preserved
  let order1 = []
  let order2 = []
  map1.each(fn(k, v) { order1.push((k, v)) })
  map2.each(fn(k, v) { order2.push((k, v)) })
  inspect(
    order1,
    content=
      #|[("a", 1), ("b", 2), ("c", 3)]
    ,
  )
  inspect(
    order2,
    content=
      #|[("a", 1), ("b", 2), ("c", 3)]
    ,
  )
}

///|
test "Map::copy - independence" {
  let map1 = { "x": 10, "y": 20 }
  let map2 = map1.copy()
  
  // Modify original
  map1.set("x", 100)
  map1.set("z", 30)
  
  // Check original is changed
  inspect(map1.get("x"), content="Some(100)")
  inspect(map1.get("z"), content="Some(30)")
  inspect(map1.size(), content="3")
  
  // Check copy is unchanged
  inspect(map2.get("x"), content="Some(10)")
  inspect(map2.get("z"), content="None")
  inspect(map2.size(), content="2")
  
  // Modify copy
  map2.set("y", 200)
  
  // Check original is unaffected by copy modification
  inspect(map1.get("y"), content="Some(20)")
  inspect(map2.get("y"), content="Some(200)")
}

///|
test "Map::copy - empty map" {
  let empty : Map[String, Int] = {}
  let copy = empty.copy()
  
  inspect(copy.size(), content="0")
  inspect(copy.is_empty(), content="true")
  
  // Add to original  
  empty.set("test", 1)
  inspect(empty.size(), content="1")
  inspect(copy.size(), content="0")
}

///|
test "Map::map and copy - chaining operations" {
  let original = { "one": 1, "two": 2, "three": 3 }
  let mapped = original.map(fn(_k, v) { v * 10 })
  let copied = mapped.copy()
  
  // All should have the same structure but different values for original vs mapped/copied
  inspect(original.size(), content="3")
  inspect(mapped.size(), content="3") 
  inspect(copied.size(), content="3")
  
  // Check values
  inspect(original.get("one"), content="Some(1)")
  inspect(mapped.get("one"), content="Some(10)")
  inspect(copied.get("one"), content="Some(10)")
  
  // Modify copied, ensure others unchanged
  copied.set("one", 100)
  inspect(original.get("one"), content="Some(1)")
  inspect(mapped.get("one"), content="Some(10)")
  inspect(copied.get("one"), content="Some(100)")
}

///|
test "Map::map - complex transformation with keys" {
  let map = { "apple": 5, "banana": 6, "cherry": 6 }
  let result = map.map(fn(k, v) { k + " has " + v.to_string() + " letters" })
  
  inspect(result.get("apple"), content="Some(\"apple has 5 letters\")")
  inspect(result.get("banana"), content="Some(\"banana has 6 letters\")") 
  inspect(result.get("cherry"), content="Some(\"cherry has 6 letters\")")
  
  // Check insertion order is preserved
  let pairs = []
  result.each(fn(k, v) { pairs.push((k, v)) })
  inspect(
    pairs,
    content=
      #|[("apple", "apple has 5 letters"), ("banana", "banana has 6 letters"), ("cherry", "cherry has 6 letters")]
    ,
  )
}