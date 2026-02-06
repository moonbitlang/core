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
/// A mapping from marks to slots that tracks position markers during matching.
///
/// `MarkSlotMap` maintains the association between `Mark` identifiers (which mark
/// boundaries in the pattern) and `Slot` indices (where positions are stored).
/// Each execution thread carries its own MarkSlotMap to track which marks it has
/// encountered along its matching path.
///
/// # How It Works
///
/// 1. When a thread encounters a `Mark(mark)` expression during derivative computation,
///    the mark is added to the thread's MarkSlotMap with an unassigned slot
/// 2. When creating a new state, if a slot is available, all unassigned slots in
///    the state's threads are uniformly assigned to that slot via `assign_slot`
/// 3. During execution, when reaching a state with an assigned slot, the current
///    position is stored at that slot index in the `Positions` storage
/// 4. After matching completes, captured substrings are extracted using:
///    - MarkSlotMap: mark → slot (which slot stores this mark's position)
///    - Positions: slot → position value (what position is stored at this slot)
///
/// # Key Operations
///
/// - `add_mark`: Records that a mark was encountered (initially unassigned)
/// - `assign_slot`: Assigns a slot to all previously unassigned marks
/// - `get_slot`: Retrieves the slot associated with a mark
struct MarkSlotMap(@immut/sorted_map.SortedMap[Mark, Slot]) derive(Eq, Hash)

///|
fn MarkSlotMap::empty() -> MarkSlotMap {
  MarkSlotMap(@immut/sorted_map.SortedMap::new())
}

///|
fn MarkSlotMap::add_mark(self : MarkSlotMap, mark : Mark) -> MarkSlotMap {
  MarkSlotMap(self.0.add(mark, Slot::unassigned()))
}

///|
fn MarkSlotMap::assign_slot(self : MarkSlotMap, slot : Slot) -> MarkSlotMap {
  MarkSlotMap(
    self.0.map_with_key((_mark, prev_slot) => {
      if prev_slot.is_assigned() {
        prev_slot
      } else {
        slot
      }
    }),
  )
}

///|
pub fn MarkSlotMap::get_slot(self : MarkSlotMap, mark : Mark) -> Slot {
  match self.0.get(mark) {
    None => Slot::unassigned()
    Some(slot) => slot
  }
}

///|
pub fn MarkSlotMap::iter2(self : MarkSlotMap) -> Iter2[Mark, Slot] {
  self.0.iter2()
}
