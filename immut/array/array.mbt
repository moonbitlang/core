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

//-----------------------------------------------------------------------------
// Constructors (construct T or convert other types to T)
//-----------------------------------------------------------------------------

///|
/// Return a new empty array
#as_free_fn
pub fn[A] T::new() -> T[A] {
  { tree: Tree::empty(), size: 0, shift: 0 }
}

///|
/// Create a persistent array with a given length and value.
#as_free_fn
pub fn[A] T::make(len : Int, value : A) -> T[A] {
  let quot = len / branching_factor
  let rem = len % branching_factor
  let leaves = if rem == 0 {
    Array::make(quot, FixedArray::make(branching_factor, value))
  } else {
    let arr : Array[FixedArray[A]] = Array::make(
      quot + 1,
      FixedArray::make(branching_factor, value),
    )
    arr[quot] = FixedArray::make(rem, value)
    arr
  }
  let size = len
  let (shift, cap) = shift_cap_of_size(size)
  let tree = if size == 0 { Empty } else { from_leaves(leaves[:], cap) }
  { shift, tree, size }
}

///|
/// Create a persistent array with a given length and a function to generate values.
#as_free_fn
pub fn[A] T::makei(len : Int, f : (Int) -> A raise?) -> T[A] raise? {
  let quot = len / branching_factor
  let rem = len % branching_factor
  let leaves = if rem == 0 {
    Array::makei(quot, k => FixedArray::makei(branching_factor, i => f(
      k * branching_factor + i,
    )))
  } else {
    let arr : Array[FixedArray[A]] = Array::make(quot + 1, [])
    for k in 0..<quot {
      arr[k] = FixedArray::makei(branching_factor, i => f(
        k * branching_factor + i,
      ))
    }
    arr[quot] = FixedArray::makei(rem, i => f(quot * branching_factor + i))
    arr
  }
  let size = len
  let (shift, cap) = shift_cap_of_size(size)
  let tree = if size == 0 { Empty } else { from_leaves(leaves[:], cap) }
  { shift, tree, size }
}

///|
/// Convert a FixedArray to an @immut/array.
#as_free_fn
pub fn[A] T::of(arr : FixedArray[A]) -> T[A] {
  makei(arr.length(), i => arr[i])
}

