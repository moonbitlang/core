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

/// Creates a new empty priority queue.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = PriorityQueue::new()
/// ```
pub fn PriorityQueue::new[T : Compare]() -> PriorityQueue[T] {
  { len: 0, top: Nil }
}

test "new" {
  let queue : PriorityQueue[Int] = new()
  @test.assert_eq(queue.len, 0)?
}

/// Creates a new empty priority queue from an array.
/// 
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4, 5]
/// ```
pub fn PriorityQueue::from_array[T : Compare](
  arr : Array[T]
) -> PriorityQueue[T] {
  // CR: bad formatting  
  let len = arr.length()
  for i = 0, acc = Node::Nil {
    if i < len {
      continue i + 1,
        meld(acc, Cons({ content: arr[i], sibling: Nil, child: Nil }))
    } else {
      break { len, top: acc }
    }
  }
}

test "from_array" {
  let pq = PriorityQueue::[1, 2, 3, 4, 5]
  @test.assert_eq(pq.peek(), Some(5))?
}

fn meld[T : Compare](x : Node[T], y : Node[T]) -> Node[T] {
  match (x, y) {
    (Nil, _) => y
    (_, Nil) => x
    (Cons(x_top), Cons(y_top)) =>
      if x_top.content > y_top.content {
        y_top.sibling = x_top.child
        x_top.child = y
        x
      } else {
        x_top.sibling = y_top.child
        y_top.child = x
        y
      }
  }
}

fn merges[T : Compare](x : Node[T]) -> Node[T] {
  match x {
    Nil => Nil
    Cons(top) =>
      match top.sibling {
        Nil => x
        Cons(next_top) =>
          match next_top.sibling {
            Nil => meld(x, top.sibling)
            Cons(_) => meld(merges(next_top.sibling), meld(x, top.sibling))
          }
      }
  }
}

pub fn length[T](self : PriorityQueue[T]) -> Int {
  self.len
}

test "length" {
  let pq : PriorityQueue[Int] = PriorityQueue::new()
  @test.assert_eq(pq.length(), 0)?
  pq.push(1)
  @test.assert_eq(pq.length(), 1)?
  pq.push(2)
  @test.assert_eq(pq.length(), 2)?
  pq.pop_exn()
  @test.assert_eq(pq.length(), 1)?
}

/// Pops the first value from the priority queue.
/// 
/// Panics if the queue is empty.
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4]
/// let first = queue.pop_exn() // 4
/// ```
pub fn pop_exn[T : Compare](self : PriorityQueue[T]) -> Unit {
  if self.len == 0 {
    abort("The PriorityQueue is empty!")
  }
  self.top = match self.top {
    Nil => Nil
    Cons(top) => merges(top.child)
  }
  self.len -= 1
}

test "pop_exn" {
  let pq = PriorityQueue::[5, 5, 4, 3, 2, 1]
  @test.assert_eq(pq.peek(), Some(5))?
  pq.pop_exn()
  @test.assert_eq(pq.peek(), Some(5))?
  pq.pop_exn()
  @test.assert_eq(pq.peek(), Some(4))?
}

/// Pops the first value from the priority queue, which returns None if the queue is empty.
/// 
/// Panics if the queue is empty.
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4]
/// let first = queue.pop() // Some(4)
/// ```
pub fn pop[T : Compare](self : PriorityQueue[T]) -> Option[T] {
  let result = self.peek()
  self.top = match self.top {
    Nil => Nil
    Cons(top) => {
      self.len -= 1
      merges(top.child)
    }
  }
  result
}

test "pop" {
  let pq = PriorityQueue::[1, 2, 3, 4, 5, 5]
  @test.assert_eq(pq.pop(), Some(5))?
  @test.assert_eq(pq.pop(), Some(5))?
  @test.assert_eq(pq.pop(), Some(4))?
}

/// Adds a value to the priority queue.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = PriorityQueue::new()
/// queue.add(1)
/// ```
pub fn push[T : Compare](self : PriorityQueue[T], value : T) -> Unit {
  self.top = meld(self.top, Cons({ content: value, sibling: Nil, child: Nil }))
  self.len += 1
}

test "push" {
  let pq = PriorityQueue::[5, 4, 3, 2, 1]
  pq.push(-1)
  pq.push(6)
  @test.assert_eq(pq.length(), 7)?
  @test.assert_eq(pq.peek(), Some(6))?
}

/// Peeks at the first value in the priority queue, which returns None if the priority queue is empty.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = PriorityQueue::[1, 2, 3, 4]
/// let first = queue.peek() // Some(4)
/// ```
pub fn peek[T](self : PriorityQueue[T]) -> Option[T] {
  match self.top {
    Nil => None
    Cons(top) => Some(top.content)
  }
}

test "peek" {
  let pq = PriorityQueue::[1, 2, 3, 4, 5]
  @test.assert_eq(pq.peek(), Some(5))?
  pq.clear()
  @test.assert_eq(pq.peek(), None)?
}

/// Clears the queue.
/// 
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4]
/// queue.clear()
/// ```
pub fn clear[T](self : PriorityQueue[T]) -> Unit {
  self.top = Nil
  self.len = 0
}

test "clear" {
  let pq = PriorityQueue::[5, 4, 3, 2, 1]
  pq.clear()
  @test.assert_eq(pq.length(), 0)?
}

/// Checks if the priority queue is empty.
/// 
/// # Example
/// ```
/// let queue : Priorityt[Int] = Priority::new()
/// let is_empty = queue.is_empty() // true
/// ```
pub fn is_empty[T](self : PriorityQueue[T]) -> Bool {
  self.len == 0
}

test "is_empty" {
  let pq = PriorityQueue::[5, 4, 3, 2, 1]
  @test.assert_eq(pq.is_empty(), false)?
  pq.clear()
  @test.assert_eq(pq.is_empty(), true)?
}
