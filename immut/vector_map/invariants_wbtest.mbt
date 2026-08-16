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

// The public tests pin down what the map means; these pin down what it is.
// Nothing observable distinguishes a spine full of unreclaimed holes from a
// dense one, so the bounds that keep the representation from degrading — the
// index agreeing with the spine both ways, no trailing tombstone, holes never
// outnumbering entries past the threshold — have to be asserted from inside.

///|
/// Every representation invariant from the doc comment on `VectorMap`, as a
/// single predicate. Returns the first failure as a message so that a property
/// counterexample says which invariant broke.
fn[K : Eq + Hash + Show, V] check_invariants(map : VectorMap[K, V]) -> String? {
  let length = map.spine.length()
  // `size` counts exactly the live slots.
  let mut live = 0
  map.spine.each(entry => if entry is Some(_) { live += 1 })
  guard live == map.size else {
    return Some("size is \{map.size} but the spine holds \{live} entries")
  }
  // The index holds exactly the live keys…
  guard map.index.length() == map.size else {
    return Some(
      "index holds \{map.index.length()} keys for \{map.size} entries",
    )
  }
  // …and each one points at a slot carrying that same key.
  for key, slot in map.index {
    guard slot >= 0 && slot < length else {
      return Some("key \{key} points at slot \{slot}, outside 0..<\{length}")
    }
    guard map.spine.get(slot) is Some(Some((slot_key, _))) else {
      return Some("key \{key} points at slot \{slot}, which is a tombstone")
    }
    guard slot_key == key else {
      return Some("key \{key} points at slot \{slot}, which holds \{slot_key}")
    }
  }
  // Conversely every live slot is reachable through the index, at that slot —
  // this is the direction that catches an index left stale by a rebuild.
  let mut failure = None
  map.spine.eachi((slot, entry) => {
    if entry is Some((key, _)) {
      if map.index.get(key) != Some(slot) {
        failure = Some(
          "slot \{slot} holds \{key}, which the index sends elsewhere",
        )
      }
    }
  })
  guard failure is None else { return failure }
  // A non-empty spine never ends on a hole, so an empty map is empty underneath.
  if length > 0 {
    guard map.spine.get(length - 1) is Some(Some(_)) else {
      return Some("the spine ends on a tombstone")
    }
  }
  // Holes stay bounded once the spine is long enough to be worth rebuilding.
  if length >= MIN_COMPACT_LENGTH && length - map.size > map.size {
    return Some("\{length - map.size} holes against \{map.size} entries")
  }
  None
}

///|
test "invariants hold through a deletion-heavy operation sequence" {
  @quickcheck.check(
    (ops : Array[Int]) => {
      let mut map : VectorMap[Int, Int] = new()
      for op in ops {
        let n = op & 0x7fffffff
        let key = n / 8 % 24
        match n % 6 {
          0 | 1 => map = map.add(key, n % 7)
          2 | 3 | 4 => map = map.remove(key)
          _ => map = map.filter((k, _) => k % 3 != 0)
        }
        guard check_invariants(map) is None else { return false }
      }
      true
    },
    count=300,
  )
}

///|
test "invariants hold while the spine is churned around the threshold" {
  // Alternating growth and shrinkage across `MIN_COMPACT_LENGTH` is where
  // trimming, the compaction trigger and the index rebuild interact.
  @quickcheck.check(
    (raw : Array[Int]) => {
      let mut map : VectorMap[Int, Int] = new()
      let mut next = 0
      for n in raw {
        // `abs` would overflow on `Int::min_value`; masking cannot.
        let count = (n & 0x7fffffff) % 12 + 1
        // grow
        for _ in 0..<count {
          map = map.add(next, next)
          next += 1
          guard check_invariants(map) is None else { return false }
        }
        // shrink, oldest first, so the holes open at the front where trimming
        // cannot reach them
        for k in (next - count * 2)..<next {
          if k >= 0 && n % 3 != 0 {
            map = map.remove(k)
            guard check_invariants(map) is None else { return false }
          }
        }
      }
      true
    },
    count=200,
  )
}

///|
test "trailing removals shrink the spine instead of leaving holes" {
  let map = from_iter((0).until(10).map(i => (i, i)))
  inspect(map.spine.length(), content="10")
  // Dropping the last entry must pop it, not tombstone it…
  let popped = map.remove(9)
  inspect(popped.spine.length(), content="9")
  // …and the trim keeps going over holes it uncovers.
  let mut chained = map.remove(7).remove(8)
  inspect(chained.spine.length(), content="10")
  chained = chained.remove(9)
  inspect(chained.spine.length(), content="7")
  assert_true(check_invariants(chained) is None)
}

