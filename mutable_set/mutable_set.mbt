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

// Construct a empty MutableSet.
pub fn MutableSet::new[T]() -> MutableSet[T] {
  { root: Empty(Black) }
}

/// Returns the one-value MutableSet containing only `value`.
pub fn MutableSet::singleton[T : Compare](value : T) -> MutableSet[T] {
  { root: Node({ color: Black, left: Empty(Black), value, right: Empty(Black) }) }
}

/// Initialize an MutableSet[T] from a Array[T]
pub fn MutableSet::from_array[T : Compare](array : Array[T]) -> MutableSet[T] {
  let set = MutableSet::new()
  for i = 0; i < array.length(); i = i + 1 {
    set.add(array[i])
  }
  set
}

/// Convert MutableSet[T] to List[T], the result must be ordered.
pub fn to_list[T : Compare](self : MutableSet[T]) -> List[T] {
  fn values_aux(set : Node[T], list : List[T]) {
    match set {
      Empty(_) => list
      Node({ color, left, value, right }) =>
        values_aux(left, Cons(value, values_aux(right, list)))
    }
  }

  values_aux(self.root, Nil)
}

/// Convert MutableSet[T] to Array[T], the result must be ordered.
pub fn to_array[T : Compare](self : MutableSet[T]) -> Array[T] {
  fn aux(set : Node[T]) {
    match set {
      Empty(_) => []
      Node({ color, left, value, right }) => aux(left) + [value] + aux(right)
    }
  }

  aux(self.root)
}

/// Convert MutableSet[T] to Vec[T], the result must be ordered.
pub fn to_vec[T : Compare](self : MutableSet[T]) -> @vec.Vec[T] {
  // This approach is better than vec splicing implementation 
  // due to the scaling cost of Vec
  @vec.from_array(self.to_array())
}

/// Insert a value into the MutableSet.
/// 
/// # Example
/// 
/// ```
/// println(MutableSet::[6, 3, 8, 1].add(5))
/// // output: MutableSet::[1, 3, 5, 6, 8]
/// ```
pub fn add[T : Compare](self : MutableSet[T], value : T) -> Unit {
  fn add_int(n : Node[T], value : T) -> Unit {
    match n {
      Empty(_) => abort("Impossible to reach")
      Node(node) => {
        let compare_result = value.compare(node.value)
        if compare_result == 0 {
          ()
        } else if compare_result < 0 {
          match node.left {
            Empty(_) => {
              let l = { color: Red, left: Empty(Black), value, right: Empty(Black) }
              node.left = Node(l)
              balance(node)
            }
            Node(_) => {
              add_int(node.left, value)
              balance(node)
            }
          }
        } else {
          match node.right {
            Empty(_) => {
              let r = { color: Red, left: Empty(Black), value, right: Empty(Black) }
              node.right = Node(r)
              balance(r)
            }
            Node(_) => {
              add_int(node.right, value)
              balance(node)
            }
          }
        }
      }
    }
  }

  match self.root {
    Empty(_) =>
      self.root = Node({ color: Black, left: Empty(Black), value, right: Empty(Black) })
    Node(_) => {
      add_int(self.root, value)
      match self.root {
        Node(node) => node.color = Black
        _ => abort("Impossible to reach here")
      }
    }
  }
}

// @alert unsafe "Panic if called on an empty set.""
fn min[T: Compare](self: Node[T]) -> T {
  match self {
    Empty(_) => abort("Impossible to reach")
    Node({ left: Empty(Black), value, .. }) => value
    Node({ left, .. }) => min(left)
  }
}





// pub fn remove[T : Compare](
//    self : MutableSet[T],
//    value : T
//  ) -> Unit {
//   fn aux(node : Node[T], value : T) -> Unit {
//     fn aux_aux(node : Node[T], value : T) -> Unit {
//       match node {
//         Empty(_) => 
      
/// Returns true if MutableSet is empty
pub fn is_empty[T : Compare](self : MutableSet[T]) -> Bool {
  match self.root {
    Empty(_) => true
    _ => false
  }
}

