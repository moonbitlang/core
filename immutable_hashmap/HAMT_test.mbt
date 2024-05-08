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
  for i = 0, map = Map::make(); i < 20; i = i + 1, map = map.add(i, i) {
    @assertion.assert_eq(map.size(), i)?
  } else {
    @assertion.assert_eq(map.add(0, 0).size(), 20)?
  }
}

test "HAMT" {
  let map = loop 0, Map::make() {
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
  let map = loop 0, Map::make() {
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
