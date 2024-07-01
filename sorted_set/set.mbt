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

/// Constructions

/// Construct a empty set.
pub fn new[V]() -> T[V] {
  { root: None, size: 0L }
}

/// Returns the one-value set containing only `value`.
pub fn singleton[V : Compare](value : V) -> T[V] {
  { root: Some({ value, left: None, right: None, height: 1 }), size: 1L }
}

/// Initialize an set from an array.
pub fn of[V : Compare](array : Array[V]) -> T[V] {
  let set = new()
  for i = 0; i < array.length(); i = i + 1 {
    set.add(array[i])
  }
  set
}

/// Returns a deep clone of the MutableSet.
/// 
/// FIXME: it is just copying the tree structure, not the values.
///        It requires a Clone trait on T, which we don't have yet.
pub fn deep_clone[V](self : T[V]) -> T[V] {
  match self.root {
    None => new()
    Some(_) => { root: deep_clone_tree(self.root), size: self.size }
  }
}

fn deep_clone_tree[V](node : Node[V]?) -> Node[V]? {
  match node {
    None => None
    Some(node) => {
      let left = deep_clone_tree(node.left)
      let right = deep_clone_tree(node.right)
      let new_node = new_node(node.value, ~left, ~right, height=node.height)
      Some(new_node)
    }
  }
}

fn new_node[V](
  value : V,
  ~left : Node[V]? = None,
  ~right : Node[V]? = None,
  ~height : Int = 1
) -> Node[V] {
  { value, left, right, height }
}

fn new_node_update_height[V](
  value : V,
  ~left : Node[V]? = None,
  ~right : Node[V]? = None
) -> Node[V] {
  { value, left, right, height: max(height(left), height(right)) + 1 }
}

// Manipulations

pub fn add[V : Compare](self : T[V], value : V) -> Unit {
  let (new_root, inserted) = add_node(self.root, value)
  if self.root != new_root {
    self.root = new_root
  }
  if inserted {
    self.size += 1L
  }
}

pub fn remove[V : Compare](self : T[V], value : V) -> Unit {
  match self.root {
    None => ()
    Some(old_root) => {
      let (new_root, deleted) = delete_node(old_root, value)
      if self.root != new_root {
        self.root = new_root
      }
      if deleted {
        self.size -= 1L
      }
    }
  }
}

// Set operations
// Including union, intersection, difference, subset, disjoint, contains.
// Note that these functions return a new set that doesn't share memory with
// the original set, and the original sets are not modified.

/// Return if a value is contained in the set.
pub fn contains[V : Compare](self : T[V], value : V) -> Bool {
  loop self.root, value {
    None, _ => false
    Some(node), value => {
      let compare_result = value.compare(node.value)
      if compare_result == 0 {
        true
      } else if compare_result < 0 {
        continue node.left, value
      } else {
        continue node.right, value
      }
    }
  }
}

/// Returns the union of two sets.
pub fn union[V : Compare](self : T[V], src : T[V]) -> T[V] {
  fn aux(a : Node[V]?, b : Node[V]?) -> Node[V]? {
    match (a, b) {
      (Some(_), None) => a
      (None, Some(_)) => b
      (Some({ value: va, left: la, right: ra, .. }), Some(_)) => {
        let (l, r) = split(b, va)
        Some(join(aux(la, l), va, aux(ra, r)))
      }
      (None, None) => None
    }
  }

  match (self.root, src.root) {
    (Some(_), Some(_)) => {
      let t1 = deep_clone_tree(self.root)
      let t2 = deep_clone_tree(src.root)
      let t = aux(t1, t2)
      let mut ct = 0L
      let ret = { root: t, size: 0L }
      // TODO: optimize this. Avoid counting the size of the set.
      ret.each(fn(_x) { ct = ct + 1L })
      ret.size = ct
      ret
    }
    (Some(_), None) => { root: deep_clone_tree(self.root), size: self.size }
    (None, Some(_)) => { root: deep_clone_tree(src.root), size: src.size }
    (None, None) => new()
  }
}

fn split[V : Compare](root : Node[V]?, value : V) -> (Node[V]?, Node[V]?) {
  match root {
    None => (None, None)
    Some(node) =>
      if value == node.value {
        (node.left, node.right)
      } else if value < node.value {
        let (l, r) = split(node.left, value)
        (l, Some(join(r, node.value, node.right)))
      } else {
        let (l, r) = split(node.right, value)
        (Some(join(node.left, node.value, l)), r)
      }
  }
}

fn join[V : Compare](left : Node[V]?, value : V, right : Node[V]?) -> Node[V] {
  let (hl, hr) = (height(left), height(right))
  if hl > hr + 1 {
    join_right(left, value, right)
  } else if hr > hl + 1 {
    join_left(left, value, right)
  } else {
    new_node_update_height(value, ~left, ~right)
  }
}

