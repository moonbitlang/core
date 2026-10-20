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
struct TestElement {
  id : Int32
  mut index : Int32
  mut next : Int32
  mut prev : Int32
}

///|
fn test_element(id : Int32) -> TestElement {
  { id, index: -1, next: -1, prev: -1, }
}

///|
impl Element for TestElement with fn get_index(self) {
  self.index
}

///|
impl Element for TestElement with fn set_index(self, index) {
  self.index = index
}

///|
impl Element for TestElement with fn get_next(self) {
  self.next
}

///|
impl Element for TestElement with fn set_next(self, next) {
  self.next = next
}

///|
impl Element for TestElement with fn get_prev(self) {
  self.prev
}

///|
impl Element for TestElement with fn set_prev(self, prev) {
  self.prev = prev
}

///|
fn assert_queue(q : Queue[TestElement], expected : Array[Int32]) -> Unit raise {
  @test.assert_eq(q.len, expected.length())
  let mut cursor = q.head
  let mut previous = -1
  for id in expected {
    assert_true(cursor >= 0 && cursor < q.len)
    guard! q.buf.unsafe_get(cursor) is Some(node)
    @test.assert_eq(node.id, id)
    @test.assert_eq(node.index, cursor)
    @test.assert_eq(node.prev, previous)
    previous = cursor
    cursor = node.next
  }
  @test.assert_eq(cursor, -1)
  @test.assert_eq(q.last, previous)
  for i in 0..<q.len {
    guard! q.buf.unsafe_get(i) is Some(node)
    @test.assert_eq(node.index, i)
  }
  if q.len < q.buf.length() {
    assert_true(q.buf.unsafe_get(q.len) is None)
  }
}

///|
fn assert_detached(node : TestElement) -> Unit raise {
  @test.assert_eq(node.index, -1)
  @test.assert_eq(node.prev, -1)
  @test.assert_eq(node.next, -1)
}

///|
test "remove head, middle, and tail after array compaction" {
  let q : Queue[TestElement] = Queue()
  let a = test_element(1)
  let b = test_element(2)
  let c = test_element(3)
  let d = test_element(4)
  q.push(a)
  q.push(b)
  q.push(c)
  q.push(d)
  assert_queue(q, [1, 2, 3, 4])
  q.remove(a)
  assert_detached(a)
  assert_queue(q, [2, 3, 4])
  q.remove(c)
  assert_detached(c)
  assert_queue(q, [2, 4])
  q.remove(d)
  assert_queue(q, [2])
  guard! q.pop() is Some(popped)
  @test.assert_eq(popped.id, 2)
  assert_queue(q, [])
}

///|
test "remove tail while another element occupies the final array cell" {
  let q : Queue[TestElement] = Queue()
  let a = test_element(1)
  let b = test_element(2)
  let c = test_element(3)
  q.push(a)
  q.push(b)
  q.push(c)
  q.remove(a)
  assert_queue(q, [2, 3])
  // b is now the head but occupies the final array cell.
  q.remove(c)
  assert_detached(c)
  assert_queue(q, [2])
  q.push(c)
  assert_queue(q, [2, 3])
  guard! q.pop() is Some(popped)
  @test.assert_eq(popped.id, 2)
  assert_queue(q, [3])
  guard! q.pop() is Some(popped)
  @test.assert_eq(popped.id, 3)
  assert_queue(q, [])
}
