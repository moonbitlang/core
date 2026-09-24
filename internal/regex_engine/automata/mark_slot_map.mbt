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
///
/// Indexed by mark. `Slot::absent()` means the mark was never recorded,
/// `Slot::unassigned()` means it was recorded but has no slot yet, and an
/// assigned `Slot` stores the mark's position.
/// The separate absent state is required because optional capture groups can
/// leave holes between the smallest and largest recorded mark.
struct MarkSlotMap {
  slots : FixedArray[Slot]
  /// True when some recorded mark still holds `Slot::unassigned()`; lets
  /// `assign_slot` skip the copy for the (common) threads that recorded no
  /// new mark in the current step.
  has_unassigned : Bool
} derive(Eq, Hash)

///|
fn MarkSlotMap::empty() -> MarkSlotMap {
  { slots: [], has_unassigned: false, }
}

///|
/// Record `mark` at the current position (overwriting an earlier record of
/// the same mark, as a later iteration of a group does).
fn MarkSlotMap::add_mark(self : MarkSlotMap, mark : Mark) -> MarkSlotMap {
  let n = Int::max(self.slots.length(), mark.0 + 1)
  let slots = FixedArray::make_and_blit(
    self.slots,
    allocate_len=n,
    init=Slot::absent(),
    len=self.slots.length(),
  )
  slots[mark.0] = Slot::unassigned()
  { slots, has_unassigned: true, }
}

///|
fn MarkSlotMap::assign_slot(self : MarkSlotMap, slot : Slot) -> MarkSlotMap {
  // `Slot::unassigned()` encodes "unassigned", so assigning slot 0 would
  // silently leave the map unassigned; `find_slot` never hands out index 0.
  guard slot.is_assigned() else { panic() }
  if !self.has_unassigned {
    self
  } else {
    let slots = self.slots.copy()
    for i, s in slots {
      if s == Slot::unassigned() {
        slots[i] = slot
      }
    }
    { slots, has_unassigned: false, }
  }
}

///|
/// Function `get_slot`.
pub fn MarkSlotMap::get_slot(self : MarkSlotMap, mark : Mark) -> Slot {
  if mark.0 >= 0 && mark.0 < self.slots.length() {
    let slot = self.slots[mark.0]
    if slot.is_absent() {
      Slot::unassigned()
    } else {
      slot
    }
  } else {
    Slot::unassigned()
  }
}

///|
/// Return an iterator via `iter2`.
pub fn MarkSlotMap::iter2(self : MarkSlotMap) -> Iter2[Mark, Slot] {
  let mut i = 0
  Iter2::new(() => {
    while i < self.slots.length() {
      let s = self.slots[i]
      i += 1
      if !s.is_absent() {
        return Some((Mark(i - 1), s))
      }
    }
    None
  })
}
