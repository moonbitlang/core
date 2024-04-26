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

pub fn PersistentVector::empty[T]() -> PersistentVector[T] {
  { tree: Tree::empty(), size: 0, shift: 0 }
}

pub fn to_string[T : Show](self : PersistentVector[T]) -> String {
  let mut s = "[".to_string()
  for i = 0; i < self.size; i = i + 1 {
    s = s + self[i].to_string()
    if i < self.size - 1 {
      s = s + ", "
    }
  }
  s = s + "]"
  s
}

test "to_string" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  let ve : PersistentVector[Int] = PersistentVector::empty()
  inspect(v, content="[1, 2, 3, 4, 5]")?
  inspect(ve, content="[]")?
}

pub fn is_empty[T](v : PersistentVector[T]) -> Bool {
  v.size == 0
}

pub fn length[T](v : PersistentVector[T]) -> Int {
  v.size
}

pub fn copy[T](self : PersistentVector[T]) -> PersistentVector[T] {
  fn copy(t : Tree[T]) -> Tree[T] {
    match t {
      Leaf(l) => Leaf(immutable_copy(l))
      Empty => Empty
      Node(node) =>
        Node(@array.new_with_index(node.length(), fn(i) { copy(node[i]) }))
    }
  }

  { tree: copy(self.tree), size: self.size, shift: self.shift }
}

test "copy" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  let vc = v.copy()
  inspect(vc, content="[1, 2, 3, 4, 5]")?
  inspect(v == vc, content="true")?
}

pub fn op_get[T](self : PersistentVector[T], index : Int) -> T {
  if index == 0 {
    self.tree.get_first()
  } else if index == self.size - 1 {
    self.tree.get_last()
  } else {
    self.tree.get(index, self.shift)
  }
}

test "op_get" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  inspect(v[0], content="1")?
  inspect(v[1], content="2")?
  inspect(v[2], content="3")?
  inspect(v[3], content="4")?
  inspect(v[4], content="5")?
}

pub fn set[T](
  self : PersistentVector[T],
  index : Int,
  value : T
) -> PersistentVector[T] {
  fn set(i : Int, e, s, t : Tree[T]) -> Tree[T] {
    match t {
      Leaf(l) => Leaf(immutable_set(l, i.land(bitmask), e))
      Node(node) => {
        let idx = i.lsr(s).land(bitmask)
        Node(immutable_set(node, idx, set(i, e, s - num_bits, node[idx])))
      }
      Empty => abort("Index out of bounds")
    }
  }

  {
    tree: set(index, value, self.shift, self.tree),
    size: self.size,
    shift: self.shift,
  }
}

test "set" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  let v1 = v.set(1, 10)
  let v2 = v.set(2, 10)
  inspect(v1, content="[1, 10, 3, 4, 5]")?
  inspect(v2, content="[1, 2, 10, 4, 5]")?
}

pub fn push[T](self : PersistentVector[T], value : T) -> PersistentVector[T] {
  if self.size == branching_factor.lsl(self.shift) {
    {
      tree: Node([self.tree, new_branch([value], self.shift)]),
      size: self.size + 1,
      shift: self.shift + num_bits,
    }
  } else {
    {
      tree: self.tree.add(self.size, self.shift, value),
      size: self.size + 1,
      shift: self.shift,
    }
  }
}

test "push" {
  let v = PersistentVector::empty().push(1).push(2).push(3)
  inspect(v, content="[1, 2, 3]")?
  inspect(v.push(1), content="[1, 2, 3, 1]")?
  inspect(v.push(2), content="[1, 2, 3, 2]")?
  inspect(v.push(3), content="[1, 2, 3, 3]")?
}

/// TODO : A more efficient implementation
pub fn PersistentVector::from_array[T](arr : Array[T]) -> PersistentVector[T] {
  let mut v = PersistentVector::empty()
  arr.iter(fn(e) { v = v.push(e) })
  v
}

