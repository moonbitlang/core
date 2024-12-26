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

///|
let num_bits = 5

///|
/// Invariant: `branching_factor` is a power of 2.
let branching_factor : Int = 1 << num_bits

///|
let bitmask : Int = branching_factor - 1

///|
/// The threshold for switching to a linear search.
const LINEAR_THRESHOLD : Int = 4

///|
fn Tree::empty[T]() -> Tree[T] {
  Tree::Empty
}

///|
fn get_first[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[0]
    Node(node, _) => get_first(node[0]) // TODO: prove that this should always be non-zero
    Empty => abort("Index out of bounds")
  }
}

///|
fn get_last[T](self : Tree[T]) -> T {
  match self {
    Leaf(leaf) => leaf[leaf.length() - 1]
    Node(node, _) => get_last(node[node.length() - 1]) // TODO: prove that this should always be non-zero 
    Empty => abort("Index out of bounds")
  }
}

///|
fn get[T](self : Tree[T], index : Int, shift : Int) -> T {
  fn get_radix(node : Tree[T], shift : Int) -> T {
    match node {
      Leaf(leaf) => leaf[index & bitmask]
      Node(node, None) =>
        get_radix(node[radix_indexing(index, shift)], shift - num_bits)
      Node(_, Some(_)) =>
        abort("Unreachable: Node should not have sizes in get_radix")
      Empty => abort("Index out of bounds")
    }
  }

  match self {
    Leaf(leaf) => leaf[index]
    Node(children, Some(sizes)) => {
      let branch_index = get_branch_index(sizes, index)
      let sub_index = index - sizes[branch_index]
      get(children[branch_index], sub_index, shift - num_bits)
    }
    Node(_, None) => get_radix(self, shift)
    Empty => abort("Index out of bounds")
  }
}

///|
fn set[T](self : Tree[T], index : Int, shift : Int, value : T) -> Tree[T] {
  fn set_radix(node : Tree[T], shift : Int) -> Tree[T] {
    match node {
      Leaf(leaf) => Leaf(immutable_set(leaf, index & bitmask, value))
      Node(node, None) => {
        let sub_idx = radix_indexing(index, shift)
        Node(
          immutable_set(
            node,
            sub_idx,
            set_radix(node[radix_indexing(index, shift)], shift - num_bits),
          ),
          None,
        )
      }
      Node(_, Some(_)) =>
        abort("Unreachable: Node should not have sizes in set_radix")
      Empty => abort("Index out of bounds")
    }
  }

  match self {
    Leaf(leaf) => Leaf(immutable_set(leaf, index & bitmask, value))
    Node(children, Some(sizes)) => {
      let branch_index = get_branch_index(sizes, index)
      let sub_index = index - sizes[branch_index]
      Node(
        immutable_set(
          children,
          branch_index,
          children[branch_index].set(sub_index, shift - num_bits, value),
        ),
        Some(sizes.copy()),
      )
    }
    Node(_children, None) => set_radix(self, shift)
    Empty => abort("Index out of bounds")
  }
}

///|
fn is_empty_tree[T](self : Tree[T]) -> Bool {
  match self {
    Tree::Empty => true
    _ => false
  }
}

///|
/// Create a new tree with a single leaf. Note that the resulting tree is a left-skewed tree.
fn new_branch_left[T](leaf : FixedArray[T], shift : Int) -> Tree[T] {
  match shift {
    0 => Leaf(leaf)
    s => Node([new_branch_left(leaf, s - num_bits)], None) // size is None because we can use radix indexing
  }
}

