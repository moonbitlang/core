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
/// The cancellable queue data structure is intrusive:
/// it requires elements to provide mutable storage for
/// an array index and a doubly linked list header.
pub(open) trait Element {
  fn get_index(Self) -> Int32
  fn set_index(Self, Int32) -> Unit
  fn get_next(Self) -> Int32
  fn set_next(Self, Int32) -> Unit
  fn get_prev(Self) -> Int32
  fn set_prev(Self, Int32) -> Unit
  fn is_queued(Self) -> Bool = _
}

///|
impl Element with fn is_queued(self) {
  self.get_index() >= 0
}

///|
/// An intrusive queue with random removal support,
/// useful for storing waiter set with cancellation support.
struct Queue[X] {
  // For internal use in `moonbitlang/async`, all elements should be `struct` type,
  // hence `X?` does not need extra boxing here.
  // Using `X?` allows us to release the memory occupied by empty cells immediately.
  // All elements within `0..<len` should be `Some`
  mut buf : FixedArray[X?]
  mut len : Int32

  // Index of the first element in the queue, updated when popping
  mut head : Int32

  // Index of the last element in the queue, updated when pushing
  mut last : Int32
}

///|
/// Create an empty queue
pub fn[X] Queue::Queue() -> Queue[X] {
  { buf: [], len: 0, head: -1, last: -1, }
}

///|
/// Pop the oldest element from the queue, or `None` if the queue is empty
pub fn[X : Element] Queue::pop(self : Queue[X]) -> X? {
  guard self.len > 0 else { None }
  guard! self.buf.unsafe_get(self.head) is Some(head)
  self.remove(head)
  Some(head)
}

///|
fn[X] Queue::enlarge_to(self : Queue[X], size : Int32) -> Unit {
  let new_buf = FixedArray::make(size, None)
  self.buf.blit_to(new_buf, src_offset=0, dst_offset=0, len=self.len)
  self.buf = new_buf
}

///|
/// Add an element that is not currently in a queue.
pub fn[X : Element] Queue::push(self : Queue[X], elem : X) -> Unit {
  let capacity = self.buf.length()
  if self.len >= capacity {
    self.enlarge_to(if capacity < 16 { 16 } else { capacity * 2 })
  }

  elem.set_index(self.len)
  elem.set_next(-1)
  elem.set_prev(self.last)
  self.buf.unsafe_set(self.len, Some(elem))
  if self.last >= 0 {
    guard! self.buf.unsafe_get(self.last) is Some(last)
    last.set_next(self.len)
  }
  self.last = self.len
  if self.head < 0 {
    self.head = self.len
  }
  self.len += 1
}

///|
/// Remove an element currently in this queue. Its links are reset so it can
/// be inserted again.
pub fn[X : Element] Queue::remove(self : Queue[X], elem : X) -> Unit {
  let index = elem.get_index()
  let prev = elem.get_prev()
  let next = elem.get_next()
  if prev >= 0 {
    guard! self.buf.unsafe_get(prev) is Some(prev)
    prev.set_next(next)
  }
  if next >= 0 {
    guard! self.buf.unsafe_get(next) is Some(next)
    next.set_prev(prev)
  }
  if index == self.head {
    self.head = next
  }
  if index == self.last {
    self.last = prev
  }
  self.len -= 1
  if index < self.len {
    guard! self.buf.unsafe_get(self.len) is Some(last)
    self.buf.unsafe_set(index, Some(last))
    last.set_index(index)
    if self.head == self.len {
      self.head = index
    }
    if self.last == self.len {
      self.last = index
    }
    let prev = last.get_prev()
    let next = last.get_next()
    if prev >= 0 {
      guard! self.buf.unsafe_get(prev) is Some(prev)
      prev.set_next(index)
    }
    if next >= 0 {
      guard! self.buf.unsafe_get(next) is Some(next)
      next.set_prev(index)
    }
  }
  self.buf.unsafe_set(self.len, None)
  elem.set_index(-1)
  elem.set_prev(-1)
  elem.set_next(-1)
}
