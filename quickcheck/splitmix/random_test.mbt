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
  let state = @splitmix.new()
  let _ = state.next()
  inspect(state.next_uint(), content="1118850684")
}

///|
test "next_two_uint should return two 32-bit unsigned integers" {
  let state = @splitmix.new()
  debug_inspect(state.next_two_uint(), content="(520772969, 1037978766)")
}

///|
test "clone_random_state" {
  let state = @splitmix.new(seed=42UL)
  let cloned = state.clone()

  // Generate some values from both states to ensure they behave the same
  let orig_int = state.next_int()
  let clone_int = cloned.next_int()

  // The cloned state should produce the same value as the original
  inspect(orig_int == clone_int, content="true")
}

///|
test "next_float" {
  let state = @splitmix.new(seed=42UL)
  let result = state.next_float()
  // Since the result is random, we only check if it falls within the expected range [0, 1]
  inspect(result >= 0.0, content="true")
  inspect(result <= 1.0, content="true")
}

///|
test "mix_gamma else branch seed" {
  let state = @splitmix.new(seed=930507UL)
  inspect(state.next_uint(), content="3773570134")
}

///|
test "next_uint64_below skips masked values outside the bound" {
  let state = @splitmix.new(seed=7UL)
  let value = state.next_uint64_below(3UL)
  debug_inspect((value, state.next_uint64()), content="(2, 622236291405445593)")
}

///|
test "next_uint_below skips masked values outside the bound" {
  let state = @splitmix.new(seed=7UL)
  let value = state.next_uint_below(3U)
  debug_inspect((value, state.next_uint64()), content="(2, 622236291405445593)")
}

///|
test "next_uint64_below handles unit and power-of-two bounds" {
  let unit = @splitmix.new(seed=1UL)
  let unit_value = unit.next_uint64_below(1UL)
  let power = @splitmix.new(seed=1UL)
  let power_value = power.next_uint64_below(8UL)
  debug_inspect(
    (unit_value, unit.next_uint64(), power_value, power.next_uint64()),
    content="(0, 9482272708574442377, 1, 9482272708574442377)",
  )
}

///|
test "panic next_uint64_below rejects a zero bound" {
  let state = @splitmix.new(seed=1UL)
  ignore(state.next_uint64_below(0UL))
}

///|
test "panic next_uint_below rejects a zero bound" {
  let state = @splitmix.new(seed=1UL)
  ignore(state.next_uint_below(0U))
}
