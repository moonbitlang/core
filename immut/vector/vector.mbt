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
// Constructors (construct Vector or convert other types to Vector)
//-----------------------------------------------------------------------------

///|
/// Return a new empty vector
#as_free_fn
pub fn[A] Vector::new() -> Vector[A] {
  make_t(Tree::empty(), [], 0, 0)
}

///|
/// Create a vector with a single element.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.singleton(42)
///   @debug.assert_eq(v, @vector.from_array([42]))
///   @test.assert_eq(v.length(), 1)
/// }
/// ```
#as_free_fn
pub fn[A] Vector::singleton(value : A) -> Vector[A] {
  make_t(Tree::empty(), [value], 1, 0)
}

///|
/// Create a persistent vector with a given length and value.
#as_free_fn
pub fn[A] Vector::make(len : Int, value : A) -> Vector[A] {
  guard len > 0 else { new() }
  let tail_len = tail_len_of_size(len)
  let tree_len = len - tail_len
  let tail = FixedArray::make(tail_len, value)
  let (tree, shift) = if tree_len == 0 {
    (Tree::empty(), 0)
  } else {
    let leaves = Array::make(
      tree_len / BRANCHING_FACTOR,
      FixedArray::make(BRANCHING_FACTOR, value),
    )
    let (shift, cap) = shift_cap_of_size(tree_len)
    (from_leaves(leaves, cap), shift)
  }
  make_t(tree, tail, len, shift)
}

///|
/// Create a persistent vector with a given length and a function to generate values.
#as_free_fn
pub fn[A] Vector::makei(len : Int, f : (Int) -> A raise?) -> Vector[A] raise? {
  guard len > 0 else { new() }
  let tail_len = tail_len_of_size(len)
  let tree_len = len - tail_len
  let tail = FixedArray::makei(tail_len, i => f(tree_len + i))
  let (tree, shift) = if tree_len == 0 {
    (Tree::empty(), 0)
  } else {
    let quot = tree_len / BRANCHING_FACTOR
    let leaves : Array[FixedArray[A]] = Array::make(quot, [])
    for k in 0..<quot {
      leaves[k] = FixedArray::makei(BRANCHING_FACTOR, i => {
        f(k * BRANCHING_FACTOR + i)
      })
    }
    let (shift, cap) = shift_cap_of_size(tree_len)
    (from_leaves(leaves, cap), shift)
  }
  make_t(tree, tail, len, shift)
}

///|
/// Create a persistent vector from an array.
/// 
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.Vector([1, 2, 3])
///   @debug.assert_eq(v, @vector.from_array([1, 2, 3]))
/// }
/// ```
#alias(from_array)
#as_free_fn(from_array)
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[A] Vector::Vector(arr : ArrayView[A]) -> Vector[A] {
  Vector::makei(arr.length(), i => arr[i])
}

///|
/// Creates an immutable vector from an iterator of values.
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[A] Vector::from_iter(iter : Iter[A]) -> Vector[A] {
  let mut buf : FixedArray[A] = []
  let mut index = 0
  let leaves = []
  while iter.next() is Some(x) {
    if index == 0 {
      buf = FixedArray::make(BRANCHING_FACTOR, x)
      index += 1
    } else if index < BRANCHING_FACTOR {
      buf[index] = x
      index += 1
    } else {
      leaves.push(buf)
      index = 1
      buf = FixedArray::make(BRANCHING_FACTOR, x)
    }
  }
  if index == 0 {
    return new()
  }
  let tail = if index == BRANCHING_FACTOR {
    if leaves.is_empty() {
      buf
    } else {
      leaves.push(buf)
      []
    }
  } else {
    FixedArray::make_and_blit(buf, allocate_len=index, init=buf[0], len=index)
  }
  let tree_len = leaves.length() * BRANCHING_FACTOR
  let (tree, shift) = if tree_len == 0 {
    (Tree::empty(), 0)
  } else {
    let (shift, cap) = shift_cap_of_size(tree_len)
    (from_leaves(leaves, cap), shift)
  }
  make_t(tree, tail, tree_len + tail.length(), shift)
}

