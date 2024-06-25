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

// This file implements a mutable set using a red-black tree.
// The functions are organized in groups of related operations.
// Each public function is followed by subroutines that are used to implement it.
// All tests are at the end of the file.

// # Node allocation functions. 
// All memory allocation is done by them. We try to avoid memory allocation as
// much as possible, since it is one of the major reasons that we use mutable
// set.

// Construct a empty MutableSet.
pub fn MutableSet::new[T]() -> MutableSet[T] {
  { root: None, size: 0L }
}

/// Returns the one-value MutableSet containing only `value`.
pub fn MutableSet::singleton[T : Compare](value : T) -> MutableSet[T] {
  {
    root: Some(
      {
        color: Black,
        left: None,
        value: Some(value),
        right: None,
        parent: None,
      },
    ),
    size: 1L,
  }
}

/// Returns a deep clone of the MutableSet.
/// 
/// FIXME: it is just copying the tree structure, not the values.
///        It requires a Clone trait on T, which we don't have yet.
pub fn deep_clone[T](self : MutableSet[T]) -> MutableSet[T] {
  match self.root {
    None => MutableSet::new()
    Some(_) => { root: deep_clone_tree(self.root), size: self.size }
  }
}

fn new_node[T](color : Color, value : T, parent : Node[T]?) -> Node[T] {
  let left = new_nil()
  let right = new_nil()
  let ret = new_node_full(color, left, Some(value), right, parent)
  set_parent(ret.left, Some(ret))
  set_parent(ret.right, Some(ret))
  ret
}

fn new_node_full[T](
  color : Color,
  left : Node[T]?,
  value : T?,
  right : Node[T]?,
  parent : Node[T]?
) -> Node[T] {
  { color, left, value, right, parent }
}

fn new_nil[T]() -> Node[T]? {
  Some({ color: Black, left: None, value: None, right: None, parent: None })
}

fn new_set[T](root : Node[T]?, size : Int64) -> MutableSet[T] {
  { root, size }
}

fn deep_clone_tree[T](node : Node[T]?) -> Node[T]? {
  match node {
    None => None
    Some(node) => {
      let left = deep_clone_tree(node.left)
      let right = deep_clone_tree(node.right)
      let new_node = new_node_full(node.color, left, node.value, right, None)
      set_parent(left, Some(new_node))
      set_parent(right, Some(new_node))
      Some(new_node)
    }
  }
}

fn new_tree[T](root : Node[T]?, size : Int64) -> MutableSet[T] {
  { root, size }
}

// # Add

/// Add a value into the set.
pub fn add[T : Compare](self : MutableSet[T], value : T) -> Unit {
  fn aux(n : Node[T]?, value : T) -> Unit {
    match n {
      None => abort("Impossible to reach")
      Some(node) => {
        let compare_result = value.compare(get_value(n))
        if compare_result == 0 {
          ()
        } else if compare_result < 0 {
          if is_nil(node.left) {
            let l = new_node(Red, value, n) // New node allocation
            node.left = Some(l)
            add_fix(node)
          } else {
            aux(node.left, value)
            add_fix(node)
          }
        } else if is_nil(node.right) {
          let r = new_node(Red, value, n) // New node allocation
          node.right = Some(r)
          add_fix(node)
        } else {
          aux(node.right, value)
          add_fix(node)
        }
      }
    }
  }

  match self.root {
    None => self.root = Some(new_node(Black, value, None))
    Some(_) => {
      aux(self.root, value)
      match self.root {
        Some(_) => set_color(self.root, Black)
        None => abort("Impossible to reach")
      }
    }
  }
  self.size += 1L
}

fn add_fix[T : Compare](parent : Node[T]) -> Unit {
  // Cite: Red-Black Trees in a Functional Setting by Chris Okasaki
  match parent {
    {
      color: Black,
      left: Some(
        {
          color: Red,
          left: Some({ color: Red, left: a, value: x, right: b, .. } as r),
          value: y,
          right: c,
          ..,
        }
        as
        l
      ),
      value: z,
      right: d,
      ..,
    }
    | {
      color: Black,
      left: Some(
        {
          color: Red,
          left: a,
          value: x,
          right: Some({ color: Red, left: b, value: y, right: c, .. } as r),
          ..,
        }
        as
        l
      ),
      value: z,
      right: d,
      ..,
    }
    | {
      color: Black,
      left: a,
      value: x,
      right: Some(
        {
          color: Red,
          left: Some({ color: Red, left: b, value: y, right: c, .. } as l),
          value: z,
          right: d,
          ..,
        }
        as
        r
      ),
      ..,
    }
    | {
      color: Black,
      left: a,
      value: x,
      right: Some(
        {
          color: Red,
          left: b,
          value: y,
          right: Some({ color: Red, left: c, value: z, right: d, .. } as l),
          ..,
        }
        as
        r
      ),
      ..,
    } => {
      parent.value = y
      parent.color = Red

      // parent.left = Some(new_node_full(Black, a, x, b, Some(parent)))
      parent.left = Some(l)
      l.color = Black
      l.value = x
      l.left = a
      l.right = b
      l.parent = Some(parent)
      set_parent(a, parent.left)
      set_parent(b, parent.left)

      // parent.right = new_node_full(Black, c, z, d, Some(parent))
      parent.right = Some(r)
      r.color = Black
      r.value = z
      r.left = c
      r.right = d
      r.parent = Some(parent)
      set_parent(c, parent.right)
      set_parent(d, parent.right)
    }
    _ => ()
  }
}

