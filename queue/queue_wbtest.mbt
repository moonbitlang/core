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
test "Queue capacity is forwarded to the backing deque" {
  inspect(
    Queue(([] : Array[Int32]), capacity=16).inner.capacity(),
    content="16",
  )
  inspect(Queue([1, 2, 3], capacity=1).inner.capacity(), content="3")
  inspect(Queue([1, 2, 3]).inner.capacity(), content="3")
}

///|
test "Queue::release_unused overwrites the slots pop vacated" {
  let queue : Queue[String] = from_array(["a", "b", "c", "d"])
  let (front, _) = queue.inner.as_views()
  let _ = queue.pop()
  let _ = queue.pop()
  // without a release, the popped elements stay reachable from the buffer
  @debug.debug_inspect(
    front,
    content=(
      #|<ArrayView: ["a", "b", "c", "d"]>
    ),
  )
  queue.release_unused(placeholder="-")
  @debug.debug_inspect(
    front,
    content=(
      #|<ArrayView: ["-", "-", "c", "d"]>
    ),
  )
  @debug.debug_inspect(
    queue,
    content=(
      #|<Queue: ["c", "d"]>
    ),
  )
  inspect(queue.capacity(), content="4")
}

///|
test "Queue::release_unused after clear overwrites the whole buffer" {
  let queue : Queue[String] = from_array(["a", "b", "c"])
  let (front, _) = queue.inner.as_views()
  queue.clear()
  queue.release_unused(placeholder="-")
  inspect(queue.length(), content="0")
  inspect(queue.capacity(), content="3")
  @debug.debug_inspect(
    front,
    content=(
      #|<ArrayView: ["-", "-", "-"]>
    ),
  )
}

///|
test "Queue::release_unused covers a wrapped buffer" {
  let queue : Queue[String] = from_array(["a", "b", "c", "d", "e"])
  let (whole, _) = queue.inner.as_views()
  // rotate so the contents wrap around the end of the buffer
  for _ in 0..<3 {
    queue.push(queue.pop().unwrap())
  }
  let (front, back) = queue.inner.as_views()
  assert_true(back.length() > 0)
  @debug.debug_inspect(
    front,
    content=(
      #|<ArrayView: ["d", "e"]>
    ),
  )
  let _ = queue.pop()
  queue.release_unused(placeholder="-")
  @debug.debug_inspect(
    queue,
    content=(
      #|<Queue: ["e", "a", "b", "c"]>
    ),
  )
  // only the slot `pop` vacated (which held "d") was overwritten
  @debug.debug_inspect(
    whole,
    content=(
      #|<ArrayView: ["a", "b", "c", "-", "e"]>
    ),
  )
}
