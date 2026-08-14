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

// Whitebox structural-invariant tests for the mutable AVL tree behind
// `SortedMap`. Blackbox tests can only observe symptoms (wrong lookups,
// wrong iteration order); these tests recursively verify the internal
// invariants of every node after every mutation, so latent corruption
// (a stale cached height, an unbalanced subtree that merely degrades
// performance, a size counter that drifted) is caught at the operation
// that introduced it.
//
// Invariants checked (see `check_invariants`):
//  1. BST order with full min/max bounds propagation (checking only the
//     immediate children would miss violations deeper in the tree).
//  2. AVL balance: |height(left) - height(right)| <= 1 at every node.
//  3. Cached height: the stored `height` field equals the recomputed
//     true height (leaf = 1).
//  4. The map-level `size` field equals the actual node count.

///|
/// Recursively checks one node. `lower`/`upper` are exclusive bounds
/// inherited from ancestors. Returns (recomputed_height, node_count).
fn check_node(
  node : Node[Int, Int]?,
  lower : Int?,
  upper : Int?,
) -> (Int, Int) raise {
  match node {
    None => (0, 0)
    Some(n) => {
      if lower is Some(lo) && n.key <= lo {
        fail("BST order violated: key \{n.key} <= lower bound \{lo}")
      }
      if upper is Some(hi) && n.key >= hi {
        fail("BST order violated: key \{n.key} >= upper bound \{hi}")
      }
      let (lh, lc) = check_node(n.left, lower, Some(n.key))
      let (rh, rc) = check_node(n.right, Some(n.key), upper)
      let true_height = 1 + max(lh, rh)
      if n.height != true_height {
        fail(
          "stale cached height at key \{n.key}: stored \{n.height}, actual \{true_height}",
        )
      }
      let bal = lh - rh
      if bal > 1 || bal < -1 {
        fail(
          "AVL balance violated at key \{n.key}: left height \{lh}, right height \{rh}",
        )
      }
      (true_height, lc + rc + 1)
    }
  }
}

///|
/// Verifies every structural invariant of the whole map.
fn check_invariants(map : SortedMap[Int, Int]) -> Unit raise {
  let (_, count) = check_node(map.root, None, None)
  if count != map.size {
    fail(
      "size field out of sync: stored \{map.size}, actual node count \{count}",
    )
  }
}

///|
/// Minimal deterministic splitmix64 PRNG so the whitebox test needs no
/// extra package imports (importing `quickcheck` here would pull in a
/// package that itself depends on `sorted_map`).
priv struct Rand {
  mut state : UInt64
}

///|
fn Rand::next(self : Rand) -> UInt64 {
  self.state += 0x9E3779B97F4A7C15UL
  let mut z = self.state
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL
  z = (z ^ (z >> 27)) * 0x94D049BB133111EBUL
  z ^ (z >> 31)
}

///|
/// Uniform-ish integer in [0, limit).
fn Rand::below(self : Rand, limit : Int) -> Int {
  (self.next() & 0x7FFFFFFFUL).to_int() % limit
}

///|
/// Checks that the map agrees with a naive model: same length, same
/// lookups over the whole key space, and ascending iteration order.
fn check_against_model(
  map : SortedMap[Int, Int],
  model : Map[Int, Int],
  key_space : Int,
) -> Unit raise {
  @test.assert_eq(map.length(), model.length())
  for k in 0..<key_space {
    @test.assert_eq(map.get(k), model.get(k))
  }
  let mut prev : Int? = None
  map.each((k, _) => {
    if prev is Some(p) {
      @test.assert_eq(p < k, true)
      prev = Some(k)
    } else {
      prev = Some(k)
    }
  })
}

///|
/// Random interleaved set/remove/update_or_default sequences over a small
/// key space (lots of collisions and removes of absent keys), invariants
/// checked after every single operation.
fn random_ops_scenario(seed : UInt64, ops : Int, key_space : Int) -> Unit raise {
  let rng = Rand::{ state: seed }
  let map : SortedMap[Int, Int] = new_sorted_map()
  let model : Map[Int, Int] = Map([])
  for i in 0..<ops {
    let k = rng.below(key_space)
    match rng.below(10) {
      0..=5 => {
        let v = rng.below(1000)
        map.set(k, v)
        model[k] = v
      }
      6..=8 => {
        map.remove(k)
        model.remove(k)
      }
      _ => {
        map.update_or_default(k, 1, x => x + 1)
        model[k] = match model.get(k) {
          Some(x) => x + 1
          None => 1
        }
      }
    }
    check_invariants(map)
    @test.assert_eq(map.length(), model.length())
    if i % 32 == 31 {
      check_against_model(map, model, key_space)
    }
  }
  check_against_model(map, model, key_space)
}

