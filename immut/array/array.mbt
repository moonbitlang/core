// Copyright 2026 International Digital Economy Academy
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
  make_t(Tree::empty(), [], 0, 0)
}

///|
/// Create a persistent array with a given length and value.
#as_free_fn
pub fn[A] T::make(len : Int, value : A) -> T[A] {
  guard len > 0 else { new() }
  let tail_len = tail_len_of_size(len)
  let tree_len = len - tail_len
  let tail = FixedArray::make(tail_len, value)
  let (tree, shift) = if tree_len == 0 {
    (Tree::empty(), 0)
  } else {
    let leaves = Array::make(
      tree_len / branching_factor,
      FixedArray::make(branching_factor, value),
    )
    let (shift, cap) = shift_cap_of_size(tree_len)
    (from_leaves(leaves[:], cap), shift)
  }
  make_t(tree, tail, len, shift)
}

///|
/// Create a persistent array with a given length and a function to generate values.
#as_free_fn
pub fn[A] T::makei(len : Int, f : (Int) -> A raise?) -> T[A] raise? {
  guard len > 0 else { new() }
  let tail_len = tail_len_of_size(len)
  let tree_len = len - tail_len
  let tail = FixedArray::makei(tail_len, i => f(tree_len + i))
  let (tree, shift) = if tree_len == 0 {
    (Tree::empty(), 0)
  } else {
    let quot = tree_len / branching_factor
    let leaves : Array[FixedArray[A]] = Array::make(quot, [])
    for k in 0..<quot {
      leaves[k] = FixedArray::makei(branching_factor, i => {
        f(k * branching_factor + i)
      })
    }
    let (shift, cap) = shift_cap_of_size(tree_len)
    (from_leaves(leaves[:], cap), shift)
  }
  make_t(tree, tail, len, shift)
}

///|
/// Create a persistent array from an array.
/// 
/// # Example
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3])
///   assert_eq(v, @array.from_array([1, 2, 3]))
/// }
/// ```
#as_free_fn
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[A] T::from_array(arr : ArrayView[A]) -> T[A] {
  makei(arr.length(), i => arr[i])
}

///|
/// Creates an immutable array from an iterator of values.
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[A] T::from_iter(iter : Iter[A]) -> T[A] {
  let mut buf : FixedArray[A] = []
  let mut index = 0
  let leaves = []
  while iter.next() is Some(x) {
    if index == 0 {
      buf = FixedArray::make(branching_factor, x)
      index += 1
    } else if index < branching_factor {
      buf[index] = x
      index += 1
    } else {
      leaves.push(buf)
      index = 1
      buf = FixedArray::make(branching_factor, x)
    }
  }
  if index == 0 {
    return new()
  }
  let tail = if index == branching_factor {
    buf
  } else {
    let res = FixedArray::make(index, buf[0])
    buf.blit_to(res, len=index)
    res
  }
  let tree_len = leaves.length() * branching_factor
  let (tree, shift) = if tree_len == 0 {
    (Tree::empty(), 0)
  } else {
    let (shift, cap) = shift_cap_of_size(tree_len)
    (from_leaves(leaves[:], cap), shift)
  }
  make_t(tree, tail, tree_len + tail.length(), shift)
}

//-----------------------------------------------------------------------------
// Converter (convert T to other types)
//-----------------------------------------------------------------------------

