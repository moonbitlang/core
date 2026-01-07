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

///|
pub impl[K : Eq, V : Eq] Eq for SortedMap[K, V] with equal(self, other) {
  guard self.size == other.size else { return false }
  let iter = self.iter()
  let iter1 = other.iter()
  while iter.next() is Some(a) && iter1.next() is Some(b) {
    guard a == b else { break false }
  } else {
    true
  }
}

///|
/// Returns a new sorted map.
#as_free_fn
pub fn[K, V] SortedMap::new() -> SortedMap[K, V] {
  { root: None, size: 0 }
}

///|
/// Creates a sorted map from an array of key-value pairs.
#as_free_fn
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[K : Compare, V] SortedMap::from_array(
  entries : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  let map = { root: None, size: 0 }
  for e in entries {
    map.set(e.0, e.1)
  }
  map
}

///|
/// FIXME: (remove this line will break formatter)
/// ```mbt check
/// test {
///   let map = @sorted_map.new()
///   map.set(1, "a")
///   map.set(2, "b")
///   map.set(2, "c") // updates value for key 2
///   inspect(map.get(1), content="Some(\"a\")")
///   inspect(map.get(2), content="Some(\"c\")")
/// }
/// ```
#alias("_[_]=_")
#alias(add, deprecated="Use set instead")
pub fn[K : Compare, V] SortedMap::set(
  self : SortedMap[K, V],
  key : K,
  value : V,
) -> Unit {
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
pub fn[K : Compare, V] SortedMap::remove(
  self : SortedMap[K, V],
  key : K,
) -> Unit {
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
pub fn[K : Compare, V] SortedMap::get(self : SortedMap[K, V], key : K) -> V? {
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
#alias("_[_]")
pub fn[K : Compare, V] SortedMap::at(self : SortedMap[K, V], key : K) -> V {
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
pub fn[K : Compare, V] SortedMap::contains(
  self : SortedMap[K, V],
  key : K,
) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

///|
/// Returns true if map is empty.
pub fn[K, V] SortedMap::is_empty(self : SortedMap[K, V]) -> Bool {
  self.size == 0
}

///|
/// Returns the count of key-value pairs in the map.
#alias(size, deprecated)
pub fn[K, V] SortedMap::length(self : SortedMap[K, V]) -> Int {
  self.size
}

///|
/// Clears the map.
pub fn[K, V] SortedMap::clear(self : SortedMap[K, V]) -> Unit {
  self.root = None
  self.size = 0
}

///|
/// Iterates the map.
pub fn[K, V] SortedMap::each(
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
pub fn[K, V] SortedMap::eachi(
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
pub fn[K, V] SortedMap::keys_as_iter(self : SortedMap[K, V]) -> Iter[K] {
  let todo_list = []
  let mut next_node = self.root
  Iter::new(fn() {
    loop next_node {
      Some({ left, key, value: _, right, height: _ }) => {
        todo_list.push((key, right))
        continue left
      }
      None if todo_list.pop() is Some((key, right)) => {
        next_node = right
        Some(key)
      }
      None => None
    }
  })
}

///|
/// Returns all values in the map.
pub fn[K, V] SortedMap::values_as_iter(self : SortedMap[K, V]) -> Iter[V] {
  let todo_list = []
  let mut next_node = self.root
  Iter::new(fn() {
    loop next_node {
      Some({ left, key: _, value, right, height: _ }) => {
        todo_list.push((value, right))
        continue left
      }
      None if todo_list.pop() is Some((value, right)) => {
        next_node = right
        Some(value)
      }
      None => None
    }
  }).iter()
}

///|
/// Converts the map to an array.
pub fn[K, V] SortedMap::to_array(self : SortedMap[K, V]) -> Array[(K, V)] {
  let arr = Array::new(capacity=self.size)
  self.each((k, v) => arr.push((k, v)))
  arr
}

///|
#alias(iterator, deprecated)
pub fn[K, V] SortedMap::iter(self : SortedMap[K, V]) -> Iter[(K, V)] {
  let todo_list = []
  let mut next_node = self.root
  Iter::new(fn() {
    loop next_node {
      Some({ left, key, value, right, height: _ }) => {
        todo_list.push((key, value, right))
        continue left
      }
      None if todo_list.pop() is Some((key, value, right)) => {
        next_node = right
        Some((key, value))
      }
      None => None
    }
  })
}

///|
#alias(iterator2, deprecated)
pub fn[K, V] SortedMap::iter2(self : SortedMap[K, V]) -> Iter2[K, V] {
  self.iter()
}

///|
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Compare, V] SortedMap::from_iter(
  iter : Iter[(K, V)],
) -> SortedMap[K, V] {
  let m = new()
  while iter.next() is Some((k, v)) {
    m[k] = v
  }
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
/// Returns a new array of key-value pairs that are within the specified range [low, high].
pub fn[K : Compare, V] SortedMap::range(
  self : SortedMap[K, V],
  low : K,
  high : K,
) -> Iter2[K, V] {
  let todo_list = []
  let mut next_node = self.root
  Iter2::new(fn() {
    loop next_node {
      Some({ left, key, value, right, height: _ }) => {
        let cmp_key_low = key.compare(low)
        let cmp_key_high = key.compare(high)
        if cmp_key_low < 0 {
          // `key > low`, the left subtree and the value itself
          // should not be visited
          continue right
        } else if cmp_key_high > 0 {
          // `key > right`, the right subtree and the value itself
          // should not be visited
          continue left
          // `low <= key <= high`,
          // the value itself falls in the range,
          // and both the left and right sub tree need to be visited
        } else if left is None {
          next_node = right
          Some((key, value))
        } else {
          todo_list.push((key, value, right))
          continue left
        }
      }
      None if todo_list.pop() is Some((key, value, right)) => {
        next_node = right
        Some((key, value))
      }
      None => None
    }
  }).iter2()
}

///|
/// Creates a deep copy of the sorted map.
///
/// This operation creates a new map with the same structure and contents as the
/// original map. The copy is independent - modifications to the copy will not
/// affect the original map and vice versa.
///
/// This is more efficient than creating a new map and inserting all elements,
/// as it preserves the tree structure without needing to rebalance.
///
/// Parameters:
///
/// * `self` : The sorted map to copy.
///
/// Returns a new sorted map with the same contents and structure.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map1 = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c")])
///   let map2 = map1.copy()
///   map2.set(4, "d")
///   inspect(map1.length(), content="3")
///   inspect(map2.length(), content="4")
/// }
/// ```
pub fn[K, V] SortedMap::copy(self : SortedMap[K, V]) -> SortedMap[K, V] {
  fn copy_node(node : Node[K, V]?) -> Node[K, V]? {
    match node {
      None => None
      Some({ key, value, left, right, height }) =>
        Some({
          key,
          value,
          left: copy_node(left),
          right: copy_node(right),
          height,
        })
    }
  }

  { root: copy_node(self.root), size: self.size }
}

///|
/// Merges two sorted maps into a new map. Returns a new map containing all
/// key-value pairs from both maps. When both maps contain the same key, the
/// value from `other` takes precedence.
///
/// This is a pure operation - it does not modify either of the input maps.
///
/// Parameters:
///
/// * `self` : The first sorted map.
/// * `other` : The second sorted map whose values take precedence in case of
/// key conflicts.
///
/// Returns a new sorted map containing all entries from both maps.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map1 = @sorted_map.from_array([(1, "a"), (2, "b")])
///   let map2 = @sorted_map.from_array([(2, "c"), (3, "d")])
///   let merged = map1.merge(map2)
///   inspect(merged.get(1), content="Some(\"a\")")
///   inspect(merged.get(2), content="Some(\"c\")")
///   inspect(merged.get(3), content="Some(\"d\")")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::merge(
  self : SortedMap[K, V],
  other : SortedMap[K, V],
) -> SortedMap[K, V] {
  let result = self.copy()
  other.each((k, v) => result.set(k, v))
  result
}

///|
/// Merges another sorted map into this map in-place. Updates the current map by
/// adding all key-value pairs from `other`. When both maps contain the same key,
/// the value from `other` overwrites the value in this map.
///
/// This is a mutating operation - it modifies the receiver map.
///
/// Parameters:
///
/// * `self` : The sorted map to be modified.
/// * `other` : The sorted map whose entries will be added to `self`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map1 = @sorted_map.from_array([(1, "a"), (2, "b")])
///   let map2 = @sorted_map.from_array([(2, "c"), (3, "d")])
///   map1.merge_in_place(map2)
///   inspect(map1.get(1), content="Some(\"a\")")
///   inspect(map1.get(2), content="Some(\"c\")")
///   inspect(map1.get(3), content="Some(\"d\")")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::merge_in_place(
  self : SortedMap[K, V],
  other : SortedMap[K, V],
) -> Unit {
  other.each((k, v) => self.set(k, v))
}

// AVL tree operations

///|
fn[K, V] replace_root_with_min(
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
fn[K, V] Node::update_height(self : Node[K, V]) -> Unit {
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
  inspect(map.length(), content="0")
}

///|
test "of" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  inspect(map.length(), content="3")
}

///|
test "add1" {
  let map = new()
  map.set(6, "a")
  map.set(5, "b")
  map.set(4, "c")
  map.set(3, "d")
  map.set(2, "e")
  map.set(1, "f")
  inspect(
    map.debug_tree(),
    content="([3]3,d,([2]2,e,([1]1,f,_,_),_),([2]5,b,([1]4,c,_,_),([1]6,a,_,_)))",
  )
  inspect(map.length(), content="6")
}

///|
test "add2" {
  let map = new()
  map.set(1, "a")
  map.set(2, "b")
  map.set(3, "c")
  map.set(4, "d")
  map.set(5, "e")
  map.set(6, "f")
  inspect(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]5,e,_,([1]6,f,_,_)))",
  )
  inspect(map.length(), content="6")
}

///|
test "add3" {
  let map = new()
  map.set(4, "a")
  map.set(1, "b")
  map.set(3, "c")
  map.set(2, "d")
  inspect(
    map.debug_tree(),
    content="([3]3,c,([2]1,b,_,([1]2,d,_,_)),([1]4,a,_,_))",
  )
}

///|
test "add4" {
  let map = new()
  map.set(1, "a")
  map.set(4, "b")
  map.set(2, "c")
  map.set(3, "d")
  inspect(
    map.debug_tree(),
    content="([3]2,c,([1]1,a,_,_),([2]4,b,([1]3,d,_,_),_))",
  )
}

///|
test "add duplicate key" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  map.set(1, "x")
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
  inspect(map.length(), content="8")
  map.remove(6)
  inspect(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,([1]5,e,_,_),([1]8,h,_,_)))",
  )
  inspect(map.length(), content="7")
  map.remove(4)
  inspect(
    map.debug_tree(),
    content="([3]5,e,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect(map.length(), content="6")
  map.remove(2)
  inspect(
    map.debug_tree(),
    content="([3]5,e,([2]3,c,([1]1,a,_,_),_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect(map.length(), content="5")
  map.remove(3)
  inspect(
    map.debug_tree(),
    content="([3]5,e,([1]1,a,_,_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect(map.length(), content="4")
  map.remove(5)
  inspect(map.debug_tree(), content="([2]7,g,([1]1,a,_,_),([1]8,h,_,_))")
  inspect(map.length(), content="3")
  map.remove(7)
  inspect(map.debug_tree(), content="([2]8,h,([1]1,a,_,_),_)")
  inspect(map.length(), content="2")
  map.remove(8)
  inspect(map.debug_tree(), content="([1]1,a,_,_)")
  inspect(map.length(), content="1")
  map.remove(1)
  inspect(map.debug_tree(), content="_")
  inspect(map.size, content="0")
}

///|
test "_[_]=_" {
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
  inspect(map.length(), content="0")
}

///|
test "copy" {
  let map1 = from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
    (6, "f"),
  ])
  let map2 = map1.copy()
  inspect(map1.debug_tree(), content=map2.debug_tree())
  inspect(map1.length(), content="6")
  inspect(map2.length(), content="6")

  // Verify independence - modifying copy doesn't affect original
  map2.set(7, "g")
  inspect(map1.length(), content="6")
  inspect(map2.length(), content="7")
  inspect(map1.get(7), content="None")
  inspect(map2.get(7), content="Some(\"g\")")

  // Verify independence - modifying original doesn't affect copy
  map1.remove(1)
  inspect(map1.length(), content="5")
  inspect(map2.length(), content="7")
  inspect(map1.get(1), content="None")
  inspect(map2.get(1), content="Some(\"a\")")
}

///|
pub impl[K, V] Default for SortedMap[K, V] with default() {
  new()
}
