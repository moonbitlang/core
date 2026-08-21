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
/// The deque representation invariant guarantees these indices are in bounds.
/// Keep these private so callers cannot bypass bounds checks.
#inline
fn[T] UninitializedArray::unsafe_get(
  self : UninitializedArray[T],
  index : Int,
) -> T = "%fixedarray.unsafe_get"

///|
#inline
fn[T] UninitializedArray::unsafe_set(
  self : UninitializedArray[T],
  index : Int,
  value : T,
) -> Unit = "%fixedarray.unsafe_set"

///|
/// Converts a zero-based logical offset from `head` to a physical buffer index.
/// If the offset fits before the buffer end, `head + offset` is known to be less
/// than `capacity`. Otherwise the wrapped branch subtracts the remaining space
/// from `offset` and never evaluates that addition.
#inline
fn wrap_index(
  head : Int,
  offset : Int,
  capacity : Int,
) -> Int where {
  proof_require: index_in_bounds(head, capacity),
  proof_require: index_in_bounds(offset, capacity),
  proof_ensure: result => {
    circular_index_at_offset(head, offset, capacity, result)
  },
} {
  let contiguous = capacity - head
  if offset < contiguous {
    head + offset
  } else {
    offset - contiguous
  }
}

///|
/// Moves an in-buffer index forward by one without division.
#inline
fn increment_index(
  index : Int,
  capacity : Int,
) -> Int where {
  proof_require: index_in_bounds(index, capacity),
  proof_ensure: result => circular_successor(index, capacity, result),
} {
  if index == capacity - 1 {
    0
  } else {
    index + 1
  }
}

///|
/// Moves an in-buffer index back by one without division.
#inline
fn decrement_index(
  index : Int,
  capacity : Int,
) -> Int where {
  proof_require: index_in_bounds(index, capacity),
  proof_ensure: result => circular_predecessor(index, capacity, result),
} {
  if index == 0 {
    capacity - 1
  } else {
    index - 1
  }
}

///|
/// Computes the capacity used by `realloc` after its runtime overflow check.
/// The contract proves the layout invariant restored after a successful growth.
#warnings("-unused_value")
#inline
fn deque_realloc_capacity(
  capacity : Int,
  len : Int,
) -> Int where {
  proof_require: len >= 0,
  proof_require: len <= capacity,
  proof_require: capacity <= 0x3fff_ffff,
  proof_ensure: result => result > capacity,
  proof_ensure: result => result <= 0x7fff_ffff,
  proof_ensure: result => len < result,
  proof_ensure: result => deque_layout_inv(result, 0, len),
} {
  if capacity == 0 {
    8
  } else {
    capacity * 2
  }
}

///|
#inline
fn deque_tail_index(
  head : Int,
  len : Int,
  capacity : Int,
) -> Int where {
  proof_require: deque_layout_inv(capacity, head, len),
  proof_require: len > 0,
  proof_ensure: result => {
    circular_index_at_offset(head, len - 1, capacity, result)
  },
  proof_ensure: result => index_in_bounds(result, capacity),
} {
  wrap_index(head, len - 1, capacity)
}

///|
#warnings("-unused_value")
#inline
fn deque_element_index(
  head : Int,
  len : Int,
  capacity : Int,
  index : Int,
) -> Int where {
  proof_require: deque_layout_inv(capacity, head, len),
  proof_require: index >= 0,
  proof_require: index < len,
  proof_ensure: result => {
    circular_index_at_offset(head, index, capacity, result)
  },
  proof_ensure: result => index_in_bounds(result, capacity),
} {
  wrap_index(head, index, capacity)
}

///|
#inline
fn deque_push_back_core(
  head : Int,
  len : Int,
  capacity : Int,
) -> Int where {
  proof_require: deque_layout_inv(capacity, head, len),
  proof_require: len < capacity,
  proof_ensure: result => circular_index_at_offset(head, len, capacity, result),
  proof_ensure: result => {
    index_in_bounds(result, capacity) &&
    deque_layout_inv(capacity, head, len + 1)
  },
} {
  wrap_index(head, len, capacity)
}

///|
#warnings("-unused_value")
#inline
fn deque_push_front_core(
  head : Int,
  len : Int,
  capacity : Int,
) -> Int where {
  proof_require: deque_layout_inv(capacity, head, len),
  proof_require: len < capacity,
  proof_ensure: result => circular_predecessor(head, capacity, result),
  proof_ensure: result => index_in_bounds(result, capacity),
  proof_ensure: result => deque_layout_inv(capacity, result, len + 1),
} {
  decrement_index(head, capacity)
}

///|
#warnings("-unused_value")
#inline
fn deque_pop_front_core(
  head : Int,
  len : Int,
  capacity : Int,
) -> Int where {
  proof_require: deque_layout_inv(capacity, head, len),
  proof_require: len > 0,
  proof_ensure: result => circular_successor(head, capacity, result),
  proof_ensure: result => index_in_bounds(result, capacity),
  proof_ensure: result => deque_layout_inv(capacity, result, len - 1),
} {
  increment_index(head, capacity)
}

///|
#inline
fn deque_pop_back_core(
  head : Int,
  len : Int,
  capacity : Int,
) -> Int where {
  proof_require: deque_layout_inv(capacity, head, len),
  proof_require: len > 0,
  proof_ensure: result => {
    circular_index_at_offset(head, len - 1, capacity, result)
  },
  proof_ensure: result => {
    index_in_bounds(result, capacity) &&
    deque_layout_inv(capacity, head, len - 1)
  },
} {
  wrap_index(head, len - 1, capacity)
}
