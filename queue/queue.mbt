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

/// Creates a new empty queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::new()
/// ```
pub fn Queue::new[T]() -> Queue[T] {
  { length: 0, first: Nil, last: Nil }
}

test "new" {
  let queue : Queue[Int] = new()
  @test.eq(queue.length, 0)?
}

/// Creates a new queue from an array.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::from_array([1, 2, 3, 4])
/// ```
pub fn Queue::from_array[T](arr : Array[T]) -> Queue[T] {
  if arr.length() == 0 {
    return new()
  }
  let queue : Queue[T] = Queue::new()
  queue.length = arr.length()
  queue.last = Cons({ content: arr[queue.length - 1], next: Nil })
  queue.first = queue.last
  for i = arr.length() - 2; i >= 0; i = i - 1 {
    queue.first = Cons({ content: arr[i], next: queue.first })
  }
  queue
}

test "from_array_1" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  let queue2 : Queue[Int] = Queue::[1]
  @test.eq(queue.length, 4)?
  @test.eq(queue.pop_exn(), 1)?
  @test.eq(queue.pop_exn(), 2)?
  @test.eq(queue.pop_exn(), 3)?
  @test.eq(queue.pop_exn(), 4)?
  @test.eq(queue2.pop_exn(), 1)?
  @test.eq(queue2.length, 0)?
}

test "from_array_2" {
  let q = Queue::[1, 2, 3, 4]
  q.push(11)
  @test.eq(q.pop_exn(), 1)?
  @test.eq(q.pop_exn(), 2)?
}

/// Tests if two queue cells are equal.
fn op_equal[T : Eq](self : Cell[T], other : Cell[T]) -> Bool {
  loop self, other {
    Nil, Nil => true
    Cons({ content: x, next: xs }), Cons({ content: y, next: ys }) =>
      if x == y {
        continue xs, ys
      } else {
        false
      }
    _, _ => false
  }
}

/// Clears the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// queue.clear()
/// ```
pub fn clear[T](self : Queue[T]) -> Unit {
  self.length = 0
  self.first = Nil
  self.last = Nil
}

test "clear" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @test.eq(queue.length, 4)?
  queue.clear()
  @test.eq(queue.length, 0)?
}

pub fn length[T](self : Queue[T]) -> Int {
  self.length
}

/// Checks if the queue is empty.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::new()
/// let is_empty = queue.is_empty()
/// ```
pub fn is_empty[T](self : Queue[T]) -> Bool {
  self.length == 0
}

test "is_empty" {
  let queue : Queue[Int] = new()
  @test.assert_true(queue.is_empty())?
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(4)
  @test.is_false(queue.is_empty())?
}

/// Adds a value to the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::new()
/// queue.add(1)
/// ```
pub fn push[T](self : Queue[T], x : T) -> Unit {
  let cell : Cell[T] = Cons({ content: x, next: Nil })
  match self.last {
    Nil => {
      self.length = 1
      self.first = cell
      self.last = cell
    }
    Cons(last) => {
      last.next = cell
      self.length = self.length + 1
      self.last = cell
    }
  }
}

test "push" {
  let queue : Queue[Int] = Queue::new()
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(1)
  @test.eq(queue.length, 4)?
  @test.eq(queue.pop_exn(), 1)?
  @test.eq(queue.pop_exn(), 2)?
  @test.eq(queue.pop_exn(), 3)?
  @test.eq(queue.pop_exn(), 1)?
}

/// Peeks at the first value in the queue.
/// 
/// Panics if the queue is empty.
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let first = queue.peek_exn()
/// ```
pub fn peek_exn[T](self : Queue[T]) -> T {
  match self.first {
    Nil => abort("Queue is empty")
    Cons(first) => first.content
  }
}

test "peek_exn" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @test.eq(queue.peek_exn(), 1)?
  @test.eq(queue.length, 4)?
  @test.eq(queue.pop_exn(), 1)?
  @test.eq(queue.peek_exn(), 2)?
  @test.eq(queue.length, 3)?
}

/// Peeks at the first value in the queue, which returns None if the queue is empty.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let first = queue.peek()
/// ```
pub fn peek[T](self : Queue[T]) -> Option[T] {
  match self.first {
    Nil => None
    Cons(first) => Some(first.content)
  }
}

test "peek" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @test.eq(queue.peek(), Some(1))?
  queue.clear()
  @test.eq(queue.peek(), None)?
}

/// Pops the first value from the queue.
/// 
/// Panics if the queue is empty.
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let first = queue.pop_exn()
/// ```
pub fn pop_exn[T](self : Queue[T]) -> T {
  match self.first {
    Nil => abort("Queue is empty")
    Cons({ content, next: Nil }) => {
      self.clear()
      content
    }
    Cons({ content, next }) => {
      self.length = self.length - 1
      self.first = next
      content
    }
  }
}

test "pop_exn" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @test.eq(queue.pop_exn(), 1)?
  @test.eq(queue.pop_exn(), 2)?
  @test.eq(queue.pop_exn(), 3)?
  @test.eq(queue.pop_exn(), 4)?
  @test.eq(queue.length, 0)?
}

/// Pops the first value from the queue, which returns None if the queue is empty.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let first = queue.pop()
/// ```
pub fn pop[T](self : Queue[T]) -> Option[T] {
  if self.length == 0 {
    None
  } else {
    Some(self.pop_exn())
  }
}

test "pop" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @test.eq(queue.pop(), Some(1))?
  @test.eq(queue.pop(), Some(2))?
  @test.eq(queue.pop(), Some(3))?
  @test.eq(queue.pop(), Some(4))?
  @test.eq(queue.pop(), None)?
}

/// Iterates over the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// queue.iter(fn(x) { print(x) })
/// ```
pub fn iter[T](self : Queue[T], f : (T) -> Unit) -> Unit {
  loop self.first {
    Cons({ content, next }) => {
      f(content)
      continue next
    }
    Nil => ()
  }
}

test "iter" {
  let queue : Queue[Int] = new()
  let mut sum = 0
  queue.iter(fn(x) { sum = sum + x })
  @test.eq(sum, 0)?
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(4)
  sum = 0
  queue.iter(fn(x) { sum = sum + x })
  @test.eq(sum, 10)?
}

/// Folds over the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let sum = queue.fold(0, fn(acc, x) { acc + x })
/// ```
pub fn fold[T](self : Queue[T], ~init : T, f : (T, T) -> T) -> T {
  loop self.first, init {
    cell, acc =>
      match cell {
        Nil => acc
        Cons({ content, next }) => continue next, f(acc, content)
      }
  }
}

test "fold" {
  let queue : Queue[Int] = new()
  let sum = queue.fold(~init=0, fn(acc, x) { acc + x })
  @test.eq(sum, 0)?
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(4)
  let sum = queue.fold(~init=0, fn(acc, x) { acc + x })
  @test.eq(sum, 10)?
  let sum2 = Queue::[1, 2, 3, 4].fold(~init=0, fn(acc, x) { acc + x })
  @test.eq(sum2, 10)?
}
