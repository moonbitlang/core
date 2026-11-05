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
fn[K, V] height(t : SortedMap[K, V]) -> Int32 {
  match t {
    Empty => 0
    Tree(_, l, r, ..) => {
      let hl = height(l)
      let hr = height(r)
      1 + (if hl > hr { hl } else { hr })
    }
  }
}

///|
/// Whether every node caches the right `size` and satisfies the size-balance
/// condition that `balance` checks: its subtrees hold fewer than 2 nodes
/// in total, or neither holds more than `DELTA` times as many as the other.
fn[K, V] is_balanced(t : SortedMap[K, V]) -> Bool {
  match t {
    Empty => true
    Tree(_, l, r, size~, ..) => {
      let ln = l.length()
      let rn = r.length()
      size == ln + rn + 1 &&
      (ln + rn < 2 || (ln <= DELTA * rn && rn <= DELTA * ln)) &&
      is_balanced(l) &&
      is_balanced(r)
    }
  }
}

///|
/// `is_balanced`, plus keys in strictly ascending order.
fn[K : Compare, V] is_valid(t : SortedMap[K, V]) -> Bool {
  let keys = t.keys_as_iter().to_array()
  for i in 1..<keys.length() {
    if keys[i - 1] >= keys[i] {
      return false
    }
  }
  is_balanced(t)
}

///|
test "merge of ascending singletons" {
  let mut m : SortedMap[Int32, Int32] = new()
  for i in 0..<2000 {
    m = m.merge(singleton(i, i))
  }
  inspect(m.length(), content="2000")
  inspect(height(m), content="16")
  inspect(is_valid(m), content="true")
}

///|
test "merge of descending singletons" {
  let mut m : SortedMap[Int32, Int32] = new()
  for i = 2000; i > 0; i = i - 1 {
    m = m.merge(singleton(i, i))
  }
  inspect(m.length(), content="2000")
  inspect(height(m), content="16")
  inspect(is_valid(m), content="true")
}

///|
/// Merge `m` with `other` and check the result is valid and holds the same
/// entries as `m` updated with `other`'s entries one `add` at a time.
fn check_merge(
  m : SortedMap[Int32, Int32],
  other : SortedMap[Int32, Int32],
) -> SortedMap[Int32, Int32] raise {
  let merged = m.merge(other)
  assert_true(is_valid(merged))
  let mut expected = m
  for k, v in other {
    expected = expected.add(k, v)
  }
  @test.assert_eq(merged.to_array(), expected.to_array())
  merged
}

///|
test "merge keeps the tree balanced" {
  // singletons merged in on either side, ascending and descending
  let mut a : SortedMap[Int32, Int32] = new()
  let mut b : SortedMap[Int32, Int32] = new()
  let mut c : SortedMap[Int32, Int32] = new()
  for i in 0..<500 {
    a = check_merge(a, singleton(i, i))
    b = check_merge(singleton(i, i), b)
    c = check_merge(c, singleton(-i, i))
  }
  // pseudo-random keys, with duplicates
  let mut seed = 12345U
  let mut d : SortedMap[Int32, Int32] = new()
  for i in 0..<500 {
    seed = seed * 1103515245U + 12345U
    let k = (seed >> 16).reinterpret_as_int() % 300
    d = check_merge(d, singleton(k, i))
  }
  // ascending batches, interleaved maps, and very uneven sizes
  let mut e : SortedMap[Int32, Int32] = new()
  for j in 0..<20 {
    e = check_merge(e, SortedMap(Array::makei(25, i => (j * 25 + i, i))))
  }
  let evens = SortedMap(Array::makei(500, i => (2 * i, i)))
  let odds = SortedMap(Array::makei(500, i => (2 * i + 1, i)))
  check_merge(evens, odds) |> ignore
  check_merge(odds, evens) |> ignore
  let big = SortedMap(Array::makei(2000, i => (i, i)))
  let small = SortedMap([(-1, 0), (500, 0), (2000, 0)])
  check_merge(big, small) |> ignore
  check_merge(small, big) |> ignore
  // `split` shares `join` with `merge`
  for i in -1..<=2000 {
    let (l, found, r) = big.split(i)
    assert_true(is_valid(l) && is_valid(r))
    @test.assert_eq(found, if i >= 0 && i < 2000 { Some(i) } else { None })
    @test.assert_eq(
      l.length() + r.length(),
      if found is Some(_) {
        1999
      } else {
        2000
      },
    )
  }
}

