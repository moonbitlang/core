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

// This module implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

// Red-black tree implementation of a set.

// Invariant:
// - root cannot be NIL, i.e., either get_value(root) succeeds, or root = None.
struct MutableSet[T] {
  mut root : Node[T]?
  mut size : Int64
} derive(Eq)

priv enum Color {
  Red
  Black
} derive(Show, Debug, Eq)

// Invariants:
// - Only root has None as its parent.
// - Only leaves have None as their children.
// - Only leaves have None as their value.
priv struct Node[T] {
  mut color : Color
  mut left : Node[T]?
  mut value : T?
  mut right : Node[T]?
  mut parent : Node[T]?
} derive(Eq) // Don't derive Debug because it is self-referential on `parent`
