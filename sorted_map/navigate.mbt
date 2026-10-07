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

// Ordered navigation: smallest/largest entries, nearest-key queries,
// and reverse iteration.

///|
/// Returns the entry with the smallest key, or `None` if the map is empty.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(3, "c"), (1, "a"), (2, "b")])
///   @debug.debug_inspect(map.first(), content="Some((1, \"a\"))")
/// }
/// ```
pub fn[K, V] SortedMap::first(self : SortedMap[K, V]) -> (K, V)? {
  guard self.root is Some(root) else { return None }
  for node = root {
    match node.left {
      Some(left) => continue left
      None => break Some((node.key, node.value))
    }
  }
}

///|
/// Returns the entry with the largest key, or `None` if the map is empty.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(3, "c"), (1, "a"), (2, "b")])
///   @debug.debug_inspect(map.last(), content="Some((3, \"c\"))")
/// }
/// ```
pub fn[K, V] SortedMap::last(self : SortedMap[K, V]) -> (K, V)? {
  guard self.root is Some(root) else { return None }
  for node = root {
    match node.right {
      Some(right) => continue right
      None => break Some((node.key, node.value))
    }
  }
}

///|
/// Removes and returns the entry with the smallest key, or returns `None` if
/// the map is empty.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(3, "c"), (1, "a"), (2, "b")])
///   @debug.debug_inspect(map.pop_first(), content="Some((1, \"a\"))")
///   @debug.debug_inspect(map.to_array(), content="[(2, \"b\"), (3, \"c\")]")
/// }
/// ```
pub fn[K, V] SortedMap::pop_first(self : SortedMap[K, V]) -> (K, V)? {
  guard self.root is Some(root) else { return None }
  let (new_root, key, value) = remove_min_node(root)
  self.root = new_root
  self.size -= 1
  Some((key, value))
}

///|
/// Removes and returns the entry with the largest key, or returns `None` if
/// the map is empty.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(3, "c"), (1, "a"), (2, "b")])
///   @debug.debug_inspect(map.pop_last(), content="Some((3, \"c\"))")
///   @debug.debug_inspect(map.to_array(), content="[(1, \"a\"), (2, \"b\")]")
/// }
/// ```
pub fn[K, V] SortedMap::pop_last(self : SortedMap[K, V]) -> (K, V)? {
  guard self.root is Some(root) else { return None }
  let (new_root, key, value) = remove_max_node(root)
  self.root = new_root
  self.size -= 1
  Some((key, value))
}

///|
/// Returns the entry with the smallest key that is greater than or equal to
/// `key`, or `None` if there is no such entry.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(10, "a"), (20, "b"), (30, "c")])
///   @debug.debug_inspect(map.first_ge(20), content="Some((20, \"b\"))")
///   @debug.debug_inspect(map.first_ge(21), content="Some((30, \"c\"))")
///   @debug.debug_inspect(map.first_ge(31), content="None")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::first_ge(
  self : SortedMap[K, V],
  key : K,
) -> (K, V)? {
  successor(self.root, key, inclusive=true)
}

///|
/// Returns the entry with the smallest key that is strictly greater than
/// `key`, or `None` if there is no such entry.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(10, "a"), (20, "b"), (30, "c")])
///   @debug.debug_inspect(map.first_gt(20), content="Some((30, \"c\"))")
///   @debug.debug_inspect(map.first_gt(30), content="None")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::first_gt(
  self : SortedMap[K, V],
  key : K,
) -> (K, V)? {
  successor(self.root, key, inclusive=false)
}

///|
/// Returns the entry with the largest key that is less than or equal to
/// `key`, or `None` if there is no such entry.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(10, "a"), (20, "b"), (30, "c")])
///   @debug.debug_inspect(map.last_le(20), content="Some((20, \"b\"))")
///   @debug.debug_inspect(map.last_le(19), content="Some((10, \"a\"))")
///   @debug.debug_inspect(map.last_le(9), content="None")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::last_le(
  self : SortedMap[K, V],
  key : K,
) -> (K, V)? {
  predecessor(self.root, key, inclusive=true)
}

///|
/// Returns the entry with the largest key that is strictly less than `key`,
/// or `None` if there is no such entry.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(10, "a"), (20, "b"), (30, "c")])
///   @debug.debug_inspect(map.last_lt(20), content="Some((10, \"a\"))")
///   @debug.debug_inspect(map.last_lt(10), content="None")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::last_lt(
  self : SortedMap[K, V],
  key : K,
) -> (K, V)? {
  predecessor(self.root, key, inclusive=false)
}

