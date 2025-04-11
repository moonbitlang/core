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

///|
pub fn op_set[K : Compare, V](self : T[K, V], key : K, value : V) -> Unit {
  self.add(key, value)
}

///|
pub fn op_get[K : Compare, V](self : T[K, V], key : K) -> V? {
  self.get(key)
}

///|
pub impl[K : Eq, V : Eq] Eq for T[K, V] with op_equal(self, other) {
  self.to_array() == other.to_array()
}

///|
/// Returns a new sorted map.
pub fn new[K, V]() -> T[K, V] {
  { root: None, size: 0 }
}

///|
#deprecated("Use @sorted_map.from_array instead")
pub fn of[K : Compare, V](entries : Array[(K, V)]) -> T[K, V] {
  let map = { root: None, size: 0 }
  entries.each(fn(e) { map.add(e.0, e.1) })
  map
}

///| Creates a sorted map from a array of key-value pairs.
pub fn from_array[K : Compare, V](entries : Array[(K, V)]) -> T[K, V] {
  let map = { root: None, size: 0 }
  entries.each(fn(e) { map.add(e.0, e.1) })
  map
}

///|
/// Inserts a key-value pair.
pub fn add[K : Compare, V](self : T[K, V], key : K, value : V) -> Unit {
  let (new_root, inserted) = add_node(self.root, key, value)
  if self.root != new_root {
    self.root = new_root
  }
  if inserted {
    self.size += 1
  }
}

///|
/// Removes a key-value pair.
pub fn remove[K : Compare, V](self : T[K, V], key : K) -> Unit {
  if self.root is Some(old_root) {
    let (new_root, deleted) = delete_node(old_root, key)
    if self.root != new_root {
      self.root = new_root
    }
    if deleted {
      self.size -= 1
    }
  }
}

///|
/// Gets a value by a key.
pub fn get[K : Compare, V](self : T[K, V], key : K) -> V? {
  loop self.root {
    Some(node) => {
      let cmp = key.compare(node.key)
      if cmp == 0 {
        break Some(node.value)
      } else if cmp > 0 {
        continue node.right
      } else {
        continue node.left
      }
    }
    None => break None
  }
}

