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
// operation keeps the trie canonical: one topology per content, regardless
// of history. This property sweep drives random operation sequences
// against an array model and requires, after every single step, that the
// set is `==` to a fresh `from_iter` of its content — and, at the end, to
// a rebuild by `add` in reverse order. Each regime below picks a hash
// quotient that stresses a different part of the trie: distinct hashes
// (plain `Int`), segment-1 divergence with full collisions
// (`CollidingElem`), mid-trie segment-3 divergence (`MidDepthElem`),
// maximum-depth divergence and collisions (`DeepElem`), and a single
// all-elements bucket (`ZeroHashElem`).

///|
/// Elements whose hash lives only in path segment 3 (bits 10..=14): all
/// elements share segments 1-2 and diverge — or fully collide — at
/// mid-trie depth.
priv struct MidDepthElem(Int) derive(Eq)

///|
impl Hash for MidDepthElem with fn hash(self) {
  (self.0 & 3) << 10
}

///|
impl Hash for MidDepthElem with fn hash_combine(self, hasher) {
  hasher.combine_int((self.0 & 3) << 10)
}

///|
/// Elements that all share the one and only collision bucket.
priv struct ZeroHashElem(Int) derive(Eq)

///|
impl Hash for ZeroHashElem with fn hash(_) {
  0
}

///|
impl Hash for ZeroHashElem with fn hash_combine(_, hasher) {
  hasher.combine_int(0)
}

///|
fn model_insert(model : Array[Int], key : Int) -> Unit {
  if !model.contains(key) {
    model.push(key)
  }
}

///|
fn model_delete(model : Array[Int], key : Int) -> Unit {
  for i, k in model {
    if k == key {
      let _ = model.remove(i)
      return
    }
  }
}

///|
/// Interpret `ops` as a stream of set operations over a 16-element
/// universe, mirror each on the model, and require full canonicity after
/// every step.
fn[A : Eq + Hash] canonical_after_ops(
  mk : (Int) -> A,
  ops : Array[Int],
) -> Bool {
  let model : Array[Int] = []
  let mut hs : @hashset.HashSet[A] = @hashset.new()
  for op in ops {
    let n = op & 0x7fffffff
    let key = n / 8 % 16
    match n % 8 {
      0 | 1 | 2 => {
        hs = hs.add(mk(key))
        model_insert(model, key)
      }
      3 | 4 => {
        hs = hs.remove(mk(key))
        model_delete(model, key)
      }
      op_code => {
        // A second set derived from a slice of the current content plus
        // one possibly-fresh element, built canonically via `from_iter`.
        let other_model : Array[Int] = []
        for k in model {
          if (k + key) % 3 != 0 {
            other_model.push(k)
          }
        }
        model_insert(other_model, key)
        let other = @hashset.from_iter(other_model.iter().map(mk))
        match op_code {
          5 => {
            hs = hs.union(other)
            for k in other_model {
              model_insert(model, k)
            }
          }
          6 => {
            hs = hs.intersection(other)
            model.retain(k => other_model.contains(k))
          }
          _ => {
            hs = hs.difference(other)
            model.retain(k => !other_model.contains(k))
          }
        }
      }
    }
    // Content agreement guards the model itself…
    if hs.length() != model.length() {
      return false
    }
    for k in model {
      if !hs.contains(mk(k)) {
        return false
      }
    }
    // …and this is the canonicity property: same content, same structure.
    let rebuilt = @hashset.from_iter(model.iter().map(mk))
    if hs != rebuilt {
      return false
    }
  }
  // Insertion-order independence: adding the final content in reverse
  // order must reproduce the exact structure.
  let mut reversed : @hashset.HashSet[A] = @hashset.new()
  for i in 0..<model.length() {
    reversed = reversed.add(mk(model[model.length() - 1 - i]))
  }
  reversed == hs
}

///|
test "quickcheck: canonical after every op (distinct hashes)" {
  @quickcheck.check((ops : Array[Int]) => canonical_after_ops(n => n, ops))
}

///|
test "quickcheck: canonical after every op (first-segment collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => CollidingElem(n), ops)
  })
}

///|
test "quickcheck: canonical after every op (mid-depth collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => MidDepthElem(n), ops)
  })
}

///|
test "quickcheck: canonical after every op (maximum-depth collisions)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => DeepElem(n), ops)
  })
}

///|
test "quickcheck: canonical after every op (single collision bucket)" {
  @quickcheck.check((ops : Array[Int]) => {
    canonical_after_ops(n => ZeroHashElem(n), ops)
  })
}