///|
/// Push a value to the end of the tree.
/// Precondition:
/// - The height of `self` = `shift` / `num_bits` (the height starts from 0).
/// - `length` is the number of elements in the tree.
fn push_end[T](self : Tree[T], shift : Int, value : T) -> (Tree[T], Int) {
  fn update_sizes_last(sizes : FixedArray[Int]?) -> FixedArray[Int]? {
    match sizes {
      Some(sizes) => {
        let new_sizes = sizes.copy()
        new_sizes[new_sizes.length() - 1] += 1
        Some(new_sizes)
      }
      None => None
    }
  }

  fn push_sizes_last(sizes : FixedArray[Int]?) -> FixedArray[Int]? {
    match sizes {
      Some(sizes) => Some(immutable_push(sizes, 1))
      None => None
    }
  }

  fn worker(node : Tree[T], shift : Int) -> Tree[T]? {
    match node {
      Leaf(leaf) => {
        if shift != 0 {
          abort(
            "Unreachable: Leaf should not have a non-zero shift, which means we have not reached the bottom of the tree",
          )
        }
        if leaf.length() < branching_factor {
          Some(Leaf(immutable_push(leaf, value)))
        } else {
          None
        }
      }
      Node(nodes, sizes) => {
        let len = nodes.length()
        match worker(nodes[len - 1], shift - num_bits) {
          // We have successfully pushed the value, now duplicate its ancestor nodes.
          Some(new_node) => {
            let new_nodes = nodes.copy()
            new_nodes[len - 1] = new_node
            Some(Node(new_nodes, update_sizes_last(sizes)))
          }
          // We need to create a new node to push the value.
          None =>
            if len < branching_factor {
              Some(
                Node(
                  immutable_push(
                    nodes,
                    new_branch_left([value], shift - num_bits),
                  ),
                  push_sizes_last(sizes),
                ),
              )
            } else {
              None
            }
        }
      }
      Empty => Some(Leaf([value]))
    }
  }

  match worker(self, shift) {
    Some(new_tree) => (new_tree, shift)
    None => {
      let new_branch = new_branch_left([value], shift)
      (
        match self {
          Leaf(_leaf) => Node([self, new_branch], None)
          Node(_nodes, Some(sizes)) =>
            Node([self, new_branch], Some([sizes[sizes.length() - 1], 1]))
          Node(_nodes, None) => Node([self, new_branch], None)
          Empty =>
            abort(
              "Unreachable: Empty tree should have fallen into the Some(new_tree) branch",
            )
        },
        shift + num_bits,
      )
    }
  }
}

///|
/// 
/// For each element in the tree, apply the function `f`.
fn each[A](self : Tree[A], f : (A) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(l) => l.each(f)
    Node(ns, _) => ns.each(fn(t) { t.each(f) })
  }
}

///|
///
/// For each element in the tree, apply the function `f` with the index of the element.
fn eachi[A](
  self : Tree[A],
  f : (Int, A) -> Unit,
  shift : Int,
  start : Int
) -> Unit {
  match self {
    Empty => ()
    Leaf(l) =>
      for i = 0; i < l.length(); i = i + 1 {
        f(start + i, l[i])
      }
    Node(ns, None) => {
      let child_shift = shift - num_bits
      let mut start = start
      for i = 0; i < ns.length(); i = i + 1 {
        ns[i].eachi(f, child_shift, start)
        start += 1 << shift
      }
    }
    Node(ns, Some(sizes)) => {
      let child_shift = shift - num_bits
      let mut start = start
      for i = 0; i < ns.length(); i = i + 1 {
        ns[i].eachi(f, child_shift, start)
        start += sizes[i]
      }
    }
  }
}

///|
/// Fold the tree.
fn fold[A, B](self : Tree[A], acc : B, f : (B, A) -> B) -> B {
  match self {
    Empty => acc
    Leaf(l) => l.fold(f, init=acc)
    Node(n, _) => n.fold(fn(acc, t) { t.fold(acc, f) }, init=acc)
  }
}

///|
/// Fold the tree in reverse order.
fn rev_fold[A, B](self : Tree[A], acc : B, f : (B, A) -> B) -> B {
  match self {
    Empty => acc
    Leaf(l) => l.rev_fold(f, init=acc)
    Node(n, _) => n.rev_fold(fn(acc, t) { t.rev_fold(acc, f) }, init=acc)
  }
}

///|
/// Map the tree.
fn map[A, B](self : Tree[A], f : (A) -> B) -> Tree[B] {
  match self {
    Empty => Empty
    Leaf(l) => Leaf(l.map(f))
    Node(n, szs) =>
      Node(
        FixedArray::makei(n.length(), fn(i) { n[i].map(f) }),
        copy_sizes(szs),
      )
  }
}

