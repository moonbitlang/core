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
  Valid(
    mut ~psl : Int,
    ~hash : Int,
    ~key : K,
    mut ~value : V,
    mut ~prev : Entry[K, V],
    mut ~next : Entry[K, V]
  )
} derive(Debug)

fn op_equal[K : Eq, V](self : Entry[K, V], other : Entry[K, V]) -> Bool {
  match (self, other) {
    (Empty, Empty) => true
    (Valid(_), Empty) => false
    (Empty, Valid(_)) => false
    (Valid(hash=h1, key=k1, ..), Valid(hash=h2, key=k2, ..)) =>
      h1 == h2 && k1 == k2
  }
}

/// Mutable linked hash map that maintains the order of insertion, not thread safe. 
///  
/// # Example
/// 
/// ```
/// let map = HashMap::[(3, "three"), (8, "eight"), (1, "one")]
/// println(map.get(2)) // output: None
/// println(map.get(3)) // output: Some("three")
/// map.set(3, "updated")
/// println(map.get(3)) // output: Some("updated")
/// map.iter(fn(k, v) { println("\(k)-\(v)") })
/// // output:
/// // 3-three
/// // 8-eight
/// // 1-one
/// ```
struct LinkedHashMap[K, V] {
  mut entries : Array[Entry[K, V]]
  mut size : Int // active key-value pairs count
  mut capacity : Int // current capacity 
  mut growAt : Int // threshold that triggers grow
  mut head : Entry[K, V] // head of linked list
  mut tail : Entry[K, V] // tail of linked list
}
