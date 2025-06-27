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
    content=
      #|{"a": "a1", "b": "b2", "c": "c3"}
    ,
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let v = map.map((k, v) => k + v.to_string())
  inspect(
    v,
    content=
      #|{"a": "a1", "b": "b2", "d": "d10", "e": "e20"}
    ,
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
    content=
      #|{"a": 1, "b": 2, "c": 3}
    ,
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let copy = map.copy()
  inspect(
    copy,
    content=
      #|{"a": 1, "b": 2, "d": 10, "e": 20}
    ,
  )
  let copy : Map[String, String] = {}.copy()
  inspect(copy, content="{}")
}
