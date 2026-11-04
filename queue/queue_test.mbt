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
  let queue : @queue.Queue[Int32] = Queue([])
  @test.assert_eq(queue.length(), 0)
}

///|
test "copy empty" {
  let queue : @queue.Queue[Int32] = Queue([])
  let copied = queue.copy()
  inspect(copied.length(), content="0")
}

///|
test "from_array_1" {
  let queue = @queue.from_array([1, 2, 3, 4])
  let queue2 = @queue.from_array([1])
  @test.assert_eq(queue.length(), 4)
  @test.assert_eq(queue.unsafe_pop(), 1)
  @test.assert_eq(queue.unsafe_pop(), 2)
  @test.assert_eq(queue.unsafe_pop(), 3)
  @test.assert_eq(queue.unsafe_pop(), 4)
  @test.assert_eq(queue2.unsafe_pop(), 1)
  @test.assert_eq(queue2.length(), 0)
}

///|
test "Queue constructor" {
  let queue = @queue.Queue([1, 2, 3])
  @test.assert_eq(queue.length(), 3)
  @test.assert_eq(queue.unsafe_pop(), 1)
  @test.assert_eq(queue.unsafe_pop(), 2)
  @test.assert_eq(queue.unsafe_pop(), 3)
}

///|
test "from_array_2" {
  let q : @queue.Queue[Int32] = @queue.from_array([])
  debug_inspect(
    q,
    content=(
      #|<Queue: []>
    ),
  )
  let array = Array::makei(3, idx => idx + 1)
  let q : @queue.Queue[Int32] = @queue.from_array(array)
  debug_inspect(
    q,
    content=(
      #|<Queue: [1, 2, 3]>
    ),
  )
  let q : @queue.Queue[Int32] = @queue.from_array(Array(capacity=10))
  debug_inspect(
    q,
    content=(
      #|<Queue: []>
    ),
  )
}

///|
test "to_string" {
  let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
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
  let queue : @queue.Queue[Int32] = @queue.from_array([])
  debug_inspect(
    queue,
    content=(
      #|<Queue: []>
    ),
  )
  let queue : @queue.Queue[Int32] = @queue.from_array([9, 8, 7, 5])
  debug_inspect(
    queue,
    content=(
      #|<Queue: [9, 8, 7, 5]>
    ),
  )
}

///|
test "clear" {
  let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
  @test.assert_eq(queue.length(), 4)
  queue.clear()
  @test.assert_eq(queue.length(), 0)
}

///|
test "is_empty" {
  let queue : @queue.Queue[Int32] = Queue([])
  assert_true(queue.is_empty())
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(4)
  assert_false(queue.is_empty())
}

///|
test "unsafe_peek" {
  let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
  @test.assert_eq(queue.unsafe_peek(), 1)
  @test.assert_eq(queue.length(), 4)
  @test.assert_eq(queue.unsafe_pop(), 1)
  @test.assert_eq(queue.unsafe_peek(), 2)
  @test.assert_eq(queue.length(), 3)
}

///|
test "peek" {
  let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
  @test.assert_eq(queue.peek(), Some(1))
  queue.clear()
  @test.assert_eq(queue.peek(), None)
}

///|
test "unsafe_pop" {
  let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
  @test.assert_eq(queue.unsafe_pop(), 1)
  @test.assert_eq(queue.unsafe_pop(), 2)
  @test.assert_eq(queue.unsafe_pop(), 3)
  @test.assert_eq(queue.unsafe_pop(), 4)
  @test.assert_eq(queue.length(), 0)
}

///|
test "pop" {
  let queue : @queue.Queue[Int32] = @queue.from_array([1, 2, 3, 4])
  @test.assert_eq(queue.pop(), Some(1))
  @test.assert_eq(queue.pop(), Some(2))
  @test.assert_eq(queue.pop(), Some(3))
  @test.assert_eq(queue.pop(), Some(4))
  @test.assert_eq(queue.pop(), None)
}

