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

// Callback order of immutable `HashMap::map` (#4357). The order itself is
// unspecified, so `map` is checked against `each`, `iter`, and `fold` on
// the same map, including a collision bucket.

///|
priv struct Collide(String) derive(Eq)

///|
impl Hash for Collide with fn hash_combine(_self, hasher) {
  hasher.combine(1)
}

///|
fn[K, V] hamt_pairs(m : @hashmap.HashMap[K, V]) -> Array[(K, V)] {
  let pairs = []
  m.each((k, v) => pairs.push((k, v)))
  pairs
}

///|
fn[K, V] hamt_iter_keys(m : @hashmap.HashMap[K, V]) -> Array[K] {
  m.iter().map(p => p.0).to_array()
}

///|
fn[K, V] hamt_fold_keys(m : @hashmap.HashMap[K, V]) -> Array[K] {
  let keys = []
  m.fold(init=(), (_, k, _) => keys.push(k))
  keys
}

///|
fn[T : Eq] assert_same(actual : Array[T], expected : Array[T]) -> Unit raise {
  assert_true(actual == expected)
}

///|
fn[K : Eq, V] assert_hamt_map_order(m : @hashmap.HashMap[K, V]) -> Unit raise {
  let expected = hamt_pairs(m).map(p => p.0)
  assert_same(hamt_iter_keys(m), expected)
  assert_same(hamt_fold_keys(m), expected)
  let seen = []
  let mut n = 0
  let mapped = m.map((k, v) => {
    seen.push(k)
    let tag = n
    n += 1
    (tag, v)
  })
  assert_same(seen, expected)
  // The rebuilt tree is walked by the same traversal, so the tags come
  // back in callback order.
  let tags = []
  mapped.each((_, pair) => tags.push(pair.0))
  assert_same(tags, [ for i in 0..<n => i ])
}

///|
fn[K : Eq, V : Eq] assert_hamt_map_stops(
  m : @hashmap.HashMap[K, V],
  stop : K,
) -> Unit raise {
  let before = hamt_pairs(m)
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
  assert_same(hamt_pairs(m), before)
}

///|
test "immut HashMap::map callback order matches each, iter, and fold" {
  let empty : @hashmap.HashMap[Int32, Int32] = @hashmap.new()
  assert_hamt_map_order(empty)
  assert_hamt_map_order(@hashmap.singleton(4, 40))
  let mut grown = @hashmap.new()
  for i in 0..<24 {
    grown = grown.add(i, i)
  }
  assert_hamt_map_order(grown)
  // Removing and inserting again rebuilds the tree; the new traversal is
  // what `map` must follow.
  let mut changed = grown
  for i in 0..<24 {
    if i % 3 == 0 {
      changed = changed.remove(i)
    }
  }
  for i in 0..<24 {
    if i % 3 == 0 {
      changed = changed.add(i, i + 1000)
    }
  }
  assert_hamt_map_order(changed)
  let collided = @hashmap.HashMap([
    (Collide("a"), 1),
    (Collide("b"), 2),
    (Collide("c"), 3),
    (Collide("d"), 4),
  ])
  assert_hamt_map_order(collided)
  inspect(hamt_pairs(collided).length(), content="4")
}

///|
test "immut HashMap::map stops at the raising key" {
  let mut m = @hashmap.new()
  for i in 0..<12 {
    m = m.add(i, i)
  }
  let order = hamt_pairs(m).map(p => p.0)
  assert_hamt_map_stops(m, order[0])
  assert_hamt_map_stops(m, order[order.length() / 2])
  assert_hamt_map_stops(m, order[order.length() - 1])
  let collided = @hashmap.HashMap([
    (Collide("a"), 1),
    (Collide("b"), 2),
    (Collide("c"), 3),
    (Collide("d"), 4),
  ])
  let collided_order = hamt_pairs(collided).map(p => p.0)
  assert_hamt_map_stops(collided, collided_order[0])
  assert_hamt_map_stops(collided, collided_order[collided_order.length() - 1])
}
