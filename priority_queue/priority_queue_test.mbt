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
  let queue : @priority_queue.T[Int] = @priority_queue.new()
  assert_eq!(queue.length(), 0)
}

test "from_array" {
  let pq = @priority_queue.of([1, 3, 6, 4, 5])
  inspect!(pq.peek(), content="Some(6)")
  let pq_ : @priority_queue.T[Int] = @priority_queue.of([])
  inspect!(pq_.peek(), content="None")
}

test "from_fixed_array" {
  let pq = @priority_queue.of([1, 2, 3, 4, 5])
  assert_eq!(pq.peek(), Some(5))
}

test "copy" {
  let v = @priority_queue.of([1, 2, 3, 4])
  let ve = v.copy()
  inspect!(v.peek(), content="Some(4)")
  inspect!(ve.peek(), content="Some(4)")
  v.pop() |> ignore
  inspect!(v.peek(), content="Some(3)")
  inspect!(ve.peek(), content="Some(4)")
}

test "to_array" {
  let v = @priority_queue.of([1, 6, 3, 4, 9, 2, 1])
  inspect!(v.to_array(), content="[9, 6, 4, 3, 2, 1, 1]")
}

test "iter" {
  let buf = Buffer::new(size_hint=20)
  let v = @priority_queue.of([1, 2, 3])
  for e in v {
    buf.write_string("[\{e}]")
  }
  inspect!(buf, content="[3][2][1]")
  buf.reset()
  for e in v.iter().take(2) {
    buf.write_string("[\{e}]")
  }
  inspect!(buf, content="[3][2]")
}

test "length" {
  let pq = @priority_queue.new()
  assert_eq!(pq.length(), 0)
  pq.push(1)
  assert_eq!(pq.length(), 1)
  pq.push(2)
  assert_eq!(pq.length(), 2)
  pq.pop_exn()
  assert_eq!(pq.length(), 1)
}

test "pop_exn" {
  let pq = @priority_queue.of([5, 5, 4, 3, 2, 1])
  inspect!(pq.length(), content="6")
  assert_eq!(pq.peek(), Some(5))
  pq.pop_exn()
  assert_eq!(pq.peek(), Some(5))
  pq.pop_exn()
  assert_eq!(pq.peek(), Some(4))
  let pq_ = @priority_queue.of([1])
  pq_.pop_exn()
  inspect!(pq_.length(), content="0")
}

test "panic pop_exn" {
  let pq : @priority_queue.T[Int] = @priority_queue.of([])
  pq.pop_exn()
}

test "pop" {
  let pq = @priority_queue.of([1, 2, 3, 4, 5, 5])
  assert_eq!(pq.pop(), Some(5))
  assert_eq!(pq.pop(), Some(5))
  assert_eq!(pq.pop(), Some(4))
  let pq_ = @priority_queue.of([1])
  pq_.pop() |> ignore
  inspect!(pq_.length(), content="0")
}

test "push" {
  let pq = @priority_queue.of([5, 4, 3, 2, 1])
  pq.push(-1)
  pq.push(6)
  assert_eq!(pq.length(), 7)
  assert_eq!(pq.peek(), Some(6))
}

test "peek" {
  let pq = @priority_queue.of([1, 2, 3, 4, 5])
  assert_eq!(pq.peek(), Some(5))
  pq.clear()
  assert_eq!(pq.peek(), None)
}

test "clear" {
  let pq = @priority_queue.of([5, 4, 3, 2, 1])
  pq.clear()
  assert_eq!(pq.length(), 0)
}

test "is_empty" {
  let pq = @priority_queue.of([5, 4, 3, 2, 1])
  assert_eq!(pq.is_empty(), false)
  pq.clear()
  assert_eq!(pq.is_empty(), true)
}

test "from_iter multiple elements iter" {
  inspect!(
    @priority_queue.T::from_iter([1, 2, 3].iter()),
    content="@priority_queue.of([3, 2, 1])",
  )
}

test "from_iter single element iter" {
  inspect!(
    @priority_queue.T::from_iter([1].iter()),
    content="@priority_queue.of([1])",
  )
}

test "from_iter empty iter" {
  let pq : @priority_queue.T[Int] = @priority_queue.T::from_iter(Iter::empty())
  inspect!(pq, content="@priority_queue.of([])")
}
