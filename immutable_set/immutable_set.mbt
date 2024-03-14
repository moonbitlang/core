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

/// ImmutableSets are represented by balanced binary trees (the heights of the children differ by at most 2).
enum ImmutableSet[T] {
  Empty
  Node(Node[T])
} derive(Default, Show, Debug, Eq)

priv struct Node[T] {
  left : ImmutableSet[T]
  right : ImmutableSet[T]
  height : Int
  value : T
} derive(Default, Show, Debug, Eq)

/// Returns the one-value ImmutableSet containing only `value`.
pub fn ImmutableSet::from_value[T : Compare](value : T) -> ImmutableSet[T] {
  Node({ left: Empty, value, right: Empty, height: 1 })
}

/// Initialize an ImmutableSet[T] from a List[T], T : Compare
pub fn ImmutableSet::from_list[T : Compare](list : List[T]) -> ImmutableSet[T] {
  match list {
    Nil => Empty
    // For very small lists, adding values to the set directly using the add function is much faster than sorting and de-important the entire list.
    Cons(value, Nil) => ImmutableSet::from_value(value)
    Cons(value, Cons(value1, Nil)) =>
      ImmutableSet::from_value(value).add(value1)
    Cons(value, Cons(value1, Cons(value2, Nil))) =>
      ImmutableSet::from_value(value).add(value1).add(value2)
    Cons(value, Cons(value1, Cons(value2, Cons(value3, Nil)))) =>
      ImmutableSet::from_value(value).add(value1).add(value2).add(value3)
    Cons(value, Cons(value1, Cons(value2, Cons(value3, Cons(value4, Nil))))) =>
      ImmutableSet::from_value(value).add(value1).add(value2).add(value3).add(
        value4,
      )
    _ => of_sorted_list(list.sort())
  }
}

/// Convert ImmutableSet[T] to List[T], the result must be ordered.
pub fn to_list[T : Compare](self : ImmutableSet[T]) -> List[T] {
  fn values_aux(set : ImmutableSet[T], list : List[T]) {
    match set {
      Empty => list
      Node({ left, right, value, height: _ }) =>
        values_aux(left, Cons(value, values_aux(right, list)))
    }
  }

  values_aux(self, Nil)
}

