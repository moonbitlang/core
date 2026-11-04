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

// A callback that modifies the map it is traversing gets unspecified results,
// but the results must stay memory-safe and well-formed.

///|
test "Map::map: callback clears the source" {
  let m = Map([(1, "a"), (2, "b")])
  let r = m.map((_, v) => {
    m.clear()
    v + "!"
  })
  inspect(r.length(), content="2")
  @debug.debug_inspect(
    r.to_array(),
    content=(
      #|[(1, "a!"), (2, "b!")]
    ),
  )
  inspect(m.length(), content="0")
}

///|
test "Map::map: callback grows the source" {
  let m = Map([(1, 1), (2, 2), (3, 3), (4, 4)])
  let r = m.map((k, v) => {
    if k == 1 {
      for i in 100..<200 {
        m.set(i, i)
      }
    }
    v * 10
  })
  inspect(r.length(), content="4")
  @debug.debug_inspect(
    r.to_array(),
    content="[(1, 10), (2, 20), (3, 30), (4, 40)]",
  )
  for k in 1..<=4 {
    @debug.debug_inspect(r.get(k), content="Some(\{k * 10})")
  }
  r.set(5, 50)
  @debug.debug_inspect(r.get(5), content="Some(50)")
  inspect(m.length(), content="104")
}

///|
test "Map::map: callback re-adds the current key" {
  let m = Map([(1, 1), (2, 2), (3, 3)])
  let r = m.map((k, v) => {
    if k == 1 {
      m.remove(1)
      m.set(1, v)
    }
    v * 10
  })
  @debug.debug_inspect(r.to_array(), content="[(1, 10), (2, 20), (3, 30)]")
  @debug.debug_inspect(m.to_array(), content="[(2, 2), (3, 3), (1, 1)]")
}

///|
test "Map::filter: callback re-adds the current key" {
  let m = Map([(1, 1), (2, 2), (3, 3)])
  let r = m.filter((k, v) => {
    if k == 1 {
      m.remove(1)
      m.set(1, v)
    }
    true
  })
  inspect(r.length(), content="3")
  @debug.debug_inspect(r.to_array(), content="[(1, 1), (2, 2), (3, 3)]")
}

///|
test "Map::filter: callback replaces the value it is given" {
  let m = Map([(1, 10), (2, 20)])
  let r = m.filter((k, v) => {
    m.set(k, 99)
    v == 10 || v == 20
  })
  @debug.debug_inspect(r.to_array(), content="[(1, 10), (2, 20)]")
  @debug.debug_inspect(m.to_array(), content="[(1, 99), (2, 99)]")
}

///|
test "Map::map: values are read as each key is reached" {
  let m = Map([(1, 10), (2, 20)])
  let r = m.map((k, v) => {
    if k == 1 {
      m.set(2, 99)
    }
    v
  })
  @debug.debug_inspect(r.to_array(), content="[(1, 10), (2, 99)]")
}
