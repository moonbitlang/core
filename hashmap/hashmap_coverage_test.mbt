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

// Black-box tests covering hashmap paths the existing suites miss: Robin Hood
// displacement (push-away) on collisions during set/update/update_or_default,
// specialized bytes/string lookups that miss after probing, and `Show`.

///|
/// A key whose hash deliberately maps every value into one of only 8 buckets,
/// so insertions collide heavily and deterministically (independent of the
/// runtime hash seed, which is randomized on some targets). This forces the
/// Robin Hood push-away path to run regardless of platform.
priv struct Collide(Int) derive(Eq)

///|
impl Hash for Collide with fn hash(self) {
  let Collide(x) = self
  x % 8
}

///|
impl Hash for Collide with fn hash_combine(self, hasher) {
  let Collide(x) = self
  hasher.combine_int(x % 8)
}

///|
test "set into a half-full map triggers robin hood displacement" {
  // a large capacity keeps the map below the grow threshold while the
  // collision-heavy keys force entries to be pushed away
  let m : @hashmap.HashMap[Collide, Int] = HashMap([], capacity=512)
  for i in 0..<240 {
    m.set(Collide(i), i * 10)
  }
  assert_eq(m.length(), 240)
  // every key remains retrievable after the displacements
  for i in 0..<240 {
    assert_eq(m.get(Collide(i)), Some(i * 10))
  }
  // overwriting an existing key keeps the size stable
  m.set(Collide(100), -1)
  assert_eq(m.get(Collide(100)), Some(-1))
  assert_eq(m.length(), 240)
}

///|
test "update inserts, modifies and removes through the probe chain" {
  let m : @hashmap.HashMap[Collide, Int] = HashMap([], capacity=512)
  // insert many colliding keys via update (f(None) -> Some) to force displacement
  for i in 0..<240 {
    m.update(Collide(i), v => {
      match v {
        None => Some(i)
        Some(x) => Some(x + 1)
      }
    })
  }
  assert_eq(m.length(), 240)
  // update an existing key (f(Some) -> Some)
  m.update(Collide(5), v => {
    match v {
      Some(x) => Some(x + 100)
      None => Some(0)
    }
  })
  assert_eq(m.get(Collide(5)), Some(105))
  // update that returns None for an absent key is a no-op
  m.update(Collide(10000), _ => None)
  assert_eq(m.get(Collide(10000)), None)
  assert_eq(m.length(), 240)
  // update that returns None for an existing key removes it
  m.update(Collide(5), _ => None)
  assert_eq(m.get(Collide(5)), None)
  assert_eq(m.length(), 239)
}

///|
test "update_or_default inserts and modifies through the probe chain" {
  let m : @hashmap.HashMap[Collide, Int] = HashMap([], capacity=512)
  for i in 0..<240 {
    m.update_or_default(Collide(i), 1, x => x + 1)
  }
  assert_eq(m.length(), 240)
  // all first insertions store the default (f is not applied on insert)
  for i in 0..<240 {
    assert_eq(m.get(Collide(i)), Some(1))
  }
  // a second update applies f to the existing value
  m.update_or_default(Collide(7), 1, x => x + 41)
  assert_eq(m.get(Collide(7)), Some(42))
  assert_eq(m.length(), 240)
}

///|
/// Encode a `String` as `Bytes` (the direct conversion is deprecated, but is
/// the simplest way to build many distinct byte keys here).
#warnings("-deprecated")
fn bytes_of(s : String) -> Bytes {
  s.to_bytes()
}

///|
test "get_from_bytes and get_from_string miss after probing" {
  let bytes_map : @hashmap.HashMap[Bytes, Int] = HashMap([], capacity=64)
  for i in 0..<28 {
    bytes_map.set(bytes_of("key\{i}"), i)
  }
  assert_eq(bytes_map.get_from_bytes(bytes_of("key3")), Some(3))
  // absent keys still have to walk the probe chain before reporting a miss
  for i in 0..<12 {
    assert_eq(bytes_map.get_from_bytes(bytes_of("absent\{i}")), None)
  }
  let str_map : @hashmap.HashMap[String, Int] = HashMap([], capacity=64)
  for i in 0..<28 {
    str_map.set("k\{i}", i)
  }
  assert_eq(str_map.get_from_string("k3"), Some(3))
  for i in 0..<12 {
    assert_eq(str_map.get_from_string("missing\{i}"), None)
  }
}

///|
/// Render a hashmap through its (deprecated) `Show` instance.
#warnings("-deprecated")
fn show_map(m : @hashmap.HashMap[Int, Int]) -> String {
  m.to_string()
}

///|
test "Show renders a hashmap as a from_array expression" {
  let m : @hashmap.HashMap[Int, Int] = HashMap([])
  m.set(1, 10)
  m.set(2, 20)
  let shown = show_map(m)
  assert_true(shown.has_prefix("HashMap::from_array(["))
  assert_true(shown.has_suffix("])"))
  // two entries are separated by a comma
  assert_true(shown.contains(", "))
  // an empty map still renders the wrapper
  let e : @hashmap.HashMap[Int, Int] = HashMap([])
  inspect(show_map(e), content="HashMap::from_array([])")
}
