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
/// Creates a new empty priority queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @priority_queue.PriorityQueue[Int] = @priority_queue.new()
///   assert_eq(queue.length(), 0)
/// }
/// ```
#as_free_fn
pub fn[A] PriorityQueue::new() -> PriorityQueue[A] {
  { len: 0, top: None }
}

///|
/// Creates a new priority queue from an array.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4, 5])
///   assert_eq(queue.length(), 5)
/// }
/// ```
#as_free_fn
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[A : Compare] PriorityQueue::from_array(
  arr : ArrayView[A],
) -> PriorityQueue[A] {
  guard arr is [a0, ..] else { return new() }
  let len = arr.length()
  for i = 1, acc = { content: a0, sibling: None, child: None } {
    if i < len {
      continue i + 1, meld(acc, { content: arr[i], sibling: None, child: None })
    } else {
      break { len, top: Some(acc) }
    }
  }
}

///|
fn[A] copy_node(x : Node[A]?) -> Node[A]? {
  match x {
    None => None
    Some(node) =>
      Some({
        content: node.content,
        sibling: copy_node(node.sibling),
        child: copy_node(node.child),
      })
  }
}

///|
/// Return a copy of the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   let queue2 = queue.copy()
///   inspect(queue2.length(), content="4")
/// }
/// ```
pub fn[A] PriorityQueue::copy(self : PriorityQueue[A]) -> PriorityQueue[A] {
  let new_que : PriorityQueue[A] = { len: self.len, top: copy_node(self.top) }
  new_que
}

///|
pub fn[A : Compare] PriorityQueue::to_array(
  self : PriorityQueue[A],
) -> Array[A] {
  let arr = Array::new(capacity=self.len)
  let stack : Array[Node[A]?] = [self.top]
  while stack.pop() is Some(node) {
    match node {
      None => ()
      Some({ content, sibling, child }) => {
        arr.push(content)
        stack.push(sibling)
        stack.push(child)
      }
    }
  }
  arr.sort()
  arr.rev_in_place()
  arr
}

///|
#alias(iterator, deprecated)
pub fn[A : Compare] PriorityQueue::iter(self : PriorityQueue[A]) -> Iter[A] {
  self.to_array().iter()
}

///|
pub impl[A : ToJson + Compare] ToJson for PriorityQueue[A] with to_json(self) {
  let arr = []
  for x in self {
    arr.push(x.to_json())
  }
  Json::array(arr)
}

///|
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Compare] PriorityQueue::from_iter(
  iter : Iter[K],
) -> PriorityQueue[K] {
  let s = new()
  while iter.next() is Some(e) {
    s.push(e)
  }
  s
}

///|
fn[A : Compare] meld(x : Node[A], y : Node[A]) -> Node[A] {
  if x.content > y.content {
    y.sibling = x.child
    x.child = Some(y)
    x
  } else {
    x.sibling = y.child
    y.child = Some(x)
    y
  }
}

///|
fn[A : Compare] merges(x : Node[A]?) -> Node[A]? {
  let (x, acc) = match x {
    None => return None
    Some({ sibling: None, .. }) as x => return x
    Some({ sibling: Some({ sibling: s2, .. } as s1), .. } as x) => {
      x.sibling = None
      s1.sibling = None
      (s2, meld(x, s1))
    }
  }
  loop (x, acc) {
    (None, acc) => Some(acc)
    (Some({ sibling: None, .. } as x), acc) => Some(meld(acc, x))
    (Some({ sibling: Some({ sibling: s2, .. } as s1), .. } as x), acc) => {
      x.sibling = None
      s1.sibling = None
      continue (s2, meld(acc, meld(x, s1)))
    }
  }
}

///|
pub fn[A] PriorityQueue::length(self : PriorityQueue[A]) -> Int {
  self.len
}

///|
/// Pops the first value from the priority queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   queue.unsafe_pop()
///   inspect(queue.length(), content="3")
/// }
/// ```
#internal(unsafe, "Panic if the queue is empty.")
#doc(hidden)
pub fn[A : Compare] PriorityQueue::unsafe_pop(self : PriorityQueue[A]) -> Unit {
  self.top = match self.top {
    None => abort("The PriorityQueue is empty!")
    Some({ child, .. }) => merges(child)
  }
  self.len -= 1
}

///|
/// Pops the first value from the priority queue, which returns None if the queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   let first = queue.pop() // Some(4)
///   inspect(first, content="Some(4)")
///   inspect(queue.length(), content="3")
/// }
/// ```
pub fn[A : Compare] PriorityQueue::pop(self : PriorityQueue[A]) -> A? {
  match self.top {
    None => None
    Some({ content, child, .. }) => {
      self.len -= 1
      self.top = merges(child)
      Some(content)
    }
  }
}

///|
/// Adds a value to the priority queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.new()
///   queue.push(1)
///   assert_eq(queue.length(), 1)
/// }
/// ```
pub fn[A : Compare] PriorityQueue::push(
  self : PriorityQueue[A],
  value : A,
) -> Unit {
  let x = { content: value, sibling: None, child: None }
  self.top = match self.top {
    None => Some(x)
    Some(top) => Some(meld(top, x))
  }
  self.len += 1
}

///|
/// Peeks at the first value in the priority queue, which returns None if the priority queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   let first = queue.peek() // Some(4)
///   assert_eq(first, Some(4))
/// }
/// ```
pub fn[A] PriorityQueue::peek(self : PriorityQueue[A]) -> A? {
  match self.top {
    None => None
    Some({ content, .. }) => Some(content)
  }
}

///|
/// Clears the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue = @priority_queue.from_array([1, 2, 3, 4])
///   queue.clear()
///   assert_eq(queue.length(), 0)
/// }
/// ```
pub fn[A] PriorityQueue::clear(self : PriorityQueue[A]) -> Unit {
  self.top = None
  self.len = 0
}

///|
/// Checks if the priority queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @priority_queue.PriorityQueue[Int] = @priority_queue.new()
///   assert_eq(queue.is_empty(), true)
/// }
/// ```
pub fn[A] PriorityQueue::is_empty(self : PriorityQueue[A]) -> Bool {
  self.len == 0
}

///|
pub impl[A : Show + Compare] Show for PriorityQueue[A] with output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@priority_queue.from_array([",
    suffix="])",
  )
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for PriorityQueue[
  X,
] with arbitrary(size, rs) {
  let len = if size == 0 { 0 } else { rs.next_positive_int() % size }
  guard len > 0 else { return new() }
  for i = 1, acc = { content: X::arbitrary(0, rs), sibling: None, child: None } {
    if i < len {
      continue i + 1,
        meld(acc, { content: X::arbitrary(i, rs), sibling: None, child: None })
    } else {
      break { len, top: Some(acc) }
    }
  }
}

///|
test "priority queue arbitrary" {
  let samples : Array[PriorityQueue[Int]] = @quickcheck.samples(20)
  inspect(
    samples[5:10],
    content="[@priority_queue.from_array([]), @priority_queue.from_array([]), @priority_queue.from_array([0]), @priority_queue.from_array([0, 0]), @priority_queue.from_array([3, 2, 1, 0, 0, 0, 0])]",
  )
  inspect(
    samples[11:15],
    content="[@priority_queue.from_array([0, 0, 0, -1, -2]), @priority_queue.from_array([8, 4, 0, 0, 0, 0, 0, 0, -2, -5]), @priority_queue.from_array([2, 0, 0, -1]), @priority_queue.from_array([0, 0])]",
  )
}

///|
pub impl[K] Default for PriorityQueue[K] with default() {
  new()
}
