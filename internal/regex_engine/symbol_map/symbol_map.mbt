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
pub fn new() -> SymbolMap {
  SymbolMap(@sorted_set.new())
}

///|
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
pub fn SymbolMap::finalize(
  self : SymbolMap,
  lb : @shared_types.Rechar,
  ub : @shared_types.Rechar,
) -> (&Table, ReadOnlyArray[@shared_types.Rechar]) {
  if ub - lb < 1024 {
    let (table, repr) = self.finalize_dense(lb, ub)
    (table as &Table, repr)
  } else {
    let (table, repr) = self.finalize_sparse(lb, ub)
    (table as &Table, repr)
  }
}

///|
fn SymbolMap::finalize_dense(
  self : SymbolMap,
  lb : @shared_types.Rechar,
  ub : @shared_types.Rechar,
) -> (DenseTable, ReadOnlyArray[@shared_types.Rechar]) {
  let repr = []
  let table = FixedArray::make(ub - lb + 1, 0)
  self.each_intervals(lb, ub, (lo, hi) => {
    let symbol = repr.length()
    repr.push(lo)
    for c in lo..<=hi {
      table[c] = symbol
    }
  })
  (DenseTable(table), ReadOnlyArray::from_array(repr))
}

///|
fn SymbolMap::finalize_sparse(
  self : SymbolMap,
  lb : @shared_types.Rechar,
  ub : @shared_types.Rechar,
) -> (SparseTable, ReadOnlyArray[@shared_types.Rechar]) {
  let repr = []
  let entries = []
  self.each_intervals(lb, ub, (lo, hi) => {
    let symbol = repr.length()
    repr.push(lo)
    entries.push({ lo, hi, symbol })
  })
  (
    SparseTable(ReadOnlyArray::from_array(entries)),
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
    let mut last_stop = lb
    for stop in self.0 {
      if stop - 1 >= last_stop {
        f(last_stop, stop - 1)
        last_stop = stop
      }
    }
    if ub >= last_stop {
      f(last_stop, ub)
    }
  }
}
