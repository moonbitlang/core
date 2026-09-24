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
struct SymbolMap(@sorted_set.SortedSet[@shared_types.Rechar])

///|
/// Create a new instance.
pub fn new() -> SymbolMap {
  SymbolMap(SortedSet([]))
}

///|
/// Function `split`.
pub fn SymbolMap::split(
  self : SymbolMap,
  set : @shared_types.RecharSet,
) -> Unit {
  for interval in set.intervals() {
    let (start, stop) = interval
    self.0.add(start)
    if stop + 1 > stop {
      self.0.add(stop + 1)
    }
  }
}

///|
/// Assign a symbol to every maximal run of code units in `[0, ub]` that no
/// split point separates, and build the lookup table for it.
///
/// Returns the table and, per symbol, a representative code unit (the lowest
/// one not below `lb`) used to classify the symbol.
pub fn SymbolMap::finalize(
  self : SymbolMap,
  lb : @shared_types.Rechar,
  ub : @shared_types.Rechar,
) -> (Table, ReadOnlyArray[@shared_types.Rechar]) {
  // Most cases lb is 0
  guard lb >= 0 else { panic() }
  let repr = []
  // Contiguous, ascending `(lo, hi, symbol)` runs covering `[0, ub]`.
  let runs : Array[(Int, Int, Int)] = []
  self.each_intervals(0, ub, (lo, hi) => {
    let symbol = repr.length()
    repr.push(Int::max(lo, lb))
    runs.push((lo, hi, symbol))
  })
  let nblocks = (ub >> 8) + 1
  let index = FixedArray::make(nblocks, 0)
  let blocks = []
  // Physical block shared by every uniform block of a given symbol.
  let uniform_base = Array::make(repr.length(), -1)
  let mut run = 0
  // Block 0 is emitted first, so it always starts at offset 0 (relied on by
  // the `Table::map` fast path).
  for b in 0..<nblocks {
    let start = b << 8
    let stop = Int::min(start + 255, ub)
    while runs[run].1 < start {
      run += 1
    }
    let (lo, hi, symbol) = runs[run]
    if lo <= start && hi >= stop {
      if uniform_base[symbol] < 0 {
        uniform_base[symbol] = blocks.length()
        for _ in 0..<256 {
          blocks.push(symbol)
        }
      }
      index[b] = uniform_base[symbol]
    } else {
      index[b] = blocks.length()
      let mut r = run
      for c in start..<=stop {
        while runs[r].1 < c {
          r += 1
        }
        blocks.push(runs[r].2)
      }
      // Keep every physical block exactly 256 entries long.
      for _ in (stop + 1)..<=(start + 255) {
        blocks.push(0)
      }
    }
  }
  (
    {
      index,
      blocks: FixedArray::from_array(blocks),
      ub,
      fast_limit: Int::min(256, ub + 1),
    },
    ReadOnlyArray::from_array(repr),
  )
}

///|
#locals(f)
fn SymbolMap::each_intervals(
  self : SymbolMap,
  lb : @shared_types.Rechar,
  ub : @shared_types.Rechar,
  f : (@shared_types.Rechar, @shared_types.Rechar) -> Unit,
) -> Unit {
  if self.0.is_empty() {
    f(lb, ub)
  } else {
    let last_stop = for stop in self.0; last_stop = lb {
      if stop > ub {
        break last_stop
      }
      if stop - 1 >= last_stop {
        f(last_stop, stop - 1)
        continue stop
      } else {
        continue last_stop
      }
    } nobreak {
      last_stop
    }
    if ub >= last_stop {
      f(last_stop, ub)
    }
  }
}
