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
test "compare: size first, then elements in ascending order" {
  let empty : @sorted_set.SortedSet[Int32] = SortedSet([])
  let small = @sorted_set.SortedSet([9])
  let big = @sorted_set.SortedSet([0, 1])
  // fewer elements is smaller, whatever the elements
  inspect(empty.compare(small), content="-1")
  inspect(small.compare(big), content="-1")
  inspect(big.compare(small), content="1")
  // same size: the first differing element decides
  let a = @sorted_set.SortedSet([1, 3])
  let b = @sorted_set.SortedSet([1, 2])
  inspect(a > b, content="true")
  inspect(b <= a, content="true")
  // insertion order is irrelevant
  inspect(a.compare(SortedSet([3, 1])), content="0")
  inspect(empty.compare(SortedSet([])), content="0")
}

///|
test "compare: matches @immut/sorted_set and agrees with ==" {
  // Every subset of {0, 1, 2, 3} (16 sets, 256 ordered pairs).
  let subsets : Array[Array[Int32]] = []
  for mask in 0..<16 {
    subsets.push([ for i in 0..<4 if (mask >> i) % 2 == 1 => i ])
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

  for xs in subsets {
    for ys in subsets {
      let s1 = @sorted_set.SortedSet(xs)
      let s2 = @sorted_set.SortedSet(ys)
      let expected = sign(
        @immut/sorted_set.SortedSet(xs).compare(SortedSet(ys)),
      )
      let actual = sign(s1.compare(s2))
      assert_eq(actual, expected)
      assert_eq(actual == 0, s1 == s2)
      assert_eq(actual, -sign(s2.compare(s1)))
    }
  }
}
