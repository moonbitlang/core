// Copyright 2025 International Digital Economy Academy
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
  inspect(state.next_two_uint(), content="(520772969, 1037978766)")
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