fn join_left[V : Compare](l : Node[V]?, v : V, r : Node[V]?) -> Node[V] {
  let { value: rv, left: rl, right: rr, .. } = r.unwrap()
  let node = if height(rl) <= height(l) + 1 {
    let new_l = new_node_update_height(left=l, v, right=rl)
    if height(Some(new_l)) <= height(rr) + 1 {
      new_node_update_height(left=Some(new_l), rv, right=rr)
    } else {
      let new_l = rotate_l(new_l)
      let new = new_node_update_height(left=Some(new_l), rv, right=rr)
      rotate_r(new)
    }
  } else {
    let new_l = join_left(l, v, rl)
    let new = new_node_update_height(left=Some(new_l), rv, right=rr)
    if height(Some(new_l)) <= height(rr) + 1 {
      new
    } else {
      rotate_r(new)
    }
  }
  node.update_height()
  node
}

fn join_right[V : Compare](l : Node[V]?, v : V, r : Node[V]?) -> Node[V] {
  let { value: lv, left: ll, right: lr, .. } = l.unwrap()
  let node = if height(lr) <= height(r) + 1 {
    let new_r = new_node_update_height(left=lr, v, right=r)
    if height(Some(new_r)) <= height(ll) + 1 {
      new_node_update_height(left=ll, lv, right=Some(new_r))
    } else {
      let new_r = rotate_r(new_r)
      let new = new_node_update_height(left=ll, lv, right=Some(new_r))
      rotate_l(new)
    }
  } else {
    let new_r = join_right(lr, v, r)
    let new = new_node_update_height(left=ll, lv, right=Some(new_r))
    if height(Some(new_r)) <= height(ll) + 1 {
      new
    } else {
      rotate_l(new)
    }
  }
  node.update_height()
  node
}

/// Returns the difference of two sets.
pub fn diff[V : Compare](self : T[V], src : T[V]) -> T[V] {
  let ret = new()
  self.each(fn(x) { if not(src.contains(x)) { ret.add(x) } })
  ret
}

/// Returns the intersection of two sets.
pub fn intersect[V : Compare](self : T[V], src : T[V]) -> T[V] {
  let ret = new()
  self.each(fn(x) { if src.contains(x) { ret.add(x) } })
  ret
}

/// Returns if a set is a subset of another set.
pub fn subset[V : Compare](self : T[V], src : T[V]) -> Bool {
  let mut ret = true
  self.each(fn(x) { if not(src.contains(x)) { ret = false } })
  ret
}

/// Returns if two sets are disjoint.
pub fn disjoint[V : Compare](self : T[V], src : T[V]) -> Bool {
  let mut ret = true
  self.each(fn(x) { if src.contains(x) { ret = false } })
  ret
}

// General collection operations

/// Returns if MutableSet is empty.
pub fn is_empty[V : Compare](self : T[V]) -> Bool {
  match self.root {
    None => true
    _ => false
  }
}

/// Returns the number of elements in the MutableSet.
pub fn size[V : Compare](self : T[V]) -> Int64 {
  self.size
}

/// Iterates the set.
pub fn each[V](self : T[V], f : (V) -> Unit) -> Unit {
  let s = []
  let mut p = self.root
  while p.is_empty().not() || s.is_empty().not() {
    while p.is_empty().not() {
      s.push(p)
      p = p.unwrap().left
    }
    if s.is_empty().not() {
      p = s.pop_exn()
      f(p.unwrap().value)
      p = p.unwrap().right
    }
  }
}

/// Iterates the set with index.
pub fn eachi[V](self : T[V], f : (Int, V) -> Unit) -> Unit {
  let s = []
  let mut p = self.root
  let mut i = 0
  while p.is_empty().not() || s.is_empty().not() {
    while p.is_empty().not() {
      s.push(p)
      p = p.unwrap().left
    }
    if s.is_empty().not() {
      p = s.pop_exn()
      f(i, p.unwrap().value)
      p = p.unwrap().right
      i += 1
    }
  }
}

/// Converts the set to an array.
pub fn to_array[V](self : T[V]) -> Array[V] {
  let arr = []
  self.each(fn(v) { arr.push(v) })
  arr
}

