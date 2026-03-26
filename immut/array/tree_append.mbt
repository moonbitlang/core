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

/// Tree-local helpers used by array push and tail normalization.

///|
fn append_sizes_last(sizes : FixedArray[Int]?, delta : Int) -> FixedArray[Int]? {
  match sizes {
    Some(sizes) => {
      let new_sizes = sizes.copy()
      new_sizes[new_sizes.length() - 1] += delta
      Some(new_sizes)
    }
    None => None
  }
}

///|
fn push_sizes_last(sizes : FixedArray[Int]?, delta : Int) -> FixedArray[Int]? {
  match sizes {
    Some(sizes) =>
      Some(immutable_push(sizes, delta + sizes[sizes.length() - 1]))
    None => None
  }
}

///|
/// Append a leaf to the right spine of a tree without going through generic tree concat.
fn[T] Tree::append_right_leaf(
  self : Tree[T],
  shift : Int,
  leaf : FixedArray[T],
) -> (Tree[T], Int) {
  let delta = leaf.length()
  guard delta > 0 else { return (self, shift) }

  fn worker(
    node : Tree[T],
    shift : Int,
    leaf : FixedArray[T],
    delta : Int,
  ) -> Tree[T]? {
    match node {
      Leaf(elems) => {
        guard shift == 0 else {
          abort("Unreachable: Leaf should only appear at shift 0")
        }
        if elems.length() + delta <= branching_factor {
          Some(Leaf(immutable_concat(elems, leaf)))
        } else {
          None
        }
      }
      Node(nodes, sizes) => {
        let len = nodes.length()
        match worker(nodes[len - 1], shift - num_bits, leaf, delta) {
          Some(new_node) =>
            Some(
              Node(
                immutable_set(nodes, len - 1, new_node),
                append_sizes_last(sizes, delta),
              ),
            )
          None =>
            if len < branching_factor {
              Some(
                Node(
                  immutable_push(nodes, new_branch_left(leaf, shift - num_bits)),
                  push_sizes_last(sizes, delta),
                ),
              )
            } else {
              None
            }
        }
      }
      Empty => Some(Leaf(leaf))
    }
  }

  match worker(self, shift, leaf, delta) {
    Some(new_tree) => (new_tree, shift)
    None => {
      let new_branch = new_branch_left(leaf, shift)
      (
        match self {
          Leaf(_) => Node([self, new_branch], None)
          Node(_, Some(sizes)) => {
            let len = sizes[sizes.length() - 1]
            Node([self, new_branch], Some([len, len + delta]))
          }
          Node(_, None) => Node([self, new_branch], None)
          Empty =>
            abort("Unreachable: Empty tree should have been handled in worker")
        },
        shift + num_bits,
      )
    }
  }
}

///|
/// Concatenate two trees while threading an extra right-most leaf from the left side
/// through the splice recursion, avoiding a full normalize-then-concat pass.
fn[T] Tree::concat_with_suffix(
  left : Tree[T],
  left_shift : Int,
  suffix : FixedArray[T],
  right : Tree[T],
  right_shift : Int,
  top : Bool,
) -> (Tree[T], Int) {
  if suffix.length() == 0 {
    return Tree::concat(left, left_shift, right, right_shift, top)
  }
  if left_shift > right_shift {
    let (c, c_shift) = Tree::concat_with_suffix(
      left.right_child(),
      left_shift - num_bits,
      suffix,
      right,
      right_shift,
      false,
    )
    guard c_shift == left_shift
    rebalance(left, c, Empty, left_shift, top)
  } else if right_shift > left_shift {
    let (c, c_shift) = Tree::concat_with_suffix(
      left,
      left_shift,
      suffix,
      right.left_child(),
      right_shift - num_bits,
      false,
    )
    guard c_shift == right_shift
    rebalance(Empty, c, right, right_shift, top)
  } else if left_shift == 0 {
    let leaves = FixedArray::from_array([left, Leaf(suffix), right])
    let (node_counts, new_len) = redis_plan(leaves)
    let new_children = redis(leaves, node_counts, new_len, 0)
    if top && new_len == 1 {
      (new_children[0], 0)
    } else {
      let node = Node(new_children, compute_sizes(new_children, 0))
      (node, num_bits)
    }
  } else {
    let (c, c_shift) = Tree::concat_with_suffix(
      left.right_child(),
      left_shift - num_bits,
      suffix,
      right.left_child(),
      right_shift - num_bits,
      false,
    )
    guard c_shift == left_shift
    guard c_shift == right_shift
    rebalance(left, c, right, left_shift, top)
  }
}
