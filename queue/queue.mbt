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
  { inner: Deque([]), }
}

///|
/// Creates a new queue holding the elements of `arr`, front first.
///
/// `capacity` preallocates room for at least that many elements (never less
/// than `arr.length()`), as in `@deque.Deque(arr, capacity=...)`. Aborts if
/// `capacity` is negative.
///
/// # Example
/// ```mbt check
/// test {
///   let array = Array::makei(3, idx => idx + 1)
///   let queue : @queue.Queue[Int32] = Queue(array)
///   @test.assert_eq(queue.length(), 3)
/// }
/// ```
#alias(from_array)
#as_free_fn(from_array)
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[A] Queue::Queue(arr : ArrayView[A], capacity? : Int32) -> Queue[A] {
  { inner: Deque(arr, capacity?), }
}

///|
#deprecated("Use @debug.Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show] Show for Queue[A]

///|
pub impl[A : Show] Show for Queue[A] with fn output(self, logger) {
  logger.write_iter(self.iter(), prefix="@queue.from_array([", suffix="])")
}

///|
/// Tests if two queues hold the same elements in the same order.
pub impl[A : Eq] Eq for Queue[A] with fn equal(self, other) {
  self.inner == other.inner
}

///|
/// Compares two queues in shortlex order, as `@deque.Deque::compare` does: by
/// length first (a shorter queue is less than a longer one), then
/// lexicographically from the front, by their first differing element.
///
/// # Example
///
/// ```mbt check
/// test {
///   let q1 : @queue.Queue[Int32] = @queue.from_array([1, 2, 3])
///   let q2 : @queue.Queue[Int32] = @queue.from_array([1, 2, 4])
///   let q3 : @queue.Queue[Int32] = @queue.from_array([1, 2])
///   inspect(q1.compare(q2), content="-1") // q1 < q2
///   inspect(q2.compare(q1), content="1") // q2 > q1
///   inspect(q1.compare(q3), content="1") // q1 > q3 (longer)
///   inspect(q1.compare(q1), content="0") // q1 = q1
/// }
/// ```
pub impl[A : Compare] Compare for Queue[A] with fn compare(self, other) {
  self.inner.compare(other.inner)
}

///|
/// Hashes the elements of the queue in order, front first, as
/// `@deque.Deque` does, so queues that are equal hash equally.
///
/// # Example
///
/// ```mbt check
/// test {
///   let q1 : @queue.Queue[Int32] = @queue.from_array([1, 2, 3])
///   let q2 : @queue.Queue[Int32] = @queue.from_array([1, 2, 3])
///   @test.assert_eq(q1.hash(), q2.hash())
/// }
/// ```
pub impl[A : Hash] Hash for Queue[A] with fn hash_combine(self, hasher) {
  Hash::hash_combine(self.inner, hasher)
}

///|
/// Clears the queue.
///
/// This keeps the memory the queue has allocated, only setting the length to 0.
///
/// Emptying a queue is a removal like any other: the queue may keep referring
/// to the elements that were in it until later pushes overwrite them or the
/// queue is dropped. Call `Queue::shrink_to_fit` to release them at once.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
///   queue.clear()
///   inspect(queue.length(), content="0")
/// }
/// ```
pub fn[A] Queue::clear(self : Queue[A]) -> Unit {
  self.inner.clear()
}

///|
/// Releases the memory the queue holds beyond its current elements.
///
/// Removing elements (`Queue::pop`, `Queue::clear`, or `Queue::transfer` on its
/// source) does not let go of them right away: the queue may keep referring to
/// them, so they stay reachable until later pushes overwrite them or the queue
/// is dropped. After this call the queue refers only to the elements it
/// currently holds, and its spare capacity is returned as well. The elements
/// and their order are unchanged.
///
/// This matters only for element types holding references; it costs an
/// allocation plus a copy of the current elements, and does nothing when the
/// queue has no spare capacity.
///
/// # Example
///
/// ```mbt check
/// test {
///   let queue : @queue.Queue[String] = @queue.from_array(["a", "b", "c"])
///   let _ = queue.pop()
///   queue.shrink_to_fit()
///   @debug.debug_inspect(
///     queue,
///     content=(
///       #|<Queue: ["b", "c"]>
///     ),
///   )
/// }
/// ```
pub fn[A] Queue::shrink_to_fit(self : Queue[A]) -> Unit {
  self.inner.shrink_to_fit()
}

///|
/// Get the length of the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = Queue([])
///   @test.assert_eq(queue.length(), 0)
/// }
/// ```
pub fn[A] Queue::length(self : Queue[A]) -> Int32 {
  self.inner.length()
}

///|
/// Checks if the queue is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = Queue([])
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
///   let queue : @queue.Queue[Int32] = Queue([])
///   queue.push(1)
/// }
/// ```
#owned(x)
pub fn[A] Queue::push(self : Queue[A], x : A) -> Unit {
  self.inner.push_back(x)
}

///|
/// Peeks at the first value in the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
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
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
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
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
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
/// The queue may keep referring to the removed element until a later push
/// overwrites it or the queue is dropped. Call `Queue::shrink_to_fit` to
/// release it at once.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
///   @test.assert_eq(queue.pop(), Some(1))
/// }
/// ```
pub fn[A] Queue::pop(self : Queue[A]) -> A? {
  self.inner.pop_front()
}

