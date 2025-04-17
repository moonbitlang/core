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

// This module implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

///|
// Construct a empty ImmutableSet.
pub fn new[A]() -> T[A] {
  Empty
}

///|
pub impl[A] Default for T[A] with default() {
  Empty
}

///|
/// Returns the one-value ImmutableSet containing only `value`.
pub fn singleton[A : Compare](value : A) -> T[A] {
  Node(left=Empty, value~, right=Empty, size=1)
}

///|
/// Initialize an ImmutableSet[T] from a Array[T]
pub fn from_array[A : Compare](array : Array[A]) -> T[A] {
  for i = array.length() - 1, set = Empty; i >= 0; {
    continue i - 1, set.add(array[i])
  } else {
    set
  }
}

///|
/// Convert ImmutableSet[T] to Array[T], the result must be ordered.
pub fn to_array[A : Compare](self : T[A]) -> Array[A] {
  let arr = []
  fn aux(set : T[A]) {
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
/// Remove the smallest value,
///
/// # Example
///
/// ```
/// assert_eq!(@sorted_set.of([3, 4, 5]).remove_min(), @sorted_set.of([4, 5]))
/// ```
/// @alert unsafe "Panic if the ImmutableSet is empty."
pub fn remove_min[A : Compare](self : T[A]) -> T[A] {
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
/// ```
/// assert_eq!(@sorted_set.of([6, 3, 8, 1]).add(5), @sorted_set.of([1, 3, 5, 6, 8]))
/// ```
pub fn add[A : Compare](self : T[A], value : A) -> T[A] {
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
/// ```
/// assert_eq!(@sorted_set.of([3, 8, 1]).remove(8), @sorted_set.of([1, 3]))
/// ```
pub fn remove[A : Compare](self : T[A], value : A) -> T[A] {
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
///
/// # Example
///
/// ```
/// assert_eq!(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).min(), 1)
/// ```
/// @alert unsafe "Panic if the sorted_set is empty."
pub fn min[A : Compare](self : T[A]) -> A {
  match self {
    Empty => abort("min: there are no values in sorted_set.")
    Node(left~, value~, ..) => if left is Empty { value } else { left.min() }
  }
}

///|
/// Returns the smallest value in the sorted_set.
/// But returns None when the value does not exist.
pub fn min_option[A : Compare](self : T[A]) -> A? {
  match self {
    Empty => None
    Node(left~, value~, ..) =>
      if left is Empty {
        Some(value)
      } else {
        left.min_option()
      }
  }
}

///|
/// Returns the largest value in the sorted_set.
///
/// # Example
///
/// ```
/// assert_eq!(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).max(), 9)
/// ```
/// @alert unsafe "Panic if the sorted_set is empty."
pub fn max[A : Compare](self : T[A]) -> A {
  match self {
    Empty => abort("max: there are no values in ImmutableSet.")
    Node(right~, value~, ..) => if right is Empty { value } else { right.max() }
  }
}

///|
/// Returns the largest value in the ImmutableSet.
/// But returns None when the value does not exist.
pub fn max_option[A : Compare](self : T[A]) -> A? {
  match self {
    Empty => None
    Node(right~, value~, ..) =>
      if right is Empty {
        Some(value)
      } else {
        right.max_option()
      }
  }
}

///|
/// Returns a triple (left, present, right), where left < divide < right.
/// present == false if self contains no value equal to divide,
/// present == true  if self contains an value equal to divide.
///
/// # Example
///
/// ```
/// let (left, present, right) = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(5)
/// assert_eq!(present, true)
/// assert_eq!(left, @sorted_set.of([1, 2, 3, 4]))
/// assert_eq!(right, @sorted_set.of([6, 7, 8, 9]))
/// ```
pub fn split[A : Compare](self : T[A], divide : A) -> (T[A], Bool, T[A]) {
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
pub fn is_empty[A : Compare](self : T[A]) -> Bool {
  self is Empty
}

///|
/// Return true if value contain in sorted_set
pub fn contains[A : Compare](self : T[A], value : A) -> Bool {
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
/// Returns the union of self and other.
///
/// # Example
///
/// ```
/// assert_eq!(@sorted_set.of([3, 4, 5]).union(@sorted_set.of([4, 5, 6])), @sorted_set.of([3, 4, 5, 6]))
/// ```
pub fn union[A : Compare](self : T[A], other : T[A]) -> T[A] {
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
/// ```
/// assert_eq!(@sorted_set.of([3, 4, 5]) + (@sorted_set.of([4, 5, 6])), @sorted_set.of([3, 4, 5, 6]))
/// ```
pub impl[A : Compare] Add for T[A] with op_add(self, other) {
  return self.union(other)
}

///|
#deprecated("Use `intersection` instead")
#coverage.skip
pub fn inter[A : Compare](self : T[A], other : T[A]) -> T[A] {
  self.intersection(other)
}

///|
/// Returns the intersection of self with other.
///
/// # Example
///
/// ```
/// assert_eq!(@sorted_set.of([3, 4, 5]).intersection(@sorted_set.of([4, 5, 6])), @sorted_set.of([4, 5]))
/// ```
pub fn intersection[A : Compare](self : T[A], other : T[A]) -> T[A] {
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
/// ```
/// assert_eq!(@sorted_set.of([1, 2, 3]).difference(@sorted_set.of([4, 5, 1])), @sorted_set.of([2, 3]))
/// ```
///
#deprecated("Use `difference` instead")
#coverage.skip
pub fn diff[A : Compare](self : T[A], other : T[A]) -> T[A] {
  self.difference(other)
}

///|
/// Returns the difference between self and other.
///
/// # Example
///
/// ```
/// assert_eq!(@sorted_set.of([1, 2, 3]).difference(@sorted_set.of([4, 5, 1])), @sorted_set.of([2, 3]))
/// ```
pub fn difference[A : Compare](self : T[A], other : T[A]) -> T[A] {
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
/// ```moonbit
/// test "symmetric_difference" {
///   let set1 = @sorted_set.of([1, 2, 3, 4])
///   let set2 = @sorted_set.of([3, 4, 5, 6])
///   inspect!(
///     set1.symmetric_difference(set2),
///     content="@immut/sorted_set.of([1, 2, 5, 6])",
///   )
/// }
/// ```
pub fn symmetric_difference[A : Compare](self : T[A], other : T[A]) -> T[A] {
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
/// ```
/// assert_eq!(@sorted_set.of([1, 2, 3]).subset(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1])), true)
/// ```
pub fn subset[A : Compare](self : T[A], other : T[A]) -> Bool {
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
        r1.subset(self)
      } else {
        Node(left=Empty, value=v1, right=r1, size=1).subset(r2) &&
        l1.subset(self)
      }
    }
  }
}

///|
/// Returns true if the two sets do not intersect.
///
/// # Example
///
/// ```
/// assert_eq!(@sorted_set.of([1, 2, 3]).disjoint(@sorted_set.of([4, 5, 6])), true)
/// ```
pub fn disjoint[A : Compare](self : T[A], other : T[A]) -> Bool {
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
/// ```
/// let arr = []
/// @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(fn(x) { arr.push(x) })
/// assert_eq!(arr, [1, 2, 3, 4, 5, 6, 7, 8, 9])
/// ```
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
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
/// ```
/// assert_eq!(@sorted_set.of([1, 2, 3, 4, 5]).fold(init=0, fn(acc, x) { acc + x }), 15)
/// ```
pub fn fold[A : Compare, B](self : T[A], init~ : B, f : (B, A) -> B) -> B {
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
/// ```
/// assert_eq!(@sorted_set.of([1, 2, 3]).map(fn(x){ x * 2}), @sorted_set.of([2, 4, 6]))
/// ```
pub fn map[A : Compare, B : Compare](self : T[A], f : (A) -> B) -> T[B] {
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
/// ```
/// assert_eq!(@sorted_set.of([2, 4, 6]).all(fn(v) { v % 2 == 0}), true)
/// ```
pub fn all[A : Compare](self : T[A], f : (A) -> Bool) -> Bool {
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
/// ```
/// assert_eq!(@sorted_set.of([1, 4, 3]).any(fn(v) { v % 2 == 0}), true)
/// ```
pub fn any[A : Compare](self : T[A], f : (A) -> Bool) -> Bool {
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
/// ```
/// assert_eq!(@sorted_set.of([1, 2, 3, 4, 5, 6]).filter(fn(v) { v % 2 == 0}), @sorted_set.of([2, 4, 6]))
/// ```
pub fn filter[A : Compare](self : T[A], f : (A) -> Bool) -> T[A] {
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
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/sorted_set.of([", suffix="])")
}

///|
pub impl[A : ToJson] ToJson for T[A] with to_json(self) {
  let capacity = self.iter().count()
  guard capacity != 0 else { return Json::array([]) }
  let jsons = Array::new(capacity~)
  self.each(fn(a) { jsons.push(a.to_json()) })
  Json::array(jsons)
}

///|
pub fn to_json[A : ToJson](self : T[A]) -> Json {
  ToJson::to_json(self)
}

///|
pub impl[A : @json.FromJson + Compare] @json.FromJson for T[A] with from_json(
  json,
  path
) {
  guard json is Array(arr) else {
    raise @json.JsonDecodeError(
      (path, "@immut/sorted_set.from_json: expected array"),
    )
  }
  let mut set = new()
  for i in arr {
    set = set.add(A::from_json!(i, path))
  }
  set
}

///|
pub fn from_json[A : @json.FromJson + Compare](
  json : Json
) -> T[A]!@json.JsonDecodeError {
  @json.from_json!(json)
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

// The following are the helper functions or types used by the internal implementation of ImmutableSet

///|
/// The ratio between the sizes of the left and right subtrees.
const BALANCE_RATIO = 5

///|
priv enum SplitBis[A] {
  Found
  NotFound(T[A], () -> T[A])
}

///|
impl[T : Show] Show for SplitBis[T] with output(self, logger) {
  match self {
    Found => logger.write_string("Found")
    NotFound(_) => logger.write_string("NotFound")
  }
}

///|
/// Same as split, but compute the left and right only if the pivot value is not in the ImmutableSet.
/// The right is computed on demand.
fn split_bis[A : Compare](self : T[A], value : A) -> SplitBis[A] {
  match self {
    Empty => NotFound(Empty, fn() -> T[A] { Empty })
    Node(left~, value=node_value, right~, ..) => {
      let compare_result = value.compare(node_value)
      if compare_result == 0 {
        Found
      } else if compare_result < 0 {
        match left.split_bis(value) {
          Found => Found
          NotFound(ll, rl) =>
            NotFound(ll, fn() -> T[A] { join(rl(), node_value, right) })
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
pub fn size[A : Compare](self : T[A]) -> Int {
  match self {
    Empty => 0
    Node(size~, ..) => size
  }
}

///|
/// Creates a new node.
fn create[A : Compare](left : T[A], value : A, right : T[A]) -> T[A] {
  Node(left~, right~, value~, size=left.size() + right.size() + 1)
}

///|
/// Same as create, but performs one step of rebalancing if necessary.
fn balance[A : Compare](left : T[A], value : A, right : T[A]) -> T[A] {
  let left_size = left.size()
  let right_size = right.size()
  if left_size + right_size < 2 {
    create(left, value, right)
  } else if left_size > right_size * BALANCE_RATIO {
    match left {
      Empty => abort("balance: left is empty.")
      Node(left=ll, value=lv, right=lr, ..) =>
        if ll.size() >= lr.size() {
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
        if rr.size() >= rl.size() {
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
fn add_min_value[A : Compare](self : T[A], value : A) -> T[A] {
  match self {
    Empty => singleton(value)
    Node(left~, value=node_value, right~, ..) =>
      balance(left.add_min_value(value), node_value, right)
  }
}

///|
fn add_max_value[A : Compare](self : T[A], value : A) -> T[A] {
  match self {
    Empty => singleton(value)
    Node(left~, value=node_value, right~, ..) =>
      balance(left, node_value, right.add_max_value(value))
  }
}

///|
/// Same as create and balance, but no assumptions are made on the relative heights of left and right.
fn join[A : Compare](left : T[A], value : A, right : T[A]) -> T[A] {
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
fn try_join[A : Compare](left : T[A], value : A, right : T[A]) -> T[A] {
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
fn merge[A : Compare](self : T[A], other : T[A]) -> T[A] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    _ => balance(self, other.min(), other.remove_min())
  }
}

///|
/// Same as merge, but no assumption on the heights of self and other.
fn concat[A : Compare](self : T[A], other : T[A]) -> T[A] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    _ => join(self, other.min(), other.remove_min())
  }
}

///|
pub fn of[A : Compare](array : FixedArray[A]) -> T[A] {
  for i = array.length() - 1, set = Empty; i >= 0; {
    continue i - 1, set.add(array[i])
  } else {
    set
  }
}

///|
pub impl[A : Hash] Hash for T[A] with hash_combine(self, hasher) {
  for t in self {
    t.hash_combine(hasher)
  }
}

///|
test "split_bis" {
  inspect!(of([1, 2, 3]).split_bis(1), content="Found")
  inspect!(of([1, 2, 3]).split_bis(3), content="Found")
  inspect!(of([1, 2, 3]).split_bis(0), content="NotFound")
  inspect!(of([1, 2, 3]).split_bis(4), content="NotFound")
}

///|
test "balance with left height greater" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5])
  let balanced_set = balance(left, value, right)
  inspect!(balanced_set, content="@immut/sorted_set.of([1, 2, 3, 4, 5])")
}

///|
test "balance with right height greater" {
  let left = of([1])
  let value = 2
  let right = of([3, 4, 5])
  let balanced_set = balance(left, value, right)
  inspect!(balanced_set, content="@immut/sorted_set.of([1, 2, 3, 4, 5])")
}

///|
test "join with different heights" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5, 6, 7])
  let joined_set = join(left, value, right)
  inspect!(joined_set, content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7])")
}

///|
test "hash" {
  assert_eq!(Hash::hash(of([1, 2, 3, 4])), Hash::hash(of([3, 2]).add(1).add(4)))
  assert_not_eq!(Hash::hash(of([1, 2, 3])), Hash::hash(of([1, 2, 4])))
}
