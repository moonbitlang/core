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

// `SortedMap::map` used to call `f` on the current node before either
// subtree (preorder). `each`, `iter`, and `fold` walk keys in ascending
// order, and so does `map` now (#4357).

///|
/// A non-raising callback must keep `map` itself non-raising.
fn sorted_map_identity(
  m : @sorted_map.SortedMap[Int32, String],
) -> @sorted_map.SortedMap[Int32, String] {
  m.map((_, v) => v)
}

///|
fn sorted_each_keys(m : @sorted_map.SortedMap[Int32, String]) -> Array[Int32] {
  let keys = []
  m.each((k, _) => keys.push(k))
  keys
}

///|
test "SortedMap::map visits keys in ascending order" {
  let empty : @sorted_map.SortedMap[Int32, String] = @sorted_map.new()
  let seen_empty = []
  ignore(
    empty.map((k, v) => {
      seen_empty.push(k)
      v
    }),
  )
  assert_true(seen_empty == [])
  let single = @sorted_map.SortedMap([(2, "two")])
  assert_true(sorted_map_identity(single).to_array() == [(2, "two")])
  // Inserted as 3, 8, 1, 2, 0. The tree is not a right spine, so preorder
  // (3, 1, 0, 2, 8) differs from ascending order.
  let m = @sorted_map.SortedMap([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let ascending = [0, 1, 2, 3, 8]
  assert_true(sorted_each_keys(m) == ascending)
  assert_true(m.iter().map(p => p.0).to_array() == ascending)
  let folded = []
  m.fold(init=(), (_, k, _) => folded.push(k))
  assert_true(folded == ascending)
  let seen = []
  let mut n = 0
  let mapped = m.map((k, v) => {
    seen.push(k)
    let tag = n
    n += 1
    (tag, v)
  })
  assert_true(seen == ascending)
  // Tags follow visit order. `to_array` walks the same ascending order,
  // so the tags come back as 0, 1, 2, 3, 4.
  assert_true(mapped.to_array().map(kv => kv.1.0) == [0, 1, 2, 3, 4])
  assert_true(
    m.to_array() ==
    [(0, "zero"), (1, "one"), (2, "two"), (3, "three"), (8, "eight")],
  )
}

///|
test "SortedMap::map stops at the raising key" {
  let m = @sorted_map.SortedMap([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let before = m.to_array()
  let seen = []
  let msg = try {
    ignore(
      m.map((k, v) => {
        seen.push(k)
        if k == 2 {
          raise Failure("2")
        }
        v
      }),
    )
    fail("expected Failure")
  } catch {
    Failure(msg) => msg
  }
  assert_true(msg == "2")
  // 0 and 1 are the keys below 2; 3 and 8 are not visited.
  assert_true(seen == [0, 1, 2])
  assert_true(m.to_array() == before)
  let seen_first = []
  let first = try {
    ignore(
      m.map((k, v) => {
        seen_first.push(k)
        if k == 0 {
          raise Failure("0")
        }
        v
      }),
    )
    fail("expected Failure")
  } catch {
    Failure(msg) => msg
  }
  assert_true(first == "0")
  assert_true(seen_first == [0])
}
