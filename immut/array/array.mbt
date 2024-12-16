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

///|
/// Return a new empty array
pub fn T::new[A]() -> T[A] {
  { tree: Tree::empty(), size: 0, shift: 0 }
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/array.of([", suffix="])")
}

///|
pub fn is_empty[A](self : T[A]) -> Bool {
  self.size == 0
}

///|
pub fn to_array[A](self : T[A]) -> Array[A] {
  let arr = []
  self.each(fn(v) { arr.push(v) })
  arr
}

///|
pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    let arr = self.to_array()
    for i = 0; i < self.size; i = i + 1 {
      if yield_(arr[i]) == IterEnd {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
pub fn T::from_iter[A](iter : Iter[A]) -> T[A] {
  iter.fold(init=new(), fn(arr, e) { arr.push(e) })
}

///|
pub fn length[A](self : T[A]) -> Int {
  self.size
}

///|
pub fn copy[A](self : T[A]) -> T[A] {
  fn copy(t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(l.copy())
      Empty => Empty
      Node(node) =>
        Node(FixedArray::makei(node.length(), fn(i) { copy(node[i]) }))
    }
  }

  { tree: copy(self.tree), size: self.size, shift: self.shift }
}

///|
/// Get a value at the given index.
/// 
/// # Examples
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v[0], 1)
/// ```
pub fn op_get[A](self : T[A], index : Int) -> A {
  if index == 0 {
    self.tree.get_first()
  } else if index == self.size - 1 {
    self.tree.get_last()
  } else {
    self.tree.get(index, self.shift)
  }
}

///|
/// Set a value at the given index (immutable).
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v.set(1, 10), @array.of([1, 10, 3, 4, 5]))
/// ```
pub fn set[A](self : T[A], index : Int, value : A) -> T[A] {
  fn set(i : Int, e, s, t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(immutable_set(l, i & bitmask, e))
      Node(node) => {
        let idx = shr_as_uint(i, s) & bitmask
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

///|
/// Push a value to the end of the array.
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3])
/// assert_eq!(v.push(4), @array.of([1, 2, 3, 4]))
/// ```
pub fn push[A](self : T[A], value : A) -> T[A] {
  if self.size == (branching_factor << self.shift) {
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

///|
/// Create a persistent array from an array.
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3])
/// assert_eq!(v, @array.from_array([1, 2, 3]))
/// ```
pub fn T::from_array[A](arr : Array[A]) -> T[A] {
  makei(arr.length(), fn(i) { arr[i] })
}

///|
/// Iterate over the array.
/// 
/// # Example
/// ```
/// let arr = []
/// let v = @array.of([1, 2, 3, 4, 5])
/// v.each(fn(e) { arr.push(e) })
/// assert_eq!(arr, [1, 2, 3, 4, 5])
/// ```
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
  fn go(t : Tree[A]) -> Unit {
    match t {
      Empty => ()
      Leaf(l) => l.each(f)
      Node(n) => n.each(fn(t) { go(t) })
    }
  }

  go(self.tree)
}

///|
/// Iterate over the array with index.
/// 
/// # Example
/// ```
/// let arr = []
/// let v = @array.of([1, 2, 3, 4, 5])
/// v.eachi(fn(i, e) { arr.push(i * e) })
/// assert_eq!(arr, [0, 2, 6, 12, 20])
/// ```
pub fn eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  fn go(t : Tree[A], shift : Int, start : Int) -> Unit {
    match t {
      Empty => ()
      Leaf(l) =>
        for i = 0; i < l.length(); i = i + 1 {
          f(start + i, l[i])
        }
      Node(n) => {
        let child_shift = shift - num_bits
        let mut start = start
        for i = 0; i < n.length(); i = i + 1 {
          go(n[i], child_shift, start)
          start += 1 << shift
        }
      }
    }
  }

  go(self.tree, self.shift, 0)
}

///|
pub impl[A : Eq] Eq for T[A] with op_equal(self, other) {
  self.size == other.size && self.tree == other.tree
}

///|
/// Fold the array.
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v.fold(fn(a, b) { a + b }, init=0), 15)
/// ```
pub fn fold[A, B](self : T[A], init~ : B, f : (B, A) -> B) -> B {
  fn go(t : Tree[A], acc : B) -> B {
    match t {
      Empty => acc
      Leaf(l) => l.fold(f, init=acc)
      Node(n) => n.fold(fn(t, acc) { go(acc, t) }, init=acc)
    }
  }

  go(self.tree, init)
}

///|
/// Fold the array in reverse order.
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v.rev_fold(fn(a, b) { a + b }, init=0), 15)
/// ```
pub fn rev_fold[A, B](self : T[A], init~ : B, f : (B, A) -> B) -> B {
  fn go(t : Tree[A], acc : B) -> B {
    match t {
      Empty => acc
      Leaf(l) => l.rev_fold(f, init=acc)
      Node(n) => n.rev_fold(fn(t, acc) { go(acc, t) }, init=acc)
    }
  }

  go(self.tree, init)
}

