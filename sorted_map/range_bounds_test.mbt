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
fn bound_of(kind : Int, key : Int) -> @cmp.Bound[Int] {
  match kind.abs() % 3 {
    0 => Included(key)
    1 => Excluded(key)
    _ => Unbounded
  }
}

///|
test "quickcheck: range_bounds matches filtering the sorted entries" {
  @quickcheck.check((input : (Array[(Int, Int)], (Int, Int), (Int, Int))) => {
    let (entries, (lk, lo), (hk, hi)) = input
    let map = @sorted_map.from_array(entries)
    let lower = bound_of(lk, lo)
    let upper = bound_of(hk, hi)
    let expected = map
      .to_array()
      .filter(p => {
        let above = match lower {
          Included(b) => p.0 >= b
          Excluded(b) => p.0 > b
          Unbounded => true
        }
        let below = match upper {
          Included(b) => p.0 <= b
          Excluded(b) => p.0 < b
          Unbounded => true
        }
        above && below
      })
    map.range_bounds(lower, upper).iter().to_array() == expected &&
    map.rev_range_bounds(lower, upper).iter().to_array() == expected.rev()
  })
}
