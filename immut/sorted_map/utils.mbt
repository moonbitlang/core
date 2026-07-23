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
/// Create an empty map.
#as_free_fn
#alias(empty, deprecated)
pub fn[K, V] SortedMap::new() -> SortedMap[K, V] {
  Empty
}

///|
/// Create a map with a single key-value pair.
#as_free_fn
pub fn[K, V] SortedMap::singleton(key : K, value : V) -> SortedMap[K, V] {
  Tree(key, value~, size=1, Empty, Empty)
}

///|
/// Check if the map contains a key.
/// O(log n).
pub fn[K : Compare, V] SortedMap::contains(
  self : SortedMap[K, V],
  key : K,
) -> Bool {
  for x = self {
    match x {
      Empty => break false
      Tree(k, l, r, ..) => {
        let c = key.compare(k)
        if c == 0 {
          break true
        } else if c < 0 {
          continue l
        } else {
          continue r
        }
      }
    }
  }
}

///|
/// Get the number of key-value pairs in the map.
#alias(size, deprecated)
#inline
pub fn[K, V] SortedMap::length(self : SortedMap[K, V]) -> Int {
  match self {
    Empty => 0
    Tree(_) as t => t.size
  }
}

///|
/// Return whether the value empty.
pub fn[K, V] SortedMap::is_empty(self : SortedMap[K, V]) -> Bool {
  self.length() == 0
}

///|
#inline
fn[K, V] make_tree(
  key : K,
  value : V,
  l : SortedMap[K, V],
  r : SortedMap[K, V],
) -> SortedMap[K, V] {
  // length() is #inline, so the size match collapses into make_tree, which
  // is itself #inline into balance / merge / add.
  let size = l.length() + r.length() + 1
  Tree(key, value~, size~, l, r)
}

///|
/// Get the value associated with a key.
/// O(log n).
#alias(lookup, deprecated)
pub fn[K : Compare, V] SortedMap::get(self : SortedMap[K, V], key : K) -> V? {
  for x = self {
    match x {
      Empty => break None
      Tree(k, value~, l, r, ..) => {
        let c = key.compare(k)
        if c == 0 {
          break Some(value)
        } else if c < 0 {
          continue l
        } else {
          continue r
        }
      }
    }
  }
}

///|
/// Get the value associated with a key.
/// O(log n).
#alias("_[_]")
pub fn[K : Compare, V] SortedMap::at(self : SortedMap[K, V], key : K) -> V {
  for x = self {
    match x {
      Empty => break panic()
      Tree(k, value~, l, r, ..) => {
        let c = key.compare(k)
        if c == 0 {
          break value
        } else if c < 0 {
          continue l
        } else {
          continue r
        }
      }
    }
  }
}

///|
/// Iterate over the key-value pairs in the map.
pub fn[K, V] SortedMap::each(
  self : SortedMap[K, V],
  f : (K, V) -> Unit,
) -> Unit {
  match self {
    Empty => ()
    Tree(k, value~, l, r, ..) => {
      l.each(f)
      f(k, value)
      r.each(f)
    }
  }
}

///|
/// Iterate over the key-value pairs with index.
pub fn[K, V] SortedMap::eachi(
  self : SortedMap[K, V],
  f : (Int, K, V) -> Unit,
) -> Unit {
  fn do_eachi(m : SortedMap[K, V], f, i) {
    match m {
      Empty => ()
      Tree(k, value~, l, r, ..) => {
        do_eachi(l, f, i)
        f(l.length() + i, k, value)
        do_eachi(r, f, l.length() + i + 1)
      }
    }
  }

  do_eachi(self, f, 0)
}

///|
/// Maps over the key-value pairs in the map.
#alias(map_with_key, deprecated)
pub fn[K, X, Y] SortedMap::map(
  self : SortedMap[K, X],
  f : (K, X) -> Y,
) -> SortedMap[K, Y] {
  match self {
    Empty => Empty
    Tree(k, value~, l, r, size~) =>
      Tree(k, value=f(k, value), size~, l.map(f), r.map(f))
  }
}