// # Remove

/// Remove a value from the MutableSet. If the value is not in the set, nothing happens.
pub fn remove[T : Compare](self : MutableSet[T], value : T) -> Unit {
  // Cite: https://github.com/fgoncalves/Generic-Red-Black-Tree/blob/master/rbtree.c
  let z = search_node(self, value)
  if z == None {
    // nothing to remove
    return
  }
  let mut original_color = get_color(z)
  let z_right = get_right(z)
  let mut x = Option::None
  if is_nil(get_left(z)) {
    if is_nil(get_right(z)) && same_pointer(z, self.root) {
      // remove the last node in the tree
      self.root = None
      return
    }
    x = z_right
    transplant(self, z, z_right)
  } else if is_nil(z_right) {
    x = get_left(z)
    transplant(self, z, x)
  } else {
    let y = min_node(z_right)
    original_color = get_color(y)
    x = get_right(y)
    if same_pointer(get_parent(y), z) {
      set_parent(x, y)
    } else {
      transplant(self, y, get_right(y))
      set_right(y, z_right)
      set_parent(get_right(y), y)
    }
    transplant(self, z, y)
    set_left(y, get_left(z))
    set_parent(get_left(y), y)
    set_color(y, get_color(z))
  }
  if original_color == Black {
    remove_fix(self, x)
  }
  self.size -= 1L
}

fn remove_fix[T](root : MutableSet[T], x : Node[T]?) -> Unit {
  let mut x = x
  while not(same_pointer(x, root.root)) && get_color(x) == Black {
    let x_parent = get_parent(x)
    if same_pointer(x, get_left(x_parent)) {
      let mut w = get_right(x_parent)
      if get_color(w) == Red {
        set_color(w, Black)
        set_color(x_parent, Red)
        rotate_left(Some(root), x_parent)
        w = get_right(x_parent)
      }
      if get_color(get_left(w)) == Black && get_color(get_right(w)) == Black {
        set_color(w, Red)
        x = x_parent
      } else {
        if get_color(get_right(w)) == Black {
          set_color(get_left(w), Black)
          set_color(w, Red)
          rotate_right(Some(root), w)
          w = get_right(x_parent)
        }
        set_color(w, get_color(x_parent))
        set_color(x_parent, Black)
        set_color(get_right(w), Black)
        rotate_left(Some(root), x_parent)
        x = root.root
      }
    } else {
      let mut w = get_left(x_parent)
      if get_color(w) == Red {
        set_color(w, Black)
        set_color(x_parent, Red)
        rotate_right(Some(root), x_parent)
        w = get_left(x_parent)
      }
      if get_color(get_right(w)) == Black && get_color(get_left(w)) == Black {
        set_color(w, Red)
        x = x_parent
      } else {
        if get_color(get_left(w)) == Black {
          set_color(get_right(w), Black)
          set_color(w, Red)
          rotate_left(Some(root), w)
          w = get_left(x_parent)
        }
        set_color(w, get_color(x_parent))
        set_color(x_parent, Black)
        set_color(get_left(w), Black)
        rotate_right(Some(root), x_parent)
        x = root.root
      }
    }
  }
  set_color(x, Black)
}

fn transplant[T](tree : MutableSet[T], u : Node[T]?, v : Node[T]?) -> Unit {
  match u {
    None => abort("Impossible to reach") // why transplant an empty tree?
    Some(u_inner) => {
      match u_inner.parent {
        None => tree.root = v
        Some(u_parent) =>
          if physical_equal(u, u_parent.left) {
            u_parent.left = v
          } else {
            u_parent.right = v
          }
      }
      set_parent(v, u_inner.parent)
    }
  }
}

fn search_node[T : Compare](tree : MutableSet[T], value : T) -> Node[T]? {
  loop tree.root, value {
    Some({ left, value: node_value, right, .. }) as n, value => {
      if node_value == None {
        return None
      }
      let compare_result = value.compare(get_value(n))
      if compare_result == 0 {
        n
      } else if compare_result < 0 {
        continue left, value
      } else {
        continue right, value
      }
    }
    None, _ => None
  }
}