///|
/// Physically copy the array.
/// Since it is an immutable data structure,
/// it is rarely the case that you would need this function.
/// 
#deprecated("We don't copy immutable array")
#coverage.skip
pub fn[A] copy(self : T[A]) -> T[A] {
  fn copy(t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(l.copy())
      Empty => Empty
      Node(node, sizes) =>
        Node(
          FixedArray::makei(node.length(), i => copy(node[i])),
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
/// ```mbt
///   let v = @array.of([1, 2, 3])
///   assert_eq(v, @array.from_array([1, 2, 3]))
/// ```
#as_free_fn
pub fn[A] T::from_array(arr : Array[A]) -> T[A] {
  makei(arr.length(), i => arr[i])
}

///|
#as_free_fn
pub fn[A] T::from_iter(iter : Iter[A]) -> T[A] {
  let mut buf : FixedArray[A] = []
  let mut index = 0
  let leaves = []
  iter.each(x => if index == 0 {
    buf = FixedArray::make(branching_factor, x)
    index += 1
  } else if index < branching_factor {
    buf[index] = x
    index += 1
  } else {
    leaves.push(buf)
    index = 1
    buf = FixedArray::make(branching_factor, x)
  })
  if index == branching_factor {
    leaves.push(buf)
  } else if index > 0 {
    let res = FixedArray::make(index, buf[0])
    buf.blit_to(res, len=index)
    leaves.push(res)
  }
  let size = leaves.fold(init=0, (acc, xs) => acc + xs.length())
  let (shift, cap) = shift_cap_of_size(size)
  let tree = if size == 0 { Empty } else { from_leaves(leaves[:], cap) }
  { shift, tree, size }
}

//-----------------------------------------------------------------------------
// Converter (convert T to other types)
//-----------------------------------------------------------------------------

///|
pub fn[A] to_array(self : T[A]) -> Array[A] {
  if self.is_empty() {
    []
  } else {
    let arr = Array::make(self.length(), self[0])
    self.eachi((i, v) => arr[i] = v)
    arr
  }
}

//-----------------------------------------------------------------------------
// Properties
//-----------------------------------------------------------------------------

///|
pub fn[A] is_empty(self : T[A]) -> Bool {
  self.size == 0
}

///|
pub fn[A] length(self : T[A]) -> Int {
  self.size
}

//-----------------------------------------------------------------------------
// Lookup
//-----------------------------------------------------------------------------

///|
/// Get a value at the given index.
///
/// # Examples
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   inspect(v[0], content="1")
/// ```
pub fn[A] op_get(self : T[A], index : Int) -> A {
  if index == 0 {
    self.tree.get_first()
  } else if index == self.size - 1 {
    self.tree.get_last()
  } else {
    self.tree.get(index, self.shift)
  }
}

///|
/// Returns the element at the specified index in the array, wrapped in an
/// `Option` type.
///
/// Parameters:
///
/// * `array` : The immutable array.
/// * `index` : The index of the element to retrieve.
///
/// Returns `Some(value)` if the index is valid, `None` if the index is out of
/// bounds.
///
/// Example:
///
/// ```moonbit
///   let v = @array.of([1, 2, 3])
///   inspect(v.get(1), content="Some(2)")
///   inspect(v.get(-1), content="None")
///   inspect(v.get(3), content="None")
/// ```
pub fn[A] get(self : T[A], index : Int) -> A? {
  guard 0 <= index && index < self.size else { None }
  Some(self[index])
}

//-----------------------------------------------------------------------------
// Modifier
//-----------------------------------------------------------------------------

///|
/// Set a value at the given index (immutable).
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.set(1, 10), @array.of([1, 10, 3, 4, 5]))
/// ```
pub fn[A] set(self : T[A], index : Int, value : A) -> T[A] {
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
/// ```mbt
///   let v = @array.of([1, 2, 3])
///   assert_eq(v.push(4), @array.of([1, 2, 3, 4]))
/// ```
pub fn[A] push(self : T[A], value : A) -> T[A] {
  let (tree, shift) = self.tree.push_end(self.shift, value)
  { tree, size: self.size + 1, shift }
}

///|
/// Given two trees, concatenate them into a new tree.
pub fn[A] concat(self : T[A], other : T[A]) -> T[A] {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let (tree, shift) = Tree::concat(
    self.tree,
    self.shift,
    other.tree,
    other.shift,
    true,
  )
  { tree, size: self.size + other.size, shift }
}

///|
/// Concat two arrays.
pub impl[A] Add for T[A] with add(self, other) {
  self.concat(other)
}

//-----------------------------------------------------------------------------
// Iterators
//-----------------------------------------------------------------------------

///|
/// Return an iterator over the array.
pub fn[A] iter(self : T[A]) -> Iter[A] {
  self.tree.iter()
}

///|
/// Iterate over the array.
///
/// # Example
/// ```mbt
///   let arr = []
///   let v = @array.of([1, 2, 3, 4, 5])
///   v.each((e) => { arr.push(e) })
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[A] each(self : T[A], f : (A) -> Unit raise?) -> Unit raise? {
  self.tree.each(f)
}

///|
/// Iterate over the array with index.
///
/// # Example
/// ```mbt
///   let arr = []
///   let v = @array.of([1, 2, 3, 4, 5])
///   v.eachi((i, e) => { arr.push(i * e) })
///   assert_eq(arr, [0, 2, 6, 12, 20])
/// ```
pub fn[A] eachi(self : T[A], f : (Int, A) -> Unit raise?) -> Unit raise? {
  self.tree.eachi(f, self.shift, 0)
}

///|
/// Fold the array.
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.fold((a, b) => { a + b }, init=0), 15)
/// ```
pub fn[A, B] fold(self : T[A], init~ : B, f : (B, A) -> B raise?) -> B raise? {
  self.tree.fold(init, f)
}

///|
/// Fold the array in reverse order.
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.rev_fold((a, b) => { a + b }, init=0), 15)
/// ```
pub fn[A, B] rev_fold(
  self : T[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  self.tree.rev_fold(init, f)
}

///|
/// Fold the array from left to right.
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.fold((a, b) => { a + b }, init=0), 15)
/// ```
#deprecated("Use `fold` instead")
#coverage.skip
pub fn[A] fold_left(self : T[A], f : (A, A) -> A raise?, init~ : A) -> A raise? {
  self.fold(init~, f)
}

///|
/// Fold the array from right to left.
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.rev_fold((a, b) => { a + b }, init=0), 15)
/// ```
#deprecated("Use `rev_fold` instead")
#coverage.skip
pub fn[A] fold_right(
  self : T[A],
  f : (A, A) -> A raise?,
  init~ : A,
) -> A raise? {
  self.rev_fold(init~, f)
}

