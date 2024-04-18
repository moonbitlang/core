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
  { root: None }
}

/// Returns the one-value MutableSet containing only `value`.
pub fn MutableSet::singleton[T : Compare + Show](value : T) -> MutableSet[T] {
  {
    root: Some(
      {
        color: Black,
        left: None,
        value: Some(value),
        right: None,
        parent: None,
      },
    ),
  }
}

/// Initialize an MutableSet[T] from a Array[T]
pub fn MutableSet::from_array[T : Compare + Show](
  array : Array[T]
) -> MutableSet[T] {
  let set = MutableSet::new()
  for i = 0; i < array.length(); i = i + 1 {
    set.add(array[i])
  }
  set
}

/// Convert MutableSet[T] to List[T], the result must be ordered.
pub fn to_list[T : Compare + Show](self : MutableSet[T]) -> List[T] {
  fn aux(set : Option[Node[T]], list : List[T]) {
    match set {
      None => list
      Some(node) =>
        match node.value {
          None => list
          Some(value) => aux(node.left, Cons(value, aux(node.right, list)))
        }
    }
  }

  aux(self.root, Nil)
}

/// Convert MutableSet[T] to Array[T], the result must be ordered.
pub fn to_array[T : Compare + Show](self : MutableSet[T]) -> Array[T] {
  fn aux(set : Option[Node[T]]) {
    match set {
      None => []
      Some(node) =>
        match node.value {
          Some(value) => aux(node.left) + [value] + aux(node.right)
          None => []
        }
    }
  }

  aux(self.root)
}

