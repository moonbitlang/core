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
  satisfies_lower(k, lower) && satisfies_upper(k, upper)
}

///|
/// Checks every navigation query against a sorted array of the map's
/// entries, over all keys and all bound combinations.
fn check_navigation(map : SortedMap[Int, Int], key_space : Int) -> Unit raise {
  let sorted = map.to_array()
  @test.assert_eq(map.first(), sorted.get(0))
  @test.assert_eq(map.last(), sorted.last())
  @test.assert_eq(map.rev_iter().to_array(), sorted.rev())
  @test.assert_eq(map.rev_keys().to_array(), sorted.rev().map(p => p.0))
  @test.assert_eq(map.rev_values().to_array(), sorted.rev().map(p => p.1))
  for k in -1..<=key_space {
    @test.assert_eq(map.first_ge(k), sorted.iter().find_first(p => p.0 >= k))
    @test.assert_eq(map.first_gt(k), sorted.iter().find_first(p => p.0 > k))
    @test.assert_eq(
      map.last_le(k),
      sorted.rev().iter().find_first(p => p.0 <= k),
    )
    @test.assert_eq(
      map.last_lt(k),
      sorted.rev().iter().find_first(p => p.0 < k),
    )
  }
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
test "navigation agrees with a sorted-array model" {
  let rng = Rand::{ state: 0x5EED_1234UL, }
  for round in 0..<12 {
    let key_space = 4 + round * 3
    let map : SortedMap[Int, Int] = new_sorted_map()
    check_navigation(map, key_space)
    for _ in 0..<(key_space * 2) {
      let k = rng.below(key_space)
      if rng.below(4) == 0 {
        map.remove(k)
      } else {
        map.set(k, k * 10)
      }
      check_navigation(map, key_space)
    }
  }
}

///|
test "pop_first and pop_last keep invariants and agree with the model" {
  let rng = Rand::{ state: 0xC0FFEEUL, }
  for _ in 0..<8 {
    let map : SortedMap[Int, Int] = new_sorted_map()
    let model : Map[Int, Int] = Map([])
    for _ in 0..<400 {
      let k = rng.below(200)
      match rng.below(6) {
        0 => {
          let expected = model
            .keys()
            .fold(init=None, (acc : Int?, k) => {
              match acc {
                Some(m) if m <= k => acc
                _ => Some(k)
              }
            })
          let popped = map.pop_first()
          @test.assert_eq(popped.map(p => p.0), expected)
          if expected is Some(m) {
            model.remove(m)
          }
        }
        1 => {
          let expected = model
            .keys()
            .fold(init=None, (acc : Int?, k) => {
              match acc {
                Some(m) if m >= k => acc
                _ => Some(k)
              }
            })
          let popped = map.pop_last()
          @test.assert_eq(popped.map(p => p.0), expected)
          if expected is Some(m) {
            model.remove(m)
          }
        }
        _ => {
          map.set(k, k)
          model[k] = k
        }
      }
      check_invariants(map)
      @test.assert_eq(map.length(), model.length())
    }
    while map.pop_first() is Some(_) {
      check_invariants(map)
    }
    @test.assert_eq(map.length(), 0)
    @test.assert_eq(map.pop_last(), None)
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
