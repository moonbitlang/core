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

// Structural `Eq` is a valid proxy for content equality only if every
// operation keeps the trie canonical: one shape per content, regardless of
// history. This property sweep drives random operation sequences against
// an association-array model and requires, after every single step, that
// the map is `==` to a fresh `from_iter` of its content, hashes like it,
// iterates exactly its content, and compares UNEQUAL to perturbed content
// — and, at the end, that a rebuild by `add` in reverse order reproduces
// it. Each regime below picks a hash quotient that stresses a different
// part of the trie: distinct hashes (plain `Int`), segment-1 divergence
// with full collisions (`CollidingKey`), mid-trie segment-3 divergence
// (`MidDepthKey`), maximum-depth divergence and collisions (`DeepKey`),
// and a single all-keys bucket (`ZeroHashKey`).

///|
/// Keys whose hash lives only in path segment 3 (bits 10..=14): all keys
/// share segments 1-2 and diverge — or fully collide — at mid-trie depth.
priv struct MidDepthKey(Int) derive(Eq)

///|
impl Hash for MidDepthKey with fn hash(self) {
  (self.0 & 3) << 10
}

///|
impl Hash for MidDepthKey with fn hash_combine(self, hasher) {
  hasher.combine_int((self.0 & 3) << 10)
}

///|
/// Keys that all share the one and only collision bucket.
priv struct ZeroHashKey(Int) derive(Eq)

///|
impl Hash for ZeroHashKey with fn hash(_) {
  0
}

///|
impl Hash for ZeroHashKey with fn hash_combine(_, hasher) {
  hasher.combine_int(0)
}

///|
/// Replace-or-append, mirroring `HashMap::add`.
fn model_add(model : Array[(Int, Int)], key : Int, value : Int) -> Unit {
  for i, kv in model {
    if kv.0 == key {
      model[i] = (key, value)
      return
    }
  }
  model.push((key, value))
}

///|
fn model_remove(model : Array[(Int, Int)], key : Int) -> Unit {
  for i, kv in model {
    if kv.0 == key {
      let _ = model.remove(i)
      return
    }
  }
}

///|
fn model_lookup(model : Array[(Int, Int)], key : Int) -> Int? {
  for kv in model {
    if kv.0 == key {
      return Some(kv.1)
    }
  }
  None
}

///|
/// Interpret `ops` as a stream of map operations over a 16-key universe,
/// mirror each on the model, and require full canonicity after every step.
/// `un` projects a key back to the underlying `Int` (for iteration
/// comparison against the model).
fn[K : Eq + Hash] canonical_after_ops(
  mk : (Int) -> K,
  un : (K) -> Int,
  ops : Array[Int],
) -> Bool {
  let model : Array[(Int, Int)] = []
  let mut hm : @hashmap.HashMap[K, Int] = @hashmap.new()
  for op in ops {
    let n = op & 0x7fffffff
    let key = n / 8 % 16
    let value = n / 128 % 7
    match n % 8 {
      0 | 1 | 2 => {
        hm = hm.add(mk(key), value)
        model_add(model, key, value)
      }
      3 => {
        hm = hm.remove(mk(key))
        model_remove(model, key)
      }
      4 => {
        // The predicate must be expressible on the model too, so filter on
        // the value (an `Int` in both worlds).
        hm = hm.filter((_, v) => (v + key) % 3 != 0)
        model.retain(kv => (kv.1 + key) % 3 != 0)
      }
      op_code => {
        // A second map derived from a slice of the current content plus
        // one possibly-fresh key, built canonically via `from_iter`.
        let other_model : Array[(Int, Int)] = []
        for kv in model {
          if (kv.0 + key) % 3 != 0 {
            model_add(other_model, kv.0, kv.1 + 1)
          }
        }
        model_add(other_model, key, value)
        let other = @hashmap.from_iter(
          other_model.iter().map(kv => (mk(kv.0), kv.1)),
        )
        // The key's parity picks between the plain and the `_with`
        // flavor of the merge, so both trie walks get exercised.
        let merge = (x : Int, y : Int) => x * 2 + y
        match op_code {
          5 =>
            if key % 2 == 0 {
              // union: the right-hand side's value wins
              hm = hm.union(other)
              for kv in other_model {
                model_add(model, kv.0, kv.1)
              }
            } else {
              // union_with: merge values of keys present on both sides
              hm = hm.union_with(other, (_, x, y) => merge(x, y))
              for kv in other_model {
                match model_lookup(model, kv.0) {
                  Some(v0) => model_add(model, kv.0, merge(v0, kv.1))
                  None => model_add(model, kv.0, kv.1)
                }
              }
            }
          6 => {
            // intersection keeps keys in both; the plain flavor takes the
            // right-hand side's value, `_with` merges both
            if key % 2 == 0 {
              hm = hm.intersection(other)
            } else {
              hm = hm.intersection_with(other, (_, x, y) => merge(x, y))
            }
            model.retain(kv => model_lookup(other_model, kv.0) is Some(_))
            for i, kv in model {
              guard model_lookup(other_model, kv.0) is Some(v) else {
                return false
              }
              model[i] = (kv.0, if key % 2 == 0 { v } else { merge(kv.1, v) })
            }
          }
          _ => {
            // difference: keys of the left-hand side absent from the right
            hm = hm.difference(other)
            model.retain(kv => model_lookup(other_model, kv.0) is None)
          }
        }
      }
    }
    // Content agreement guards the model itself…
    if hm.length() != model.length() {
      return false
    }
    for kv in model {
      if hm.get(mk(kv.0)) != Some(kv.1) {
        return false
      }
    }
    // …and this is the canonicity property: same content, same structure.
    let rebuilt = @hashmap.from_iter(model.iter().map(kv => (mk(kv.0), kv.1)))
    if hm != rebuilt {
      return false
    }
    // Equal content must also hash equally, under every collision regime
    let h1 = Hasher()
    h1.combine(hm)
    let h2 = Hasher()
    h2.combine(rebuilt)
    if h1.finalize() != h2.finalize() {
      return false
    }
    // The iterator must produce exactly the model's content
    let iterated = hm.to_array().map(kv => (un(kv.0), kv.1))
    iterated.sort()
    let expected = model.map(kv => kv)
    expected.sort()
    if iterated != expected {
      return false
    }
    // Different content must compare unequal: perturb by adding a fresh
    // key, removing an entry, and changing a value
    if hm.add(mk(16), 0) == rebuilt {
      return false
    }
    if model.length() > 0 {
      let (k0, v0) = model[0]
      if hm.remove(mk(k0)) == rebuilt {
        return false
      }
      if hm.add(mk(k0), v0 + 1) == rebuilt {
        return false
      }
    }
  }
  // Insertion-order independence: adding the final content in reverse
  // order must reproduce the exact structure.
  let mut reversed : @hashmap.HashMap[K, Int] = @hashmap.new()
  for i in 0..<model.length() {
    let kv = model[model.length() - 1 - i]
    reversed = reversed.add(mk(kv.0), kv.1)
  }
  reversed == hm
}