///|
test "random ops keep invariants (small key space, heavy collisions)" {
  for seed in 1..<=6 {
    random_ops_scenario(seed.to_uint64() * 0x9E3779B9UL, 300, 31)
  }
}

///|
test "random ops keep invariants (large key space, deeper trees)" {
  for seed in 1..<=3 {
    random_ops_scenario(0xDEADBEEFUL + seed.to_uint64(), 400, 1009)
  }
}

///|
test "ascending inserts keep invariants" {
  let map : SortedMap[Int, Int] = new_sorted_map()
  for i in 0..<300 {
    map.set(i, i)
    check_invariants(map)
  }
  @test.assert_eq(map.length(), 300)
}

///|
test "descending inserts keep invariants" {
  let map : SortedMap[Int, Int] = new_sorted_map()
  for i in 0..<300 {
    map.set(300 - i, i)
    check_invariants(map)
  }
  @test.assert_eq(map.length(), 300)
}

///|
test "zigzag inserts keep invariants" {
  let map : SortedMap[Int, Int] = new_sorted_map()
  for i in 0..<150 {
    map.set(i, i)
    check_invariants(map)
    map.set(1000 - i, i)
    check_invariants(map)
  }
  @test.assert_eq(map.length(), 300)
}

///|
test "ascending inserts then ascending removals keep invariants" {
  let map : SortedMap[Int, Int] = new_sorted_map()
  for i in 0..<300 {
    map.set(i, i)
  }
  check_invariants(map)
  for i in 0..<300 {
    map.remove(i)
    check_invariants(map)
  }
  @test.assert_eq(map.length(), 0)
  @test.assert_eq(map.root is None, true)
}

///|
test "repeated root removal keeps invariants" {
  let map : SortedMap[Int, Int] = new_sorted_map()
  let rng = Rand::{ state: 42UL }
  for _ in 0..<300 {
    map.set(rng.below(100000), 0)
  }
  check_invariants(map)
  while map.root is Some(n) {
    map.remove(n.key)
    check_invariants(map)
  }
  @test.assert_eq(map.length(), 0)
}

///|
test "from_array and clear keep invariants" {
  let rng = Rand::{ state: 7UL }
  for round in 0..<20 {
    let n = round * 13 + 1
    let arr = Array::makei(n, _ => (rng.below(97), rng.below(1000)))
    let map = SortedMap::SortedMap(arr)
    check_invariants(map)
    // last write wins for duplicate keys
    let model : Map[Int, Int] = Map([])
    for e in arr {
      model[e.0] = e.1
    }
    check_against_model(map, model, 97)
    map.clear()
    check_invariants(map)
    @test.assert_eq(map.root is None, true)
    @test.assert_eq(map.length(), 0)
  }
}

///|
test "copy, merge and merge_in_place keep invariants" {
  let rng = Rand::{ state: 99UL }
  let a : SortedMap[Int, Int] = new_sorted_map()
  let b : SortedMap[Int, Int] = new_sorted_map()
  for _ in 0..<200 {
    a.set(rng.below(500), rng.below(1000))
    b.set(rng.below(500), rng.below(1000))
  }
  check_invariants(a)
  check_invariants(b)
  let c = a.copy()
  check_invariants(c)
  @test.assert_eq(c.length(), a.length())
  let merged = a.merge(b)
  check_invariants(merged)
  // merge must not disturb its inputs
  check_invariants(a)
  check_invariants(b)
  c.merge_in_place(b)
  check_invariants(c)
  @test.assert_eq(c.length(), merged.length())
  // merged trees agree entry-by-entry
  @test.assert_eq(c.to_array(), merged.to_array())
}

///|
test "range agrees with model and leaves tree intact" {
  let rng = Rand::{ state: 1234UL }
  let map : SortedMap[Int, Int] = new_sorted_map()
  for _ in 0..<300 {
    map.set(rng.below(1000), 1)
  }
  check_invariants(map)
  for _ in 0..<50 {
    let x = rng.below(1000)
    let y = rng.below(1000)
    let (lo, hi) = if x <= y { (x, y) } else { (y, x) }
    let via_range = []
    for k, _ in map.range(lo, hi) {
      via_range.push(k)
    }
    let via_filter = []
    map.each((k, _) => if k >= lo && k <= hi { via_filter.push(k) })
    @test.assert_eq(via_range, via_filter)
  }
  check_invariants(map)
}
