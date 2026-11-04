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
test "RandomState::next" {
  let state = @splitmix.RandomState()
  let _ = state.next()
  inspect(
    state.next_uint(),
    content=(
      #|2537841416
    ),
  )
}

///|
test "next_two_uint should return two 32-bit unsigned integers" {
  let state = @splitmix.RandomState()
  debug_inspect(
    state.next_two_uint(),
    content=(
      #|(278417593, 2319484945)
    ),
  )
}

///|
test "RandomState::copy preserves the current sequence independently" {
  let state = @splitmix.RandomState(seed=42UL)
  state.next()
  let copied = state.copy()
  // Advance each state in batches to detect shared mutable state.
  let expected = Array::makei(8, _ => state.next_uint64())
  let actual = Array::makei(8, _ => copied.next_uint64())
  inspect(actual == expected, content="true")
  let expected = Array::makei(8, _ => copied.next_uint64())
  let actual = Array::makei(8, _ => state.next_uint64())
  inspect(actual == expected, content="true")
}

///|
#warnings("-deprecated")
test "RandomState::clone remains compatible with copy" {
  let state = @splitmix.RandomState(seed=42UL)
  state.next()
  let cloned = state.clone()
  let copied = state.copy()
  for _ in 0..<8 {
    assert_eq(cloned.next_uint64(), copied.next_uint64())
  }
}

///|
test "next_float" {
  let state = @splitmix.RandomState(seed=42UL)
  let result = state.next_float()
  // Since the result is random, we only check if it falls within the expected range [0, 1]
  inspect(result >= 0.0, content="true")
  inspect(result <= 1.0, content="true")
}

///|
test "mix_gamma else branch seed" {
  let state = @splitmix.RandomState(seed=12UL)
  inspect(
    state.next_uint(),
    content=(
      #|134979002
    ),
  )
}

///|
test "next_uint64 with a limit skips masked values outside the bound" {
  // The first two masked candidates are 3 (rejected) and 2 (accepted).
  let state = @splitmix.RandomState(seed=2UL)
  let value = state.next_uint64(limit=3UL)
  debug_inspect(
    (value, state.next_uint64()),
    content=(
      #|(2, 560996353185190935)
    ),
  )
}

///|
test "next_uint with a limit skips masked values outside the bound" {
  let state = @splitmix.RandomState(seed=2UL)
  let value = state.next_uint(limit=3U)
  debug_inspect(
    (value, state.next_uint64()),
    content=(
      #|(2, 560996353185190935)
    ),
  )
}

///|
test "next_uint64 handles unit and power-of-two limits" {
  let unit = @splitmix.RandomState(seed=1UL)
  let unit_value = unit.next_uint64(limit=1UL)
  let power = @splitmix.RandomState(seed=1UL)
  let power_value = power.next_uint64(limit=8UL)
  debug_inspect(
    (unit_value, unit.next_uint64(), power_value, power.next_uint64()),
    content=(
      #|(0, 8251698951335059867, 5, 8251698951335059867)
    ),
  )
}

///|
test "panic next_uint64 rejects a zero limit" {
  let state = @splitmix.RandomState(seed=1UL)
  ignore(state.next_uint64(limit=0UL))
}

///|
test "panic next_uint rejects a zero limit" {
  let state = @splitmix.RandomState(seed=1UL)
  ignore(state.next_uint(limit=0U))
}