//-----------------------------------------------------------------------------
// Converter (convert Vector to other types)
//-----------------------------------------------------------------------------

///|
/// Returns a mutable array containing all elements.
pub fn[A] Vector::to_array(self : Vector[A]) -> Array[A] {
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
/// Returns `true` if the vector contains no elements.
pub fn[A] Vector::is_empty(self : Vector[A]) -> Bool {
  self.size == 0
}

///|
/// Returns the number of elements in the vector.
pub fn[A] Vector::length(self : Vector[A]) -> Int {
  self.size
}

///|
fn[A] Vector::tail_offset(self : Vector[A]) -> Int {
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
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   inspect(v[0], content="1")
/// }
/// ```
#alias("_[_]")
pub fn[A] Vector::at(self : Vector[A], index : Int) -> A {
  guard index >= 0 && index < self.size
  let tail_offset = self.tail_offset()
  if index >= tail_offset {
    self.tail[index - tail_offset]
  } else {
    self.tree.get(index, self.shift)
  }
}

///|
/// Returns the element at the specified index in the vector, wrapped in an
/// `Option` type.
///
/// Parameters:
///
/// * `vector` : The immutable vector.
/// * `index` : The index of the element to retrieve.
///
/// Returns `Some(value)` if the index is valid, `None` if the index is out of
/// bounds.
///
/// Example:
///
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3])
///   debug_inspect(v.get(1), content="Some(2)")
///   debug_inspect(v.get(-1), content="None")
///   debug_inspect(v.get(3), content="None")
/// }
/// ```
pub fn[A] Vector::get(self : Vector[A], index : Int) -> A? {
  guard 0 <= index && index < self.size else { None }
  Some(self[index])
}

///|
/// Returns the last element in the vector.
pub fn[A] Vector::peek(self : Vector[A]) -> A? {
  if self.size == 0 {
    None
  } else {
    Some(self[self.size - 1])
  }
}

