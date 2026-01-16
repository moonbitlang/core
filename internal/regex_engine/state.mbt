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
priv struct State {
  kind : StateKind
  desc : @automata.State
  transitions : FixedArray[State] // indexed by symbol
  mut final_ : @list.List[(Category, @automata.Slot, @automata.Status)]
}

///|
priv enum StateKind {
  Pending
  Break
  Normal
}

///|
fn State::new(desc : @automata.State, num_symbols : Int) -> State {
  let is_break = match desc.status() {
    Match(_) | Failed => true
    Running => false
  }
  State::{
    kind: if is_break {
      Break
    } else {
      Normal
    },
    desc,
    transitions: if is_break {
      []
    } else {
      FixedArray::make(num_symbols, pending_state)
    },
    final_: @list.empty(),
  }
}

///|
let pending_state : State = {
  kind: Pending,
  desc: @automata.st_dummy,
  transitions: [],
  final_: @list.empty(),
}

///|
fn find_state(
  table : @hashmap.HashMap[@automata.State, State],
  num_symbols : Int,
  desc : @automata.State,
) -> State {
  table.get_or_init(desc, () => State::new(desc, num_symbols))
}