fn rotate_left[T](root : MutableSet[T]?, x : Node[T]?) -> Unit {
  let y = get_right(x)
  set_right(x, get_left(y))
  set_parent(get_left(y), x)
  let x_parent = get_parent(x)
  set_parent(y, x_parent)
  match x_parent {
    None =>
      match root {
        Some(root) => root.root = y
        None => ()
      }
    Some(_) =>
      if same_pointer(x, get_left(x_parent)) {
        set_left(x_parent, y)
      } else {
        set_right(x_parent, y)
      }
  }
  set_left(y, x)
  set_parent(x, y)
}

fn rotate_right[T](root : MutableSet[T]?, x : Node[T]?) -> Unit {
  let y = get_left(x)
  set_left(x, get_right(y))
  set_parent(get_right(y), x)
  let x_parent = get_parent(x)
  set_parent(y, x_parent)
  match x_parent {
    None =>
      match root {
        Some(root) => root.root = y
        None => ()
      }
    Some(_) =>
      if same_pointer(x, get_right(x_parent)) {
        set_right(x_parent, y)
      } else {
        set_left(x_parent, y)
      }
  }
  set_right(y, x)
  set_parent(x, y)
}

fn min_node[T : Compare](tree : Node[T]?) -> Node[T]? {
  let mut rt = tree
  loop tree {
    None => rt
    Some({ left, .. }) =>
      match left {
        None => rt
        Some(_) => {
          if not(is_nil(left)) {
            rt = left
          }
          continue left
        }
      }
  }
}

// # Set operations
// Including union, intersection, difference, subset, disjoint, contains.
// Note that these functions return a new set that doesn't share memory with
// the original set, and the original sets are not modified.

/// Returns the union of two sets.
pub fn union[T : Compare](
  self : MutableSet[T],
  src : MutableSet[T]
) -> MutableSet[T] {
  fn aux(a : Node[T]?, b : Node[T]?) -> Node[T]? {
    match (a, b) {
      (Some(_), Some(_)) =>
        if is_nil(a) {
          b
        } else if is_nil(b) {
          a
        } else {
          let v = get_value(b)
          let (l1, r1) = split(a, v)
          join(aux(l1, get_left(b)), v, aux(r1, get_right(b)))
        }
      (Some(_), None) => a
      (None, Some(_)) => b
      (None, None) => abort("Impossible to reach")
    }
  }

  match (self.root, src.root) {
    (Some(_), Some(_)) => {
      let t1 = deep_clone_tree(self.root)
      let t2 = deep_clone_tree(src.root)
      let t = aux(t1, t2)
      let mut ct = 0L
      let ret = new_set(t, 0L)
      // TODO: optimize this. Avoid counting the size of the set.
      ret.iter(fn(_x) { ct = ct + 1L })
      ret.size = ct
      ret
    }
    (Some(_), None) => new_set(deep_clone_tree(self.root), self.size)
    (None, Some(_)) => new_set(deep_clone_tree(src.root), src.size)
    (None, None) => new()
  }
}

/// Return if a value is contained in the set.
pub fn contains[T : Compare](self : MutableSet[T], value : T) -> Bool {
  loop self.root, value {
    None, _ => false
    Some({ left, right, .. }) as n, value => {
      if is_nil(n) {
        return false
      }
      let compare_result = value.compare(get_value(n))
      if compare_result == 0 {
        true
      } else if compare_result < 0 {
        continue left, value
      } else {
        continue right, value
      }
    }
  }
}

/// Returns the difference of two sets.
pub fn diff[T : Compare](
  self : MutableSet[T],
  src : MutableSet[T]
) -> MutableSet[T] {
  let ret = MutableSet::new()
  self.iter(fn(x) { if not(src.contains(x)) { ret.add(x) } })
  ret
}

/// Returns the intersection of two sets.
pub fn intersect[T : Compare](
  self : MutableSet[T],
  src : MutableSet[T]
) -> MutableSet[T] {
  let ret = MutableSet::new()
  self.iter(fn(x) { if src.contains(x) { ret.add(x) } })
  ret
}

/// Returns if a set is a subset of another set.
pub fn subset[T : Compare](self : MutableSet[T], src : MutableSet[T]) -> Bool {
  let mut ret = true
  self.iter(fn(x) { if not(src.contains(x)) { ret = false } })
  ret
}

/// Returns if two sets are disjoint.
pub fn disjoint[T : Compare](self : MutableSet[T], src : MutableSet[T]) -> Bool {
  let mut ret = true
  self.iter(fn(x) { if src.contains(x) { ret = false } })
  ret
}

