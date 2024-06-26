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

test "HAMT::size" {
  for i = 0, map = Map::new(); i < 20; i = i + 1, map = map.add(i, i) {
    @assertion.assert_eq(map.size(), i)?
  } else {
    @assertion.assert_eq(map.add(0, 0).size(), 20)?
  }
}

test "HAMT" {
  let map = loop 0, Map::new() {
    100, map => map
    i, map => continue i + 1, map.add(i, i)
  }
  for i = 0; i < 100; i = i + 1 {
    @assertion.assert_eq((i, map.find(i)), (i, Some(i)))?
  }
  inspect((100, map.find(100)), content="(100, None)")?
  let map = map.add(100, 100)
  inspect((100, map.find(100)), content="(100, Some(100))")?
  // test for replacement
  let map = loop 0, map {
    100, map => map
    i, map => continue i + 2, map.add(i, i + 1)
  }
  for i = 0; i < 100; i = i + 2 {
    @assertion.assert_eq((i, map.find(i)), (i, Some(i + 1)))?
    @assertion.assert_eq((i + 1, map.find(i + 1)), (i + 1, Some(i + 1)))?
  }
}

test "HAMT::remove" {
  let map = loop 0, Map::new() {
    100, map => map
    i, map => continue i + 1, map.add(i, i)
  }
  for i = 0; i < 100; i = i + 1 {
    @assertion.assert_eq((i, map.find(i)), (i, Some(i)))?
  }
  let map = loop 0, map {
    100, map => map.remove(100) // test for removing non-existing element
    i, map => continue i + 2, map.remove(i)
  }
  for i = 0; i < 100; i = i + 2 {
    @assertion.assert_eq(map.find(i), None)?
    @assertion.assert_eq(map.find(i + 1), Some(i + 1))?
  }
}

test "HAMT::as_iter" {
  let data = of([(0, "a"), (2, "b"), (3, "d"), (5, "e"), (11111, "f")])
  let mut s = ""
  data.as_iter().each(fn { (k, v) => s += " \(k),\(v)" })
  inspect(s, content=" 0,a 5,e 3,d 11111,f 2,b")?
}

test "HAMT::to_string" {
  let map = Map::new().add(1, 1).add(3, 3).add(0x0f_ff_ff_ff, 0x0f_ff_ff_ff).add(
    42, 42,
  )
  inspect(
    map,
    content="@immutable_hashmap.Map::[(3, 3), (42, 42), (1, 1), (268435455, 268435455)]",
  )?
}

test "HAMT::from_array" {
  let map = of([(1, "1"), (2, "2"), (42, "42")])
  inspect((1, map.find(1)), content="(1, Some(1))")?
  inspect((2, map.find(2)), content="(2, Some(2))")?
  inspect((42, map.find(42)), content="(42, Some(42))")?
  inspect((43, map.find(43)), content="(43, None)")?
}
