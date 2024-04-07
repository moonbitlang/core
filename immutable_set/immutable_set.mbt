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

// This module implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

// Construct a empty ImmutableSet.
pub fn ImmutableSet::new[T]() -> ImmutableSet[T] {
  Empty
}

/// Returns the one-value ImmutableSet containing only `value`.
pub fn ImmutableSet::singleton[T : Compare](value : T) -> ImmutableSet[T] {
  Node({ left: Empty, value, right: Empty, height: 1 })
}

/// Initialize an ImmutableSet[T] from a List[T]
pub fn ImmutableSet::from_list[T : Compare](list : List[T]) -> ImmutableSet[T] {
  match list {
    Nil => Empty
    // For very small lists, adding values to the set directly using the add function is much faster than sorting and de-important the entire list.
    Cons(value, Nil) => singleton(value)
    Cons(value, Cons(value1, Nil)) => singleton(value).add(value1)
    Cons(value, Cons(value1, Cons(value2, Nil))) =>
      singleton(value).add(value1).add(value2)
    Cons(value, Cons(value1, Cons(value2, Cons(value3, Nil)))) =>
      singleton(value).add(value1).add(value2).add(value3)
    Cons(value, Cons(value1, Cons(value2, Cons(value3, Cons(value4, Nil))))) =>
      singleton(value).add(value1).add(value2).add(value3).add(value4)
    _ => of_sorted_list(list.sort())
  }
}

/// Initialize an ImmutableSet[T] from a Array[T]
pub fn ImmutableSet::from_array[T : Compare](
  array : Array[T]
) -> ImmutableSet[T] {
  for i = array.length() - 1, set = ImmutableSet::Empty; i >= 0; {
    continue i - 1, set.add(array[i])
  } else {
    set
  }
}

/// Convert ImmutableSet[T] to List[T], the result must be ordered.
pub fn to_list[T : Compare](self : ImmutableSet[T]) -> List[T] {
  fn values_aux(set : ImmutableSet[T], list : List[T]) {
    match set {
      Empty => list
      Node({ left, right, value, .. }) =>
        values_aux(left, Cons(value, values_aux(right, list)))
    }
  }

  values_aux(self, Nil)
}

/// Convert ImmutableSet[T] to Array[T], the result must be ordered.
pub fn to_array[T : Compare](self : ImmutableSet[T]) -> Array[T] {
  match self {
    Empty => []
    Node({ left, value, right, .. }) =>
      to_array(left) + [value] + to_array(right)
  }
}

/// Convert ImmutableSet[T] to Vec[T], the result must be ordered.
pub fn to_vec[T : Compare](self : ImmutableSet[T]) -> @vec.Vec[T] {
  // This approach is better than using vec splicing implementation 
  // due to the existence of scaling costs for Vec
  @vec.from_array(self.to_array())
}

/// Remove the smallest value,
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[3, 4, 5].remove_min())
/// // output: ImmutableSet::[4, 5]
/// ```
pub fn remove_min[T : Compare](self : ImmutableSet[T]) -> ImmutableSet[T] {
  match self {
    Empty => abort("remove_min: empty ImmutableSet")
    Node({ left, right, value, .. }) =>
      match left {
        Empty => right
        _ => balance(left.remove_min(), value, right)
      }
  }
}

