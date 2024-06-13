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

/// Returns a new sorted map.
pub fn new[K, V]() -> T[K, V] {
  { root: None, size: 0 }
}

/// Creates a sorted map from given entries.
pub fn of[K : Compare, V](entries : Array[(K, V)]) -> T[K, V] {
  let map = { root: None, size: 0 }
  entries.iter(fn(e) { map.add(e.0, e.1) })
  map
}

/// Inserts a key-value pair.
pub fn add[K : Compare, V](self : T[K, V], key : K, value : V) -> Unit {
  if self.size == 0 {
    self.root = Some(new_node(key, value))
    self.size += 1
    return
  }
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

pub fn op_set[K : Compare, V](self : T[K, V], key : K, value : V) -> Unit {
  self.add(key, value)
}

pub fn op_get[K : Compare, V](self : T[K, V], key : K) -> V? {
  self.get(key)
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
