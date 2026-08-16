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
/// A persistent map that iterates in **insertion order**, the immutable
/// counterpart of the built-in insertion-ordered `Map`.
///
/// Entries live in a persistent vector — the *spine* — in the order they were
/// first inserted, and a persistent hash map — the *index* — maps each key to
/// its slot in that spine. Iteration therefore reads the spine straight
/// through, without descending the hash trie, which is what makes it suited to
/// rendering a collection on every state change.
///
/// Removal punches a hole in the spine rather than shifting the entries after
/// it, since shifting would invalidate every index entry to their right. Those
/// holes are reclaimed by `compact` once they outnumber the live entries.
///
/// # Invariants
///
/// - `index` holds exactly the live keys, and `spine[index[k]]` is
///   `Some((k, _))` for every one of them.
/// - `size` is the number of `Some` slots in `spine`.
/// - The last slot of a non-empty `spine` is never a tombstone, so an empty
///   map always has an empty spine.
/// - Tombstones never outnumber live entries once the spine reaches
///   `MIN_COMPACT_LENGTH`.
///
/// Note that the representation is deliberately *not* canonical: two equal maps
/// may hold different tombstone layouts, so `Eq` compares the live entry
/// sequence rather than the underlying structure.
struct VectorMap[K, V] {
  index : @hashmap.HashMap[K, Int]
  spine : @vector.Vector[(K, V)?]
  size : Int
}

///|
/// A spine shorter than this is never compacted: rebuilding it costs more than
/// the slots it wastes. Matches the threshold Immutable.js uses for the same
/// representation.
const MIN_COMPACT_LENGTH : Int = 32
