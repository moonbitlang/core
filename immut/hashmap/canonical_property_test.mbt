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
// the map is `==` to a fresh `from_iter` of its content — and, at the end,
// to a rebuild by `add` in reverse order. Each regime below picks a hash
// quotient that stresses a different part of the trie: distinct hashes
// (plain `Int`), first-segment collisions (`CollidingKey`), maximum-depth
// divergence and collisions (`DeepKey`), and a single all-keys bucket
// (`ZeroHashKey`).

///|
/// Keys that all share the one and only full-hash collision bucket.
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
fn[K : Eq + Hash] canonical_after_ops(
  mk : (Int) -> K,
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
        match op_code {
          5 => {
            // union: the right-hand side's value wins
            hm = hm.union(other)
            for kv in other_model {
              model_add(model, kv.0, kv.1)
            }
          }
          6 => {
            // intersection: keys in both, values from the right-hand side
            hm = hm.intersection(other)
            model.retain(kv => model_lookup(other_model, kv.0) is Some(_))
            for i, kv in model {
              guard model_lookup(other_model, kv.0) is Some(v) else {
                return false
              }
              model[i] = (kv.0, v)
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
  @quickcheck.check((ops : Array[Int]) => canonical_after_ops(n => n, ops))
}

///|
test "quickcheck: canonical after every op (first-segment collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => CollidingKey(n), ops)
  })
}

///|
test "quickcheck: canonical after every op (maximum-depth collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => DeepKey(n), ops)
  })
}

///|
test "quickcheck: canonical after every op (single collision bucket)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => ZeroHashKey(n), ops)
  })
}
