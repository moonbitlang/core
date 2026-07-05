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

// This package implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

// Construct an empty ImmutableSet.

///|
/// Creates an empty immutable sorted set.
#as_free_fn
pub fn[A] SortedSet::new() -> SortedSet[A] {
  Empty
}

///|
pub impl[A] Default for SortedSet[A] with fn default() {
  Empty
}

///|
/// Returns the one-value ImmutableSet containing only `value`.
#as_free_fn
pub fn[A] SortedSet::singleton(value : A) -> SortedSet[A] {
  Node(left=Empty, value~, right=Empty, size=1)
}

///|
/// Initialize a `SortedSet[A]` from an array.
/// O(n) when the input is already monotonic, otherwise O(n*log n).
#as_free_fn(deprecated="Use @immut/sorted_set.SortedSet([...]) instead")
#alias(of, deprecated="Use @immut/sorted_set.SortedSet([...]) instead")
#as_free_fn(of, deprecated="Use @immut/sorted_set.SortedSet([...]) instead")
#deprecated("Use @immut/sorted_set.SortedSet([...]) instead")
pub fn[A : Compare] SortedSet::from_array(array : ArrayView[A]) -> SortedSet[A] {
  sorted_set_from_array(array)
}

///|
fn[A : Compare] sorted_set_from_array(array : ArrayView[A]) -> SortedSet[A] {
  let (order, has_duplicates) = sorted_set_array_order(array)
  if order == 1 {
    if has_duplicates {
      let compacted = sorted_set_compact_ordered_array(array, true, false)
      return sorted_set_from_ascending_array(compacted, 0, compacted.length())
    }
    return sorted_set_from_ascending_array(array, 0, array.length())
  } else if order == -1 {
    if has_duplicates {
      let compacted = sorted_set_compact_ordered_array(array, false, false)
      return sorted_set_from_ascending_array(compacted, 0, compacted.length())
    }
    return sorted_set_from_descending_array(array, 0, array.length())
  }
  if array.length() >= sorted_set_sort_build_threshold {
    // `array` is borrowed, so copy it into a buffer we own before sorting.
    sorted_set_from_unsorted_buffer(array.to_owned().mut_view(), false)
  } else {
    sorted_set_from_array_by_add(array)
  }
}

///|
let sorted_set_sort_build_threshold = 64

///|
/// Sort an owned buffer in place and build a set from it, keeping the first or
/// last element of each equal run per `keep_first`. `stable_sort` preserves the
/// insertion order of equal elements, so the chosen representative matches
/// building the set by repeated `add`. The caller must own `buf` and not use it
/// afterwards, since the elements are permuted in place.
fn[A : Compare] sorted_set_from_unsorted_buffer(
  buf : MutArrayView[A],
  keep_first : Bool,
) -> SortedSet[A] {
  buf.stable_sort()
  let len = sorted_set_dedupe_in_place(buf, keep_first)
  sorted_set_from_ascending_array(buf.view(start=0, end=len), 0, len)
}

///|
// Drop duplicate runs from a sorted buffer in place, keeping the first or last
// element of each run per `keep_first`. The unique elements are packed at the
// front and their count is returned; the tail is left untouched. Indices are
// monotonic (write <= start <= end < len), so the unchecked accessors stay in
// bounds.
fn[A : Compare] sorted_set_dedupe_in_place(
  buf : MutArrayView[A],
  keep_first : Bool,
) -> Int {
  let len = buf.length()
  let mut write = 0
  for start = 0; start < len; {
    let end = for end = start; end + 1 < len &&
                 buf.unsafe_get(end).compare(buf.unsafe_get(end + 1)) == 0; {
      continue end + 1
    } nobreak {
      end
    }
    let survivor = if keep_first {
      buf.unsafe_get(start)
    } else {
      buf.unsafe_get(end)
    }
    buf.unsafe_set(write, survivor)
    write += 1
    continue end + 1
  }
  write
}

///|
fn[A : Compare] sorted_set_from_array_by_add(
  array : ArrayView[A],
) -> SortedSet[A] {
  for i = array.length() - 1, set = Empty; i >= 0; {
    continue i - 1, set.add(array[i])
  } nobreak {
    set
  }
}

