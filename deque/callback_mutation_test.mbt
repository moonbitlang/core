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

// A callback or iterator over a deque that the deque's owner modifies gets
// unspecified results, but the results must stay memory-safe: an iterator
// reads the elements the deque held when the iterator was created.

///|
test "for-in: shrink and reallocate during iteration" {
  let dq = @deque.Deque(["a", "b", "c", "d"], capacity=4)
  let seen = []
  for x in dq {
    if seen.is_empty() {
      dq.pop_back() |> ignore
      dq.pop_back() |> ignore
      dq.pop_back() |> ignore
      dq.reserve_capacity(64)
    }
    seen.push(x)
  }
  debug_inspect(seen, content="[\"a\", \"b\", \"c\", \"d\"]")
  debug_inspect(dq.to_array(), content="[\"a\"]")
}

///|
test "iter: clear and shrink_to_fit during iteration" {
  let dq = @deque.Deque([1, 2, 3])
  let it = dq.iter()
  debug_inspect(it.next(), content="Some(1)")
  dq.clear()
  dq.shrink_to_fit()
  debug_inspect(it.next(), content="Some(2)")
  debug_inspect(it.next(), content="Some(3)")
  debug_inspect(it.next(), content="None")
}

///|
test "iter2: clear and shrink_to_fit during iteration" {
  let dq = @deque.Deque([1, 2, 3])
  let it = dq.iter2()
  debug_inspect(it.next(), content="Some((0, 1))")
  dq.clear()
  dq.shrink_to_fit()
  debug_inspect(it.next(), content="Some((1, 2))")
  debug_inspect(it.next(), content="Some((2, 3))")
  debug_inspect(it.next(), content="None")
}

///|
test "rev_iter: clear and shrink_to_fit during iteration" {
  let dq = @deque.Deque([1, 2, 3])
  let it = dq.rev_iter()
  debug_inspect(it.next(), content="Some(3)")
  dq.clear()
  dq.shrink_to_fit()
  debug_inspect(it.next(), content="Some(2)")
  debug_inspect(it.next(), content="Some(1)")
  debug_inspect(it.next(), content="None")
}

///|
test "rev_iter2: clear and shrink_to_fit during iteration" {
  let dq = @deque.Deque([1, 2, 3])
  let it = dq.rev_iter2()
  debug_inspect(it.next(), content="Some((0, 3))")
  dq.clear()
  dq.shrink_to_fit()
  debug_inspect(it.next(), content="Some((1, 2))")
  debug_inspect(it.next(), content="Some((2, 1))")
  debug_inspect(it.next(), content="None")
}

///|
test "iter: wrapped buffer" {
  let dq = @deque.Deque([], capacity=4)
  dq.push_back(3)
  dq.push_back(4)
  dq.push_front(2)
  dq.push_front(1)
  debug_inspect(dq.iter().to_array(), content="[1, 2, 3, 4]")
  debug_inspect(dq.rev_iter().to_array(), content="[4, 3, 2, 1]")
  debug_inspect(
    dq.iter2().to_array(),
    content="[(0, 1), (1, 2), (2, 3), (3, 4)]",
  )
  debug_inspect(
    dq.rev_iter2().to_array(),
    content="[(0, 4), (1, 3), (2, 2), (3, 1)]",
  )
}

///|
test "map: callback grows the source" {
  let dq = @deque.Deque([1, 2, 3], capacity=3)
  let r = dq.map(x => {
    dq.push_back(x)
    x * 10
  })
  inspect(r.length(), content="3")
  debug_inspect(r.to_array(), content="[10, 20, 30]")
  debug_inspect(dq.to_array(), content="[1, 2, 3, 1, 2, 3]")
}

///|
test "map: callback clears the source" {
  let dq = @deque.Deque([1, 2, 3])
  let r = dq.map(x => {
    dq.clear()
    dq.shrink_to_fit()
    x * 10
  })
  debug_inspect(r.to_array(), content="[10, 20, 30]")
}