///|
test "the spine is rebuilt once the holes outnumber the entries" {
  let map = from_iter((0).until(100).map(i => (i, i)))
  inspect(map.spine.length(), content="100")
  // Removing 49 of the first 99 leaves 51 entries against 49 holes: still
  // above the ratio, so nothing has been rebuilt yet.
  let mut punched = map
  for i in 0..<49 {
    punched = punched.remove(i * 2)
  }
  inspect(punched.length(), content="51")
  inspect(punched.spine.length(), content="100")
  // Level pegging does not tip it either: the trigger is a strict majority of
  // holes, so 50 against 50 still leaves the spine alone.
  punched = punched.remove(98)
  inspect(punched.length(), content="50")
  inspect(punched.spine.length(), content="100")
  // One more hole does tip it, and the spine collapses onto the live entries.
  punched = punched.remove(97)
  inspect(punched.length(), content="49")
  inspect(punched.spine.length(), content="49")
  assert_true(check_invariants(punched) is None)
  // The rebuilt index still resolves every survivor.
  for k, v in punched {
    assert_true(punched.get(k) == Some(v))
  }
}

///|
test "a short spine is left alone however holey it gets" {
  // Below the threshold the ratio is not worth a rebuild, so the holes stay.
  let map = from_iter((0).until(10).map(i => (i, i)))
  let mut punched = map
  for i in 0..<9 {
    punched = punched.remove(i)
  }
  inspect(punched.length(), content="1")
  inspect(punched.spine.length(), content="10")
  assert_true(check_invariants(punched) is None)
  // Emptying it entirely still leaves nothing behind, because the trim runs
  // regardless of the threshold.
  punched = punched.remove(9)
  inspect(punched.spine.length(), content="0")
  assert_true(punched.is_empty())
}

///|
test "appending can be what tips the spine into a rebuild" {
  // A spine of 31 slots holding one entry is under `MIN_COMPACT_LENGTH`, so
  // nothing reclaims its 30 holes. Appending one more entry carries it to 32,
  // at which point the ratio is wildly over the limit — so `add` has to test
  // for compaction too, not just `remove`.
  let mut map = from_iter((0).until(31).map(i => (i, i)))
  for i in 0..<30 {
    map = map.remove(i)
  }
  inspect(map.length(), content="1")
  inspect(map.spine.length(), content="31")
  assert_true(check_invariants(map) is None)
  let appended = map.add(100, 100)
  inspect(appended.length(), content="2")
  inspect(appended.spine.length(), content="2")
  assert_true(check_invariants(appended) is None)
  // …and the rebuild kept the order and every lookup
  @debug.debug_inspect(appended.to_array(), content="[(30, 30), (100, 100)]")
}

///|
test "churn under add and remove keeps reclaiming the spine" {
  // Drives the ratio repeatedly rather than once, so a compaction that only
  // worked from a pristine spine would show up here.
  let mut map = from_iter((0).until(40).map(i => (i, i)))
  let mut compactions = 0
  for round in 0..<12 {
    let before = map.spine.length()
    // remove two thirds of what is there, oldest first…
    for k, _ in map.to_array()[:map.length() * 2 / 3] {
      map = map.remove(k)
    }
    // …and append fresh keys, which land past the holes
    for j in 0..<8 {
      map = map.add(1000 + round * 8 + j, j)
    }
    if map.spine.length() < before {
      compactions += 1
    }
    assert_true(check_invariants(map) is None)
  }
  assert_true(compactions > 0)
  // The surviving entries are still exactly what the operations left.
  for k, v in map {
    assert_true(map.get(k) == Some(v))
  }
}

///|
test "the simple constructors produce valid representations" {
  let empty : VectorMap[String, Int] = new()
  assert_true(check_invariants(empty) is None)
  assert_true(check_invariants(singleton("a", 1)) is None)
  assert_true(
    check_invariants(VectorMap([("a", 1), ("b", 2), ("a", 3)])) is None,
  )
  assert_true(
    check_invariants(from_iter((0).until(40).map(i => (i, i)))) is None,
  )
}

///|
test "map shares the index rather than rebuilding it" {
  // Values change, slots do not, so the trie is handed straight over. This is
  // what keeps a value-only transform off the hash path entirely.
  let map = from_iter((0).until(40).map(i => (i, i)))
  let mapped = map.map((_, v) => v * 2)
  assert_true(physical_equal(mapped.index, map.index))
  assert_true(check_invariants(mapped) is None)
}