///|
/// Initialize a `SortedSet` from an array.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(@sorted_set.SortedSet([3, 1, 2, 3]).to_array(), [1, 2, 3])
/// }
/// ```
pub fn[A : Compare] SortedSet::SortedSet(array : ArrayView[A]) -> SortedSet[A] {
  sorted_set_from_array(array)
}

///|
// `array` is the fresh, owned buffer collected from the iterator, so the
// unsorted branch can sort it in place instead of copying it again.
fn[A : Compare] sorted_set_from_iter_array(array : Array[A]) -> SortedSet[A] {
  let (order, has_duplicates) = sorted_set_array_order(array)
  if order == 1 {
    if has_duplicates {
      let compacted = sorted_set_compact_ordered_array(array, true, true)
      return sorted_set_from_ascending_array(compacted, 0, compacted.length())
    }
    return sorted_set_from_ascending_array(array, 0, array.length())
  } else if order == -1 {
    if has_duplicates {
      let compacted = sorted_set_compact_ordered_array(array, false, true)
      return sorted_set_from_ascending_array(compacted, 0, compacted.length())
    }
    return sorted_set_from_descending_array(array, 0, array.length())
  }
  if array.length() >= sorted_set_sort_build_threshold {
    sorted_set_from_unsorted_buffer(array.mut_view(), true)
  } else {
    sorted_set_from_iter_array_by_add(array)
  }
}

///|
fn[A : Compare] sorted_set_from_iter_array_by_add(
  array : ArrayView[A],
) -> SortedSet[A] {
  for item in array; set = Empty {
    continue set.add(item)
  } nobreak {
    set
  }
}

