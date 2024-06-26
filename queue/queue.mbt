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

pub fn to_string[T : Show](self : Queue[T]) -> String {
  let mut res = "Queue.of(["
  self.iteri(
    fn(i, t) {
      if i > 0 {
        res += ", "
      }
      res += t.to_string()
    },
  )
  res + "])"
}

pub fn debug_write[T : Show](self : Queue[T], buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
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
fn op_equal[T : Eq](self : Queue[T], other : Queue[T]) -> Bool {
  self.length == other.length && self.first == other.first
}

/// Clears the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// queue.clear()
/// ```
pub fn clear[T](self : Queue[T]) -> Unit {
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

/// Peeks at the first value in the queue.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let first = queue.peek_exn()
/// ```
/// @alert unsafe "Panics if the queue is empty."
pub fn peek_exn[T](self : Queue[T]) -> T {
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
pub fn peek[T](self : Queue[T]) -> T? {
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

/// Pops the first value from the queue, which returns None if the queue is empty.
///
/// # Example
/// ```
/// let queue : Queue[Int] = of([1, 2, 3, 4])
/// let first = queue.pop()
/// ```
pub fn pop[T](self : Queue[T]) -> T? {
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

pub fn iteri[T](self : Queue[T], f : (Int, T) -> Unit) -> Unit {
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
pub fn fold[T](self : Queue[T], ~init : T, f : (T, T) -> T) -> T {
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
pub fn copy[T](self : Queue[T]) -> Queue[T] {
  loop
    { length: self.length, first: Nil, last: Nil },
    (Nil : Cell[T]),
    self.first {
    qres, prev, cell =>
      match cell {
        Nil => {
          qres.last = prev
          qres
        }
        Cons({ content, next }) => {
          let res : Cell[T] = Cons({ content, next: Nil })
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
pub fn transfer[T](self : Queue[T], dst : Queue[T]) -> Unit {
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

pub fn as_iter[T](self : Queue[T]) -> Iter[T] {
  Iter::_unstable_internal_make(
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

pub fn Queue::of[T](arr : FixedArray[T]) -> Queue[T] {
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
