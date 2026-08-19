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
// `SortedSet`, focused on the split/join based set operations
// (`difference`, `intersection`, `symmetric_difference`, `union`).
// Blackbox tests can only observe symptoms (wrong membership, wrong
// iteration order); these tests recursively verify the internal invariants
// of every node in every operation result, so latent corruption (a stale
// cached height, an unbalanced subtree that merely degrades performance,
// a size counter that drifted, a node shared with an input tree) is caught
// directly.
//
// Invariants checked (see `check_invariants`):
//  1. BST order with full min/max bounds propagation (checking only the
//     immediate children would miss violations deeper in the tree).
//  2. AVL balance: |height(left) - height(right)| <= 1 at every node.
//  3. Cached height: the stored `height` field equals the recomputed
//     true height (leaf = 1).
//  4. The set-level `size` field equals the actual node count.

///|
/// Recursively checks one node. `lower`/`upper` are exclusive bounds
/// inherited from ancestors. Returns (recomputed_height, node_count).
fn check_node(
  node : Node[Int]?,
  lower : Int?,
  upper : Int?,
) -> (Int, Int) raise {
  match node {
    None => (0, 0)
    Some(n) => {
      if lower is Some(lo) && n.value <= lo {
        fail("BST order violated: value \{n.value} <= lower bound \{lo}")
      }
      if upper is Some(hi) && n.value >= hi {
        fail("BST order violated: value \{n.value} >= upper bound \{hi}")
      }
      let (lh, lc) = check_node(n.left, lower, Some(n.value))
      let (rh, rc) = check_node(n.right, Some(n.value), upper)
      let true_height = 1 + max(lh, rh)
      if n.height != true_height {
        fail(
          "stale cached height at value \{n.value}: stored \{n.height}, actual \{true_height}",
        )
      }
      let bal = lh - rh
      if bal > 1 || bal < -1 {
        fail(
          "AVL balance violated at value \{n.value}: left height \{lh}, right height \{rh}",
        )
      }
      (true_height, lc + rc + 1)
    }
  }
}

///|
/// Verifies every structural invariant of the whole set.
fn check_invariants(set : SortedSet[Int]) -> Unit raise {
  let (_, count) = check_node(set.root, None, None)
  if count != set.size {
    fail(
      "size field out of sync: stored \{set.size}, actual node count \{count}",
    )
  }
}

///|
/// Minimal deterministic splitmix64 PRNG so the whitebox test needs no
/// extra package imports (importing `quickcheck` here would pull in a
/// package that itself depends on `sorted_set`).
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
/// Builds two random sets over `key_space`, runs the four set operations,
/// and checks that every result satisfies the structural invariants and has
/// the size the array model predicts, that the inputs are left intact, and
/// that the results stay valid under further mutation.
fn set_ops_scenario(
  seed : UInt64,
  size_a : Int,
  size_b : Int,
  key_space : Int,
) -> Unit raise {
  let rng = Rand::{ state: seed }
  let a : SortedSet[Int] = new_sorted_set()
  let b : SortedSet[Int] = new_sorted_set()
  for _ in 0..<size_a {
    a.add(rng.below(key_space))
  }
  for _ in 0..<size_b {
    b.add(rng.below(key_space))
  }
  check_invariants(a)
  check_invariants(b)
  let a0 = a.to_array()
  let b0 = b.to_array()
  let mut shared = 0
  for x in a0 {
    if b.contains(x) {
      shared += 1
    }
  }
  let d = a.difference(b)
  let i = a.intersection(b)
  let s = a.symmetric_difference(b)
  let u = a.union(b)
  for result in [d, i, s, u] {
    check_invariants(result)
  }
  @test.assert_eq(d.length(), a0.length() - shared)
  @test.assert_eq(i.length(), shared)
  @test.assert_eq(s.length(), a0.length() + b0.length() - 2 * shared)
  @test.assert_eq(u.length(), a0.length() + b0.length() - shared)
  // the inputs are untouched, structurally and in content
  check_invariants(a)
  check_invariants(b)
  @test.assert_eq(a.to_array(), a0)
  @test.assert_eq(b.to_array(), b0)
  // the results stay valid trees under further mutation, and mutating them
  // never leaks into the inputs (they would if nodes were shared)
  for result in [d, i, s, u] {
    for _ in 0..<20 {
      result.add(rng.below(key_space))
      result.remove(rng.below(key_space))
      check_invariants(result)
    }
  }
  @test.assert_eq(a.to_array(), a0)
  @test.assert_eq(b.to_array(), b0)
}

///|
test "set operations keep invariants (heavy overlap)" {
  for seed in 1..<=5 {
    set_ops_scenario(seed.to_uint64() * 0x9E3779B9UL, 120, 120, 60)
  }
}

///|
test "set operations keep invariants (sparse overlap, deeper trees)" {
  for seed in 1..<=3 {
    set_ops_scenario(0xDEADBEEFUL + seed.to_uint64(), 200, 150, 5000)
  }
}

///|
test "set operations keep invariants (asymmetric sizes)" {
  for seed in 1..<=3 {
    set_ops_scenario(0xC0FFEEUL + seed.to_uint64(), 300, 7, 400)
    set_ops_scenario(0xF00DUL + seed.to_uint64(), 7, 300, 400)
  }
}

///|
test "set operations with self and empty keep invariants" {
  let rng = Rand::{ state: 77UL }
  let a : SortedSet[Int] = new_sorted_set()
  for _ in 0..<150 {
    a.add(rng.below(500))
  }
  let empty : SortedSet[Int] = new_sorted_set()
  for
    result in [
      a.difference(a),
      a.intersection(a),
      a.symmetric_difference(a),
      a.difference(empty),
      empty.difference(a),
      a.intersection(empty),
      a.symmetric_difference(empty),
      empty.symmetric_difference(a),
    ] {
    check_invariants(result)
  }
  @test.assert_eq(a.difference(a).length(), 0)
  @test.assert_eq(a.intersection(a).to_array(), a.to_array())
  @test.assert_eq(a.symmetric_difference(a).length(), 0)
  check_invariants(a)
  check_invariants(empty)
}
