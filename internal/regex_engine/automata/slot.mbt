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
/// A storage slot index used to store positions during pattern matching.
///
/// `Slot` is a newtype wrapper around `Int` that represents an index into the
/// `Positions` storage where actual positions (byte or character indices) are
/// recorded during automaton execution.
///
/// # Special Value
///
/// A slot value of -1 represents an "unassigned" slot, indicating that a slot
/// has not been assigned. This is checked via `is_assigned()`.
///
/// # How It Works
///
/// 1. Each state in the automaton is associated with a slot
/// 2. During execution, when reaching a state with an assigned slot, the current
///    position is stored at that slot index in the `Positions` storage
/// 3. After matching completes, captured substrings are extracted using
///    `MarkSlotMap` (mark → slot mapping) + `Positions` (slot → position values)
pub struct Slot(Int) derive(Eq, Hash)

///|
/// Returns the special unassigned slot value (-1).
///
/// Note: This is the only slot value that is considered "unassigned".
pub fn Slot::unassigned() -> Slot {
  Slot(-1)
}

///|
pub fn Slot::is_assigned(self : Slot) -> Bool {
  self.0 != -1
}
