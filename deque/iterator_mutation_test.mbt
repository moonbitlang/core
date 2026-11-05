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

// An iterator over a deque that is modified meanwhile only promises to stay
// memory-safe. The expected values below record the current behaviour (the
// iterator walks the buffer, head and length it captured at creation); they
// are not a contract.

///|
/// Two elements in a buffer of capacity 8: slots 2..<8 were never written.
fn two_in_eight() -> @deque.Deque[String] {
  Deque(["a", "b"], capacity=8)
}

///|
test "iter after pop_front does not read unwritten slots" {
  let dq = two_in_eight()
  let it = dq.iter()
  debug_inspect(it.next(), content="Some(\"a\")")
  // `head` moves to slot 1; a live read of `head + 1` would hit slot 2.
  dq.pop_front() |> ignore
  debug_inspect(it.to_array(), content="[\"b\"]")
}

///|
test "iter2 after pop_front does not read unwritten slots" {
  let dq = two_in_eight()
  let it = dq.iter2()
  debug_inspect(it.next(), content="Some((0, \"a\"))")
  dq.pop_front() |> ignore
  debug_inspect(it.to_array(), content="[(1, \"b\")]")
}

///|
test "rev_iter after pop_front does not read unwritten slots" {
  let dq = two_in_eight()
  let it = dq.rev_iter()
  dq.pop_front() |> ignore
  debug_inspect(it.to_array(), content="[\"b\", \"a\"]")
}

///|
test "rev_iter2 after pop_front does not read unwritten slots" {
  let dq = two_in_eight()
  let it = dq.rev_iter2()
  dq.pop_front() |> ignore
  debug_inspect(it.to_array(), content="[(0, \"b\"), (1, \"a\")]")
}

///|
test "for-in loop popping from the front" {
  let dq = two_in_eight()
  let seen = []
  for x in dq {
    seen.push(x)
    dq.pop_front() |> ignore
  }
  debug_inspect(seen, content="[\"a\", \"b\"]")
  debug_inspect(dq, content="<Deque: []>")
}

///|
/// `clear` + `shrink_to_fit` replaces the buffer with one of length 0, which a
/// live `% buf.length()` would divide by.
fn emptied_and_shrunk(dq : @deque.Deque[String]) -> Unit raise {
  dq.clear()
  dq.shrink_to_fit()
  @test.assert_eq(dq.capacity(), 0)
}

///|
test "iter after clear and shrink_to_fit" {
  let dq = @deque.Deque(["a", "b", "c"])
  let it = dq.iter()
  emptied_and_shrunk(dq)
  debug_inspect(it.to_array(), content="[\"a\", \"b\", \"c\"]")
}

///|
test "iter2 after clear and shrink_to_fit" {
  let dq = @deque.Deque(["a", "b", "c"])
  let it = dq.iter2()
  emptied_and_shrunk(dq)
  debug_inspect(it.to_array(), content="[(0, \"a\"), (1, \"b\"), (2, \"c\")]")
}

///|
test "rev_iter after clear and shrink_to_fit" {
  let dq = @deque.Deque(["a", "b", "c"])
  let it = dq.rev_iter()
  emptied_and_shrunk(dq)
  debug_inspect(it.to_array(), content="[\"c\", \"b\", \"a\"]")
}

///|
test "rev_iter2 after clear and shrink_to_fit" {
  let dq = @deque.Deque(["a", "b", "c"])
  let it = dq.rev_iter2()
  emptied_and_shrunk(dq)
  debug_inspect(it.to_array(), content="[(0, \"c\"), (1, \"b\"), (2, \"a\")]")
}

///|
test "iter over a wrapped buffer after reallocation" {
  // Elements wrap around the end of the buffer: slots 6, 7, 0, 1.
  let dq = @deque.Deque([], capacity=8)
  for x in ["x", "x", "x", "x", "x", "x"] {
    dq.push_back(x)
  }
  for _ in 0..<6 {
    dq.pop_front() |> ignore
  }
  for x in ["a", "b", "c", "d"] {
    dq.push_back(x)
  }
  let it = dq.iter()
  debug_inspect(it.next(), content="Some(\"a\")")
  // Growing moves the elements to a new buffer starting at slot 0.
  dq.reserve_capacity(64)
  dq.push_front("z")
  debug_inspect(it.to_array(), content="[\"b\", \"c\", \"d\"]")
}