///|
/// Returns an iterator over all entries in descending key order.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(1, "a"), (3, "c"), (2, "b")])
///   @debug.debug_inspect(
///     map.rev_iter().to_array(),
///     content="[(3, \"c\"), (2, \"b\"), (1, \"a\")]",
///   )
/// }
/// ```
pub fn[K, V] SortedMap::rev_iter(self : SortedMap[K, V]) -> Iter[(K, V)] {
  rev_nodes(self).map(node => (node.key, node.value))
}

///|
/// Returns a two-value iterator over entries in descending key order,
/// according to the keys' `Compare` ordering.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(1, "a"), (3, "c"), (2, "b")])
///   let entries = []
///   for key, value in map.rev_iter2() {
///     entries.push((key, value))
///   }
///   @debug.debug_inspect(entries, content="[(3, \"c\"), (2, \"b\"), (1, \"a\")]")
/// }
/// ```
pub fn[K, V] SortedMap::rev_iter2(self : SortedMap[K, V]) -> Iter2[K, V] {
  self.rev_iter()
}

///|
/// Returns an iterator over the keys in descending order.
pub fn[K, V] SortedMap::rev_keys(self : SortedMap[K, V]) -> Iter[K] {
  rev_nodes(self).map(node => node.key)
}

///|
/// Returns an iterator over the values in descending key order.
pub fn[K, V] SortedMap::rev_values(self : SortedMap[K, V]) -> Iter[V] {
  rev_nodes(self).map(node => node.value)
}

///|
fn[K, V] rev_nodes(map : SortedMap[K, V]) -> Iter[Node[K, V]] {
  let stack : Array[Node[K, V]] = []
  let mut next_node = map.root
  Iter::new(
    fn() {
      for x = next_node {
        match x {
          Some(node) => {
            stack.push(node)
            continue node.right
          }
          None =>
            match stack.pop() {
              Some(node) => {
                next_node = node.left
                break Some(node)
              }
              None => {
                next_node = None
                break None
              }
            }
        }
      }
    },
    size_hint=map.size,
  )
}

///|
/// The entry with the smallest key `>= key` (or `> key` when not inclusive).
fn[K : Compare, V] successor(
  root : Node[K, V]?,
  key : K,
  inclusive~ : Bool,
) -> (K, V)? {
  for x = root, best = None {
    match x {
      Some(node) => {
        let cmp = node.key.compare(key)
        if cmp == 0 && inclusive {
          break Some((node.key, node.value))
        } else if cmp > 0 {
          continue node.left, Some(node)
        } else {
          continue node.right, best
        }
      }
      None => break best.map(node => (node.key, node.value))
    }
  }
}

///|
/// The entry with the largest key `<= key` (or `< key` when not inclusive).
fn[K : Compare, V] predecessor(
  root : Node[K, V]?,
  key : K,
  inclusive~ : Bool,
) -> (K, V)? {
  for x = root, best = None {
    match x {
      Some(node) => {
        let cmp = node.key.compare(key)
        if cmp == 0 && inclusive {
          break Some((node.key, node.value))
        } else if cmp < 0 {
          continue node.right, Some(node)
        } else {
          continue node.left, best
        }
      }
      None => break best.map(node => (node.key, node.value))
    }
  }
}

///|
/// Removes the leftmost node of the subtree rooted at `node`, rebalancing on
/// the way back up. Returns the new subtree root and the removed entry.
fn[K, V] remove_min_node(node : Node[K, V]) -> (Node[K, V]?, K, V) {
  match node.left {
    None => (node.right, node.key, node.value)
    Some(left) => {
      let (new_left, key, value) = remove_min_node(left)
      node.left = new_left
      (Some(balance(node)), key, value)
    }
  }
}

///|
/// Removes the rightmost node of the subtree rooted at `node`, rebalancing on
/// the way back up. Returns the new subtree root and the removed entry.
fn[K, V] remove_max_node(node : Node[K, V]) -> (Node[K, V]?, K, V) {
  match node.right {
    None => (node.left, node.key, node.value)
    Some(right) => {
      let (new_right, key, value) = remove_max_node(right)
      node.right = new_right
      (Some(balance(node)), key, value)
    }
  }
}