///|
/// Post-order fold.
/// O(n).
#alias(foldr_with_key)
pub fn[K, V, A] SortedMap::rev_fold(
  self : SortedMap[K, V],
  f : (A, K, V) -> A,
  init~ : A,
) -> A {
  fn go(m : SortedMap[K, V], acc) {
    match m {
      Empty => acc
      Tree(k, value~, l, r, ..) => go(l, f(go(r, acc), k, value))
    }
  }

  go(self, init)
}

///|
/// Pre-order fold.
/// O(n).
#alias(foldl_with_key, deprecated)
pub fn[K, V, A] SortedMap::fold(
  self : SortedMap[K, V],
  f : (A, K, V) -> A,
  init~ : A,
) -> A {
  fn go(m : SortedMap[K, V], acc) {
    match m {
      Empty => acc
      Tree(k, value~, l, r, ..) => go(r, f(go(l, acc), k, value))
    }
  }

  go(self, init)
}

///|
fn[K : Show, V : Show] SortedMap::debug_tree(self : SortedMap[K, V]) -> String {
  match self {
    Empty => "_"
    Tree(k, value~, l, r, ..) => {
      let l = l.debug_tree()
      let r = r.debug_tree()
      "(\{k},\{value},\{l},\{r})"
    }
  }
}

///|

///|
/// Build a map from an array of key-value pairs.
/// O(n) when the input is already monotonic by key, otherwise O(n*log n).
#as_free_fn(deprecated="Use @immut/sorted_map.SortedMap([...]) instead")
#alias(of, deprecated="Use @immut/sorted_map.SortedMap([...]) instead")
#as_free_fn(of, deprecated="Use @immut/sorted_map.SortedMap([...]) instead")
#deprecated("Use @immut/sorted_map.SortedMap([...]) instead")
pub fn[K : Compare, V] SortedMap::from_array(
  array : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  sorted_map_from_array(array)
}

///|
fn[K : Compare, V] sorted_map_from_array(
  array : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  let (order, has_duplicates) = sorted_map_array_order(array)
  if order == 1 {
    if has_duplicates {
      let compacted = sorted_map_compact_ordered_array(array, true)
      return sorted_map_from_ascending_array(compacted, 0, compacted.length())
    }
    return sorted_map_from_ascending_array(array, 0, array.length())
  } else if order == -1 {
    if has_duplicates {
      let compacted = sorted_map_compact_ordered_array(array, false)
      return sorted_map_from_ascending_array(compacted, 0, compacted.length())
    }
    return sorted_map_from_descending_array(array, 0, array.length())
  }
  if array.length() >= sorted_map_sort_build_threshold {
    sorted_map_from_unsorted_array(array)
  } else {
    sorted_map_from_array_by_add(array)
  }
}

///|
let sorted_map_sort_build_threshold = 64

///|
/// A key-value pair tagged with its original position, used to sort an unsorted
/// input by key while breaking ties on insertion order.
priv struct SortEntry[K, V] {
  key : K
  value : V
  index : Int
}

///|
impl[K : Compare, V] Eq for SortEntry[K, V] with fn equal(self, other) {
  self.key == other.key && self.index == other.index
}

///|
// Ordering by key, then by original position, so that a plain (unstable) `sort`
// still keeps duplicate keys in insertion order — the last one wins on compact.
impl[K : Compare, V] Compare for SortEntry[K, V] with fn compare(self, other) {
  let c = self.key.compare(other.key)
  if c == 0 {
    self.index.compare(other.index)
  } else {
    c
  }
}

///|
fn[K : Compare, V] sorted_map_from_unsorted_array(
  array : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  let entries : FixedArray[SortEntry[K, V]] = FixedArray::makei(
    array.length(),
    i => { key: array[i].0, value: array[i].1, index: i },
  )
  sorted_map_from_unsorted_entries(entries.mut_view())
}

///|
/// Sort a `SortEntry` buffer in place, drop duplicate keys, and build the tree
/// from its unique prefix. The caller owns the backing buffer, which is permuted
/// in place. Shared by the array and iterator entry points.
fn[K : Compare, V] sorted_map_from_unsorted_entries(
  entries : MutArrayView[SortEntry[K, V]],
) -> SortedMap[K, V] {
  entries.sort()
  let len = sorted_map_compact_entries_in_place(entries)
  sorted_map_from_sorted_entries(entries.view(), 0, len)
}

