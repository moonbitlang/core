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
/// The symbol of every byte. A symbol is below 256, so it is stored as a
/// byte, and a byte is below 256, so every lookup is in bounds: mapping a
/// byte is one load, with neither the `fast_limit` branch nor the bounds
/// check of the string engine's two-level table.
struct Table(Bytes)

///|
/// The symbol of byte `b`.
pub fn Table::map(self : Table, b : Byte) -> Int32 {
  self.0.unsafe_get(b.to_int()).to_int()
}

///|
/// The symbols of the bytes in `set`. Assumes `set` was split in the map.
pub fn Table::map_set(
  self : Table,
  set : @shared_types.ByteSet,
) -> @shared_types.ByteSet {
  // Symbols are numbered in byte order, so a run of bytes is a run of
  // symbols.
  let mut out = @shared_types.ByteSet::empty()
  for interval in set.intervals() {
    let (lo, hi) = interval
    out = out +
      @shared_types.ByteSet::char_range(
        self.0[lo].to_int(),
        self.0[hi].to_int(),
      )
  }
  out
}
