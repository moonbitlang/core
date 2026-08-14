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

// Property sweep for the persistent AVL map. The reference model is a plain
// association array; `agrees_with_model` is the full specification check:
// same length, every model key looks up to its model value, an absent probe
// key misses, and `to_array` yields exactly the model's entries with keys in
// STRICTLY ascending order — an externally observable witness of the BST
// invariant, which is what rotations after insert/remove must preserve.

///|
/// Replace-or-append, mirroring `SortedMap::add` (last write wins).
fn model_set(model : Array[(Int, Int)], key : Int, value : Int) -> Unit {
  for i, entry in model {
    if entry.0 == key {
      model[i] = (key, value)
      return
    }
  }
  model.push((key, value))
}

///|
fn model_remove(model : Array[(Int, Int)], key : Int) -> Unit {
  for i, entry in model {
    if entry.0 == key {
      model.remove(i) |> ignore
      return
    }
  }
}

///|
/// The model's entries sorted by key (keys are unique, so tuple order is
/// key order).
fn sorted_entries(model : Array[(Int, Int)]) -> Array[(Int, Int)] {
  let sorted = model.copy()
  sorted.sort()
  sorted
}

///|
fn agrees_with_model(
  map : @sorted_map.SortedMap[Int, Int],
  model : Array[(Int, Int)],
) -> Bool {
  if map.length() != model.length() {
    return false
  }
  if map.is_empty() != (model.length() == 0) {
    return false
  }
  for entry in model {
    if map.get(entry.0) != Some(entry.1) || !map.contains(entry.0) {
      return false
    }
  }
  // A key outside the generated key space must miss.
  if map.get(1 << 20) != None || map.contains(1 << 20) {
    return false
  }
  let actual = map.to_array()
  for i in 1..<actual.length() {
    // Strictly ascending: sortedness AND key uniqueness in one check.
    if actual[i - 1].0 >= actual[i].0 {
      return false
    }
  }
  actual == sorted_entries(model)
}

///|
/// Build a map and its model from raw entries, folding keys into a small
/// space so replacements (and later, overlaps between two maps) are common.
fn build(
  entries : Array[(Int, Int)],
) -> (@sorted_map.SortedMap[Int, Int], Array[(Int, Int)]) {
  let model : Array[(Int, Int)] = []
  let pairs : Array[(Int, Int)] = []
  for entry in entries {
    let key = entry.0 % 31
    pairs.push((key, entry.1))
    model_set(model, key, entry.1)
  }
  (SortedMap(pairs), model)
}

///|
test "quickcheck: op sequences agree with a model and old versions persist" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let mut map : @sorted_map.SortedMap[Int, Int] = @sorted_map.new()
      let model : Array[(Int, Int)] = []
      // Snapshots of every intermediate version paired with its expected
      // content; persistence means none of them may change afterwards.
      let snapshots : Array[
        (@sorted_map.SortedMap[Int, Int], Array[(Int, Int)]),
      ] = [(map, [])]
      for op in ops {
        // A small key space deliberately generates replacements and
        // removals of both present and absent keys.
        let key = op.0 % 31
        if op.1 % 4 == 0 {
          map = map.remove(key)
          model_remove(model, key)
        } else {
          map = map.add(key, op.1)
          model_set(model, key, op.1)
        }
        if !agrees_with_model(map, model) {
          return false
        }
        snapshots.push((map, model.copy()))
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
test "quickcheck: remove leaves exactly the other keys, present or not" {
  @quickcheck.check(
    (input : (Array[(Int, Int)], Int)) => {
      let (entries, raw_key) = input
      let (map, model) = build(entries)
      // Drain the map one key at a time in generated order; every step
      // must rebalance back to a well-formed tree with the exact residue.
      let mut current = map
      let current_model = model.copy()
      for entry in entries {
        current = current.remove(entry.0 % 31)
        model_remove(current_model, entry.0 % 31)
        if !agrees_with_model(current, current_model) {
          return false
        }
      }
      // Removing an arbitrary (often absent) key from the original.
      let key = raw_key % 61
      let removed = map.remove(key)
      let removed_model = model.copy()
      model_remove(removed_model, key)
      if !agrees_with_model(removed, removed_model) {
        return false
      }
      // The original version is untouched by any of the removals.
      agrees_with_model(map, model)
    },
    count=200,
  )
}

///|
test "quickcheck: constructor is last-wins and round-trips via to_array" {
  @quickcheck.check(
    (entries : Array[(Int, Int)]) => {
      let (map, model) = build(entries)
      if !agrees_with_model(map, model) {
        return false
      }
      // Rebuilding from the (deduplicated, sorted) content reproduces an
      // equal map, and `Eq` agrees with content equality.
      @sorted_map.from_iter(map.iter()) == map &&
      @sorted_map.SortedMap(map.to_array()) == map
    },
    count=300,
  )
}

///|
test "quickcheck: merge is model union with right bias, empty is identity" {
  @quickcheck.check(
    (input : (Array[(Int, Int)], Array[(Int, Int)])) => {
      let (xs, ys) = input
      let (a, model_a) = build(xs)
      let (b, model_b) = build(ys)
      // Model union: start from a's content, let b's entries overwrite.
      let union_model = model_a.copy()
      for entry in model_b {
        model_set(union_model, entry.0, entry.1)
      }
      if !agrees_with_model(a.merge(b), union_model) {
        return false
      }
      // Merging must not disturb either operand (persistence).
      if !agrees_with_model(a, model_a) || !agrees_with_model(b, model_b) {
        return false
      }
      let empty : @sorted_map.SortedMap[Int, Int] = @sorted_map.new()
      a.merge(empty) == a && empty.merge(a) == a
    },
    count=200,
  )
}

///|
test "quickcheck: filter and map agree with the array reference" {
  @quickcheck.check(
    (entries : Array[(Int, Int)]) => {
      let (map, model) = build(entries)
      // filter on a key/value predicate
      let filtered = map.filter((k, v) => (k + v) % 3 != 0)
      let filtered_model = model.copy()
      filtered_model.retain(entry => (entry.0 + entry.1) % 3 != 0)
      if !agrees_with_model(filtered, filtered_model) {
        return false
      }
      // map with key-dependent values
      let mapped = map.map((k, v) => v * 2 + k)
      let mapped_model = model.map(entry => (entry.0, entry.1 * 2 + entry.0))
      agrees_with_model(mapped, mapped_model)
    },
    count=300,
  )
}

///|
test "quickcheck: range yields exactly the in-bounds entries in order" {
  @quickcheck.check(
    (input : (Array[(Int, Int)], Int, Int)) => {
      let (entries, raw_low, raw_high) = input
      let (map, model) = build(entries)
      // Bounds roam a slightly larger space than the keys, and low > high
      // (empty range) is generated as often as low <= high.
      let low = raw_low % 40
      let high = raw_high % 40
      let actual = []
      for k, v in map.range(low~, high~) {
        actual.push((k, v))
      }
      let expected = sorted_entries(model).filter(entry => {
        low <= entry.0 && entry.0 <= high
      })
      actual == expected
    },
    count=300,
  )
}
