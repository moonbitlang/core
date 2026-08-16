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
/// Two maps are equal when they hold the same entries **in the same order**.
///
/// Order is part of the content here, so maps built from the same pairs in
/// different orders are not equal — which is what a consumer rendering the
/// entries needs, since a reordering is a visible change. The comparison reads
/// the live entries only: tombstone layout is representation, and two equal
/// maps reached by different histories may well have different spines.
///
/// `O(1)` when the two are physically identical or differ in length, `O(n)`
/// otherwise — and it stops at the first entry that differs.
pub impl[K : Eq, V : Eq] Eq for VectorMap[K, V] with fn equal(self, other) {
  if physical_equal(self, other) {
    return true
  }
  // Comparing lengths first is not just a shortcut: the walk below stops after
  // `self.size` entries, so without it a map would compare equal to any longer
  // map it is a prefix of — and `Eq` would not even be symmetric.
  guard self.size == other.size else { return false }
  let left = self.iter()
  let right = other.iter()
  for _ in 0..<self.size {
    guard left.next() == right.next() else { return false }
  }
  true
}

///|
/// Hash the entries in insertion order, so that two maps that compare equal
/// hash equally and two orderings of the same entries generally do not.
///
/// The length is not folded in separately: the hasher is fed one key and one
/// value per entry in sequence, so a map and a proper prefix of it already feed
/// it different sequences. That is not a guarantee of different hashes — only
/// equal maps hashing equally is promised, and unequal ones may always collide.
/// `O(n)`.
pub impl[K : Hash, V : Hash] Hash for VectorMap[K, V] with fn hash_combine(
  self,
  hasher,
) {
  for k, v in self {
    hasher.combine(k)
    hasher.combine(v)
  }
}

///|
/// Render the entries in insertion order. `O(n)`, plus whatever rendering each
/// key and value costs.
pub impl[K : @debug.Debug, V : @debug.Debug] @debug.Debug for VectorMap[K, V] with fn to_repr(
  self,
) {
  @debug.Repr::opaque_(
    "VectorMap",
    @debug.Repr::map([ for k, v in self => (Repr(k), Repr(v)) ]),
  )
}

///|
/// Serialise as an array of `[key, value]` pairs.
///
/// An array rather than an object, because the point of this type is the order
/// of its entries and JSON object member order is not something a reader is
/// obliged to preserve. It also keeps non-string keys intact. `O(n)`.
pub impl[K : ToJson, V : ToJson] ToJson for VectorMap[K, V] with fn to_json(
  self,
) {
  [
    for k, v in self => ([k, v] : Json)
  ]
}

///|
/// Decode an array of `[key, value]` pairs, applying the same duplicate-key rule
/// as the array constructor, at the same `O(m log n)` for `m` pairs.
pub impl[K : @json.FromJson + Eq + Hash, V : @json.FromJson] @json.FromJson for VectorMap[
  K,
  V,
] with fn from_json(json, path) {
  guard json is Array(pairs) else {
    raise JsonDecodeError((path, "@immut/vector_map.from_json: expected array"))
  }
  let entries : Array[(K, V)] = Array::new(capacity=pairs.length())
  for i, pair in pairs {
    let entry_path = path.add_index(i)
    guard pair is Array([key, value]) else {
      raise JsonDecodeError(
        (entry_path, "@immut/vector_map.from_json: expected [key, value] pair"),
      )
    }
    entries.push(
      (
        @json.FromJson::from_json(key, entry_path.add_index(0)),
        @json.FromJson::from_json(value, entry_path.add_index(1)),
      ),
    )
  }
  from_pairs(entries.iter())
}
