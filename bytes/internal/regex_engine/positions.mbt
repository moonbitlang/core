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
priv struct Positions(Array[Int])

///|
fn Positions::new() -> Positions {
  Positions(Array::make(8, -1))
}

///|
#alias("_[_]=_")
fn Positions::set(self : Positions, slot : @automata.Slot, pos : Int) -> Unit {
  // Slot::unassigned() uses index 0, so writing it is harmless and keeps this path branchless.
  if slot.index >= self.0.length() {
    self.0.resize(slot.index + 8, -1)
  }
  self.0[slot.index] = pos
}

///|
#alias("_[_]")
fn Positions::get(self : Positions, slot : @automata.Slot) -> Int {
  debug_assert(() => slot.is_assigned())
  if slot.index >= self.0.length() {
    -1
  } else {
    self.0[slot.index]
  }
}
