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
priv struct Entry[K] {
  mut psl : Int
  hash : Int
  key : K
} derive(Show)

/// A mutable hash set implements with Robin Hood hashing.
///
/// reference:
/// - <https://programming.guide/robin-hood-hashing.html>
/// - <https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf>

///|
/// Mutable hash set, not thread safe.
///
/// # Example
///
/// ```mbt check
/// test {
///   let set = @hashset.from_array([(3, "three"), (8, "eight"), (1, "one")])
///   set.add((4, "four"))
///   assert_eq(set.contains((4, "four")), true)
/// }
/// ```
#alias(T, deprecated)
struct HashSet[K] {
  mut entries : FixedArray[Entry[K]?]
  mut size : Int // active key count
  mut capacity : Int // current capacity
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  mut grow_at : Int // threshold that triggers grow
}
