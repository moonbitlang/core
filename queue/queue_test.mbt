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
test "new" {
  let queue : @queue.Queue[Int] = @queue.Queue([])
  assert_eq(queue.length(), 0)
}

///|
test "copy empty" {
  let queue : @queue.Queue[Int] = @queue.Queue([])
  let copied = queue.copy()
  inspect(copied.length(), content="0")
}

///|
test "from_fixed_array_1" {
  let queue = @queue.from_array([1, 2, 3, 4])
  let queue2 = @queue.from_array([1])
  assert_eq(queue.length(), 4)
  assert_eq(queue.unsafe_pop(), 1)
  assert_eq(queue.unsafe_pop(), 2)
  assert_eq(queue.unsafe_pop(), 3)
  assert_eq(queue.unsafe_pop(), 4)
  assert_eq(queue2.unsafe_pop(), 1)
  assert_eq(queue2.length(), 0)
}

///|
test "from_fixed_array_2" {
  let q : @queue.Queue[Int] = @queue.from_array([])
  debug_inspect(
    q,
    content=(
      #|<Queue: []>
    ),
  )
}

///|
test "from_array_1" {
  let queue = @queue.from_array([1, 2, 3, 4])
  let queue2 = @queue.from_array([1])
  assert_eq(queue.length(), 4)
  assert_eq(queue.unsafe_pop(), 1)
  assert_eq(queue.unsafe_pop(), 2)
  assert_eq(queue.unsafe_pop(), 3)
  assert_eq(queue.unsafe_pop(), 4)
  assert_eq(queue2.unsafe_pop(), 1)
  assert_eq(queue2.length(), 0)
}

///|
test "Queue constructor" {
  let queue = @queue.Queue([1, 2, 3])
  assert_eq(queue.length(), 3)
  assert_eq(queue.unsafe_pop(), 1)
  assert_eq(queue.unsafe_pop(), 2)
  assert_eq(queue.unsafe_pop(), 3)
}

///|
test "from_array_2" {
  let q : @queue.Queue[Int] = @queue.from_array([])
  debug_inspect(
    q,
    content=(
      #|<Queue: []>
    ),
  )
  let array = Array::makei(3, idx => idx + 1)
  let q : @queue.Queue[Int] = @queue.from_array(array)
  debug_inspect(
    q,
    content=(
      #|<Queue: [1, 2, 3]>
    ),
  )
  let q : @queue.Queue[Int] = @queue.from_array(Array::new(capacity=10))
  debug_inspect(
    q,
    content=(
      #|<Queue: []>
    ),
  )
}

///|
test "to_string" {
  let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
  debug_inspect(
    queue,
    content=(
      #|<Queue: [1, 2, 3, 4]>
    ),
  )
  queue.push(11)
  debug_inspect(
    queue,
    content=(
      #|<Queue: [1, 2, 3, 4, 11]>
    ),
  )
  queue.unsafe_pop() |> ignore
  debug_inspect(
    queue,
    content=(
      #|<Queue: [2, 3, 4, 11]>
    ),
  )
  let queue : @queue.Queue[Int] = @queue.from_array([])
  debug_inspect(
    queue,
    content=(
      #|<Queue: []>
    ),
  )
  let queue : @queue.Queue[Int] = @queue.from_array([9, 8, 7, 5])
  debug_inspect(
    queue,
    content=(
      #|<Queue: [9, 8, 7, 5]>
    ),
  )
}

///|
test "clear" {
  let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
  assert_eq(queue.length(), 4)
  queue.clear()
  assert_eq(queue.length(), 0)
}

///|
test "is_empty" {
  let queue : @queue.Queue[Int] = @queue.Queue([])
  assert_true(queue.is_empty())
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(4)
  assert_false(queue.is_empty())
}

///|
test "unsafe_peek" {
  let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
  assert_eq(queue.unsafe_peek(), 1)
  assert_eq(queue.length(), 4)
  assert_eq(queue.unsafe_pop(), 1)
  assert_eq(queue.unsafe_peek(), 2)
  assert_eq(queue.length(), 3)
}

///|
test "peek" {
  let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
  assert_eq(queue.peek(), Some(1))
  queue.clear()
  assert_eq(queue.peek(), None)
}

