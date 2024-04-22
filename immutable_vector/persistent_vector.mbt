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

pub fn is_empty[T](v : PersistentVector[T]) -> Bool {
  v.size == 0
}

pub fn length[T](v : PersistentVector[T]) -> Int {
  v.size
}

pub fn new_branch[T](leaf : Array[T], shift : Int) -> Tree[T] {
  match shift {
    0 => Leaf(leaf)
    s => Node([new_branch(leaf, s - num_bits)])
  }
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

pub fn op_get[T](self : PersistentVector[T], index : Int) -> T {
  if index == 0 {
    self.tree.get_first()
  } else if index == self.size - 1 {
    self.tree.get_last()
  } else {
    self.tree.get(index, self.shift)
  }
}

pub fn op_set[T](
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

pub fn push[T](self : PersistentVector[T], value : T) -> PersistentVector[T] {
  fn add(i : Int, e, s, t : Tree[T]) -> Tree[T] {
    match t {
      Leaf(l) => {
        let l1 = Array::make(l.length() + 1, value)
        array_blit(src=l, dst=l1, 0, 0, l.length())
        Leaf(l1)
      }
      Node(n) => {
        let ci = i.lsr(s).land(bitmask)
        if ci < n.length() {
          Node(immutable_set(n, ci, add(i, e, s - num_bits, n[ci])))
        } else {
          Node(immutable_push(n, new_branch([e], s - num_bits)))
        }
      }
      Empty => Leaf([e])
    }
  }

  if self.size == branching_factor.lsl(self.shift) {
    {
      tree: Node([self.tree, new_branch([value], self.shift)]),
      size: self.size + 1,
      shift: self.shift + num_bits,
    }
  } else {
    {
      tree: add(self.size, value, self.shift, self.tree),
      size: self.size + 1,
      shift: self.shift,
    }
  }
}

/// TODO : A more efficient implementation
pub fn PersistentVector::from_array[T](arr : Array[T]) -> PersistentVector[T] {
  let mut v = PersistentVector::empty()
  arr.iter(fn(e) { v = v.push(e) })
  v
}

test "from_array" {
  let v = PersistentVector::[1, 1, 4, 5, 1, 4]
  inspect(v, content="[1, 1, 4, 5, 1, 4]")?
}