/// Insert a value into the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[6, 3, 8, 1].add(5))
/// // output: ImmutableSet::[1, 3, 5, 6, 8]
/// ```
pub fn add[T : Compare](self : ImmutableSet[T], value : T) -> ImmutableSet[T] {
  match self {
    Empty => Node({ left: Empty, value, right: Empty, height: 1 })
    Node({ left, right, value: node_value, .. }) => {
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

/// Remove n value from the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[3, 8, 1].remove(8))
/// // output: ImmutableSet::[1, 3]
/// ```
pub fn remove[T : Compare](
  self : ImmutableSet[T],
  value : T
) -> ImmutableSet[T] {
  match self {
    Empty => Empty
    Node(node) => {
      let compare_result = value.compare(node.value)
      if compare_result == 0 {
        node.left.merge(node.right)
      } else if compare_result < 0 {
        let left = node.left.remove(value)
        if physical_equal(node.left, left) {
          Node(node)
        } else {
          balance(left, node.value, node.right)
        }
      } else {
        let right = node.right.remove(value)
        if physical_equal(node.right, right) {
          Node(node)
        } else {
          balance(node.left, node.value, right)
        }
      }
    }
  }
}

/// Returns the smallest value in the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].min())
/// // output: 1
/// ```
pub fn min[T : Compare](self : ImmutableSet[T]) -> T {
  match self {
    Empty => abort("min: there are no values in ImmutableSet.")
    Node(node) =>
      match node.left {
        Empty => node.value
        _ => node.left.min()
      }
  }
}

/// Returns the smallest value in the ImmutableSet.
/// But returns None when the value does not exist.
pub fn min_option[T : Compare](self : ImmutableSet[T]) -> Option[T] {
  match self {
    Empty => None
    Node(node) =>
      match node.left {
        Empty => Some(node.value)
        _ => node.left.min_option()
      }
  }
}

/// Returns the largest value in the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].max())
/// // output: 9
/// ```
pub fn max[T : Compare](self : ImmutableSet[T]) -> T {
  match self {
    Empty => abort("max: there are no values in ImmutableSet.")
    Node(node) =>
      match node.right {
        Empty => node.value
        _ => node.right.max()
      }
  }
}

/// Returns the largest value in the ImmutableSet.
/// But returns None when the value does not exist.
pub fn max_option[T : Compare](self : ImmutableSet[T]) -> Option[T] {
  match self {
    Empty => None
    Node(node) =>
      match node.right {
        Empty => Some(node.value)
        _ => node.right.max_option()
      }
  }
}

/// Returns a triple (left, present, right), where left < divide < right.
/// present == false if self contains no value equal to divide, 
/// present == true  if self contains an value equal to divide.
/// 
/// # Example
/// 
/// ```
/// let (left, present, right) = ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].split(5)
/// println(present) // output: true
/// println(left) // output: ImmutableSet::[1, 2, 3, 4]
/// println(right) // output:ImmutableSet::[6, 7, 8, 9]
/// ```
pub fn split[T : Compare](
  self : ImmutableSet[T],
  divide : T
) -> (ImmutableSet[T], Bool, ImmutableSet[T]) {
  match self {
    Empty => (Empty, false, Empty)
    Node(node) => {
      let compare_result = divide.compare(node.value)
      if compare_result == 0 {
        (node.left, true, node.right)
      } else if compare_result < 0 {
        let (left_left, present, right_left) = node.left.split(divide)
        (left_left, present, join(right_left, node.value, node.right))
      } else {
        let (left_right, present, right_right) = node.right.split(divide)
        (join(node.left, node.value, left_right), present, right_right)
      }
    }
  }
}

/// Returns true if ImmutableSet is empty
pub fn is_empty[T : Compare](self : ImmutableSet[T]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

/// Return true if value contain in ImmutableSet
pub fn contain[T : Compare](self : ImmutableSet[T], value : T) -> Bool {
  match self {
    Empty => false
    Node(node) => {
      let compare_result = value.compare(node.value)
      compare_result == 0 || (if compare_result < 0 {
        node.left
      } else {
        node.right
      }).contain(value)
    }
  }
}

/// Returns the union of self and other.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[3, 4, 5].union(ImmutableSet::[4, 5, 6]))
/// // output: ImmutableSet::[3, 4, 5, 6]
/// ```
pub fn union[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    (
      Node({ left: l1, value: v1, right: r1, height: h1 }),
      Node({ left: l2, value: v2, right: r2, height: h2 }),
    ) =>
      if h1 >= h2 {
        if h2 == 1 {
          self.add(v2)
        } else {
          let (l2, _, r2) = other.split(v1)
          join(l1.union(l2), v1, r1.union(r2))
        }
      } else if h1 == 1 {
        other.add(v1)
      } else {
        let (l1, _, r1) = self.split(v2)
        join(l1.union(l2), v2, r1.union(r2))
      }
  }
}

/// Returns the intersection of self with other.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[3, 4, 5].inter(ImmutableSet::[4, 5, 6]))
/// // output: ImmutableSet::[4, 5]
/// ```
pub fn inter[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, _) | (_, Empty) => Empty
    (Node({ left: l1, value: v1, right: r1, .. }), _) =>
      match other.split(v1) {
        (l2, false, r2) => l1.inter(l2).concat(r1.inter(r2))
        (l2, true, r2) => join(l1.inter(l2), v1, r1.inter(r2))
      }
  }
}

/// Returns the difference between self and other.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[1, 2, 3].diff(ImmutableSet::[4, 5, 1]))
/// // output: ImmutableSet::[2, 3]
/// ```
pub fn diff[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, _) => Empty
    (_, Empty) => self
    (Node({ left: l1, value: v1, right: r1, .. }), _) =>
      match other.split(v1) {
        (l2, false, r2) => join(l1.diff(l2), v1, r1.diff(r2))
        (l2, true, r2) => l1.diff(l2).concat(r1.diff(r2))
      }
  }
}

