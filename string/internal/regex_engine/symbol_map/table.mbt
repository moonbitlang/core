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
struct Table(FixedArray[Rechar])

///|
pub fn Table::map(self : Table, c : Rechar) -> Rechar {
  if c < 128 {
    self.0.unsafe_get(c)
  } else {
    let arr = self.0
    let mut left = 0
    let mut right = (arr.length() - 128) / 3 - 1
    while left <= right {
      let mid = left + (right - left) / 2
      let entry_base = 128 + mid * 3
      if c < arr[entry_base] {
        right = mid - 1
      } else if c > arr[entry_base + 1] {
        left = mid + 1
      } else {
        // c is within [lo, hi]
        return arr[entry_base + 2]
      }
    }
    panic()
  }
}

///|
pub fn Table::map_set(self : Table, set : RecharSet) -> RecharSet {
  set.offset_by(c => self.map(c))
}