///|
/// Map a function over the array.
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.map((e) => { e * 2 }), @array.of([2, 4, 6, 8, 10]))
/// ```
pub fn[A, B] map(self : T[A], f : (A) -> B raise?) -> T[B] raise? {
  { tree: self.tree.map(f), size: self.size, shift: self.shift }
}

//-----------------------------------------------------------------------------
// Common Traits Implementation
//-----------------------------------------------------------------------------

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs,
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
pub impl[A : Eq] Eq for T[A] with equal(self, other) {
  self.size == other.size && self.tree == other.tree
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/array.of([", suffix="])")
}

///|
/// Compares two arrays based on shortlex order.
///
/// First compares the lengths of the arrays. If they differ, returns -1 if the
/// first array is shorter, 1 if it's longer. If the lengths are equal, compares
/// elements pairwise until a difference is found or all elements have been
/// compared.
///
/// Parameters:
///
/// * `self` : The first array to compare.
/// * `other` : The second array to compare.
///
/// Returns an integer that indicates the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
///   let arr1 = @array.of([1, 2, 3])
///   let arr2 = @array.of([1, 2, 4])
///   let arr3 = @array.of([1, 2])
///   inspect(arr1.compare(arr2), content="-1") // arr1 < arr2
///   inspect(arr1.compare(arr3), content="1") // arr2 > arr1
///   inspect(arr3.compare(arr1), content="-1") // arr1 > arr3 (longer)
///   inspect(arr1.compare(arr1), content="0") // arr1 = arr1
/// ```
pub impl[A : Compare] Compare for T[A] with compare(self, other) {
  let len_self = self.length()
  let len_other = other.length()
  let cmp = len_self.compare(len_other)
  guard cmp is 0 else { return cmp }
  for i in 0..<len_self {
    let cmp = self[i].compare(other[i])
    guard cmp is 0 else { break cmp }
  } else {
    return 0
  }
}

//-----------------------------------------------------------------------------
// For Internal Use
//-----------------------------------------------------------------------------

///|
fn[A] from_leaves(
  leaves : @core/array.View[FixedArray[A]],
  cap : Int,
) -> Tree[A] {
  if cap == branching_factor {
    Leaf(leaves[0])
  } else if leaves.length() <= branching_factor {
    let arr = FixedArray::make(leaves.length(), Empty)
    for i in 0..<leaves.length() {
      arr[i] = Leaf(leaves[i])
    }
    Node(arr, None)
  } else {
    let len = leaves.length() * branching_factor
    let child_cap = cap / branching_factor
    let quot = len / child_cap
    let rem = len % child_cap
    let times = child_cap / branching_factor
    let arr = if rem == 0 {
      FixedArray::makei(quot, i => from_leaves(
        leaves[i * times:(i + 1) * times],
        child_cap,
      ))
    } else {
      let arr = FixedArray::make(quot + 1, Tree::Empty)
      for i in 0..<quot {
        arr[i] = from_leaves(leaves[i * times:(i + 1) * times], child_cap)
      }
      arr[quot] = from_leaves(leaves[times * quot:], child_cap)
      arr
    }
    Node(arr, None)
  }
}

///|
fn shift_cap_of_size(size : Int) -> (Int, Int) {
  let mut cap = branching_factor
  let mut depth = 0
  while cap < size {
    cap *= branching_factor
    depth += 1
  }
  let shift = num_bits * depth
  (shift, cap)
}
