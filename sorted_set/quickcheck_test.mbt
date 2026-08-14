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
test "quickcheck: iteration is sorted and duplicate-free" {
  @quickcheck.check((xs : Array[Int]) => {
    let set = @sorted_set.from_array(xs)
    let actual = set.to_array()
    for i in 1..<actual.length() {
      if actual[i - 1] >= actual[i] {
        return false
      }
    }
    @sorted_set.from_array(actual) == set
  })
}

///|
test "quickcheck: set operations obey membership laws" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (xs, ys) = input
    let a = @sorted_set.from_array(xs)
    let b = @sorted_set.from_array(ys)
    let union = a.union(b)
    let intersection = a.intersection(b)
    let difference = a.difference(b)
    for x in xs {
      if !union.contains(x) ||
        intersection.contains(x) != b.contains(x) ||
        difference.contains(x) == b.contains(x) {
        return false
      }
    }
    for y in ys {
      if !union.contains(y) || difference.contains(y) {
        return false
      }
    }
    true
  })
}
