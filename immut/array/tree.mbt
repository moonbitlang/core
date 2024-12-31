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

/// A tree data structure that backs the `immut/array`.

///|
/// The controlling factor of the tree depth.
/// This is the only parameter you normally would adjust.
let num_bits = 2

///|
/// Invariant: `branching_factor` is a power of 2.
let branching_factor : Int = 1 << num_bits

///|
let bitmask : Int = branching_factor - 1

///|
/// The threshold for switching to a linear search.
const LINEAR_THRESHOLD : Int = 4

///|
/// The $e_{max}$ parameter of the search step invariant.
const E_MAX : Int = 2

///|
/// $e_{max} / 2$.
let e_max_2 : Int = E_MAX / 2

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
/// For each element in the tree, apply the function `f`.
fn each[A](self : Tree[A], f : (A) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(l) => l.each(f)
    Node(ns, _) => ns.each(fn(t) { t.each(f) })
  }
}

///|
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
/// Concatenate two trees.
/// Should be called as with `top = true`.
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
    guard c_shift == left_shift
    return rebalance(left, c, Empty, left_shift, top)
  } else if right_shift > left_shift {
    let (c, c_shift) = concat(
      left,
      left_shift,
      right.left_child(),
      right_shift - num_bits,
      false,
    )
    guard c_shift == right_shift
    return rebalance(Empty, c, right, right_shift, top)
  } else if left_shift == 0 {
    // Handle Leaf case
    let left_elems = left.leaf_elements()
    let right_elems = right.leaf_elements()
    let left_len = left_elems.length()
    let right_len = right_elems.length()
    let len = left_len + right_len
    if top && len <= branching_factor {
      return (
        Leaf(
          FixedArray::makei(len, fn(i : Int) {
            if i < left_len {
              left_elems[i]
            } else {
              right_elems[i - left_len]
            }
          }),
        ),
        0,
      )
    } else {
      return (
        Node(
          FixedArray::from_array([left, right]),
          Some(FixedArray::from_array([left_len, len])),
        ),
        num_bits,
      )
    }
  } else {
    // Handle Node case
    let (c, c_shift) = concat(
      left.right_child(),
      left_shift - num_bits,
      right.left_child(),
      right_shift - num_bits,
      false,
    )
    guard c_shift == left_shift
    guard c_shift == right_shift
    return rebalance(left, c, right, left_shift, top)
  }
}

///|
/// Given three `Node`s of the same height (`shift` / `num_bits`), rebalance them into two.
/// `top` is `true` if the resulting node has no upper node.
/// Returns the new node and its shift.
fn rebalance[A](
  left : Tree[A],
  center : Tree[A],
  right : Tree[A],
  shift : Int,
  top : Bool
) -> (Tree[A], Int) {
  // Suppose H = shift / num_bits
  let t = tri_merge(left, center, right) // t is a list of trees of (H-1) height
  let (nc, nc_len) = redis_plan(t)
  let new_t = redis(t, nc, nc_len, shift - num_bits) // new_t is a list of trees of (H-1) height
  guard new_t.length() == nc_len
  if nc_len <= branching_factor {
    // All nodes can be accommodated in a single node
    let node = Node(new_t, compute_sizes(new_t, shift - num_bits)) // node of H height
    if not(top) {
      return (Node(FixedArray::from_array([node]), None), shift + num_bits)
      // return (H+1) height node, add another layer to align with the case at the end of the thisfunction
    } else {
      return (node, shift)
      // return H height node, no upper node so no need to add another layer on top of it
    }
  } else {
    let new_child_1 = FixedArray::makei(branching_factor, fn(i) { new_t[i] })
    let new_child_2 = FixedArray::makei(new_t.length() - branching_factor, fn(
      i
    ) {
      new_t[i + branching_factor]
    })
    let new_node_1 = Node(
      new_child_1,
      compute_sizes(new_child_1, shift - num_bits),
    ) // height H
    let new_node_2 = Node(
      new_child_2,
      compute_sizes(new_child_2, shift - num_bits),
    ) // height H
    let new_children = FixedArray::from_array([new_node_1, new_node_2])
    return (
      Node(new_children, compute_sizes(new_children, shift)),
      shift + num_bits,
    ) // return (H+1) height node
  }
}

