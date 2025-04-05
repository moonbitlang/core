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

///|
/// Creates a new empty immutable priority queue.
///
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.push(1).length(), 1)
/// ```
pub fn new[A : Compare]() -> T[A] {
  Empty
}

///|
/// Creates a new immutable priority queue from an array.
///
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4, 5])
/// assert_eq!(queue.length(), 5)
/// ```
pub fn from_array[A : Compare](array : Array[A]) -> T[A] {
  let mut pq = new()
  for x in array {
    pq = pq.push(x)
  }
  pq
}

///|
pub fn to_array[A : Compare](self : T[A]) -> Array[A] {
  let arr : Array[A] = []
  fn go(x : T[A]) {
    match x {
      Empty => return
      Leaf(a) => arr.push(a)
      Branch(a, left=l, right=r, ..) => {
        arr.push(a)
        go(l)
        go(r)
      }
    }
  }

  go(self)
  arr..sort_by(fn(x, y) { y.compare(x) })
}

///|
pub fn iter[A : Compare](self : T[A]) -> Iter[A] {
  self.to_array().iter()
}

///|
pub fn T::from_iter[A : Compare](iter : Iter[A]) -> T[A] {
  iter.fold(init=new(), push)
}

///|
/// Pops the first value from the immutable priority queue, which returns None if the queue is empty.
///
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// let first = queue.pop()
/// assert_eq!(first, Some(@priority_queue.of([1, 2, 3])))
/// ```
pub fn pop[A : Compare](self : T[A]) -> T[A]? {
  match self {
    Empty => None
    Leaf(_) => Some(Empty)
    Branch(_) => {
      let (value, temp) = self.remove_last_leaf()
      Some(temp.change_and_down(value))
    }
  }
}

///|
fn remove_last_leaf[A : Compare](self : T[A]) -> (A, T[A]) {
  match self {
    Empty => abort("Priority queue is empty!")
    Leaf(a) => (a, Empty)
    Branch(a, left=Leaf(l_top), right=Empty, ..) => (l_top, Leaf(a))
    Branch(a, left=l, right=r, size~) =>
      if last_leaf_in_left(size) {
        let (e, ld) = l.remove_last_leaf()
        (e, Branch(a, left=ld, right=r, size=size - 1))
      } else {
        let (e, rd) = r.remove_last_leaf()
        (e, Branch(a, left=l, right=rd, size=size - 1))
      }
  }
}

///|
/// require: self is not empty
fn change_and_down[A : Compare](self : T[A], value : A) -> T[A] {
  match self {
    Empty => abort("unreachable")
    Leaf(_) => Leaf(value)
    Branch(_, left=l, right=r, size~) =>
      match (l, r) {
        (Leaf(l_top), Empty) =>
          if value >= l_top {
            Branch(value, left=l, right=Empty, size~)
          } else {
            Branch(l_top, left=Leaf(value), right=Empty, size~)
          }
        (Branch(l_top, ..) | Leaf(l_top), Branch(r_top, ..) | Leaf(r_top)) =>
          if value >= l_top && value >= r_top {
            Branch(value, left=l, right=r, size~)
          } else if l_top >= r_top {
            Branch(l_top, left=l.change_and_down(value), right=r, size~)
          } else {
            Branch(r_top, left=l, right=r.change_and_down(value), size~)
          }
        _ => abort("unreachable")
      }
  }
}

///|
/// require: `size >= 2`
fn last_leaf_in_left(size : Int) -> Bool {
  loop size {
    0b10 => true
    0b11 => false
    x => continue x >> 1
  }
}

///|
/// Pops the first value from the immutable priority queue.
///
/// @alert unsafe "Panics if the queue is empty."
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// let first = queue.unsafe_pop()
/// assert_eq!(first, @priority_queue.of([1, 2, 3]))
/// ```
pub fn unsafe_pop[A : Compare](self : T[A]) -> T[A] {
  match self {
    Empty => abort("Priority queue is empty!")
    Leaf(_) => Empty
    Branch(_) => {
      let (value, temp) = self.remove_last_leaf()
      temp.change_and_down(value)
    }
  }
}

///|
#deprecated("Use `unsafe_pop` instead")
#coverage.skip
pub fn pop_exn[A : Compare](self : T[A]) -> T[A] {
  unsafe_pop(self)
}

///|
/// Adds a value to the immutable priority queue.
///
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.push(1).length(), 1)
/// ```
pub fn push[A : Compare](self : T[A], value : A) -> T[A] {
  match self {
    Empty => Leaf(value)
    Leaf(a) => {
      let (high, low) = if a > value { (a, value) } else { (value, a) }
      Branch(high, left=Leaf(low), right=Empty, size=2)
    }
    Branch(a, left=l, right=r, size=old_size) => {
      let (high, low) = if a > value { (a, value) } else { (value, a) }
      let size = old_size + 1
      if last_leaf_in_left(size) {
        Branch(high, left=l.push(low), right=r, size~)
      } else {
        Branch(high, left=l, right=r.push(low), size~)
      }
    }
  }
}

///|
/// Peeks at the first value in the immutable priority queue, which returns None if the immutable priority queue is empty.
///
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// assert_eq!(queue.peek(), Some(4))
/// ```
pub fn peek[A](self : T[A]) -> A? {
  match self {
    Empty => None
    Leaf(a) => Some(a)
    Branch(a, ..) => Some(a)
  }
}

///|
/// Checks if the immutable priority queue is empty.
///
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.is_empty(), true)
/// assert_eq!(queue.push(1).is_empty(), false)
/// ```
pub fn is_empty[A](self : T[A]) -> Bool {
  self is Empty
}

///|
/// Return the length of the immutable priority queue.
///
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.length(), 0)
/// assert_eq!(queue.push(1).length(), 1)
/// ```
pub fn length[A](self : T[A]) -> Int {
  match self {
    Empty => 0
    Leaf(_) => 1
    Branch(_, size~, ..) => size
  }
}

///|
pub fn of[A : Compare](arr : FixedArray[A]) -> T[A] {
  T::from_iter(arr.iter())
}

///|
pub impl[A : Show + Compare] Show for T[A] with output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/priority_queue.of([",
    suffix="])",
  )
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs
) {
  T::from_iter(@quickcheck.Arbitrary::arbitrary(size, rs))
}

///|
pub impl[A : Compare] Eq for T[A] with op_equal(self, other) {
  self.length() == other.length() && self.to_array() == other.to_array()
}

///|
pub impl[A : Hash + Compare] Hash for T[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}
