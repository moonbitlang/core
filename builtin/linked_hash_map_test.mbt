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
    content=(
      #|["a", "b", "c"]
    ),
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
    content=(
      #|{"a": 1, "b": 2, "c": 3}
    ),
  )
}

///|
test "Map:: iter2" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.iter2()
  let mut res = ""
  v.each((k, v) => res = res + k + v.to_string())
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
test "Map::map" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.map((k, v) => k + v.to_string())
  inspect(
    v,
    content=(
      #|{"a": "a1", "b": "b2", "c": "c3"}
    ),
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let v = map.map((k, v) => k + v.to_string())
  inspect(
    v,
    content=(
      #|{"a": "a1", "b": "b2", "d": "d10", "e": "e20"}
    ),
  )
  let v : Map[String, String] = {}.map((k, v) => k + v)
  inspect(v, content="{}")
}

///|
test "Map::copy" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let copy = map.copy()
  inspect(
    copy,
    content=(
      #|{"a": 1, "b": 2, "c": 3}
    ),
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let copy = map.copy()
  inspect(
    copy,
    content=(
      #|{"a": 1, "b": 2, "d": 10, "e": 20}
    ),
  )
  let copy : Map[String, String] = {}.copy()
  inspect(copy, content="{}")
}

///|
test "Map::update" {
  // Test updating existing value
  let map = { "a": 1, "b": 2, "c": 3 }
  map.update("a", fn(v) {
    match v {
      Some(x) => Some(x + 10)
      None => Some(0)
    }
  })
  inspect(map.get("a"), content="Some(11)")
  inspect(map.size(), content="3")

  // Test inserting new value when key doesn't exist
  map.update("d", fn(v) {
    match v {
      Some(x) => Some(x)
      None => Some(4)
    }
  })
  inspect(map.get("d"), content="Some(4)")
  inspect(map.size(), content="4")
  inspect(
    map,
    content=(
      #|{"a": 11, "b": 2, "c": 3, "d": 4}
    ),
  )

  // Test removing existing value by returning None
  map.update("b", fn(_) { None })
  inspect(map.get("b"), content="None")
  inspect(map.size(), content="3")
  inspect(
    map,
    content=(
      #|{"a": 11, "c": 3, "d": 4}
    ),
  )

  // Test no-op when key doesn't exist and function returns None
  map.update("e", fn(_) { None })
  inspect(map.get("e"), content="None")
  inspect(map.size(), content="3")

  // Test incrementing a counter (common use case)
  let counter_map : Map[String, Int] = {}
  counter_map.update("clicks", fn(v) {
    match v {
      Some(count) => Some(count + 1)
      None => Some(1)
    }
  })
  inspect(counter_map.get("clicks"), content="Some(1)")
  counter_map.update("clicks", fn(v) {
    match v {
      Some(count) => Some(count + 1)
      None => Some(1)
    }
  })
  inspect(counter_map.get("clicks"), content="Some(2)")

  // Test on empty map
  let empty_map : Map[String, Int] = {}

  // Test no-op on empty map
  empty_map.update("empty", fn(_) { None })

  // Test inserting new value on empty map
  empty_map.update("new", fn(v) {
    match v {
      Some(x) => Some(x * 2)
      None => Some(42)
    }
  })
  inspect(empty_map.get("new"), content="Some(42)")
  inspect(empty_map.size(), content="1")

  // Test adding to empty map
  let empty_map : Map[String, Int] = Map::new(capacity=1)
  empty_map.update("a", _ => Some(1))
  empty_map.update("b", _ => Some(2))
  empty_map.update("c", _ => Some(3))
}