///|
/// Given three trees of the same height (if not `Empty`), merge them into one.
/// `left` and `right` might be `Node` or `Empty`.
/// `center` is always a `Node`.
/// The resulting array might be longer than `branching_factor`,
/// which will be handled by `rebalance` later.
/// 
/// Preconditions:
/// - `left` and `right` are `Empty` or `Node`.
/// - `center` is `Node`.
/// 
/// Postconditions:
/// - The resulting array is of length `left.size() + center.size() + right.size()`.
/// - The height of a `Tree` in the resulting array is one less than the height of the input `Tree`s.
fn tri_merge[A](
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
  let left_len = if left_len == 0 { 0 } else { left_len - 1 }
  let center_len = center_children.length()
  let right_len = right_children.length()
  let right_len = if right_len == 0 { 0 } else { right_len - 1 }
  FixedArray::makei(left_len + center_len + right_len, fn(i) {
    if i < left_len {
      left_children[i]
    } else if i < left_len + center_len {
      center_children[i - left_len]
    } else if right_len > 0 {
      right_children[1 + i - left_len - center_len]
    } else {
      abort("Unreachable")
    }
  })
}

///|
/// Create a redistribution plan for the tree.
fn redis_plan[A](t : FixedArray[Tree[A]]) -> (FixedArray[Int], Int) {
  let node_counts = FixedArray::makei(t.length(), fn { i => t[i].local_size() })
  let total_nodes = node_counts.fold(init=0, fn { acc, x => acc + x })
  // round up to the nearest integer of S/branching_factor
  let opt_len = (total_nodes + branching_factor - 1) / branching_factor
  let mut new_len = t.length()
  let mut i = 0
  while opt_len + e_max_2 < new_len {
    // Skip over all nodes satisfying the invariant.
    while node_counts[i] > branching_factor - e_max_2 {
      i += 1
    }

    // Found short node, so redistribute over the next nodes
    let mut remaining_nodes = node_counts[i]
    while remaining_nodes > 0 {
      let min_size = min(remaining_nodes + node_counts[i + 1], branching_factor)
      node_counts[i] = min_size
      remaining_nodes = remaining_nodes + node_counts[i + 1] - min_size
      i += 1
    }
    for j = i; j < new_len - 1; j = j + 1 {
      node_counts[j] = node_counts[j + 1]
    }
    new_len -= 1
    i -= 1
  }
  return (node_counts, new_len)
}

