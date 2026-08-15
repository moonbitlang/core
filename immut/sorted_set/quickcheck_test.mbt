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

// Property sweep for the persistent balanced BST set. The reference model is
// a plain array of unique elements; `agrees_with_model` is the full
// specification check: same length, every model element is contained, an
// absent probe misses, min/max match the model extremes, and `to_array`
// yields exactly the model's elements in STRICTLY ascending order — an
// externally observable witness of the BST invariant, which is what
// rotations after insert/remove and the bulk set operations must preserve.

///|
fn model_add(model : Array[Int], x : Int) -> Unit {
  if !model.contains(x) {
    model.push(x)
  }
}

///|
fn model_remove(model : Array[Int], x : Int) -> Unit {
  for i, y in model {
    if y == x {
      model.remove(i) |> ignore
      return
    }
  }
}

///|
fn sorted_model(model : Array[Int]) -> Array[Int] {
  let sorted = model.copy()
  sorted.sort()
  sorted
}

///|
fn agrees_with_model(
  set : @sorted_set.SortedSet[Int],
  model : Array[Int],
) -> Bool {
  if set.length() != model.length() {
    return false
  }
  if set.is_empty() != (model.length() == 0) {
    return false
  }
  for x in model {
    if !set.contains(x) {
      return false
    }
  }
  // An element outside the generated space must miss.
  if set.contains(1 << 20) {
    return false
  }
  let expected = sorted_model(model)
  if set.min_option() != expected.get(0) ||
    set.max_option() != expected.get(expected.length() - 1) {
    return false
  }
  let actual = set.to_array()
  for i in 1..<actual.length() {
    // Strictly ascending: sortedness AND uniqueness in one check.
    if actual[i - 1] >= actual[i] {
      return false
    }
  }
  actual == expected
}

///|
/// Build a set and its model from raw values, folding them into a small
/// space so duplicates (and later, overlaps between two sets) are common.
fn build(xs : Array[Int]) -> (@sorted_set.SortedSet[Int], Array[Int]) {
  let model : Array[Int] = []
  let values : Array[Int] = []
  for x in xs {
    let v = x % 31
    values.push(v)
    model_add(model, v)
  }
  (SortedSet(values), model)
}

///|
test "quickcheck: op sequences agree with a model and old versions persist" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let mut set : @sorted_set.SortedSet[Int] = @sorted_set.new()
      let model : Array[Int] = []
      // Snapshots of every intermediate version paired with its expected
      // content; persistence means none of them may change afterwards.
      let snapshots : Array[(@sorted_set.SortedSet[Int], Array[Int])] = [
        (set, []),
      ]
      for op in ops {
        // A small element space deliberately generates duplicate inserts
        // and removals of both present and absent elements.
        let x = op.0 % 31
        if op.1 % 4 == 0 {
          set = set.remove(x)
          model_remove(model, x)
        } else {
          set = set.add(x)
          model_add(model, x)
        }
        if !agrees_with_model(set, model) {
          return false
        }
        snapshots.push((set, model.copy()))
      }
      // Draining exercises the rebalance-after-remove path from many shapes.
      let mut drained = set
      let drained_model = sorted_model(model)
      while !drained_model.is_empty() {
        drained = drained.remove_min()
        drained_model.remove(0) |> ignore
        if !agrees_with_model(drained, drained_model) {
          return false
        }
      }
      // Every earlier version must still agree with its recorded content.
      for snapshot in snapshots {
        if !agrees_with_model(snapshot.0, snapshot.1) {
          return false
        }
      }
      true
    },
    count=200,
  )
}

///|
test "quickcheck: set algebra agrees with array references, operands persist" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int])) => {
      let (xs, ys) = input
      let (a, model_a) = build(xs)
      let (b, model_b) = build(ys)
      let union_model = model_a.copy()
      for y in model_b {
        model_add(union_model, y)
      }
      let inter_model = model_a.filter(x => model_b.contains(x))
      let diff_model = model_a.filter(x => !model_b.contains(x))
      let sym_model = union_model.filter(x => !inter_model.contains(x))
      let union = a.union(b)
      let inter = a.intersection(b)
      let diff = a.difference(b)
      let sym = a.symmetric_difference(b)
      if !agrees_with_model(union, union_model) ||
        !agrees_with_model(inter, inter_model) ||
        !agrees_with_model(diff, diff_model) ||
        !agrees_with_model(sym, sym_model) {
        return false
      }
      // The bulk operations rebuild trees; neither operand may be disturbed.
      if !agrees_with_model(a, model_a) || !agrees_with_model(b, model_b) {
        return false
      }
      // Inclusion-exclusion on sizes.
      if union.length() != a.length() + b.length() - inter.length() {
        return false
      }
      // Operator aliases.
      a + b == union && a - b == diff
    },
    count=200,
  )
}

