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

/// Tree-local slicing helpers used by vector slice/split.

///|
fn[A] Tree::slice_right(self : Tree[A], shift : Int, end : Int) -> Tree[A] {
  guard end > 0 else { return Empty }
  guard end < self.size(shift) else { return self }
  match self {
    Empty => Empty
    Leaf(leaf) => Leaf(immutable_slice(leaf, 0, end))
    Node(children, sizes) => {
      let child_shift = shift - num_bits
      let child_index = match sizes {
        Some(sizes) => get_branch_index(sizes, end - 1)
        None => radix_indexing(end - 1, shift)
      }
      let child_start = match sizes {
        Some(sizes) => if child_index == 0 { 0 } else { sizes[child_index - 1] }
        None => child_index * (1 << shift)
      }
      let new_len = child_index + 1
      let new_children = FixedArray::make(new_len, children[0])
      for i in 0..<child_index {
        new_children[i] = children[i]
      }
      new_children[child_index] = children[child_index].slice_right(
        child_shift,
        end - child_start,
      )
      Node(new_children, compute_sizes(new_children, child_shift))
    }
  }
}

///|
fn[A] Tree::slice_left(self : Tree[A], shift : Int, start : Int) -> Tree[A] {
  guard start > 0 else { return self }
  match self {
    Empty => Empty
    Leaf(leaf) => Leaf(immutable_slice(leaf, start, leaf.length()))
    Node(children, sizes) => {
      let child_shift = shift - num_bits
      let child_index = match sizes {
        Some(sizes) => get_branch_index(sizes, start)
        None => radix_indexing(start, shift)
      }
      let child_start = match sizes {
        Some(sizes) =>
          if child_index == 0 {
            start
          } else {
            start - sizes[child_index - 1]
          }
        None => start - child_index * (1 << shift)
      }
      let new_len = children.length() - child_index
      let new_children = FixedArray::make(
        new_len,
        children[child_index].slice_left(child_shift, child_start),
      )
      for i in 1..<new_len {
        new_children[i] = children[child_index + i]
      }
      Node(new_children, compute_sizes(new_children, child_shift))
    }
  }
}