///|
test "unsafe_pop" {
  let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
  assert_eq(queue.unsafe_pop(), 1)
  assert_eq(queue.unsafe_pop(), 2)
  assert_eq(queue.unsafe_pop(), 3)
  assert_eq(queue.unsafe_pop(), 4)
  assert_eq(queue.length(), 0)
}

///|
test "pop" {
  let queue : @queue.Queue[Int] = @queue.from_array([1, 2, 3, 4])
  assert_eq(queue.pop(), Some(1))
  assert_eq(queue.pop(), Some(2))
  assert_eq(queue.pop(), Some(3))
  assert_eq(queue.pop(), Some(4))
  assert_eq(queue.pop(), None)
}

///|
test "each" {
  let queue : @queue.Queue[Int] = @queue.Queue([])
  let mut sum = 0
  queue.each(x => sum = sum + x)
  assert_eq(sum, 0)
  @queue.from_array([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.each(x => sum = sum + x)
  assert_eq(sum, 10)
}

///|
test "iter_fold" {
  let q = @queue.from_array([1, 2, 3, 4, 5])
  inspect(q.iter().fold((x, y) => x + y, init=0), content="15")
}

///|
test "iteri" {
  let queue : @queue.Queue[Int] = @queue.Queue([])
  let mut sum = 0
  queue.eachi((i, x) => sum = sum + i * x)
  assert_eq(sum, 0)
  @queue.from_array([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.eachi((i, x) => sum = sum + i * x)
  assert_eq(sum, 20)
}

///|
test "fold" {
  let queue : @queue.Queue[Int] = @queue.Queue([])
  let sum = queue.fold(init=0, (acc, x) => acc + x)
  assert_eq(sum, 0)
  @queue.from_array([1, 2, 3, 4]).transfer(queue)
  let sum = queue.fold(init=0, (acc, x) => acc + x)
  assert_eq(sum, 10)
  let sum2 = @queue.from_array([1, 2, 3, 4]).fold(init=0, (acc, x) => acc + x)
  assert_eq(sum2, 10)
  inspect(
    @queue.from_array([1, 2, 3, 4]).fold(init=0L, (acc, x) => acc + x.to_int64()),
    content="10",
  )
}

///|
test "length" {
  let empty : @queue.Queue[Unit] = @queue.from_array([])
  inspect(empty.length(), content="0")
  inspect(@queue.from_array([1, 2, 3]).length(), content="3")
}

///|
test "iter" {
  let q = @queue.from_array([1, 2, 3, 4, 5])
  inspect(q.iter().fold((x, y) => x + y, init=0), content="15")
}

///|
test "from_iter multiple elements iter" {
  debug_inspect(
    @queue.from_iter([1, 2, 3].iter()),
    content=(
      #|<Queue: [1, 2, 3]>
    ),
  )
}

///|
test "from_iter single element iter" {
  debug_inspect(
    @queue.from_iter([1].iter()),
    content=(
      #|<Queue: [1]>
    ),
  )
}

///|
test "from_iter empty iter" {
  let pq : @queue.Queue[Int] = @queue.from_iter(Iter::empty())
  debug_inspect(
    pq,
    content=(
      #|<Queue: []>
    ),
  )
}

///|
test "queue arbitrary" {
  let samples : Array[@queue.Queue[Int]] = @quickcheck.samples(20)
  debug_inspect(
    samples[1:5],
    content=(
      #|<ArrayView: [<Queue: []>, <Queue: []>, <Queue: [0]>, <Queue: [0]>]>
    ),
  )
  debug_inspect(
    samples[15],
    content=(
      #|<Queue: []>
    ),
  )
}

///|
test "transfer_self" {
  // Test self-transfer: q.transfer(q) should be a no-op
  let q : @queue.Queue[Int] = @queue.from_array([1, 2, 3])
  q.transfer(q)
  // After self-transfer, queue should remain unchanged
  debug_inspect(
    q,
    content=(
      #|<Queue: [1, 2, 3]>
    ),
  )
}

///|
test "transfer_self_empty" {
  // Test self-transfer on empty queue
  let q : @queue.Queue[Int] = @queue.Queue([])
  q.transfer(q)
  debug_inspect(
    q,
    content=(
      #|<Queue: []>
    ),
  )
}
