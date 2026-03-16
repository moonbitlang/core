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
/// FIXME: derive(Debug) pulls in such local using
using @debug {trait Debug, type Repr}

///|
struct MatchResult(Array[Int]) derive(Debug)

///|
const NULL_SYMBOL : Rechar = -1

///|
fn category_from_symbol(
  profile~ : Profile,
  symbol_repr~ : ReadOnlyArray[Rechar],
  symbol : Rechar,
) -> Category {
  if symbol is NULL_SYMBOL {
    Category::inexistant()
  } else {
    (profile.category)(symbol_repr[symbol])
  }
}

///|
/// Access capture `group` information.
pub fn MatchResult::group(self : MatchResult, index : Int) -> (Int, Int)? {
  let start_pos = self.0.get(index * 2)
  guard start_pos is Some(start_pos) && start_pos >= 0 else { None }
  let end_pos = self.0[index * 2 + 1]
  guard end_pos >= 0 else { panic() }
  Some((start_pos, end_pos))
}

///|
/// Execute using this compiled object.
pub fn Regex::execute(
  self : Regex,
  input : StringView,
  last_index : Int,
) -> MatchResult? {
  guard last_index >= 0 && last_index <= input.length() else { panic() }
  let symbol_table = self.symbol_table
  let start_cat = if last_index == 0 {
    Category::inexistant()
  } else {
    let prev = input.unsafe_get(last_index - 1).to_int()
    let prev_symbol = symbol_table.map(prev)
    category_from_symbol(
      profile=self.profile,
      symbol_repr=self.symbol_repr,
      prev_symbol,
    )
  }
  let start_state_id = self.stablize_start_state(start_cat)
  let positions = Positions::new()
  let mut transition_table = self.transition_table
  let data = input.data()
  let mut pos = input.start_offset() + last_index
  let end = input.start_offset() + input.length()
  let mut state_id = start_state_id
  while pos < end {
    let ch = data.unsafe_get(pos).to_int()
    let symbol = symbol_table.map(ch)
    // INVARIANT: The start state is never a break state.
    // Empty character classes like `/[]/` are transformed during compilation:
    //   `/[]/`  -> `seq(shortest(char(any)), capture(empty))`
    //   `/^[]/` -> `capture(seq(start_of_input, empty))`
    // This ensures the executor can safely access state.transitions[symbol] without checking.
    let transition_index = state_id.transition_base() + symbol
    let prev_state_id = state_id
    state_id = transition_table.unsafe_get(transition_index)
    if state_id.is_pending() {
      state_id = self.stablize_next_state(prev_state_id, symbol)
      transition_table = self.transition_table
      transition_table[transition_index] = state_id
    }
    let slot = state_id.slot()
    // NOTE: we manually inline `Positions::set` here to avoid the overhead
    // of callee-owned RC (reference counting) operations.
    // Slot::unassigned() uses index 0, so writing it is harmless and keeps this path branchless.
    if slot.index >= positions.0.length() {
      positions.0.resize(slot.index + 8, -1)
    }
    positions.0[slot.index] = pos
    if state_id.is_break() {
      break
    }
    pos += 1
  }
  let state = self.get_state(state_id)
  let matched = match state.status() {
    Failed => None
    Running => {
      // Some states require checking the next character's category to determine
      // whether they match (e.g., for end-of-input anchors or boundary assertions)
      let (slot, status) = self.stablize_final(
        state_id,
        state,
        if pos >= end {
          NULL_SYMBOL
        } else {
          let ch = data.unsafe_get(pos).to_int()
          symbol_table.map(ch)
        },
      )
      match status {
        Failed | Running => None
        Match(marks) => {
          positions.set(slot, pos)
          Some(marks)
        }
      }
    }
    Match(marks) => Some(marks)
  }
  match matched {
    None => None
    Some(marks) => {
      let mark_pos = Array::make(self.groups.length() * 2, -1)
      let shift = input.start_offset()
      for mark, slot in marks {
        mark_pos[mark.0] = positions.get(slot) - shift
      }
      Some(MatchResult(mark_pos))
    }
  }
}