///|
test "each" {
  let queue : @queue.Queue[Int32] = Queue([])
  let mut sum = 0
  queue.each(x => sum += x)
  @test.assert_eq(sum, 0)
  @queue.from_array([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.each(x => sum += x)
  @test.assert_eq(sum, 10)
}

///|
test "iter_fold" {
  let q = @queue.from_array([1, 2, 3, 4, 5])
  inspect(q.iter().fold((x, y) => x + y, init=0), content="15")
}

///|
test "iteri" {
  let queue : @queue.Queue[Int32] = Queue([])
  let mut sum = 0
  queue.eachi((i, x) => sum += i * x)
  @test.assert_eq(sum, 0)
  @queue.from_array([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.eachi((i, x) => sum += i * x)
  @test.assert_eq(sum, 20)
}

///|
test "fold" {
  let queue : @queue.Queue[Int32] = Queue([])
  let sum = queue.fold(init=0, (acc, x) => acc + x)
  @test.assert_eq(sum, 0)
  @queue.from_array([1, 2, 3, 4]).transfer(queue)
  let sum = queue.fold(init=0, (acc, x) => acc + x)
  @test.assert_eq(sum, 10)
  let sum2 = @queue.from_array([1, 2, 3, 4]).fold(init=0, (acc, x) => acc + x)
  @test.assert_eq(sum2, 10)
  inspect(
    @queue.from_array([1, 2, 3, 4]).fold(init=0L, (acc, x) => acc + x.to_int64()),
    content="10",
  )
}

///|
fn expect_callback_failure(action : () -> Unit raise) -> Unit raise {
  try action() catch {
    Failure(message) => inspect(message, content="callback failed")
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected error")
  }
}

///|
fn fail_on_two(x : Int32) -> Unit raise {
  if x == 2 {
    raise Failure::Failure("callback failed")
  }
}

///|
test "each with error callback" {
  let queue = @queue.from_array([1, 2, 3])
  expect_callback_failure(() => queue.each(fail_on_two))
}

///|
test "eachi with error callback" {
  let queue = @queue.from_array([1, 2, 3])
  expect_callback_failure(() => queue.eachi((_i, x) => fail_on_two(x)))
}

///|
test "fold with error callback" {
  let queue = @queue.from_array([1, 2, 3])
  expect_callback_failure(() => {
    queue.fold(init=0, (acc, x) => {
      fail_on_two(x)
      acc + x
    })
    |> ignore
  })
}

///|
test "length" {
  let empty : @queue.Queue[Unit] = @queue.from_array([])
  inspect(empty.length(), content="0")
  inspect(@queue.from_array([1, 2, 3]).length(), content="3")
}

///|
test "from_iter multiple elements iter" {
  debug_inspect(
    @queue.from_iter([|1, 2, 3|]),
    content=(
      #|<Queue: [1, 2, 3]>
    ),
  )
}

///|
test "from_iter single element iter" {
  debug_inspect(
    @queue.from_iter([|1|]),
    content=(
      #|<Queue: [1]>
    ),
  )
}

///|
test "from_iter empty iter" {
  let pq : @queue.Queue[Int32] = @queue.from_iter([||])
  debug_inspect(
    pq,
    content=(
      #|<Queue: []>
    ),
  )
}

///|
test "transfer_self" {
  // Test self-transfer: q.transfer(q) should be a no-op
  let q : @queue.Queue[Int32] = @queue.from_array([1, 2, 3])
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
  let q : @queue.Queue[Int32] = Queue([])
  q.transfer(q)
  debug_inspect(
    q,
    content=(
      #|<Queue: []>
    ),
  )
}

///|
test "Queue constructor with capacity" {
  let q : @queue.Queue[Int32] = Queue([], capacity=16)
  inspect(q.is_empty(), content="true")
  for i in 0..<20 {
    q.push(i)
  }
  inspect(q.length(), content="20")
  @debug.debug_inspect(q.pop(), content="Some(0)")
  // A capacity smaller than the input still keeps every element.
  let q = @queue.Queue([1, 2, 3], capacity=1)
  inspect(q.length(), content="3")
  @debug.debug_inspect(q.peek(), content="Some(1)")
}

///|
test "Eq compares elements in order" {
  let a = @queue.Queue([1, 2, 3])
  let b = @queue.Queue([0, 1, 2, 3])
  ignore(b.pop())
  inspect(a == b, content="true")
  inspect(a.equal(b), content="true")
  b.push(4)
  inspect(a == b, content="false")
  inspect(a != Queue([3, 2, 1]), content="true")
}

///|
test "Default is the empty queue" {
  let q : @queue.Queue[Int32] = Default::default()
  inspect(q.is_empty(), content="true")
}

///|
test "to_array is front first" {
  let q = @queue.Queue([1, 2])
  q.push(3)
  ignore(q.pop())
  @debug.debug_inspect(q.to_array(), content="[2, 3]")
  @debug.debug_inspect(
    (Queue([]) : @queue.Queue[Int32]).to_array(),
    content="[]",
  )
}

///|
test "JSON round-trip" {
  let q = @queue.Queue([1, 2, 3])
  ignore(q.pop())
  q.push(4)
  @json.json_inspect(q, content=[2, 3, 4])
  let back : @queue.Queue[Int32] = @json.from_json(Json(q))
  inspect(back == q, content="true")
  @debug.debug_inspect(back.pop(), content="Some(2)")
  let bad : Json = { "a": 1 }
  try (@json.from_json(bad) : @queue.Queue[Int32]) |> ignore catch {
    e =>
      inspect(
        e,
        content=(
          #|JsonDecodeError((, @queue.from_json: expected array))
        ),
      )
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
  let bad_elem : Json = [1, "x"]
  try (@json.from_json(bad_elem) : @queue.Queue[Int32]) |> ignore catch {
    _ => ()
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Queue::capacity reports the backing buffer" {
  let queue : @queue.Queue[Int32] = Queue([], capacity=8)
  inspect(queue.capacity(), content="8")
  for i in 0..<8 {
    queue.push(i)
  }
  inspect(queue.capacity(), content="8")
  queue.push(8)
  assert_true(queue.capacity() >= 9)
}

///|
test "Queue::shrink_to_fit drops spare capacity and keeps the order" {
  let queue : @queue.Queue[String] = Queue([], capacity=16)
  for s in ["a", "b", "c", "d", "e"] {
    queue.push(s)
  }
  let _ = queue.pop()
  let _ = queue.pop()
  queue.shrink_to_fit()
  inspect(queue.capacity(), content="3")
  @debug.debug_inspect(
    queue,
    content=(
      #|<Queue: ["c", "d", "e"]>
    ),
  )
  // the shrunken queue still works as a FIFO
  queue.push("f")
  @debug.debug_inspect(queue.pop(), content="Some(\"c\")")
  @debug.debug_inspect(
    queue,
    content=(
      #|<Queue: ["d", "e", "f"]>
    ),
  )
  queue.clear()
  queue.shrink_to_fit()
  inspect(queue.capacity(), content="0")
}

///|
test "Queue::compare orders by length, then front to back" {
  let q123 : @queue.Queue[Int32] = @queue.from_array([1, 2, 3])
  let q124 : @queue.Queue[Int32] = @queue.from_array([1, 2, 4])
  let q12 : @queue.Queue[Int32] = @queue.from_array([1, 2])
  let q9 : @queue.Queue[Int32] = @queue.from_array([9])
  inspect(q123.compare(q124), content="-1")
  inspect(q124.compare(q123), content="1")
  inspect(q123.compare(q12), content="1")
  inspect(q9.compare(q12), content="-1")
  inspect(q123.compare(@queue.from_array([1, 2, 3])), content="0")
  assert_true(q123 < q124)
  assert_true(q12 <= q123)
  assert_true(q124 > q9)
}

///|
test "Queue::compare agrees with the backing deque and with ==" {
  let arrays : Array[Array[Int32]] = [
    [],
    [0],
    [1],
    [0, 1],
    [1, 0],
    [1, 2, 3],
    [1, 2, 4],
    [3, 2, 1],
  ]
  for a in arrays {
    for b in arrays {
      let qa : @queue.Queue[Int32] = @queue.from_array(a)
      let qb : @queue.Queue[Int32] = @queue.from_array(b)
      @test.assert_eq(
        qa.compare(qb),
        @deque.from_array(a).compare(@deque.from_array(b)),
      )
      @test.assert_eq(qa.compare(qb) == 0, qa == qb)
    }
  }
}

///|
test "Queue::hash is consistent with ==" {
  // equal queues reached through different histories hash equally
  let pushed : @queue.Queue[Int32] = Queue([], capacity=8)
  for i in 0..<6 {
    pushed.push(i)
  }
  for _ in 0..<3 {
    let _ = pushed.pop()
  }
  pushed.push(6)
  let built : @queue.Queue[Int32] = @queue.from_array([3, 4, 5, 6])
  assert_true(pushed == built)
  @test.assert_eq(pushed.hash(), built.hash())
  // they hash as the backing deque does
  @test.assert_eq(built.hash(), @deque.from_array([3, 4, 5, 6]).hash())
  // order and length matter
  let reversed : @queue.Queue[Int32] = @queue.from_array([6, 5, 4, 3])
  @test.assert_not_eq(built.hash(), reversed.hash())
  @test.assert_not_eq(built.hash(), @queue.from_array([3, 4, 5]).hash())
  // queues work as hash-map keys
  let seen : Map[@queue.Queue[Int32], Int32] = Map([])
  seen[pushed] = 1
  @test.assert_eq(seen.get(built), Some(1))
}
