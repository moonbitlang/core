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
fn pairs(m : MarkSlotMap) -> Array[(Int, Int)] {
  let out = []
  for mark, slot in m {
    out.push((mark.0, slot.index))
  }
  out
}

///|
test "record, assign, overwrite, lookup" {
  let m0 = MarkSlotMap::empty()
  assert_true(pairs(m0) == [])
  assert_true(!m0.has_unassigned)
  assert_true(m0.get_slot(Mark(0)) == Slot::unassigned())
  let m1 = m0.add_mark(Mark(2))
  assert_true(pairs(m1) == [(2, 0)])
  assert_true(m1.has_unassigned)
  assert_true(m1.slots.length() == 3)
  let m2 = m1.assign_slot(Slot::from_index(5))
  assert_true(pairs(m2) == [(2, 5)])
  assert_true(!m2.has_unassigned)
  assert_true(m2.get_slot(Mark(2)) == Slot::from_index(5))
  assert_true(m2.get_slot(Mark(1)) == Slot::unassigned())
  assert_true(m2.get_slot(Mark(99)) == Slot::unassigned())
  // a new mark below an existing one keeps the length; assign only touches
  // unassigned entries
  let m3 = m2.add_mark(Mark(0)).assign_slot(Slot::from_index(7))
  assert_true(pairs(m3) == [(0, 7), (2, 5)])
  // re-recording an assigned mark makes it unassigned again
  let m4 = m3.add_mark(Mark(2))
  assert_true(pairs(m4) == [(0, 7), (2, 0)])
  assert_true(m4.has_unassigned)
  assert_true(pairs(m4.assign_slot(Slot::from_index(9))) == [(0, 7), (2, 9)])
  // assign_slot with nothing to assign returns the same content
  assert_true(m3.assign_slot(Slot::from_index(1)) == m3)
}

///|
test "equality and hashing depend on content only" {
  let a = MarkSlotMap::empty()
    .add_mark(Mark(1))
    .assign_slot(Slot::from_index(3))
  let b = MarkSlotMap::empty()
    .add_mark(Mark(1))
    .add_mark(Mark(1))
    .assign_slot(Slot::from_index(3))
  assert_true(a == b)
  assert_true(a.hash() == b.hash())
  let c = a.add_mark(Mark(0)).assign_slot(Slot::from_index(3))
  assert_true(a != c)
  let d = MarkSlotMap::empty()
    .add_mark(Mark(1))
    .assign_slot(Slot::from_index(4))
  assert_true(a != d)
}
