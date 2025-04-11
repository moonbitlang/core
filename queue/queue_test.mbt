// Copyright 2025 International Digital Economy Academy
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
  let queue : @queue.T[Int] = @queue.new()
  assert_eq!(queue.length(), 0)
}

///|
test "from_fixed_array_1" {
  let queue = @queue.of([1, 2, 3, 4])
  let queue2 = @queue.of([1])
  assert_eq!(queue.length(), 4)
  assert_eq!(queue.unsafe_pop(), 1)
  assert_eq!(queue.unsafe_pop(), 2)
  assert_eq!(queue.unsafe_pop(), 3)
  assert_eq!(queue.unsafe_pop(), 4)
  assert_eq!(queue2.unsafe_pop(), 1)
  assert_eq!(queue2.length(), 0)
}

///|
test "from_fixed_array_2" {
  let q : @queue.T[Int] = @queue.of([])
  inspect!(q, content="@queue.of([])")
}

///|
test "from_array_1" {
  let queue = @queue.from_array([1, 2, 3, 4])
  let queue2 = @queue.from_array([1])
  assert_eq!(queue.length(), 4)
  assert_eq!(queue.unsafe_pop(), 1)
  assert_eq!(queue.unsafe_pop(), 2)
  assert_eq!(queue.unsafe_pop(), 3)
  assert_eq!(queue.unsafe_pop(), 4)
  assert_eq!(queue2.unsafe_pop(), 1)
  assert_eq!(queue2.length(), 0)
}

///|
test "from_array_2" {
  let q : @queue.T[Int] = @queue.from_array([])
  inspect!(q, content="@queue.of([])")
  let array = Array::makei(3, fn(idx) { idx + 1 })
  let q : @queue.T[Int] = @queue.from_array(array)
  inspect!(q, content="@queue.of([1, 2, 3])")
  let q : @queue.T[Int] = @queue.from_array(Array::new(capacity=10))
  inspect!(q, content="@queue.of([])")
}

///|
test "to_string" {
  let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
  inspect!(queue, content="@queue.of([1, 2, 3, 4])")
  queue.push(11)
  inspect!(queue, content="@queue.of([1, 2, 3, 4, 11])")
  queue.unsafe_pop() |> ignore
  inspect!(queue, content="@queue.of([2, 3, 4, 11])")
}

///|
test "clear" {
  let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
  assert_eq!(queue.length(), 4)
  queue.clear()
  assert_eq!(queue.length(), 0)
}

///|
test "is_empty" {
  let queue : @queue.T[Int] = @queue.new()
  assert_true!(queue.is_empty())
  queue.push(1)
  queue.push(2)
  queue.push(3)
  queue.push(4)
  assert_false!(queue.is_empty())
}

///|
test "unsafe_peek" {
  let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
  assert_eq!(queue.unsafe_peek(), 1)
  assert_eq!(queue.length(), 4)
  assert_eq!(queue.unsafe_pop(), 1)
  assert_eq!(queue.unsafe_peek(), 2)
  assert_eq!(queue.length(), 3)
}

///|
test "peek" {
  let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
  assert_eq!(queue.peek(), Some(1))
  queue.clear()
  assert_eq!(queue.peek(), None)
}

///|
test "unsafe_pop" {
  let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
  assert_eq!(queue.unsafe_pop(), 1)
  assert_eq!(queue.unsafe_pop(), 2)
  assert_eq!(queue.unsafe_pop(), 3)
  assert_eq!(queue.unsafe_pop(), 4)
  assert_eq!(queue.length(), 0)
}

///|
test "pop" {
  let queue : @queue.T[Int] = @queue.of([1, 2, 3, 4])
  assert_eq!(queue.pop(), Some(1))
  assert_eq!(queue.pop(), Some(2))
  assert_eq!(queue.pop(), Some(3))
  assert_eq!(queue.pop(), Some(4))
  assert_eq!(queue.pop(), None)
}

///|
test "iter" {
  let queue : @queue.T[Int] = @queue.new()
  let mut sum = 0
  queue.each(fn(x) { sum = sum + x })
  assert_eq!(sum, 0)
  @queue.of([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.each(fn(x) { sum = sum + x })
  assert_eq!(sum, 10)
}

///|
test "iteri" {
  let queue : @queue.T[Int] = @queue.new()
  let mut sum = 0
  queue.eachi(fn(x, i) { sum = sum + x * i })
  assert_eq!(sum, 0)
  @queue.of([1, 2, 3, 4]).transfer(queue)
  sum = 0
  queue.eachi(fn(x, i) { sum = sum + x * i })
  assert_eq!(sum, 20)
}

///|
test "fold" {
  let queue : @queue.T[Int] = @queue.new()
  let sum = queue.fold(init=0, fn(acc, x) { acc + x })
  assert_eq!(sum, 0)
  @queue.of([1, 2, 3, 4]).transfer(queue)
  let sum = queue.fold(init=0, fn(acc, x) { acc + x })
  assert_eq!(sum, 10)
  let sum2 = @queue.of([1, 2, 3, 4]).fold(init=0, fn(acc, x) { acc + x })
  assert_eq!(sum2, 10)
  inspect!(
    @queue.of([1, 2, 3, 4]).fold(init=0L, fn(acc, x) { acc + x.to_int64() }),
    content="10",
  )
}

///|
test "length" {
  let empty : @queue.T[Unit] = @queue.of([])
  inspect!(empty.length(), content="0")
  inspect!(@queue.of([1, 2, 3]).length(), content="3")
}

///|
test "iter" {
  let q = @queue.of([1, 2, 3, 4, 5])
  inspect!(q.iter().fold(fn(x, y) { x + y }, init=0), content="15")
}

///|
test "from_iter multiple elements iter" {
  inspect!(@queue.from_iter([1, 2, 3].iter()), content="@queue.of([1, 2, 3])")
}

///|
test "from_iter single element iter" {
  inspect!(@queue.from_iter([1].iter()), content="@queue.of([1])")
}

///|
test "from_iter empty iter" {
  let pq : @queue.T[Int] = @queue.from_iter(Iter::empty())
  inspect!(pq, content="@queue.of([])")
}

///|
test "to_string" {
  let queue : @queue.T[Int] = @queue.from_array([])
  assert_eq!(queue.to_string(), "@queue.of([])")
  let queue : @queue.T[Int] = @queue.from_array([9, 8, 7, 5])
  assert_eq!(queue.to_string(), "@queue.of([9, 8, 7, 5])")
}

///|
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
