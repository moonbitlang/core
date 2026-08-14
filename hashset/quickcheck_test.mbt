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
fn normalized(xs : Array[Int]) -> Array[Int] {
  let result : Array[Int] = []
  for x in xs {
    let x = x % 47
    if !result.contains(x) {
      result.push(x)
    }
  }
  result.sort()
  result
}

///|
test "quickcheck: construction and mutation preserve set semantics" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (inserted, removed) = input
    let set : @hashset.HashSet[Int] = HashSet([])
    for x in inserted {
      set.add(x % 47)
    }
    for x in removed {
      set.remove(x % 47)
    }
    let removed = normalized(removed)
    let expected = normalized(inserted)
    expected.retain(x => !removed.contains(x))
    let actual = set.to_array()
    actual.sort()
    actual == expected && set.length() == expected.length()
  })
}

///|
test "quickcheck: union, intersection, and difference obey membership laws" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (xs, ys) = input
    let a = @hashset.from_array(xs.map(x => x % 47))
    let b = @hashset.from_array(ys.map(x => x % 47))
    let union = a.union(b)
    let intersection = a.intersection(b)
    let difference = a.difference(b)
    for x in -46..<47 {
      if union.contains(x) != (a.contains(x) || b.contains(x)) ||
        intersection.contains(x) != (a.contains(x) && b.contains(x)) ||
        difference.contains(x) != (a.contains(x) && !b.contains(x)) {
        return false
      }
    }
    true
  })
}
