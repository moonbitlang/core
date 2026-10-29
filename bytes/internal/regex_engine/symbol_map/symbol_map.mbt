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
/// `starts[c]` is set when byte `c` begins a new symbol. Byte `0` begins
/// the first symbol whether or not its flag is set.
struct SymbolMap(FixedArray[Bool])

///|
/// A map in which every byte is one symbol until it is split.
pub fn new() -> SymbolMap {
  SymbolMap(FixedArray::make(256, false))
}

///|
/// Make sure that no symbol holds bytes both inside and outside `set`.
pub fn SymbolMap::split(self : SymbolMap, set : @shared_types.ByteSet) -> Unit {
  for interval in set.intervals() {
    let (start, stop) = interval
    self.0[start] = true
    if stop + 1 < 256 {
      self.0[stop + 1] = true
    }
  }
}

///|
/// Number the symbols in ascending byte order. Returns the table and, for
/// each symbol, the smallest byte it holds.
pub fn SymbolMap::finalize(self : SymbolMap) -> (Table, ReadOnlyArray[Int32]) {
  let repr = [0]
  let symbols = FixedArray::make(256, b'\x00')
  for c in 1..<256 {
    if self.0[c] {
      repr.push(c)
    }
    symbols[c] = (repr.length() - 1).to_byte()
  }
  (Table(Bytes::from_array(symbols)), ReadOnlyArray::from_array(repr))
}