///|
test "quickcheck: canonical after every op (distinct hashes)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => n, k => k, ops)
  })
}

///|
test "quickcheck: canonical after every op (first-segment collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => CollidingKey(n), k => k.0, ops)
  })
}

///|
test "quickcheck: canonical after every op (mid-depth collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => MidDepthKey(n), k => k.0, ops)
  })
}

///|
test "quickcheck: canonical after every op (maximum-depth collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => DeepKey(n), k => k.0, ops)
  })
}

///|
test "quickcheck: canonical after every op (single collision bucket)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => ZeroHashKey(n), k => k.0, ops)
  })
}

///|
/// Build a map from an `add` stream over the 16-key universe.
fn[K : Eq + Hash] build_map(
  mk : (Int) -> K,
  xs : Array[Int],
) -> @hashmap.HashMap[K, Int] {
  let mut m = @hashmap.new()
  for x in xs {
    let n = x & 0x7fffffff
    m = m.add(mk(n % 16), n / 16 % 7)
  }
  m
}

///|
/// Algebraic laws of the merge operations, stated with structural `==` —
/// which canonicity makes a valid way to compare independently computed
/// results.
fn[K : Eq + Hash] map_laws(
  mk : (Int) -> K,
  input : (Array[Int], Array[Int], Array[Int]),
) -> Bool {
  let (xs, ys, zs) = input
  let a = build_map(mk, xs)
  let b = build_map(mk, ys)
  let c = build_map(mk, zs)
  let empty : @hashmap.HashMap[K, Int] = @hashmap.new()
  // union: associative, idempotent, empty is the identity
  guard a.union(b).union(c) == a.union(b.union(c)) else { return false }
  guard a.union(a) == a else { return false }
  guard a.union(empty) == a && empty.union(a) == a else { return false }
  // union is right-biased, per key
  let u = a.union(b)
  for i in 0..<18 {
    let k = mk(i)
    let expected = match b.get(k) {
      Some(v) => Some(v)
      None => a.get(k)
    }
    guard u.get(k) == expected else { return false }
  }
  // union_with is symmetric under a commutative merge function
  let merged_lr = a.union_with(b, (_, x, y) => x + y)
  let merged_rl = b.union_with(a, (_, x, y) => x + y)
  guard merged_lr == merged_rl else { return false }
  // intersection: idempotent; keeps keys in both with right-side values
  guard a.intersection(a) == a else { return false }
  let inter = a.intersection(b)
  for i in 0..<18 {
    let k = mk(i)
    let expected = if a.contains(k) { b.get(k) } else { None }
    guard inter.get(k) == expected else { return false }
  }
  // left-biased intersection is difference of differences
  let left_biased = a.intersection_with(b, (_, x, _) => x)
  guard left_biased == a.difference(a.difference(b)) else { return false }
  // difference: self-annihilating; subtracting a union is subtracting twice
  guard a.difference(a) == empty else { return false }
  guard a.difference(b).difference(c) == a.difference(b.union(c)) else {
    return false
  }
  true
}

///|
test "quickcheck: merge-operation laws (distinct hashes)" {
  @quickcheck.check((input : (Array[Int], Array[Int], Array[Int])) => {
    map_laws(n => n, input)
  })
}

///|
test "quickcheck: merge-operation laws (maximum-depth collisions)" {
  @quickcheck.check((input : (Array[Int], Array[Int], Array[Int])) => {
    map_laws(n => DeepKey(n), input)
  })
}
