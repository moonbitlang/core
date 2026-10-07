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
/// Every bound kind over keys in `-1..=key_space`, so bounds fall below,
/// inside, between and above the stored keys.
fn all_bounds(key_space : Int) -> Array[@cmp.Bound[Int]] {
  let bounds : Array[@cmp.Bound[Int]] = [Unbounded]
  for k in -1..<=key_space {
    bounds.push(Included(k))
    bounds.push(Excluded(k))
  }
  bounds
}

///|
fn in_bounds(k : Int, lower : @cmp.Bound[Int], upper : @cmp.Bound[Int]) -> Bool {
  let above = match lower {
    Included(b) => k >= b
    Excluded(b) => k > b
    Unbounded => true
  }
  let below = match upper {
    Included(b) => k <= b
    Excluded(b) => k < b
    Unbounded => true
  }
  above && below
}

///|
fn check_bounds(map : SortedMap[Int, Int], key_space : Int) -> Unit raise {
  let sorted = map.to_array()
  let bounds = all_bounds(key_space)
  for lower in bounds {
    for upper in bounds {
      let expected = sorted.filter(p => in_bounds(p.0, lower, upper))
      @test.assert_eq(
        map.range_bounds(lower, upper).iter().to_array(),
        expected,
      )
      @test.assert_eq(
        map.rev_range_bounds(lower, upper).iter().to_array(),
        expected.rev(),
      )
    }
  }
}

///|
test "bounded ranges agree with a sorted-array model" {
  let rng = Rand::{ state: 0x5EED_1234UL, }
  for round in 0..<12 {
    let key_space = 4 + round * 3
    let map : SortedMap[Int, Int] = new_sorted_map()
    check_bounds(map, key_space)
    for _ in 0..<(key_space * 2) {
      let k = rng.below(key_space)
      if rng.below(4) == 0 {
        map.remove(k)
      } else {
        map.set(k, k * 10)
      }
      check_bounds(map, key_space)
    }
  }
}

///|
test "range iterators stop early and leave the tree intact" {
  let map : SortedMap[Int, Int] = new_sorted_map()
  for k in 0..<1000 {
    map.set(k, k)
  }
  let it = map.range_bounds(Excluded(10), Unbounded)
  @test.assert_eq(it.iter().take(3).to_array(), [(11, 11), (12, 12), (13, 13)])
  let rev = map.rev_range_bounds(Unbounded, Excluded(990))
  @test.assert_eq(rev.iter().take(2).to_array(), [(989, 989), (988, 988)])
  check_invariants(map)
  @test.assert_eq(map.length(), 1000)
}

///|
fn double_keys(it : Iter2[Double, Int]) -> Array[String] {
  it.iter().map(p => p.0.to_string()).to_array()
}

///|
test "range bounds follow Compare ordering for NaN keys" {
  // Double's relational operators are false for NaN, while `compare` (which
  // `range`, `get` and the nearest-key queries use) treats NaN as equal to
  // every value. Bounded ranges must follow `compare`, like `range` does.
  let nan = 0.0 / 0.0
  let map : SortedMap[Double, Int] = new_sorted_map()
  map.set(1.0, 1)
  map.set(nan, 2)
  map.set(-1.0, 3)
  for bounds in [(nan, nan), (-1.0, nan), (nan, 1.0), (-1.0, 1.0)] {
    let (low, high) = bounds
    let expected = double_keys(map.range(low, high))
    @test.assert_eq(
      double_keys(map.range_bounds(Included(low), Included(high))),
      expected,
    )
    @test.assert_eq(double_keys(map.rev_range(low, high)), expected.rev())
  }
}
