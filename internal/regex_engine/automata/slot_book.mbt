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
/// A bitmap-based allocator for tracking slot usage during automaton execution.
///
/// `SlotBook` efficiently tracks which slots are currently in use by maintaining
/// a bitmap where each bit represents one slot's availability (0 = free, 1 = used).
///
/// # Purpose
///
/// During derivative computation in the automaton, we need to assign unassigned
/// marks to slots. The SlotBook helps find available slots efficiently to avoid
/// conflicts with slots already in use by the current thread set.
///
/// # Implementation Details
///
/// - Uses a `FixedArray[Int]` as a bitmap (32 slots per integer)
/// - Initial capacity: 128 slots (4 integers)
/// - Grows by powers of 2 when more slots are needed
/// - Uses bitwise operations and count-trailing-zeros for efficient slot finding
priv struct SlotBook(FixedArray[Int])

///|
fn SlotBook::empty() -> SlotBook {
  SlotBook(FixedArray::make(4, 0))
}

///|
fn SlotBook::mark_used(self : SlotBook, slot : Slot) -> Unit {
  guard slot.is_assigned() else { () }
  let index = slot.0 / 32
  let bit = slot.0 % 32
  self.0[index] = self.0[index] | (1 << bit)
}

///|
fn SlotBook::find_unused(self : SlotBook) -> Slot {
  for i = 0; i < self.0.length(); i = i + 1 {
    if self.0[i] != -1 {
      let bit = self.0[i].lnot().ctz()
      return Slot(i * 32 + bit)
    }
  }
  Slot(self.0.length() * 32)
}

///|
fn SlotBook::clear(self : SlotBook) -> Unit {
  self.0.fill(0)
}

///|
fn next_pow_of_two(n : Int) -> Int {
  if n <= 1 {
    1
  } else {
    guard n <= 0x40000000 else { panic() }
    1 << (32 - (n - 1).clz())
  }
}

///|
fn SlotBook::need_grow(self : SlotBook, slot : Slot) -> Bool {
  slot.0 >= 32 * self.0.length()
}

///|
fn SlotBook::grow(self : SlotBook) -> SlotBook {
  SlotBook(FixedArray::make(next_pow_of_two(self.0.length() + 1), 0))
}
