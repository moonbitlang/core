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
test "iterators keep initialized slots after front removal" {
  let dq = @deque.Deque([(1, "a"), (2, "b"), (3, "c")], capacity=8)
  let forward = dq.iter()
  let indexed = dq.iter2()
  let reverse = dq.rev_iter()
  let reverse_indexed = dq.rev_iter2()
  ignore(forward.next())
  ignore(indexed.next())
  ignore(reverse.next())
  ignore(reverse_indexed.next())
  // Move the head into unused slots without overwriting the old elements.
  ignore(dq.pop_front())
  ignore(dq.pop_front())
  ignore(dq.pop_front())
  for
    iter in [
      forward,
      indexed.iter().map(pair => pair.1),
      reverse,
      reverse_indexed.iter().map(pair => pair.1),
    ] {
    let values = iter.map(value => value.1.length()).to_array()
    assert_eq(values, [1, 1])
  }
}

///|
test "iterators keep wrapped storage after clearing and shrinking" {
  let dq = @deque.Deque([(1, "a"), (2, "b")], capacity=8)
  dq.push_front((0, "z"))
  let forward = dq.iter()
  let indexed = dq.iter2()
  let reverse = dq.rev_iter()
  let reverse_indexed = dq.rev_iter2()
  dq.clear()
  dq.shrink_to_fit()
  debug_inspect(
    forward.to_array(),
    content="[(0, \"z\"), (1, \"a\"), (2, \"b\")]",
  )
  debug_inspect(
    indexed.to_array(),
    content="[(0, (0, \"z\")), (1, (1, \"a\")), (2, (2, \"b\"))]",
  )
  debug_inspect(
    reverse.to_array(),
    content="[(2, \"b\"), (1, \"a\"), (0, \"z\")]",
  )
  debug_inspect(
    reverse_indexed.to_array(),
    content="[(0, (2, \"b\")), (1, (1, \"a\")), (2, (0, \"z\"))]",
  )
}

///|
test "each and filter tolerate source removal" {
  let dq = @deque.Deque([(1, "a"), (2, "b"), (3, "c")], capacity=8)
  let seen = []
  dq.each(value => {
    ignore(dq.pop_front())
    seen.push(value.1.length())
  })
  debug_inspect(seen, content="[1, 1, 1]")
  let source = @deque.Deque([(1, "a"), (2, "b"), (3, "c")], capacity=8)
  let result = source.filter(value => {
    ignore(source.pop_front())
    value.1.length() == 1
  })
  inspect(result.length(), content="3")
}

///|
test "mapping keeps initialized slots after growth and head movement" {
  let dq = @deque.Deque([(1, "a"), (2, "bb")], capacity=8)
  let mut first = true
  let mapped = dq.map(value => {
    if first {
      first = false
      dq.reserve_capacity(10)
      dq.push_front((3, "c"))
    }
    value.1.length()
  })
  debug_inspect(mapped.to_array(), content="[1, 2]")
  let source = @deque.Deque([(1, "a"), (2, "bb")], capacity=8)
  let indexed = source.mapi((i, value) => {
    if i == 0 {
      source.reserve_capacity(10)
      source.push_front((3, "c"))
    }
    i + value.1.length()
  })
  debug_inspect(indexed.to_array(), content="[1, 3]")
}

///|
test "mapping keeps initialized slots after clearing and shrinking" {
  let dq = @deque.Deque([(1, "a"), (2, "bb")], capacity=8)
  let mapped = dq.map(value => {
    dq.clear()
    dq.shrink_to_fit()
    value.1.length()
  })
  debug_inspect(mapped.to_array(), content="[1, 2]")
  let source = @deque.Deque([(1, "a"), (2, "bb")], capacity=8)
  let indexed = source.mapi((i, value) => {
    source.clear()
    source.shrink_to_fit()
    i + value.1.length()
  })
  debug_inspect(indexed.to_array(), content="[1, 3]")
}

///|
test "extracting preserves a valid length when the callback clears the deque" {
  let dq = @deque.Deque([(1, "a"), (2, "bb")], capacity=8)
  let removed = dq.extract_if(value => {
    dq.clear()
    dq.shrink_to_fit()
    value.1.length() > 0
  })
  inspect(dq.length(), content="0")
  debug_inspect(removed.to_array(), content="[(1, \"a\"), (2, \"bb\")]")
  dq.push_back((3, "c"))
  debug_inspect(dq.to_array(), content="[(3, \"c\")]")
  let source = @deque.Deque([(1, "a"), (2, "bb")], capacity=8)
  let removed = source.extract_if(_ => {
    source.clear()
    source.shrink_to_fit()
    false
  })
  inspect(removed.length(), content="0")
  debug_inspect(source.to_array(), content="[(1, \"a\"), (2, \"bb\")]")
}

///|
test "shuffling keeps initialized slots when the callback moves the head" {
  let dq = @deque.Deque([(1, "a"), (2, "bb")], capacity=8)
  let old_slots = dq.iter()
  dq.shuffle_in_place(rand=_ => {
    ignore(dq.pop_front())
    ignore(dq.pop_front())
    0
  })
  debug_inspect(
    old_slots.map(value => value.1.length()).to_array(),
    content="[2, 1]",
  )
  inspect(dq.length(), content="0")
}
