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
pub fn T::new[A]() -> T[A] {
  { length: 0, first: Nil, last: Nil }
}

/// Creates a new queue from an array.
///
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::from_array([1, 2, 3, 4])
/// ```
pub fn T::from_array[A](arr : Array[A]) -> T[A] {
  if arr.length() == 0 {
    return new()
  }
  let queue : T[A] = T::new()
  queue.length = arr.length()
  queue.last = Cons({ content: arr[queue.length - 1], next: Nil })
  queue.first = queue.last
  for i = arr.length() - 2; i >= 0; i = i - 1 {
    queue.first = Cons({ content: arr[i], next: queue.first })
  }
  queue
}

pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_string("@queue.of([")
  self.eachi(
    fn(i, t) {
      if i > 0 {
        logger.write_string(", ")
      }
      t.output(logger)
    },
  )
  logger.write_string("])")
}

// Reuse the default implementation of [Show::to_string] here
pub fn to_string[A : Show](self : T[A]) -> String {
  Show::to_string(self)
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

/// Tests if two queues are equal.
fn op_equal[A : Eq](self : T[A], other : T[A]) -> Bool {
  self.length == other.length && self.first == other.first
}

/// Clears the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// queue.clear()
/// ```
pub fn clear[A](self : T[A]) -> Unit {
  self.length = 0
  self.first = Nil
  self.last = Nil
}

/// Get the length of the queue.
///
/// # Example
/// ```
/// of([1, 2, 3, 4]).length()
/// ```
pub fn length[A](self : T[A]) -> Int {
  self.length
}

/// Checks if the queue is empty.
///
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::new()
/// let is_empty = queue.is_empty()
/// ```
pub fn is_empty[A](self : T[A]) -> Bool {
  self.length == 0
}

/// Adds a value to the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::new()
/// queue.add(1)
/// ```
pub fn push[A](self : T[A], x : A) -> Unit {
  let cell : Cell[A] = Cons({ content: x, next: Nil })
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

/// Peeks at the first value in the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let first = queue.peek_exn()
/// ```
/// @alert unsafe "Panics if the queue is empty."
pub fn peek_exn[A](self : T[A]) -> A {
  match self.first {
    Nil => abort("Queue is empty")
    Cons(first) => first.content
  }
}

/// Peeks at the first value in the queue, which returns None if the queue is empty.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let first = queue.peek()
/// ```
pub fn peek[A](self : T[A]) -> A? {
  match self.first {
    Nil => None
    Cons(first) => Some(first.content)
  }
}

/// Pops the first value from the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let first = queue.pop_exn()
/// ```
/// @alert unsafe "Panics if the queue is empty."
pub fn pop_exn[A](self : T[A]) -> A {
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

/// Pops the first value from the queue, which returns None if the queue is empty.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let first = queue.pop()
/// ```
pub fn pop[A](self : T[A]) -> A? {
  if self.length == 0 {
    None
  } else {
    Some(self.pop_exn())
  }
}

/// Iterates over the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// queue.each(fn(x) { print(x) })
/// ```
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
  loop self.first {
    Cons({ content, next }) => {
      f(content)
      continue next
    }
    Nil => ()
  }
}

pub fn eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  loop self.first, 0 {
    Cons({ content, next }), index => {
      f(index, content)
      continue next, index + 1
    }
    Nil, _ => ()
  }
}

/// Folds over the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let sum = queue.fold(0, fn(acc, x) { acc + x })
/// ```
pub fn fold[A](self : T[A], ~init : A, f : (A, A) -> A) -> A {
  loop self.first, init {
    cell, acc =>
      match cell {
        Nil => acc
        Cons({ content, next }) => continue next, f(acc, content)
      }
  }
}

/// Return a copy of the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let queue2 : Queue[Int] = queue.copy()
/// ```
pub fn copy[A](self : T[A]) -> T[A] {
  loop
    { length: self.length, first: Nil, last: Nil },
    (Nil : Cell[A]),
    self.first {
    qres, prev, cell =>
      match cell {
        Nil => {
          qres.last = prev
          qres
        }
        Cons({ content, next }) => {
          let res : Cell[A] = Cons({ content, next: Nil })
          match prev {
            Nil => qres.first = res
            Cons(p) => p.next = res
          }
          continue qres, res, next
        }
      }
  }
}

/// Transfer all elements from one queue to another.
///
/// Adds all of the elements of source to the end of destination, then clears source.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let queue2 : Queue[Int] = of([5, 6, 7, 8])
/// queue.transfer(queue2)
/// ```
pub fn transfer[A](self : T[A], dst : T[A]) -> Unit {
  if self.length > 0 {
    match dst.last {
      Nil => {
        dst.length = self.length
        dst.first = self.first
        dst.last = self.last
        self.clear()
      }
      Cons(last) => {
        last.next = self.first
        dst.length = dst.length + self.length
        dst.last = self.last
        self.clear()
      }
    }
  }
}

pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(
    fn(yield) {
      loop self.first {
        Cons({ content, next }) => {
          if yield(content) == IterEnd {
            break IterEnd
          }
          continue next
        }
        Nil => IterContinue
      }
    },
  )
}

pub fn T::of[A](arr : FixedArray[A]) -> T[A] {
  if arr.length() == 0 {
    return new()
  }
  let queue : T[A] = T::new()
  queue.length = arr.length()
  queue.last = Cons({ content: arr[queue.length - 1], next: Nil })
  queue.first = queue.last
  for i = arr.length() - 2; i >= 0; i = i - 1 {
    queue.first = Cons({ content: arr[i], next: queue.first })
  }
  queue
}

test "from_fixed_array_2" {
  let q = of([1, 2, 3, 4])
  q.push(11)
  @test.eq!(q, of([1, 2, 3, 4, 11]))
  q.pop_exn() |> ignore
  @test.eq!(q, of([2, 3, 4, 11]))
}

test "from_array_2" {
  let q = of([1, 2, 3, 4])
  q.push(11)
  @test.eq!(q, of([1, 2, 3, 4, 11]))
  q.pop_exn() |> ignore
  @test.eq!(q, of([2, 3, 4, 11]))
}

test "op_equal" {
  let queue = of([1, 2, 3, 4])
  let queue2 = of([1, 2, 3, 4])
  let queue3 = of([1, 2, 3, 5])
  @test.is_true!(queue == queue2)
  @test.is_false!(queue == queue3)
  queue.pop_exn() |> ignore
  @test.is_false!(queue == queue2)
  @test.eq!(queue, of([2, 3, 4]))
}

test "push" {
  let queue : T[Int] = new()
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(1)
  @test.eq!(queue.length(), 4)
  @test.eq!(queue, of([1, 2, 3, 1]))
}

test "copy" {
  let queue : T[Int] = of([1, 2, 3, 4])
  let queue2 : T[Int] = queue.copy()
  @test.eq!(queue2.length(), 4)
  @test.eq!(queue2, of([1, 2, 3, 4]))
  @test.eq!(queue.length(), 4)
  @test.eq!(queue, of([1, 2, 3, 4]))
}

test "transfer" {
  let queue : T[Int] = of([1, 2, 3, 4])
  let queue2 : T[Int] = of([5, 6, 7, 8])
  queue.transfer(queue2)
  @test.eq!(queue.length(), 0)
  @test.eq!(queue2.length(), 8)
  @test.eq!(queue2, of([5, 6, 7, 8, 1, 2, 3, 4]))
}

test "cell_equal" {
  @test.is_false!(of([]).first == of([1]).first)
}
