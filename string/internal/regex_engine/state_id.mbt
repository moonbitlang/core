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
priv struct StateId(Int64)

///|
let pending_state_id : StateId = -1

///|
fn StateId::new(
  index~ : Int,
  slot~ : @automata.Slot,
  is_break~ : Bool,
  num_symbols~ : Int,
) -> StateId {
  debug_assert(() => {
    index <= 0b1111_1111_1111_1111_1110 &&
    slot.index <= 0b111_1111_1111 &&
    num_symbols <= 0b111_1111_1110
  })
  let transition_base = index * num_symbols
  let encoded_index = if is_break { -2 - index } else { index }
  let id = StateId(
    (((encoded_index << 11) | slot.index).to_int64() << 32) |
    transition_base.to_int64(),
  )
  debug_assert(() => {
    id.index() == index && id.slot() == slot && id.is_break() == is_break
  })
  id
}

///|
fn StateId::is_pending(self : StateId) -> Bool {
  self.0 == -1
}

///|
fn StateId::is_break(self : StateId) -> Bool {
  self.0 < -1
}

///|
fn StateId::transition_base(self : StateId) -> Int {
  self.0.to_int()
}

///|
fn StateId::index(self : StateId) -> Int {
  let x = (self.0 >> 43).to_int()
  if x < 0 {
    -(x + 2)
  } else {
    x
  }
}

///|
fn StateId::slot(self : StateId) -> @automata.Slot {
  @automata.Slot::from_index((self.0 >> 32).to_int() & 0b111_1111_1111)
}