/// Return true if value contain in MutableSet
pub fn contains[T : Compare](self : MutableSet[T], value : T) -> Bool {
  fn aux(node : Node[T], value : T) -> Bool {
    match node {
      Empty(_) => false
      Node({ left, value: node_value, right, .. }) => {
        let compare_result = value.compare(node_value)
        if compare_result == 0 {
          true
        } else if compare_result < 0 {
          aux(left, value)
        } else {
          aux(right, value)
        }
      }
    }
  }

  aux(self.root, value)
}

pub fn to_string[T : Show + Compare](self : MutableSet[T]) -> String {
  match self.root {
    Empty(_) => "MutableSet::[]"
    _ => {
      let linear = self.to_array()
      let len = linear.length()
      for i = 0, str = "MutableSet::["; i < len - 1; {
        continue i + 1, str + linear[i].to_string() + ", "
      } else {
        str + linear[len - 1].to_string() + "]"
      }
    }
  }
}

fn balance[T : Compare](tree : NodeImpl[T]) -> Unit {
  match tree {
    {
      color: Black,
      left: Node(
        {
          color: Red,
          left: Node({ color: Red, left: a, value: x, right: b }),
          value: y,
          right: c,
        }
      ),
      value: z,
      right: d,
    }
    | {
      color: Black,
      left: Node(
        {
          color: Red,
          left: a,
          value: x,
          right: Node({ color: Red, left: b, value: y, right: c }),
        }
      ),
      value: z,
      right: d,
    }
    | {
      color: Black,
      left: a,
      value: x,
      right: Node(
        {
          color: Red,
          left: Node({ color: Red, left: b, value: y, right: c }),
          value: z,
          right: d,
        }
      ),
    }
    | {
      color: Black,
      left: a,
      value: x,
      right: Node(
        {
          color: Red,
          left: b,
          value: y,
          right: Node({ color: Red, left: c, value: z, right: d }),
        }
      ),
    } => {
      tree.color = Red
      tree.left = Node({ color: Black, left: a, value: x, right: b })
      tree.value = y
      tree.right = Node({ color: Black, left: c, value: z, right: d })
    }
    _ => ()
  }
}

// test "disjoint" {
//   inspect(
//     MutableSet::[1, 2, 3].disjoint(MutableSet::[4, 5, 6]),
//     ~content="true",
//   )?
//   inspect(
//     MutableSet::[1, 2, 3].subset(MutableSet::[3, 4, 5]),
//     ~content="false",
//   )?
// }

// test "subset" {
//   inspect(
//     MutableSet::[1, 2, 3].subset(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
//     ~content="true",
//   )?
//   inspect(
//     MutableSet::[1, 2, 3].subset(MutableSet::[10, 11, 12, 13, 14]),
//     ~content="false",
//   )?
// }

// test "diff" {
//   inspect(
//     MutableSet::[1, 2, 3].diff(MutableSet::[4, 5, 1]),
//     ~content="MutableSet::[2, 3]",
//   )?
// }

// test "inter" {
//   inspect(
//     MutableSet::[3, 4, 5].inter(MutableSet::[4, 5, 6]),
//     ~content="MutableSet::[4, 5]",
//   )?
// }

// test "union" {
//   inspect(
//     MutableSet::[3, 4, 5].union(MutableSet::[4, 5, 6]),
//     ~content="MutableSet::[3, 4, 5, 6]",
//   )?
// }

// test "map" {
//   inspect(
//     MutableSet::[1, 2, 3, 4, 5].map(fn(x) { x * 2 }),
//     ~content="MutableSet::[2, 4, 6, 8, 10]",
//   )?
// }

// test "forall" {
//   inspect(MutableSet::[2, 4, 6].forall(fn(v) { v % 2 == 0 }), ~content="true")?
//   inspect(
//     MutableSet::[1, 3, 5].forall(fn(v) { v % 2 == 0 }),
//     ~content="false",
//   )?
// }

// test "exists" {
//   inspect(MutableSet::[1, 4, 3].exists(fn(v) { v % 2 == 0 }), ~content="true")?
//   inspect(
//     MutableSet::[1, 5, 3].exists(fn(v) { v % 2 == 0 }),
//     ~content="false",
//   )?
// }

