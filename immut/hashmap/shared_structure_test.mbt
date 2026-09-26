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
/// Map operations between a map and versions derived from it (so the two
/// share most of their structure) must agree with a model and stay
/// canonical; removing an absent key must return the very same map.
fn[K : Eq + Hash] derived_map_versions_agree(
  mk : (Int) -> K,
  input : (Array[Int], Array[Int]),
) -> Bool {
  let (xs, edits) = input
  let model : Array[(Int, Int)] = []
  let mut a : @hashmap.HashMap[K, Int] = @hashmap.new()
  for x in xs {
    let k = (x & 0x7fffffff) % 16
    a = a.add(mk(k), x)
    model_add(model, k, x)
  }
  for k in 0..<16 {
    if model_lookup(model, k) is None {
      guard physical_equal(a.remove(mk(k)), a) else { return false }
    }
  }
  // Derive `b` from `a` by a few edits (new values and removals).
  let mut b = a
  let b_model = model.copy()
  for e in edits {
    let k = (e & 0x7fffffff) / 2 % 16
    if e % 2 == 0 {
      b = b.add(mk(k), e)
      model_add(b_model, k, e)
    } else {
      b = b.remove(mk(k))
      model_remove(b_model, k)
    }
  }
  let rebuild = (m : Array[(Int, Int)]) => {
    @hashmap.from_iter(m.iter().map(kv => (mk(kv.0), kv.1)))
  }
  // union/intersection keep the right-hand side's value.
  let right_union = (l : Array[(Int, Int)], r : Array[(Int, Int)]) => {
    let out = l.copy()
    for kv in r {
      model_add(out, kv.0, kv.1)
    }
    out
  }
  let right_inter = (l : Array[(Int, Int)], r : Array[(Int, Int)]) => {
    r.filter(kv => model_lookup(l, kv.0) is Some(_))
  }
  let diff = (l : Array[(Int, Int)], r : Array[(Int, Int)]) => {
    l.filter(kv => model_lookup(r, kv.0) is None)
  }
  a.union(b) == rebuild(right_union(model, b_model)) &&
  b.union(a) == rebuild(right_union(b_model, model)) &&
  a.intersection(b) == rebuild(right_inter(model, b_model)) &&
  b.intersection(a) == rebuild(right_inter(b_model, model)) &&
  a.difference(b) == rebuild(diff(model, b_model)) &&
  b.difference(a) == rebuild(diff(b_model, model)) &&
  a.union(a) == a &&
  a.intersection(a) == a &&
  a.difference(a) == @hashmap.new()
}

///|
test "quickcheck: derived map versions (distinct hashes)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_map_versions_agree(n => n, input)
  })
}

///|
test "quickcheck: derived map versions (first-segment collisions)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_map_versions_agree(n => CollidingKey(n), input)
  })
}

///|
test "quickcheck: derived map versions (mid-depth collisions)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_map_versions_agree(n => MidDepthKey(n), input)
  })
}

///|
test "quickcheck: derived map versions (maximum-depth collisions)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_map_versions_agree(n => DeepKey(n), input)
  })
}

///|
test "quickcheck: derived map versions (single collision bucket)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_map_versions_agree(n => ZeroHashKey(n), input)
  })
}