///|
/// Returns a mutable array containing all elements.
pub fn[A] T::to_array(self : T[A]) -> Array[A] {
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
/// Returns `true` if the array contains no elements.
pub fn[A] T::is_empty(self : T[A]) -> Bool {
  self.size == 0
}

///|
/// Returns the number of elements in the array.
pub fn[A] T::length(self : T[A]) -> Int {
  self.size
}

///|
fn[A] T::tail_offset(self : T[A]) -> Int {
  self.size - self.tail.length()
}

//-----------------------------------------------------------------------------
// Lookup
//-----------------------------------------------------------------------------

///|
/// Get a value at the given index.
///
/// # Examples
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3, 4, 5])
///   inspect(v[0], content="1")
/// }
/// ```
#alias("_[_]")
pub fn[A] T::at(self : T[A], index : Int) -> A {
  guard index >= 0 && index < self.size
  let tail_offset = self.tail_offset()
  if index >= tail_offset {
    self.tail[index - tail_offset]
  } else if index == 0 {
    self.tree.get_first()
  } else if index == tail_offset - 1 {
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
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3])
///   inspect(v.get(1), content="Some(2)")
///   inspect(v.get(-1), content="None")
///   inspect(v.get(3), content="None")
/// }
/// ```
pub fn[A] T::get(self : T[A], index : Int) -> A? {
  guard 0 <= index && index < self.size else { None }
  Some(self[index])
}

///|
/// Returns the last element in the array.
pub fn[A] T::peek(self : T[A]) -> A? {
  if self.size == 0 {
    None
  } else {
    Some(self[self.size - 1])
  }
}

//-----------------------------------------------------------------------------
// Modifier
//-----------------------------------------------------------------------------

///|
/// Set a value at the given index (immutable).
///
/// # Example
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3, 4, 5])
///   assert_eq(v.set(1, 10), @array.from_array([1, 10, 3, 4, 5]))
/// }
/// ```
pub fn[A] T::set(self : T[A], index : Int, value : A) -> T[A] {
  guard index >= 0 && index < self.size
  let tail_offset = self.tail_offset()
  if index >= tail_offset {
    make_t(
      self.tree,
      immutable_set(self.tail, index - tail_offset, value),
      self.size,
      self.shift,
    )
  } else {
    make_t(
      self.tree.set(index, self.shift, value),
      self.tail,
      self.size,
      self.shift,
    )
  }
}

///|
/// Push a value to the end of the array.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3])
///   assert_eq(v.push(4), @array.from_array([1, 2, 3, 4]))
/// }
/// ```
pub fn[A] T::push(self : T[A], value : A) -> T[A] {
  if self.tail.length() < branching_factor {
    make_t(
      self.tree,
      immutable_push(self.tail, value),
      self.size + 1,
      self.shift,
    )
  } else {
    let (tree, shift) = if self.tree is Empty {
      (Leaf(self.tail), 0)
    } else {
      self.tree.append_right_leaf(self.shift, self.tail)
    }
    make_t(tree, [value], self.size + 1, shift)
  }
}

///|
/// Remove the last element from the array.
pub fn[A] T::pop(self : T[A]) -> T[A]? {
  if self.size == 0 {
    None
  } else if self.size == 1 {
    Some(new())
  } else if self.tail.length() > 1 {
    Some(
      make_t(
        self.tree,
        immutable_slice(self.tail, 0, self.tail.length() - 1),
        self.size - 1,
        self.shift,
      ),
    )
  } else {
    let new_tail = self.tree.last_leaf_elements()
    let (tree, shift) = self.tree
      .pop_rightmost_leaf(self.shift)
      .shrink_top(self.shift)
    Some(make_t(tree, new_tail, self.size - 1, shift))
  }
}

///|
/// Given two trees, concatenate them into a new tree.
pub fn[A] T::concat(self : T[A], other : T[A]) -> T[A] {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let size = self.size + other.size
  if other.tree is Empty {
    let combined_tail_len = self.tail.length() + other.tail.length()
    if combined_tail_len <= branching_factor {
      return make_t(
        self.tree,
        immutable_concat(self.tail, other.tail),
        size,
        self.shift,
      )
    } else if self.tail.length() == 0 {
      return make_t(self.tree, other.tail, size, self.shift)
    } else {
      let (tree, shift) = self.normalize_tree()
      return make_t(tree, other.tail, size, shift)
    }
  }
  let (left_tree, left_shift) = if self.tree is Empty {
    (Leaf(self.tail), 0)
  } else if self.tail.length() == 0 {
    (self.tree, self.shift)
  } else {
    self.normalize_tree()
  }
  let (tree, shift) = Tree::concat(
    left_tree,
    left_shift,
    other.tree,
    other.shift,
    true,
  )
  make_t(tree, other.tail, size, shift)
}

