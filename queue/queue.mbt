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
fn[A] new_queue() -> Queue[A] {
  { inner: Deque([]) }
}

///|
/// Creates a new queue from an array.
///
/// # Example
/// ```mbt check
/// test {
///   let array = Array::makei(3, idx => idx + 1)
///   let queue : @queue.Queue[Int] = Queue(array)
///   @test.assert_eq(queue.length(), 3)
/// }
/// ```
#alias(from_array)
#as_free_fn(from_array)
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[A] Queue::Queue(arr : ArrayView[A]) -> Queue[A] {
  { inner: Deque(arr) }
}

///|
#deprecated("Use @debug.Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show] Show for Queue[A]

///|
pub impl[A : Show] Show for Queue[A] with fn output(self, logger) {
  logger.write_iter(self.iter(), prefix="@queue.from_array([", suffix="])")
}

///|
/// Tests if two queues are equal.
impl[A : Eq] Eq for Queue[A] with fn equal(self, other) {
  self.inner == other.inner
}

///|
/// Clears the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   queue.clear()
/// }
/// ```
pub fn[A] Queue::clear(self : Queue[A]) -> Unit {
  self.inner.clear()
}

///|
/// Get the length of the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = Queue([])
///   @test.assert_eq(queue.length(), 0)
/// }
/// ```
pub fn[A] Queue::length(self : Queue[A]) -> Int {
  self.inner.length()
}

///|
/// Checks if the queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = Queue([])
///   assert_true(queue.is_empty())
/// }
/// ```
pub fn[A] Queue::is_empty(self : Queue[A]) -> Bool {
  self.inner.is_empty()
}

///|
/// Adds a value to the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = Queue([])
///   queue.push(1)
/// }
/// ```
pub fn[A] Queue::push(self : Queue[A], x : A) -> Unit {
  self.inner.push_back(x)
}

///|
/// Peeks at the first value in the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   @test.assert_eq(queue.unsafe_peek(), 1)
/// }
/// ```
#internal(unsafe, "Panics if the queue is empty.")
#doc(hidden)
#alias(peek_exn, deprecated)
pub fn[A] Queue::unsafe_peek(self : Queue[A]) -> A {
  match self.inner.front() {
    None => abort("Queue is empty")
    Some(x) => x
  }
}

///|
/// Peeks at the first value in the queue, which returns None if the queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   @test.assert_eq(queue.peek(), Some(1))
/// }
/// ```
pub fn[A] Queue::peek(self : Queue[A]) -> A? {
  self.inner.front()
}

///|
/// Pops the first value from the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   @test.assert_eq(queue.unsafe_pop(), 1)
/// }
/// ```
#internal(unsafe, "Panics if the queue is empty.")
#doc(hidden)
#alias(pop_exn, deprecated)
pub fn[A] Queue::unsafe_pop(self : Queue[A]) -> A {
  match self.inner.pop_front() {
    None => abort("Queue is empty")
    Some(x) => x
  }
}

///|
/// Pops the first value from the queue, which returns None if the queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   @test.assert_eq(queue.pop(), Some(1))
/// }
/// ```
pub fn[A] Queue::pop(self : Queue[A]) -> A? {
  self.inner.pop_front()
}

///|
/// Iterates over the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   let mut sum = 0
///   queue.each(x => sum = sum + x)
/// }
/// ```
#locals(f)
pub fn[A] Queue::each(self : Queue[A], f : (A) -> Unit) -> Unit {
  for x in self.inner {
    f(x)
  }
}

///|
/// Iterates over the queue with index.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   let mut sum = 0
///   queue.eachi((i, x) => sum = sum + i * x)
/// }
/// ```
#locals(f)
pub fn[A] Queue::eachi(self : Queue[A], f : (Int, A) -> Unit) -> Unit {
  for i, x in self.inner {
    f(i, x)
  }
}

///|
/// Folds over the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = Queue([])
///   let sum = queue.fold(init=0, (acc, x) => acc + x)
///   @test.assert_eq(sum, 0)
/// }
/// ```
#locals(f)
pub fn[A, B] Queue::fold(self : Queue[A], init~ : B, f : (B, A) -> B) -> B {
  let mut acc = init
  for x in self.inner {
    acc = f(acc, x)
  }
  acc
}