/// Convert MutableSet[T] to Vec[T], the result must be ordered.
pub fn to_vec[T : Compare + Show](self : MutableSet[T]) -> @vec.Vec[T] {
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
pub fn add[T : Compare + Show](self : MutableSet[T], value : T) -> Unit {
  fn aux(n : Option[Node[T]], value : T) -> Unit {
    match n {
      None => abort("Impossible to reach")
      Some(node) => {
        let compare_result = value.compare(get_value(n))
        if compare_result == 0 {
          ()
        } else if compare_result < 0 {
          if is_leaf(node.left) {
            let l = new_node(Red, value, n)
            node.left = Some(l)
            balance(node)
          } else {
            aux(node.left, value)
            balance(node)
          }
        } else if is_leaf(node.right) {
          let r = new_node(Red, value, n)
          node.right = Some(r)
          balance(node)
        } else {
          aux(node.right, value)
          balance(node)
        }
      }
    }
  }

  match self.root {
    None => self.root = Some(new_node(Black, value, None))
    Some(_) => {
      aux(self.root, value)
      match self.root {
        Some(_) => set_color(self.root, Black)
        None => abort("Impossible to reach here")
      }
    }
  }
}

pub fn remove[T : Show + Compare](self : MutableSet[T], value : T) -> Unit {
  let mut y = search_node(self, value)
  let z = y
  if y == None {
    abort("Can't remove an element in the set that does not exist.")
  }
  let mut y_original_color = get_color(y)
  let z_right = get_right(z)
  let mut x = Option::None
  if is_leaf(get_left(z)) {
    x = z_right
    transplant(self, z, z_right)
  } else if is_leaf(z_right) {
    x = get_left(z)
    transplant(self, z, x)
  } else {
    y = min_node(z_right)
    y_original_color = get_color(y)
    x = get_right(y)
    if same_pointer(get_parent(y), z) {
      set_parent(x, y)
    } else {
      transplant(self, y, get_right(y))
      set_right(y, z_right)
      set_parent(get_right(y), y)
    }
    transplant(self, z, y)
    set_left(y, get_left(z))
    set_parent(get_left(y), y)
    set_color(y, get_color(z))
  }
  if y_original_color == Black {
    remove_fix(self, x)
  }
}

/// Returns true if MutableSet is empty
pub fn is_empty[T : Compare + Show](self : MutableSet[T]) -> Bool {
  match self.root {
    None => true
    _ => false
  }
}

/// Return true if value contain in MutableSet
pub fn contains[T : Compare + Show](self : MutableSet[T], value : T) -> Bool {
  loop self.root, value {
    None, _ => false
    Some({ left, value: node_value, right, .. }) as n, value => {
      let compare_result = value.compare(get_value(n))
      if compare_result == 0 {
        true
      } else if compare_result < 0 {
        continue left, value
      } else {
        continue right, value
      }
    }
  }
}

fn to_array[T](self : Node[T]) -> Array[T] {
  fn aux(n : Option[Node[T]]) {
    match n {
      None => []
      _ =>
        if is_leaf(n) {
          []
        } else {
          aux(get_left(n)) + [get_value(n)] + aux(get_right(n))
        }
    }
  }

  aux(Some(self))
}

fn node_debug[T : Show](n : Option[Node[T]]) -> String {
  fn aux(node : Option[Node[T]]) -> String {
    match node {
      None => "()"
      Some(node) => {
        let left = aux(node.left)
        let right = aux(node.right)
        "(" + left + ") + " + node.value.to_string() + " + (" + right + ")"
      }
    }
  }

  aux(n)
}

fn to_string[T : Show](self : Node[T]) -> String {
  let linear = self.to_array()
  let len = linear.length()
  for i = 0, str = "MutableSet::["; i < len - 1; {
    continue i + 1, str + linear[i].to_string() + ", "
  } else {
    str + linear[len - 1].to_string() + "]"
  }
}

pub fn to_string[T : Show + Compare](self : MutableSet[T]) -> String {
  match self.root {
    None => "MutableSet::[]"
    Some(node) => node.to_string()
  }
}

fn balance[T : Compare + Show](parent : Node[T]) -> Unit {
  match parent {
    {
      color: Black,
      left: Some(
        {
          color: Red,
          left: Some({ color: Red, left: a, value: x, right: b, .. }),
          value: y,
          right: c,
          ..,
        }
      ),
      value: z,
      right: d,
      ..,
    }
    | {
      color: Black,
      left: Some(
        {
          color: Red,
          left: a,
          value: x,
          right: Some({ color: Red, left: b, value: y, right: c, .. }),
          ..,
        }
      ),
      value: z,
      right: d,
      ..,
    }
    | {
      color: Black,
      left: a,
      value: x,
      right: Some(
        {
          color: Red,
          left: Some({ color: Red, left: b, value: y, right: c, .. }),
          value: z,
          right: d,
          ..,
        }
      ),
      ..,
    }
    | {
      color: Black,
      left: a,
      value: x,
      right: Some(
        {
          color: Red,
          left: b,
          value: y,
          right: Some({ color: Red, left: c, value: z, right: d, .. }),
          ..,
        }
      ),
      ..,
    } => {
      parent.color = Red
      parent.left = Some(new_node_full(Black, a, x, b, Some(parent)))
      set_parent(a, parent.left)
      set_parent(b, parent.left)
      parent.value = y
      parent.right = Some(
        { color: Black, left: c, value: z, right: d, parent: Some(parent) },
      )
      set_parent(c, parent.right)
      set_parent(d, parent.right)
    }
    _ => ()
  }
}

fn search_node[T : Compare + Show](
  tree : MutableSet[T],
  value : T
) -> Option[Node[T]] {
  let mut ret = Option::None
  loop tree.root, value {
    Some({ left, value: node_value, right, .. }) as n, value => {
      if node_value == None {
        return None
      }
      let compare_result = value.compare(get_value(n))
      if compare_result == 0 {
        ret
      } else if compare_result < 0 {
        ret = left
        continue left, value
      } else {
        ret = right
        continue right, value
      }
    }
    None, _ => None
  }
}

fn transplant[T](
  tree : MutableSet[T],
  u : Option[Node[T]],
  v : Option[Node[T]]
) -> Unit {
  match u {
    None => abort("Impossible to reach") // why transplant an empty tree?
    Some(u_inner) => {
      match u_inner.parent {
        None => tree.root = v
        Some(u_parent) =>
          if physical_equal(u, u_parent.left) {
            u_parent.left = v
          } else {
            u_parent.right = v
          }
      }
      set_parent(v, u_inner.parent)
    }
  }
}

fn same_pointer[T](x : Option[Node[T]], y : Option[Node[T]]) -> Bool {
  match (x, y) {
    (None, None) => true
    (Some(x), Some(y)) => physical_equal(x, y)
    (_, _) => false
  }
}

fn get_left[T](x : Option[Node[T]]) -> Option[Node[T]] {
  match x {
    None => abort("Impossible to reach") // why get left of an empty tree?
    Some({ left, .. }) => left
  }
}

fn set_left[T](x : Option[Node[T]], left : Option[Node[T]]) -> Unit {
  match x {
    None => abort("Impossible to reach") // why set left of an empty tree?
    Some(tree) => tree.left = left
  }
}

fn get_right[T](x : Option[Node[T]]) -> Option[Node[T]] {
  match x {
    None => abort("Impossible to reach") // why get right of an empty tree?
    Some({ right, .. }) => right
  }
}

fn set_right[T](x : Option[Node[T]], right : Option[Node[T]]) -> Unit {
  match x {
    None => abort("Impossible to reach") // why set right of an empty tree?
    Some(tree) => tree.right = right
  }
}

fn rotate_left[T](root : MutableSet[T], x : Option[Node[T]]) -> Unit {
  let y = get_right(x)
  set_right(x, get_left(y))
  set_parent(get_left(y), x)
  let x_parent = get_parent(x)
  set_parent(y, x_parent)
  match x_parent {
    None => root.root = y
    Some(_) =>
      if same_pointer(x, get_left(x_parent)) {
        set_left(x_parent, y)
      } else {
        set_right(x_parent, y)
      }
  }
  set_left(y, x)
  set_parent(x, y)
}

fn rotate_right[T](root : MutableSet[T], x : Option[Node[T]]) -> Unit {
  let y = get_left(x)
  set_left(x, get_right(y))
  set_parent(get_right(y), x)
  let x_parent = get_parent(x)
  set_parent(y, x_parent)
  match x_parent {
    None => root.root = y
    Some(_) =>
      if same_pointer(x, get_right(x_parent)) {
        set_right(x_parent, y)
      } else {
        set_left(x_parent, y)
      }
  }
  set_right(y, x)
  set_parent(x, y)
}

fn remove_fix[T : Show](root : MutableSet[T], x : Option[Node[T]]) -> Unit {
  let mut x = x
  while not(same_pointer(x, root.root)) && get_color(x) == Black {
    let x_parent = get_parent(x)
    if same_pointer(x, get_left(x_parent)) {
      let mut w = get_right(x_parent)
      if get_color(w) == Red {
        set_color(w, Black)
        set_color(x_parent, Red)
        rotate_left(root, x_parent)
        w = get_right(x_parent)
      }
      if get_color(get_left(w)) == Black && get_color(get_right(w)) == Black {
        set_color(w, Red)
        x = x_parent
      } else {
        if get_color(get_right(w)) == Black {
          set_color(get_left(w), Black)
          set_color(w, Red)
          rotate_right(root, w)
          w = get_right(x_parent)
        }
        set_color(w, get_color(x_parent))
        set_color(x_parent, Black)
        set_color(get_right(w), Black)
        rotate_left(root, x_parent)
        x = root.root
      }
    } else {
      let mut w = get_left(x_parent)
      if get_color(w) == Red {
        set_color(w, Black)
        set_color(x_parent, Red)
        rotate_right(root, x_parent)
        w = get_left(x_parent)
      }
      if get_color(get_right(w)) == Black && get_color(get_left(w)) == Black {
        set_color(w, Red)
        x = x_parent
      } else {
        if get_color(get_left(w)) == Black {
          set_color(get_right(w), Black)
          set_color(w, Red)
          rotate_left(root, w)
          w = get_left(x_parent)
        }
        set_color(w, get_color(x_parent))
        set_color(x_parent, Black)
        set_color(get_left(w), Black)
        rotate_right(root, x_parent)
        x = root.root
      }
    }
  }
  set_color(x, Black)
}

fn new_node[T](color : Color, value : T, parent : Option[Node[T]]) -> Node[T] {
  let left = {
    color: Black,
    left: None,
    value: None,
    right: None,
    parent: None,
  }
  let right = {
    color: Black,
    left: None,
    value: None,
    right: None,
    parent: None,
  }
  let ret = {
    color,
    left: Some(left),
    value: Some(value),
    right: Some(right),
    parent,
  }
  set_parent(ret.left, Some(ret))
  set_parent(ret.right, Some(ret))
  ret
}

fn new_node_full[T](
  color : Color,
  left : Option[Node[T]],
  value : Option[T],
  right : Option[Node[T]],
  parent : Option[Node[T]]
) -> Node[T] {
  { color, left, value, right, parent }
}

// @alert unsafe "Panic if called on an empty set.""
fn min[T : Compare + Show](tree : Option[Node[T]]) -> T {
  let mut rt = match tree {
    None => abort("Impossible to reach") // why get min of an empty tree?
    Some(tree) =>
      match tree.value {
        None => abort("Impossible to reach") // why get min of an empty tree?
        Some(value) => value
      }
  }
  loop tree {
    None => rt
    Some({ left, value, .. }) => {
      rt = match value {
        None => rt
        Some(value) => value
      }
      continue left
    }
  }
}

// @alert unsafe "Panic if called on an empty set.""
fn min_node[T : Compare + Show](tree : Option[Node[T]]) -> Option[Node[T]] {
  let mut rt = tree
  loop tree {
    None => rt
    Some({ left, .. }) =>
      match left {
        None => rt
        Some(_) => {
          if not(is_leaf(left)) {
            rt = left
          }
          continue left
        }
      }
  }
}

fn get_parent[T](x : Option[Node[T]]) -> Option[Node[T]] {
  match x {
    None => abort("Impossible to reach") // why get parent of an empty tree?
    Some(tree) => tree.parent
  }
}

fn set_parent[T](x : Option[Node[T]], parent : Option[Node[T]]) -> Unit {
  match x {
    None => ()
    Some(tree) => tree.parent = parent
  }
}

fn get_color[T : Show](tree : Option[Node[T]]) -> Color {
  match tree {
    None => Black
    Some({ color, .. }) => color
  }
}

fn set_color[T](tree : Option[Node[T]], color : Color) -> Unit {
  match tree {
    None => abort("Impossible to reach") // why set color of an empty tree?
    Some(tree) => tree.color = color
  }
}

fn get_node[T](node : Option[Node[T]], value : T) -> Node[T] {
  match node {
    None => abort("Impossible to reach")
    Some(node) => node
  }
}

fn debug_write[T : Show](self : Node[T], buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

fn is_leaf[T](node : Option[Node[T]]) -> Bool {
  match node {
    None => false
    Some(node) =>
      match node.value {
        None => true
        Some(_) => false
      }
  }
}

fn get_value[T](node : Option[Node[T]]) -> T {
  match node {
    None => abort("Impossible to reach") // why get value of an empty tree?
    Some({ value, .. }) =>
      match value {
        None => abort("Impossible to reach") // why get value of a leaf?
        Some(value) => value
      }
  }
}

fn set_value[T](node : Option[Node[T]], value : T) -> Unit {
  match node {
    None => abort("Impossible to reach") // why set value of an empty tree?
    Some(tree) => tree.value = Some(value)
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
    content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

// test "to_array" {
//   inspect(
//     MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_array(),
//     content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
//   )?
// }

// test "to_vec" {
//   inspect(
//     MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_vec(),
//     content="Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
//   )?
// }

// test "from_array" {
//   inspect(
//     MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
//     content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
//   )?
// }

test "add" {
  let set = MutableSet::[7, 2, 9, 4, 6, 3, 8, 1]
  set.add(5)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
  let set = MutableSet::[2]
  set.add(1)
  inspect(set, content="MutableSet::[1, 2]")?
  let set = MutableSet::[2]
  set.add(3)
  inspect(set, content="MutableSet::[2, 3]")?
  let set = MutableSet::[2]
  set.add(1)
  set.add(3)
  inspect(set, content="MutableSet::[1, 2, 3]")?
  let set = MutableSet::[1, 2]
  set.add(1)
  inspect(set, content="MutableSet::[1, 2]")?
  let set = MutableSet::[2, 3]
  set.add(3)
  inspect(set, content="MutableSet::[2, 3]")?
  let set = MutableSet::[1, 2, 3]
  set.add(1)
  inspect(set, content="MutableSet::[1, 2, 3]")?
  let set = MutableSet::[1, 2, 3]
  set.add(3)
  inspect(set, content="MutableSet::[1, 2, 3]")?
  let set = MutableSet::[1]
  set.add(2)
  set.add(2)
  inspect(set, content="MutableSet::[1, 2]")?
}

test "remove" {
  let set = MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1]
  set.remove(8)
  inspect(set, content="MutableSet::[1, 2, 3, 4, 5, 6, 7, 9]")?
}

// test "is_empty" {
//   inspect((MutableSet::[] : MutableSet[Int]).is_empty(), content="true")?
//   inspect(MutableSet::[1].is_empty(), content="false")?
// }

// test "to_string" {
//   inspect(MutableSet::[1, 2, 3, 4, 5], content="MutableSet::[1, 2, 3, 4, 5]")?
//   inspect((MutableSet::[] : MutableSet[Int]), content="MutableSet::[]")?
// }
