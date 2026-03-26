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
fn Regex::get_state(self : Regex, state_id : StateId) -> @automata.State {
  self.states.unsafe_get(state_id.index())
}

///|
fn Regex::stablize_start_state(self : Regex, prev_cat : Category) -> StateId {
  for i in 0..<self.start_states.length() {
    let (cat, state_id) = self.start_states[i]
    if cat == prev_cat {
      return state_id
    }
  }
  let state_id = self.stablize_state(
    @automata.State::start(prev_cat, self.expr),
  )
  self.start_states.push((prev_cat, state_id))
  state_id
}

///|
fn Regex::stablize_state(self : Regex, state : @automata.State) -> StateId {
  self.state_table.get_or_init(state, () => {
    let index = self.num_states
    self.num_states += 1
    let num_symbols = self.num_symbols()
    if index >= self.states.length() {
      let new_states_len = Int::max(self.states.length() * 2, 4)

      let new_states = FixedArray::make(new_states_len, @automata.st_dummy)
      self.states.blit_to(new_states, len=self.states.length())

      let new_transition_table = FixedArray::make(
        new_states_len * num_symbols,
        pending_state_id,
      )
      self.transition_table.blit_to(
        new_transition_table,
        len=self.transition_table.length(),
      )

      let new_final_table = FixedArray::make(new_states_len, @list.empty())
      self.final_table.blit_to(new_final_table, len=self.final_table.length())

      self.states = new_states
      self.transition_table = new_transition_table
      self.final_table = new_final_table
    }
    self.states[index] = state
    let state_id = StateId::new(
      index~,
      slot=state.slot(),
      is_break=state.status() is (Match(_) | Failed),
      num_symbols~,
    )
    state_id
  })
}

///|
fn Regex::stablize_next_state(
  self : Regex,
  prev_state_id : StateId,
  symbol : Rechar,
) -> StateId {
  let cat = category_from_symbol(
    profile=self.profile,
    symbol_repr=self.symbol_repr,
    symbol,
  )
  let prev_state = self.get_state(prev_state_id)
  let state = @automata.delta(ctx=self.ctx, prev_state, symbol, next_cat=cat)
  self.stablize_state(state)
}

///|
fn Regex::stablize_final(
  self : Regex,
  state_id : StateId,
  state : @automata.State,
  next_cat : Category,
) -> (@automata.Slot, @automata.Status) {
  let state_index = state_id.index()
  for entry = self.final_table[state_index] {
    match entry {
      Empty => {
        let next_state = @automata.delta(
          ctx=self.ctx,
          state,
          NULL_SYMBOL,
          next_cat~,
        )
        let slot = next_state.slot()
        let status = next_state.status()
        self.final_table[state_index] = @list.cons(
          (next_cat, slot, status),
          self.final_table[state_index],
        )
        break (slot, status)
      }
      More(head, tail~) =>
        if head.0 == next_cat {
          break (head.1, head.2)
        } else {
          continue tail
        }
    }
  }
}
