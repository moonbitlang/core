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

// This package implements a mutable sorted set backed by an AVL tree.
// The element type must implement the Compare trait.
// Mutating operations update the set in place; set operations return new sets.

///|
/// A mutable, ordered set backed by an AVL tree.
///
/// Values are ordered by `Compare`. Inserting an equal value replaces the stored
/// value.
///
/// # Example
/// ```mbt check
/// test {
///   let set = @sorted_set.from_array([3, 1, 2, 2])
///   inspect(set.to_array(), content="[1, 2, 3]")
/// }
/// ```
#alias(T, deprecated)
struct SortedSet[V] {
  mut root : Node[V]?
  mut size : Int
}

///|
/// Internal AVL tree node for `SortedSet`.
priv struct Node[V] {
  mut value : V
  mut left : Node[V]?
  mut right : Node[V]?
  mut height : Int
}
