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
test "panic unsafe_pop_front" {
  @deque.from_array(([] : Array[Int])).unsafe_pop_front()
}

///|
test "panic unsafe_pop_back" {
  @deque.from_array(([] : Array[Int])).unsafe_pop_back()
}

///|
test "panic get" {
  @deque.from_array([1, 2, 3])[-1] |> ignore
}

///|
test "panic Deque::set" {
  @deque.from_array([1, 2, 3])[-1] = 1
}

///|
test "panic insert out of bounds" {
  @deque.from_array([1, 2, 3]).insert(4, 9)
}

///|
test "panic remove out of bounds" {
  @deque.from_array([1, 2, 3]).remove(3) |> ignore
}

///|
test "panic drain with negative start" {
  @deque.from_array([5, 6]).drain(start=-1) |> ignore
}

///|
test "panic drain with start out of bounds" {
  @deque.from_array([5, 6]).drain(start=100) |> ignore
}

///|
test "panic drain with negative len" {
  @deque.from_array([5, 6]).drain(start=0, len=-1) |> ignore
}

///|
test "panic drain with len exceeding bounds" {
  @deque.from_array([5, 6]).drain(start=1, len=100) |> ignore
}

///|
test "panic blit_to with overflowing source range" {
  let source = @deque.from_array([1, 2, 3])
  let destination = @deque.from_array([0])
  source.blit_to(destination, src_offset=0x7fffffff, len=1)
}

///|
test "panic drain with overflowing range" {
  @deque.from_array([1, 2, 3]).drain(start=1, len=0x7fffffff) |> ignore
}

///|
test "panic extract_if predicate clears the deque" {
  let dq = @deque.Deque([1])
  ignore(
    dq.extract_if(_ => {
      dq.clear()
      true
    }),
  )
}

///|
test "panic extract_if predicate replaces the buffer" {
  let dq = @deque.Deque([1])
  ignore(
    dq.extract_if(_ => {
      dq.reserve_capacity(10)
      false
    }),
  )
}

///|
test "panic extract_if predicate rotates the head" {
  let dq = @deque.Deque([1, 2, 3])
  let mut first = true
  ignore(
    dq.extract_if(_ => {
      if first {
        first = false
        dq.push_back(dq.pop_front().unwrap())
      }
      true
    }),
  )
}

///|
test "panic flatten total length overflow with shared deques" {
  // Only two small buffers are needed to describe 2^32 output elements.
  let inner = @deque.Deque(Array::make(65536, 0))
  let outer = @deque.Deque(Array::make(65536, inner))
  ignore(outer.flatten())
}
