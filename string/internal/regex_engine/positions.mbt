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
/// Scratch buffer holding, for every slot, the input offset recorded the last
/// time a state owning that slot was entered.
///
/// The buffer lives on the `Regex` and is reused across `execute` calls:
/// `execute` runs no caller code (the profile's `category` callback is the
/// only hook, and the profiles are fixed by this package's users), so it
/// cannot be re-entered, and every slot that a match result reads was
/// written during the same call.
priv struct Positions {
  mut buf : FixedArray[Int]
}

///|
fn Positions::new() -> Positions {
  { buf: FixedArray::make(8, -1), }
}

///|
/// Make sure `buf` can hold slot indices up to and including `max_slot`.
fn Positions::ensure(self : Positions, max_slot : Int) -> FixedArray[Int] {
  if max_slot >= self.buf.length() {
    let buf = FixedArray::make(
      Int::max(max_slot + 8, self.buf.length() * 2),
      -1,
    )
    self.buf.blit_to(buf, len=self.buf.length())
    self.buf = buf
  }
  self.buf
}

///|
fn Positions::set(self : Positions, slot : @automata.Slot, pos : Int) -> Unit {
  let buf = self.ensure(slot.index)
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