///|
test "mapi: callback grows the source" {
  let dq = @deque.Deque([1, 2, 3], capacity=3)
  let r = dq.mapi((i, x) => {
    dq.push_back(x)
    x * 10 + i
  })
  inspect(r.length(), content="3")
  debug_inspect(r.to_array(), content="[10, 21, 32]")
}

///|
test "mapi: callback clears the source" {
  let dq = @deque.Deque([1, 2, 3])
  let r = dq.mapi((i, x) => {
    dq.clear()
    dq.shrink_to_fit()
    x * 10 + i
  })
  debug_inspect(r.to_array(), content="[10, 21, 32]")
}

///|
test "extract_if: callback clears the source" {
  let dq = @deque.Deque([1])
  let r = dq.extract_if(_ => {
    dq.clear()
    true
  })
  debug_inspect(r.to_array(), content="[1]")
  inspect(dq.length(), content="0")
  dq.push_back(5)
  debug_inspect(dq.to_array(), content="[5]")
}

///|
test "extract_if: callback shrinks the buffer" {
  let dq = @deque.Deque([1, 2, 3, 4])
  let r = dq.extract_if(x => {
    if x == 2 {
      dq.clear()
      dq.shrink_to_fit()
    }
    x % 2 == 0
  })
  debug_inspect(r.to_array(), content="[2, 4]")
  inspect(dq.length(), content="0")
  dq.push_back(5)
  debug_inspect(dq.to_array(), content="[5]")
}

///|
let search_target : Ref[@deque.Deque[Probe]] = { val: Deque([]), }

///|
/// Comparing two probes empties the deque in `search_target`.
priv struct Probe(Int32)

///|
impl Eq for Probe with fn equal(self, other) {
  search_target.val.clear()
  search_target.val.shrink_to_fit()
  self.0 == other.0
}

///|
test "search: Eq clears the source" {
  let dq = @deque.Deque([Probe(1), Probe(2), Probe(3)])
  search_target.val = dq
  debug_inspect(dq.search(Probe(3)), content="Some(2)")
}

///|
fn wrapped_deque_1234() -> @deque.Deque[Int32] {
  // Capacity 4 with head at 2: the elements wrap past the end of the buffer.
  let dq = @deque.Deque([], capacity=4)
  dq.push_back(3)
  dq.push_back(4)
  dq.push_front(2)
  dq.push_front(1)
  dq
}

///|
test "map/mapi: wrapped buffer, callback grows the source" {
  let dq = wrapped_deque_1234()
  let r = dq.map(x => {
    dq.push_back(x)
    x * 10
  })
  debug_inspect(r.to_array(), content="[10, 20, 30, 40]")
  debug_inspect(dq.to_array(), content="[1, 2, 3, 4, 1, 2, 3, 4]")
  let dq = wrapped_deque_1234()
  let r = dq.mapi((i, x) => {
    dq.push_front(x)
    x * 10 + i
  })
  debug_inspect(r.to_array(), content="[10, 21, 32, 43]")
}

///|
test "extract_if: wrapped buffer" {
  let dq = wrapped_deque_1234()
  let r = dq.extract_if(x => x % 2 == 0)
  debug_inspect(r.to_array(), content="[2, 4]")
  debug_inspect(dq.to_array(), content="[1, 3]")
}

///|
test "extract_if: wrapped buffer, callback grows the source" {
  // The result is unspecified, but the deque must stay usable.
  let dq = wrapped_deque_1234()
  let r = dq.extract_if(x => {
    dq.push_back(x)
    x % 2 == 0
  })
  debug_inspect(r.to_array(), content="[2, 4]")
  inspect(dq.length() == dq.iter().count(), content="true")
  dq.push_back(9)
  inspect(dq.to_array().length() == dq.length(), content="true")
}