/// Remove the smallest value,
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::from_list(List::[3, 4, 5]).remove_min().to_list())
/// // output: Cons(4, Cons(5, Nil))
/// ```
pub fn remove_min[T : Compare](self : ImmutableSet[T]) -> ImmutableSet[T] {
  match self {
    Empty => abort("remove_min: empty ImmutableSet")
    Node({ left, right, value, height: _ }) =>
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
/// println(ImmutableSet::from_list(List::[6, 3, 8, 1]).add(5).to_list())
/// // output: Cons(1, Cons(3, Cons(5, Cons(6, Cons(8, Nil)))))
/// ```
pub fn add[T : Compare](self : ImmutableSet[T], value : T) -> ImmutableSet[T] {
  match self {
    Empty => Node({ left: Empty, value, right: Empty, height: 1 })
    Node({ left, right, value: node_value, height: _ }) as node => {
      let compare_result = value.compare(node_value)
      if compare_result == 0 {
        node
      } else if compare_result < 0 {
        let ll = left.add(value)
        if physical_equal(left, ll) {
          node
        } else {
          balance(ll, node_value, right)
        }
      } else {
        let rr = right.add(value)
        if physical_equal(right, rr) {
          node
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
/// println(ImmutableSet::from_list(List::[3, 8, 1]).remove(8).to_list())
/// // output: Cons(1, Cons(3, Nil))
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
/// println(ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]).min())
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
/// println(ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]).max())
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
/// let (left, present, right) = ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1],).split(5)
/// println(present) // output: true
/// println(left.to_list()) // output: Cons(1, Cons(2, Cons(3, Cons(4, Nil))))
/// println(right.to_list()) // output: Cons(6, Cons(7, Cons(8, Cons(9, Nil))))
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

/// Return true if value exists in ImmutableSet
pub fn exists[T : Compare](self : ImmutableSet[T], value : T) -> Bool {
  match self {
    Empty => false
    Node(node) => {
      let compare_result = value.compare(node.value)
      compare_result == 0 || (if compare_result < 0 {
        node.left
      } else {
        node.right
      }).exists(value)
    }
  }
}

/// Returns the union of self and other.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::from_list(List::[3, 4, 5])
///           .union(ImmutableSet::from_list(List::[4, 5, 6]))
///           .to_list())
/// // output: Cons(3, Cons(4, Cons(5, Cons(6, Nil))))
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
/// println(ImmutableSet::from_list(List::[3, 4, 5])
///           .inter(ImmutableSet::from_list(List::[4, 5, 6]))
///           .to_list())
/// // output: Cons(4, Cons(5, Nil))
/// ```
pub fn inter[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, _) | (_, Empty) => Empty
    (Node({ left: l1, value: v1, right: r1, height: _ }), _) =>
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
/// println(ImmutableSet::from_list(List::[1, 2, 3])
///           .diff(ImmutableSet::from_list(List::[4, 5, 1]))
///           .to_list())
/// // output: Cons(2, Cons(3, Nil))
/// ```
pub fn diff[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, _) => Empty
    (_, Empty) => self
    (Node({ left: l1, value: v1, right: r1, height: _ }), _) =>
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
/// println(ImmutableSet::from_list(List::[1, 2, 3]).subset(
///   ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]))))
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
      Node({ left: l1, value: v1, right: r1, height: _ }),
      Node({ left: l2, value: v2, right: r2, height: _ }) as node,
    ) => {
      let compare_result = v1.compare(v2)
      if compare_result == 0 {
        l1.subset(l2) && r1.subset(r2)
      } else if compare_result < 0 {
        Node::new(l1, v1, Empty, 0).subset(l2) && r1.subset(node)
      } else {
        Node::new(Empty, v1, r1, 0).subset(r2) && l1.subset(node)
      }
    }
  }
}

/// Returns true if the two sets do not intersect.
/// 
/// # Example
/// 
/// ```
/// println(ImmutableSet::from_list(List::[1, 2, 3]).disjoint(
///    ImmutableSet::from_list(List::[4, 5, 6]))))
/// // output: true
/// ```
pub fn disjoint[T : Compare](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> Bool {
  match (self, other) {
    (Empty, _) | (_, Empty) => true
    (Node({ left: l1, value: v1, right: r1, height: _ }), _) =>
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
    Node({ left, value: node_value, right, height: _ }) => {
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

fn Node::new[T : Compare](
  left : ImmutableSet[T],
  value : T,
  right : ImmutableSet[T],
  height : Int
) -> ImmutableSet[T] {
  Node({ left, value, right, height })
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
      Node({ left: ll, value: lv, right: lr, height: _ }) =>
        if ll.height() >= lr.height() {
          create(ll, lv, create(lr, value, right))
        } else {
          match lr {
            Empty => abort("balance: right left.right is empty.")
            Node({ left: lrl, value: lrv, right: lrr, height: _ }) =>
              create(create(ll, lv, lrl), lrv, create(lrr, value, right))
          }
        }
    }
  } else if right_height > left_height + 2 {
    match right {
      Empty => abort("balance: right is empty")
      Node({ left: rl, value: rv, right: rr, height: _ }) =>
        if rr.height() >= rl.height() {
          create(create(left, value, rl), rv, rr)
        } else {
          match rl {
            Empty => abort("balance: right.left is empty")
            Node({ left: rll, value: rlv, right: rlr, height: _ }) =>
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
    Empty => ImmutableSet::from_value(value)
    Node({ left, value: node_value, right, height: _ }) =>
      balance(left.add_min_value(value), node_value, right)
  }
}

fn add_max_value[T : Compare](
  self : ImmutableSet[T],
  value : T
) -> ImmutableSet[T] {
  match self {
    Empty => ImmutableSet::from_value(value)
    Node({ left, value: node_value, right, height: _ }) =>
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

  let (set, _) = sub(list.length(), list)
  set
}

test "disjoint" {
  @assertion.assert_true(
    ImmutableSet::from_list(List::[1, 2, 3]).disjoint(
      ImmutableSet::from_list(List::[4, 5, 6]),
    ),
  )?
  @assertion.assert_false(
    ImmutableSet::from_list(List::[1, 2, 3]).subset(
      ImmutableSet::from_list(List::[3, 4, 5]),
    ),
  )?
}

test "subset" {
  @assertion.assert_true(
    ImmutableSet::from_list(List::[1, 2, 3]).subset(
      ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
    ),
  )?
  @assertion.assert_false(
    ImmutableSet::from_list(List::[1, 2, 3]).subset(
      ImmutableSet::from_list(List::[10, 11, 12, 13, 14]),
    ),
  )?
}

test "diff" {
  @assertion.assert_eq(
    ImmutableSet::from_list(List::[1, 2, 3]).diff(
      ImmutableSet::from_list(List::[4, 5, 1]),
    ).to_list(),
    List::[2, 3],
  )?
}

test "inter" {
  @assertion.assert_eq(
    ImmutableSet::from_list(List::[3, 4, 5]).inter(
      ImmutableSet::from_list(List::[4, 5, 6]),
    ).to_list(),
    List::[4, 5],
  )?
}

test "union" {
  @assertion.assert_eq(
    ImmutableSet::from_list(List::[3, 4, 5]).union(
      ImmutableSet::from_list(List::[4, 5, 6]),
    ).to_list(),
    List::[3, 4, 5, 6],
  )?
}

test "max" {
  @assertion.assert_eq(
    9,
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]).max(),
  )?
}

test "split" {
  let (left, present, right) = ImmutableSet::from_list(
    List::[7, 2, 9, 4, 5, 6, 3, 8, 1],
  ).split(5)
  @assertion.assert_true(present)?
  @assertion.assert_eq(left.to_list(), List::[1, 2, 3, 4])?
  @assertion.assert_eq(right.to_list(), List::[6, 7, 8, 9])?
  let (left, present, right) = ImmutableSet::from_list(
    List::[7, 2, 9, 4, 5, 6, 3, 8, 1],
  ).split(0)
  @assertion.assert_false(present)?
  @assertion.assert_eq(left.to_list(), Nil)?
  @assertion.assert_eq(right.to_list(), List::[1, 2, 3, 4, 5, 6, 7, 8, 9])?
}

test "exists" {
  @assertion.assert_true(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 6, 3, 8, 1]).add(5).exists(5),
  )?
}

test "from_list" {
  @assertion.assert_eq(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
    Node(
      {
        left: Node(
          {
            left: Node(
              {
                left: Node({ left: Empty, right: Empty, height: 1, value: 1 }),
                right: Empty,
                height: 2,
                value: 2,
              },
            ),
            right: Node({ left: Empty, right: Empty, height: 1, value: 4 }),
            height: 3,
            value: 3,
          },
        ),
        right: Node(
          {
            left: Node(
              {
                left: Node({ left: Empty, right: Empty, height: 1, value: 6 }),
                right: Empty,
                height: 2,
                value: 7,
              },
            ),
            right: Node({ left: Empty, right: Empty, height: 1, value: 9 }),
            height: 3,
            value: 8,
          },
        ),
        height: 4,
        value: 5,
      },
    ),
  )?
}

test "to_list" {
  @assertion.assert_eq(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]).to_list(),
    List::[1, 2, 3, 4, 5, 6, 7, 8, 9],
  )?
}

test "remove_min" {
  let set = ImmutableSet::from_list(List::[3, 4, 5]).remove_min()
  @assertion.assert_eq(set.to_list(), List::[4, 5])?
}

test "add" {
  @assertion.assert_eq(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 6, 3, 8, 1]).add(5).to_list(),
    List::[1, 2, 3, 4, 5, 6, 7, 8, 9],
  )?
}

test "remove" {
  @assertion.assert_eq(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(8).to_list(),
    List::[1, 2, 3, 4, 5, 6, 7, 9],
  )?
}

test "min" {
  @assertion.assert_eq(
    1,
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]).min(),
  )?
}
