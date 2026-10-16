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

// Callback order of `HashMap::map` (#4357). Slot order is unspecified, so
// these tests compare `map` with `each` and `iter` on the same map rather
// than hard-coding keys.

///|
priv struct SlotKey(Int32, Int32) derive(Eq)

///|
impl Hash for SlotKey with fn hash(self) {
  let SlotKey(_, hash) = self
  hash
}

///|
impl Hash for SlotKey with fn hash_combine(self, hasher) {
  let SlotKey(_, hash) = self
  hasher.combine_int(hash)
}

///|
fn[K, V] each_pairs(m : @hashmap.HashMap[K, V]) -> Array[(K, V)] {
  let pairs = []
  m.each((k, v) => pairs.push((k, v)))
  pairs
}

///|
fn[K, V] iter_keys(m : @hashmap.HashMap[K, V]) -> Array[K] {
  m.iter().map(p => p.0).to_array()
}

///|
fn[T : Eq] assert_same(actual : Array[T], expected : Array[T]) -> Unit raise {
  assert_true(actual == expected)
}

///|
/// `map` visits the same keys as `each` and `iter`, and the values it writes
/// record that visit order.
fn[K : Eq, V] assert_map_order(m : @hashmap.HashMap[K, V]) -> Unit raise {
  let expected = each_pairs(m).map(p => p.0)
  assert_same(iter_keys(m), expected)
  let seen = []
  let mut n = 0
  let mapped = m.map((k, v) => {
    seen.push(k)
    let tag = n
    n += 1
    (tag, v)
  })
  assert_same(seen, expected)
  let tags = []
  mapped.each((_, pair) => tags.push(pair.0))
  assert_same(tags, [ for i in 0..<expected.length() => i ])
}

///|
/// Raising on `stop` reports that key and does not visit anything `each`
/// would visit after it. `self` is unchanged.
fn[K : Eq, V : Eq] assert_map_stops(
  m : @hashmap.HashMap[K, V],
  stop : K,
) -> Unit raise {
  let before = each_pairs(m)
  let mut index = -1
  for i in 0..<before.length() {
    if before[i].0 == stop {
      index = i
      break
    }
  }
  guard index >= 0 else { fail("stop key is not in the map") }
  let seen = []
  let msg = try {
    ignore(
      m.map((k, v) => {
        seen.push(k)
        if k == stop {
          raise Failure("stop")
        }
        v
      }),
    )
    fail("expected Failure")
  } catch {
    Failure(msg) => msg
  }
  assert_true(msg == "stop")
  let prefix = []
  for i in 0..<=index {
    prefix.push(before[i].0)
  }
  assert_same(seen, prefix)
  assert_same(each_pairs(m), before)
}

///|
test "HashMap::map callback order matches each and iter" {
  let empty : @hashmap.HashMap[Int32, Int32] = HashMap([])
  assert_map_order(empty)
  assert_map_order(@hashmap.from_array([(7, 1)]))
  let grown : @hashmap.HashMap[Int32, Int32] = HashMap([], capacity=2)
  for i in 0..<40 {
    grown.set(i, i)
  }
  assert_map_order(grown)
  for i in 0..<40 {
    if i % 3 == 0 {
      grown.remove(i)
    }
  }
  for i in 0..<40 {
    if i % 3 == 0 {
      grown.set(i, i + 1000)
    }
  }
  assert_map_order(grown)
  // Every key hashes to 1, so the probe chain is one collision cluster.
  let collided : @hashmap.HashMap[SlotKey, Int32] = HashMap([])
  for i in 0..<10 {
    collided.set(SlotKey(i, 1), i)
  }
  assert_map_order(collided)
}

///|
test "HashMap::map stops at the raising key" {
  let m = @hashmap.from_array([(0, "a"), (1, "b"), (2, "c"), (3, "d"), (4, "e")])
  let order = each_pairs(m).map(p => p.0)
  assert_map_stops(m, order[0])
  assert_map_stops(m, order[order.length() / 2])
  assert_map_stops(m, order[order.length() - 1])
  let collided : @hashmap.HashMap[SlotKey, Int32] = HashMap([])
  for i in 0..<6 {
    collided.set(SlotKey(i, 0), i)
  }
  let collided_order = each_pairs(collided).map(p => p.0)
  assert_map_stops(collided, collided_order[0])
  assert_map_stops(collided, collided_order[3])
  assert_map_stops(collided, collided_order[collided_order.length() - 1])
}