// test "fold" {
//   inspect(
//     MutableSet::[1, 2, 3, 4, 5].fold(~init=0, fn(acc, x) { acc + x }),
//     ~content="15",
//   )?
// }

// test "filter" {
//   inspect(
//     MutableSet::[1, 2, 3, 4, 5, 6].filter(fn(v) { v % 2 == 0 }),
//     ~content="MutableSet::[2, 4, 6]",
//   )?
// }

// test "max" {
//   inspect(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].max(), ~content="9")?
// }

// test "split" {
//   let (left, present, right) = MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].split(
//     5,
//   )
//   inspect(present, ~content="true")?
//   inspect(left, ~content="MutableSet::[1, 2, 3, 4]")?
//   inspect(right, ~content="MutableSet::[6, 7, 8, 9]")?
//   let (left, present, right) = MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].split(
//     0,
//   )
//   inspect(present, ~content="false")?
//   inspect(left, ~content="MutableSet::[]")?
//   inspect(right, ~content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
// }

// test "contains" {
//   inspect(
//     MutableSet::[7, 2, 9, 4, 6, 3, 8, 1].add(5).contain(5),
//     ~content="true",
//   )?
//   inspect(MutableSet::[7, 2, 9, 4, 6, 3, 8, 1].contain(5), ~content="false")?
// }

// test "from_list" {
//   inspect(MutableSet::from_list(List::[1]), ~content="MutableSet::[1]")?
//   inspect(MutableSet::from_list(List::[1, 2]), ~content="MutableSet::[1, 2]")?
//   inspect(
//     MutableSet::from_list(List::[1, 2, 3]),
//     ~content="MutableSet::[1, 2, 3]",
//   )?
//   inspect(
//     MutableSet::from_list(List::[1, 2, 3, 4]),
//     ~content="MutableSet::[1, 2, 3, 4]",
//   )?
//   inspect(
//     MutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
//     ~content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
//   )?
// }

test "to_list" {
  inspect(
    MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
    ~content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_array" {
  inspect(
    MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_array(),
    ~content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_vec" {
  inspect(
    MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_vec(),
    ~content="Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "from_array" {
  inspect(
    MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
    ~content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "add" {
  let set = MutableSet::[7, 2, 9, 4, 6, 3, 8, 1]
  set.add(5)
  inspect(set, ~content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
  let set = MutableSet::[2]
  set.add(1)
  inspect(set, ~content="MutableSet::[1, 2]")?
  let set = MutableSet::[2]
  set.add(3)
  inspect(set, ~content="MutableSet::[2, 3]")?
  let set = MutableSet::[2]
  set.add(1)
  set.add(3)
  inspect(set, ~content="MutableSet::[1, 2, 3]")?
  let set = MutableSet::[1, 2]
  set.add(1)
  inspect(set, ~content="MutableSet::[1, 2]")?
  let set = MutableSet::[2, 3]
  set.add(3)
  inspect(set, ~content="MutableSet::[2, 3]")?
  let set = MutableSet::[1, 2, 3]
  set.add(1)
  inspect(set, ~content="MutableSet::[1, 2, 3]")?
  let set = MutableSet::[1, 2, 3]
  set.add(3)
  inspect(set, ~content="MutableSet::[1, 2, 3]")?
  let set = MutableSet::[1]
  set.add(2)
  set.add(2)
  inspect(set, ~content="MutableSet::[1, 2]")?
}

// test "remove" {
//   inspect(
//     MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].remove(8),
//     ~content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 9]",
//   )?
// }

test "is_empty" {
  inspect((MutableSet::[] : MutableSet[Int]).is_empty(), ~content="true")?
  inspect(MutableSet::[1].is_empty(), ~content="false")?
}

test "to_string" {
  inspect(MutableSet::[1, 2, 3, 4, 5], ~content="MutableSet::[1, 2, 3, 4, 5]")?
  inspect((MutableSet::[] : MutableSet[Int]), ~content="MutableSet::[]")?
}