///|
/// `(left size, right size)` of every node, in pre-order, whose subtrees
/// break the size-balance condition checked by `is_balanced`.
fn[K, V] unbalanced_nodes(t : SortedMap[K, V]) -> Array[(Int32, Int32)] {
  let acc = []
  fn go(t : SortedMap[K, V]) {
    guard t is Tree(_, l, r, ..) else { return }
    let ln = l.length()
    let rn = r.length()
    if ln + rn >= 2 && (ln > DELTA * rn || rn > DELTA * ln) {
      acc.push((ln, rn))
    }
    go(l)
    go(r)
  }

  go(t)
  acc
}

///|
test "filter rebuilds a balanced tree" {
  let m = SortedMap(Array::makei(2000, i => (i, i)))
  // The root is 1000: `kept` keeps it and `dropped` drops it.
  let kept = m.filter((k, _) => k == 0 || k >= 1000)
  inspect(kept.length(), content="1001")
  @debug.debug_inspect(
    unbalanced_nodes(kept),
    content=(
      #|[]
    ),
  )
  inspect(is_valid(kept), content="true")
  let dropped = m.filter((k, _) => k < 1000 || k == 1999)
  inspect(dropped.length(), content="1001")
  @debug.debug_inspect(
    unbalanced_nodes(dropped),
    content=(
      #|[]
    ),
  )
  inspect(is_valid(dropped), content="true")
}

///|
/// Filter `m` with `pred` and check the result is valid and holds exactly
/// the entries of `m` that satisfy `pred`.
fn check_filter(
  m : SortedMap[Int32, Int32],
  pred : (Int32, Int32) -> Bool,
) -> Unit raise {
  let filtered = m.filter(pred)
  assert_true(is_valid(filtered))
  @test.assert_eq(
    filtered.to_array(),
    m.to_array().filter(kv => pred(kv.0, kv.1)),
  )
}

///|
test "filter keeps the tree balanced" {
  // every subset of small maps
  for n in 0..<=12 {
    let m = SortedMap(Array::makei(n, i => (i, i)))
    for mask in 0..<(1 << n) {
      check_filter(m, (k, _) => ((mask >> k) & 1) == 1)
    }
  }
  // every contiguous range of medium maps
  for n in 13..<=40 {
    let m = SortedMap(Array::makei(n, i => (i, i)))
    for a in 0..<n {
      for b in a..<=n {
        check_filter(m, (k, _) => k >= a && k < b)
      }
    }
  }
  // lopsided predicates on a large map
  let m = SortedMap(Array::makei(2000, i => (i, i)))
  check_filter(m, (k, _) => k >= 1000)
  check_filter(m, (k, _) => k < 1000)
  check_filter(m, (k, _) => k >= 1000 && k < 1100)
  check_filter(m, (k, _) => (k >= 500 && k < 1500) || k == 0)
  check_filter(m, (k, _) => k % 100 == 0 || k >= 1500)
  check_filter(m, (k, _) => k < 10 || k >= 1990)
  check_filter(m, (k, _) => k != 1000)
  check_filter(m, (k, _) => k < 1000 || k >= 1998)
  check_filter(m, (k, _) => k <= 2 || (k > 1000 && k < 1500))
}

///|
test "remove rebalances: minimal repro" {
  // With the old (5, 1) parameters, removing 0 double-rotated the root's
  // right subtree into a node with subtree sizes (0, 2).
  let mut m : SortedMap[Int32, Int32] = new()
  for k in [1, 0, 5, 3, 6, 2, 7] {
    m = m.add(k, k)
  }
  @debug.debug_inspect(
    unbalanced_nodes(m),
    content=(
      #|[]
    ),
  )
  let m = m.remove(0)
  @debug.debug_inspect(
    unbalanced_nodes(m),
    content=(
      #|[]
    ),
  )
  inspect(is_valid(m), content="true")
  inspect(
    m.debug_tree(),
    content=(
      #|(3,3,(1,1,_,(2,2,_,_)),(6,6,(5,5,_,_),(7,7,_,_)))
    ),
  )
}

