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

let num_bits = 5

let branching_factor : Int = (1).lsl(num_bits)

let bitmask : Int = branching_factor - 1

pub fn Tree::empty[T]() -> Tree[T] {
  Tree::Empty
}

fn get_first[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[0]
    Node(node) => get_first(node[0])
    Empty => abort("Index out of bounds")
  }
}

fn get_last[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[leaf.length() - 1]
    Node(node) => get_last(node[node.length() - 1])
    Empty => abort("Index out of bounds")
  }
}

fn get[T](self : Tree[T], index : Int, shift : Int) -> T {
  match self {
    Tree::Leaf(leaf) => leaf[index.land(bitmask)]
    Node(node) =>
      get(node[index.lsr(shift).land(bitmask)], index, shift - num_bits)
    Empty => abort("Index out of bounds")
  }
}

fn is_empty_tree[T](self : Tree[T]) -> Bool {
  match self {
    Tree::Empty => true
    _ => false
  }
}