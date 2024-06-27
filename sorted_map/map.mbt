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

pub fn op_set[K : Compare, V](self : T[K, V], key : K, value : V) -> Unit {
  self.add(key, value)
}

pub fn op_get[K : Compare, V](self : T[K, V], key : K) -> V? {
  self.get(key)
}

pub fn op_equal[K : Eq, V : Eq](self : T[K, V], other : T[K, V]) -> Bool {
  self.to_array() == other.to_array()
}

/// Returns a new sorted map.
pub fn new[K, V]() -> T[K, V] {
  { root: None, size: 0 }
}

/// Creates a sorted map from given entries.
pub fn of[K : Compare, V](entries : Array[(K, V)]) -> T[K, V] {
  let map = { root: None, size: 0 }
  entries.each(fn(e) { map.add(e.0, e.1) })
  map
}

/// Inserts a key-value pair.
pub fn add[K : Compare, V](self : T[K, V], key : K, value : V) -> Unit {
  let parent = loop self.root, self.root {
    Some(curr), _ =>
      continue if key < curr.key { curr.left } else { curr.right }, Some(curr)
    None, parent => parent
  }
  let new = new_node(key, value, ~parent)
  if parent.is_empty() {
    self.root = Some(new)
  } else if key < parent.unwrap().key {
    parent.unwrap().left = Some(new)
  } else {
    parent.unwrap().right = Some(new)
  }
  new.parent = parent
  self.balance(new)
  self.size += 1
}

/// Removes a key-value pair.
pub fn remove[K : Compare, V](self : T[K, V], key : K) -> Unit {
  // Find node
  let node = loop self.root {
    Some(node) =>
      if key == node.key {
        break node
      } else if key < node.key {
        continue node.left
      } else {
        continue node.right
      }
    None => return
  }
  self.delete_node(node)
  self.balance(node)
  node.parent = None
  self.size -= 1
}

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

/// Checks if map contains a key-value pair.
pub fn contains[K : Compare, V](self : T[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

/// Returns true if map is empty.
pub fn is_empty[K, V](self : T[K, V]) -> Bool {
  self.size == 0
}

/// Returns the count of key-value pairs in the map.
pub fn size[K, V](self : T[K, V]) -> Int {
  self.size
}

/// Clears the map.
pub fn clear[K, V](self : T[K, V]) -> Unit {
  self.root = None
  self.size = 0
}

/// Iterates the map.
pub fn each[K, V](self : T[K, V], f : (K, V) -> Unit) -> Unit {
  let s = []
  let mut p = self.root
  while p.is_empty().not() || s.is_empty().not() {
    while p.is_empty().not() {
      s.push(p)
      p = p.unwrap().left
    }
    if s.is_empty().not() {
      p = s.pop_exn()
      f(p.unwrap().key, p.unwrap().value)
      p = p.unwrap().right
    }
  }
}

/// Iterates the map with index.
pub fn eachi[K, V](self : T[K, V], f : (Int, K, V) -> Unit) -> Unit {
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
      f(i, p.unwrap().key, p.unwrap().value)
      p = p.unwrap().right
      i += 1
    }
  }
}

/// Returns all keys in the map.
pub fn keys[K, V](self : T[K, V]) -> Array[K] {
  let keys = []
  self.each(fn(k, _v) { keys.push(k) })
  keys
}

/// Returns all values in the map.
pub fn values[K, V](self : T[K, V]) -> Array[V] {
  let values = []
  self.each(fn(_k, v) { values.push(v) })
  values
}

/// Converts the map to an array.
pub fn to_array[K, V](self : T[K, V]) -> Array[(K, V)] {
  let arr = []
  self.each(fn(k, v) { arr.push((k, v)) })
  arr
}

/// Returns a iterator.
pub fn iter[K, V](self : T[K, V]) -> Iter[(K, V)] {
  Iter::_unstable_internal_make(
    fn(yield) {
      let arr = self.to_array()
      for i = 0, len = arr.length(); i < len; i = i + 1 {
        match arr[i] {
          (key, value) => if yield((key, value)) == IterEnd { break IterEnd }
        }
      } else {
        IterContinue
      }
    },
  )
}

// Private functions

fn delete_node[K : Compare, V](self : T[K, V], node : Node[K, V]) -> Unit {
  if node.left.is_empty() {
    self.replace_node(node, node.right)
  } else if node.right.is_empty() {
    self.replace_node(node, node.left)
  } else {
    let succ = min_node(node.right.unwrap())
    if succ.parent != Some(node) {
      self.replace_node(succ, succ.right)
      succ.right = node.right
      node.right.unwrap().parent = Some(succ)
    }
    self.replace_node(node, Some(succ))
    succ.left = node.left
    succ.left.unwrap().parent = Some(succ)
    succ.update_height()
  }
}

fn min_node[K, V](root : Node[K, V]) -> Node[K, V] {
  loop root, root.left {
    _, Some(n) => continue n, n.left
    n, None => n
  }
}

fn replace_node[K : Compare, V](
  self : T[K, V],
  u : Node[K, V],
  v : Node[K, V]?
) -> Unit {
  if u.parent.is_empty() {
    self.root = v
  } else if u.parent.unwrap().left == Some(u) {
    u.parent.unwrap().left = v
  } else {
    u.parent.unwrap().right = v
  }
  if v.is_empty().not() {
    v.unwrap().parent = u.parent
  }
}

fn update_height[K, V](self : Node[K, V]) -> Unit {
  self.height = 1 + max(height(self.left), height(self.right))
}

fn balance[K : Compare, V](self : T[K, V], node : Node[K, V]) -> Unit {
  loop node.parent {
    Some(parent) => {
      let pp = parent.parent
      parent.update_height()
      if height(parent.left) > height(parent.right) + 1 {
        self.rotate_right(parent)
      }
      if height(parent.right) > height(parent.left) + 1 {
        self.rotate_left(parent)
      }
      continue pp
    }
    None => break
  }
}

fn rotate_left[K : Compare, V](self : T[K, V], target : Node[K, V]) -> Unit {
  let pivot = target.right.unwrap()
  target.right = pivot.left
  if pivot.left.is_empty().not() {
    pivot.left.unwrap().parent = Some(target)
  }
  pivot.parent = target.parent
  if target.parent.is_empty() {
    self.root = Some(pivot)
  } else if target.parent.unwrap().left == Some(target) {
    target.parent.unwrap().left = Some(pivot)
  } else {
    target.parent.unwrap().right = Some(pivot)
  }
  pivot.left = Some(target)
  target.parent = Some(pivot)
  target.update_height()
  pivot.update_height()
}

fn rotate_right[K : Compare, V](self : T[K, V], target : Node[K, V]) -> Unit {
  let pivot = target.left.unwrap()
  target.left = pivot.right
  if pivot.right.is_empty().not() {
    pivot.right.unwrap().parent = Some(target)
  }
  pivot.parent = target.parent
  if target.parent.is_empty() {
    self.root = Some(pivot)
  } else if target.parent.unwrap().left == Some(target) {
    target.parent.unwrap().left = Some(pivot)
  } else {
    target.parent.unwrap().right = Some(pivot)
  }
  pivot.right = Some(target)
  target.parent = Some(pivot)
  target.update_height()
  pivot.update_height()
}
