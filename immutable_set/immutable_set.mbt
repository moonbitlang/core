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
pub fn ImmutableSet::new[T](value : T) -> ImmutableSet[T] {
  Node({ left: Empty, value, right: Empty, height: 1 })
}

/// Initialize an ImmutableSet[T] from a List[T], T : Compare
pub fn ImmutableSet::from_list[T : Compare](list : List[T]) -> ImmutableSet[T] {
  match list {
    Nil => Empty
    // For very small lists, adding values to the set directly using the add function is much faster than sorting and de-important the entire list.
    Cons(value, Nil) => ImmutableSet::new(value)
    Cons(value, Cons(value1, Nil)) => ImmutableSet::new(value).add(value1)
    Cons(value, Cons(value1, Cons(value2, Nil))) =>
      ImmutableSet::new(value).add(value1).add(value2)
    Cons(value, Cons(value1, Cons(value2, Cons(value3, Nil)))) =>
      ImmutableSet::new(value).add(value1).add(value2).add(value3)
    Cons(value, Cons(value1, Cons(value2, Cons(value3, Cons(value4, Nil))))) =>
      ImmutableSet::new(value).add(value1).add(value2).add(value3).add(value4)
    _ => of_sorted_list(list.sort())
  }
}

/// Convert ImmutableSet[T] to List[T], the result must be ordered.
pub fn to_list[T](self : ImmutableSet[T]) -> List[T] {
  fn values_aux(set : ImmutableSet[T], list : List[T]) {
    match set {
      Empty => list
      Node(node) =>
        values_aux(node.left, Cons(node.value, values_aux(node.right, list)))
    }
  }

  values_aux(self, Nil)
}

/// Remove the smallest value,
pub fn remove_min[T](self : ImmutableSet[T]) -> ImmutableSet[T] {
  match self {
    Empty => abort("remove_min: empty ImmutableSet")
    Node(node) =>
      match node.left {
        Empty => node.right
        _ => balance(node.left.remove_min(), node.value, node.right)
      }
  }
}

/// Insert a value into the ImmutableSet.
pub fn add[T : Compare](self : ImmutableSet[T], value : T) -> ImmutableSet[T] {
  match self {
    Empty => Node({ left: Empty, value, right: Empty, height: 1 })
    Node(node) => {
      let compare_result = value.compare(node.value)
      if compare_result == 0 {
        Node(node)
      } else if compare_result < 0 {
        let left = node.left.add(value)
        if physical_equal(node.left, left) {
          Node(node)
        } else {
          balance(left, node.value, node.right)
        }
      } else {
        let right = node.right.add(value)
        if physical_equal(right, node.right) {
          Node(node)
        } else {
          balance(node.left, node.value, right)
        }
      }
    }
  }
}

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

pub fn min[T](self : ImmutableSet[T]) -> T {
  match self {
    Empty => abort("min: there are no values in ImmutableSet.")
    Node(node) =>
      match node.left {
        Empty => node.value
        _ => node.left.min()
      }
  }
}

pub fn min_option[T](self : ImmutableSet[T]) -> Option[T] {
  match self {
    Empty => None
    Node(node) =>
      match node.left {
        Empty => Some(node.value)
        _ => node.left.min_option()
      }
  }
}

pub fn max[T](self : ImmutableSet[T]) -> T {
  match self {
    Empty => abort("max: there are no values in ImmutableSet.")
    Node(node) =>
      match node.right {
        Empty => node.value
        _ => node.right.max()
      }
  }
}

pub fn max_option[T](self : ImmutableSet[T]) -> Option[T] {
  match self {
    Empty => None
    Node(node) =>
      match node.right {
        Empty => Some(node.value)
        _ => node.right.max_option()
      }
  }
}

/// Returns a triple (left, present, right), left < divide < right
/// present is false if self contains no element equal to divide, 
/// or true if self contains an element equal to divide.
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

pub fn is_empty[T](self : ImmutableSet[T]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

/// Whether value exists in ImmutableSet
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

/// Get the height of set.
fn height[T](self : ImmutableSet[T]) -> Int {
  match self {
    Empty => 0
    Node(node) => node.height
  }
}

/// Creates a new node.
fn create[T](
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
fn balance[T](
  left : ImmutableSet[T],
  value : T,
  right : ImmutableSet[T]
) -> ImmutableSet[T] {
  let left_height = left.height()
  let right_height = right.height()
  if left_height > right_height + 2 {
    match left {
      Empty => abort("balance: left subtree is empty.")
      Node(node) =>
        if node.left.height() >= node.right.height() {
          create(node.left, node.value, create(node.right, node.value, right))
        } else {
          match node.right {
            Empty => abort("balance: right subtree is empty.")
            Node(right_node) =>
              create(
                create(node.left, node.value, right_node.left),
                right_node.value,
                create(right_node.right, value, right),
              )
          }
        }
    }
  } else if right_height > left_height + 2 {
    match right {
      Empty => abort("balance: right subtree is empty")
      Node(node) =>
        if node.right.height() > node.left.height() {
          create(create(left, value, node.left), node.value, node.right)
        } else {
          match node.left {
            Empty => abort("balance: right subtree is empty")
            Node(left_node) =>
              create(
                create(left, value, left_node.left),
                left_node.value,
                create(left_node.right, node.value, node.right),
              )
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

fn add_min_value[T](self : ImmutableSet[T], value : T) -> ImmutableSet[T] {
  match self {
    Empty => new(value)
    Node(node) => balance(node.left.add_min_value(value), value, node.right)
  }
}

fn add_max_value[T](self : ImmutableSet[T], value : T) -> ImmutableSet[T] {
  match self {
    Empty => new(value)
    Node(node) => balance(node.left, value, node.right.add_max_value(value))
  }
}

/// Same as create and balance, but no assumptions are made on the relative heights of left and right.
fn join[T](
  left : ImmutableSet[T],
  value : T,
  right : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (left, right) {
    (Empty, _) => right.add_min_value(value)
    (_, Empty) => left.add_max_value(value)
    (Node(left_node), Node(right_node)) =>
      if left_node.height > right_node.height + 2 {
        balance(
          left_node.left,
          left_node.value,
          join(left_node.right, value, right),
        )
      } else if right_node.height > left_node.height + 2 {
        balance(
          join(left, value, right_node.left),
          right_node.value,
          right_node.right,
        )
      } else {
        create(left, value, right)
      }
  }
}

/// Merge two ImmutableSet[T] into one. 
/// All values of left must precede the values of r.
fn merge[T](self : ImmutableSet[T], other : ImmutableSet[T]) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, other) => other
    (self, Empty) => self
    (_, _) => balance(self, other.min(), other.remove_min())
  }
}

/// Same as merge, but no assumption on the heights of self and other.
fn concat[T](
  self : ImmutableSet[T],
  other : ImmutableSet[T]
) -> ImmutableSet[T] {
  match (self, other) {
    (Empty, other) => other
    (self, Empty) => self
    (_, _) => join(self, other.min(), other.remove_min())
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
          Nil => abort("of_sorted_list: cannot constructs the left subtree")
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
}

test "exists" {
  @assertion.assert_true(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]).exists(5),
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
  let set = create(ImmutableSet::new(1), 3, ImmutableSet::new(2)).remove_min()
  @assertion.assert_eq(
    set,
    Node(
      {
        left: Empty,
        right: Node({ left: Empty, right: Empty, height: 1, value: 2 }),
        height: 2,
        value: 3,
      },
    ),
  )?
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
