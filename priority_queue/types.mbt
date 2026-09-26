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
/// A node of the pairing heap behind `PriorityQueue`, stored in
/// left-child/right-sibling form: `child` is the first child and `sibling` is
/// the next node in the parent's child list. The root's `sibling` is always
/// `None`. As long as the stored elements keep a consistent ordering, a node's
/// `content` is never smaller than the content of any of its descendants, so
/// the root holds the maximum. Mutating an element in a way that changes how
/// it compares breaks this heap order, but it cannot change the links.
///
/// # Why `#unsafe_cycle_free` holds
///
/// The nodes of a queue form a tree: every node is referenced by at most one
/// other node (its parent's `child` or its left neighbor's `sibling`). Only
/// `meld` and `copy` create links between nodes; `merges` only clears them.
/// `meld` joins the roots of two disjoint trees, and `copy` points each copied
/// link at a node it has just allocated, so neither can close a cycle.
///
/// The compiler does not check this. The attribute only covers the links in
/// `Node`. If the element type `A` can reach a queue again (for example
/// `struct S { q : PriorityQueue[S] }`), the compiler ignores the attribute
/// for that instance and treats `Node[S]` as cycle-capable.
///
/// # What it buys
///
/// Only the native backend uses the attribute. Without it, `Node` counts as
/// cycle-capable because it has mutable fields that point back to `Node`.
/// Each new node then gets its cycle status set, and in a runtime built with
/// trial deletion, dropping a reference that does not free the node registers
/// it as a possible cycle root. With the attribute, and when `A` does not
/// reach a queue again, node retain/release use the cheaper `_cycle_free`
/// variants and neither step happens.
///
/// Remove the attribute if a change to `child` or `sibling` can ever form a
/// cycle, including a node linked to itself or `meld` on two trees that
/// overlap. Otherwise the cycle collector skips those nodes and the cycle
/// leaks.
#unsafe_cycle_free
priv struct Node[A] {
  content : A
  mut sibling : Node[A]?
  mut child : Node[A]?
}

///|
struct PriorityQueue[A] {
  mut len : Int
  mut top : Node[A]?
}