///|
fn[A : Compare] sorted_set_array_order(array : ArrayView[A]) -> (Int, Bool) {
  let len = array.length()
  guard len > 1 else { return (1, false) }
  let mut order = 0
  let mut has_duplicates = false
  for i in 1..<len {
    let cmp = array[i - 1].compare(array[i])
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
fn[A : Compare] sorted_set_compact_ordered_array(
  array : ArrayView[A],
  ascending : Bool,
  keep_first : Bool,
) -> Array[A] {
  let result = []
  let len = array.length()
  if ascending {
    for start = 0; start < len; {
      let end = for end = start; end + 1 < len &&
                   array[end].compare(array[end + 1]) == 0; {
        continue end + 1
      } nobreak {
        end
      }
      result.push(if keep_first { array[start] } else { array[end] })
      continue end + 1
    }
  } else {
    for end = len - 1; end >= 0; {
      let start = for start = end; start > 0 &&
                     array[start - 1].compare(array[start]) == 0; {
        continue start - 1
      } nobreak {
        start
      }
      result.push(if keep_first { array[start] } else { array[end] })
      continue start - 1
    }
  }
  result
}

///|
/// Build a set from values that are already strictly sorted.
///
/// The input must be in ascending order and must not contain duplicates.
/// This function does not validate that precondition.
/// O(n).
///
/// # Example
/// ```mbt check
/// test {
///   let set = @sorted_set.from_sorted_array([1, 2, 3])
///   @test.assert_eq(set.to_array(), [1, 2, 3])
/// }
/// ```
#warnings("-unused_trait_bound")
#as_free_fn
pub fn[A : Compare] SortedSet::from_sorted_array(
  array : ArrayView[A],
) -> SortedSet[A] {
  sorted_set_from_ascending_array(array, 0, array.length())
}

///|
/// Build a balanced tree from a slice sorted in ascending order.
/// The ascending case of a monotonic array is exactly this construction.
fn[A] sorted_set_from_ascending_array(
  array : ArrayView[A],
  start : Int,
  end : Int,
) -> SortedSet[A] {
  if start >= end {
    Empty
  } else {
    let mid = (start + end) / 2
    let value = array[mid]
    let left = sorted_set_from_ascending_array(array, start, mid)
    let right = sorted_set_from_ascending_array(array, mid + 1, end)
    create(left, value, right)
  }
}

///|
/// Build a balanced tree from a slice sorted in descending order, without
/// materializing a reversed copy: the middle element is still the subtree root,
/// but the smaller values sit at the higher indices, so the halves are swapped.
fn[A] sorted_set_from_descending_array(
  array : ArrayView[A],
  start : Int,
  end : Int,
) -> SortedSet[A] {
  if start >= end {
    Empty
  } else {
    let mid = (start + end) / 2
    let value = array[mid]
    let left = sorted_set_from_descending_array(array, mid + 1, end)
    let right = sorted_set_from_descending_array(array, start, mid)
    create(left, value, right)
  }
}

///|
/// Returns an array of all elements in ascending order.
pub fn[A] SortedSet::to_array(self : SortedSet[A]) -> Array[A] {
  let arr = []
  fn aux(set : SortedSet[A]) {
    match set {
      Empty => ()
      Node(left~, value~, right~, ..) => {
        aux(left)
        arr.push(value)
        aux(right)
        //TODO: rewrite [...aux(left),value,...aux(right)]
      }
    }
  }

  aux(self)
  arr
}

///|
/// Remove the smallest value.
/// This function will panic if the set is empty.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([3, 4, 5]).remove_min(),
///     SortedSet([4, 5]),
///   )
/// }
/// ```
pub fn[A] SortedSet::remove_min(self : SortedSet[A]) -> SortedSet[A] {
  match self {
    Empty => abort("remove_min: empty ImmutableSet")
    Node(left~, right~, value~, ..) =>
      if left is Empty {
        right
      } else {
        balance(left.remove_min(), value, right)
      }
  }
}

///|
/// Insert a value into the ImmutableSet.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([6, 3, 8, 1]).add(5),
///     SortedSet([1, 3, 5, 6, 8]),
///   )
/// }
/// ```
pub fn[A : Compare] SortedSet::add(
  self : SortedSet[A],
  value : A,
) -> SortedSet[A] {
  match self {
    Empty => Node(left=Empty, value~, right=Empty, size=1)
    Node(left~, right~, value=node_value, ..) => {
      let compare_result = value.compare(node_value)
      if compare_result == 0 {
        self
      } else if compare_result < 0 {
        let ll = left.add(value)
        if physical_equal(left, ll) {
          self
        } else {
          balance(ll, node_value, right)
        }
      } else {
        let rr = right.add(value)
        if physical_equal(right, rr) {
          self
        } else {
          balance(left, node_value, rr)
        }
      }
    }
  }
}

///|
/// Remove n value from the ImmutableSet.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(@sorted_set.SortedSet([3, 8, 1]).remove(8), SortedSet([1, 3]))
/// }
/// ```
pub fn[A : Compare] SortedSet::remove(
  self : SortedSet[A],
  value : A,
) -> SortedSet[A] {
  match self {
    Empty => Empty
    Node(left~, right~, value=node_value, ..) => {
      let compare_result = value.compare(node_value)
      if compare_result == 0 {
        left.merge(right)
      } else if compare_result < 0 {
        let new_left = left.remove(value)
        if physical_equal(left, new_left) {
          self
        } else {
          balance(new_left, node_value, right)
        }
      } else {
        let new_right = right.remove(value)
        if physical_equal(right, new_right) {
          self
        } else {
          balance(left, node_value, new_right)
        }
      }
    }
  }
}

///|
/// Returns the smallest value in the sorted_set.
/// This function will panic if the set is empty.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(@sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).min(), 1)
/// }
/// ```
pub fn[A] SortedSet::min(self : SortedSet[A]) -> A {
  for cur = self {
    match cur {
      Empty => abort("min: there are no values in sorted_set.")
      Node(left~, value~, ..) =>
        if left is Empty {
          break value
        } else {
          continue left
        }
    }
  }
}

///|
/// Returns the smallest value in the sorted_set.
/// But returns None when the value does not exist.
pub fn[A] SortedSet::min_option(self : SortedSet[A]) -> A? {
  for cur = self {
    match cur {
      Empty => break None
      Node(left~, value~, ..) =>
        if left is Empty {
          break Some(value)
        } else {
          continue left
        }
    }
  }
}

///|
/// Returns the largest value in the sorted_set.
/// This function will panic if the set is empty.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(@sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).max(), 9)
/// }
/// ```
pub fn[A] SortedSet::max(self : SortedSet[A]) -> A {
  for cur = self {
    match cur {
      Empty => abort("max: there are no values in ImmutableSet.")
      Node(right~, value~, ..) =>
        if right is Empty {
          break value
        } else {
          continue right
        }
    }
  }
}

///|
/// Returns the largest value in the ImmutableSet.
/// But returns None when the value does not exist.
pub fn[A] SortedSet::max_option(self : SortedSet[A]) -> A? {
  for cur = self {
    match cur {
      Empty => break None
      Node(right~, value~, ..) =>
        if right is Empty {
          break Some(value)
        } else {
          continue right
        }
    }
  }
}

///|
/// Returns a triple (left, present, right), where left < divide < right.
/// present == false if self contains no value equal to divide,
/// present == true  if self contains a value equal to divide.
///
/// # Example
///
/// ```mbt check
/// test {
///   let (left, present, right) = @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(
///     5,
///   )
///   inspect(present, content="true")
///   @test.assert_eq(left, SortedSet([1, 2, 3, 4]))
///   @test.assert_eq(right, SortedSet([6, 7, 8, 9]))
/// }
/// ```
pub fn[A : Compare] SortedSet::split(
  self : SortedSet[A],
  divide : A,
) -> (SortedSet[A], Bool, SortedSet[A]) {
  match self {
    Empty => (Empty, false, Empty)
    Node(left~, right~, value~, ..) => {
      let compare_result = divide.compare(value)
      if compare_result == 0 {
        (left, true, right)
      } else if compare_result < 0 {
        let (left_left, present, right_left) = left.split(divide)
        (left_left, present, join(right_left, value, right))
      } else {
        let (left_right, present, right_right) = right.split(divide)
        (join(left, value, left_right), present, right_right)
      }
    }
  }
}

///|
/// Returns true if sorted_set is empty
pub fn[A] SortedSet::is_empty(self : SortedSet[A]) -> Bool {
  self is Empty
}

///|
/// Returns `true` if the set contains the given value.
pub fn[A : Compare] SortedSet::contains(self : SortedSet[A], value : A) -> Bool {
  match self {
    Empty => false
    Node(left~, right~, value=node_value, ..) => {
      let compare_result = value.compare(node_value)
      compare_result == 0 ||
      (if compare_result < 0 { left } else { right }).contains(value)
    }
  }
}

///|
/// Returns an iterator over all values in the set that fall within the
/// inclusive range `[low, high]`.
///
/// The iterator yields values in ascending order. Values equal to `low` or
/// `high` are included if present.
///
/// # Arguments
///
/// * `low` - The lower bound of the range (inclusive).
/// * `high` - The upper bound of the range (inclusive).
///
/// # Returns
///
/// An `Iter[A]` that yields values where `low <= value <= high`.
///
/// # Performance
///
/// Time complexity is O(log n + k) where n is the size of the set and k is the
/// number of elements in the range. The algorithm efficiently prunes subtrees
/// that fall entirely outside the range.
///
/// # Behavior
///
/// * If `low > high`, the iterator yields no elements.
/// * If the range contains no values from the set, the iterator yields no elements.
/// * The iterator is single-use; create a new one for multiple traversals.
///
/// # Example
///
/// ```mbt check
/// test {
///   let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
///   let result = []
///   for v in set.range(low=2, high=4) {
///     result.push(v)
///   }
///   @test.assert_eq(result, [2, 3, 4])
/// }
/// ```
pub fn[A : Compare] SortedSet::range(
  self : SortedSet[A],
  low~ : A,
  high~ : A,
) -> Iter[A] {
  let todo_list = []
  let mut next_node = self
  Iter::new(fn() {
    for x = next_node {
      match x {
        Node(left~, right~, value~, ..) => {
          let cmp_value_low = value.compare(low)
          let cmp_value_high = value.compare(high)
          if cmp_value_low < 0 {
            // value < low, skip left subtree and current node, visit right
            continue right
          } else if cmp_value_high > 0 {
            // value > high, skip right subtree and current node, visit left
            continue left
          } else if left is Empty {
            next_node = right
            break Some(value)
          } else {
            todo_list.push((value, right))
            continue left
          }
        }
        Empty if todo_list.pop() is Some((value, right)) => {
          next_node = right
          break Some(value)
        }
        Empty => break None
      }
    }
  })
}

///|
/// Returns the union of self and other.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([3, 4, 5]).union(SortedSet([4, 5, 6])),
///     SortedSet([3, 4, 5, 6]),
///   )
/// }
/// ```
pub fn[A : Compare] SortedSet::union(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    (
      Node(left=l1, value=v1, right=r1, size=s1),
      Node(left=l2, value=v2, right=r2, size=s2),
    ) =>
      if s1 >= s2 {
        if s2 == 1 {
          self.add(v2)
        } else {
          let (l2, _, r2) = other.split(v1)
          join(l1.union(l2), v1, r1.union(r2))
        }
      } else if s1 == 1 {
        other.add(v1)
      } else {
        let (l1, _, r1) = self.split(v2)
        join(l1.union(l2), v2, r1.union(r2))
      }
  }
}

///|
/// a convenient alias of `union`
/// # Example
/// 
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([3, 4, 5]) + SortedSet([4, 5, 6]),
///     SortedSet([3, 4, 5, 6]),
///   )
/// }
/// ```
pub impl[A : Compare] Add for SortedSet[A] with fn add(self, other) {
  return self.union(other)
}

///|
/// Returns the intersection of self with other.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([3, 4, 5]).intersection(SortedSet([4, 5, 6])),
///     SortedSet([4, 5]),
///   )
/// }
/// ```
#alias(inter, deprecated)
pub fn[A : Compare] SortedSet::intersection(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  match (self, other) {
    (Empty, _) | (_, Empty) => Empty
    (Node(left=l1, value=v1, right=r1, ..), _) =>
      match other.split(v1) {
        (l2, false, r2) => l1.intersection(l2).concat(r1.intersection(r2))
        (l2, true, r2) => join(l1.intersection(l2), v1, r1.intersection(r2))
      }
  }
}

///|
/// Returns the difference between self and other.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([1, 2, 3]).difference(SortedSet([4, 5, 1])),
///     SortedSet([2, 3]),
///   )
/// }
/// ```
#alias(diff, deprecated)
pub fn[A : Compare] SortedSet::difference(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  match (self, other) {
    (Empty, _) => Empty
    (_, Empty) => self
    (Node(left=l1, value=v1, right=r1, ..), _) =>
      match other.split(v1) {
        (l2, false, r2) => join(l1.difference(l2), v1, r1.difference(r2))
        (l2, true, r2) => l1.difference(l2).concat(r1.difference(r2))
      }
  }
}

///|
/// Difference of two sorted sets.
pub impl[A : Compare] Sub for SortedSet[A] with fn sub(self, other) {
  self.difference(other)
}

///|
/// Returns a new set containing elements that are in either `self` or `other`,
/// but not in both sets.
///
/// Parameters:
///
/// * `self` : The first sorted set.
/// * `other` : The second sorted set.
///
/// Returns a new sorted set containing elements that appear in exactly one of
/// the input sets.
///
/// Example:
///
/// ```mbt check
/// test {
///   let set1 = @sorted_set.SortedSet([1, 2, 3, 4])
///   let set2 = @sorted_set.SortedSet([3, 4, 5, 6])
///   @debug.debug_inspect(
///     set1.symmetric_difference(set2),
///     content=(
///       #|<SortedSet: [1, 2, 5, 6]>
///     ),
///   )
/// }
/// ```
pub fn[A : Compare] SortedSet::symmetric_difference(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    (Node(left=l1, value=v1, right=r1, ..), _) =>
      match other.split(v1) {
        (l2, false, r2) =>
          join(l1.symmetric_difference(l2), v1, r1.symmetric_difference(r2))
        (l2, true, r2) =>
          l1.symmetric_difference(l2).concat(r1.symmetric_difference(r2))
      }
  }
}

