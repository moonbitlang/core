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

// A callback that modifies the map it is traversing gets an unspecified
// result, but the result must stay memory-safe: its structure has to satisfy
// the invariants that `to_array` and the probe loops rely on.

///|
/// Checks the structure without trusting it: the list walk is bounded, and
/// every node must sit in the table at the slot its successor (or `tail`)
/// names, with a `psl` that matches that slot.
fn[K, V] assert_well_formed(m : Map[K, V]) -> Unit raise {
  let mut count = 0
  let mut prev = -1
  let mut x = m.head
  while x is Some(entry) {
    assert_true(count < m.capacity)
    assert_true(entry.prev == prev)
    let slot = match entry.next {
      Some(next) => next.prev
      None => m.tail
    }
    assert_true(slot >= 0 && slot < m.capacity)
    assert_true(m.entries[slot] is Some(e) && physical_equal(e, entry))
    assert_true(entry.psl == ((slot - entry.hash) & m.capacity_mask))
    count += 1
    prev = slot
    x = entry.next
  }
  assert_true(count == m.size)
  assert_true(m.entries.iter().filter(e => e is Some(_)).count() == m.size)
  assert_true(m.size < m.capacity)
}

///|
/// Checks the result, then that it stays well-formed through later use.
fn assert_well_formed_in_use(m : Map[Int32, Int32]) -> Unit raise {
  assert_well_formed(m)
  assert_true(m.to_array().length() == m.size)
  for i in 1000..<1100 {
    m.set(i, i)
  }
  assert_well_formed(m)
  for i in 1000..<1050 {
    m.remove(i)
  }
  assert_well_formed(m)
  m.retain((k, _) => k % 2 == 0)
  assert_well_formed(m)
  assert_true(m.to_array().length() == m.size)
}

///|
test "Map::map: callback clears the source" {
  let m = Map([(1, 1), (2, 2), (3, 3)])
  let r = m.map((_, v) => {
    m.clear()
    v
  })
  assert_well_formed_in_use(r)
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
  assert_well_formed_in_use(r)
}

///|
test "Map::map: callback removes later keys" {
  let m = Map([(1, 1), (2, 2), (3, 3), (4, 4)])
  let r = m.map((k, v) => {
    if k == 1 {
      m.remove(2)
      m.remove(3)
    }
    v
  })
  assert_well_formed_in_use(r)
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
  assert_well_formed_in_use(r)
}

///|
test "Map::map: a non-mutating callback copies the structure" {
  let m = Map([(1, 1), (2, 2), (3, 3)])
  m.remove(2)
  m.set(4, 4)
  let r = m.map((_, v) => v * 10)
  assert_well_formed(r)
  assert_true(r.to_array() == [(1, 10), (3, 30), (4, 40)])
  assert_well_formed_in_use(r)
}
