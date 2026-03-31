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
/// Invariants:
/// - `shift` = tree height * `num_bits`. When it is 0, we are at the leaf level.
/// - `size` = the total number of elements in `tree` and `tail`.
/// - `tail` stores the right-most chunk and has at most `branching_factor` elements.
/// - `tree` stores the prefix before `tail`.
/// - `shift` is not used when `tree` is `Empty`.
#alias(T, deprecated)
struct Vector[A] {
  tree : Tree[A]
  tail : FixedArray[A]
  size : Int
  shift : Int
}

///|
/// Invariants:
/// - For `Node`, the sizes array is `None` if the tree is full, i.e., we can use radix indexing.
priv enum Tree[A] {
  Empty
  Node(FixedArray[Tree[A]], FixedArray[Int]?) // (Subtrees, Sizes of subtrees)
  Leaf(FixedArray[A])
} derive(Eq)