fn black_height[T : Compare](n : Node[T]?) -> Int {
  loop n, 0 {
    None, ct => ct
    Some(node), ct =>
      if node.color == Black {
        continue node.left, ct + 1
      } else {
        continue node.left, ct
      }
  }
}

fn join_right[T : Compare](
  left : Node[T]?,
  value : T,
  right : Node[T]?
) -> Node[T]? {
  let left_color = get_color(left)
  // TODO: optimize this. We have computed the black height of left in `join`.
  if left_color == Black && black_height(left) == black_height(right) {
    let ret = Option::Some(
      new_node_full(Color::Red, left, Some(value), right, None),
    ) // New node allocation
    set_parent(left, ret)
    set_parent(right, ret)
    return ret
  }
  let new_right = join_right(get_right(left), value, right)
  set_right(left, new_right)
  let rr = get_right(new_right)
  if left_color == Black && get_color(new_right) == Red && get_color(rr) == Red {
    set_color(rr, Black)
    rotate_left(None, left)
    return new_right
  }
  set_parent(new_right, left)
  left
}

fn join_left[T : Compare](
  left : Node[T]?,
  value : T,
  right : Node[T]?
) -> Node[T]? {
  let right_color = get_color(right)
  if right_color == Black && black_height(right) == black_height(left) {
    let ret = Option::Some(
      new_node_full(Color::Red, left, Some(value), right, None),
    ) // New node allocation
    set_parent(left, ret)
    set_parent(right, ret)
    return ret
  }
  let new_left = join_left(left, value, get_left(right))
  set_left(right, new_left)
  let ll = get_left(new_left)
  if right_color == Black && get_color(new_left) == Red && get_color(ll) == Red {
    set_color(ll, Black)
    rotate_right(None, right)
    return new_left
  }
  set_parent(new_left, right)
  right
}

// Given two red-black trees (l, r), and a value k. For all values in l < k, and all values in r >= k.
// Returns a new red-black tree containing all values in l and r, and the value k.
fn join[T : Compare](left : Node[T]?, value : T, right : Node[T]?) -> Node[T]? {
  match (left, right) {
    (Some(_), Some(_)) => ()
    (None, None) => return Some(new_node(Black, value, None))
    (Some(_), None) => {
      let a = new_tree(left, 0L)
      a.add(value)
      return a.root
    }
    (None, Some(_)) => {
      let a = new_tree(right, 0L)
      a.add(value)
      return a.root
    }
  }
  let lh = black_height(left)
  let rh = black_height(right)
  if lh > rh {
    let t = join_right(left, value, right)
    if get_color(t) == Red && get_color(get_right(t)) == Red {
      set_color(t, Black)
    }
    t
  } else if rh > lh {
    let t = join_left(left, value, right)
    if get_color(t) == Red && get_color(get_left(t)) == Red {
      set_color(t, Black)
    }
    t
  } else { // same height, create a new node to join them
    let color = if get_color(left) == Black && get_color(right) == Black {
      Color::Red
    } else {
      Color::Black
    }
    let ret = Option::Some(new_node_full(color, left, Some(value), right, None)) // New node allocation
    set_parent(left, ret)
    set_parent(right, ret)
    ret
  }
}

// Returns two red-black trees (l, r).
// All values in l < k. All values in r >= k.
fn split[T : Compare](tree : Node[T]?, k : T) -> (Node[T]?, Node[T]?) {
  match tree {
    None => (None, None)
    Some(_) => {
      if is_nil(tree) {
        return (tree, new_nil()) // New node allocation
      }
      let value = get_value(tree)
      let left = get_left(tree)
      let right = get_right(tree)
      if k == value {
        (left, right)
      } else if k < value {
        let (l, r) = split(left, k)
        (l, join(r, value, right))
      } else {
        let (l, r) = split(right, k)
        (join(left, value, l), r)
      }
    }
  }
}

// # General collection operations

/// Returns if MutableSet is empty.
pub fn is_empty[T : Compare](self : MutableSet[T]) -> Bool {
  match self.root {
    None => true
    _ => false
  }
}

/// Returns the number of elements in the MutableSet.
pub fn size[T : Compare](self : MutableSet[T]) -> Int64 {
  self.size
}

/// An iterator over the MutableSet, iterates over all elements in the set.
pub fn iter[T : Compare](self : MutableSet[T], f : (T) -> Unit) -> Unit {
  fn aux(n : Node[T]?, f : (T) -> Unit) {
    match n {
      Some(node) => {
        if is_nil(n) {
          return
        }
        aux(node.left, f)
        f(get_value(n))
        aux(node.right, f)
      }
      None => ()
    }
  }

  aux(self.root, f)
}

