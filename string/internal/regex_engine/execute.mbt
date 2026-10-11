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
/// Capture offsets of a successful match: `[start0, end0, start1, end1, ...]`
/// relative to the searched view, `-1` for groups that did not participate.
struct MatchResult(Array[Int]) derive(@debug.Debug)

///|
/// The `(start, end)` offsets of capture group `index`, or `None` when the
/// index is out of range or the group did not participate in the match.
pub fn MatchResult::group(self : MatchResult, index : Int) -> (Int, Int)? {
  // Validate before multiplying so large indices cannot wrap into a group.
  guard index >= 0 && index < self.0.length() / 2 else { None }
  let start = self.0[index * 2]
  let end = self.0[index * 2 + 1]
  guard start >= 0 && end >= 0 else { None }
  Some((start, end))
}

///|
/// Search `input` for the leftmost-first match starting at or after
/// `last_index`.
pub fn Regex::execute(
  self : Regex,
  input : StringView,
  last_index : Int,
) -> MatchResult? {
  guard last_index >= 0 && last_index <= input.length() else { panic() }
  let table = self.table
  let data = input.data()
  let shift = input.start_offset()
  let end = shift + input.length()
  let ctx = if last_index == 0 {
    self.ctx_start
  } else {
    self.sym_ctx[table.map(input.unsafe_get(last_index - 1).to_int())]
  }
  let mut base = self.start_base(ctx)
  let mut trans = self.trans
  let mut slots = self.slots
  let mut regs = self.regs
  let mut pos = shift + last_index
  // A negative `stop` is the table entry that ended the scan.
  let mut stop = 0
  while pos < end {
    let index = base + table.map(data.unsafe_get(pos).to_int())
    let mut next = trans.unsafe_get(index)
    if next < 0 {
      // Off the fast path: an unbuilt transition, or the end of the scan.
      if next == UNKNOWN {
        next = self.build(base, index - base, pos)
        trans = self.trans
        slots = self.slots
        regs = self.regs
        regs.unsafe_set(self.built_slot, pos)
        if next >= 0 {
          base = next
          pos += 1
          continue
        }
      } else {
        regs.unsafe_set(slots.unsafe_get(index), pos)
        if is_moving(next) {
          next = self.follow(next)
          if next >= 0 {
            base = next
            pos += 1
            continue
          }
        }
      }
      stop = next
      break
    }
    regs.unsafe_set(slots.unsafe_get(index), pos)
    base = next
    pos += 1
  }
  if stop == 0 {
    let index = base + self.nsym
    stop = trans.unsafe_get(index)
    if stop == UNKNOWN {
      stop = self.build(base, self.nsym, pos)
      regs = self.regs
      regs.unsafe_set(self.built_slot, pos)
    } else {
      regs.unsafe_set(slots.unsafe_get(index), pos)
      if is_moving(stop) {
        stop = self.follow(stop)
      }
    }
  }
  guard stop != DEAD else { None }
  // A terminal state has no threads, only the row of the match: its length
  // and then `(tag, register)` pairs.
  let key = self.kernels[terminal_state(stop)].key
  let result = Array::make(self.ntags, -1)
  for i in 0..<key[2] {
    result[key[3 + 2 * i]] = regs[key[4 + 2 * i]] - shift
  }
  Some(MatchResult(result))
}
