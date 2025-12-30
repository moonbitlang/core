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
test "unsafe_pop_front after many push_front" {
  let dq = new()
  for i in 0..<10 {
    dq.push_front(i)
  }
  for i in 0..<10 {
    dq.unsafe_pop_front()
  }
  assert_eq(dq.head, dq.tail)
}

///|
test "truncate zero" {
  let dq = from_array([1, 2, 3])
  dq.truncate(0)
  inspect(dq.len, content="0")
  assert_eq(dq.head, dq.tail)
}

///|
/// Test from_array with empty array maintains invariant:
/// When len == 0, head and tail should point to the same slot.
test "from_array_empty_invariant" {
  let dq : Deque[Int] = from_array([])
  inspect(dq.len, content="0")
  // Invariant: when empty, head == tail
  assert_eq(dq.head, dq.tail)
}

///|
/// Test add (operator +) with empty deques maintains invariant:
/// When len == 0, head and tail should point to the same slot.
test "add_empty_invariant" {
  let empty1 : Deque[Int] = new()
  let empty2 : Deque[Int] = new()
  let result = empty1 + empty2
  inspect(result.len, content="0")
  // Invariant: when empty, head == tail
  assert_eq(result.head, result.tail)
}

///|
test "weird behavior after drain" {
  let deque = new(capacity=16)
  deque.push_back(1)
  deque.push_back(2)
  deque.push_back(3)
  deque.push_back(4)
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  deque.push_back(5)
  ignore(deque.pop_front())
  deque.push_back(6)
  ignore(deque.pop_front())
  deque.push_back(7)
  ignore(deque.pop_front())
  deque.push_back(8)
  ignore(deque.pop_front())
  deque.push_back(9)
  deque.push_back(10)
  deque.push_back(11)
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  deque.push_back(12)
  deque.push_back(13)
  ignore(deque.pop_front())
  deque.push_back(14)
  ignore(deque.pop_front())
  ignore(deque.drain(start=0, len=2))
  deque.push_back(15)
  ignore(deque.pop_front())
  deque.push_back(16)
  ignore(deque.pop_front())
  deque.push_back(17)
  ignore(deque.pop_front())
  deque.push_back(18)
  ignore(deque.pop_front())
  deque.push_back(19)
  ignore(deque.pop_front())
  deque.push_back(20)
  deque.push_back(21)
  deque.push_back(22)
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  deque.push_back(23)
  deque.push_back(24)
  deque.push_back(25)
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  deque.push_back(26)
  deque.push_back(27)
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  ignore(deque.pop_front())
  deque.push_back(28)
  ignore(deque.pop_front())
  deque.push_back(29)
  ignore(deque.pop_front())
  deque.push_back(30)
  inspect(deque.as_views(), content="([29, 30], [])")
  ignore(deque.drain(start=0, len=2))
  inspect(deque.as_views(), content="([], [])")
  deque.push_back(31)
  deque.push_back(32)
  inspect(deque.as_views(), content="([31, 32], [])") // <- here
  ignore(deque.pop_front())
}
