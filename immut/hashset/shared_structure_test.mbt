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
/// Set operations between a set and versions derived from it (so the two
/// share most of their structure) must agree with a model and stay
/// canonical; no-op updates must return the very same set.
fn[A : Eq + Hash] derived_versions_agree(
  mk : (Int) -> A,
  input : (Array[Int], Array[Int]),
) -> Bool {
  let (xs, edits) = input
  let model : Array[Int] = []
  let mut a : @hashset.HashSet[A] = @hashset.new()
  for x in xs {
    let k = (x & 0x7fffffff) % 16
    a = a.add(mk(k))
    model_insert(model, k)
  }
  // No-op updates return the same set.
  for k in model {
    guard physical_equal(a.add(mk(k)), a) else { return false }
  }
  for k in 0..<16 {
    if !model.contains(k) {
      guard physical_equal(a.remove(mk(k)), a) else { return false }
    }
  }
  // Derive `b` from `a` by a few edits.
  let mut b = a
  let b_model = model.copy()
  for e in edits {
    let k = (e & 0x7fffffff) / 2 % 16
    if e % 2 == 0 {
      b = b.add(mk(k))
      model_insert(b_model, k)
    } else {
      b = b.remove(mk(k))
      model_delete(b_model, k)
    }
  }
  let rebuild = (m : Array[Int]) => @hashset.from_iter(m.iter().map(mk))
  let union_model = model.copy()
  for k in b_model {
    model_insert(union_model, k)
  }
  a.union(b) == rebuild(union_model) &&
  b.union(a) == rebuild(union_model) &&
  a.intersection(b) == rebuild(model.filter(k => b_model.contains(k))) &&
  a.difference(b) == rebuild(model.filter(k => !b_model.contains(k))) &&
  b.difference(a) == rebuild(b_model.filter(k => !model.contains(k))) &&
  a.union(a) == a &&
  a.intersection(a) == a &&
  a.difference(a) == @hashset.new()
}

///|
test "quickcheck: derived versions (distinct hashes)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_versions_agree(n => n, input)
  })
}

///|
test "quickcheck: derived versions (first-segment collisions)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_versions_agree(n => CollidingElem(n), input)
  })
}

///|
test "quickcheck: derived versions (mid-depth collisions)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_versions_agree(n => MidDepthElem(n), input)
  })
}

///|
test "quickcheck: derived versions (maximum-depth collisions)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_versions_agree(n => DeepElem(n), input)
  })
}

///|
test "quickcheck: derived versions (single collision bucket)" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    derived_versions_agree(n => ZeroHashElem(n), input)
  })
}
