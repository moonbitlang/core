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
/// Capture endpoints relative to the matched StringView, independent of the
/// mutable register buffer owned by the compiled regex.
struct MatchResult(Array[Int]) derive(@debug.Debug)

///|
/// Access capture `group` information.
pub fn MatchResult::group(self : MatchResult, index : Int) -> (Int, Int)? {
  guard index >= 0 && index < self.0.length() / 2 else { None }
  let start_pos = self.0.get(index * 2)
  guard start_pos is Some(start_pos) && start_pos >= 0 else { None }
  let end_pos = self.0[index * 2 + 1]
  guard end_pos >= 0 else { panic() }
  Some((start_pos, end_pos))
}

///|
fn Regex::ensure_registers(self : Regex) -> Unit {
  let required = self.max_registers + 1
  if required > self.registers.length() {
    let size = Int::max(self.registers.length() * 2, required + 8)
    let registers = FixedArray::make(size, -1)
    self.registers.blit_to(registers, len=self.registers.length())
    self.registers = registers
  }
}

///|
/// Executes this compiled regex and returns the first match from `last_index`.
pub fn Regex::execute(
  self : Regex,
  input : StringView,
  last_index : Int,
) -> MatchResult? {
  guard last_index >= 0 && last_index <= input.length() else { panic() }
  let prev = if last_index == 0 {
    Category::inexistant()
  } else {
    self.categories[self.symbols.map(input.unsafe_get(last_index - 1).to_int())]
  }
  let mut state = self.start_state(prev)
  let mut next = self.next
  let mut actions = self.actions
  let mut registers = self.registers
  let data = input.data()
  let mut pos = input.start_offset() + last_index
  let end = input.start_offset() + input.length()
  while state >= 0 {
    let symbol = if pos < end {
      self.symbols.map(data.unsafe_get(pos).to_int())
    } else {
      self.repr.length()
    }
    let edge = state + symbol
    let mut target = next.unsafe_get(edge)
    if target == -1 {
      self.build_edge(state, symbol)
      self.ensure_registers()
      next = self.next
      actions = self.actions
      registers = self.registers
      target = next.unsafe_get(edge)
    }
    // The transition action is either zero (no tag writes) or a register
    // index containing the current input cursor.
    registers.unsafe_set(actions.unsafe_get(edge), pos)
    state = target
    if state < 0 {
      break
    }
    // EOF closure cannot leave a character-consuming thread alive.
    guard pos < end else { panic() }
    pos += 1
  }
  let key = self.states[-state - 2]
  if key.threads.is_empty() {
    None
  } else {
    let shift = input.start_offset()
    let tags = key.threads[0].tags
    let result = Array::make(tags.length(), -1)
    for i = 0; i < tags.length(); i = i + 1 {
      let reg = tags[i]
      if reg >= 0 {
        result[i] = registers[reg + 1] - shift
      }
    }
    Some(MatchResult(result))
  }
}
