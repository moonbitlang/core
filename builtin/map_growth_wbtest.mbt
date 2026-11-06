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
/// A key whose hash always collides, counting equality checks.
priv struct Collide(Int32)

///|
priv struct Counter {
  mut val : Int32
}

///|
let collide_eq_calls : Counter = { val: 0, }

///|
impl Hash for Collide with fn hash(_) {
  0
}

///|
impl Hash for Collide with fn hash_combine(_, hasher) {
  hasher.combine_int(0)
}

///|
impl Eq for Collide with fn equal(self, other) {
  collide_eq_calls.val += 1
  self.0 == other.0
}

///|
/// Fill `map` with colliding keys up to its growth threshold.
fn fill_to_threshold(map : Map[Collide, Int32]) -> Unit {
  for i = 0; map.size < map.grow_at; i = i + 1 {
    map.set(Collide(i), i)
  }
}

///|
test "set of the key that triggers growth compares each key once" {
  let map : Map[Collide, Int32] = Map([])
  fill_to_threshold(map)
  let size = map.size
  let buckets = map.capacity
  collide_eq_calls.val = 0
  map.set(Collide(size), size)
  assert_true(map.capacity == buckets * 2)
  // Every existing key shares the hash, so one probe compares each once;
  // re-probing after growing would compare them all a second time.
  assert_true(collide_eq_calls.val == size)
  for i in 0..<=size {
    assert_true(map.get(Collide(i)) == Some(i))
  }
}

///|
test "update_or_default of the key that triggers growth compares each key once" {
  let map : Map[Collide, Int32] = Map([])
  fill_to_threshold(map)
  let size = map.size
  let buckets = map.capacity
  collide_eq_calls.val = 0
  map.update_or_default(Collide(size), -1, v => v + 1)
  assert_true(map.capacity == buckets * 2)
  assert_true(collide_eq_calls.val == size)
  for i in 0..<size {
    assert_true(map.get(Collide(i)) == Some(i))
  }
  assert_true(map.get(Collide(size)) == Some(-1))
}