///|
test "quickcheck: union laws (commutative, associative, idempotent, unit)" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Array[Int])) => {
      let (xs, ys, zs) = input
      let (a, _) = build(xs)
      let (b, _) = build(ys)
      let (c, _) = build(zs)
      let empty : @sorted_set.SortedSet[Int] = @sorted_set.new()
      a.union(b) == b.union(a) &&
      a.union(b).union(c) == a.union(b.union(c)) &&
      a.union(a) == a &&
      a.union(empty) == a &&
      empty.union(a) == a &&
      a.intersection(b) == b.intersection(a) &&
      a.intersection(a) == a &&
      a.difference(a) == empty &&
      a.symmetric_difference(b) == b.symmetric_difference(a) &&
      a.symmetric_difference(a) == empty &&
      a.symmetric_difference(b) == a.union(b).difference(a.intersection(b))
    },
    count=200,
  )
}

///|
test "quickcheck: subset and disjoint agree with the model and each other" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int])) => {
      let (xs, ys) = input
      let (a, model_a) = build(xs)
      let (b, model_b) = build(ys)
      let model_subset = model_a.iter().all(x => model_b.contains(x))
      let model_disjoint = model_a.iter().all(x => !model_b.contains(x))
      if a.subset(b) != model_subset || a.disjoint(b) != model_disjoint {
        return false
      }
      // Mutual inclusion is exactly equality.
      if (a.subset(b) && b.subset(a)) != (a == b) {
        return false
      }
      // Derived containment facts.
      a.difference(b).disjoint(b) &&
      a.intersection(b).subset(a) &&
      a.intersection(b).subset(b) &&
      a.subset(a.union(b)) &&
      b.subset(a.union(b)) &&
      a.symmetric_difference(b).disjoint(a.intersection(b))
    },
    count=200,
  )
}

///|
test "quickcheck: constructors round-trip and deduplicate" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let (set, model) = build(xs)
      if !agrees_with_model(set, model) {
        return false
      }
      // Rebuilding from the (sorted, deduplicated) content reproduces an
      // equal set, and `Eq` agrees with content equality.
      @sorted_set.from_iter(set.iter()) == set &&
      @sorted_set.SortedSet(set.to_array()) == set &&
      set.iter().to_array() == set.to_array() &&
      set.rev_iter().to_array() == set.to_array().rev()
    },
    count=300,
  )
}

///|
test "quickcheck: filter and map agree with array references" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let (set, model) = build(xs)
      // filter keeps exactly the elements satisfying the predicate.
      let filtered = set.filter(x => x % 3 != 0)
      let filtered_model = model.filter(x => x % 3 != 0)
      if !agrees_with_model(filtered, filtered_model) {
        return false
      }
      // A monotone map preserves order and cardinality.
      let doubled = set.map(x => x * 2)
      let doubled_model = model.map(x => x * 2)
      if !agrees_with_model(doubled, doubled_model) {
        return false
      }
      // A collapsing map must deduplicate the images.
      let collapsed = set.map(x => x % 7)
      let collapsed_model : Array[Int] = []
      for x in model {
        model_add(collapsed_model, x % 7)
      }
      // The source set is untouched by either transformation.
      agrees_with_model(collapsed, collapsed_model) &&
      agrees_with_model(set, model)
    },
    count=300,
  )
}

///|
test "quickcheck: split and range partition the set around a pivot" {
  @quickcheck.check(
    (input : (Array[Int], Int, Int)) => {
      let (xs, raw_low, raw_high) = input
      let (set, model) = build(xs)
      // The pivot roams a slightly larger space than the elements, so it is
      // absent about as often as it is present.
      let pivot = raw_low % 40
      let (left, present, right) = set.split(pivot)
      if present != set.contains(pivot) {
        return false
      }
      if !agrees_with_model(left, model.filter(x => x < pivot)) ||
        !agrees_with_model(right, model.filter(x => x > pivot)) {
        return false
      }
      // range is inclusive on both bounds; low > high yields the empty
      // sequence as often as not.
      let low = raw_low % 40
      let high = raw_high % 40
      let in_range = set.range(low~, high~).to_array()
      let expected = sorted_model(model).filter(x => low <= x && x <= high)
      // Splitting and ranging leave the original untouched.
      in_range == expected && agrees_with_model(set, model)
    },
    count=300,
  )
}
