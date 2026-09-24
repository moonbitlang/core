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
/// Encoded reference to a stabilized state, as stored in the transition table.
///
/// - `value >= 0`: a running state; the value is its transition base
///   (`index * num_symbols`), so the next transition is `value + symbol`.
/// - `value == -1`: the transition has not been computed yet.
/// - `value <= -2`: a break state (matched or failed) with base `-2 - value`.
///
/// Keeping this a plain `Int` matters on the JS backend, where `Int64` is
/// lowered to `BigInt` and every operation in the scan loop would allocate.
priv struct StateId(Int)

///|
let pending_state_id : StateId = StateId(-1)

///|
fn StateId::new(base~ : Int, is_break~ : Bool) -> StateId {
  guard base >= 0 && base <= 0x7FFFFFFD else { panic() }
  StateId(if is_break { -2 - base } else { base })
}

///|
fn StateId::is_break(self : StateId) -> Bool {
  self.0 < -1
}

///|
fn StateId::transition_base(self : StateId) -> Int {
  if self.0 >= 0 {
    self.0
  } else {
    -2 - self.0
  }
}