///|
/// Iterates over the queue.
///
/// If `f` pushes, pops or clears the queue, the result is memory-safe but
/// otherwise unspecified.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
///   let mut sum = 0
///   queue.each(x => sum += x)
///   inspect(sum, content="10")
/// }
/// ```
#locals(f)
pub fn[A] Queue::each(self : Queue[A], f : (A) -> Unit raise?) -> Unit raise? {
  for x in self.inner {
    f(x)
  }
}

///|
/// Iterates over the queue with index.
///
/// If `f` pushes, pops or clears the queue, the result is memory-safe but
/// otherwise unspecified.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
///   let mut sum = 0
///   queue.eachi((i, x) => sum += i * x)
///   inspect(sum, content="20")
/// }
/// ```
#locals(f)
pub fn[A] Queue::eachi(
  self : Queue[A],
  f : (Int32, A) -> Unit raise?,
) -> Unit raise? {
  for i, x in self.inner {
    f(i, x)
  }
}

///|
/// Folds over the queue.
///
/// If `f` pushes, pops or clears the queue, the result is memory-safe but
/// otherwise unspecified.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = Queue([])
///   let sum = queue.fold(init=0, (acc, x) => acc + x)
///   @test.assert_eq(sum, 0)
/// }
/// ```
#locals(f)
pub fn[A, B] Queue::fold(
  self : Queue[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
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
///   let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
///   let queue2 : @queue.Queue[Int32] = queue.copy()
///   @test.assert_eq(queue2.length(), 4)
/// }
/// ```
#alias(clone, deprecated)
pub fn[A] Queue::copy(self : Queue[A]) -> Queue[A] {
  { inner: self.inner.copy(), }
}

///|
/// Transfers all elements from one queue to another.
///
/// Adds all of the elements of source to the end of destination, then clears source.
/// If source and destination are the same queue, this is a no-op.
///
/// Like `Queue::clear`, emptying the source may leave it referring to the
/// transferred elements; call `Queue::shrink_to_fit` on it to release them.
///
/// # Example
/// ```mbt check
/// test {
///   let dst : @queue.Queue[Int32] = Queue([])
///   let src : @queue.Queue[Int32] = @queue.from_array([5, 6, 7, 8])
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
/// Modifying the queue while the iterator is in use is memory-safe, but which
/// elements the iterator then yields is unspecified.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = @queue.from_array([5, 6, 7, 8])
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
///   let queue : @queue.Queue[Int32] = @queue.from_iter([||])
///   @test.assert_eq(queue.length(), 0)
/// }
/// ```
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[A] Queue::from_iter(iter : Iter[A]) -> Queue[A] {
  { inner: @deque.from_iter(iter), }
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
  let queue : Queue[Int32] = new_queue()
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(1)
  @test.assert_eq(queue.length(), 4)
  @test.assert_eq(queue, from_array([1, 2, 3, 1]))
}

///|
test "copy" {
  let queue : Queue[Int32] = from_array([1, 2, 3, 4])
  let queue2 : Queue[Int32] = queue.copy()
  @test.assert_eq(queue2.length(), 4)
  @test.assert_eq(queue2, from_array([1, 2, 3, 4]))
  @test.assert_eq(queue.length(), 4)
  @test.assert_eq(queue, from_array([1, 2, 3, 4]))
}

///|
test "transfer" {
  let queue : Queue[Int32] = from_array([1, 2, 3, 4])
  let queue2 : Queue[Int32] = from_array([5, 6, 7, 8])
  queue.transfer(queue2)
  @test.assert_eq(queue.length(), 0)
  @test.assert_eq(queue2.length(), 8)
  @test.assert_eq(queue2, from_array([5, 6, 7, 8, 1, 2, 3, 4]))
}

///|
/// The empty queue.
pub impl[A] Default for Queue[A] with fn default() {
  new_queue()
}

///|
/// Returns the elements of the queue as an array, front first.
///
/// # Example
///
/// ```mbt check
/// test {
///   let queue = @queue.Queue([1, 2, 3])
///   queue.push(4)
///   ignore(queue.pop())
///   @debug.debug_inspect(queue.to_array(), content="[2, 3, 4]")
/// }
/// ```
pub fn[A] Queue::to_array(self : Queue[A]) -> Array[A] {
  self.inner.to_array()
}

///|
/// Encodes the queue as a JSON array, front first.
pub impl[A : @json.ToJson] @json.ToJson for Queue[A] with fn to_json(self) {
  @json.ToJson::to_json(self.inner)
}

///|
/// Decodes a queue from a JSON array, the form `to_json` produces; the first
/// array element becomes the front of the queue.
///
/// # Example
///
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int32] = @json.from_json([1, 2, 3])
///   @debug.debug_inspect(queue.peek(), content="Some(1)")
/// }
/// ```
pub impl[A : @json.FromJson] @json.FromJson for Queue[A] with fn from_json(
  json,
  path,
) {
  guard json is Array(_) else {
    raise path.error("@queue.from_json: expected array")
  }
  { inner: @json.FromJson::from_json(json, path), }
}
