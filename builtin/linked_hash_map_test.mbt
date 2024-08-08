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

test "Map keys iter" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.keys()
  inspect!(
    v,
    content=
      #|["a", "b", "c"]
    ,
  )
  inspect!(map.values(), content="[1, 2, 3]")
  inspect!(({  } : Map[String, Int]).keys(), content="[]")
  inspect!(({  } : Map[String, Int]).values(), content="[]")
}

test "Map::from_iter" {
  let iter = [("a", 1), ("b", 2), ("c", 3)].iter()
  let map = Map::from_iter(iter)
  inspect!(
    map,
    content=
      #|{"a": 1, "b": 2, "c": 3}
    ,
  )
}

test "Map:: iter2" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.iter2()
  let mut res = ""
  v.each(fn(k, v) { res = res + k + v.to_string() })
  inspect!(res, content="a1b2c3")
}

test "foreach" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let mut res = "" // note foreach does not have an acc state so it is more impreative than functional loop
  foreach (k, v) <- map {
    res += "\{k}\{v}"
  }
  inspect!(res, content="a1b2c3")
  inspect!(
    map.iter().fold(init="", fn(acc, kv) { acc + kv.0 + kv.1.to_string() }),
  )

  // map.iter().fold(init="", fn(acc,k,v) { acc + k + v.to_string() })
  // weird error message
}
