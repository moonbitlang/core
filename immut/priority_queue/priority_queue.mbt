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

///|
/// Creates a new immutable priority queue from an array.
///
/// Runs in O(n): the elements are copied once and turned into a heap in place,
/// which is asymptotically faster than inserting them one by one with `push`
/// (O(n log n)).
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.PriorityQueue([1, 2, 3, 4, 5])
///   inspect(queue.length(), content="5")
/// }
/// ```
#alias(from_array)
#as_free_fn(from_array)
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[A : Compare] PriorityQueue::PriorityQueue(
  array : ArrayView[A],
) -> PriorityQueue[A] {
  // `array` is borrowed, so copy it into a buffer we own before heapifying.
  from_array_in_place(array.to_owned().mut_view())
}

///|
/// Builds a priority queue from `heap`, reordering it in place.
///
/// The caller must own the buffer behind `heap` and not use it afterwards: the
/// elements are permuted into heap order rather than copied, which is what lets
/// callers such as `from_iter` skip the extra allocation that
/// `PriorityQueue(ArrayView)` needs for its defensive copy.
///
/// ## Why this produces a valid queue
///
/// The queue is a binary max-heap kept as a complete binary tree (`Node`). The
/// exact same tree is what `push`/`pop` maintain: the `k`-th node in level
/// order lands at array index `k`, whose children live at `2*k+1` and `2*k+2`.
/// So reading `heap` with that child rule yields a tree of the *same shape* the
/// rest of the module expects.
///
/// `heapify` then enforces the ordering invariant with Floyd's bottom-up
/// build-heap: it sifts down every internal node from `len/2 - 1` back to the
/// root. Visiting a node only after both of its child subtrees are already
/// heaps means a single `sift_down` per node suffices to make `heap` a max-heap
/// (each parent `>=` both children). Because most nodes sit near the bottom and
/// sink only a short distance, the whole pass is O(n) rather than the
/// O(n log n) of `len` repeated `push`es.
///
/// Finally `priority_queue_node_from_heap` transcribes the implicit array tree
/// into `Node` using the same index-to-child mapping, so the result keeps both
/// the complete-tree shape and the heap invariant and can be consumed directly
/// by `pop`/`peek`.
fn[A : Compare] from_array_in_place(heap : MutArrayView[A]) -> PriorityQueue[A] {
  let len = heap.length()
  guard len > 0 else { return { node: Empty, size: 0 } }
  heapify(heap)
  { node: priority_queue_node_from_heap(heap, 0, len), size: len }
}

///|
/// Floyd bottom-up build-heap: reorders `heap` into a max-heap in O(n).
fn[A : Compare] heapify(heap : MutArrayView[A]) -> Unit {
  let len = heap.length()
  // Nodes from index `len / 2` on are leaves and already trivial heaps, so sift
  // down every internal node from the last one back to the root. The descending
  // order is required: each subtree is already a heap when its parent is sifted.
  // `(len / 2)>..0` iterates from `len / 2 - 1` down to `0` inclusive (and is
  // empty when `len < 2`).
  for i in (len / 2)>..0 {
    sift_down(heap, i, len)
  }
}

///|
/// Sinks the element at `start` until the subtree rooted there is a max-heap,
/// repeatedly swapping it with its larger child.
fn[A : Compare] sift_down(
  heap : MutArrayView[A],
  start : Int,
  len : Int,
) -> Unit {
  for root = start {
    let left = root * 2 + 1
    guard left < len else { break }
    let right = left + 1
    let child = if right < len && heap.unsafe_get(right) > heap.unsafe_get(left) {
      right
    } else {
      left
    }
    guard heap.unsafe_get(root) < heap.unsafe_get(child) else { break }
    let root_value = heap.unsafe_get(root)
    heap.unsafe_set(root, heap.unsafe_get(child))
    heap.unsafe_set(child, root_value)
    continue child
  }
}

///|
/// Transcribes the implicit array heap into the persistent `Node` tree,
/// preserving the `index -> (2*index+1, 2*index+2)` child mapping.
fn[A] priority_queue_node_from_heap(
  heap : MutArrayView[A],
  index : Int,
  len : Int,
) -> Node[A] {
  if index >= len {
    Empty
  } else {
    let value = heap.unsafe_get(index)
    let left_index = index * 2 + 1
    if left_index >= len {
      Leaf(value)
    } else {
      Branch(
        value,
        left=priority_queue_node_from_heap(heap, left_index, len),
        right=priority_queue_node_from_heap(heap, left_index + 1, len),
      )
    }
  }
}

///|
/// Returns an array of all elements in descending priority order.
pub fn[A : Compare] PriorityQueue::to_array(
  self : PriorityQueue[A],
) -> Array[A] {
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
  arr.rev_in_place()
  arr
}

