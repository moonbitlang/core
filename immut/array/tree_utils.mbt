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

/// Utility functions for working with trees.
/// Other utility functions are in `utils.mbt`.

///|
/// If the tree is a `Node`.
fn[A] Tree::is_node(self : Tree[A]) -> Bool {
  self is Node(_, _)
}

///|
fn[A] Tree::is_leaf(self : Tree[A]) -> Bool {
  self is Leaf(_)
}

///|
/// Get the rightmost child of a tree node. Abort if
/// it is not a `Node`.
fn[A] Tree::right_child(self : Tree[A]) -> Tree[A] {
  match self {
    Node(children, _) => children[children.length() - 1]
    Leaf(_) | Empty => abort("Should not get children on non-`Node`s")
  }
}

///|
/// Get the leftmost child of a tree node. Abort if
/// it is not a `Node`.
fn[A] Tree::left_child(self : Tree[A]) -> Tree[A] {
  match self {
    Node(children, _) => children[0]
    Leaf(_) | Empty => abort("Should not get children on non-`Node`s")
  }
}

///|
/// Get the leaf contents. Abort if it is not a `Leaf`.
fn[A] Tree::leaf_elements(self : Tree[A]) -> FixedArray[A] {
  guard self is Leaf(children) else {
    abort("Should not call `get_leaf_elements` on non-leaf nodes")
  }
  children
}

///|
/// Get the children of a `Node`. Abort if it is not a `Node`.
fn[A] Tree::node_children(self : Tree[A]) -> FixedArray[Tree[A]] {
  guard self is Node(children, _) else {
    abort("Should not call `node_children` on non-`Node`s")
  }
  children
}

///|
/// Get the physical size of the current node, not the total number of elements in the tree.
fn[A] Tree::local_size(self : Tree[A]) -> Int {
  match self {
    Empty => 0
    Leaf(l) => l.length()
    Node(children, _) => children.length()
  }
}

///|
/// Get the total number of elements in the tree.
fn[A] Tree::size(self : Tree[A], shift : Int) -> Int {
  match self {
    Empty => 0
    Leaf(l) => l.length()
    Node(_, Some(sizes)) => sizes[sizes.length() - 1]
    Node(children, None) => {
      let len_1 = children.length() - 1
      (len_1 << shift) + children[len_1].size(shift - num_bits)
    }
  }
}
