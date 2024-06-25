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

//
// An efficient implementation of Map.
// Based on size balanced binary trees, described by:
// Stephen Adams, "Efficient sets: a balancing act" Journal of Functional Programming 3(4):553-562, October 1993
//

/// Immuatable map, consists of key-value pairs.
///
/// # Example
///
/// ```
/// let map1 = of([(3, "three"), (8, "eight"), (1, "one")])
/// let map2 = map1.insert(2, "two").remove(3)
/// println(map3.lookup(3)) // output: None
/// println(map3.lookup(2)) // output: Some("two")
/// let map3 = map2.insert(2, "updated")
/// println(map3.lookup(2)) // output: Some("updated")
/// ```
enum Map[K, V] {
  Empty
  Tree(K, ~value : V, ~size : Int, Map[K, V], Map[K, V])
}
