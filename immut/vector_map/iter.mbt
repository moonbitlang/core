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

// Every traversal below walks the spine and skips tombstones, so all of them
// yield entries in insertion order and none of them touches the hash trie.

///|
/// Apply `f` to every entry, in insertion order. `O(n)`.
pub fn[K, V] VectorMap::each(
  self : VectorMap[K, V],
  f : (K, V) -> Unit raise?,
) -> Unit raise? {
  self.spine.each(entry => if entry is Some((k, v)) { f(k, v) })
}

///|
/// Apply `f` to every entry along with its position, in insertion order.
///
/// The position is the entry's rank among the live entries, so it always runs
/// from `0` to `length() - 1` with no gaps, whatever the spine looks like
/// underneath. `O(n)`.
pub fn[K, V] VectorMap::eachi(
  self : VectorMap[K, V],
  f : (Int, K, V) -> Unit raise?,
) -> Unit raise? {
  let mut i = 0
  self.spine.each(entry => {
    if entry is Some((k, v)) {
      f(i, k, v)
      i += 1
    }
  })
}

///|
/// Iterate over the entries, in insertion order. `O(1)` to build, `O(n)` to
/// drain.
#alias(iterator, deprecated)
pub fn[K, V] VectorMap::iter(self : VectorMap[K, V]) -> Iter[(K, V)] {
  self.spine.iter().filter_map(entry => entry)
}

///|
/// Iterate over the entries as key/value pairs, in insertion order. `O(1)` to
/// build, `O(n)` to drain.
#alias(iterator2, deprecated)
pub fn[K, V] VectorMap::iter2(self : VectorMap[K, V]) -> Iter2[K, V] {
  self.iter()
}

///|
/// Iterate over the keys, in insertion order. `O(1)` to build, `O(n)` to drain.
pub fn[K, V] VectorMap::keys(self : VectorMap[K, V]) -> Iter[K] {
  self.iter().map(kv => kv.0)
}

///|
/// Iterate over the values, in insertion order. `O(1)` to build, `O(n)` to
/// drain.
#alias(elems, deprecated)
pub fn[K, V] VectorMap::values(self : VectorMap[K, V]) -> Iter[V] {
  self.iter().map(kv => kv.1)
}

///|
/// Fold over the entries, in insertion order. `O(n)`.
pub fn[K, V, A] VectorMap::fold(
  self : VectorMap[K, V],
  init~ : A,
  f : (A, K, V) -> A raise?,
) -> A raise? {
  self.spine.fold(init~, (acc, entry) => {
    match entry {
      Some((k, v)) => f(acc, k, v)
      None => acc
    }
  })
}

///|
/// Collect the entries into an array, in insertion order. `O(n)`.
pub fn[K, V] VectorMap::to_array(self : VectorMap[K, V]) -> Array[(K, V)] {
  let result : Array[(K, V)] = Array::new(capacity=self.size)
  self.each((k, v) => result.push((k, v)))
  result
}

///|
/// Transform every value, keeping the keys and their order.
///
/// The index is shared with the receiver rather than rebuilt: no slot moves, so
/// the mapping from keys to positions is unchanged. `O(n)`, and no key is
/// hashed.
#alias(map_with_key, deprecated)
pub fn[K, V, A] VectorMap::map(
  self : VectorMap[K, V],
  f : (K, V) -> A raise?,
) -> VectorMap[K, A] raise? {
  {
    index: self.index,
    spine: self.spine.map(entry => {
      match entry {
        Some((k, v)) => Some((k, f(k, v)))
        None => None
      }
    }),
    size: self.size,
  }
}

///|
/// Keep the entries satisfying `pred`, in their existing relative order.
///
/// A predicate that rejects nothing returns the receiver itself, holes and all;
/// any other result is rebuilt dense, so filtering never *introduces* a hole.
///
/// `O(n)`: one spine pass, then the index is filtered and renumbered in place
/// of being rebuilt from the keys, so again nothing is hashed.
#alias(filter_with_key, deprecated)
pub fn[K, V] VectorMap::filter(
  self : VectorMap[K, V],
  pred : (K, V) -> Bool raise?,
) -> VectorMap[K, V] raise? {
  // `remap` sends a surviving slot to its new dense position and a dropped one
  // to -1, which is what lets the index be filtered and renumbered below
  // without rehashing any key.
  let remap = FixedArray::make(self.spine.length(), -1)
  let kept : Array[(K, V)?] = []
  self.spine.eachi((slot, entry) => {
    if entry is Some((k, v)) {
      if pred(k, v) {
        remap[slot] = kept.length()
        kept.push(entry)
      }
    }
  })
  if kept.length() == self.size {
    return self
  }
  {
    index: self.index
    .filter((_, slot) => remap[slot] >= 0)
    .map((_, slot) => remap[slot]),
    spine: @vector.from_iter(kept.iter()),
    size: kept.length(),
  }
}
