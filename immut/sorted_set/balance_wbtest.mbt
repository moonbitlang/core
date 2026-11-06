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
/// Number of nodes on the longest root-to-leaf path (0 for `Empty`).
fn[A] height(t : SortedSet[A]) -> Int32 {
  match t {
    Empty => 0
    Node(left~, right~, ..) => {
      let hl = height(left)
      let hr = height(right)
      1 + (if hl > hr { hl } else { hr })
    }
  }
}

///|
/// Whether every node caches the right `size` and satisfies the size-balance
/// condition that `balance` checks: its subtrees hold fewer than 2 elements
/// in total, or neither holds more than `DELTA` times as many as the other.
fn[A] is_balanced(t : SortedSet[A]) -> Bool {
  match t {
    Empty => true
    Node(left~, right~, size~, ..) => {
      let ln = left.length()
      let rn = right.length()
      size == ln + rn + 1 &&
      (ln + rn < 2 || (ln <= DELTA * rn && rn <= DELTA * ln)) &&
      is_balanced(left) &&
      is_balanced(right)
    }
  }
}

///|
/// `is_balanced`, plus elements in strictly ascending order.
fn[A : Compare] is_valid(t : SortedSet[A]) -> Bool {
  let values = t.to_array()
  for i in 1..<values.length() {
    if values[i - 1] >= values[i] {
      return false
    }
  }
  is_balanced(t)
}

///|
/// `(left size, right size)` of every node, in pre-order, whose subtrees
/// break the size-balance condition checked by `is_balanced`.
fn[A] unbalanced_nodes(t : SortedSet[A]) -> Array[(Int32, Int32)] {
  let acc = []
  fn go(t : SortedSet[A]) {
    guard t is Node(left~, right~, ..) else { return }
    let ln = left.length()
    let rn = right.length()
    if ln + rn >= 2 && (ln > DELTA * rn || rn > DELTA * ln) {
      acc.push((ln, rn))
    }
    go(left)
    go(right)
  }

  go(t)
  acc
}

///|
/// The tree's shape: `(left value right)`, with `_` for `Empty`.
fn[A : Show] shape(t : SortedSet[A]) -> String {
  match t {
    Empty => "_"
    Node(left~, value~, right~, ..) =>
      "(\{shape(left)} \{value} \{shape(right)})"
  }
}

///|
test "remove rebalances: minimal repro" {
  // With the old (5, 1) parameters, removing 0 left a node with subtree
  // sizes (0, 2).
  let mut s : SortedSet[Int32] = new()
  for v in [1, 0, 5, 3, 6, 2, 7] {
    s = s.add(v)
  }
  @debug.debug_inspect(
    unbalanced_nodes(s),
    content=(
      #|[]
    ),
  )
  let s = s.remove(0)
  @debug.debug_inspect(
    unbalanced_nodes(s),
    content=(
      #|[]
    ),
  )
  inspect(is_valid(s), content="true")
  inspect(
    shape(s),
    content=(
      #|((_ 1 (_ 2 _)) 3 ((_ 5 _) 6 (_ 7 _)))
    ),
  )
}

///|
test "height of sequentially built sets" {
  let mut asc : SortedSet[Int32] = new()
  let mut desc : SortedSet[Int32] = new()
  let mut window : SortedSet[Int32] = new()
  for i in 0..<50000 {
    asc = asc.add(i)
    desc = desc.add(-i)
  }
  // a sliding window: always 50 000 live values once full
  for i in 0..<100000 {
    window = window.add(i)
    if i >= 50000 {
      window = window.remove(i - 50000)
    }
  }
  // the ideal height for 50 000 elements is 16
  inspect(height(asc), content="21")
  inspect(height(desc), content="21")
  inspect(height(window), content="21")
  inspect(height(from_iter((0).until(50000))), content="21")
  inspect(is_balanced(asc) && is_balanced(desc), content="true")
  inspect(is_balanced(window), content="true")
}

///|
/// A seeded linear congruential generator, so failures reproduce.
priv struct Lcg {
  mut state : UInt32
}