///|
/// Fold the array from left to right.
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v.fold(fn(a, b) { a + b }, init=0), 15)
/// ```
/// @alert deprecated "Use `fold` instead"
pub fn fold_left[A](self : T[A], f : (A, A) -> A, init~ : A) -> A {
  self.fold(init~, f)
}

///|
/// Fold the array from right to left.
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v.rev_fold(fn(a, b) { a + b }, init=0), 15)
/// ```
/// @alert deprecated "Use `rev_fold` instead"
pub fn fold_right[A](self : T[A], f : (A, A) -> A, init~ : A) -> A {
  self.rev_fold(init~, f)
}

///|
/// Map a function over the array.
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v.map(fn(e) { e * 2 }), @array.of([2, 4, 6, 8, 10]))
/// ```
pub fn map[A, B](self : T[A], f : (A) -> B) -> T[B] {
  fn go(t : Tree[A]) -> Tree[B] {
    match t {
      Empty => Empty
      Leaf(l) => Leaf(l.map(f))
      Node(n) => Node(FixedArray::makei(n.length(), fn(i) { go(n[i]) }))
    }
  }

  { tree: go(self.tree), size: self.size, shift: self.shift }
}

///|
fn new_by_leaves[A](len : Int, gen_leaf : (Int, Int) -> FixedArray[A]) -> T[A] {
  fn tree(cap, len, s) -> Tree[A] {
    if cap == branching_factor {
      Leaf(gen_leaf(s, len))
    } else {
      let child_cap = cap / branching_factor
      let part = len / child_cap
      let (child_count, last_child_len) = match len % child_cap {
        0 => (part, child_cap)
        r => (part + 1, r)
      }
      fn child(k) {
        let i = s + k * child_cap
        let len = if k + 1 == child_count { last_child_len } else { child_cap }
        tree(cap / branching_factor, len, i)
      }

      Node(FixedArray::makei(child_count, child))
    }
  }

  if len == 0 {
    T::new()
  } else {
    let (cap, shift) = loop len, branching_factor, 1 {
      len, m_pow, depth =>
        match len < m_pow {
          false => continue len, m_pow * branching_factor, depth + 1
          true => (m_pow, (depth - 1) * num_bits)
        }
    }
    { shift, tree: tree(cap, len, 0), size: len }
  }
}

test "new_by_leaves" {
  let e : T[Int] = new_by_leaves(0, fn(_s, _l) { abort("never reach") })
  let v = new_by_leaves(5, fn(_s, l) { FixedArray::make(l, 1) })
  let v2 = new_by_leaves(33, fn(_s, l) { FixedArray::make(l, 10) })
  inspect!(e, content="@immut/array.of([])")
  inspect!(v, content="@immut/array.of([1, 1, 1, 1, 1])")
  inspect!(
    v2,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
  let v3 = new_by_leaves(32, fn(_s, l) { FixedArray::make(l, 10) })
  inspect!(
    v3,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
}

///|
/// Create a persistent array with a given length and value.
pub fn T::make[A](len : Int, value : A) -> T[A] {
  new_by_leaves(len, fn(_s, l) { FixedArray::make(l, value) })
}

///|
/// Create a persistent array with a given length and a function to generate values.
pub fn T::makei[A](len : Int, f : (Int) -> A) -> T[A] {
  new_by_leaves(len, fn(s, l) { FixedArray::makei(l, fn(i) { f(s + i) }) })
}

///|
pub fn T::of[A](arr : FixedArray[A]) -> T[A] {
  makei(arr.length(), fn(i) { arr[i] })
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub impl[A : Hash] Hash for T[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

test "mix" {
  let mut v = T::new()
  inspect!(v.tree.is_empty_tree(), content="true")
  for i = 0; i < 100; i = i + 1 {
    v = v.push(i)
  }
  inspect!(
    v,
    content="@immut/array.of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99])",
  )
  let mut v2 = v.copy()
  for i = 0; i < 100; i = i + 1 {
    v2 = v2.set(i, i * 2)
  }
  let mut ct = 0
  v.each(fn(e) { ct = ct + e })
  inspect!(ct, content="4950")
  v2.each(fn(e) { ct = ct + e })
  inspect!(ct, content="14850")
  v2 = v2.map(fn(e) { e * 2 })
  let ct1 = fold(v2, fn(a, b) { a + b }, init=0)
  let ct2 = rev_fold(v2, fn(a, b) { a + b }, init=0)
  inspect!(ct1, content="19800")
  inspect!(ct2, content="19800")
  inspect!(v.tree.is_empty_tree(), content="false")
  let large_const = branching_factor * branching_factor + 1
  let mut v = T::new()
  for i = 0; i < large_const; i = i + 1 {
    v = v.push(i)
  }
  let vec = []
  v.eachi(fn(i, _e) { vec.push(i) })
  for i = 0; i < large_const; i = i + 1 {
    assert_eq!(vec[i], i)
  }
}