/// Returns a new MutableSet with all elements that satisfy the predicate.
pub fn filter[T : Compare](
  self : MutableSet[T],
  f : (T) -> Bool
) -> MutableSet[T] {
  let ret = MutableSet::new()
  self.iter(fn(x) { if f(x) { ret.add(x) } })
  ret
}

/// Convert MutableSet[T] to Array[T], the result must be ordered.
pub fn to_array[T : Compare](self : MutableSet[T]) -> Array[T] {
  fn aux(set : Node[T]?) -> Array[_] {
    match set {
      None => []
      Some(node) =>
        match node.value {
          Some(value) => aux(node.left) + [value] + aux(node.right)
          None => []
        }
    }
  }

  aux(self.root)
}

/// Convert MutableSet[T] to String, the result must be ordered.
pub fn to_string[T : Compare + Show](self : MutableSet[T]) -> String {
  match self.root {
    None => "MutableSet::[]"
    Some(node) => node.to_string()
  }
}

fn to_array[T](self : Node[T]) -> Array[T] {
  fn aux(n : Node[T]?) -> Array[_] {
    match n {
      None => abort("Impossible to reach")
      _ =>
        if is_nil(n) {
          []
        } else {
          aux(get_left(n)) + [get_value(n)] + aux(get_right(n))
        }
    }
  }

  aux(Some(self))
}

fn to_string[T : Show](self : Node[T]) -> String {
  let linear = self.to_array()
  let len = linear.length()
  if len == 0 {
    return "MutableSet::[]"
  }
  for i = 0, str = "MutableSet::["; i < len - 1; {
    continue i + 1, str + linear[i].to_string() + ", "
  } else {
    str + linear[len - 1].to_string() + "]"
  }
}

// # Convert from
// Convert from other data structures to MutableSet.

/// Initialize an MutableSet[T] from a FixedArray[T]
pub fn MutableSet::of[T : Compare](array : FixedArray[T]) -> MutableSet[T] {
  let set = MutableSet::new()
  for i = 0; i < array.length(); i = i + 1 {
    set.add(array[i])
  }
  set
}

/// Initialize an MutableSet[T] from a Array[T]
pub fn MutableSet::from_array[T : Compare](array : Array[T]) -> MutableSet[T] {
  let set = MutableSet::new()
  array.iter(fn(x) { set.add(x) })
  set
}

// # Getter and setter functions

fn get_left[T](x : Node[T]?) -> Node[T]? {
  match x {
    None => abort("Impossible to reach") // why get left of an empty tree?
    Some({ left, .. }) => left
  }
}

fn set_left[T](x : Node[T]?, left : Node[T]?) -> Unit {
  match x {
    None => abort("Impossible to reach") // why set left of an empty tree?
    Some(tree) => tree.left = left
  }
}

fn get_right[T](x : Node[T]?) -> Node[T]? {
  match x {
    None => abort("Impossible to reach") // why get right of an empty tree?
    Some({ right, .. }) => right
  }
}

fn set_right[T](x : Node[T]?, right : Node[T]?) -> Unit {
  match x {
    None => abort("Impossible to reach") // why set right of an empty tree?
    Some(tree) => tree.right = right
  }
}

fn get_parent[T](x : Node[T]?) -> Node[T]? {
  match x {
    None => abort("Impossible to reach") // why get parent of an empty tree?
    Some(tree) => tree.parent
  }
}

fn set_parent[T](x : Node[T]?, parent : Node[T]?) -> Unit {
  match x {
    None => ()
    Some(tree) => tree.parent = parent
  }
}

fn get_color[T](tree : Node[T]?) -> Color {
  match tree {
    None => abort("Impossible to reach") // why get color of None? 
    Some({ color, .. }) => color
  }
}

fn set_color[T](tree : Node[T]?, color : Color) -> Unit {
  match tree {
    Some(tree) => tree.color = color
    None => abort("Impossible to reach") // why set color of an empty tree?
  }
}

fn get_value[T](node : Node[T]?) -> T {
  match node {
    None => abort("Impossible to reach") // why get value of an empty tree?
    Some({ value, .. }) =>
      match value {
        None => abort("Impossible to reach") // why get value of a leaf?
        Some(value) => value
      }
  }
}

// # Other helper functions

pub fn debug_write[T : Compare + Debug](
  self : MutableSet[T],
  buf : Buffer
) -> Unit {
  let linear = self.to_array()
  let len = linear.length()
  if len == 0 {
    buf.write_string("MutableSet::[]")
    return
  }
  buf.write_string("MutableSet::[")
  for i = 0; i < len - 1; i = i + 1 {
    linear[i].debug_write(buf)
    buf.write_string(", ")
  } else {
    linear[len - 1].debug_write(buf)
    buf.write_string("]")
  }
}

