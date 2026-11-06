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
test "new" {
  let m : HashMap[Int32, Int32] = HashMap([])
  inspect(m.capacity, content="8")
  inspect(m.length(), content="0")
}

///|
test "merge_in_place self-aliasing should be no-op" {
  let map : HashMap[String, Int32] = HashMap([])
  // With 4 elements: capacity=8, size=4
  // The grow condition is size >= capacity/2, i.e., 4 >= 4
  // Without fix, merge_in_place(map) calls set_with_hash which triggers grow()
  for i in 0..<4 {
    map.set(i.to_string(), i)
  }
  let cap_before = map.capacity
  @test.assert_eq(cap_before, 8) // Verify initial state
  @test.assert_eq(map.length(), 4)
  // Merging with self should be a no-op - capacity should NOT grow from 8 to 16
  map.merge_in_place(map)
  @test.assert_eq(map.capacity, cap_before)
  @test.assert_eq(map.length(), 4)
  // Verify all entries are still correct
  for i in 0..<4 {
    @test.assert_eq(map.get(i.to_string()), Some(i))
  }
}

///|
test "set updating existing key should not grow" {
  let map : HashMap[String, Int32] = HashMap([])
  // Fill to exactly at grow threshold: capacity=8, size=4
  for i in 0..<4 {
    map.set(i.to_string(), i)
  }
  @test.assert_eq(map.capacity, 8)
  @test.assert_eq(map.length(), 4)
  // Update existing keys - should NOT trigger grow
  for i in 0..<4 {
    map.set(i.to_string(), i * 10)
  }
  @test.assert_eq(map.capacity, 8) // Should still be 8, not 16
  @test.assert_eq(map.length(), 4)
  // Verify values were updated
  for i in 0..<4 {
    @test.assert_eq(map.get(i.to_string()), Some(i * 10))
  }
}

///|
test "filter sizes the result for the kept entries" {
  let m : HashMap[Int32, Int32] = HashMap([ for i in 0..<10000 => (i, i) ])
  for keep in [0, 1, 10, 5000, 10000] {
    let kept = m.filter((k, _) => k < keep)
    let rebuilt = HashMap([ for k, v in m if k < keep => (k, v) ])
    @test.assert_eq(kept.length(), keep)
    @test.assert_eq(kept.capacity, rebuilt.capacity)
  }
}

///|
test "retain visits each entry once when a cluster wraps around the table" {
  let m : HashMap[Int32, Int32] = HashMap([])
  let mask = m.capacity - 1
  // Two keys whose home is the last slot: the second one wraps to slot 0.
  let keys = []
  for k = 0; keys.length() < 2; k = k + 1 {
    if (Hash::hash(k) & mask) == mask {
      keys.push(k)
    }
  }
  m.set(keys[0], 0)
  m.set(keys[1], 1)
  let calls = HashMap([])
  m.retain((k, _) => {
    calls.set(k, calls.get_or_default(k, 0) + 1)
    k != keys[0]
  })
  @debug.debug_inspect(calls.get(keys[0]), content="Some(1)")
  @debug.debug_inspect(calls.get(keys[1]), content="Some(1)")
  @debug.debug_inspect(m.to_array(), content="[(\{keys[1]}, 1)]")
}

///|
test "capacity" {
  let m = HashMap([])
  inspect(m.capacity, content="8")
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("d", 4)
  m.set("e", 5)
  m.set("f", 6)
  m.set("g", 7)
  m.set("h", 8)
  inspect(m.capacity, content="16")
}
