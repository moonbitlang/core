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

///-----------------------------------------------------------------------------
let num_bits = 5

///-----------------------------------------------------------------------------
let branching_factor : Int = 1 << num_bits

///-----------------------------------------------------------------------------
let bitmask : Int = branching_factor - 1

///-----------------------------------------------------------------------------
fn Tree::empty[T]() -> Tree[T] {
  Tree::Empty
}

///-----------------------------------------------------------------------------
fn get_first[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[0]
    Node(node) => get_first(node[0])
    Empty => abort("Index out of bounds")
  }
}

///-----------------------------------------------------------------------------
fn get_last[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[leaf.length() - 1]
    Node(node) => get_last(node[node.length() - 1])
    Empty => abort("Index out of bounds")
  }
}

///-----------------------------------------------------------------------------
fn get[T](self : Tree[T], index : Int, shift : Int) -> T {
  match self {
    Leaf(leaf) => leaf[index & bitmask]
    Node(node) =>
      get(node[shr_as_uint(index, shift) & bitmask], index, shift - num_bits)
    Empty => abort("Index out of bounds")
  }
}

///-----------------------------------------------------------------------------
fn is_empty_tree[T](self : Tree[T]) -> Bool {
  match self {
    Tree::Empty => true
    _ => false
  }
}

///-----------------------------------------------------------------------------
fn new_branch[T](leaf : FixedArray[T], shift : Int) -> Tree[T] {
  match shift {
    0 => Leaf(leaf)
    s => Node([new_branch(leaf, s - num_bits)])
  }
}

///-----------------------------------------------------------------------------
fn add[T](self : Tree[T], index : Int, shift : Int, value : T) -> Tree[T] {
  match self {
    Leaf(l) => Leaf(immutable_push(l, value))
    Node(n) => {
      let idx = shr_as_uint(index, shift) & bitmask
      if idx < n.length() {
        Node(immutable_set(n, idx, n[idx].add(index, shift - num_bits, value)))
      } else {
        Node(immutable_push(n, new_branch([value], shift - num_bits)))
      }
    }
    Empty => Leaf([value])
  }
}
