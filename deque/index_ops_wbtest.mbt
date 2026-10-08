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
test "circular index arithmetic at Int limits" {
  for capacity in [1, 2, 3, 0x3fff_ffff, 0x4000_0000, 0x7fff_ffff] {
    for head in [0, capacity / 2, capacity - 1] {
      for offset in [0, capacity / 2, capacity - 1] {
        let expected = ((head.to_int64() + offset.to_int64()) %
        capacity.to_int64()).to_int()
        @test.assert_eq(wrap_index(head, offset, capacity), expected)
      }
      @test.assert_eq(
        increment_index(head, capacity),
        ((head.to_int64() + 1) % capacity.to_int64()).to_int(),
      )
      @test.assert_eq(
        decrement_index(head, capacity),
        ((head.to_int64() + capacity.to_int64() - 1) % capacity.to_int64()).to_int(),
      )
    }
  }
  inspect(deque_realloc_capacity(0, 0), content="8")
  inspect(deque_realloc_capacity(1, 1), content="2")
  inspect(
    deque_realloc_capacity(0x3fff_ffff, 0x3fff_ffff),
    content="2147483646",
  )
}

///|
test "combined deque lengths at Int limits" {
  inspect(deque_combined_length(0, 0), content="0")
  inspect(deque_combined_length(0, 0x7fff_ffff), content="2147483647")
  inspect(deque_combined_length(0x7fff_ffff, 0), content="2147483647")
  inspect(deque_combined_length(0x3fff_ffff, 0x4000_0000), content="2147483647")
}