/// Returns true if self is a subset of other.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[1, 2, 3].subset(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1]))
/// // output: true
/// ```
pub fn subset[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> Bool {
  match (self, other) {
    (Empty, _) => true
    (_, Empty) => false
    (
      Node({ left: l1, value: v1, right: r1, .. }),
      Node({ left: l2, value: v2, right: r2, .. }),
    ) => {
      let compare_result = v1.compare(v2)
      if compare_result == 0 {
        l1.subset(l2) && r1.subset(r2)
      } else if compare_result < 0 {
        ImmutableSet::Node({ left: l1, value: v1, right: Empty, height: 0 }).subset(
          l2,
        ) && r1.subset(self)
      } else {
        ImmutableSet::Node({ left: Empty, value: v1, right: r1, height: 0 }).subset(
          r2,
        ) && l1.subset(self)
      }
    }
  }
}

/// Returns true if the two sets do not intersect.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[1, 2, 3].disjoint(ImmutableSet::[4, 5, 6]))
/// // output: true
/// ```
pub fn disjoint[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> Bool {
  match (self, other) {
    (Empty, _) | (_, Empty) => true
    (Node({ left: l1, value: v1, right: r1, .. }), _) =>
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

/// Iterates over the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].iter(print)
/// // output: 123456789
/// ```
pub fn iter[T : Compare](self : ImmutableSet[T], f : (T) -> Unit) -> Unit {
  match self {
    Empty => ()
    Node({ left, value, right, .. }) => {
      left.iter(f)
      f(value)
      right.iter(f)
    }
  }
}

/// Fold the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[1, 2, 3, 4, 5].fold(0, fn(acc, x) { acc + x }))
/// // output: 15
/// ```
pub fn fold[T : Compare, U](
  self : ImmutableSet[T],
  f : (U, T) -> U,
  ~init : U
) -> U {
  match self {
    Empty => init
    Node({ left, value, right, .. }) =>
      right.fold(~init=f(left.fold(~init, f), value), f)
  }
}

/// Maps the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[1, 2, 3].map(fn(x){ x * 2}))
/// // output: ImmutableSet::[2, 4, 6]
/// ```
pub fn map[T : Compare, U : Compare](
  self : ImmutableSet[T],
  f : (T) -> U
) -> ImmutableSet[U] {
  match self {
    Empty => Empty
    Node({ left, value, right, .. }) =>
      try_join(left.map(f), f(value), right.map(f))
  }
}

/// Test if all values of the ImmutableSet satisfy the predicate.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[2, 4, 6].forall(fn(v) { v % 2 == 0}))
/// // output: true
/// ```
pub fn forall[T : Compare](self : ImmutableSet[T], f : (T) -> Bool) -> Bool {
  match self {
    Empty => true
    Node({ left, value, right, .. }) =>
      f(value) && left.forall(f) && right.forall(f)
  }
}

/// Checks if at least one element of the set satisfies the predicate.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[1, 4, 3].exists(fn(v) { v % 2 == 0}))
/// // output: true
/// ```
pub fn exists[T : Compare](self : ImmutableSet[T], f : (T) -> Bool) -> Bool {
  match self {
    Empty => false
    Node({ left, value, right, .. }) =>
      f(value) || left.exists(f) || right.exists(f)
  }
}

/// Filter the ImmutableSet.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::[1, 2, 3, 4, 5, 6].filter(fn(v) { v % 2 == 0}))
/// // output: ImmutableSet::[2, 4, 6]
/// ```
pub fn filter[T : Compare](
  self : ImmutableSet[T],
  f : (T) -> Bool
) -> ImmutableSet[T] {
  match self {
    Empty => Empty
    Node({ left, value, right, .. }) => {
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

pub fn to_string[T : Show + Compare](self : ImmutableSet[T]) -> String {
  match self {
    Empty => "ImmutableSet::[]"
    _ => {
      let linear = self.to_array()
      let len = linear.length()
      for i = 0, str = "ImmutableSet::["; i < len - 1; {
        continue i + 1, str + linear[i].to_string() + ", "
      } else {
        str + linear[len - 1].to_string() + "]"
      }
    }
  }
}

// The following are the helper functions or types used by the internal implementation of ImmutableSet

priv enum SplitBis[T] {
  Found
  NotFound(ImmutableSet[T], () -> ImmutableSet[T])
}

/// Same as split, but compute the left and right only if the pivot value is not in the ImmutableSet.
/// The right is computed on demand.
fn split_bis[T : Compare](self : ImmutableSet[T], value : T) -> SplitBis[T] {
  match self {
    Empty => NotFound(Empty, fn() -> ImmutableSet[T] { Empty })
    Node({ left, value: node_value, right, .. }) => {
      let compare_result = value.compare(node_value)
      if compare_result == 0 {
        Found
      } else if compare_result < 0 {
        match left.split_bis(value) {
          Found => Found
          NotFound(ll, rl) =>
            NotFound(
              ll,
              fn() -> ImmutableSet[T] { join(rl(), node_value, right) },
            )
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

/// Get the height of set.
fn height[T : Compare](self : ImmutableSet[T]) -> Int {
  match self {
    Empty => 0
    Node(node) => node.height
  }
}

/// Creates a new node.
fn create[T : Compare](
  left : ImmutableSet[T],
  value : T,
  right : ImmutableSet[T]
) -> ImmutableSet[T] {
  let left_height = left.height()
  let right_height = right.height()
  Node(
    {
      left,
      right,
      value,
      height: if left_height >= right_height {
        left_height + 1
      } else {
        right_height + 1
      },
    },
  )
}

/// Same as create, but performs one step of rebalancing if necessary.
fn balance[T : Compare](
  left : ImmutableSet[T],
  value : T,
  right : ImmutableSet[T]
) -> ImmutableSet[T] {
  let left_height = left.height()
  let right_height = right.height()
  if left_height > right_height + 2 {
    match left {
      Empty => abort("balance: left is empty.")
      Node({ left: ll, value: lv, right: lr, .. }) =>
        if ll.height() >= lr.height() {
          create(ll, lv, create(lr, value, right))
        } else {
          match lr {
            Empty => abort("balance: right left.right is empty.")
            Node({ left: lrl, value: lrv, right: lrr, .. }) =>
              create(create(ll, lv, lrl), lrv, create(lrr, value, right))
          }
        }
    }
  } else if right_height > left_height + 2 {
    match right {
      Empty => abort("balance: right is empty")
      Node({ left: rl, value: rv, right: rr, .. }) =>
        if rr.height() >= rl.height() {
          create(create(left, value, rl), rv, rr)
        } else {
          match rl {
            Empty => abort("balance: right.left is empty")
            Node({ left: rll, value: rlv, right: rlr, .. }) =>
              create(create(left, value, rll), rlv, create(rlr, rv, rr))
          }
        }
    }
  } else {
    Node(
      {
        left,
        value,
        right,
        height: if left_height >= right_height {
          left_height + 1
        } else {
          right_height + 1
        },
      },
    )
  }
}

fn add_min_value[T : Compare](
  self : ImmutableSet[T],
  value : T
) -> ImmutableSet[T] {
  match self {
    Empty => singleton(value)
    Node({ left, value: node_value, right, .. }) =>
      balance(left.add_min_value(value), node_value, right)
  }
}

fn add_max_value[T : Compare](
  self : ImmutableSet[T],
  value : T
) -> ImmutableSet[T] {
  match self {
    Empty => singleton(value)
    Node({ left, value: node_value, right, .. }) =>
      balance(left, node_value, right.add_max_value(value))
  }
}

/// Same as create and balance, but no assumptions are made on the relative heights of left and right.
fn join[T : Compare](
  left : ImmutableSet[T],
  value : T,
  right : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (left, right) {
    (Empty, _) => right.add_min_value(value)
    (_, Empty) => left.add_max_value(value)
    (
      Node({ left: ll, value: lv, right: lr, height: lh }),
      Node({ left: rl, value: rv, right: rr, height: rh }),
    ) =>
      if lh > rh + 2 {
        balance(ll, lv, join(lr, value, right))
      } else if rh > lh + 2 {
        balance(join(left, value, rl), rv, rr)
      } else {
        create(left, value, right)
      }
  }
}

fn try_join[T : Compare](
  left : ImmutableSet[T],
  value : T,
  right : ImmutableSet[T]
) -> ImmutableSet[T] {
  if (left == Empty || left.max().compare(value) < 0) && (right == Empty || value.compare(
    right.min(),
  ) < 0) {
    join(left, value, right)
  } else {
    left.union(right.add(value))
  }
}

/// Merge two ImmutableSet[T] into one. 
/// All values of left must precede the values of r.
fn merge[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    _ => balance(self, other.min(), other.remove_min())
  }
}

/// Same as merge, but no assumption on the heights of self and other.
fn concat[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, _) => other
    (_, Empty) => self
    _ => join(self, other.min(), other.remove_min())
  }
}

// Convert a sorted list into a balanced binary search tree to facilitate subsequent search, insertion, and deletion operations.
fn of_sorted_list[T : Compare](list : List[T]) -> ImmutableSet[T] {
  // Recursively process the input list and build a balanced binary search tree based on the length n of the list.
  fn sub(n : Int, list : List[T]) -> (ImmutableSet[T], List[T]) {
    match (n, list) {
      (0, list) => (Empty, list)
      (1, Cons(value, list)) =>
        (Node({ left: Empty, value, right: Empty, height: 1 }), list)
      (2, Cons(value, Cons(value1, list))) =>
        (
          Node(
            {
              left: Node({ left: Empty, value, right: Empty, height: 1 }),
              value: value1,
              right: Empty,
              height: 2,
            },
          ),
          list,
        )
      (3, Cons(value, Cons(value1, Cons(value2, list)))) =>
        (
          Node(
            {
              left: Node({ left: Empty, value, right: Empty, height: 1 }),
              value: value1,
              right: Node(
                { left: Empty, value: value2, right: Empty, height: 1 },
              ),
              height: 2,
            },
          ),
          list,
        )

      // For n > 3, the function first calculates the size of the left subtree,
      // and then recursively constructs the left subtree.
      _ => {
        let left_length = n / 2
        let (left, list) = sub(left_length, list)
        match list {
          Nil => abort("of_sorted_list: cannot constructs the left")
          Cons(mid, list) => {
            let (right, list) = sub(n - left_length - 1, list)
            (create(left, mid, right), list)
          }
        }
      }
    }
  }

  sub(list.length(), list).0
}

test "disjoint" {
  inspect(
    ImmutableSet::[1, 2, 3].disjoint(ImmutableSet::[4, 5, 6]),
    ~content="true",
  )?
  inspect(
    ImmutableSet::[1, 2, 3].subset(ImmutableSet::[3, 4, 5]),
    ~content="false",
  )?
}

test "subset" {
  inspect(
    ImmutableSet::[1, 2, 3].subset(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
    ~content="true",
  )?
  inspect(
    ImmutableSet::[1, 2, 3].subset(ImmutableSet::[10, 11, 12, 13, 14]),
    ~content="false",
  )?
}

test "diff" {
  inspect(
    ImmutableSet::[1, 2, 3].diff(ImmutableSet::[4, 5, 1]),
    ~content="ImmutableSet::[2, 3]",
  )?
}

test "inter" {
  inspect(
    ImmutableSet::[3, 4, 5].inter(ImmutableSet::[4, 5, 6]),
    ~content="ImmutableSet::[4, 5]",
  )?
}

test "union" {
  inspect(
    ImmutableSet::[3, 4, 5].union(ImmutableSet::[4, 5, 6]),
    ~content="ImmutableSet::[3, 4, 5, 6]",
  )?
}

test "map" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5].map(fn(x) { x * 2 }),
    ~content="ImmutableSet::[2, 4, 6, 8, 10]",
  )?
}

test "forall" {
  inspect(ImmutableSet::[2, 4, 6].forall(fn(v) { v % 2 == 0 }), ~content="true")?
  inspect(
    ImmutableSet::[1, 3, 5].forall(fn(v) { v % 2 == 0 }),
    ~content="false",
  )?
}

test "exists" {
  inspect(ImmutableSet::[1, 4, 3].exists(fn(v) { v % 2 == 0 }), ~content="true")?
  inspect(
    ImmutableSet::[1, 5, 3].exists(fn(v) { v % 2 == 0 }),
    ~content="false",
  )?
}

test "fold" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5].fold(~init=0, fn(acc, x) { acc + x }),
    ~content="15",
  )?
}

test "filter" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5, 6].filter(fn(v) { v % 2 == 0 }),
    ~content="ImmutableSet::[2, 4, 6]",
  )?
}

test "max" {
  inspect(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].max(), ~content="9")?
}