///|
/// Split the array into `[0, index)` and `[index, len)`.
pub fn[A] T::split(self : T[A], index : Int) -> (T[A], T[A]) {
  guard 0 <= index && index <= self.size else { abort("Index out of bounds") }
  (self.slice_unchecked(0, index), self.slice_unchecked(index, self.size))
}

///|
/// Return the first `count` elements.
pub fn[A] T::take(self : T[A], count : Int) -> T[A] {
  let end = if count <= 0 { 0 } else { min(count, self.size) }
  self.slice_unchecked(0, end)
}

///|
/// Drop the first `count` elements.
pub fn[A] T::drop(self : T[A], count : Int) -> T[A] {
  let start = if count <= 0 { 0 } else { min(count, self.size) }
  self.slice_unchecked(start, self.size)
}

///|
/// Return the slice `[start, end)`.
pub fn[A] T::slice(self : T[A], start : Int, end : Int) -> T[A] {
  guard start <= end else { abort("start index greater than end index") }
  guard 0 <= start && end <= self.size else { abort("Index out of bounds") }
  self.slice_unchecked(start, end)
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
/// Returns an iterator over the elements of the array.
#alias(iterator, deprecated)
pub fn[A] T::iter(self : T[A]) -> Iter[A] {
  let tree_iter = self.tree.iter()
  let tail_iter = self.tail.iter()
  tree_iter.concat(tail_iter)
}

///|
/// Iterate over the array.
///
/// # Example
/// ```mbt check
/// test {
///   let arr = []
///   let v = @array.from_array([1, 2, 3, 4, 5])
///   v.each(e => arr.push(e))
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[A] T::each(self : T[A], f : (A) -> Unit raise?) -> Unit raise? {
  self.tree.each(f)
  self.tail.each(f)
}

///|
/// Iterate over the array with index.
///
/// # Example
/// ```mbt check
/// test {
///   let arr = []
///   let v = @array.from_array([1, 2, 3, 4, 5])
///   v.eachi((i, e) => arr.push(i * e))
///   assert_eq(arr, [0, 2, 6, 12, 20])
/// }
/// ```
pub fn[A] T::eachi(self : T[A], f : (Int, A) -> Unit raise?) -> Unit raise? {
  self.tree.eachi(f, self.shift, 0)
  let tail_offset = self.tail_offset()
  for i in 0..<self.tail.length() {
    f(tail_offset + i, self.tail[i])
  }
}

///|
/// Fold the array.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3, 4, 5])
///   assert_eq(v.fold((a, b) => a + b, init=0), 15)
/// }
/// ```
#alias(fold_left, deprecated)
pub fn[A, B] T::fold(
  self : T[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  let acc = self.tree.fold(init, f)
  self.tail.fold(f, init=acc)
}

///|
/// Fold the array in reverse order.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3, 4, 5])
///   assert_eq(v.rev_fold((a, b) => a + b, init=0), 15)
/// }
/// ```
#alias(fold_right, deprecated)
pub fn[A, B] T::rev_fold(
  self : T[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  let acc = self.tail.rev_fold(f, init~)
  self.tree.rev_fold(acc, f)
}

///|
/// Map a function over the array.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @array.from_array([1, 2, 3, 4, 5])
///   assert_eq(v.map(e => e * 2), @array.from_array([2, 4, 6, 8, 10]))
/// }
/// ```
pub fn[A, B] T::map(self : T[A], f : (A) -> B raise?) -> T[B] raise? {
  make_t(self.tree.map(f), self.tail.map(f), self.size, self.shift)
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
  if physical_equal(self, other) {
    true
  } else if self.size != other.size {
    false
  } else {
    let left = self.iter()
    let right = other.iter()
    for _ in 0..<self.size {
      match (left.next(), right.next()) {
        (Some(a), Some(b)) => if a != b { return false }
        _ => return false
      }
    }
    true
  }
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/array.from_array([",
    suffix="])",
  )
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
/// ```mbt check
/// test {
///   let arr1 = @array.from_array([1, 2, 3])
///   let arr2 = @array.from_array([1, 2, 4])
///   let arr3 = @array.from_array([1, 2])
///   inspect(arr1.compare(arr2), content="-1") // arr1 < arr2
///   inspect(arr1.compare(arr3), content="1") // arr2 > arr1
///   inspect(arr3.compare(arr1), content="-1") // arr1 > arr3 (longer)
///   inspect(arr1.compare(arr1), content="0") // arr1 = arr1
/// }
/// ```
pub impl[A : Compare] Compare for T[A] with compare(self, other) {
  let len_self = self.length()
  let len_other = other.length()
  let cmp = len_self.compare(len_other)
  guard cmp is 0 else { return cmp }
  for i in 0..<len_self {
    let cmp = self[i].compare(other[i])
    guard cmp is 0 else { break cmp }
  } nobreak {
    return 0
  }
}

//-----------------------------------------------------------------------------
// For Internal Use
//-----------------------------------------------------------------------------

///|
fn[A] make_t(
  tree : Tree[A],
  tail : FixedArray[A],
  size : Int,
  shift : Int,
) -> T[A] {
  { tree, tail, size, shift }
}

///|
fn[A] from_leaves(leaves : ArrayView[FixedArray[A]], cap : Int) -> Tree[A] {
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
      FixedArray::makei(quot, i => {
        from_leaves(leaves[i * times:(i + 1) * times], child_cap)
      })
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
fn tail_len_of_size(size : Int) -> Int {
  if size <= branching_factor {
    size
  } else {
    let rem = size % branching_factor
    if rem == 0 {
      branching_factor
    } else {
      rem
    }
  }
}

///|
fn[A] T::normalize_tree(self : T[A]) -> (Tree[A], Int) {
  if self.size == 0 {
    (Tree::empty(), 0)
  } else if self.tail.length() == 0 {
    (self.tree, self.shift)
  } else if self.tail_offset() == 0 {
    (Leaf(self.tail), 0)
  } else if self.tail.length() == 1 {
    self.tree.push_end(self.shift, self.tail[0])
  } else {
    self.tree.append_right_leaf(self.shift, self.tail)
  }
}

///|
fn[A] T::slice_unchecked(self : T[A], start : Int, end : Int) -> T[A] {
  let len = end - start
  if len == 0 {
    new()
  } else if start == 0 && end == self.size {
    self
  } else {
    let tail_offset = self.tail_offset()
    if start >= tail_offset {
      make_t(
        Empty,
        immutable_slice(self.tail, start - tail_offset, end - tail_offset),
        len,
        0,
      )
    } else {
      let tree_end = min(end, tail_offset)
      let sliced_tree = if tree_end == tail_offset {
        self.tree
      } else {
        self.tree.slice_right(self.shift, tree_end)
      }
      let sliced_tree = if start == 0 {
        sliced_tree
      } else {
        sliced_tree.slice_left(self.shift, start)
      }
      let (tree, shift) = sliced_tree.shrink_top(self.shift)
      let tail = if end > tail_offset {
        immutable_slice(self.tail, 0, end - tail_offset)
      } else {
        []
      }
      make_t(tree, tail, len, shift)
    }
  }
}

///|
fn shift_cap_of_size(size : Int) -> (Int, Int) {
  for cap = branching_factor, depth = 0; cap < size; {
    continue cap * branching_factor, depth + 1
  } nobreak {
    (num_bits * depth, cap)
  }
}
