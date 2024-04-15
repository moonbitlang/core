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
struct MutableSet[T] {
  mut root: Node[T]
} derive(Debug, Eq)

enum Node[T] {
  Empty(Color)
  Node(NodeImpl[T])
} derive(Debug, Eq)

priv enum Color {
  Red
  Black
  DBlack // Double black
} derive(Debug, Eq)

// HACK: mut is not allowed in enum variant, so we need to use a struct to wrap the fields.
priv struct NodeImpl[T] {
  mut color: Color
  mut left: Node[T]
  mut value: T
  mut right: Node[T]
} derive(Debug, Eq)