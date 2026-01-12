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
struct MatchResult(Array[Int])

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
pub fn MatchResult::group(self : MatchResult, index : Int) -> (Int, Int)? {
  let start_pos = self.0.get(index * 2)
  guard start_pos is Some(start_pos) && start_pos >= 0 else { None }
  let end_pos = self.0[index * 2 + 1]
  guard end_pos >= 0 else { panic() }
  Some((start_pos, end_pos))
}

///|
fn Regex::find_start_state(self : Regex, cat : Category) -> State {
  for i in 0..<self.start_states.length() {
    let (cat2, state) = self.start_states[i]
    if cat2 == cat {
      return state
    }
  }
  let state = find_state(
    self.state_table,
    self.symbol_repr.length(),
    @automata.State::start(cat, self.expr),
  )
  self.start_states.push((cat, state))
  state
}

///|
pub fn[T : Input] Regex::execute(
  self : Regex,
  input : T,
  lastIndex : Int,
) -> MatchResult? {
  guard lastIndex >= 0 && lastIndex <= input.length() else { panic() }
  let mut pos = lastIndex
  let end = input.length()
  let start_cat = if pos == 0 {
    Category::inexistant()
  } else {
    let prev = input.get(pos - 1)
    let prev_symbol = self.symbol_table.map(prev)
    category_from_symbol(
      profile=self.profile,
      symbol_repr=self.symbol_repr,
      prev_symbol,
    )
  }
  let start_state = self.find_start_state(start_cat)
  let positions = Positions::new()
  let mut state = start_state
  while pos < end {
    let ch = input.get(pos)
    let symbol = self.symbol_table.map(ch)
    // INVARIANT: The start state is never a break state.
    // Empty character classes like `/[]/` are transformed during compilation:
    //   `/[]/`  -> `seq(shortest(char(any)), capture(empty))`
    //   `/^[]/` -> `capture(seq(start_of_input, empty))`
    // This ensures the executor can safely access state.transitions[symbol] without checking.
    let next_state = state.transitions[symbol]
    state = if next_state.kind is Pending {
      let cat = category_from_symbol(
        profile=self.profile,
        symbol_repr=self.symbol_repr,
        symbol,
      )
      let next_desc = @automata.delta(
        ctx=self.ctx,
        state.desc,
        symbol,
        next_cat=cat,
      )
      let next_state = find_state(
        self.state_table,
        self.symbol_repr.length(),
        next_desc,
      )
      state.transitions[symbol] = next_state
      next_state
    } else {
      next_state
    }
    let slot = state.desc.slot()
    if slot.is_assigned() {
      positions.set(slot, pos)
    }
    if state.kind is Break {
      break
    }
    pos += 1
  }
  let matched = match state.desc.status() {
    Failed => None
    Running => {
      // Some states require checking the next character's category to determine
      // whether they match (e.g., for end-of-input anchors or boundary assertions)
      let final_cat = if pos == end {
        Category::inexistant()
      } else {
        let ch = input.get(pos)
        let symbol = self.symbol_table.map(ch)
        category_from_symbol(
          profile=self.profile,
          symbol_repr=self.symbol_repr,
          symbol,
        )
      }
      let (slot, status) = loop state.final_ {
        Empty => {
          let next_desc = @automata.delta(
            ctx=self.ctx,
            state.desc,
            NULL_SYMBOL,
            next_cat=final_cat,
          )
          let slot = next_desc.slot()
          let status = next_desc.status()
          state.final_ = @list.cons((final_cat, slot, status), state.final_)
          (slot, status)
        }
        More(head, tail~) =>
          if head.0 == final_cat {
            (head.1, head.2)
          } else {
            continue tail
          }
      }
      match status {
        Failed | Running => None
        Match(marks) => {
          if slot.is_assigned() {
            positions.set(slot, pos)
          }
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
      for mark, slot in marks {
        mark_pos[mark.0] = positions.get(slot)
      }
      Some(MatchResult(mark_pos))
    }
  }
}