///|
fn[K : Compare, V] sorted_map_from_array_by_add(
  array : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  for item in array; mp = Empty {
    let (k, v) = item
    continue mp.add(k, v)
  } nobreak {
    mp
  }
}

///|
/// Build a map from an array of key-value pairs.
/// O(n) when the input is already monotonic by key, otherwise O(n*log n).
///
/// # Example
///
/// ```mbt check
/// test {
///   let m = @sorted_map.SortedMap([(3, "c"), (1, "a"), (2, "b")])
///   @test.assert_eq(m.get(1), Some("a"))
///   @test.assert_eq(m.get(3), Some("c"))
/// }
/// ```
pub fn[K : Compare, V] SortedMap::SortedMap(
  array : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  sorted_map_from_array(array)
}

///|
// Deduplicate a key-sorted `SortEntry` buffer in place, keeping the last value
// seen for each key (last writer wins, matching `add`). The unique entries are
// packed at the front and their count is returned; the tail is left untouched
// and must be ignored by the caller. Indices are monotonic (write <= start <=
// end < len), so the unchecked accessors stay in bounds.
fn[K : Compare, V] sorted_map_compact_entries_in_place(
  entries : MutArrayView[SortEntry[K, V]],
) -> Int {
  let len = entries.length()
  let mut write = 0
  for start = 0; start < len; {
    let end = for end = start; end + 1 < len &&
                 entries.unsafe_get(end).key.compare(
                   entries.unsafe_get(end + 1).key,
                 ) ==
                 0; {
      continue end + 1
    } nobreak {
      end
    }
    entries.unsafe_set(write, {
      key: entries.unsafe_get(start).key,
      value: entries.unsafe_get(end).value,
      index: entries.unsafe_get(start).index,
    })
    write += 1
    continue end + 1
  }
  write
}

///|
fn[K : Compare, V] sorted_map_array_order(
  array : ArrayView[(K, V)],
) -> (Int, Bool) {
  let len = array.length()
  guard len > 1 else { return (1, false) }
  let mut order = 0
  let mut has_duplicates = false
  for i in 1..<len {
    let cmp = array[i - 1].0.compare(array[i].0)
    if cmp == 0 {
      has_duplicates = true
    } else {
      let current = if cmp < 0 { 1 } else { -1 }
      if order == 0 {
        order = current
      } else if order != current {
        return (0, has_duplicates)
      }
    }
  }
  (if order == 0 { 1 } else { order }, has_duplicates)
}

///|
fn[K : Compare, V] sorted_map_compact_ordered_array(
  array : ArrayView[(K, V)],
  ascending : Bool,
) -> Array[(K, V)] {
  let result = []
  let len = array.length()
  if ascending {
    for start = 0; start < len; {
      let end = for end = start; end + 1 < len &&
                   array[end].0.compare(array[end + 1].0) == 0; {
        continue end + 1
      } nobreak {
        end
      }
      result.push((array[start].0, array[end].1))
      continue end + 1
    }
  } else {
    for end = len - 1; end >= 0; {
      let start = for start = end; start > 0 &&
                     array[start - 1].0.compare(array[start].0) == 0; {
        continue start - 1
      } nobreak {
        start
      }
      result.push((array[start].0, array[end].1))
      continue start - 1
    }
  }
  result
}

///|
/// Build a map from key-value pairs that are already strictly sorted by key.
///
/// The input must be in ascending key order and must not contain duplicate keys.
/// This function does not validate that precondition.
/// O(n).
///
/// # Example
/// ```mbt check
/// test {
///   let map = @sorted_map.from_sorted_array([(1, "a"), (2, "b")])
///   @test.assert_eq(map.to_array(), [(1, "a"), (2, "b")])
/// }
/// ```
#warnings("-unused_trait_bound")
#as_free_fn
pub fn[K : Compare, V] SortedMap::from_sorted_array(
  array : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  sorted_map_from_ascending_array(array, 0, array.length())
}

