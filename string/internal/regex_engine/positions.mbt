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
/// For every slot, the input offset recorded the last time a state owning
/// that slot was entered.
priv struct Positions {
  mut buf : FixedArray[Int]
}

///|
fn Positions::new() -> Positions {
  { buf: FixedArray::make(8, -1), }
}

///|
/// Grow `buf` so that `slot` is in range and return it.
fn Positions::grow(self : Positions, slot : Int) -> FixedArray[Int] {
  let buf = FixedArray::make(Int::max(slot + 8, self.buf.length() * 2), -1)
  self.buf.blit_to(buf, len=self.buf.length())
  self.buf = buf
  buf
}

///|
fn Positions::set(self : Positions, slot : @automata.Slot, pos : Int) -> Unit {
  let buf = if slot.index >= self.buf.length() {
    self.grow(slot.index)
  } else {
    self.buf
  }
  buf[slot.index] = pos
}

///|
fn Positions::get(self : Positions, slot : @automata.Slot) -> Int {
  if slot.index >= self.buf.length() {
    -1
  } else {
    self.buf[slot.index]
  }
}