///|
/// Returns `true` if the vector contains the given value.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   inspect(v.contains(3), content="true")
///   inspect(v.contains(6), content="false")
/// }
/// ```
pub fn[A : Eq] Vector::contains(self : Vector[A], value : A) -> Bool {
  if self.tree.contains(value) {
    return true
  }
  self.tail.contains(value)
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
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   @debug.assert_eq(v.set(1, 10), @vector.from_array([1, 10, 3, 4, 5]))
/// }
/// ```
pub fn[A] Vector::set(self : Vector[A], index : Int, value : A) -> Vector[A] {
  guard index >= 0 && index < self.size
  let tail_len = self.tail.length()
  if tail_len == 0 {
    make_t(
      self.tree.set(index, self.shift, value),
      self.tail,
      self.size,
      self.shift,
    )
  } else {
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
}

///|
/// Push a value to the end of the vector.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3])
///   @debug.assert_eq(v.push(4), @vector.from_array([1, 2, 3, 4]))
/// }
/// ```
pub fn[A] Vector::push(self : Vector[A], value : A) -> Vector[A] {
  if self.tail.length() < BRANCHING_FACTOR {
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
/// Remove the last element from the vector.
pub fn[A] Vector::pop(self : Vector[A]) -> Vector[A]? {
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
  } else if self.tail.length() == 1 {
    let new_tail = self.tree.last_leaf_elements()
    let (tree, shift) = self.tree
      .pop_rightmost_leaf(self.shift)
      .shrink_top(self.shift)
    Some(make_t(tree, new_tail, self.size - 1, shift))
  } else {
    let last_leaf = self.tree.last_leaf_elements()
    if last_leaf.length() > 1 {
      let (tree, shift) = self.tree
        .pop_rightmost_leaf(self.shift)
        .shrink_top(self.shift)
      Some(
        make_t(
          tree,
          immutable_slice(last_leaf, 0, last_leaf.length() - 1),
          self.size - 1,
          shift,
        ),
      )
    } else {
      let stripped = self.tree.pop_rightmost_leaf(self.shift)
      let (promoted_tree, promoted_shift) = stripped.shrink_top(self.shift)
      if promoted_tree is Empty {
        Some(new())
      } else {
        let new_tail = promoted_tree.last_leaf_elements()
        let (tree, shift) = promoted_tree
          .pop_rightmost_leaf(promoted_shift)
          .shrink_top(promoted_shift)
        Some(make_t(tree, new_tail, self.size - 1, shift))
      }
    }
  }
}

///|
/// Given two trees, concatenate them into a new tree.
pub fn[A] Vector::concat(self : Vector[A], other : Vector[A]) -> Vector[A] {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let size = self.size + other.size
  if other.tree is Empty {
    let combined_tail_len = self.tail.length() + other.tail.length()
    if combined_tail_len <= BRANCHING_FACTOR {
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
  let (tree, shift) = if self.tree is Empty {
    Tree::concat(Leaf(self.tail), 0, other.tree, other.shift, true)
  } else if self.tail.length() == 0 {
    Tree::concat(self.tree, self.shift, other.tree, other.shift, true)
  } else {
    Tree::concat_with_suffix(
      self.tree,
      self.shift,
      self.tail,
      other.tree,
      other.shift,
      true,
    )
  }
  make_t(tree, other.tail, size, shift)
}

///|
/// Split the vector into `[0, index)` and `[index, len)`.
pub fn[A] Vector::split(
  self : Vector[A],
  index : Int,
) -> (Vector[A], Vector[A]) {
  guard 0 <= index && index <= self.size else { abort("Index out of bounds") }
  (self.slice_unchecked(0, index), self.slice_unchecked(index, self.size))
}

///|
/// Return the first `count` elements.
pub fn[A] Vector::take(self : Vector[A], count : Int) -> Vector[A] {
  let end = if count <= 0 { 0 } else { min(count, self.size) }
  self.slice_unchecked(0, end)
}

///|
/// Drop the first `count` elements.
pub fn[A] Vector::drop(self : Vector[A], count : Int) -> Vector[A] {
  let start = if count <= 0 { 0 } else { min(count, self.size) }
  self.slice_unchecked(start, self.size)
}

///|
/// Return the slice `[start, end)`.
pub fn[A] Vector::slice(self : Vector[A], start : Int, end : Int) -> Vector[A] {
  guard start <= end else { abort("start index greater than end index") }
  guard 0 <= start && end <= self.size else { abort("Index out of bounds") }
  self.slice_unchecked(start, end)
}

///|
/// Concat two vectors.
pub impl[A] Add for Vector[A] with fn add(self, other) {
  self.concat(other)
}

//-----------------------------------------------------------------------------
// Iterators
//-----------------------------------------------------------------------------

///|
/// Returns an iterator over the elements of the vector.
#alias(iterator, deprecated)
pub fn[A] Vector::iter(self : Vector[A]) -> Iter[A] {
  let mut in_tree = true
  let mut curr_tree = self.tree
  let mut curr_index = 0
  let mut curr_leaf : FixedArray[A] = []
  let mut leaf_index = 0
  let mut leaf_len = 0
  let parents = []
  let mut tail_index = 0
  let tail_len = self.tail.length()
  Iter::new(
    fn() {
      if leaf_index < leaf_len {
        let elem = curr_leaf.unsafe_get(leaf_index)
        leaf_index += 1
        return Some(elem)
      }
      let tree_result = if in_tree {
        for tree = curr_tree {
          match tree {
            Node(children, _) as t if curr_index < children.length() => {
              let child = children.unsafe_get(curr_index)
              parents.push((t, curr_index + 1))
              curr_tree = child
              curr_index = 0
              continue child
            }
            Leaf(elems) if curr_index < elems.length() => {
              let len = elems.length()
              let elem = elems.unsafe_get(curr_index)
              curr_leaf = elems
              leaf_len = len
              leaf_index = curr_index + 1
              curr_index = len
              break Some(elem)
            }
            _ if parents.pop() is Some((parent_tree, parent_index)) => {
              curr_tree = parent_tree
              curr_index = parent_index
              continue parent_tree
            }
            _ => {
              in_tree = false
              break None
            }
          }
        }
      } else {
        None
      }
      match tree_result {
        Some(_) => tree_result
        None =>
          if tail_index < tail_len {
            let elem = self.tail.unsafe_get(tail_index)
            tail_index += 1
            Some(elem)
          } else {
            None
          }
      }
    },
    size_hint=self.size,
  )
}

///|
/// Iterate over the vector.
///
/// # Example
/// ```mbt check
/// test {
///   let arr = []
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   v.each(e => arr.push(e))
///   @debug.assert_eq(arr, [1, 2, 3, 4, 5])
/// }
/// ```
pub fn[A] Vector::each(self : Vector[A], f : (A) -> Unit raise?) -> Unit raise? {
  self.tree.each(f)
  self.tail.each(f)
}

///|
/// Iterate over the vector with index.
///
/// # Example
/// ```mbt check
/// test {
///   let arr = []
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   v.eachi((i, e) => arr.push(i * e))
///   @debug.assert_eq(arr, [0, 2, 6, 12, 20])
/// }
/// ```
pub fn[A] Vector::eachi(
  self : Vector[A],
  f : (Int, A) -> Unit raise?,
) -> Unit raise? {
  self.tree.eachi(f, self.shift, 0)
  let tail_offset = self.tail_offset()
  for i, x in self.tail {
    f(tail_offset + i, x)
  }
}

///|
/// Fold the vector.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   @test.assert_eq(v.fold((a, b) => a + b, init=0), 15)
/// }
/// ```
#alias(fold_left, deprecated)
pub fn[A, B] Vector::fold(
  self : Vector[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  let acc = self.tree.fold(init, f)
  self.tail.fold(f, init=acc)
}

///|
/// Fold the vector in reverse order.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   @test.assert_eq(v.rev_fold((a, b) => a + b, init=0), 15)
/// }
/// ```
#alias(fold_right, deprecated)
pub fn[A, B] Vector::rev_fold(
  self : Vector[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  let acc = self.tail.rev_fold(f, init~)
  self.tree.rev_fold(acc, f)
}

///|
/// Map a function over the vector.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   @debug.assert_eq(v.map(e => e * 2), @vector.from_array([2, 4, 6, 8, 10]))
/// }
/// ```
pub fn[A, B] Vector::map(
  self : Vector[A],
  f : (A) -> B raise?,
) -> Vector[B] raise? {
  make_t(self.tree.map(f), self.tail.map(f), self.size, self.shift)
}

///|
/// Creates a new vector containing only the elements that satisfy the predicate.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   @debug.assert_eq(v.filter(x => x % 2 == 0), @vector.from_array([2, 4]))
/// }
/// ```
pub fn[A] Vector::filter(
  self : Vector[A],
  f : (A) -> Bool raise?,
) -> Vector[A] raise? {
  let arr : Array[A] = Array::new(capacity=self.size)
  self.each(value => if f(value) { arr.push(value) })
  from_array(arr)
}

///|
/// Returns a new vector with the elements in reverse order.
///
/// # Example
/// ```mbt check
/// test {
///   let v = @vector.from_array([1, 2, 3, 4, 5])
///   @debug.assert_eq(v.rev(), @vector.from_array([5, 4, 3, 2, 1]))
/// }
/// ```
pub fn[A] Vector::rev(self : Vector[A]) -> Vector[A] {
  if self.size == 0 {
    new()
  } else {
    let arr = Array::make(self.size, self[0])
    self.eachi((i, value) => arr[self.size - 1 - i] = value)
    from_array(arr)
  }
}

//-----------------------------------------------------------------------------
// Common Traits Implementation
//-----------------------------------------------------------------------------

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for Vector[X] with fn arbitrary(
  size,
  rs,
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> Vector::from_array
}

///|
pub impl[A : Hash] Hash for Vector[A] with fn hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

///|
pub impl[A : Eq] Eq for Vector[A] with fn equal(self, other) {
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
#deprecated("Use @debug.Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show] Show for Vector[A]

///|
pub impl[A : Show] Show for Vector[A] with fn output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/vector.from_array([",
    suffix="])",
  )
}

///|
pub impl[A : ToJson] ToJson for Vector[A] with fn to_json(self) {
  [
    for value in self => value
  ]
}

///|
pub impl[A : @json.FromJson] @json.FromJson for Vector[A] with fn from_json(
  json,
  path,
) {
  guard json is Array(arr) else {
    raise JsonDecodeError((path, "@immut/vector.from_json: expected array"))
  }
  let len = arr.length()
  guard len != 0 else { return new() }
  let values : Array[A] = Array::new(capacity=len)
  for i, value in arr {
    values.push(A::from_json(value, path.add_index(i)))
  }
  Vector::from_array(values)
}

///|
/// Compares two vectors based on shortlex order.
///
/// First compares the lengths of the vectors. If they differ, returns -1 if the
/// first vector is shorter, 1 if it's longer. If the lengths are equal, compares
/// elements pairwise until a difference is found or all elements have been
/// compared.
///
/// Parameters:
///
/// * `self` : The first vector to compare.
/// * `other` : The second vector to compare.
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
///   let arr1 = @vector.from_array([1, 2, 3])
///   let arr2 = @vector.from_array([1, 2, 4])
///   let arr3 = @vector.from_array([1, 2])
///   inspect(arr1.compare(arr2), content="-1") // arr1 < arr2
///   inspect(arr1.compare(arr3), content="1") // arr1 > arr3 (longer)
///   inspect(arr3.compare(arr1), content="-1") // arr3 < arr1 (shorter)
///   inspect(arr1.compare(arr1), content="0") // arr1 = arr1
/// }
/// ```
pub impl[A : Compare] Compare for Vector[A] with fn compare(self, other) {
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
) -> Vector[A] {
  { tree, tail, size, shift }
}

///|
fn[A] from_leaves(leaves : ArrayView[FixedArray[A]], cap : Int) -> Tree[A] {
  if cap == BRANCHING_FACTOR {
    Leaf(leaves[0])
  } else if leaves.length() <= BRANCHING_FACTOR {
    let arr = FixedArray::make(leaves.length(), Empty)
    for i, leaf in leaves {
      arr[i] = Leaf(leaf)
    }
    Node(arr, None)
  } else {
    let len = leaves.length() * BRANCHING_FACTOR
    let child_cap = cap / BRANCHING_FACTOR
    let quot = len / child_cap
    let rem = len % child_cap
    let times = child_cap / BRANCHING_FACTOR
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
  if size <= BRANCHING_FACTOR {
    size
  } else {
    let rem = size % BRANCHING_FACTOR
    if rem == 0 {
      0
    } else {
      rem
    }
  }
}

///|
fn[A] Vector::normalize_tree(self : Vector[A]) -> (Tree[A], Int) {
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
fn[A] Vector::slice_unchecked(
  self : Vector[A],
  start : Int,
  end : Int,
) -> Vector[A] {
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
  for cap = BRANCHING_FACTOR, depth = 0; cap < size; {
    continue cap * BRANCHING_FACTOR, depth + 1
  } nobreak {
    (NUM_BITS * depth, cap)
  }
}
