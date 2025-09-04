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

/// Constructions

///|
/// Construct a empty set.
#as_free_fn
pub fn[V] SortedSet::new() -> SortedSet[V] {
  { root: None, size: 0 }
}

///|
/// Returns the one-value set containing only `value`.
#as_free_fn
pub fn[V] SortedSet::singleton(value : V) -> SortedSet[V] {
  { root: Some({ value, left: None, right: None, height: 1 }), size: 1 }
}

///|
/// Initialize an set from an array.
#as_free_fn
pub fn[V : Compare] SortedSet::from_array(array : Array[V]) -> SortedSet[V] {
  let set = new()
  for i in 0..<array.length() {
    set.add(array[i])
  }
  set
}

///|
#as_free_fn
pub fn[V : Compare] SortedSet::of(array : FixedArray[V]) -> SortedSet[V] {
  let set = new()
  for i in 0..<array.length() {
    set.add(array[i])
  }
  set
}

///|
/// Returns a shallow copy of the set.
/// 
/// It is just copying the tree structure, not the values.
/// 
pub fn[V] copy(self : SortedSet[V]) -> SortedSet[V] {
  match self.root {
    None => new()
    Some(_) => { root: copy_tree(self.root), size: self.size }
  }
}

///|
fn[V] copy_tree(node : Node[V]?) -> Node[V]? {
  match node {
    None => None
    Some(node) => {
      let left = copy_tree(node.left)
      let right = copy_tree(node.right)
      let new_node = new_node(node.value, left~, right~, height=node.height)
      Some(new_node)
    }
  }
}

///|
fn[V] new_node(
  value : V,
  left? : Node[V]? = None,
  right? : Node[V]? = None,
  height? : Int = 1,
) -> Node[V] {
  { value, left, right, height }
}

///|
fn[V] new_node_update_height(
  value : V,
  left~ : Node[V]?,
  right~ : Node[V]?,
) -> Node[V] {
  { value, left, right, height: max(height(left), height(right)) + 1 }
}

// Manipulations

///|
pub fn[V : Compare] add(self : SortedSet[V], value : V) -> Unit {
  let (new_root, inserted) = add_node(self.root, value)
  if self.root != new_root {
    self.root = new_root
  }
  if inserted {
    self.size += 1
  }
}

///|
pub fn[V : Compare] remove(self : SortedSet[V], value : V) -> Unit {
  if self.root is Some(old_root) {
    let (new_root, deleted) = delete_node(old_root, value)
    if self.root != new_root {
      self.root = new_root
    }
    if deleted {
      self.size -= 1
    }
  }
}

// Set operations
// Including union, intersection, difference, subset, disjoint, contains.
// Note that these functions return a new set that doesn't share memory with
// the original set, and the original sets are not modified.

///|
/// Return if a value is contained in the set.
pub fn[V : Compare] contains(self : SortedSet[V], value : V) -> Bool {
  loop (self.root, value) {
    (None, _) => false
    (Some(node), value) => {
      let compare_result = value.compare(node.value)
      if compare_result == 0 {
        true
      } else if compare_result < 0 {
        continue (node.left, value)
      } else {
        continue (node.right, value)
      }
    }
  }
}

///|
/// Returns the union of two sets.
pub fn[V : Compare] union(
  self : SortedSet[V],
  src : SortedSet[V],
) -> SortedSet[V] {
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
      let t1 = copy_tree(self.root)
      let t2 = copy_tree(src.root)
      let t = aux(t1, t2)
      let mut ct = 0
      let ret = { root: t, size: 0 }
      // TODO: optimize this. Avoid counting the size of the set.
      ret.each(_x => ct = ct + 1)
      ret.size = ct
      ret
    }
    (Some(_), None) => { root: copy_tree(self.root), size: self.size }
    (None, Some(_)) => { root: copy_tree(src.root), size: src.size }
    (None, None) => new()
  }
}

///|
fn[V : Compare] split(root : Node[V]?, value : V) -> (Node[V]?, Node[V]?) {
  match root {
    None => (None, None)
    Some(node) => {
      let comp = value.compare(node.value)
      if comp == 0 {
        (node.left, node.right)
      } else if comp < 0 {
        let (l, r) = split(node.left, value)
        (l, Some(join(r, node.value, node.right)))
      } else {
        let (l, r) = split(node.right, value)
        (Some(join(node.left, node.value, l)), r)
      }
    }
  }
}

