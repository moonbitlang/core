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
test "compare: size first, then entries in key order" {
  let empty : @sorted_map.SortedMap[Int32, Int32] = SortedMap([])
  let small = @sorted_map.SortedMap([(9, 9)])
  let big = @sorted_map.SortedMap([(0, 0), (1, 0)])
  // fewer entries is smaller, whatever the keys
  inspect(empty.compare(small), content="-1")
  inspect(small.compare(big), content="-1")
  inspect(big.compare(small), content="1")
  // same size: the first differing key decides
  let a = @sorted_map.SortedMap([(1, 5), (3, 0)])
  let b = @sorted_map.SortedMap([(1, 5), (2, 9)])
  inspect(a > b, content="true")
  // same keys: the first differing value decides
  let c = @sorted_map.SortedMap([(1, 5), (3, 1)])
  inspect(a < c, content="true")
  // insertion order is irrelevant
  let a2 = @sorted_map.SortedMap([(3, 0), (1, 5)])
  inspect(a.compare(a2), content="0")
  inspect(empty.compare(SortedMap([])), content="0")
}

///|
test "compare: matches @immut/sorted_map and agrees with ==" {
  // Every map over keys {0, 1, 2} with values in {0, 1}: each key is absent,
  // bound to 0, or bound to 1 (27 maps, 729 ordered pairs).
  let entries : Array[Array[(Int32, Int32)]] = []
  for code in 0..<27 {
    let es = []
    let mut c = code
    for key in 0..<3 {
      match c % 3 {
        0 => ()
        v => es.push((key, v - 1))
      }
      c = c / 3
    }
    entries.push(es)
  }
  fn sign(x : Int32) -> Int32 {
    if x < 0 {
      -1
    } else if x > 0 {
      1
    } else {
      0
    }
  }

  for xs in entries {
    for ys in entries {
      let m1 = @sorted_map.SortedMap(xs)
      let m2 = @sorted_map.SortedMap(ys)
      let expected = sign(
        @immut/sorted_map.SortedMap(xs).compare(SortedMap(ys)),
      )
      let actual = sign(m1.compare(m2))
      assert_eq(actual, expected)
      assert_eq(actual == 0, m1 == m2)
      assert_eq(actual, -sign(m2.compare(m1)))
    }
  }
}