///|
/// Returns an iterator over elements in descending priority order.
#alias(iterator, deprecated)
pub fn[A : Compare] PriorityQueue::iter(self : PriorityQueue[A]) -> Iter[A] {
  self.to_array().iter()
}

///|
/// Creates a priority queue from an iterator of values.
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[A : Compare] PriorityQueue::from_iter(
  iter : Iter[A],
) -> PriorityQueue[A] {
  // `to_array` already yields a fresh array we own, so view it in place and
  // heapify without copying it again through the public ctor.
  from_array_in_place(iter.to_array().mut_view())
}

///|
priv struct Path(Int)

///|
/// require: size >= 2
fn path(size : Int) -> Path {
  for x = size, y = 0 {
    match (x, y) {
      (1, y) => break Path(y)
      (x, y) => continue x >> 1, (y << 1) | (x & 1)
    }
  }
}

///|
fn Path::is_left(self : Path) -> Bool {
  (self.0 & 1) == 0
}

///|
fn Path::next(self : Path) -> Path {
  Path(self.0 >> 1)
}

///|
/// Pops the first value from the immutable priority queue, which returns None if the queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   let first = queue.pop()
///   @test.assert_eq(first, Some(@priority_queue.from_array([1, 2, 3])))
/// }
/// ```
pub fn[A : Compare] PriorityQueue::pop(
  self : PriorityQueue[A],
) -> PriorityQueue[A]? {
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
fn[A] Node::remove_last_leaf(self : Node[A], path : Path) -> (A, Node[A]) {
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
fn[A : Compare] Node::change_and_down(self : Node[A], value : A) -> Node[A] {
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
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   let first = queue.unsafe_pop()
///   @debug.assert_eq(first, @priority_queue.from_array([1, 2, 3]))
/// }
/// ```
#internal(unsafe, "Panics if the queue is empty.")
#doc(hidden)
#alias(pop_exn, deprecated)
pub fn[A : Compare] PriorityQueue::unsafe_pop(
  self : PriorityQueue[A],
) -> PriorityQueue[A] {
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
/// ```mbt check
/// test {
///   let queue = @priority_queue.PriorityQueue([])
///   @test.assert_eq(queue.push(1).length(), 1)
/// }
/// ```
pub fn[A : Compare] PriorityQueue::push(
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
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   @test.assert_eq(queue.peek(), Some(4))
/// }
/// ```
pub fn[A] PriorityQueue::peek(self : PriorityQueue[A]) -> A? {
  match self.node {
    Empty => None
    Leaf(a) | Branch(a, ..) => Some(a)
  }
}

///|
/// Checks if the immutable priority queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.PriorityQueue([])
///   inspect(queue.is_empty(), content="true")
///   @test.assert_eq(queue.push(1).is_empty(), false)
/// }
/// ```
pub fn[A] PriorityQueue::is_empty(self : PriorityQueue[A]) -> Bool {
  self.node is Empty
}

///|
/// Return the length of the immutable priority queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.PriorityQueue([])
///   inspect(queue.length(), content="0")
///   @test.assert_eq(queue.push(1).length(), 1)
/// }
/// ```
pub fn[A] PriorityQueue::length(self : PriorityQueue[A]) -> Int {
  self.size
}

///|
#deprecated("Use @debug.Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show + Compare] Show for PriorityQueue[A]

///|
pub impl[A : Show + Compare] Show for PriorityQueue[A] with fn output(
  self,
  logger,
) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/priority_queue.from_array([",
    suffix="])",
  )
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for PriorityQueue[
  X,
] with fn arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub impl[A : Compare] Eq for PriorityQueue[A] with fn equal(self, other) {
  physical_equal(self, other) ||
  (self.length() == other.length() && self.to_array() == other.to_array())
}

///|
pub impl[A : Hash + Compare] Hash for PriorityQueue[A] with fn hash_combine(
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
/// ```mbt check
/// test {
///   let pq1 = @priority_queue.from_array([1, 2, 3])
///   let pq2 = @priority_queue.from_array([1, 2, 4])
///   let pq3 = @priority_queue.from_array([1, 2])
///   inspect(pq1.compare(pq2), content="-1") // pq1 < pq2
///   inspect(pq1.compare(pq3), content="1") // pq2 > pq1
///   inspect(pq3.compare(pq1), content="-1") // pq1 > pq3 (longer)
///   inspect(pq1.compare(pq1), content="0") // pq1 = pq1
/// }
/// ```
pub impl[A : Compare] Compare for PriorityQueue[A] with fn compare(self, other) {
  let len_cmp = self.length().compare(other.length())
  if len_cmp != 0 {
    return len_cmp
  }
  let self_arr = self.to_array()
  let other_arr = other.to_array()
  for i, x in self_arr {
    let cmp = x.compare(other_arr[i])
    if cmp != 0 {
      return cmp
    }
  } nobreak {
    return 0
  }
}
