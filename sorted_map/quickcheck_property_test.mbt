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
test "quickcheck: iteration is ordered and round-trips map contents" {
  @quickcheck.check((entries : Array[(Int, Int)]) => {
    let map = @sorted_map.from_array(entries)
    let actual = map.to_array()
    for i in 1..<actual.length() {
      if actual[i - 1].0 >= actual[i].0 {
        return false
      }
    }
    @sorted_map.from_array(actual) == map
  })
}

///|
test "quickcheck: nearest-key queries match a linear scan" {
  @quickcheck.check((input : (Array[(Int, Int)], Int)) => {
    let (entries, key) = input
    let map = @sorted_map.from_array(entries)
    let sorted = map.to_array()
    let rev = sorted.rev()
    map.first_ge(key) == sorted.iter().find_first(p => p.0 >= key) &&
    map.first_gt(key) == sorted.iter().find_first(p => p.0 > key) &&
    map.last_le(key) == rev.iter().find_first(p => p.0 <= key) &&
    map.last_lt(key) == rev.iter().find_first(p => p.0 < key) &&
    map.first() == sorted.get(0) &&
    map.last() == sorted.last()
  })
}
