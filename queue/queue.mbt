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

///|
/// Creates a new empty queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.new()
/// assert_eq!(queue.length(), 0)
/// ```
pub fn T::new[A]() -> T[A] {
  { length: 0, first: Nil, last: Nil }
}

///|
/// Creates a new queue from an array.
///
/// # Example
/// ```
/// let array = Array::makei(3, fn(idx) { idx + 1 })
/// let queue : @queue.T[Int] = @queue.from_array(array)
/// assert_eq!(queue.length(), 3)
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

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@queue.of([", suffix="])")
}

///|
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

///|
/// Tests if two queues are equal.
fn op_equal[A : Eq](self : T[A], other : T[A]) -> Bool {
  self.length == other.length && self.first == other.first
}

///|
/// Clears the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// queue.clear()
/// ```
pub fn clear[A](self : T[A]) -> Unit {
  self.length = 0
  self.first = Nil
  self.last = Nil
}

///|
/// Get the length of the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.new()
/// assert_eq!(queue.length(), 0)
/// ```
pub fn length[A](self : T[A]) -> Int {
  self.length
}

///|
/// Checks if the queue is empty.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.new()
/// assert_true!(queue.is_empty())
/// ```
pub fn is_empty[A](self : T[A]) -> Bool {
  self.length == 0
}

///|
/// Adds a value to the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.new()
/// queue.push(1)
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

///|
/// Peeks at the first value in the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// assert_eq!(queue.unsafe_peek(), 1)
/// ```
/// @alert unsafe "Panics if the queue is empty."
pub fn unsafe_peek[A](self : T[A]) -> A {
  match self.first {
    Nil => abort("Queue is empty")
    Cons(first) => first.content
  }
}

///|
/// @alert deprecated "Use `unsafe_peek` instead"
/// @coverage.skip
pub fn peek_exn[A](self : T[A]) -> A {
  unsafe_peek(self)
}

///|
/// Peeks at the first value in the queue, which returns None if the queue is empty.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// assert_eq!(queue.peek(), Some(1))
/// ```
pub fn peek[A](self : T[A]) -> A? {
  match self.first {
    Nil => None
    Cons(first) => Some(first.content)
  }
}

///|
/// Pops the first value from the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// assert_eq!(queue.unsafe_pop(), 1)
/// ```
/// @alert unsafe "Panics if the queue is empty."
pub fn unsafe_pop[A](self : T[A]) -> A {
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

///|
/// @alert deprecated "Use `unsafe_pop` instead"
/// @coverage.skip
pub fn pop_exn[A](self : T[A]) -> A {
  unsafe_pop(self)
}

///|
/// Pops the first value from the queue, which returns None if the queue is empty.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// assert_eq!(queue.pop(), Some(1))
/// ```
pub fn pop[A](self : T[A]) -> A? {
  if self.length == 0 {
    None
  } else {
    Some(self.unsafe_pop())
  }
}

///|
/// Iterates over the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// let mut sum = 0
/// queue.each(fn(x) { sum = sum + x })
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

///|
/// Iterates over the queue with index.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// let mut sum = 0
/// queue.eachi(fn(x, i) { sum = sum + x * i })
/// ```
pub fn eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  loop self.first, 0 {
    Cons({ content, next }), index => {
      f(index, content)
      continue next, index + 1
    }
    Nil, _ => ()
  }
}

///|
/// Folds over the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.new()
/// let sum = queue.fold(init=0, fn(acc, x) { acc + x })
/// assert_eq!(sum, 0)
/// ```
pub fn fold[A, B](self : T[A], init~ : B, f : (B, A) -> B) -> B {
  loop self.first, init {
    Nil, acc => acc
    Cons({ content, next }), acc => continue next, f(acc, content)
  }
}

///|
/// Returns a copy of the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// let queue2 : @queue.T[Int] = queue.copy()
/// assert_eq!(queue2.length(), 4)
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

///|
/// Transfers all elements from one queue to another.
///
/// Adds all of the elements of source to the end of destination, then clears source.
///
/// # Example
/// ```
/// let dst : @queue.T[Int] = @queue.new()
/// let src : @queue.T[Int] = @queue.of([5, 6, 7, 8])
/// src.transfer(dst)
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

///|
/// Creates an iter from the queue.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([5, 6, 7, 8])
/// let sum = queue.iter().fold(fn(x, y) { x + y }, init=0)
/// assert_eq!(sum, 26)
/// ```
pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    loop self.first {
      Cons({ content, next }) => {
        if yield_(content) == IterEnd {
          break IterEnd
        }
        continue next
      }
      Nil => IterContinue
    }
  })
}

///|
/// Creates a new queue from an iter.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.T::from_iter(Iter::empty())
/// assert_eq!(queue.length(), 0)
/// ```
pub fn T::from_iter[A](iter : Iter[A]) -> T[A] {
  let q = T::new()
  iter.each(fn(e) { q.push(e) })
  q
}

///|
/// Creates a new queue from a FixedArray.
///
/// # Example
/// ```
/// let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
/// assert_eq!(queue.length(), 4)
/// ```
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
  assert_eq!(q, of([1, 2, 3, 4, 11]))
  q.unsafe_pop() |> ignore
  assert_eq!(q, of([2, 3, 4, 11]))
}

test "from_array_2" {
  let q = of([1, 2, 3, 4])
  q.push(11)
  assert_eq!(q, of([1, 2, 3, 4, 11]))
  q.unsafe_pop() |> ignore
  assert_eq!(q, of([2, 3, 4, 11]))
}

test "op_equal" {
  let queue = of([1, 2, 3, 4])
  let queue2 = of([1, 2, 3, 4])
  let queue3 = of([1, 2, 3, 5])
  assert_true!(queue == queue2)
  assert_false!(queue == queue3)
  queue.unsafe_pop() |> ignore
  assert_false!(queue == queue2)
  assert_eq!(queue, of([2, 3, 4]))
}

test "push" {
  let queue : T[Int] = new()
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(1)
  assert_eq!(queue.length(), 4)
  assert_eq!(queue, of([1, 2, 3, 1]))
}

test "copy" {
  let queue : T[Int] = of([1, 2, 3, 4])
  let queue2 : T[Int] = queue.copy()
  assert_eq!(queue2.length(), 4)
  assert_eq!(queue2, of([1, 2, 3, 4]))
  assert_eq!(queue.length(), 4)
  assert_eq!(queue, of([1, 2, 3, 4]))
}

test "transfer" {
  let queue : T[Int] = of([1, 2, 3, 4])
  let queue2 : T[Int] = of([5, 6, 7, 8])
  queue.transfer(queue2)
  assert_eq!(queue.length(), 0)
  assert_eq!(queue2.length(), 8)
  assert_eq!(queue2, of([5, 6, 7, 8, 1, 2, 3, 4]))
}

test "cell_equal" {
  assert_false!(of([]).first == of([1]).first)
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> T::from_iter
}

test "queue arbitrary" {
  let samples : Array[T[Int]] = @quickcheck.samples(20)
  inspect!(
    samples[1:5],
    content="[@queue.of([]), @queue.of([0]), @queue.of([0]), @queue.of([0])]",
  )
  inspect!(
    samples[15],
    content="@queue.of([0, 0, 0, 0, 0, -1, -3, -3, -1, -4, 5, -1])",
  )
}
