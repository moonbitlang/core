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

test "from_fixed_array" {
  let queue = @priority_queue.of([1, 6, 3, 4, 5])
  inspect!(queue.peek(), content="Some(6)")
}

test "from_array" {
  let queue = @priority_queue.of([1, 6, 3, 4, 5])
  inspect!(queue.peek(), content="Some(6)")
}

test "to_array" {
  let v = @priority_queue.of([1, 2, 3, 4])
  inspect!(v.to_array(), content="[4, 3, 2, 1]")
  inspect!(v.push(0).to_array(), content="[4, 3, 2, 1, 0]")
  inspect!(
    (@priority_queue.new() : @priority_queue.T[Int]).to_array(),
    content="[]",
  )
}

test "as_iter" {
  let buf = StringBuilder::new(size_hint=20)
  let v = @priority_queue.of([1, 2, 3])
  v.iter().each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[3][2][1]")
  buf.reset()
  v.iter().take(2).each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[3][2]")
}

test "pop" {
  let queue = @priority_queue.of([1, 2, 3, 4])
  let first = queue.pop()
  inspect!(
    match first {
      Some(q) => q.peek()
      None => None
    },
    content="Some(3)",
  )
  let empty : @priority_queue.T[Int] = @priority_queue.of([])
  inspect!(
    match empty.pop() {
      Some(q) => q.peek()
      None => None
    },
    content="None",
  )
}

test "pop_exn" {
  let queue = @priority_queue.of([1, 2, 3, 4])
  let first = queue.unsafe_pop()
  inspect!(first.peek(), content="Some(3)")
  inspect!(
    queue
    .unsafe_pop()
    .push(-1)
    .push(10)
    .push(11)
    .unsafe_pop()
    .unsafe_pop()
    .push(50)
    .peek(),
    content="Some(50)",
  )
}

test "push" {
  let queue = @priority_queue.of([1, 2, 3])
  inspect!(queue.push(4).peek(), content="Some(4)")
}

test "peek" {
  let queue = @priority_queue.new()
  inspect!(queue.peek(), content="None")
  inspect!(queue.push(1).peek(), content="Some(1)")
}

test "is_empty" {
  let queue = @priority_queue.new()
  inspect!(queue.is_empty(), content="true")
  inspect!(queue.push(1).is_empty(), content="false")
}

test "length" {
  let pq = @priority_queue.of([1, 2])
  inspect!(pq.length(), content="2")
  inspect!(pq.unsafe_pop().length(), content="1")
  inspect!(pq.unsafe_pop().unsafe_pop().length(), content="0")
}

test "from_iter multiple elements iter" {
  inspect!(
    @priority_queue.T::from_iter([1, 2, 3].iter()),
    content="@immut/priority_queue.of([3, 2, 1])",
  )
}

test "from_iter single element iter" {
  inspect!(
    @priority_queue.T::from_iter([1].iter()),
    content="@immut/priority_queue.of([1])",
  )
}

test "from_iter empty iter" {
  let pq : @priority_queue.T[Int] = @priority_queue.T::from_iter(Iter::empty())
  inspect!(pq, content="@immut/priority_queue.of([])")
}
