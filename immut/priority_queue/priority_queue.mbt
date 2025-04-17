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
  { node: Empty, size: 0 }
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
  for i in 0..<array.length() {
    pq = pq.push(array[i])
  }
  pq
}

///|
pub fn to_array[A : Compare](self : T[A]) -> Array[A] {
  let arr : Array[A] = []
  fn go(x : Node[A]) {
    match x {
      Empty => return
      Leaf(a) => arr.push(a)
      Branch(a, left=l, right=r) => {
        arr.push(a)
        go(l)
        go(r)
      }
    }
  }

  go(self.node)
  arr.sort_by(fn(x, y) { y.compare(x) })
  arr
}

///|
pub fn iter[A : Compare](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    let arr = self.to_array()
    for i in 0..<arr.length() {
      guard yield_(arr[i]) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
pub fn T::from_iter[A : Compare](iter : Iter[A]) -> T[A] {
  iter.fold(init=new(), fn(s, e) { s.push(e) })
}

///|
priv type Path Int

///|
/// require: size >= 2
fn path(size : Int) -> Path {
  loop size, 0 {
    1, y => Path(y)
    x, y => continue x >> 1, (y << 1) | (x & 1)
  }
}

///|
fn is_left(self : Path) -> Bool {
  (self._ & 1) == 0
}

///|
fn next(self : Path) -> Path {
  Path(self._ >> 1)
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
  match self.node {
    Empty => None
    Leaf(_) => Some({ node: Empty, size: 0 })
    Branch(_) => {
      let (value, temp) = self.node.remove_last_leaf(path(self.size))
      Some({ node: temp.change_and_down(value), size: self.size - 1 })
    }
  }
}

///|
fn remove_last_leaf[A : Compare](self : Node[A], path : Path) -> (A, Node[A]) {
  match self {
    Empty => abort("Priority queue is empty!")
    Leaf(a) => (a, Empty)
    Branch(a, left=Leaf(l_top), right=Empty) => (l_top, Leaf(a))
    Branch(a, left=l, right=r) =>
      if path.is_left() {
        let (e, ld) = l.remove_last_leaf(path.next())
        (e, Branch(a, left=ld, right=r))
      } else {
        let (e, rd) = r.remove_last_leaf(path.next())
        (e, Branch(a, left=l, right=rd))
      }
  }
}

///|
/// require: self is not empty
fn change_and_down[A : Compare](self : Node[A], value : A) -> Node[A] {
  match self {
    Empty => abort("unreachable")
    Leaf(_) => Leaf(value)
    Branch(_, left=l, right=r) =>
      match (l, r) {
        (Leaf(l_top), Empty) =>
          if value >= l_top {
            Branch(value, left=l, right=Empty)
          } else {
            Branch(l_top, left=Leaf(value), right=Empty)
          }
        (Branch(l_top, ..) | Leaf(l_top), Branch(r_top, ..) | Leaf(r_top)) =>
          if value >= l_top && value >= r_top {
            Branch(value, left=l, right=r)
          } else if l_top >= r_top {
            Branch(l_top, left=l.change_and_down(value), right=r)
          } else {
            Branch(r_top, left=l, right=r.change_and_down(value))
          }
        _ => abort("unreachable")
      }
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
  match self.node {
    Empty => abort("Priority queue is empty!")
    Leaf(_) => { node: Empty, size: 0 }
    Branch(_) => {
      let (value, temp) = self.node.remove_last_leaf(path(self.size))
      { node: temp.change_and_down(value), size: self.size - 1 }
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
  match self.node {
    Empty => { node: Leaf(value), size: 1 }
    Leaf(_) | Branch(_) => {
      let size = self.size + 1
      { node: self.node.push(value, path(size)), size }
    }
  }
}

///|
fn Node::push[A : Compare](self : Node[A], value : A, path : Path) -> Node[A] {
  match self {
    Empty => Leaf(value)
    Leaf(a) => {
      let (high, low) = if a > value { (a, value) } else { (value, a) }
      Branch(high, left=Leaf(low), right=Empty)
    }
    Branch(a, left=l, right=r) => {
      let (high, low) = if a > value { (a, value) } else { (value, a) }
      if path.is_left() {
        Branch(high, left=l.push(low, path.next()), right=r)
      } else {
        Branch(high, left=l, right=r.push(low, path.next()))
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
  match self.node {
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
  self.node is Empty
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
  self.size
}

///|
pub fn of[A : Compare](arr : FixedArray[A]) -> T[A] {
  let mut pq = new()
  for i in 0..<arr.length() {
    pq = pq.push(arr[i])
  }
  pq
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
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
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
