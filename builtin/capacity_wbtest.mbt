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
test "Map::merge_in_place self should not grow" {
  let map : Map[String, Int32] = Map([])
  // Add 6 entries to reach the growth threshold (default capacity 8, grow_at 6)
  for i in 0..<6 {
    map.set(i.to_string(), i)
  }
  let cap_before = map.capacity
  map.merge_in_place(map)
  // Capacity should remain unchanged since no new entries are added
  assert_true(map.capacity == cap_before)
  assert_true(map.length() == 6)
  // Verify all entries are still intact
  for i in 0..<6 {
    assert_true(map.get(i.to_string()) == Some(i))
  }
}

///|
test "Map::set updating existing key should not grow" {
  let map : Map[String, Int32] = Map([])
  // Add 6 entries to reach the growth threshold (default capacity 8, grow_at 6)
  for i in 0..<6 {
    map.set(i.to_string(), i)
  }
  inspect(map.capacity, content="8")
  inspect(map.length(), content="6")
  // Update existing keys - should NOT trigger grow
  for i in 0..<6 {
    map.set(i.to_string(), i * 10)
  }
  inspect(map.capacity, content="8") // Should still be 8, not 16
  inspect(map.length(), content="6")
  // Verify values were updated
  for i in 0..<6 {
    assert_true(map.get(i.to_string()) == Some(i * 10))
  }
}

///|
test "capacity hint reserves entries without growing" {
  for hint in [-1, 0, 1, 2, 3, 6, 7, 8, 13, 14, 15, 16, 26, 27, 1024, 15000] {
    let map : Map[Int32, Int32] = Map([], capacity=hint)
    let initial_capacity = map.capacity
    for i in 0..<hint.max(0) {
      map[i] = i
      assert_true(
        map.capacity == initial_capacity,
        msg="hint=\{hint}, key=\{i}",
      )
    }
    assert_true(map.length() == hint.max(0))
    // Reserving the same entry count as an array constructor should choose
    // the same table size, except for the default empty constructor.
    if hint > 0 {
      let from_array = Map([ for i in 0..<hint => (i, i) ])
      assert_true(map.capacity == from_array.capacity)
      assert_true(map.to_array() == from_array.to_array())
    }
  }
  // The hint counts total entries, including those supplied in the array.
  let seeded = Map([(0, 0), (1, 1)], capacity=13)
  let capacity = seeded.capacity
  for i in 2..<13 {
    seeded[i] = i
    assert_true(seeded.capacity == capacity)
  }
  inspect(seeded.length(), content="13")
  inspect(seeded.capacity, content="16")
  let smaller_hint = Map([(0, 0), (1, 1), (2, 2)], capacity=1)
  inspect(smaller_hint.capacity, content="4")
}

///|
test "filter sizes the result for the kept entries" {
  let m : Map[Int32, Int32] = Map([ for i in 0..<10000 => (i, i) ])
  for keep in [0, 1, 10, 5000, 10000] {
    let kept = m.filter((k, _) => k < keep)
    let rebuilt = Map([ for k, v in m if k < keep => (k, v) ])
    assert_true(kept.length() == keep)
    assert_true(kept.capacity == rebuilt.capacity)
  }
}
