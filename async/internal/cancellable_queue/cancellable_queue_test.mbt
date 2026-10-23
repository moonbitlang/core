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
impl @cancellable_queue.Element for TestElement with fn get_index(self) {
  self.index
}

///|
impl @cancellable_queue.Element for TestElement with fn set_index(self, index) {
  self.index = index
}

///|
impl @cancellable_queue.Element for TestElement with fn get_next(self) {
  self.next
}

///|
impl @cancellable_queue.Element for TestElement with fn set_next(self, next) {
  self.next = next
}

///|
impl @cancellable_queue.Element for TestElement with fn get_prev(self) {
  self.prev
}

///|
impl @cancellable_queue.Element for TestElement with fn set_prev(self, prev) {
  self.prev = prev
}

///|
test "empty and singleton queue" {
  let q : @cancellable_queue.Queue[TestElement] = Queue()
  assert_true(q.pop() is None)
  let a = test_element(1)
  q.push(a)
  guard! q.pop() is Some(popped)
  assert_eq(popped.id, 1)
  assert_true(q.pop() is None)
  q.push(a)
  q.remove(a)
  assert_true(q.pop() is None)
}

///|
test "mixed removals, pops, and growth preserve FIFO order" {
  let q : @cancellable_queue.Queue[TestElement] = Queue()
  let nodes : Array[TestElement] = []
  let expected : Array[Int32] = []
  for i in 0..<40 {
    let node = test_element(i)
    nodes.push(node)
    q.push(node)
    expected.push(i)
  }
  for i in 0..<20 {
    let index = i * 7 % expected.length()
    let id = expected.remove(index)
    q.remove(nodes[id])
  }
  for id in expected {
    guard! q.pop() is Some(node)
    assert_eq(node.id, id)
  }
  assert_true(q.pop() is None)
}
