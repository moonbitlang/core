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

fn new_node[K, V](
  key : K,
  value : V,
  ~parent : Node[K, V]? = None
) -> Node[K, V] {
  { key, value, parent, left: None, right: None, height: 0 }
}

fn max(x : Int, y : Int) -> Int {
  if x > y {
    x
  } else {
    y
  }
}

fn height[K, V](node : Node[K, V]?) -> Int {
  match node {
    Some(n) => n.height
    None => -1
  }
}

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
      parent.update_height()
      if height(parent.left) > height(parent.right) + 1 {
        self.rotate_right(parent)
      }
      if height(parent.right) > height(parent.left) + 1 {
        self.rotate_left(parent)
      }
      continue parent.parent
    }
    _ => break
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

fn debug_node[K : Show, V : Show](self : Node[K, V]) -> String {
  let l = match self.left {
    Some(left) => left.debug_node()
    None => "_"
  }
  let r = match self.right {
    Some(right) => right.debug_node()
    None => "_"
  }
  let key = self.key
  let value = self.value
  let height = self.height
  "([\(height)]\(key),\(value),\(l),\(r))"
}

fn debug_tree[K : Show, V : Show](self : T[K, V]) -> String {
  match self.root {
    Some(root) => root.debug_node()
    None => "_"
  }
}
