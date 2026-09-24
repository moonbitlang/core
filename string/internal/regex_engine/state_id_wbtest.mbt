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
test "state id encoding round-trips at the bounds" {
  for base in [0, 1, 7, 0x7FFFFFFD] {
    let running = StateId::new(base~, is_break=false)
    assert_false(running.is_break())
    assert_true(running.transition_base() == base)
    assert_false(running.0 == pending_state_id.0)
    let breaking = StateId::new(base~, is_break=true)
    assert_true(breaking.is_break())
    assert_true(breaking.transition_base() == base)
    assert_false(breaking.0 == pending_state_id.0)
  }
  assert_false(pending_state_id.is_break())
}

///|
test "panic state id rejects bases the break encoding cannot represent" {
  StateId::new(base=0x7FFFFFFE, is_break=true) |> ignore
}
