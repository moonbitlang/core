// Copyright 2024 International Digital Economy Academy
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

priv enum Entry[K, V] {
  Empty
  // (Probe Sequence Length, Hash, Key, Value)
  Valid(~psl : Int, ~hash : Int, ~key : K, ~value : V)
} derive(Debug)

/// A mutable hash map implements with Robin Hood hashing.
/// 
/// reference:
/// - <https://programming.guide/robin-hood-hashing.html>
/// - <https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf>

/// Mutable hash map, not thread safe. 
///  
/// # Example
/// 
/// ```
/// let map = HashMap::[(3, "three"), (8, "eight"), (1, "one")]
/// println(map.get(2)) // output: None
/// println(map.get(3)) // output: Some("three")
/// map.set(3, "updated")
/// println(map.get(3)) // output: Some("updated")
/// ```
struct HashMap[K, V] {
  mut entries : Array[Entry[K, V]]
  mut size : Int // active key-value pairs count
  mut capacity : Int // current capacity 
  mut growAt : Int // threshold that triggers grow
}
