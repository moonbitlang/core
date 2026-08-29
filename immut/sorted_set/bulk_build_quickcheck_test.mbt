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

// The bulk builder behind `SortedSet(..)` dispatches on the shape of its
// input: strictly ascending, ascending with duplicates, strictly descending,
// descending with duplicates, or unordered — and unordered splits again at a
// length threshold, taking the bulk-sort path at or above it and the `add`
// fold below. Every one of those paths must produce the same set, so
// `bulk_set_shapes` names one input per path and the properties drive them all
// from a single model.
//
// `from_iter` deliberately does NOT bulk-build: it folds `add`, so its live
// memory stays proportional to the distinct elements rather than to the length
// of the iterator. It is checked here anyway, because the two entry points
// disagree about which of several equal elements survives — the constructor
// keeps the LAST, `from_iter` the FIRST — and that difference is exactly what a
// future attempt to share their implementations would break. With `Int`
// elements it is invisible, so `BElem` compares on `id` only and carries a
// `tag` that makes the survivor observable.
//
// Note that quickcheck's generated arrays cannot reach the duplicate-free
// paths on their own — it sizes element `i` by `i`, so an `Array[Int]` of
// length two or more always starts `[0, 0, ..]`. The strictly monotonic and
// small-unordered shapes below are therefore built explicitly rather than
// derived from the generated array.
//
// These properties pass unchanged on the pre-bulk-build implementation too, so
// they pin the contract that was already there rather than blessing whatever
// the new code happens to do.

///|
/// Compares on `id` only; `tag` records where the element came from.
priv struct BElem {
  id : Int
  tag : Int
}

///|
impl Eq for BElem with fn equal(self, other) {
  self.id == other.id
}

///|
impl Compare for BElem with fn compare(self, other) {
  self.id.compare(other.id)
}

///|
/// `keep_last=true` models the constructor, `false` models `from_iter`.
fn bulk_set_model(values : ArrayView[BElem], keep_last~ : Bool) -> Array[BElem] {
  let out : Array[BElem] = []
  for value in values {
    let mut seen = false
    for i, entry in out {
      if entry.id == value.id {
        if keep_last {
          out[i] = value
        }
        seen = true
        break
      }
    }
    if !seen {
      out.push(value)
    }
  }
  out.sort_by((a, b) => a.id.compare(b.id))
  out
}

///|
/// Full equality including `tag`, which `BElem::equal` deliberately ignores,
/// plus a strictly ascending check — misordering, or the wrong duplicate
/// representative surviving, shows up here even when the ids alone still look
/// right.
fn bulk_set_agrees(actual : Array[BElem], expect : Array[BElem]) -> Bool {
  if actual.length() != expect.length() {
    return false
  }
  for i in 0..<actual.length() {
    if actual[i].id != expect[i].id || actual[i].tag != expect[i].tag {
      return false
    }
  }
  for i in 1..<actual.length() {
    if actual[i - 1].id >= actual[i].id {
      return false
    }
  }
  true
}

///|
/// A small id space keeps duplicates common; `tag` is the original position.
fn bulk_set_values(raw : ArrayView[Int]) -> Array[BElem] {
  Array::makei(raw.length(), i => {
    let id = raw[i] % 37
    { id: if id < 0 { id + 37 } else { id }, tag: i, }
  })
}

///|
/// One input per dispatch path. The generated array supplies the unordered and
/// duplicate-heavy cases; the strictly monotonic and small-unordered shapes are
/// explicit, since generated arrays never have distinct leading elements. The
/// 80-element shapes sit above the length threshold, the 9-element one below.
fn bulk_set_shapes(raw : ArrayView[Int]) -> Array[(String, Array[BElem])] {
  let base = bulk_set_values(raw)
  let ascending_with_duplicates = base.copy()
  ascending_with_duplicates.sort_by((a, b) => a.id.compare(b.id))
  let descending_with_duplicates = ascending_with_duplicates.rev()
  let n = base.length()
  let strict_ascending = Array::makei(80, i => { id: 100 + i, tag: n + i, })
  let strict_descending = strict_ascending.rev()
  let long_ascending_duplicates = Array::makei(80, i => {
    id: 100 + i / 2,
    tag: n + i,
  })
  let long_descending_duplicates = long_ascending_duplicates.rev()
  let long_unordered = Array::makei(80, i => {
    id: (i * 37 + 11) % 41,
    tag: n + i,
  })
  // Below the threshold, so this one takes the `add` fold rather than the
  // bulk sort.
  let small_unordered = Array::makei(9, i => {
    id: (i * 5 + 3) % 7,
    tag: n + i,
  })
  [
    ("as generated", base),
    ("ascending with duplicates", ascending_with_duplicates),
    ("descending with duplicates", descending_with_duplicates),
    ("strictly ascending", strict_ascending),
    ("strictly descending", strict_descending),
    ("long ascending with duplicates", long_ascending_duplicates),
    ("long descending with duplicates", long_descending_duplicates),
    ("long unordered", long_unordered),
    ("small unordered", small_unordered),
    ("generated then strictly ascending", base + strict_ascending),
    ("generated then strictly descending", base + strict_descending),
  ]
}

///|
test "quickcheck: bulk set build agrees with the model on every input shape" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      for shape in bulk_set_shapes(raw) {
        let (_, values) = shape
        // The constructor keeps the last equal element...
        if !bulk_set_agrees(
            @sorted_set.SortedSet(values).to_array(),
            bulk_set_model(values, keep_last=true),
          ) {
          return false
        }
        // ...while `from_iter` keeps the first. Both must still be strictly
        // ascending and hold the same ids.
        if !bulk_set_agrees(
            @sorted_set.from_iter(values.iter()).to_array(),
            bulk_set_model(values, keep_last=false),
          ) {
          return false
        }
      }
      true
    },
    count=200,
  )
}

///|
test "quickcheck: bulk set build matches inserting one at a time" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      for shape in bulk_set_shapes(raw) {
        let (_, values) = shape
        let built = @sorted_set.SortedSet(values)
        // Same size as folding `add`, and every element reachable through the
        // tree rather than merely present in `to_array`.
        let empty : @sorted_set.SortedSet[BElem] = @sorted_set.new()
        let folded = for value in values; s = empty {
          continue s.add(value)
        } nobreak {
          s
        }
        if built.length() != folded.length() {
          return false
        }
        for value in values {
          if !built.contains(value) || !folded.contains(value) {
            return false
          }
        }
        let ids = built.to_array()
        for i in 1..<ids.length() {
          if ids[i - 1].id >= ids[i].id {
            return false
          }
        }
      }
      true
    },
    count=200,
  )
}
