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

// This package implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

///|
/// ImmutableSets are represented by size balanced binary trees: in every subtree
/// of more than two elements, neither child's size exceeds 5 times the other's.
/// Subtrees of one or two elements are exempt, so a two-element set may have
/// children of size 1 and 0.
enum SortedSet[A] {
  Empty
  Node(left~ : SortedSet[A], right~ : SortedSet[A], size~ : Int, value~ : A)
}
