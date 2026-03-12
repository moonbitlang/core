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
#valtype
priv struct SparseTableEntry {
  lo : @shared_types.Rechar
  hi : @shared_types.Rechar
  symbol : @shared_types.Rechar
}

///|
priv struct SparseTable(ReadOnlyArray[SparseTableEntry])

///|
impl Table for SparseTable with map(self, c) {
  let arr = self.0
  let mut left = 0
  let mut right = arr.length() - 1
  while left <= right {
    let mid = left + (right - left) / 2
    let entry = arr[mid]
    if c < entry.lo {
      right = mid - 1
    } else if c > entry.hi {
      left = mid + 1
    } else {
      // c is within [lo, hi]
      return entry.symbol
    }
  }
  panic()
}
