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
pub fn[K : Compare, V] op_set(
  self : SortedMap[K, V],
  key : K,
  value : V,
) -> Unit {
  self.add(key, value)
}

///|
pub impl[K : Eq, V : Eq] Eq for SortedMap[K, V] with equal(self, other) {
  self.to_array() == other.to_array()
}

///|
/// Returns a new sorted map.
#as_free_fn
pub fn[K, V] SortedMap::new() -> SortedMap[K, V] {
  { root: None, size: 0 }
}

///|
/// Creates a sorted map from a array of key-value pairs.
#as_free_fn
pub fn[K : Compare, V] SortedMap::from_array(
  entries : Array[(K, V)],
) -> SortedMap[K, V] {
  let map = { root: None, size: 0 }
  entries.each(e => map.add(e.0, e.1))
  map
}

///|
#as_free_fn
pub fn[K : Compare, V] SortedMap::of(
  entries : FixedArray[(K, V)],
) -> SortedMap[K, V] {
  let map = { root: None, size: 0 }
  for i in 0..<entries.length() {
    map.add(entries[i].0, entries[i].1)
  }
  map
}

///|
/// Inserts a key-value pair.
pub fn[K : Compare, V] add(self : SortedMap[K, V], key : K, value : V) -> Unit {
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
pub fn[K : Compare, V] remove(self : SortedMap[K, V], key : K) -> Unit {
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
pub fn[K : Compare, V] get(self : SortedMap[K, V], key : K) -> V? {
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
/// Gets a value by a key.
pub fn[K : Compare, V] op_get(self : SortedMap[K, V], key : K) -> V {
  loop self.root {
    Some(node) => {
      let cmp = key.compare(node.key)
      if cmp == 0 {
        break node.value
      } else if cmp > 0 {
        continue node.right
      } else {
        continue node.left
      }
    }
    None => panic()
  }
}

///|
/// Checks if map contains a key-value pair.
pub fn[K : Compare, V] contains(self : SortedMap[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

///|
/// Returns true if map is empty.
pub fn[K, V] is_empty(self : SortedMap[K, V]) -> Bool {
  self.size == 0
}

///|
/// Returns the count of key-value pairs in the map.
pub fn[K, V] size(self : SortedMap[K, V]) -> Int {
  self.size
}

///|
/// Clears the map.
pub fn[K, V] clear(self : SortedMap[K, V]) -> Unit {
  self.root = None
  self.size = 0
}

///|
/// Iterates the map.
pub fn[K, V] each(
  self : SortedMap[K, V],
  f : (K, V) -> Unit raise?,
) -> Unit raise? {
  fn dfs(root : Node[K, V]?) -> Unit raise? {
    if root is Some(root) {
      dfs(root.left)
      f(root.key, root.value)
      dfs(root.right)
    }
  }

  dfs(self.root)
}

///|
/// Iterates the map with index.
pub fn[K, V] eachi(
  self : SortedMap[K, V],
  f : (Int, K, V) -> Unit raise?,
) -> Unit raise? {
  let mut i = 0
  self.each((k, v) => {
    f(i, k, v)
    i = i + 1
  })
}

///|
/// Returns all keys in the map.
pub fn[K, V] keys_as_iter(self : SortedMap[K, V]) -> Iter[K] {
  Iter::new(fn(yield_) {
    fn go(x : Node[K, V]?) {
      match x {
        None => IterContinue
        Some({ left, right, key, .. }) =>
          if go(left) is IterEnd {
            IterEnd
          } else if yield_(key) is IterEnd {
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
/// Returns all values in the map.
pub fn[K, V] values_as_iter(self : SortedMap[K, V]) -> Iter[V] {
  Iter::new(fn(yield_) {
    fn go(x : Node[K, V]?) {
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
/// Converts the map to an array.
pub fn[K, V] to_array(self : SortedMap[K, V]) -> Array[(K, V)] {
  let arr = Array::new(capacity=self.size)
  self.each((k, v) => arr.push((k, v)))
  arr
}

///|
pub fn[K, V] iter(self : SortedMap[K, V]) -> Iter[(K, V)] {
  Iter::new(yield_ => {
    fn go(x : Node[K, V]?) {
      match x {
        None => IterContinue
        Some({ left, right, key, value, .. }) =>
          if go(left) is IterEnd {
            IterEnd
          } else if yield_((key, value)) is IterEnd {
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
pub fn[K, V] iter2(self : SortedMap[K, V]) -> Iter2[K, V] {
  Iter2::new(yield_ => {
    fn go(x : Node[K, V]?) {
      match x {
        None => IterContinue
        Some({ left, right, key, value, .. }) =>
          if go(left) is IterEnd {
            IterEnd
          } else if yield_(key, value) is IterEnd {
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
pub fn[K : Compare, V] SortedMap::from_iter(
  iter : Iter[(K, V)],
) -> SortedMap[K, V] {
  let m = new()
  iter.each(e => m[e.0] = e.1)
  m
}

///|
pub impl[K : @quickcheck.Arbitrary + Compare, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for SortedMap[
  K,
  V,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|
///Returns a new array of key-value pairs that are within the specified range [low, high].
pub fn[K : Compare, V] range(
  self : SortedMap[K, V],
  low : K,
  high : K,
) -> Iter2[K, V] {
  Iter2::new(yield_ => {
    fn go(x : Node[K, V]?) {
      match x {
        None => IterContinue
        Some({ left, right, key, value, .. }) => {
          let cmp_key_low = key.compare(low)
          let cmp_key_high = key.compare(high)
          if cmp_key_low > 0 && go(left) is IterEnd {
            IterEnd
          } else if cmp_key_low >= 0 &&
            cmp_key_high <= 0 &&
            yield_(key, value) is IterEnd {
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
fn[K : Compare, V] replace_root_with_min(
  root : Node[K, V],
  node : Node[K, V],
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
fn[K, V] update_height(self : Node[K, V]) -> Unit {
  self.height = 1 + max(height(self.left), height(self.right))
}

///|
fn[K, V] height_ge(x1 : Node[K, V]?, x2 : Node[K, V]?) -> Bool {
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
fn[K, V] balance(root : Node[K, V]) -> Node[K, V] {
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
fn[K, V] rotate_l(n : Node[K, V]) -> Node[K, V] {
  let r = n.right.unwrap()
  n.right = r.left
  r.left = Some(n)
  n.update_height()
  r.update_height()
  r
}

///|
fn[K, V] rotate_r(n : Node[K, V]) -> Node[K, V] {
  let l = n.left.unwrap()
  n.left = l.right
  l.right = Some(n)
  n.update_height()
  l.update_height()
  l
}

///|
fn[K, V] rotate_lr(n : Node[K, V]) -> Node[K, V] {
  let l = n.left.unwrap()
  let v = rotate_l(l)
  n.left = Some(v)
  rotate_r(n)
}

///|
fn[K, V] rotate_rl(n : Node[K, V]) -> Node[K, V] {
  let r = n.right.unwrap()
  let v = rotate_r(r)
  n.right = Some(v)
  rotate_l(n)
}

///|
fn[K : Compare, V] add_node(
  root : Node[K, V]?,
  key : K,
  value : V,
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
fn[K : Compare, V] delete_node(
  root : Node[K, V],
  key : K,
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
  let map : SortedMap[Int, String] = new()
  inspect(map.debug_tree(), content="_")
  inspect(map.size(), content="0")
}

///|
test "of" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  inspect(map.size(), content="3")
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
  inspect(
    map.debug_tree(),
    content="([3]3,d,([2]2,e,([1]1,f,_,_),_),([2]5,b,([1]4,c,_,_),([1]6,a,_,_)))",
  )
  inspect(map.size(), content="6")
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
  inspect(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]5,e,_,([1]6,f,_,_)))",
  )
  inspect(map.size(), content="6")
}

///|
test "add3" {
  let map = new()
  map.add(4, "a")
  map.add(1, "b")
  map.add(3, "c")
  map.add(2, "d")
  inspect(
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
  inspect(
    map.debug_tree(),
    content="([3]2,c,([1]1,a,_,_),([2]4,b,([1]3,d,_,_),_))",
  )
}

///|
test "add duplicate key" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  map.add(1, "x")
  inspect(map.debug_tree(), content="([2]2,b,([1]1,x,_,_),([1]3,c,_,_))")
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
  inspect(
    map.debug_tree(),
    content="([4]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([3]6,f,([1]5,e,_,_),([2]7,g,_,([1]8,h,_,_))))",
  )
  inspect(map.size(), content="8")
  map.remove(6)
  inspect(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,([1]5,e,_,_),([1]8,h,_,_)))",
  )
  inspect(map.size(), content="7")
  map.remove(4)
  inspect(
    map.debug_tree(),
    content="([3]5,e,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect(map.size(), content="6")
  map.remove(2)
  inspect(
    map.debug_tree(),
    content="([3]5,e,([2]3,c,([1]1,a,_,_),_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect(map.size(), content="5")
  map.remove(3)
  inspect(
    map.debug_tree(),
    content="([3]5,e,([1]1,a,_,_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect(map.size(), content="4")
  map.remove(5)
  inspect(map.debug_tree(), content="([2]7,g,([1]1,a,_,_),([1]8,h,_,_))")
  inspect(map.size(), content="3")
  map.remove(7)
  inspect(map.debug_tree(), content="([2]8,h,([1]1,a,_,_),_)")
  inspect(map.size(), content="2")
  map.remove(8)
  inspect(map.debug_tree(), content="([1]1,a,_,_)")
  inspect(map.size(), content="1")
  map.remove(1)
  inspect(map.debug_tree(), content="_")
  inspect(map.size, content="0")
}

///|
test "op_set" {
  let map = new()
  map[1] = "a"
  map[2] = "b"
  map[3] = "c"
  inspect(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
}

///|
test "clear" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  map.clear()
  inspect(map.debug_tree(), content="_")
  inspect(map.size(), content="0")
}

///|
pub impl[K, V] Default for SortedMap[K, V] with default() {
  new()
}
