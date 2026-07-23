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
/// `psls[i] == empty_psl` marks an empty slot. A real probe-sequence length is
/// always `>= 0`, so `-1` is a safe sentinel.
let empty_psl : Int = -1

///|
/// Releases the key reference stored at `idx` so the collector can reclaim it.
fn[K] set_null(keys : UninitializedArray[K], idx : Int) = "%fixedarray.set_null"

/// A mutable hash set implemented with Robin Hood hashing.
///
/// reference:
/// - <https://programming.guide/robin-hood-hashing.html>
/// - <https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf>

///|
/// Mutable hash set, not thread safe.
///
/// The table is stored as a struct-of-arrays (`psls` / `hashes` / `keys`)
/// rather than an array of boxed entries, so inserting a key does not allocate
/// a per-entry object. For an occupied slot `i`, `hashes[i]` caches the key's
/// hash and `keys[i]` holds the key; for an empty slot `psls[i] == empty_psl`
/// and `keys[i]` is unused.
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
  mut psls : FixedArray[Int] // probe sequence length, or empty_psl when empty
  mut hashes : FixedArray[Int] // cached key hash for occupied slots
  mut keys : UninitializedArray[K] // key storage for occupied slots
  mut size : Int // active key count
  mut capacity : Int // current capacity
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  mut grow_at : Int // threshold that triggers grow
}