test "from_array" {
  let v = PersistentVector::[1, 1, 4, 5, 1, 4]
  let vv = PersistentVector::from_array(Array::make(30, 1))
  inspect(v, content="[1, 1, 4, 5, 1, 4]")?
  inspect(
    vv,
    content="[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]",
  )?
}

pub fn iter[T](self : PersistentVector[T], f : (T) -> Unit) -> Unit {
  fn go(t : Tree[T]) -> Unit {
    match t {
      Empty => ()
      Leaf(l) => l.iter(f)
      Node(n) => n.iter(fn(t) { go(t) })
    }
  }

  go(self.tree)
}

test "iter" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  let mut s = 0
  v.iter(fn(e) { s = s + e })
  inspect(s, content="15")?
}

pub fn op_equal[T : Eq](
  self : PersistentVector[T],
  other : PersistentVector[T]
) -> Bool {
  if self.size != other.size {
    false
  } else {
    fn go(t1 : Tree[T], t2 : Tree[T]) -> Bool {
      match (t1, t2) {
        (Empty, Empty) => true
        (Leaf(l1), Leaf(l2)) => l1 == l2
        (Node(n1), Node(n2)) =>
          if n1.length() != n2.length() {
            false
          } else {
            for i = 0; i < n1.length(); i = i + 1 {
              if go(n1[i], n2[i]).not() {
                break false
              }
            } else {
              true
            }
          }
        _ => false
      }
    }

    go(self.tree, other.tree)
  }
}

test "op_equal" {
  let v1 = PersistentVector::[1, 2, 3, 4, 5]
  let v2 = PersistentVector::[1, 2, 3, 4, 5]
  let v3 = PersistentVector::[1, 2, 3, 4, 6]
  let v4 = PersistentVector::[1, 2, 3, 4]
  inspect(v1 == v2, content="true")?
  inspect(v1 == v3, content="false")?
  inspect(v1 == v4, content="false")?
}

pub fn fold_left[T](
  self : PersistentVector[T],
  f : (T, T) -> T,
  ~init : T
) -> T {
  fn go(t : Tree[T], acc : T) -> T {
    match t {
      Empty => acc
      Leaf(l) => l.fold_left(f, init=acc)
      Node(n) => n.fold_left(fn(t, acc) { go(acc, t) }, init=acc)
    }
  }

  go(self.tree, init)
}

test "fold_left" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  inspect(v.fold_left(fn(a, b) { a + b }, init=0), content="15")?
}

pub fn fold_right[T](
  self : PersistentVector[T],
  f : (T, T) -> T,
  ~init : T
) -> T {
  fn go(t : Tree[T], acc : T) -> T {
    match t {
      Empty => acc
      Leaf(l) => l.fold_right(f, init=acc)
      Node(n) => n.fold_right(fn(t, acc) { go(acc, t) }, init=acc)
    }
  }

  go(self.tree, init)
}

test "fold_right" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  inspect(v.fold_right(fn(a, b) { a + b }, init=0), content="15")?
}

pub fn map[T, U](
  self : PersistentVector[T],
  f : (T) -> U
) -> PersistentVector[U] {
  fn go(t : Tree[T]) -> Tree[U] {
    match t {
      Empty => Empty
      Leaf(l) => Leaf(l.map(f))
      Node(n) => Node(@array.new_with_index(n.length(), fn(i) { go(n[i]) }))
    }
  }

  { tree: go(self.tree), size: self.size, shift: self.shift }
}

test "map" {
  let v = PersistentVector::[1, 2, 3, 4, 5]
  inspect(v.map(fn(e) { e * 2 }), content="[2, 4, 6, 8, 10]")?
  inspect(v.map(fn(e) { e.to_string() }), content="[1, 2, 3, 4, 5]")?
  inspect(
    v.map(fn(e) { e % 2 == 0 }),
    content="[false, true, false, true, false]",
  )?
}
