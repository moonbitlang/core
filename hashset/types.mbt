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
/// `hashes[i] == empty_hash` marks an empty slot. Any `Int` can legitimately
/// be a hash, so `store_hash` remaps this one value onto another; the two then
/// share a bucket, which costs an occasional extra key comparison and nothing
/// else, since lookups compare keys as well as hashes.
let empty_hash : Int = 0

///|
/// The value real hashes equal to `empty_hash` are stored as.
let remapped_hash : Int = 1

///|
/// Maps a key's hash onto the value stored in `hashes`, keeping the sentinel
/// unambiguous.
#inline
fn store_hash(hash : Int) -> Int {
  if hash == empty_hash {
    remapped_hash
  } else {
    hash
  }
}

///|
/// Package-local unchecked accessors for the key storage. These are kept
/// private here rather than exposed from `builtin`: `set_null` and
/// `unsafe_set` can corrupt memory, so the fewer packages that can name them
/// the better.
fn[K] UninitializedArray::unsafe_get(
  self : UninitializedArray[K],
  idx : Int,
) -> K = "%fixedarray.unsafe_get"

///|
fn[K] UninitializedArray::unsafe_set(
  self : UninitializedArray[K],
  idx : Int,
  key : K,
) -> Unit = "%fixedarray.unsafe_set"

///|
/// Releases the key reference stored at `idx` so the collector can reclaim it.
fn[K] UninitializedArray::set_null(
  self : UninitializedArray[K],
  idx : Int,
) -> Unit = "%fixedarray.set_null"

/// A mutable hash set implemented with Robin Hood hashing.
///
/// reference:
/// - <https://programming.guide/robin-hood-hashing.html>
/// - <https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf>

///|
/// Mutable hash set, not thread safe.
///
/// The table is stored as two parallel arrays rather than an array of boxed
/// entries, so inserting a key does not allocate a per-entry object. For an
/// occupied slot `i`, `hashes[i]` caches the key's stored hash and `keys[i]`
/// holds the key; for an empty slot `hashes[i] == empty_hash` and `keys[i]` is
/// unused.
///
/// There is no probe-sequence-length array. A slot's PSL is implied by where
/// it sits relative to where its hash wanted it, so `psl_at` derives it with
/// two arithmetic operations instead of a third random memory access. That
/// identity holds because every write to a slot happens as the key lands in
/// it, and the derivation follows the key whenever displacement moves it.
///
/// # Example
///
/// ```mbt check
/// test {
///   let set = @hashset.HashSet([(3, "three"), (8, "eight"), (1, "one")])
///   set.add((4, "four"))
///   @test.assert_eq(set.contains((4, "four")), true)
/// }
/// ```
struct HashSet[K] {
  mut hashes : FixedArray[Int] // stored key hash, or empty_hash when empty
  mut keys : UninitializedArray[K] // key storage for occupied slots
  mut size : Int // active key count
  mut capacity : Int // current capacity
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  mut grow_at : Int // threshold that triggers grow
}
