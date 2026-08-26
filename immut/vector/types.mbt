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
/// - `shift` = tree height * `NUM_BITS`. When it is 0, we are at the leaf level.
/// - `size` = the total number of elements in `tree` and `tail`.
/// - `tail` stores the right-most chunk and has at most `BRANCHING_FACTOR` elements.
/// - `tree` stores the prefix before `tail`.
/// - `shift` is 0 when `tree` is `Empty`, and otherwise names the height of
///   `tree` exactly: every operation that walks the tree is handed this `shift`
///   and decrements it by `NUM_BITS` per level, so a `Leaf` must sit at shift 0.
struct Vector[A] {
  tree : Tree[A]
  tail : FixedArray[A]
  size : Int
  shift : Int
}

///|
/// The RRB tree behind `Vector`.
///
/// Invariants (see the "Representation contract" block in `tree.mbt` for the
/// reasoning, and `invariants_wbtest.mbt` for the executable version):
///
/// - `Empty` appears only as a whole tree, never as a child.
/// - A `Leaf` holds 1..=`BRANCHING_FACTOR` elements and only ever sits at
///   shift 0.
/// - A `Node` has 1..=`BRANCHING_FACTOR` children, all of the same height.
/// - `sizes` is `Some(cumulative)` — a running total, so the last entry is the
///   subtree's element count — or `None` to mean **the whole subtree can be
///   descended by radix indexing**: every child but the last is exactly full,
///   *and* no descendant carries a sizes array of its own.
///
/// Note what `None` does **not** mean. It is not "this node is full": a radix
/// node may have a partial last child (that is what a freshly built tree looks
/// like), and conversely a node can be exactly full and still carry sizes,
/// because `append_right_leaf` and `push_end` grow a relaxed node by patching
/// its sizes array rather than re-deriving it. Treating full as equivalent to
/// radix is what made `at` abort in #4083.
#unsafe_cycle_free
priv enum Tree[A] {
  Empty
  Node(FixedArray[Tree[A]], FixedArray[Int]?) // (Subtrees, Sizes of subtrees)
  Leaf(FixedArray[A])
} derive(Eq, @debug.Debug)
