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

/// Tree-local helpers used by vector pop.

///|
fn[A] Tree::last_leaf_elements(self : Tree[A]) -> FixedArray[A] {
  match self {
    Leaf(leaf) => leaf
    Node(children, _) => children[children.length() - 1].last_leaf_elements()
    Empty => abort("Empty tree has no last leaf")
  }
}

///|
fn[A] Tree::pop_rightmost_leaf(self : Tree[A], shift : Int) -> Tree[A] {
  match self {
    Empty | Leaf(_) => Empty
    Node(children, _) => {
      let last_index = children.length() - 1
      let new_last = children[last_index].pop_rightmost_leaf(shift - NUM_BITS)
      if new_last is Empty {
        if last_index == 0 {
          Empty
        } else {
          let new_children = immutable_slice(children, 0, last_index)
          Node(new_children, compute_sizes(new_children, shift - NUM_BITS))
        }
      } else {
        let new_children = immutable_set(children, last_index, new_last)
        Node(new_children, compute_sizes(new_children, shift - NUM_BITS))
      }
    }
  }
}

///|
fn[A] Tree::shrink_top(self : Tree[A], shift : Int) -> (Tree[A], Int) {
  let mut current_shift = shift
  for tree = self {
    match tree {
      Node(children, _) if current_shift > 0 && children.length() == 1 => {
        current_shift -= NUM_BITS
        continue children[0]
      }
      Empty => break (Empty, 0)
      current => break (current, current_shift)
    }
  }
}