///|
/// Returns true if self is a subset of other.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([1, 2, 3]).subset(
///       SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]),
///     ),
///     true,
///   )
/// }
/// ```
pub fn[A : Compare] SortedSet::subset(
  self : SortedSet[A],
  other : SortedSet[A],
) -> Bool {
  match (self, other) {
    (Empty, _) => true
    (_, Empty) => false
    (
      Node(left=l1, value=v1, right=r1, ..),
      Node(left=l2, value=v2, right=r2, ..),
    ) => {
      let compare_result = v1.compare(v2)
      if compare_result == 0 {
        l1.subset(l2) && r1.subset(r2)
      } else if compare_result < 0 {
        Node(left=l1, value=v1, right=Empty, size=1).subset(l2) &&
        r1.subset(other)
      } else {
        Node(left=Empty, value=v1, right=r1, size=1).subset(r2) &&
        l1.subset(other)
      }
    }
  }
}

///|
/// Returns true if the two sets do not intersect.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([1, 2, 3]).disjoint(SortedSet([4, 5, 6])),
///     true,
///   )
/// }
/// ```
pub fn[A : Compare] SortedSet::disjoint(
  self : SortedSet[A],
  other : SortedSet[A],
) -> Bool {
  match (self, other) {
    (Empty, _) | (_, Empty) => true
    (Node(left=l1, value=v1, right=r1, ..), _) =>
      if physical_equal(self, other) {
        false
      } else {
        match other.split_bis(v1) {
          NotFound(l2, r2) => l1.disjoint(l2) && r1.disjoint(r2())
          Found => false
        }
      }
  }
}