///|
fn concat[A](
  left : Tree[A],
  left_shift : Int,
  right : Tree[A],
  right_shift : Int,
  top : Bool
) -> (Tree[A], Int) {
  if left_shift > right_shift {
    let (c, c_shift) = concat(
      left.right_child(),
      left_shift - num_bits,
      right,
      right_shift,
      false,
    )
    return rebalance(left, left_shift, c, c_shift, Empty, 0, false), 
  } else if right_shift > left_shift {
    let (c, c_shift) = concat(
      left,
      left_shift,
      right.left_child(),
      right_shift - num_bits,
      false,
    )
    return rebalance(Empty, 0, c, c_shift, right, right_shift, false)
  }
  else {

    if left_shift == 0 {
        let left_elems = left.leaf_elements()
        let right_elems = right.leaf_elements()
        let left_len = left_elems.length()
        let right_len = right_elems.length()
        let len =  left_len+right_len
      let children = {
        if top && len <= branching_factor{
           [Leaf(FixedArray::makei(len, fn (i: Int) { if i < left_len {left_elems[i]} else {right_elems[i-left_len]}}))]
        }
        else {
          [left, right]
        }
      }
      return Node(children, None)
    } else {
      let c = concat(left.right_child(), left_child - num_bits, right.left_child(), right_child - num_bits, false)
      return rebalance()
    }
  }
}

///|
/// Given three `Node`s of the same height, rebalance them into two.
fn rebalance[A](
  left : Tree[A],
  center : Tree[A],
  right : Tree[A],
  shift : Int,
  top : Bool
) -> Tree[A] {
  let t = merge(left, center, right)

}

///|
/// Given three trees of the same height (if not `Empty`), merge them into one.
/// `left` and `right` might be `Node` or `Empty`.
/// `center` is always a `Node`.
/// The resulting array might be longer than `branching_factor`,
/// which will be handled by `rebalance` later.
fn merge[A](
  left : Tree[A],
  center : Tree[A],
  right : Tree[A]
) -> FixedArray[Tree[A]] {
  if left.is_leaf() || not(center.is_node()) || right.is_leaf() {
    abort("Unreachable: input to merge is invalid")
  }
  fn get_children(self : Tree[A]) -> FixedArray[Tree[A]] {
    match self {
      Node(children, _) => children
      Empty => []
      Leaf(_) => abort("Unreachable")
    }
  }

  let left_children = get_children(left)
  let center_children = get_children(center)
  let right_children = get_children(right)
  let left_len = left_children.length()
  let center_len = center_children.length()
  let right_len = right_children.length()
  FixedArray::makei(left_len + center_len + right_len, fn(i) {
    if i < left_len {
      left_children[i]
    } else if i < left_len + center_len {
      center_children[i - left_len]
    } else {
      right_children[i - left_len - center_len]
    }
  })
}

///|
fn concat_plan[A](t : FixedArray[Tree[A]]) -> (FixedArray[Int], Int) {
  let c = FixedArray::make(t.length(), fn(i : Int) { t[i].num_children() })
  let S = c.fold(init=0, fn(acc, x) { acc + x })
  // round up to the nearest integer of S/branching_factor
  let opt_len = (S + branching_factor - 1) / branching_factor
  let mut n = t.length()
  let mut i = 0
  

}

///|
fn is_node[A](self : Tree[A]) -> Bool {
  match self {
    Node(_, _) => true
    _ => false
  }
}

///|
fn is_leaf[A](self : Tree[A]) -> Bool {
  match self {
    Leaf(_) => true
    _ => false
  }
}

///|
fn is_empty[A](self : Tree[A]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

///|
/// Get the rightmost child of a tree node. Abort if
/// it is not a `Node`.
fn right_child[A](self : Tree[A]) -> Tree[A] {
  match self {
    Node(children, _) => children[-1]
    Leaf(_) | Empty => abort("Should not get children on non-`Node`s")
  }
}

///|
/// Get the leftmost child of a tree node. Abort if
/// it is not a `Node`.
fn left_child[A](self : Tree[A]) -> Tree[A] {
  match self {
    Node(children, _) => children[0]
    Leaf(_) | Empty => abort("Should not get children on non-`Node`s")
  }
}

///|
/// Get the leaf contents. Abort if it is not a `Leaf`.
fn leaf_elements[A](self : Tree[A]) -> FixedArray[A] {
  match self {
    Leaf(children) => children
    _ => abort("Should not call `get_leaf_elements` on non-leaf nodes")
  }
}

///|
/// Get the length of the current node, not the total number of elements in the tree.
fn num_children[A](self : Tree[A]) -> Int {
  match self {
    Empty => 0
    Leaf(l) => l.length()
    Node(children, _) => children.length()
  }
}