///|
/// Checks if map contains a key-value pair.
pub fn contains[K : Compare, V](self : T[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

///|
/// Returns true if map is empty.
pub fn is_empty[K, V](self : T[K, V]) -> Bool {
  self.size == 0
}

///|
/// Returns the count of key-value pairs in the map.
pub fn size[K, V](self : T[K, V]) -> Int {
  self.size
}

///|
/// Clears the map.
pub fn clear[K, V](self : T[K, V]) -> Unit {
  self.root = None
  self.size = 0
}

///|
/// Iterates the map.
pub fn each[K, V](self : T[K, V], f : (K, V) -> Unit) -> Unit {
  let s = []
  let mut p = self.root
  while not(p.is_empty()) || not(s.is_empty()) {
    while not(p.is_empty()) {
      s.push(p)
      p = p.unwrap().left
    }
    if not(s.is_empty()) {
      p = s.unsafe_pop()
      f(p.unwrap().key, p.unwrap().value)
      p = p.unwrap().right
    }
  }
}

///|
/// Iterates the map with index.
pub fn eachi[K, V](self : T[K, V], f : (Int, K, V) -> Unit) -> Unit {
  let s = []
  let mut p = self.root
  let mut i = 0
  while not(p.is_empty()) || not(s.is_empty()) {
    while not(p.is_empty()) {
      s.push(p)
      p = p.unwrap().left
    }
    if not(s.is_empty()) {
      p = s.unsafe_pop()
      f(i, p.unwrap().key, p.unwrap().value)
      p = p.unwrap().right
      i += 1
    }
  }
}

///|
/// Returns all keys in the map.
pub fn keys[K, V](self : T[K, V]) -> Array[K] {
  let keys = []
  self.each(fn(k, _v) { keys.push(k) })
  keys
}

///|
/// Returns all values in the map.
pub fn values[K, V](self : T[K, V]) -> Array[V] {
  let values = []
  self.each(fn(_k, v) { values.push(v) })
  values
}

///|
/// Converts the map to an array.
pub fn to_array[K, V](self : T[K, V]) -> Array[(K, V)] {
  let arr = []
  self.each(fn(k, v) { arr.push((k, v)) })
  arr
}

///|
pub fn iter[K, V](self : T[K, V]) -> Iter[(K, V)] {
  iter_aux(self.root)
}

///|
fn iter_aux[K, V](node : Node[K, V]?) -> Iter[(K, V)] {
  Iter::new(fn(yield_) {
    match node {
      None => IterContinue
      Some(node) =>
        if iter_aux(node.left).run(yield_) == IterEnd {
          return IterEnd
        } else if yield_((node.key, node.value)) == IterEnd {
          return IterEnd
        } else if iter_aux(node.right).run(yield_) == IterEnd {
          return IterEnd
        } else {
          IterContinue
        }
    }
  })
}

///|
pub fn iter2[K, V](self : T[K, V]) -> Iter2[K, V] {
  iter_aux2(self.root)
}

///|
fn iter_aux2[K, V](node : Node[K, V]?) -> Iter2[K, V] {
  Iter2::new(fn(yield_) {
    match node {
      None => IterContinue
      Some(node) =>
        if iter_aux2(node.left).run(yield_) == IterEnd {
          return IterEnd
        } else if yield_(node.key, node.value) == IterEnd {
          return IterEnd
        } else if iter_aux2(node.right).run(yield_) == IterEnd {
          return IterEnd
        } else {
          IterContinue
        }
    }
  })
}

///|
pub fn from_iter[K : Compare, V](iter : Iter[(K, V)]) -> T[K, V] {
  let m = new()
  iter.each(fn(e) { m[e.0] = e.1 })
  m
}

///|
pub impl[K : @quickcheck.Arbitrary + Compare, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[
  K,
  V,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|Returns a new array of key-value pairs that are within the specified range [low, high).
pub fn range[K : Compare, V](self : T[K, V], low : K, high : K) -> Iter2[K, V] {
  range_aux(self.root, low, high)
}

///|Returns a new array of key-value pairs that are within the specified range [low, high].
fn range_aux[K : Compare, V](
  node : Node[K, V]?,
  low : K,
  high : K
) -> Iter2[K, V] {
  Iter2::new(fn(yield_) {
    match node {
      None => IterContinue
      Some(node) => {
        let cmp_key_low = node.key.compare(low)
        let cmp_key_high = node.key.compare(high)
        if cmp_key_low > 0 {
          // we should go left
          guard range_aux(node.left, low, high).run(yield_) is IterContinue else {
            return IterEnd
          }

        }
        if cmp_key_low >= 0 && cmp_key_high <= 0 {
          // we should yield this node
          guard yield_(node.key, node.value) is IterContinue else {
            return IterEnd
          }

        }
        if cmp_key_high < 0 {
          guard range_aux(node.right, low, high).run(yield_) is IterContinue else {
            return IterEnd
          }

        }
        IterContinue
      }
    }
  })
}

// AVL tree operations

///|
fn replace_root_with_min[K : Compare, V](
  root : Node[K, V],
  node : Node[K, V]
) -> Node[K, V]? {
  let (l, r) = (node.left, node.right)
  match l {
    None => {
      root.key = node.key
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
fn update_height[K, V](self : Node[K, V]) -> Unit {
  self.height = 1 + max(height(self.left), height(self.right))
}

///|
fn height_ge[K, V](x1 : Node[K, V]?, x2 : Node[K, V]?) -> Bool {
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
fn balance[K : Compare, V](root : Node[K, V]) -> Node[K, V] {
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
fn rotate_l[K : Compare, V](n : Node[K, V]) -> Node[K, V] {
  let r = n.right.unwrap()
  n.right = r.left
  r.left = Some(n)
  n.update_height()
  r.update_height()
  r
}

///|
fn rotate_r[K : Compare, V](n : Node[K, V]) -> Node[K, V] {
  let l = n.left.unwrap()
  n.left = l.right
  l.right = Some(n)
  n.update_height()
  l.update_height()
  l
}

///|
fn rotate_lr[K : Compare, V](n : Node[K, V]) -> Node[K, V] {
  let l = n.left.unwrap()
  let v = rotate_l(l)
  n.left = Some(v)
  rotate_r(n)
}

///|
fn rotate_rl[K : Compare, V](n : Node[K, V]) -> Node[K, V] {
  let r = n.right.unwrap()
  let v = rotate_r(r)
  n.right = Some(v)
  rotate_l(n)
}

///|
fn add_node[K : Compare, V](
  root : Node[K, V]?,
  key : K,
  value : V
) -> (Node[K, V]?, Bool) {
  match root {
    None => (Some(new_node(key, value)), true)
    Some(n) =>
      if key == n.key {
        n.value = value
        (Some(n), false)
      } else {
        let (l, r) = (n.left, n.right)
        if key < n.key {
          let (nl, inserted) = add_node(l, key, value)
          n.left = nl
          (Some(balance(n)), inserted)
        } else {
          let (nr, inserted) = add_node(r, key, value)
          n.right = nr
          (Some(balance(n)), inserted)
        }
      }
  }
}

///|
fn delete_node[K : Compare, V](
  root : Node[K, V],
  key : K
) -> (Node[K, V]?, Bool) {
  if key == root.key {
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
  } else if key < root.key {
    match root.left {
      None => (Some(root), false)
      Some(l) => {
        let (nl, deleted) = delete_node(l, key)
        root.left = nl
        (Some(balance(root)), deleted)
      }
    }
  } else {
    match root.right {
      None => (Some(root), false)
      Some(r) => {
        let (nr, deleted) = delete_node(r, key)
        root.right = nr
        (Some(balance(root)), deleted)
      }
    }
  }
}

///|
test "new" {
  let map : T[Int, String] = new()
  inspect!(map.debug_tree(), content="_")
  inspect!(map.size(), content="0")
}

///|
test "of" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  inspect!(map.size(), content="3")
}

///|
test "add1" {
  let map = new()
  map.add(6, "a")
  map.add(5, "b")
  map.add(4, "c")
  map.add(3, "d")
  map.add(2, "e")
  map.add(1, "f")
  inspect!(
    map.debug_tree(),
    content="([3]3,d,([2]2,e,([1]1,f,_,_),_),([2]5,b,([1]4,c,_,_),([1]6,a,_,_)))",
  )
  inspect!(map.size(), content="6")
}

///|
test "add2" {
  let map = new()
  map.add(1, "a")
  map.add(2, "b")
  map.add(3, "c")
  map.add(4, "d")
  map.add(5, "e")
  map.add(6, "f")
  inspect!(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]5,e,_,([1]6,f,_,_)))",
  )
  inspect!(map.size(), content="6")
}

///|
test "add3" {
  let map = new()
  map.add(4, "a")
  map.add(1, "b")
  map.add(3, "c")
  map.add(2, "d")
  inspect!(
    map.debug_tree(),
    content="([3]3,c,([2]1,b,_,([1]2,d,_,_)),([1]4,a,_,_))",
  )
}

///|
test "add4" {
  let map = new()
  map.add(1, "a")
  map.add(4, "b")
  map.add(2, "c")
  map.add(3, "d")
  inspect!(
    map.debug_tree(),
    content="([3]2,c,([1]1,a,_,_),([2]4,b,([1]3,d,_,_),_))",
  )
}

///|
test "add duplicate key" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  map.add(1, "x")
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,x,_,_),([1]3,c,_,_))")
}

///|
test "remove" {
  let map = from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
    (6, "f"),
    (7, "g"),
    (8, "h"),
  ])
  inspect!(
    map.debug_tree(),
    content="([4]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([3]6,f,([1]5,e,_,_),([2]7,g,_,([1]8,h,_,_))))",
  )
  inspect!(map.size(), content="8")
  map.remove(6)
  inspect!(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,([1]5,e,_,_),([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="7")
  map.remove(4)
  inspect!(
    map.debug_tree(),
    content="([3]5,e,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="6")
  map.remove(2)
  inspect!(
    map.debug_tree(),
    content="([3]5,e,([2]3,c,([1]1,a,_,_),_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="5")
  map.remove(3)
  inspect!(
    map.debug_tree(),
    content="([3]5,e,([1]1,a,_,_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="4")
  map.remove(5)
  inspect!(map.debug_tree(), content="([2]7,g,([1]1,a,_,_),([1]8,h,_,_))")
  inspect!(map.size(), content="3")
  map.remove(7)
  inspect!(map.debug_tree(), content="([2]8,h,([1]1,a,_,_),_)")
  inspect!(map.size(), content="2")
  map.remove(8)
  inspect!(map.debug_tree(), content="([1]1,a,_,_)")
  inspect!(map.size(), content="1")
  map.remove(1)
  inspect!(map.debug_tree(), content="_")
  inspect!(map.size, content="0")
}

///|
test "op_set" {
  let map = new()
  map[1] = "a"
  map[2] = "b"
  map[3] = "c"
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
}

///|
test "clear" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  map.clear()
  inspect!(map.debug_tree(), content="_")
  inspect!(map.size(), content="0")
}

///|
pub impl[K, V] Default for T[K, V] with default() {
  new()
}