///|
fn[V : Compare] join(left : Node[V]?, value : V, right : Node[V]?) -> Node[V] {
  let (hl, hr) = (height(left), height(right))
  if hl > hr + 1 {
    join_right(left, value, right)
  } else if hr > hl + 1 {
    join_left(left, value, right)
  } else {
    new_node_update_height(value, left~, right~)
  }
}

///|
fn[V : Compare] join_left(l : Node[V]?, v : V, r : Node[V]?) -> Node[V] {
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

///|
fn[V : Compare] join_right(l : Node[V]?, v : V, r : Node[V]?) -> Node[V] {
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

///|
/// Returns the difference of two sets.
pub fn[V : Compare] difference(
  self : SortedSet[V],
  src : SortedSet[V],
) -> SortedSet[V] {
  let ret = new()
  self.each(x => if !src.contains(x) { ret.add(x) })
  ret
}

///|
/// Returns a new set containing elements that are in either of the two sets, but
/// not in their intersection. In other words, returns a new set containing
/// elements that are in exactly one of the two sets.
///
/// Parameters:
///
/// * `self` : The first set.
/// * `other` : The second set.
///
/// Returns a new set containing elements that appear in exactly one of the input
/// sets.
///
/// Example:
///
/// ```moonbit
///   let set1 = @sorted_set.from_array([1, 2, 3, 4])
///   let set2 = @sorted_set.from_array([3, 4, 5, 6])
///   let diff = set1.symmetric_difference(set2)
///   inspect(diff, content="@sorted_set.from_array([1, 2, 5, 6])")
/// ```
pub fn[V : Compare] symmetric_difference(
  self : SortedSet[V],
  other : SortedSet[V],
) -> SortedSet[V] {
  // TODO: Optimize this function to avoid creating two intermediate sets.
  let set1 = self.difference(other)
  let set2 = other.difference(self)
  set1.union(set2)
}

///|
/// Returns the intersection of two sets.
pub fn[V : Compare] intersection(
  self : SortedSet[V],
  src : SortedSet[V],
) -> SortedSet[V] {
  let ret = new()
  self.each(x => if src.contains(x) { ret.add(x) })
  ret
}

///|
/// Returns if a set is a subset of another set.
pub fn[V : Compare] subset(self : SortedSet[V], src : SortedSet[V]) -> Bool {
  let mut ret = true
  self.each(x => if !src.contains(x) { ret = false })
  ret
}

///|
/// Returns if two sets are disjoint.
pub fn[V : Compare] disjoint(self : SortedSet[V], src : SortedSet[V]) -> Bool {
  let mut ret = true
  self.each(x => if src.contains(x) { ret = false })
  ret
}

// General collection operations

///|
pub impl[V : Eq] Eq for SortedSet[V] with equal(self, other) {
  self.to_array() == other.to_array()
}

///|
/// Returns if the set is empty.
pub fn[V] is_empty(self : SortedSet[V]) -> Bool {
  self.root is None
}

///|
/// Returns the number of elements in the set.
pub fn[V] size(self : SortedSet[V]) -> Int {
  self.size
}

///|
/// Iterates the set.
pub fn[V] each(self : SortedSet[V], f : (V) -> Unit raise?) -> Unit raise? {
  fn dfs(root : Node[V]?) -> Unit raise? {
    if root is Some(root) {
      dfs(root.left)
      f(root.value)
      dfs(root.right)
    }
  }

  dfs(self.root)
}

///|
/// Iterates the set with index.
pub fn[V] eachi(
  self : SortedSet[V],
  f : (Int, V) -> Unit raise?,
) -> Unit raise? {
  let mut i = 0
  self.each(v => {
    f(i, v)
    i = i + 1
  })
}

///|
/// Converts the set to an array.
pub fn[V] to_array(self : SortedSet[V]) -> Array[V] {
  if self.size == 0 {
    []
  } else {
    let padding = self.root.unwrap().value
    let arr = Array::make(self.size, padding)
    let mut i = 0
    fn dfs(root : Node[V]?) -> Unit {
      if root is Some(root) {
        dfs(root.left)
        arr[i] = root.value
        i = i + 1
        dfs(root.right)
      }
    }

    dfs(self.root)
    arr
  }
}

///|
/// Returns a iterator.
pub fn[V] iter(self : SortedSet[V]) -> Iter[V] {
  Iter::new(yield_ => {
    fn go(x : Node[V]?) {
      match x {
        None => IterContinue
        Some({ left, right, value, .. }) =>
          if go(left) is IterEnd {
            IterEnd
          } else if yield_(value) is IterEnd {
            IterEnd
          } else {
            go(right)
          }
      }
    }

    go(self.root)
  })
}

///|
#as_free_fn
pub fn[V : Compare] SortedSet::from_iter(iter : Iter[V]) -> SortedSet[V] {
  let s = new()
  iter.each(e => s.add(e))
  s
}

///|
/// Converts the set to string.
pub impl[V : Show] Show for SortedSet[V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@sorted_set.from_array([", suffix="])")
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for SortedSet[
  X,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|
impl[T : Show] Show for Node[T] with output(self, logger) {
  let x = { root: Some(self), size: 0 } // Hack for test
  logger.write_iter(x.iter())
}

///|
pub fn[V : Compare] range(self : SortedSet[V], low : V, high : V) -> Iter[V] {
  Iter::new(yield_ => {
    fn go(x : Node[V]?) {
      match x {
        None => IterContinue
        Some({ left, right, value, .. }) => {
          let cmp_key_low = value.compare(low)
          let cmp_key_high = value.compare(high)
          if cmp_key_low > 0 && go(left) is IterEnd {
            IterEnd
          } else if cmp_key_low >= 0 &&
            cmp_key_high <= 0 &&
            yield_(value) is IterEnd {
            IterEnd
          } else if cmp_key_high < 0 {
            go(right)
          } else {
            IterContinue
          }
        }
      }
    }

    go(self.root)
  })
}

// AVL tree operations

///|
fn[V : Compare] replace_root_with_min(
  root : Node[V],
  node : Node[V],
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

///|
fn[V] update_height(self : Node[V]) -> Unit {
  self.height = 1 + max(height(self.left), height(self.right))
}

///|
fn[V] height_ge(x1 : Node[V]?, x2 : Node[V]?) -> Bool {
  match x2 {
    None => true
    Some(n2) =>
      match x1 {
        None => false
        Some(n1) => n1.height >= n2.height
      }
  }
}

///|
fn[V] balance(root : Node[V]) -> Node[V] {
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

///|
fn[V] rotate_l(n : Node[V]) -> Node[V] {
  let r = n.right.unwrap()
  n.right = r.left
  r.left = Some(n)
  n.update_height()
  r.update_height()
  r
}

///|
fn[V] rotate_r(n : Node[V]) -> Node[V] {
  let l = n.left.unwrap()
  n.left = l.right
  l.right = Some(n)
  n.update_height()
  l.update_height()
  l
}

///|
fn[V] rotate_lr(n : Node[V]) -> Node[V] {
  let l = n.left.unwrap()
  let v = rotate_l(l)
  n.left = Some(v)
  rotate_r(n)
}

///|
fn[V] rotate_rl(n : Node[V]) -> Node[V] {
  let r = n.right.unwrap()
  let v = rotate_r(r)
  n.right = Some(v)
  rotate_l(n)
}

///|
fn[V : Compare] add_node(root : Node[V]?, value : V) -> (Node[V]?, Bool) {
  match root {
    None => (Some(new_node(value)), true)
    Some(n) => {
      let comp = value.compare(n.value)
      if comp == 0 {
        n.value = value
        (Some(n), false)
      } else {
        let (l, r) = (n.left, n.right)
        if comp < 0 {
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
}

///|
fn[V : Compare] delete_node(root : Node[V], value : V) -> (Node[V]?, Bool) {
  let comp = value.compare(root.value)
  if comp == 0 {
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
  } else if comp < 0 {
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

///|
test "copy" {
  let set = from_array([1, 2, 3, 4, 5])
  let copied_set = set.copy()
  inspect(copied_set, content="@sorted_set.from_array([1, 2, 3, 4, 5])")
  inspect(set.debug_tree() == copied_set.debug_tree(), content="true")
  let set : SortedSet[Int] = from_array([])
  let copied_set = set.copy()
  inspect(copied_set, content="@sorted_set.from_array([])")
  inspect(set.debug_tree() == copied_set.debug_tree(), content="true")
}

///|
test "union" {
  // Test 1: Union of two sets with no common elements
  let set1 = from_array([1, 2, 3])
  let set2 = from_array([4, 5, 6])
  let set3 = set1.union(set2)
  inspect(set3, content="@sorted_set.from_array([1, 2, 3, 4, 5, 6])")
  inspect(
    set3.debug_tree(),
    content="([3]3,([2]2,([1]1,_,_),_),([2]5,([1]4,_,_),([1]6,_,_)))",
  )

  // Test 2: Union of two sets with some common elements
  let set1 = from_array([1, 2, 3])
  let set2 = from_array([2, 3, 4])
  let set3 = set1.union(set2)
  inspect(set3, content="@sorted_set.from_array([1, 2, 3, 4])")
  inspect(set3.debug_tree(), content="([3]2,([1]1,_,_),([2]3,_,([1]4,_,_)))")

  // Test 3: Union of two sets where one is a subset of the other
  let set1 = from_array([1, 2, 3])
  let set2 = from_array([2, 3])
  let set3 = set1.union(set2)
  inspect(set3, content="@sorted_set.from_array([1, 2, 3])")
  inspect(set3.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")

  // Test 4: Union of two empty sets
  let set1 : SortedSet[Int] = new()
  let set2 = new()
  let set3 = set1.union(set2)
  inspect(set3, content="@sorted_set.from_array([])")
  inspect(set3.debug_tree(), content="_")

  // Test 5: Union of an empty set with a non-empty set
  let set1 = from_array([1, 2, 3])
  let set2 = from_array([])
  let set3 = set1.union(set2)
  inspect(set3, content="@sorted_set.from_array([1, 2, 3])")
  inspect(set3.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")
  let set1 = from_array([])
  let set2 = from_array([1, 2, 3])
  let set3 = set1.union(set2)
  inspect(set3, content="@sorted_set.from_array([1, 2, 3])")
  inspect(set3.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")

  // Test 6: Union of two large sets with no common elements
  let set1 = from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = from_array([11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
  let set3 = set1.union(set2)
  inspect(
    set3,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])",
  )
  inspect(
    set3.debug_tree(),
    content="([5]14,([4]8,([3]4,([2]2,([1]1,_,_),([1]3,_,_)),([2]6,([1]5,_,_),([1]7,_,_))),([3]12,([2]10,([1]9,_,_),([1]11,_,_)),([1]13,_,_))),([3]18,([2]16,([1]15,_,_),([1]17,_,_)),([2]19,_,([1]20,_,_))))",
  )

  // Test 7: Union of two large sets with some common elements
  let set1 = from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = from_array([6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
  let set3 = set1.union(set2)
  inspect(
    set3,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])",
  )
  inspect(
    set3.debug_tree(),
    content="([5]11,([4]4,([2]2,([1]1,_,_),([1]3,_,_)),([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]9,_,([1]10,_,_)))),([3]13,([1]12,_,_),([2]14,_,([1]15,_,_))))",
  )

  // Test 8: Union of two large sets where one is a subset of the other
  let set1 = from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = from_array([6, 7, 8, 9, 10])
  let set3 = set1.union(set2)
  inspect(
    set3,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])",
  )
  inspect(
    set3.debug_tree(),
    content="([4]4,([2]2,([1]1,_,_),([1]3,_,_)),([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]9,_,([1]10,_,_))))",
  )
}

///|
test "split" {
  let (l, r) = split(from_array([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 5)
  inspect(l, content="Some([1, 2, 3, 4])")
  inspect(r, content="Some([6, 7, 8, 9])")
  let (l, r) = split(from_array([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 0)
  inspect(l, content="None")
  inspect(r, content="Some([1, 2, 3, 4, 5, 6, 7, 8, 9])")
  let (l, r) = split(from_array([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 10)
  inspect(l, content="Some([1, 2, 3, 4, 5, 6, 7, 8, 9])")
  inspect(r, content="None")
  let (l, r) = split(from_array([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 4)
  inspect(l, content="Some([1, 2, 3])")
  inspect(r, content="Some([5, 6, 7, 8, 9])")
  let (l, r) = split(from_array([]).root, 7)
  inspect(l, content="None")
  inspect(r, content="None")
  let (l, r) = split(
    from_array([
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
      41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
      60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78,
      79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
      98, 99, 100,
    ]).root,
    50,
  )
  inspect(
    l,
    content="Some([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49])",
  )
  inspect(
    r,
    content="Some([51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100])",
  )
}

///|
test "join" {
  let l = from_array([13, 8, 17, 1, 11, 15, 25, 6])
  let r = from_array([27, 28, 40, 35, 33])
  inspect(
    join(l.root, 26, r.root),
    content="[1, 6, 8, 11, 13, 15, 17, 25, 26, 27, 28, 33, 35, 40]",
  )
  let l = from_array([3, 2, 5, 1, 4])
  let r = from_array([7])
  inspect(join(l.root, 6, r.root), content="[1, 2, 3, 4, 5, 6, 7]")
  let l = from_array([3, 2, 5, 1, 4])
  let r = from_array([])
  inspect(join(l.root, 6, r.root), content="[1, 2, 3, 4, 5, 6]")
  let l = from_array([])
  let r = from_array([])
  inspect(join(l.root, 6, r.root), content="[6]")
  let l = from_array([])
  let r = from_array([7, 8, 9, 10, 11, 12])
  inspect(join(l.root, 6, r.root), content="[6, 7, 8, 9, 10, 11, 12]")
}

///|
test "add to empty set" {
  let set = new()
  set.add(1)
  assert_eq(set.contains(1), true)
  inspect(set.debug_tree(), content="([1]1,_,_)")
}

///|
test "add to non-empty set" {
  let set = new()
  set.add(1)
  set.add(2)
  assert_eq(set.contains(1), true)
  assert_eq(set.contains(2), true)
  inspect(set.debug_tree(), content="([2]1,_,([1]2,_,_))")
}

///|
test "add duplicate value" {
  let set = new()
  set.add(1)
  set.add(1)
  assert_eq(set.contains(1), true)
  assert_eq(set.size(), 1)
  inspect(set.debug_tree(), content="([1]1,_,_)")
}

///|
test "add multiple values" {
  let set = new()
  set.add(1)
  set.add(2)
  set.add(3)
  assert_eq(set.contains(1), true)
  assert_eq(set.contains(2), true)
  assert_eq(set.contains(3), true)
  assert_eq(set.size(), 3)
  inspect(set.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")
}

///|
test "add_and_remove" {
  let set = from_array([7, 2, 9, 4, 5, 6, 3, 8, 1])
  set.remove(8)
  inspect(set, content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 9])")
  inspect(
    set.debug_tree(),
    content="([4]5,([3]3,([2]2,([1]1,_,_),_),([1]4,_,_)),([2]7,([1]6,_,_),([1]9,_,_)))",
  )
  let set = from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

  // Test 1: Remove elements
  set.remove(1)
  inspect(set, content="@sorted_set.from_array([2, 3, 4, 5, 6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([4]4,([2]2,_,([1]3,_,_)),([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]9,_,([1]10,_,_))))",
  )
  set.remove(5)
  inspect(set, content="@sorted_set.from_array([2, 3, 4, 6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([4]4,([2]2,_,([1]3,_,_)),([3]8,([2]6,_,([1]7,_,_)),([2]9,_,([1]10,_,_))))",
  )
  set.remove(10)
  inspect(set, content="@sorted_set.from_array([2, 3, 4, 6, 7, 8, 9])")
  inspect(
    set.debug_tree(),
    content="([4]4,([2]2,_,([1]3,_,_)),([3]8,([2]6,_,([1]7,_,_)),([1]9,_,_)))",
  )
  set.remove(4)
  inspect(set, content="@sorted_set.from_array([2, 3, 6, 7, 8, 9])")
  inspect(
    set.debug_tree(),
    content="([3]6,([2]2,_,([1]3,_,_)),([2]8,([1]7,_,_),([1]9,_,_)))",
  )

  // Test 2: Add elements
  set.add(1)
  inspect(set, content="@sorted_set.from_array([1, 2, 3, 6, 7, 8, 9])")
  inspect(
    set.debug_tree(),
    content="([3]6,([2]2,([1]1,_,_),([1]3,_,_)),([2]8,([1]7,_,_),([1]9,_,_)))",
  )
  set.add(5)
  inspect(set, content="@sorted_set.from_array([1, 2, 3, 5, 6, 7, 8, 9])")
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]3,_,([1]5,_,_))),([2]8,([1]7,_,_),([1]9,_,_)))",
  )
  set.add(10)
  inspect(set, content="@sorted_set.from_array([1, 2, 3, 5, 6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]3,_,([1]5,_,_))),([3]8,([1]7,_,_),([2]9,_,([1]10,_,_))))",
  )
  set.add(4)
  inspect(
    set,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])",
  )
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]4,([1]3,_,_),([1]5,_,_))),([3]8,([1]7,_,_),([2]9,_,([1]10,_,_))))",
  )

  // Test 3: Add and remove the same element
  set.add(11)
  inspect(
    set,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])",
  )
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]4,([1]3,_,_),([1]5,_,_))),([3]8,([1]7,_,_),([2]10,([1]9,_,_),([1]11,_,_))))",
  )
  set.remove(11)
  inspect(
    set,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])",
  )
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]4,([1]3,_,_),([1]5,_,_))),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )

  // Test 4: Remove an element that doesn't exist
  set.remove(12)
  inspect(
    set,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])",
  )

  // Test 5: Add an element that already exists
  set.add(10)
  inspect(
    set,
    content="@sorted_set.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])",
  )

  // Test 6: Remove all elements
  set.remove(1)
  inspect(set, content="@sorted_set.from_array([2, 3, 4, 5, 6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([4]6,([3]4,([2]2,_,([1]3,_,_)),([1]5,_,_)),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )
  set.remove(2)
  inspect(set, content="@sorted_set.from_array([3, 4, 5, 6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([4]6,([2]4,([1]3,_,_),([1]5,_,_)),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )
  set.remove(3)
  inspect(set, content="@sorted_set.from_array([4, 5, 6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([4]6,([2]4,_,([1]5,_,_)),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )
  set.remove(4)
  inspect(set, content="@sorted_set.from_array([5, 6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]10,([1]9,_,_),_))",
  )
  set.remove(5)
  inspect(set, content="@sorted_set.from_array([6, 7, 8, 9, 10])")
  inspect(
    set.debug_tree(),
    content="([3]8,([2]6,_,([1]7,_,_)),([2]10,([1]9,_,_),_))",
  )
  set.remove(6)
  inspect(set, content="@sorted_set.from_array([7, 8, 9, 10])")
  inspect(set.debug_tree(), content="([3]8,([1]7,_,_),([2]10,([1]9,_,_),_))")
  set.remove(7)
  inspect(set, content="@sorted_set.from_array([8, 9, 10])")
  inspect(set.debug_tree(), content="([2]9,([1]8,_,_),([1]10,_,_))")
  set.remove(8)
  inspect(set, content="@sorted_set.from_array([9, 10])")
  inspect(set.debug_tree(), content="([2]9,_,([1]10,_,_))")
  set.remove(9)
  inspect(set, content="@sorted_set.from_array([10])")
  inspect(set.debug_tree(), content="([1]10,_,_)")
  set.remove(10)
  inspect(set, content="@sorted_set.from_array([])")
  inspect(set.debug_tree(), content="_")
  let set = from_array([7, 2, 9, 4, 5, 6, 3, 1])
  set.remove(3)
  inspect(set, content="@sorted_set.from_array([1, 2, 4, 5, 6, 7, 9])")
  inspect(
    set.debug_tree(),
    content="([3]5,([2]2,([1]1,_,_),([1]4,_,_)),([2]7,([1]6,_,_),([1]9,_,_)))",
  )
  set.remove(2)
  inspect(set, content="@sorted_set.from_array([1, 4, 5, 6, 7, 9])")
  inspect(
    set.debug_tree(),
    content="([3]5,([2]4,([1]1,_,_),_),([2]7,([1]6,_,_),([1]9,_,_)))",
  )
  set.remove(5)
  inspect(set, content="@sorted_set.from_array([1, 4, 6, 7, 9])")
  inspect(
    set.debug_tree(),
    content="([3]6,([2]4,([1]1,_,_),_),([2]7,_,([1]9,_,_)))",
  )
  set.remove(9)
  inspect(set, content="@sorted_set.from_array([1, 4, 6, 7])")
  inspect(set.debug_tree(), content="([3]6,([2]4,([1]1,_,_),_),([1]7,_,_))")
  set.remove(1)
  inspect(set, content="@sorted_set.from_array([4, 6, 7])")
  inspect(set.debug_tree(), content="([2]6,([1]4,_,_),([1]7,_,_))")
  set.remove(7)
  inspect(set, content="@sorted_set.from_array([4, 6])")
  inspect(set.debug_tree(), content="([2]6,([1]4,_,_),_)")
  set.remove(4)
  inspect(set, content="@sorted_set.from_array([6])")
  inspect(set.debug_tree(), content="([1]6,_,_)")
  set.remove(6)
  inspect(set, content="@sorted_set.from_array([])")
  inspect(set.debug_tree(), content="_")
}

///|
pub impl[K] Default for SortedSet[K] with default() {
  new()
}