///|
test "height of sequentially built maps" {
  let mut asc : SortedMap[Int32, Int32] = new()
  let mut desc : SortedMap[Int32, Int32] = new()
  let mut window : SortedMap[Int32, Int32] = new()
  for i in 0..<50000 {
    asc = asc.add(i, i)
    desc = desc.add(-i, i)
  }
  // a sliding window: always 50 000 live keys once full
  for i in 0..<100000 {
    window = window.add(i, i)
    if i >= 50000 {
      window = window.remove(i - 50000)
    }
  }
  // the ideal height for 50 000 entries is 16
  inspect(height(asc), content="21")
  inspect(height(desc), content="21")
  inspect(height(window), content="21")
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
/// A map of up to `n` random keys below `key_range`, built with `add`.
fn Lcg::small_map(
  self : Lcg,
  n : Int32,
  key_range : Int32,
) -> SortedMap[Int32, Int32] {
  let mut m : SortedMap[Int32, Int32] = new()
  for _ in 0..<self.below(n + 1) {
    m = m.add(self.below(key_range), self.below(1000))
  }
  m
}

///|
fn model_entries(model : Array[Int32?]) -> Array[(Int32, Int32)] {
  let entries = []
  for k, v in model {
    if v is Some(v) {
      entries.push((k, v))
    }
  }
  entries
}

///|
test "random operation sequences keep every node balanced" {
  for seed in 0U..<12U {
    let rng = Lcg::{ state: seed, }
    let key_range = [16, 200, 1500][seed.reinterpret_as_int() % 3]
    let model : Array[Int32?] = Array::make(key_range, None)
    let mut m : SortedMap[Int32, Int32] = new()
    for step in 0..<600 {
      let k = rng.below(key_range)
      match rng.below(16) {
        0..<=5 => {
          let v = rng.below(1000)
          m = m.add(k, v)
          model[k] = Some(v)
        }
        6..<=10 => {
          m = m.remove(k)
          model[k] = None
        }
        11 => {
          // a sparse random predicate
          let modulus = 2 + rng.below(5)
          let drop = rng.below(modulus)
          m = m.filter((key, _) => key % modulus != drop)
          for i in 0..<key_range {
            if i % modulus == drop {
              model[i] = None
            }
          }
        }
        12 => {
          // drop a whole range, which can leave the tree lopsided
          let hi = k + rng.below(key_range - k + 1)
          m = m.filter((key, _) => key < k || key >= hi)
          for i in k..<hi {
            model[i] = None
          }
        }
        13 => {
          let other = rng.small_map(40, key_range)
          m = m.merge(other)
          for key, v in other {
            model[key] = Some(v)
          }
        }
        14 => {
          let other = rng.small_map(40, key_range)
          m = other.merge(m)
          for key, v in other {
            if model[key] is None {
              model[key] = Some(v)
            }
          }
        }
        _ => {
          let (l, found, r) = m.split(k)
          assert_true(is_valid(l) && is_valid(r), msg="split at step \{step}")
          @test.assert_eq(found, model[k])
          m = l.merge(r)
          model[k] = None
        }
      }
      assert_true(is_valid(m), msg="seed \{seed}, step \{step}")
      @test.assert_eq(m.to_array(), model_entries(model))
    }
  }
}

///|
fn ascending_map(lo : Int32, n : Int32) -> SortedMap[Int32, Int32] {
  let mut m : SortedMap[Int32, Int32] = new()
  for i in lo..<(lo + n) {
    m = m.add(i, i)
  }
  m
}

///|
fn descending_map(lo : Int32, n : Int32) -> SortedMap[Int32, Int32] {
  let mut m : SortedMap[Int32, Int32] = new()
  for i = lo + n - 1; i >= lo; i = i - 1 {
    m = m.add(i, i)
  }
  m
}

///|
test "join of every small size pair stays balanced" {
  // `join` is the full-rebalance path behind `merge`, `split` and `filter`.
  for a in 0..<=60 {
    for b in 0..<=60 {
      let lefts = [
        ascending_map(0, a),
        descending_map(0, a),
        SortedMap(Array::makei(a, i => (i, i))),
      ]
      let rights = [ascending_map(a + 1, b), descending_map(a + 1, b)]
      for l in lefts {
        for r in rights {
          let j = join(l, a, a, r)
          assert_true(is_valid(j), msg="join of sizes \{a} and \{b}")
          @test.assert_eq(j.length(), a + b + 1)
        }
      }
    }
  }
}
