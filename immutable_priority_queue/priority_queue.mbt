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

/// Creates a new empty immutable priority queue.
/// 
/// # Example
/// ```
/// let queue : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::new()
/// ```
pub fn ImmutablePriorityQueue::new[T : Compare]() -> ImmutablePriorityQueue[T] {
  Empty
}

/// Creates a new immutable priority queue from an array.
/// 
/// # Example
/// ```
/// let queue = ImmutablePriorityQueue::[1, 2, 3, 4, 5]
/// ```
pub fn ImmutablePriorityQueue::from_array[T : Compare](
  arr : Array[T]
) -> ImmutablePriorityQueue[T] {
  // CR: bad formatting  
  let len = arr.length()
  for i = 0, acc = ImmutablePriorityQueue::Empty {
    if i < len {
      continue i + 1, meld(acc, Node(arr[i], Nil))
    } else {
      break acc
    }
  }
}

test "from_array" {
  let queue = ImmutablePriorityQueue::[1, 2, 3, 4, 5]
  inspect(queue.peek(), ~content="Some(5)")?
}

fn meld[T : Compare](
  x : ImmutablePriorityQueue[T],
  y : ImmutablePriorityQueue[T]
) -> ImmutablePriorityQueue[T] {
  match (x, y) {
    (Empty, _) => y
    (_, Empty) => x
    (Node(x, left), Node(y, right)) =>
      if x > y {
        Node(x, Cons(Node(y, right), left))
      } else {
        Node(y, Cons(Node(x, left), right))
      }
  }
}

test "meld" {
  inspect(meld(Empty, ImmutablePriorityQueue::[1]).peek(), ~content="Some(1)")?
  inspect(meld(ImmutablePriorityQueue::[1], Empty).peek(), ~content="Some(1)")?
  inspect(
    meld(ImmutablePriorityQueue::[1], ImmutablePriorityQueue::[2]).peek(),
    ~content="Some(2)",
  )?
}

fn merges[T : Compare](
  x : List[ImmutablePriorityQueue[T]]
) -> ImmutablePriorityQueue[T] {
  match x {
    Nil => Empty
    Cons(t, Nil) => t
    Cons(t1, Cons(t2, ts)) => meld(meld(t1, t2), merges(ts))
  }
}

test "merges" {
  inspect(
    match merges((Nil : List[ImmutablePriorityQueue[Int]])) {
      Empty => true
      _ => false
    },
    ~content="true",
  )?
}

/// Pops the first value from the immutable priority queue, which returns None if the queue is empty.
/// 
/// # Example
/// ```
/// let queue = ImmutablePriorityQueue::[1, 2, 3, 4]
/// let first = queue.pop()
/// ```
pub fn pop[T : Compare](
  self : ImmutablePriorityQueue[T]
) -> Option[ImmutablePriorityQueue[T]] {
  match self {
    Empty => None
    Node(_, ts) => Some(merges(ts))
  }
}

test "pop" {
  let queue = ImmutablePriorityQueue::[1, 2, 3, 4]
  let first = queue.pop()
  inspect(
    match first {
      Some(q) => q.peek()
      None => None
    },
    ~content="Some(3)",
  )?
  let empty : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::[]
  inspect(
    match empty.pop() {
      Some(q) => q.peek()
      None => None
    },
    ~content="None",
  )?
}

/// Pops the first value from the immutable priority queue.
/// 
/// Panics if the queue is empty.
/// # Example
/// ```
/// let queue = ImmutablePriorityQueue::[1, 2, 3, 4]
/// let first = queue.pop()
/// ```
pub fn pop_exn[T : Compare](
  self : ImmutablePriorityQueue[T]
) -> ImmutablePriorityQueue[T] {
  match self {
    Empty => abort("The ImmutablePriorityQueue is empty!")
    Node(_, ts) => merges(ts)
  }
}

test "pop_exn" {
  let queue = ImmutablePriorityQueue::[1, 2, 3, 4]
  let first = queue.pop_exn()
  inspect(first.peek(), ~content="Some(3)")?
  inspect(
    queue.pop_exn().push(-1).push(10).push(11).pop_exn().pop_exn().push(50).peek(),
  ~content="Some(50)")?
}

/// Adds a value to the immutable priority queue.
/// 
/// # Example
/// ```
/// let queue : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::new()
/// queue.add(1)
/// ```
pub fn push[T : Compare](
  self : ImmutablePriorityQueue[T],
  value : T
) -> ImmutablePriorityQueue[T] {
  meld(self, Node(value, Nil))
}

test "push" {
  let queue = ImmutablePriorityQueue::[1, 2, 3]
  inspect(queue.push(4).peek(), ~content="Some(4)")?
}

/// Peeks at the first value in the immutable priority queue, which returns None if the immutable priority queue is empty.
/// 
/// # Example
/// ```
/// let queue : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::[1, 2, 3, 4]
/// queue.peek() // Some(4)
/// ```
pub fn peek[T](self : ImmutablePriorityQueue[T]) -> Option[T] {
  match self {
    Empty => None
    Node(v, _) => Some(v)
  }
}

test "peek" {
  let queue : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::new()
  inspect(queue.peek(), ~content="None")?
  inspect(queue.push(1).peek(), ~content="Some(1)")?
}

/// Checks if the immutable priority queue is empty.
/// 
/// # Example
/// ```
/// let queue : ImmutablePriorityt[Int] = ImmutablePriority::new()
/// queue.is_empty() // true
/// ```
pub fn is_empty[T](self : ImmutablePriorityQueue[T]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

test "is_empty" {
  let queue : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::new()
  inspect(queue.is_empty(), ~content="true")?
  inspect(queue.push(1).is_empty(), ~content="false")?
}
