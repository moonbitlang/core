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

/// Utility functions for working with trees.
/// Other utility functions are in `utils.mbt`.

///|
/// If the tree is a `Node`.
fn Tree::is_node[A](self : Tree[A]) -> Bool {
  match self {
    Node(_, _) => true
    _ => false
  }
}

///|
fn Tree::is_leaf[A](self : Tree[A]) -> Bool {
  match self {
    Leaf(_) => true
    _ => false
  }
}

///|
fn Tree::is_empty[A](self : Tree[A]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

///|
/// Get the rightmost child of a tree node. Abort if
/// it is not a `Node`.
fn Tree::right_child[A](self : Tree[A]) -> Tree[A] {
  match self {
    Node(children, _) => children[children.length() - 1]
    Leaf(_) | Empty => abort("Should not get children on non-`Node`s")
  }
}

///|
/// Get the leftmost child of a tree node. Abort if
/// it is not a `Node`.
fn Tree::left_child[A](self : Tree[A]) -> Tree[A] {
  match self {
    Node(children, _) => children[0]
    Leaf(_) | Empty => abort("Should not get children on non-`Node`s")
  }
}

///|
/// Get the leaf contents. Abort if it is not a `Leaf`.
fn Tree::leaf_elements[A](self : Tree[A]) -> FixedArray[A] {
  match self {
    Leaf(children) => children
    _ => abort("Should not call `get_leaf_elements` on non-leaf nodes")
  }
}

///|
/// Get the children of a `Node`. Abort if it is not a `Node`.
fn Tree::node_children[A](self : Tree[A]) -> FixedArray[Tree[A]] {
  match self {
    Node(children, _) => children
    _ => abort("Should not call `node_children` on non-`Node`s")
  }
}

///|
/// Get the physical size of the current node, not the total number of elements in the tree.
fn Tree::local_size[A](self : Tree[A]) -> Int {
  match self {
    Empty => 0
    Leaf(l) => l.length()
    Node(children, _) => children.length()
  }
}

///|
/// Get the total number of elements in the tree.
fn Tree::size[A](self : Tree[A], shift : Int) -> Int {
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