///|
/// Build a balanced tree from a slice sorted in ascending key order.
/// The ascending case of a monotonic array is exactly this construction.
fn[K, V] sorted_map_from_ascending_array(
  array : ArrayView[(K, V)],
  start : Int,
  end : Int,
) -> SortedMap[K, V] {
  if start >= end {
    Empty
  } else {
    let mid = (start + end) / 2
    let (key, value) = array[mid]
    let left = sorted_map_from_ascending_array(array, start, mid)
    let right = sorted_map_from_ascending_array(array, mid + 1, end)
    make_tree(key, value, left, right)
  }
}

///|
/// Build a balanced tree from a slice sorted in descending key order, without
/// materializing a reversed copy: the middle element is still the subtree root,
/// but the smaller keys sit at the higher indices, so the halves are swapped.
fn[K, V] sorted_map_from_descending_array(
  array : ArrayView[(K, V)],
  start : Int,
  end : Int,
) -> SortedMap[K, V] {
  if start >= end {
    Empty
  } else {
    let mid = (start + end) / 2
    let (key, value) = array[mid]
    let left = sorted_map_from_descending_array(array, mid + 1, end)
    let right = sorted_map_from_descending_array(array, start, mid)
    make_tree(key, value, left, right)
  }
}

///|
/// Build a balanced tree from the `[start, end)` slice of a key-sorted,
/// duplicate-free `SortEntry` buffer, reading keys and values off the entries
/// directly so no `(K, V)` copy is materialized.
fn[K, V] sorted_map_from_sorted_entries(
  entries : ArrayView[SortEntry[K, V]],
  start : Int,
  end : Int,
) -> SortedMap[K, V] {
  if start >= end {
    Empty
  } else {
    let mid = (start + end) / 2
    let entry = entries[mid]
    let left = sorted_map_from_sorted_entries(entries, start, mid)
    let right = sorted_map_from_sorted_entries(entries, mid + 1, end)
    make_tree(entry.key, entry.value, left, right)
  }
}

///|
/// Returns an iterator over key-value pairs in ascending key order.
#alias(iterator, deprecated)
pub fn[K, V] SortedMap::iter(self : SortedMap[K, V]) -> Iter[(K, V)] {
  let mut curr_node = self
  let parents = []
  Iter::new(
    fn() {
      for x = curr_node {
        match x {
          Tree(k, value~, Empty, r, ..) => {
            curr_node = r
            break Some((k, value))
          }
          Tree(k, value~, l, r, ..) => {
            parents.push((k, value, r))
            continue l
          }
          Empty if parents.pop() is Some((k, v, r)) => {
            curr_node = r
            break Some((k, v))
          }
          Empty => break None
        }
      }
    },
    size_hint=self.length(),
  )
}

///|
/// Returns a two-element iterator over key-value pairs in ascending key order.
#alias(iterator2, deprecated)
pub fn[K, V] SortedMap::iter2(self : SortedMap[K, V]) -> Iter2[K, V] {
  self.iter()
}

