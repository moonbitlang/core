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

test "new" {
  let queue : @queue.Queue[Int] = @queue.new()
  @test.eq(queue.length(), 0)!
}

test "from_fixed_array_1" {
  let queue = @queue.of([1, 2, 3, 4])
  let queue2 = @queue.of([1])
  @test.eq(queue.length(), 4)!
  @test.eq(queue.pop_exn(), 1)!
  @test.eq(queue.pop_exn(), 2)!
  @test.eq(queue.pop_exn(), 3)!
  @test.eq(queue.pop_exn(), 4)!
  @test.eq(queue2.pop_exn(), 1)!
  @test.eq(queue2.length(), 0)!
}

test "from_fixed_array_3" {
  let q : @queue.Queue[Int] = @queue.of([])
  inspect!(q, content="Queue::[]")
}

test "from_array_1" {
  let queue = @queue.of([1, 2, 3, 4])
  let queue2 = @queue.of([1])
  @test.eq(queue.length(), 4)!
  @test.eq(queue.pop_exn(), 1)!
  @test.eq(queue.pop_exn(), 2)!
  @test.eq(queue.pop_exn(), 3)!
  @test.eq(queue.pop_exn(), 4)!
  @test.eq(queue2.pop_exn(), 1)!
  @test.eq(queue2.length(), 0)!
}

test "from_array_3" {
  let q : @queue.Queue[Int] = @queue.of([])
  inspect!(q, content="Queue::[]")
}

test "to_string" {
  let queue : @queue.Queue[Int] = @queue.of([1, 2, 3, 4])
  inspect!(queue, content="Queue::[1, 2, 3, 4]")
  queue.push(11)
  inspect!(queue, content="Queue::[1, 2, 3, 4, 11]")
  queue.pop_exn() |> ignore
  inspect!(queue, content="Queue::[2, 3, 4, 11]")
}

test "clear" {
  let queue : @queue.Queue[Int] = @queue.of([1, 2, 3, 4])
  @test.eq(queue.length(), 4)!
  queue.clear()
  @test.eq(queue.length(), 0)!
}

test "is_empty" {
  let queue : @queue.Queue[Int] = @queue.new()
  @test.is_true(queue.is_empty())!
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(4)
  @test.is_false(queue.is_empty())!
}

test "peek_exn" {
  let queue : @queue.Queue[Int] = @queue.of([1, 2, 3, 4])
  @test.eq(queue.peek_exn(), 1)!
  @test.eq(queue.length(), 4)!
  @test.eq(queue.pop_exn(), 1)!
  @test.eq(queue.peek_exn(), 2)!
  @test.eq(queue.length(), 3)!
}

test "panic peek_exn" {
  @queue.of([]).peek_exn()
}

test "peek" {
  let queue : @queue.Queue[Int] = @queue.of([1, 2, 3, 4])
  @test.eq(queue.peek(), Some(1))!
  queue.clear()
  @test.eq(queue.peek(), None)!
}

test "pop_exn" {
  let queue : @queue.Queue[Int] = @queue.of([1, 2, 3, 4])
  @test.eq(queue.pop_exn(), 1)!
  @test.eq(queue.pop_exn(), 2)!
  @test.eq(queue.pop_exn(), 3)!
  @test.eq(queue.pop_exn(), 4)!
  @test.eq(queue.length(), 0)!
}

test "panic pop_exn" {
  @queue.of([]).pop_exn()
}

test "pop" {
  let queue : @queue.Queue[Int] = @queue.of([1, 2, 3, 4])
  @test.eq(queue.pop(), Some(1))!
  @test.eq(queue.pop(), Some(2))!
  @test.eq(queue.pop(), Some(3))!
  @test.eq(queue.pop(), Some(4))!
  @test.eq(queue.pop(), None)!
}

test "iter" {
  let queue : @queue.Queue[Int] = @queue.new()
  let mut sum = 0
  queue.each(fn(x) { sum = sum + x })
  @test.eq(sum, 0)!
  @queue.of([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.each(fn(x) { sum = sum + x })
  @test.eq(sum, 10)!
}

test "iteri" {
  let queue : @queue.Queue[Int] = @queue.new()
  let mut sum = 0
  queue.eachi(fn(x, i) { sum = sum + x * i })
  @test.eq(sum, 0)!
  @queue.of([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.eachi(fn(x, i) { sum = sum + x * i })
  @test.eq(sum, 20)!
}

test "fold" {
  let queue : @queue.Queue[Int] = @queue.new()
  let sum = queue.fold(init=0, fn(acc, x) { acc + x })
  @test.eq(sum, 0)!
  @queue.of([1, 2, 3, 4]).transfer(queue)
  let sum = queue.fold(init=0, fn(acc, x) { acc + x })
  @test.eq(sum, 10)!
  let sum2 = @queue.of([1, 2, 3, 4]).fold(init=0, fn(acc, x) { acc + x })
  @test.eq(sum2, 10)!
}

test "length" {
  let empty : @queue.Queue[Unit] = @queue.of([])
  inspect!(empty.length(), content="0")
  inspect!(@queue.of([1, 2, 3]).length(), content="3")
}

test "iter" {
  let q = @queue.of([1, 2, 3, 4, 5])
  inspect!(q.iter().fold(fn(x, y) { x + y }, 0), content="15")
}