fn is_nil[T](node : Node[T]?) -> Bool {
  match node {
    None => false
    Some(node) =>
      match node.value {
        None => true
        Some(_) => false
      }
  }
}

fn same_pointer[T](x : Node[T]?, y : Node[T]?) -> Bool {
  match (x, y) {
    (None, None) => true
    (Some(x), Some(y)) => physical_equal(x, y)
    (_, _) => false
  }
}

// # Tests

test "add_and_remove" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  set.remove(8)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 9]")?
  let set = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

  // Test 1: Remove elements
  set.remove(1)
  inspect(set, content="MutableSet::[2, 3, 4, 5, 6, 7, 8, 9, 10]")?
  set.remove(5)
  inspect(set, content="MutableSet::[2, 3, 4, 6, 7, 8, 9, 10]")?
  set.remove(10)
  inspect(set, content="MutableSet::[2, 3, 4, 6, 7, 8, 9]")?

  // Test 2: Add elements
  set.add(1)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 6, 7, 8, 9]")?
  set.add(5)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
  set.add(10)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")?

  // Test 3: Add and remove the same element
  set.add(11)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]")?
  set.remove(11)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")?

  // Test 4: Remove an element that doesn't exist
  set.remove(12)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")?

  // Test 5: Add an element that already exists
  set.add(10)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")?

  // Test 6: Remove all elements
  set.remove(1)
  inspect(set, content="MutableSet::[2, 3, 4, 5, 6, 7, 8, 9, 10]")?
  set.remove(2)
  inspect(set, content="MutableSet::[3, 4, 5, 6, 7, 8, 9, 10]")?
  set.remove(3)
  inspect(set, content="MutableSet::[4, 5, 6, 7, 8, 9, 10]")?
  set.remove(4)
  inspect(set, content="MutableSet::[5, 6, 7, 8, 9, 10]")?
  set.remove(5)
  inspect(set, content="MutableSet::[6, 7, 8, 9, 10]")?
  set.remove(6)
  inspect(set, content="MutableSet::[7, 8, 9, 10]")?
  set.remove(7)
  inspect(set, content="MutableSet::[8, 9, 10]")?
  set.remove(8)
  inspect(set, content="MutableSet::[9, 10]")?
  set.remove(9)
  inspect(set, content="MutableSet::[10]")?
  set.remove(10)
  inspect(set, content="MutableSet::[]")?
  set.add(1)
  inspect(set, content="MutableSet::[1]")?
  set.add(2)
  inspect(set, content="MutableSet::[1, 2]")?
  set.add(3)
  inspect(set, content="MutableSet::[1, 2, 3]")?
  set.add(4)
  inspect(set, content="MutableSet::[1, 2, 3, 4]")?
  let set = of([7, 2, 9, 4, 5, 6, 3, 1])
  set.remove(3)
  inspect(set, content="MutableSet::[1, 2, 4, 5, 6, 7, 9]")?
  set.remove(2)
  inspect(set, content="MutableSet::[1, 4, 5, 6, 7, 9]")?
  set.remove(5)
  inspect(set, content="MutableSet::[1, 4, 6, 7, 9]")?
  set.remove(9)
  inspect(set, content="MutableSet::[1, 4, 6, 7]")?
  set.remove(1)
  inspect(set, content="MutableSet::[4, 6, 7]")?
  set.remove(7)
  inspect(set, content="MutableSet::[4, 6]")?
  set.remove(4)
  inspect(set, content="MutableSet::[6]")?
  set.remove(6)
  inspect(set.root, content="None")?
}

test "join" {
  let l = of([13, 8, 17, 1, 11, 15, 25, 6])
  let r = of([27, 28, 40, 35, 33])
  inspect(
    join(l.root, 26, r.root),
    content="Some(MutableSet::[1, 6, 8, 11, 13, 15, 17, 25, 26, 27, 28, 33, 35, 40])",
  )?
  let l = of([3, 2, 5, 1, 4])
  let r = of([7])
  inspect(
    join(l.root, 6, r.root),
    content="Some(MutableSet::[1, 2, 3, 4, 5, 6, 7])",
  )?
  let l = of([3, 2, 5, 1, 4])
  let r = of([])
  inspect(
    join(l.root, 6, r.root),
    content="Some(MutableSet::[1, 2, 3, 4, 5, 6])",
  )?
  let l = of([])
  let r = of([])
  inspect(join(l.root, 6, r.root), content="Some(MutableSet::[6])")?
  let l = of([])
  let r = of([7, 8, 9, 10, 11, 12])
  inspect(
    join(l.root, 6, r.root),
    content="Some(MutableSet::[6, 7, 8, 9, 10, 11, 12])",
  )?
}