///|
/// Iterates over the ImmutableSet.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = []
///   @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(x => arr.push(x))
///   @test.assert_eq(arr, [1, 2, 3, 4, 5, 6, 7, 8, 9])
/// }
/// ```
pub fn[A] SortedSet::each(
  self : SortedSet[A],
  f : (A) -> Unit raise?,
) -> Unit raise? {
  match self {
    Empty => ()
    Node(left~, value~, right~, ..) => {
      left.each(f)
      f(value)
      right.each(f)
    }
  }
}

///|
/// Fold the ImmutableSet.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([1, 2, 3, 4, 5]).fold(init=0, (acc, x) => acc + x),
///     15,
///   )
/// }
/// ```
pub fn[A, B] SortedSet::fold(
  self : SortedSet[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  match self {
    Empty => init
    Node(left~, value~, right~, ..) =>
      right.fold(init=f(left.fold(init~, f), value), f)
  }
}

///|
/// Maps the ImmutableSet.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([1, 2, 3]).map(x => x * 2),
///     SortedSet([2, 4, 6]),
///   )
/// }
/// ```
pub fn[A, B : Compare] SortedSet::map(
  self : SortedSet[A],
  f : (A) -> B raise?,
) -> SortedSet[B] raise? {
  match self {
    Empty => Empty
    Node(left~, value~, right~, ..) =>
      try_join(left.map(f), f(value), right.map(f))
  }
}

///|
/// Test if all values of the ImmutableSet satisfy the predicate.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(@sorted_set.SortedSet([2, 4, 6]).all(v => v % 2 == 0), true)
/// }
/// ```
pub fn[A] SortedSet::all(
  self : SortedSet[A],
  f : (A) -> Bool raise?,
) -> Bool raise? {
  match self {
    Empty => true
    Node(left~, value~, right~, ..) => f(value) && left.all(f) && right.all(f)
  }
}

///|
/// Checks if at least one element of the set satisfies the predicate.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(@sorted_set.SortedSet([1, 4, 3]).any(v => v % 2 == 0), true)
/// }
/// ```
pub fn[A] SortedSet::any(
  self : SortedSet[A],
  f : (A) -> Bool raise?,
) -> Bool raise? {
  match self {
    Empty => false
    Node(left~, value~, right~, ..) => f(value) || left.any(f) || right.any(f)
  }
}

///|
/// Filter the ImmutableSet.
///
/// # Example
///
/// ```mbt check
/// test {
///   @test.assert_eq(
///     @sorted_set.SortedSet([1, 2, 3, 4, 5, 6]).filter(v => v % 2 == 0),
///     SortedSet([2, 4, 6]),
///   )
/// }
/// ```
pub fn[A] SortedSet::filter(
  self : SortedSet[A],
  f : (A) -> Bool raise?,
) -> SortedSet[A] raise? {
  match self {
    Empty => Empty
    Node(left~, value~, right~, ..) => {
      let l = left.filter(f)
      let v = f(value)
      let r = right.filter(f)
      if v {
        if physical_equal(l, left) && physical_equal(r, right) {
          self
        } else {
          join(l, value, r)
        }
      } else {
        l.concat(r)
      }
    }
  }
}

///|
#deprecated("Use @debug.Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show] Show for SortedSet[A]

///|
pub impl[A : Show] Show for SortedSet[A] with fn output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/sorted_set.from_array([",
    suffix="])",
  )
}

///|
pub impl[A : ToJson] ToJson for SortedSet[A] with fn to_json(self) {
  [
    for a in self => a
  ]
}

///|
/// Convert to `json`.
pub fn[A : ToJson] SortedSet::to_json(self : SortedSet[A]) -> Json {
  ToJson::to_json(self)
}

///|
pub impl[A : @json.FromJson + Compare] @json.FromJson for SortedSet[A] with fn from_json(
  json,
  path,
) {
  guard json is Array(arr) else {
    raise JsonDecodeError((path, "@immut/sorted_set.from_json: expected array"))
  }
  for i, x in arr; set = (new() : SortedSet[A]) {
    continue set.add(A::from_json(x, path.add_index(i)))
  } nobreak {
    set
  }
}

///|
/// Create from `json`.
#as_free_fn
pub fn[A : @json.FromJson + Compare] SortedSet::from_json(
  json : Json,
) -> SortedSet[A] raise @json.JsonDecodeError {
  @json.from_json(json)
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for SortedSet[
  X,
] with fn arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> SortedSet
}

// The following are the helper functions or types used by the internal implementation of ImmutableSet

///|
/// The ratio between the sizes of the left and right subtrees.
const BALANCE_RATIO = 5

///|
priv enum SplitBis[A] {
  Found
  NotFound(SortedSet[A], () -> SortedSet[A])
}

///|
impl[T] Show for SplitBis[T] with fn output(self, logger) {
  match self {
    Found => logger.write_string("Found")
    NotFound(_) => logger.write_string("NotFound")
  }
}

///|
/// Same as split, but compute the left and right only if the pivot value is not in the ImmutableSet.
/// The right is computed on demand.
fn[A : Compare] SortedSet::split_bis(
  self : SortedSet[A],
  value : A,
) -> SplitBis[A] {
  match self {
    Empty => NotFound(Empty, () => Empty)
    Node(left~, value=node_value, right~, ..) => {
      let compare_result = value.compare(node_value)
      if compare_result == 0 {
        Found
      } else if compare_result < 0 {
        match left.split_bis(value) {
          Found => Found
          NotFound(ll, rl) => NotFound(ll, () => join(rl(), node_value, right))
        }
      } else {
        match right.split_bis(value) {
          Found => Found
          NotFound(lr, rr) => NotFound(join(left, node_value, lr), rr)
        }
      }
    }
  }
}

///|
/// Get the height of set.
#alias(size, deprecated)
#inline
pub fn[A] SortedSet::length(self : SortedSet[A]) -> Int {
  match self {
    Empty => 0
    Node(size~, ..) => size
  }
}

///|
/// Creates a new node.
#inline
fn[A] create(
  left : SortedSet[A],
  value : A,
  right : SortedSet[A],
) -> SortedSet[A] {
  // length() is #inline, so the size match collapses into create, which is
  // itself #inline into union / intersection / balance.
  Node(left~, right~, value~, size=left.length() + right.length() + 1)
}

///|
/// Same as create, but performs one step of rebalancing if necessary.
fn[A] balance(
  left : SortedSet[A],
  value : A,
  right : SortedSet[A],
) -> SortedSet[A] {
  let left_size = left.length()
  let right_size = right.length()
  if left_size + right_size < 2 {
    create(left, value, right)
  } else if left_size > right_size * BALANCE_RATIO {
    match left {
      Empty => abort("balance: left is empty.")
      Node(left=ll, value=lv, right=lr, ..) =>
        if ll.length() >= lr.length() {
          create(ll, lv, create(lr, value, right))
        } else {
          match lr {
            Empty => abort("balance: right left.right is empty.")
            Node(left=lrl, value=lrv, right=lrr, ..) =>
              create(create(ll, lv, lrl), lrv, create(lrr, value, right))
          }
        }
    }
  } else if right_size > left_size * BALANCE_RATIO {
    match right {
      Empty => abort("balance: right is empty")
      Node(left=rl, value=rv, right=rr, ..) =>
        if rr.length() >= rl.length() {
          create(create(left, value, rl), rv, rr)
        } else {
          match rl {
            Empty => abort("balance: right.left is empty")
            Node(left=rll, value=rlv, right=rlr, ..) =>
              create(create(left, value, rll), rlv, create(rlr, rv, rr))
          }
        }
    }
  } else {
    create(left, value, right)
  }
}

///|
fn[A] SortedSet::add_min_value(self : SortedSet[A], value : A) -> SortedSet[A] {
  match self {
    Empty => singleton(value)
    Node(left~, value=node_value, right~, ..) =>
      balance(left.add_min_value(value), node_value, right)
  }
}

///|
fn[A] SortedSet::add_max_value(self : SortedSet[A], value : A) -> SortedSet[A] {
  match self {
    Empty => singleton(value)
    Node(left~, value=node_value, right~, ..) =>
      balance(left, node_value, right.add_max_value(value))
  }
}

///|
/// Same as create and balance, but no assumptions are made on the relative heights of left and right.
fn[A] join(
  left : SortedSet[A],
  value : A,
  right : SortedSet[A],
) -> SortedSet[A] {
  match (left, right) {
    (Empty, _) => right.add_min_value(value)
    (_, Empty) => left.add_max_value(value)
    (
      Node(left=ll, value=lv, right=lr, size=ls),
      Node(left=rl, value=rv, right=rr, size=rs),
    ) =>
      if ls > rs * BALANCE_RATIO {
        balance(ll, lv, join(lr, value, right))
      } else if rs > ls * BALANCE_RATIO {
        balance(join(left, value, rl), rv, rr)
      } else {
        create(left, value, right)
      }
  }
}

///|
fn[A : Compare] try_join(
  left : SortedSet[A],
  value : A,
  right : SortedSet[A],
) -> SortedSet[A] {
  if (left == Empty || left.max().compare(value) < 0) &&
    (right == Empty || value.compare(right.min()) < 0) {
    join(left, value, right)
  } else {
    left.union(right.add(value))
  }
}

///|
/// Merge two ImmutableSet[T] into one.
/// All values of left must precede the values of r.
fn[A] SortedSet::merge(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    _ => balance(self, other.min(), other.remove_min())
  }
}

