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
/// Maps input code units to symbols through a two-level table.
///
/// `index` has one entry per 256-code-unit block and holds the offset of that
/// block's 256 symbols inside `blocks`. Blocks whose 256 code units all map to
/// the same symbol (the vast majority) share one physical block, so the table
/// stays small while every lookup is two dependent loads with no search.
struct Table {
  index : FixedArray[@shared_types.Rechar]
  blocks : FixedArray[@shared_types.Rechar]
  /// Largest code unit the table was built for; `map` panics above it.
  ub : @shared_types.Rechar
  /// `min(256, ub + 1)`: code units below it are served by block 0 alone.
  fast_limit : @shared_types.Rechar
}

///|
/// Map a single `Rechar` through the symbol table.
///
/// Panics when `c` lies above the `ub` the table was built for; `c` must not
/// be negative.
pub fn Table::map(
  self : Table,
  c : @shared_types.Rechar,
) -> @shared_types.Rechar {
  if c < self.fast_limit {
    // Block 0 is always the first physical block, so Latin-1 (and in
    // particular ASCII) input needs a single load.
    self.blocks.unsafe_get(c)
  } else {
    guard c <= self.ub else { panic() }
    self.blocks.unsafe_get(self.index.unsafe_get(c >> 8) + (c & 0xFF))
  }
}

///|
/// Apply `Table::map` to every `Rechar` in the input set.
pub fn Table::map_set(
  self : Table,
  set : @shared_types.RecharSet,
) -> @shared_types.RecharSet {
  set.offset_by(c => self.map(c))
}
