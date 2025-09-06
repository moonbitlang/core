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
/// ```mbt
///   let queue = @priority_queue.new()
///   assert_eq(queue.push(1).length(), 1)
/// ```
#as_free_fn
pub fn[A] PriorityQueue::new() -> PriorityQueue[A] {
  { node: Empty, size: 0 }
}

///|
/// Creates a new immutable priority queue from an array.
///
/// # Example
/// ```mbt
///   let queue = @priority_queue.of([1, 2, 3, 4, 5])
///   inspect(queue.length(), content="5")
/// ```
#as_free_fn
pub fn[A : Compare] PriorityQueue::from_array(
  array : Array[A],
) -> PriorityQueue[A] {
  let mut pq = new()
  for i in 0..<array.length() {
    pq = pq.push(array[i])
  }
  pq
}

///|
pub fn[A : Compare] to_array(self : PriorityQueue[A]) -> Array[A] {
  let arr : Array[A] = []
  let stack : Array[Node[A]] = [self.node]
  while stack.pop() is Some(node) {
    match node {
      Empty => ()
      Leaf(a) => arr.push(a)
      Branch(a, left=l, right=r) => {
        arr.push(a)
        stack.push(l)
        stack.push(r)
      }
    }
  }
  arr.sort()
  arr.rev_inplace()
  arr
}

///|
pub fn[A : Compare] iter(self : PriorityQueue[A]) -> Iter[A] {
  Iter::new(yield_ => {
    let arr = self.to_array()
    for i in 0..<arr.length() {
      guard yield_(arr[i]) is IterContinue else { break IterEnd }
    } else {
      IterContinue
    }
  })
}

///|
#as_free_fn
pub fn[A : Compare] PriorityQueue::from_iter(
  iter : Iter[A],
) -> PriorityQueue[A] {
  iter.fold(init=new(), (s, e) => s.push(e))
}

///|
priv struct Path(Int)

///|
/// require: size >= 2
fn path(size : Int) -> Path {
  loop (size, 0) {
    (1, y) => Path(y)
    (x, y) => continue (x >> 1, (y << 1) | (x & 1))
  }
}

///|
fn is_left(self : Path) -> Bool {
  (self.0 & 1) == 0
}

///|
fn next(self : Path) -> Path {
  Path(self.0 >> 1)
}

///|
/// Pops the first value from the immutable priority queue, which returns None if the queue is empty.
///
/// # Example
/// ```mbt
///   let queue = @priority_queue.of([1, 2, 3, 4])
///   let first = queue.pop()
///   assert_eq(first, Some(@priority_queue.of([1, 2, 3])))
/// ```
pub fn[A : Compare] pop(self : PriorityQueue[A]) -> PriorityQueue[A]? {
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
fn[A : Compare] remove_last_leaf(self : Node[A], path : Path) -> (A, Node[A]) {
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
fn[A : Compare] change_and_down(self : Node[A], value : A) -> Node[A] {
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
/// # Example
/// ```mbt
///   let queue = @priority_queue.of([1, 2, 3, 4])
///   let first = queue.unsafe_pop()
///   assert_eq(first, @priority_queue.of([1, 2, 3]))
/// ```
#internal(unsafe, "Panics if the queue is empty.")
pub fn[A : Compare] unsafe_pop(self : PriorityQueue[A]) -> PriorityQueue[A] {
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
/// Adds a value to the immutable priority queue.
///
/// # Example
/// ```mbt
///   let queue = @priority_queue.new()
///   assert_eq(queue.push(1).length(), 1)
/// ```
pub fn[A : Compare] push(
  self : PriorityQueue[A],
  value : A,
) -> PriorityQueue[A] {
  match self.node {
    Empty => { node: Leaf(value), size: 1 }
    Leaf(_) | Branch(_) => {
      let size = self.size + 1
      { node: self.node.push(value, path(size)), size }
    }
  }
}

///|
fn[A : Compare] Node::push(self : Node[A], value : A, path : Path) -> Node[A] {
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
/// ```mbt
///   let queue = @priority_queue.of([1, 2, 3, 4])
///   assert_eq(queue.peek(), Some(4))
/// ```
pub fn[A] peek(self : PriorityQueue[A]) -> A? {
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
/// ```mbt
///   let queue = @priority_queue.new()
///   inspect(queue.is_empty(), content="true")
///   assert_eq(queue.push(1).is_empty(), false)
/// ```
pub fn[A] is_empty(self : PriorityQueue[A]) -> Bool {
  self.node is Empty
}

///|
/// Return the length of the immutable priority queue.
///
/// # Example
/// ```mbt
///   let queue = @priority_queue.new()
///   inspect(queue.length(), content="0")
///   assert_eq(queue.push(1).length(), 1)
/// ```
pub fn[A] length(self : PriorityQueue[A]) -> Int {
  self.size
}

///|
#as_free_fn
pub fn[A : Compare] PriorityQueue::of(arr : FixedArray[A]) -> PriorityQueue[A] {
  let mut pq = new()
  for i in 0..<arr.length() {
    pq = pq.push(arr[i])
  }
  pq
}

///|
pub impl[A : Show + Compare] Show for PriorityQueue[A] with output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/priority_queue.of([",
    suffix="])",
  )
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for PriorityQueue[
  X,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub impl[A : Compare] Eq for PriorityQueue[A] with equal(self, other) {
  self.length() == other.length() && self.to_array() == other.to_array()
}

///|
pub impl[A : Hash + Compare] Hash for PriorityQueue[A] with hash_combine(
  self,
  hasher,
) {
  for e in self {
    hasher.combine(e)
  }
}

///|
/// Compare two priority queues based on shortlex order by comparing their sorted contents.
///
/// Parameters:
///
/// * `self` : The first list to compare.
/// * `other` : The second list to compare.
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
///   let pq1 = @priority_queue.of([1, 2, 3])
///   let pq2 = @priority_queue.of([1, 2, 4])
///   let pq3 = @priority_queue.of([1, 2])
///   inspect(pq1.compare(pq2), content="-1") // pq1 < pq2
///   inspect(pq1.compare(pq3), content="1")  // pq2 > pq1
///   inspect(pq3.compare(pq1), content="-1") // pq1 > pq3 (longer)
///   inspect(pq1.compare(pq1), content="0")  // pq1 = pq1
/// ```
pub impl[A : Compare] Compare for PriorityQueue[A] with compare(self, other) {
  let len_cmp = self.length().compare(other.length())
  if len_cmp != 0 {
    return len_cmp
  }
  let self_arr = self.to_array()
  let other_arr = other.to_array()
  for i in 0..<self_arr.length() {
    let cmp = self_arr[i].compare(other_arr[i])
    if cmp != 0 {
      return cmp
    }
  } else {
    return 0
  }
}
