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

//-----------------------------------------------------------------------------
// Constructors (construct T or convert other types to T)
//-----------------------------------------------------------------------------

///|
/// Return a new empty array
pub fn T::new[A]() -> T[A] {
  { tree: Tree::empty(), size: 0, shift: 0 }
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
/// Convert a FixedArray to an @immut/array.
pub fn T::of[A](arr : FixedArray[A]) -> T[A] {
  makei(arr.length(), fn(i) { arr[i] })
}

///|
/// Physically copy the array.
/// Since it is an immutable data structure,
/// it is rarely the case that you would need this function.
pub fn copy[A](self : T[A]) -> T[A] {
  fn copy(t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(l.copy())
      Empty => Empty
      Node(node, sizes) =>
        Node(
          FixedArray::makei(node.length(), fn(i) { copy(node[i]) }),
          match sizes {
            Some(sizes) => Some(FixedArray::copy(sizes))
            None => None
          },
        )
    }
  }

  { tree: copy(self.tree), size: self.size, shift: self.shift }
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

//-----------------------------------------------------------------------------
// Convertor (convert T to other types)
//-----------------------------------------------------------------------------

///|
pub fn to_array[A](self : T[A]) -> Array[A] {
  let arr = []
  self.each(fn(v) { arr.push(v) })
  arr
}

///|
pub fn T::from_iter[A](iter : Iter[A]) -> T[A] {
  iter.fold(init=new(), fn(arr, e) { arr.push(e) })
}

//-----------------------------------------------------------------------------
// Properties
//-----------------------------------------------------------------------------

///|
pub fn is_empty[A](self : T[A]) -> Bool {
  self.size == 0
}

///|
pub fn length[A](self : T[A]) -> Int {
  self.size
}

//-----------------------------------------------------------------------------
// Lookup
//-----------------------------------------------------------------------------

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

//-----------------------------------------------------------------------------
// Modifier
//-----------------------------------------------------------------------------

///|
/// Set a value at the given index (immutable).
/// 
/// # Example
/// ```
/// let v = @array.of([1, 2, 3, 4, 5])
/// assert_eq!(v.set(1, 10), @array.of([1, 10, 3, 4, 5]))
/// ```
pub fn set[A](self : T[A], index : Int, value : A) -> T[A] {
  {
    tree: self.tree.set(index, self.shift, value),
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
  let (tree, shift) = self.tree.push_end(self.shift, value)
  { tree, size: self.size + 1, shift }
}

///|
/// Given two trees, concatenate them into a new tree.
pub fn T::concat[A](self : T[A], other : T[A]) -> T[A] {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let (tree, shift) = concat(
    self.tree,
    self.shift,
    other.tree,
    other.shift,
    true,
  )
  { tree, size: self.size + other.size, shift }
}
//-----------------------------------------------------------------------------
// Iterators
//-----------------------------------------------------------------------------

///|
/// Return an iterator over the array.
pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    let arr = self.to_array() // TODO: it first converts to an array, which is not efficient
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
  self.tree.each(f)
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
  self.tree.eachi(f, self.shift, 0)
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
  self.tree.fold(init, f)
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
  self.tree.rev_fold(init, f)
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
/// @coverage.skip
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
/// @coverage.skip
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
  { tree: self.tree.map(f), size: self.size, shift: self.shift }
}

//-----------------------------------------------------------------------------
// Common Traits Implementation
//-----------------------------------------------------------------------------

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

///|
pub impl[A : Eq] Eq for T[A] with op_equal(self, other) {
  self.size == other.size && self.tree == other.tree
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/array.of([", suffix="])")
}

//-----------------------------------------------------------------------------
// For Internal Use
//-----------------------------------------------------------------------------

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

      // Use None here because the implementation of `new_by_leaves` ensures that the tree is full
      // and we can use radix indexing.
      Node(FixedArray::makei(child_count, child), None)
    }
  }

  if len == 0 {
    T::new()
  } else {
    let (cap, shift) = loop len, branching_factor, 1 {
      len, m_pow, depth =>
        match len <= m_pow {
          false => continue len, m_pow * branching_factor, depth + 1
          true => (m_pow, (depth - 1) * num_bits)
        }
    }
    { shift, tree: tree(cap, len, 0), size: len }
  }
}

///|
/// Print the tree structure of the internal tree. For debug use.
fn to_debug_string[A : Show](self : T[A]) -> String {
  self.tree.to_string()
}