///|
/// A pseudo-random number in `[0, bound)`.
fn Lcg::below(self : Lcg, bound : Int32) -> Int32 {
  self.state = self.state * 1103515245U + 12345U
  ((self.state >> 8) % bound.reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// A set of up to `n` random values below `range`, built with `add`.
fn Lcg::small_set(self : Lcg, n : Int32, range : Int32) -> SortedSet[Int32] {
  let mut s : SortedSet[Int32] = new()
  for _ in 0..<self.below(n + 1) {
    s = s.add(self.below(range))
  }
  s
}

///|
fn model_values(model : Array[Bool]) -> Array[Int32] {
  let values = []
  for v, present in model {
    if present {
      values.push(v)
    }
  }
  values
}

///|
test "random operation sequences keep every node balanced" {
  for seed in 0U..<12U {
    let rng = Lcg::{ state: seed, }
    let range = [16, 200, 1500][seed.reinterpret_as_int() % 3]
    let model = Array::make(range, false)
    let mut s : SortedSet[Int32] = new()
    for step in 0..<600 {
      let v = rng.below(range)
      match rng.below(18) {
        0..<=5 => {
          s = s.add(v)
          model[v] = true
        }
        6..<=10 => {
          s = s.remove(v)
          model[v] = false
        }
        11 => {
          // a sparse random predicate
          let modulus = 2 + rng.below(5)
          let drop = rng.below(modulus)
          s = s.filter(x => x % modulus != drop)
          for i in 0..<range {
            if i % modulus == drop {
              model[i] = false
            }
          }
        }
        12 => {
          // drop a whole range, which can leave the tree lopsided
          let hi = v + rng.below(range - v + 1)
          s = s.filter(x => x < v || x >= hi)
          for i in v..<hi {
            model[i] = false
          }
        }
        13 => {
          let other = rng.small_set(40, range)
          s = if rng.below(2) == 0 { s.union(other) } else { other.union(s) }
          for x in other {
            model[x] = true
          }
        }
        14 => {
          let other = rng.small_set(40, range)
          s = s.difference(other)
          for x in other {
            model[x] = false
          }
        }
        15 => {
          // keep a random superset of a fraction of the set, so the
          // intersection is large
          let other = s
            .filter(x => x % 4 != v % 4)
            .union(rng.small_set(40, range))
          s = s.intersection(other)
          for i in 0..<range {
            model[i] = model[i] && other.contains(i)
          }
        }
        16 => {
          let other = rng.small_set(40, range)
          s = s.symmetric_difference(other)
          for x in other {
            model[x] = !model[x]
          }
        }
        _ => {
          let (l, found, r) = s.split(v)
          assert_true(is_valid(l) && is_valid(r), msg="split at step \{step}")
          @test.assert_eq(found, model[v])
          // `l` and `r` are disjoint and ordered, so `union` reaches `join`
          s = if s.length() % 2 == 0 { l.union(r) } else { r.union(l) }
          model[v] = false
        }
      }
      assert_true(is_valid(s), msg="seed \{seed}, step \{step}")
      @test.assert_eq(s.to_array(), model_values(model))
    }
    // `remove_min` down to empty
    while !s.is_empty() {
      s = s.remove_min()
      assert_true(is_valid(s), msg="seed \{seed}, remove_min")
    }
  }
}

///|
fn ascending_set(lo : Int32, n : Int32) -> SortedSet[Int32] {
  let mut s : SortedSet[Int32] = new()
  for i in lo..<(lo + n) {
    s = s.add(i)
  }
  s
}

///|
fn descending_set(lo : Int32, n : Int32) -> SortedSet[Int32] {
  let mut s : SortedSet[Int32] = new()
  for i = lo + n - 1; i >= lo; i = i - 1 {
    s = s.add(i)
  }
  s
}

///|
test "join of every small size pair stays balanced" {
  // `join` is the full-rebalance path behind the set algebra, `split`,
  // `filter` and `map`.
  for a in 0..<=60 {
    for b in 0..<=60 {
      let lefts = [
        ascending_set(0, a),
        descending_set(0, a),
        SortedSet(Array::makei(a, i => i)),
      ]
      let rights = [ascending_set(a + 1, b), descending_set(a + 1, b)]
      for l in lefts {
        for r in rights {
          let j = join(l, a, r)
          assert_true(is_valid(j), msg="join of sizes \{a} and \{b}")
          @test.assert_eq(j.length(), a + b + 1)
          // `concat` (no pivot) goes through `join` as well
          let c = l.concat(r)
          assert_true(is_valid(c), msg="concat of sizes \{a} and \{b}")
          @test.assert_eq(c.length(), a + b)
        }
      }
    }
  }
}

///|
test "map rebuilds a balanced tree" {
  let s = SortedSet(Array::makei(2000, i => i))
  // order-preserving: `try_join` joins directly
  let doubled = s.map(x => x * 2)
  inspect(is_valid(doubled), content="true")
  // order-scrambling with collisions: `try_join` falls back to `union`
  let folded = s.map(x => x * 7919 % 500)
  inspect(folded.length(), content="500")
  inspect(is_valid(folded), content="true")
}
