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
struct SymbolMap(@sorted_set.SortedSet[Rechar])

///|
/// Create a new instance.
pub fn new() -> SymbolMap {
  SymbolMap(@sorted_set.new())
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
/// Function `finalize`.
pub fn SymbolMap::finalize(
  self : SymbolMap,
  lb : @shared_types.Rechar,
  ub : @shared_types.Rechar,
) -> (Table, ReadOnlyArray[@shared_types.Rechar]) {
  // Most cases lb is 0
  guard lb >= 0 else { panic() }
  let repr = []
  let table = Array::make(128, -1)
  if ub < 128 {
    self.each_intervals(0, ub, (lo, hi) => {
      let symbol = repr.length()
      repr.push(lo)
      for c in lo..<=hi {
        table[c] = symbol
      }
    })
  } else {
    self.each_intervals(0, 127, (lo, hi) => {
      let symbol = repr.length()
      repr.push(lo)
      for c in lo..<=hi {
        table[c] = symbol
      }
    })
    self.each_intervals(128, ub, (lo, hi) => {
      let symbol = repr.length()
      repr.push(lo)
      // (lo, hi, symbol)
      table.push(lo)
      table.push(hi)
      table.push(symbol)
    })
  }
  (Table(FixedArray::from_array(table)), ReadOnlyArray::from_array(repr))
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