///|
/// Returns a copy of the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
///   let queue2 : @queue.Queue[Int] = queue.copy()
///   @test.assert_eq(queue2.length(), 4)
/// }
/// ```
#alias(clone, deprecated)
pub fn[A] Queue::copy(self : Queue[A]) -> Queue[A] {
  { inner: self.inner.copy() }
}

///|
/// Transfers all elements from one queue to another.
///
/// Adds all of the elements of source to the end of destination, then clears source.
/// If source and destination are the same queue, this is a no-op.
///
/// # Example
/// ```mbt check
/// test {
///   let dst : @queue.Queue[Int] = Queue([])
///   let src : @queue.Queue[Int] = @queue.from_array([5, 6, 7, 8])
///   src.transfer(dst)
/// }
/// ```
pub fn[A] Queue::transfer(self : Queue[A], dst : Queue[A]) -> Unit {
  if physical_equal(self.inner, dst.inner) {
    return // no-op for self-transfer
  }
  dst.inner.append(self.inner)
  self.inner.clear()
}

///|
/// Creates an iter from the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([5, 6, 7, 8])
///   let sum = queue.iter().fold((x, y) => x + y, init=0)
///   @test.assert_eq(sum, 26)
/// }
/// ```
#alias(iterator, deprecated)
pub fn[A] Queue::iter(self : Queue[A]) -> Iter[A] {
  self.inner.iter()
}

///|
/// Creates a new queue from an iter.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_iter(Iter::empty())
///   @test.assert_eq(queue.length(), 0)
/// }
/// ```
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[A] Queue::from_iter(iter : Iter[A]) -> Queue[A] {
  { inner: @deque.from_iter(iter) }
}

///|
test "from_fixed_array_2" {
  let q = from_array([1, 2, 3, 4])
  q.push(11)
  @test.assert_eq(q, from_array([1, 2, 3, 4, 11]))
  q.unsafe_pop() |> ignore
  @test.assert_eq(q, from_array([2, 3, 4, 11]))
}

///|
test "from_array_2" {
  let q = from_array([1, 2, 3, 4])
  q.push(11)
  @test.assert_eq(q, from_array([1, 2, 3, 4, 11]))
  q.unsafe_pop() |> ignore
  @test.assert_eq(q, from_array([2, 3, 4, 11]))
}

///|
test "equal" {
  let queue = from_array([1, 2, 3, 4])
  let queue2 = from_array([1, 2, 3, 4])
  let queue3 = from_array([1, 2, 3, 5])
  assert_true(queue == queue2)
  assert_false(queue == queue3)
  queue.unsafe_pop() |> ignore
  assert_false(queue == queue2)
  @test.assert_eq(queue, from_array([2, 3, 4]))
  assert_false(from_array([]) == from_array([1]))
}

///|
test "push" {
  let queue : Queue[Int] = new_queue()
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(1)
  @test.assert_eq(queue.length(), 4)
  @test.assert_eq(queue, from_array([1, 2, 3, 1]))
}

///|
test "copy" {
  let queue : Queue[Int] = from_array([1, 2, 3, 4])
  let queue2 : Queue[Int] = queue.copy()
  @test.assert_eq(queue2.length(), 4)
  @test.assert_eq(queue2, from_array([1, 2, 3, 4]))
  @test.assert_eq(queue.length(), 4)
  @test.assert_eq(queue, from_array([1, 2, 3, 4]))
}

///|
test "transfer" {
  let queue : Queue[Int] = from_array([1, 2, 3, 4])
  let queue2 : Queue[Int] = from_array([5, 6, 7, 8])
  queue.transfer(queue2)
  @test.assert_eq(queue.length(), 0)
  @test.assert_eq(queue2.length(), 8)
  @test.assert_eq(queue2, from_array([5, 6, 7, 8, 1, 2, 3, 4]))
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for Queue[X] with fn arbitrary(
  size,
  rs,
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}