///|
/// This function redistributes the nodes in `old_t` according to the plan in `node_counts`.
/// 
/// Preconditions:
/// - forall i in 0..node_nums, old_t[i] != Empty.
/// - `old_t` contains a list of trees, each of (`shift` / `num_bits`) height.
/// - `node_counts` contains the number of children of each node in `new_t` (the redistributed version of `old_t`).
/// - `node_nums` is the length of `node_counts`.
/// 
/// Postcondition:
/// - The resulting trees in `new_t` are of the same height as trees in `old_t`.
fn redis[A](
  old_t : FixedArray[Tree[A]],
  node_counts : FixedArray[Int],
  node_nums : Int,
  shift : Int
) -> FixedArray[Tree[A]] {
  let old_len = old_t.length()
  let new_t = FixedArray::make(node_nums, Empty)
  let mut old_offset = 0
  let mut j = 0 // the index of in the old tree
  if shift == 0 {
    // Handle Leaf case
    for i = 0; i < node_nums; i = i + 1 {
      // t[j] is the next to be redistributed
      // old_offset is the index of the next node to be redistributed in old_t[j]
      //   old_offset == 0 means all nodes in old_t[j] are to be redistributed 
      // new_t[i] is the current node to be filled with redistributed nodes
      let old_leaf_elems = old_t[i].leaf_elements()
      let old_leaf_len = old_leaf_elems.length()
      if old_offset == 0 && old_leaf_len == node_counts[i] {
        // Perfect, we just point to the old leaf
        new_t[i] = old_t[i]
      } else {
        let mut new_offset = 0 // the accumulated number of elements in the new leaf
        let new_leaf_len = node_counts[i]
        let new_elems = FixedArray::make(new_leaf_len, old_leaf_elems[0])
        while new_offset < node_counts[i] {
          guard j < old_len  // This shouldn't be triggered if the plan was correctly generated
          let remaining = min(
            node_counts[i] - new_offset,
            old_leaf_len - old_offset,
          )
          FixedArray::unsafe_blit(
            new_elems, new_offset, old_leaf_elems, old_offset, remaining,
          )
          new_offset += remaining
          old_offset += remaining
          if old_offset == old_leaf_len {
            j += 1
            old_offset = 0
          }
        }
        new_t[i] = Leaf(new_elems)
      }
    }
  } else {
    // Handle Node case, pretty much the same as the Leaf case
    for i = 0; i < node_nums; i = i + 1 {
      let old_node_chldrn = old_t[i].node_children()
      let old_node_len = old_node_chldrn.length()
      if old_offset == 0 && old_node_len == node_counts[i] {
        new_t[i] = old_t[i]
      } else {
        let mut new_offset = 0
        let new_node_len = node_counts[i]
        let new_node_chldrn = FixedArray::make(new_node_len, old_node_chldrn[0])
        while new_offset < node_counts[i] {
          guard j < old_len
          let remaining = min(
            node_counts[i] - new_offset,
            old_node_len - old_offset,
          )
          FixedArray::unsafe_blit(
            new_node_chldrn, new_offset, old_node_chldrn, old_offset, remaining,
          )
          new_offset += remaining
          old_offset += remaining
          if old_offset == old_node_len {
            j += 1
            old_offset = 0
          }
        }
        new_t[i] = Node(new_node_chldrn, compute_sizes(new_node_chldrn, shift)) // each node in `new_t` is of height (`shift` / `num_bits`)
      }
    }
  }
  new_t
}

///|
/// Given a list of trees as `children` with heights of (`shift` / `num_bits`), compute the sizes array of the subtrees.
fn compute_sizes[A](
  children : FixedArray[Tree[A]],
  shift : Int
) -> FixedArray[Int]? {
  let len = children.length()
  let sizes = FixedArray::make(len, 0)
  let mut sum = 0
  let mut flag = true
  let full_subtree_size = branching_factor << shift
  for i = 0; i < len; i = i + 1 {
    let sz = children[i].size(shift)
    flag = flag && sz == full_subtree_size
    sum += sz
    sizes[i] = sum
  }
  if flag {
    None
  } else {
    Some(sizes)
  }
}

///|
/// Print the tree structure.
impl[A : Show] Show for Tree[A] with output(self, logger : &Logger) {
  fn indent_str(s : String, indent : Int) -> String {
    String::make(indent, ' ') + s
  }

  fn rec(t : Tree[A], ident : Int) {
    match t {
      Empty => indent_str("Empty", ident)
      Leaf(l) => {
        let mut s = "Leaf("
        for i = 0; i < l.length(); i = i + 1 {
          s += l[i].to_string()
          if i != l.length() - 1 {
            s += ", "
          }
        }
        s += ")"
        indent_str(s, ident) + "\n"
      }
      Node(children, _sizes) => {
        let mut s = indent_str("Node(", ident) + "\n"
        for i = 0; i < children.length(); i = i + 1 {
          s += rec(children[i], ident + 2)
        }
        s + indent_str(")", ident) + "\n"
      }
    }
  }

  logger.write_string(rec(self, 0))
}