test "split" {
  let (l, r) = split(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].root, 5)
  inspect(l, content="Some(MutableSet::[1, 2, 3, 4])")?
  inspect(r, content="Some(MutableSet::[6, 7, 8, 9])")?
  let (l, r) = split(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].root, 0)
  inspect(l, content="Some(MutableSet::[])")?
  inspect(r, content="Some(MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9])")?
  let (l, r) = split(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].root, 10)
  inspect(l, content="Some(MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9])")?
  inspect(r, content="Some(MutableSet::[])")?
  let (l, r) = split(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].root, 4)
  inspect(l, content="Some(MutableSet::[1, 2, 3])")?
  inspect(r, content="Some(MutableSet::[5, 6, 7, 8, 9])")?
  let (l, r) = split(MutableSet::[].root, 7)
  inspect(l, content="None")?
  inspect(r, content="None")?
  let (l, r) = split(
    MutableSet::[
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
      41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
      60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78,
      79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
      98, 99, 100,
    ].root,
    50,
  )
  inspect(
    l,
    content="Some(MutableSet::[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49])",
  )?
  inspect(
    r,
    content="Some(MutableSet::[51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100])",
  )?
}

test "union" {
  // Test 1: Union of two sets with no common elements
  let set1 = of([1, 2, 3])
  let set2 = of([4, 5, 6])
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[1, 2, 3, 4, 5, 6]")?

  // Test 2: Union of two sets with some common elements
  let set1 = of([1, 2, 3])
  let set2 = of([2, 3, 4])
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[1, 2, 3, 4]")?

  // Test 3: Union of two sets where one is a subset of the other
  let set1 = of([1, 2, 3])
  let set2 = of([2, 3])
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[1, 2, 3]")?

  // Test 4: Union of two empty sets
  let set1 : MutableSet[Int] = MutableSet::new()
  let set2 = MutableSet::new()
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[]")?

  // Test 5: Union of an empty set with a non-empty set
  let set1 = of([1, 2, 3])
  let set2 = of([])
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[1, 2, 3]")?
  let set1 = of([])
  let set2 = of([1, 2, 3])
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[1, 2, 3]")?

  // Test 6: Union of two large sets with no common elements
  let set1 = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = of([11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
  let set3 = set1.union(set2)
  inspect(
    set3,
    content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]",
  )?

  // Test 7: Union of two large sets with some common elements
  let set1 = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = of([6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
  let set3 = set1.union(set2)
  inspect(
    set3,
    content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]",
  )?

  // Test 8: Union of two large sets where one is a subset of the other
  let set1 = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = of([6, 7, 8, 9, 10])
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")?
}

test "disjoint" {
  inspect(MutableSet::[1, 2, 3].disjoint(MutableSet::[4, 5, 6]), content="true")?
  inspect(MutableSet::[1, 2, 3].subset(MutableSet::[3, 4, 5]), content="false")?
}

test "subset" {
  inspect(
    MutableSet::[1, 2, 3].subset(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="true",
  )?
  inspect(
    MutableSet::[1, 2, 3].subset(MutableSet::[10, 11, 12, 13, 14]),
    content="false",
  )?
}

test "diff" {
  inspect(
    MutableSet::[1, 2, 3].diff(MutableSet::[4, 5, 1]),
    content="MutableSet::[2, 3]",
  )?
}

test "inter" {
  inspect(
    MutableSet::[3, 4, 5].intersect(MutableSet::[4, 5, 6]),
    content="MutableSet::[4, 5]",
  )?
}

test "filter" {
  inspect(
    MutableSet::[1, 2, 3, 4, 5, 6].filter(fn(v) { v % 2 == 0 }),
    content="MutableSet::[2, 4, 6]",
  )?
}

test "iter" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let result = Buffer::make(10)
  set.iter(fn(x) { result.write_string(x.to_string()) })
  inspect(result.to_string(), content="123456789")?
  let set : MutableSet[Int] = new()
  set.iter(fn(_x) { abort("Impossible to reach") })
}

test "contains" {
  let set = of([7, 2, 9, 4, 6, 3, 8, 1])
  inspect(set.contains(5), content="false")?
  set.add(5)
  inspect(set.contains(5), content="true")?
  inspect(MutableSet::[7, 2, 9, 4, 6, 3, 8, 1].contains(5), content="false")?
  inspect(MutableSet::[].contains(1), content="false")?
}

test "to_array" {
  inspect(
    MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
  inspect((MutableSet::[] : MutableSet[Int]).to_array(), content="[]")?
}

test "to_string" {
  inspect(MutableSet::[1, 2, 3, 4, 5], content="MutableSet::[1, 2, 3, 4, 5]")?
  inspect((MutableSet::[] : MutableSet[Int]), content="MutableSet::[]")?
}

test "from_array" {
  inspect(
    MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
    content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "is_empty" {
  inspect((MutableSet::[] : MutableSet[Int]).is_empty(), content="true")?
  inspect(MutableSet::[1].is_empty(), content="false")?
}

test "size" {
  inspect(MutableSet::[1, 2, 3, 4, 5].size(), content="5")?
  inspect(MutableSet::[1].size(), content="1")?
  inspect((MutableSet::[] : MutableSet[Int]).size(), content="0")?
}

test "singleton" {
  inspect(MutableSet::singleton(1).size(), content="1")?
  inspect(MutableSet::singleton(1).contains(1), content="true")?
  inspect(MutableSet::singleton(1).contains(2), content="false")?
}

test "deep_clone" {
  let set = of([1, 2, 3, 4, 5])
  let clone = set.deep_clone()
  inspect(clone, content="MutableSet::[1, 2, 3, 4, 5]")?
  let set : MutableSet[Int] = of([])
  let clone = set.deep_clone()
  inspect(clone, content="MutableSet::[]")?
}

test "debug_write" {
  let buf = Buffer::make(100)
  let set = of([1, 2, 3, 4, 5])
  set.debug_write(buf)
  inspect(buf.to_string(), content="MutableSet::[1, 2, 3, 4, 5]")?
  let buf = Buffer::make(100)
  let set : MutableSet[Int] = of([])
  set.debug_write(buf)
  inspect(buf.to_string(), content="MutableSet::[]")?
}

test "is_nil" {
  let node : Node[Int]? = Option::None
  inspect(is_nil(node), content="false")?
}

test "same_pointer" {
  let node1 : Node[Int]? = Option::None
  inspect(same_pointer(node1, node1), content="true")?
  let node2 : Node[Int]? = MutableSet::[1].root
  inspect(same_pointer(node1, node2), content="false")?
}

test "min_node" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  inspect(min_node(set.root).unwrap().value, content="Some(1)")?
  let set : MutableSet[Int] = of([])
  inspect(min_node(set.root), content="None")?
}

test "mix_everything" {
  // test all functions together, including add, remove, union, diff, inter, subset, disjoint, size, is_empty, contains
  let set1 = of([1, 2, 3, 4, 5])
  let set2 = of([4, 5, 6, 7, 8])
  set1.add(6)
  inspect(set1, content="MutableSet::[1, 2, 3, 4, 5, 6]")?
  set1.remove(6)
  inspect(set1, content="MutableSet::[1, 2, 3, 4, 5]")?
  let set3 = set1.union(set2)
  inspect(set3, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8]")?
  let set4 = set1.diff(set2)
  inspect(set4, content="MutableSet::[1, 2, 3]")?
  let set5 = set1.intersect(set2)
  inspect(set5, content="MutableSet::[4, 5]")?
  inspect(set1.subset(set3), content="true")?
  set3.remove(3)
  inspect(set3, content="MutableSet::[1, 2, 4, 5, 6, 7, 8]")?
  inspect(set3.size(), content="7")?
  inspect(set3.is_empty(), content="false")?
  inspect(set3.contains(1), content="true")?
  inspect(set3.contains(3), content="false")?
  inspect(set3.disjoint(set1), content="false")?
  let set6 = set3.union(MutableSet::[])
  inspect(set6, content="MutableSet::[1, 2, 4, 5, 6, 7, 8]")?
  let set7 = set3.union(MutableSet::[12, 13, 14, 33, 22])
  inspect(set7, content="MutableSet::[1, 2, 4, 5, 6, 7, 8, 12, 13, 14, 22, 33]")?
  for i = 1; i <= 5; i = i + 1 {
    set7.remove(i)
  }
  inspect(set7, content="MutableSet::[6, 7, 8, 12, 13, 14, 22, 33]")?
  for i = 6; i <= 33; i = i + 1 {
    set7.remove(i)
  }
  let set = MutableSet::[
    90, 70, 13, 44, 11, 49, 39, 35, 52, 8, 80, 40, 58, 67, 84, 38, 93, 97, 54, 95,
  ]
  set.remove(70)
  inspect(
    set,
    content="MutableSet::[8, 11, 13, 35, 38, 39, 40, 44, 49, 52, 54, 58, 67, 80, 84, 90, 93, 95, 97]",
  )?
  set.remove(52)
  inspect(
    set,
    content="MutableSet::[8, 11, 13, 35, 38, 39, 40, 44, 49, 54, 58, 67, 80, 84, 90, 93, 95, 97]",
  )?
}
