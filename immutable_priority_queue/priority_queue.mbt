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
  { body: Empty, len: 0 }
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
  let len = arr.length()
  for i = 0, acc = Cont::Empty {
    if i < len {
      continue i + 1, meld(acc, Node(arr[i], Nil))
    } else {
      break { body: acc, len: arr.length() }
    }
  }
}

test "from_array" {
  let queue = ImmutablePriorityQueue::[1, 2, 3, 4, 5]
  inspect(queue.peek(), ~content="Some(5)")?
}

fn meld[T : Compare](l : Cont[T], r : Cont[T]) -> Cont[T] {
  match (l, r) {
    (Empty, _) => r
    (_, Empty) => l
    (Node(x, left), Node(y, right)) =>
      if x > y {
        Node(x, Cons(r, left))
      } else {
        Node(y, Cons(l, right))
      }
  }
}

test "meld" {
  inspect(meld(Empty, ImmutablePriorityQueue::[1].body), ~content="Node(1, List::[])")?
  inspect(meld(ImmutablePriorityQueue::[1].body, Empty), ~content="Node(1, List::[])")?
  inspect(
    meld(ImmutablePriorityQueue::[1].body, ImmutablePriorityQueue::[2].body),
  ~content="Node(2, List::[Node(1, List::[])])")?
}

fn merges[T : Compare](x : List[Cont[T]]) -> Cont[T] {
  match x {
    Nil => Empty
    Cons(t, Nil) => t
    Cons(t1, Cons(t2, ts)) => meld(meld(t1, t2), merges(ts))
  }
}

test "merges" {
  inspect(
    match merges((Nil : List[Cont[Int]])) {
      Empty => true
      _ => false
    },
  ~content="true")?
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
  match self.body {
    Empty => None
    Node(_, ts) =>
      Some({ body: merges(ts), len: self.len - 1 })
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
  match self.body {
    Empty => abort("The ImmutablePriorityQueue is empty!")
    Node(_, ts) =>
      { body: merges(ts), len: self.len - 1 }
  }
}

test "pop_exn" {
  let queue = ImmutablePriorityQueue::[1, 2, 3, 4]
  let first = queue.pop_exn()
  inspect(first.peek(), ~content="Some(3)")?
  inspect(
    queue.pop_exn().push(-1).push(10).push(11).pop_exn().pop_exn().push(50).peek(),
    ~content="Some(50)",
  )?
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
  {
    body: meld(self.body, Node(value, Nil)),
    len: self.len + 1,
  }
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
  match self.body {
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
  match self.body {
    Empty => true
    _ => false
  }
}

test "is_empty" {
  let queue : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::new()
  inspect(queue.is_empty(), ~content="true")?
  inspect(queue.push(1).is_empty(), ~content="false")?
}

/// Return the length of the immutable priority queue.
/// 
/// # Example
/// ```
/// let queue : ImmutablePriorityt[Int] = ImmutablePriority::new()
/// queue.length() // 0
/// queue.push(1).length() // 1
/// ```
pub fn length[T](self:ImmutablePriorityQueue[T])->Int{
  self.len
}
