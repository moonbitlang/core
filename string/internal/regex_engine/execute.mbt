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
/// NOTE: `derive(@debug.Debug)` is used here so this file doesn’t need a local `using @debug { ... }` import.

///|
struct MatchResult(Array[Int]) derive(@debug.Debug)

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
  // Validate before multiplying so large indices cannot wrap into a group.
  guard index >= 0 && index < self.0.length() / 2 else { None }
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
  let prev_cat = category_from_symbol(
    profile=self.profile,
    symbol_repr=self.symbol_repr,
    if last_index == 0 {
      NULL_SYMBOL
    } else {
      let ch = input.unsafe_get(last_index - 1).to_int()
      symbol_table.map(ch)
    },
  )
  let start_state_id = self.stablize_start_state(prev_cat)
  let positions = Positions::new()
  let mut buf = positions.buf
  let mut transition_table = self.transition_table
  let mut slot_table = self.slot_table
  let data = input.data()
  let mut pos = input.start_offset() + last_index
  let end = input.start_offset() + input.length()
  // INVARIANT: The start state is never a break state, so `base` is a valid
  // non-negative transition base on entry to the loop. Empty character classes
  // like `/[]/` are transformed during compilation:
  //   `/[]/`  -> `seq(shortest(char(any)), capture(empty))`
  //   `/^[]/` -> `capture(seq(start_of_input, empty))`
  let mut base = start_state_id.0
  let mut state_id = start_state_id
  while pos < end {
    let ch = data.unsafe_get(pos).to_int()
    let symbol = symbol_table.map(ch)
    let transition_index = base + symbol
    let mut next = transition_table.unsafe_get(transition_index)
    if next == -1 {
      let next_id = self.stablize_next_state(StateId(base), symbol)
      transition_table = self.transition_table
      slot_table = self.slot_table
      next = next_id.0
      transition_table[transition_index] = next
      slot_table[transition_index] = self.get_state(next_id).slot().index
    }
    let slot = slot_table.unsafe_get(transition_index)
    // `Positions::set` inlined by hand: the length check is the bounds check.
    // Slot::unassigned() is index 0, so writing it is harmless and keeps this
    // path branchless.
    if slot >= buf.length() {
      buf = positions.grow(slot)
    }
    buf.unsafe_set(slot, pos)
    if next < 0 {
      state_id = StateId(next)
      break
    }
    base = next
    pos += 1
  }
  if !state_id.is_break() {
    state_id = StateId(base)
  }
  let state = self.get_state(state_id)
  let matched = match state.status() {
    Failed => None
    Running => {
      let next_cat = category_from_symbol(
        profile=self.profile,
        symbol_repr=self.symbol_repr,
        if pos >= end {
          NULL_SYMBOL
        } else {
          let ch = data.unsafe_get(pos).to_int()
          symbol_table.map(ch)
        },
      )
      // Some states require checking the next character's category to determine
      // whether they match (e.g., for end-of-input anchors or boundary assertions)
      let (slot, status) = self.stablize_final(state_id, state, next_cat)
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