test "split" {
  let (left, present, right) = ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].split(
    5,
  )
  inspect(present, ~content="true")?
  inspect(left, ~content="ImmutableSet::[1, 2, 3, 4]")?
  inspect(right, ~content="ImmutableSet::[6, 7, 8, 9]")?
  let (left, present, right) = ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].split(
    0,
  )
  inspect(present, ~content="false")?
  inspect(left, ~content="ImmutableSet::[]")?
  inspect(right, ~content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
}

test "contain" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 6, 3, 8, 1].add(5).contain(5),
    ~content="true",
  )?
  inspect(ImmutableSet::[7, 2, 9, 4, 6, 3, 8, 1].contain(5), ~content="false")?
}

test "from_list" {
  inspect(List::[1], ~content="List::[1]")?
  inspect(List::[1, 2], ~content="List::[1, 2]")?
  inspect(List::[1, 2, 3], ~content="List::[1, 2, 3]")?
  inspect(List::[1, 2, 3, 4], ~content="List::[1, 2, 3, 4]")?
  inspect(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
    ~content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_list" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
    ~content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_array" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_array(),
    ~content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_vec" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_vec(),
    ~content="Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "from_array" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
    ~content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "remove_min" {
  inspect(ImmutableSet::[3, 4, 5].remove_min(), ~content="ImmutableSet::[4, 5]")?
}

test "add" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 6, 3, 8, 1].add(5),
    ~content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
  inspect(ImmutableSet::[2].add(1), ~content="ImmutableSet::[1, 2]")?
  inspect(ImmutableSet::[2].add(3), ~content="ImmutableSet::[2, 3]")?
  inspect(ImmutableSet::[2].add(1).add(3), ~content="ImmutableSet::[1, 2, 3]")?
}

test "remove" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].remove(8),
    ~content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 9]",
  )?
}

test "min" {
  inspect(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].min(), ~content="1")?
}

test "is_empty" {
  inspect(ImmutableSet::[].is_empty(), ~content="true")?
  inspect(ImmutableSet::[1].is_empty(), ~content="false")?
}

test "to_string" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5],
    ~content="ImmutableSet::[1, 2, 3, 4, 5]",
  )?
  inspect(ImmutableSet::[], ~content="ImmutableSet::[]")?
}
