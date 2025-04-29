// Copyright 2025 International Digital Economy Academy
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
priv struct Entry[K, V] {
  mut psl : Int
  hash : Int
  key : K
  mut value : V
} derive(Show)

/// A mutable hash map implements with Robin Hood hashing.
///
/// reference:
/// - <https://programming.guide/robin-hood-hashing.html>
/// - <https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf>

///|
/// Mutable hash map, not thread safe.
///
/// # Example
///
/// ```
/// let map = @hashmap.of([(3, "three"), (8, "eight"), (1, "one")])
/// assert_eq!(map.get(2), None)
/// assert_eq!(map.get(3), Some("three"))
/// map.set(3, "updated")
/// assert_eq!(map.get(3), Some("updated"))
/// ```
struct T[K, V] {
  mut entries : FixedArray[Entry[K, V]?]
  mut capacity : Int
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  // size of field `entries`, it is redundant but useful for performance
  // so we don't need do `self.entries.length()` every time
  mut size : Int // active key-value pairs count
  // mut growAt : Int // threshold that triggers grow
}

///|
pub impl[K : Hash + Eq, V : Eq] Eq for T[K, V] with op_equal(
  self : T[K, V],
  that : T[K, V]
) -> Bool {
  guard self.size == that.size else { return false }
  for k, v in self {
    guard that.contains_kv(k, v) else { return false }

  } else {
    true
  }
}
