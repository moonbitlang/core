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
fn[K, V] filter_preorder(map : SortedMap[K, V], keys : Array[K]) -> Unit {
  match map {
    Empty => ()
    Tree(key, left, right, ..) => {
      keys.push(key)
      filter_preorder(left, keys)
      filter_preorder(right, keys)
    }
  }
}

///|
// An internal sharing regression; this does not add a public identity contract.
test "filter reuses a fully retained tree" {
  let map = SortedMap(Array::makei(31, i => (i, i)))
  let result = map.filter((_, _) => true)
  @test.assert_eq(physical_equal(map, result), true)
}

///|
test "filter preserves predicate order and size balance" {
  for size in [0, 1, 2, 3, 31, 32, 33, 127, 1024] {
    let map = SortedMap(Array::makei(size, i => (i, i)))
    let expected_order = []
    filter_preorder(map, expected_order)
    for modulus in [1, 2, 3, 100] {
      let actual_order = []
      let result = map.filter((key, _) => {
        actual_order.push(key)
        key % modulus != 0
      })
      @test.assert_eq(
        result.to_array(),
        map.to_array().filter(entry => entry.0 % modulus != 0),
      )
      @test.assert_eq(actual_order, expected_order)
      @test.assert_eq(is_valid(result), true)
    }
  }
}

///|
test "filter preserves exception order and the input" {
  let map = SortedMap(Array::makei(31, i => (i, i)))
  let entries = map.to_array()
  let order = []
  filter_preorder(map, order)
  for stop in [15, 7, 0, 10, 30] {
    let expected_order = []
    for key in order {
      expected_order.push(key)
      if key == stop {
        break
      }
    }
    let actual_order = []
    let message = try {
      let _ = map.filter((key, _) => {
        actual_order.push(key)
        if key == stop {
          raise Failure("stop")
        }
        key % 2 == 0
      })
      "no exception"
    } catch {
      Failure(message) => message
    }
    @test.assert_eq(message, "stop")
    @test.assert_eq(actual_order, expected_order)
    @test.assert_eq(map.to_array(), entries)
  }
}

///|
test "filter shares a retained branch beside a removed entry" {
  let map = SortedMap(Array::makei(31, i => (i, i)))
  guard map is Tree(_, left, _, ..) else { fail("expected tree") }
  let filtered = map.filter((key, _) => key != 30)
  guard filtered is Tree(_, kept_left, _, ..) else { fail("expected tree") }
  @test.assert_eq(physical_equal(left, kept_left), true)
  @test.assert_eq(is_valid(filtered), true)
}
