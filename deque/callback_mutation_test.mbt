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

// A callback that modifies the deque it is called on only gets memory safety:
// the expected values below record the current behaviour (the operation works
// on the buffer, head and length captured before the first call), not a
// contract.

///|
test "map with a callback that pops from the front" {
  let dq = two_in_eight()
  let mapped = dq.map(x => {
    // `head` moves to slot 1; a live read of `head + 1` would hit slot 2.
    dq.pop_front() |> ignore
    x + "!"
  })
  debug_inspect(mapped, content="<Deque: [\"a!\", \"b!\"]>")
}

///|
test "map with a callback that grows the deque" {
  let dq = @deque.Deque(["a", "b"])
  let mapped = dq.map(x => {
    dq.push_back(x)
    x + "!"
  })
  // The result must not take the live length, which exceeds its capacity.
  inspect(mapped.length(), content="2")
  assert_true(mapped.capacity() >= mapped.length())
  debug_inspect(mapped, content="<Deque: [\"a!\", \"b!\"]>")
}

///|
test "mapi with a callback that pops from the front" {
  let dq = two_in_eight()
  let mapped = dq.mapi((i, x) => {
    dq.pop_front() |> ignore
    "\{i}\{x}"
  })
  debug_inspect(mapped, content="<Deque: [\"0a\", \"1b\"]>")
}

///|
test "mapi with a callback that clears and shrinks the deque" {
  let dq = @deque.Deque(["a", "b", "c"])
  let mapped = dq.mapi((i, x) => {
    dq.clear()
    dq.shrink_to_fit()
    "\{i}\{x}"
  })
  debug_inspect(mapped, content="<Deque: [\"0a\", \"1b\", \"2c\"]>")
}

///|
/// An element whose `Eq` runs a hook, so `search` can modify the deque from
/// inside the comparison.
priv struct Hooked {
  name : String
  hook : () -> Unit
}

///|
impl Eq for Hooked with fn equal(self, other) {
  (self.hook)()
  (other.hook)()
  self.name == other.name
}

///|
test "search with an Eq that pops from the front" {
  let dq : @deque.Deque[Hooked] = Deque(
    [{ name: "a", hook: () => (), }, { name: "b", hook: () => (), }],
    capacity=8,
  )
  let probe = { name: "b", hook: () => dq.pop_front() |> ignore, }
  debug_inspect(dq.search(probe), content="Some(1)")
}

///|
test "extract_if with a callback that clears the deque" {
  let dq = @deque.Deque(["a", "b", "c"])
  let removed = dq.extract_if(x => {
    dq.clear()
    x == "a"
  })
  debug_inspect(removed, content="<Deque: [\"a\"]>")
  // Subtracting the removed count from the live length left it at -1.
  inspect(dq.length(), content="0")
  debug_inspect(dq, content="<Deque: []>")
}

///|
test "extract_if with a callback that pops from the front" {
  let dq = @deque.Deque(["a", "b", "c", "d"], capacity=8)
  let removed = dq.extract_if(x => {
    dq.pop_front() |> ignore
    x == "b"
  })
  debug_inspect(removed, content="<Deque: [\"b\"]>")
  assert_true(dq.length() >= 0)
  assert_true(dq.capacity() >= dq.length())
}

///|
test "shuffle_in_place with a rand that clears and shrinks the deque" {
  let dq = @deque.Deque(["a", "b", "c"])
  dq.shuffle_in_place(rand=_ => {
    dq.clear()
    dq.shrink_to_fit()
    0
  })
  debug_inspect(dq, content="<Deque: []>")
}