///|
/// Same as merge, but no assumption on the heights of self and other.
fn[A] SortedSet::concat(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    _ => join(self, other.min(), other.remove_min())
  }
}

///|
pub impl[A : Hash] Hash for SortedSet[A] with fn hash_combine(self, hasher) {
  for t in self {
    t.hash_combine(hasher)
  }
}

///|
test "split_bis" {
  inspect(SortedSet([1, 2, 3]).split_bis(1), content="Found")
  inspect(SortedSet([1, 2, 3]).split_bis(3), content="Found")
  inspect(SortedSet([1, 2, 3]).split_bis(0), content="NotFound")
  inspect(SortedSet([1, 2, 3]).split_bis(4), content="NotFound")
}

///|
test "balance with left height greater" {
  let left = SortedSet([1, 2, 3])
  let value = 4
  let right = SortedSet([5])
  let balanced_set = balance(left, value, right)
  @debug.debug_inspect(
    balanced_set,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5]>
    ),
  )
}

///|
test "balance with right height greater" {
  let left = SortedSet([1])
  let value = 2
  let right = SortedSet([3, 4, 5])
  let balanced_set = balance(left, value, right)
  @debug.debug_inspect(
    balanced_set,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5]>
    ),
  )
}

///|
test "join with different heights" {
  let left = SortedSet([1, 2, 3])
  let value = 4
  let right = SortedSet([5, 6, 7])
  let joined_set = join(left, value, right)
  @debug.debug_inspect(
    joined_set,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7]>
    ),
  )
}

///|
test "hash" {
  @test.assert_eq(
    Hash::hash(SortedSet([1, 2, 3, 4])),
    Hash::hash(SortedSet([3, 2]).add(1).add(4)),
  )
  @test.assert_not_eq(
    Hash::hash(SortedSet([1, 2, 3])),
    Hash::hash(SortedSet([1, 2, 4])),
  )
}