///|
/// Returns an iterator over all key-value pairs in the map where keys fall
/// within the inclusive range `[low, high]`.
///
/// The iterator yields key-value pairs in ascending key order. Keys equal to
/// `low` or `high` are included if present.
///
/// # Arguments
///
/// * `low` - The lower bound of the range (inclusive).
/// * `high` - The upper bound of the range (inclusive).
///
/// # Returns
///
/// An `Iter2[K, V]` that yields key-value pairs `(key, value)` where
/// `low <= key <= high`.
///
/// # Performance
///
/// Time complexity is O(log n + k) where n is the size of the map and k is the
/// number of elements in the range. The algorithm efficiently prunes subtrees
/// that fall entirely outside the range.
///
/// # Behavior
///
/// * If `low > high`, the iterator yields no elements.
/// * If the range contains no keys from the map, the iterator yields no elements.
/// * The iterator is single-use; create a new one for multiple traversals.
///
/// # Example
///
/// ```mbt check
/// test {
///   let map = @sorted_map.SortedMap([
///     (1, "a"),
///     (2, "b"),
///     (3, "c"),
///     (4, "d"),
///     (5, "e"),
///   ])
///   let result = []
///   for k, v in map.range(low=2, high=4) {
///     result.push((k, v))
///   }
///   @test.assert_eq(result, [(2, "b"), (3, "c"), (4, "d")])
/// }
/// ```
pub fn[K : Compare, V] SortedMap::range(
  self : SortedMap[K, V],
  low~ : K,
  high~ : K,
) -> Iter2[K, V] {
  let todo_list = []
  let mut next_node = self
  Iter2::new(fn() {
    for x = next_node {
      match x {
        Tree(k, value~, l, r, ..) => {
          let cmp_key_low = k.compare(low)
          let cmp_key_high = k.compare(high)
          if cmp_key_low < 0 {
            // k < low, skip left subtree and current node, visit right
            continue r
          } else if cmp_key_high > 0 {
            // k > high, skip right subtree and current node, visit left
            continue l
          } else if l is Empty {
            next_node = r
            break Some((k, value))
          } else {
            todo_list.push((k, value, r))
            continue l
          }
        }
        Empty if todo_list.pop() is Some((k, value, r)) => {
          next_node = r
          break Some((k, value))
        }
        Empty => break None
      }
    }
  })
}

///|
/// Creates a sorted map from an iterator of key-value pairs.
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Compare, V] SortedMap::from_iter(
  iter : Iter[(K, V)],
) -> SortedMap[K, V] {
  // Materialize into a `(K, V)` buffer and detect order there: monotonic input
  // (the common case) builds in O(n) without ever tagging elements with an
  // index, and only the genuinely-unsorted branch pays for the `SortEntry` sort.
  sorted_map_from_array(iter.to_array())
}

///|
/// Return all keys of the map in ascending order.
pub fn[K, V] SortedMap::keys_as_iter(self : SortedMap[K, V]) -> Iter[K] {
  self.iter().map(p => p.0)
}

///|
/// Return all elements of the map in the ascending order of their keys.
pub fn[K, V] SortedMap::values(self : SortedMap[K, V]) -> Iter[V] {
  self.iter().map(p => p.1)
}

///|
/// Return all keys of the map in descending order.
///
/// # Example
///
/// ```mbt check
/// test {
///   let map = @sorted_map.SortedMap([("a", 1), ("b", 2), ("c", 3)])
///   let keys = map.rev_keys().collect()
///   @test.assert_eq(keys, ["c", "b", "a"])
/// }
/// ```
pub fn[K, V] SortedMap::rev_keys(self : SortedMap[K, V]) -> Iter[K] {
  let mut curr_node = self
  let parents = []
  Iter::new(
    fn() {
      for x = curr_node {
        match x {
          Tree(k, l, Empty, ..) => {
            curr_node = l
            break Some(k)
          }
          Tree(k, l, r, ..) => {
            parents.push((k, l))
            continue r
          }
          Empty if parents.pop() is Some((k, l)) => {
            curr_node = l
            break Some(k)
          }
          Empty => break None
        }
      }
    },
    size_hint=self.length(),
  )
}

///|
/// Return all values of the map in descending order of their keys.
///
/// # Example
///
/// ```mbt nocheck
///   let map = @sorted_map.SortedMap([("a", 1), ("b", 2), ("c", 3)])
///   let values = map.rev_values().collect()
///   @test.assert_eq(values, [3, 2, 1])
/// ```
pub fn[K, V] SortedMap::rev_values(self : SortedMap[K, V]) -> Iter[V] {
  let mut curr_node = self
  let parents = []
  Iter::new(
    fn() {
      for x = curr_node {
        match x {
          Tree(_k, value~, l, Empty, ..) => {
            curr_node = l
            break Some(value)
          }
          Tree(_k, value~, l, r, ..) => {
            parents.push((value, l))
            continue r
          }
          Empty if parents.pop() is Some((v, l)) => {
            curr_node = l
            break Some(v)
          }
          Empty => break None
        }
      }
    },
    size_hint=self.length(),
  )
}

///|
/// Convert to `json`.
pub fn[K : Show, V : ToJson] SortedMap::to_json(self : SortedMap[K, V]) -> Json {
  ToJson::to_json(self)
}
