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
/// Returns an iterator over the entries whose keys lie between `lower` and
/// `upper`, in ascending key order.
///
/// Each end is a `@cmp.Bound`: `Included(k)`, `Excluded(k)` or `Unbounded`.
/// Because bounds are values, the kind of each end can be chosen at runtime.
/// Inclusion and exclusion follow `Compare::compare`, as do `range` and the
/// nearest-key queries. Lower and upper refer to that ordering, including
/// when keys use `@cmp.Reverse`.
/// The iterator is lazy: it visits O(log n) nodes to find the first entry,
/// then O(1) amortized per entry, so stopping early is cheap.
///
/// An empty iterator is returned when the bounds select no keys, including
/// when `lower` is above `upper`.
/// When the endpoints compare equal, excluding either endpoint selects no keys.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c"), (4, "d")])
///   let keys = map.range_bounds(Excluded(1), Included(3)).iter().map(p => p.0)
///   @debug.debug_inspect(keys.to_array(), content="[2, 3]")
///   let tail = map.range_bounds(Included(3), Unbounded).iter().map(p => p.0)
///   @debug.debug_inspect(tail.to_array(), content="[3, 4]")
///   let empty = map.range_bounds(Included(2), Excluded(2))
///   @debug.debug_inspect(empty.iter().to_array(), content="[]")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::range_bounds(
  self : SortedMap[K, V],
  lower : @cmp.Bound[K],
  upper : @cmp.Bound[K],
) -> Iter2[K, V] {
  let stack : Array[Node[K, V]] = []
  let mut next_node = self.root
  Iter2::new(fn() {
    for x = next_node {
      match x {
        Some(node) =>
          if !satisfies_lower(node.key, lower) {
            // The node and its left subtree are below the range.
            continue node.right
          } else if !satisfies_upper(node.key, upper) {
            // The node and its right subtree are above the range.
            continue node.left
          } else {
            stack.push(node)
            continue node.left
          }
        None =>
          match stack.pop() {
            Some(node) => {
              next_node = node.right
              break Some((node.key, node.value))
            }
            None => {
              next_node = None
              break None
            }
          }
      }
    }
  })
}

///|
/// Returns an iterator over the entries whose keys lie between `lower` and
/// `upper`, in descending key order. See `range_bounds` for how bounds work.
/// The arguments remain in lower–upper order; only traversal is reversed.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c"), (4, "d")])
///   let keys = map.rev_range_bounds(Unbounded, Excluded(4)).iter().map(p => p.0)
///   @debug.debug_inspect(keys.to_array(), content="[3, 2, 1]")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::rev_range_bounds(
  self : SortedMap[K, V],
  lower : @cmp.Bound[K],
  upper : @cmp.Bound[K],
) -> Iter2[K, V] {
  let stack : Array[Node[K, V]] = []
  let mut next_node = self.root
  Iter2::new(fn() {
    for x = next_node {
      match x {
        Some(node) =>
          if !satisfies_upper(node.key, upper) {
            // The node and its right subtree are above the range.
            continue node.left
          } else if !satisfies_lower(node.key, lower) {
            // The node and its left subtree are below the range.
            continue node.right
          } else {
            stack.push(node)
            continue node.right
          }
        None =>
          match stack.pop() {
            Some(node) => {
              next_node = node.left
              break Some((node.key, node.value))
            }
            None => {
              next_node = None
              break None
            }
          }
      }
    }
  })
}

///|
/// Returns an iterator over the entries whose keys are within `[low, high]`
/// (both inclusive), in descending key order. This is the reverse of `range`.
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c"), (4, "d")])
///   let keys = map.rev_range(2, 3).iter().map(p => p.0)
///   @debug.debug_inspect(keys.to_array(), content="[3, 2]")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::rev_range(
  self : SortedMap[K, V],
  low : K,
  high : K,
) -> Iter2[K, V] {
  self.rev_range_bounds(Included(low), Included(high))
}

///|
/// Bounds are checked with `Compare::compare`, the same ordering the map uses
/// for insertion and lookup. For keys such as `Double`, the relational
/// operators disagree with `compare` on NaN, so they must not be used here.
fn[K : Compare] satisfies_lower(key : K, lower : @cmp.Bound[K]) -> Bool {
  match lower {
    Included(bound) => key.compare(bound) >= 0
    Excluded(bound) => key.compare(bound) > 0
    Unbounded => true
  }
}

///|
fn[K : Compare] satisfies_upper(key : K, upper : @cmp.Bound[K]) -> Bool {
  match upper {
    Included(bound) => key.compare(bound) <= 0
    Excluded(bound) => key.compare(bound) < 0
    Unbounded => true
  }
}