/// Returns a iterator.
pub fn iter[V](self : T[V]) -> Iter[V] {
  Iter::_unstable_internal_make(
    fn(yield) {
      let arr = self.to_array()
      for i = 0, len = arr.length(); i < len; i = i + 1 {
        if yield(arr[i]) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

pub fn debug_write[V : Debug](self : T[V], buf : Buffer) -> Unit {
  let linear = self.to_array()
  let len = linear.length()
  if len == 0 {
    buf.write_string("{}")
    return
  }
  buf.write_string("{")
  for i = 0; i < len - 1; i = i + 1 {
    linear[i].debug_write(buf)
    buf.write_string(", ")
  } else {
    linear[len - 1].debug_write(buf)
    buf.write_string("}")
  }
}

/// Converts the set to string.
pub fn to_string[V : Show](self : T[V]) -> String {
  match self.root {
    None => "{}"
    Some(node) => node.to_string()
  }
}

fn to_string[T : Show](self : Node[T]) -> String {
  let linear = self.to_array()
  let len = linear.length()
  if len == 0 {
    return "{}"
  }
  for i = 0, str = "{"; i < len - 1; {
    continue i + 1, str + linear[i].to_string() + ", "
  } else {
    str + linear[len - 1].to_string() + "}"
  }
}

fn to_array[T](self : Node[T]) -> Array[T] {
  fn aux(n : Node[T]?) -> Array[_] {
    match n {
      None => []
      Some({ value, left, right, .. }) => aux(left) + [value] + aux(right)
    }
  }

  aux(Some(self))
}

// AVL tree operations

fn replace_root_with_min[V : Compare](
  root : Node[V],
  node : Node[V]
) -> Node[V]? {
  let (l, r) = (node.left, node.right)
  match l {
    None => {
      root.value = node.value
      r
    }
    Some(ln) => {
      node.left = replace_root_with_min(root, ln)
      Some(balance(node))
    }
  }
}

fn update_height[V](self : Node[V]) -> Unit {
  self.height = 1 + max(height(self.left), height(self.right))
}

fn height_ge[V](x1 : Node[V]?, x2 : Node[V]?) -> Bool {
  match x2 {
    None => true
    Some(n2) =>
      match x1 {
        None => false
        Some(n1) => n1.height >= n2.height
      }
  }
}

fn balance[V : Compare](root : Node[V]) -> Node[V] {
  let (l, r) = (root.left, root.right)
  let (hl, hr) = (height(l), height(r))
  let new_root = if hl > hr + 1 {
    let { left: ll, right: lr, .. } = l.unwrap()
    if height_ge(ll, lr) {
      rotate_r(root)
    } else {
      rotate_lr(root)
    }
  } else if hr > hl + 1 {
    let { left: rl, right: rr, .. } = r.unwrap()
    if height_ge(rr, rl) {
      rotate_l(root)
    } else {
      rotate_rl(root)
    }
  } else {
    root
  }
  new_root.update_height()
  new_root
}

fn rotate_l[V : Compare](n : Node[V]) -> Node[V] {
  let r = n.right.unwrap()
  n.right = r.left
  r.left = Some(n)
  n.update_height()
  r.update_height()
  r
}

fn rotate_r[V : Compare](n : Node[V]) -> Node[V] {
  let l = n.left.unwrap()
  n.left = l.right
  l.right = Some(n)
  n.update_height()
  l.update_height()
  l
}

fn rotate_lr[V : Compare](n : Node[V]) -> Node[V] {
  let l = n.left.unwrap()
  let v = rotate_l(l)
  n.left = Some(v)
  rotate_r(n)
}

fn rotate_rl[V : Compare](n : Node[V]) -> Node[V] {
  let r = n.right.unwrap()
  let v = rotate_r(r)
  n.right = Some(v)
  rotate_l(n)
}

fn add_node[V : Compare](root : Node[V]?, value : V) -> (Node[V]?, Bool) {
  match root {
    None => (Some(new_node(value)), true)
    Some(n) =>
      if value == n.value {
        n.value = value
        (Some(n), false)
      } else {
        let (l, r) = (n.left, n.right)
        if value < n.value {
          let (nl, inserted) = add_node(l, value)
          n.left = nl
          (Some(balance(n)), inserted)
        } else {
          let (nr, inserted) = add_node(r, value)
          n.right = nr
          (Some(balance(n)), inserted)
        }
      }
  }
}

fn delete_node[V : Compare](root : Node[V], value : V) -> (Node[V]?, Bool) {
  if value == root.value {
    let (l, r) = (root.left, root.right)
    let n = match (l, r) {
      (Some(_), Some(nr)) => {
        root.right = replace_root_with_min(root, nr)
        Some(balance(root))
      }
      (None, Some(_)) => r
      (Some(_), None) | (None, None) => l
    }
    (n, true)
  } else if value < root.value {
    match root.left {
      None => (Some(root), false)
      Some(l) => {
        let (nl, deleted) = delete_node(l, value)
        root.left = nl
        (Some(balance(root)), deleted)
      }
    }
  } else {
    match root.right {
      None => (Some(root), false)
      Some(r) => {
        let (nr, deleted) = delete_node(r, value)
        root.right = nr
        (Some(balance(root)), deleted)
      }
    }
  }
}
