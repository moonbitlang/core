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

// The reference model for `@set.Set` is a plain array holding the keys in
// their documented iteration order: insertion order, where re-adding a key
// that is already present keeps its original position, and removing then
// re-adding a key moves it to the end.

///|
fn model_add(model : Array[Int], key : Int) -> Unit {
  // Re-adding an existing key keeps its original position.
  if !model.contains(key) {
    model.push(key)
  }
}

///|
fn model_remove(model : Array[Int], key : Int) -> Unit {
  match model.search(key) {
    Some(i) => model.remove(i) |> ignore
    None => ()
  }
}

///|
fn first_occurrences(xs : Array[Int]) -> Array[Int] {
  let result : Array[Int] = []
  for x in xs {
    if !result.contains(x) {
      result.push(x)
    }
  }
  result
}

///|
fn agrees_with_model(set : @set.Set[Int], model : Array[Int]) -> Bool {
  if set.length() != model.length() || set.is_empty() != model.is_empty() {
    return false
  }
  // Full iteration order must match, not just set equality.
  if set.to_array() != model {
    return false
  }
  // Membership must agree over the small key space, including absent keys...
  for k in -31..<32 {
    if set.contains(k) != model.contains(k) {
      return false
    }
  }
  // ...and hold for every model key, even ones outside that range.
  for k in model {
    if !set.contains(k) {
      return false
    }
  }
  true
}

///|
test "quickcheck: add/remove sequences agree with an ordered array model" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let set : @set.Set[Int] = Set([])
      let model : Array[Int] = []
      for op in ops {
        // A small key space deliberately re-adds present keys and removes
        // absent ones; a third of the ops are removals so keys churn through
        // the linked list repeatedly.
        let key = op.0 % 31
        if op.1 % 3 == 0 {
          if set.remove_and_check(key) != model.contains(key) {
            return false
          }
          model_remove(model, key)
        } else {
          if set.add_and_check(key) != !model.contains(key) {
            return false
          }
          model_add(model, key)
        }
        if !agrees_with_model(set, model) {
          return false
        }
      }
      true
    },
    count=200,
  )
}

///|
test "quickcheck: unlinking head, tail, and middle keeps the chain intact" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let model = first_occurrences(xs.map(x => x % 31))
      let set = @set.Set(model)
      guard set.to_array() == model else { return false }
      while model.length() > 0 {
        // Rotate through removing the first, last, and middle element of the
        // current order, then re-add it (must land at the end) and remove it
        // again so the set shrinks by one element per round.
        let idx = match model.length() % 3 {
          0 => 0
          1 => model.length() - 1
          _ => model.length() / 2
        }
        let key = model[idx]
        set.remove(key)
        model.remove(idx) |> ignore
        if set.to_array() != model {
          return false
        }
        set.add(key)
        model.push(key)
        if set.to_array() != model {
          return false
        }
        set.remove(key)
        model.pop() |> ignore
      }
      set.is_empty() && set.to_array() == []
    },
    count=200,
  )
}

///|
test "quickcheck: construction keeps first-occurrence order and iterators agree" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let keys = xs.map(x => x % 31)
      let expected = first_occurrences(keys)
      let set = @set.Set(keys)
      let via_each : Array[Int] = []
      set.each(k => via_each.push(k))
      let via_eachi : Array[Int] = []
      let mut indices_ok = true
      set.eachi((i, k) => {
        if i != via_eachi.length() {
          indices_ok = false
        }
        via_eachi.push(k)
      })
      set.length() == expected.length() &&
      set.to_array() == expected &&
      set.iter().to_array() == expected &&
      via_each == expected &&
      via_eachi == expected &&
      indices_ok &&
      @set.from_iter(keys.iter()).to_array() == expected &&
      set.copy().to_array() == expected &&
      set == Set(expected)
    },
    count=300,
  )
}

///|
test "quickcheck: set algebra matches array references, order included" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int])) => {
      let (xs, ys) = input
      let a_keys = first_occurrences(xs.map(x => x % 31))
      let b_keys = first_occurrences(ys.map(x => x % 31))
      let a = @set.Set(a_keys)
      let b = @set.Set(b_keys)
      // union: elements of `a` in order, then novel elements of `b` in order.
      let union_ref = a_keys.copy()
      for k in b_keys {
        if !union_ref.contains(k) {
          union_ref.push(k)
        }
      }
      // intersection/difference: elements of `a` in order, filtered.
      let inter_ref = a_keys.filter(k => b_keys.contains(k))
      let diff_ref = a_keys.filter(k => !b_keys.contains(k))
      // symmetric difference: `a`-only elements, then `b`-only elements.
      let sym_ref = [..diff_ref, ..b_keys.filter(k => !a_keys.contains(k))]
      a.union(b).to_array() == union_ref &&
      a.intersection(b).to_array() == inter_ref &&
      a.difference(b).to_array() == diff_ref &&
      a.symmetric_difference(b).to_array() == sym_ref &&
      (a | b).to_array() == union_ref &&
      (a & b).to_array() == inter_ref &&
      (a - b).to_array() == diff_ref &&
      (a ^ b).to_array() == sym_ref &&
      a.is_disjoint(b) == inter_ref.is_empty() &&
      a.is_subset(b) == diff_ref.is_empty() &&
      a.is_superset(b) == b_keys.iter().all(k => a_keys.contains(k)) &&
      // The operands must be undisturbed by the operations above.
      a.to_array() == a_keys &&
      b.to_array() == b_keys
    },
    count=200,
  )
}

///|
test "quickcheck: insertion order survives repeated rehashing" {
  @quickcheck.check((xs : Array[Int]) => {
    let set : @set.Set[Int] = Set([])
    let model : Array[Int] = []
    // Churn a small key space first so the linked list contains entries that
    // were removed and re-added before any growth happens.
    for x in xs {
      let key = x % 31
      if x % 3 == 0 {
        set.remove(key)
        model_remove(model, key)
      } else {
        set.add(key)
        model_add(model, key)
      }
    }
    // Push far past the default capacity (8) to force several rehashes, with
    // interleaved removals so growth also relinks a chain with holes.
    for i in 0..<400 {
      let key = 100 + i
      set.add(key)
      model_add(model, key)
      if i % 17 == 0 && model.length() > 0 {
        let victim = model[i % model.length()]
        set.remove(victim)
        model_remove(model, victim)
      }
    }
    set.capacity() >= 512 && agrees_with_model(set, model)
  })
}
