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
test "add of a present key does not grow a full Set" {
  let set : Set[Int32] = Set([])
  for i in 0..<set.grow_at {
    set.add(i)
  }
  let buckets = set.capacity
  inspect(set.size == set.grow_at, content="true")
  for i in 0..<set.size {
    set.add(i)
    assert_false(set.add_and_check(i))
  }
  assert_true(set.capacity == buckets)
  // The next new key still triggers growth, and order is preserved.
  assert_true(set.add_and_check(set.size))
  assert_true(set.capacity == buckets * 2)
  assert_true(set.iter().collect() == [0, 1, 2, 3, 4, 5, 6])
}

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
test "adding the key that triggers growth compares each key once" {
  let set : Set[Collide] = Set([])
  for i in 0..<set.grow_at {
    set.add(Collide(i))
  }
  let size = set.size
  let buckets = set.capacity
  collide_eq_calls.val = 0
  set.add(Collide(size))
  assert_true(set.capacity == buckets * 2)
  // Every existing key shares the hash, so one probe compares each once;
  // re-probing after growing would compare them all a second time.
  assert_true(collide_eq_calls.val == size)
  for i in 0..<=size {
    assert_true(set.contains(Collide(i)))
  }
}
