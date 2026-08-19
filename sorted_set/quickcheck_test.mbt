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
test "quickcheck: difference matches the filter model" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (xs, ys) = input
    let a = @sorted_set.from_array(xs)
    let b = @sorted_set.from_array(ys)
    let d = a.difference(b)
    let expected = a.to_array().filter(x => !b.contains(x))
    d.to_array() == expected && d.length() == expected.length()
  })
}

///|
test "quickcheck: intersection matches the filter model" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (xs, ys) = input
    let a = @sorted_set.from_array(xs)
    let b = @sorted_set.from_array(ys)
    let i = a.intersection(b)
    let expected = a.to_array().filter(x => b.contains(x))
    i.to_array() == expected && i.length() == expected.length()
  })
}

///|
test "quickcheck: symmetric_difference matches the filter model" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (xs, ys) = input
    let a = @sorted_set.from_array(xs)
    let b = @sorted_set.from_array(ys)
    let s = a.symmetric_difference(b)
    let expected = a.to_array().filter(x => !b.contains(x))
    expected.append(b.to_array().filter(y => !a.contains(y)))
    expected.sort()
    s.to_array() == expected && s.length() == expected.length()
  })
}

///|
test "quickcheck: set algebra laws relate the operations" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (xs, ys) = input
    let a = @sorted_set.from_array(xs)
    let b = @sorted_set.from_array(ys)
    let a_minus_b = a.difference(b)
    let b_minus_a = b.difference(a)
    let both = a.intersection(b)
    let sym = a.symmetric_difference(b)
    a_minus_b.length() + both.length() == a.length() &&
    b_minus_a.length() + both.length() == b.length() &&
    sym.length() == a_minus_b.length() + b_minus_a.length() &&
    sym == a_minus_b.union(b_minus_a) &&
    a.union(b) == sym.union(both) &&
    a_minus_b.union(both) == a
  })
}

///|
test "quickcheck: operations with self and empty are identities" {
  @quickcheck.check((xs : Array[Int]) => {
    let a = @sorted_set.from_array(xs)
    let empty : @sorted_set.SortedSet[Int] = @sorted_set.from_array([])
    a.difference(a).is_empty() &&
    a.intersection(a) == a &&
    a.symmetric_difference(a).is_empty() &&
    a.difference(empty) == a &&
    empty.difference(a).is_empty() &&
    a.intersection(empty).is_empty() &&
    a.symmetric_difference(empty) == a &&
    empty.symmetric_difference(a) == a
  })
}

///|
test "quickcheck: results do not share nodes with the inputs" {
  @quickcheck.check((input : (Array[Int], Array[Int])) => {
    let (xs, ys) = input
    let a = @sorted_set.from_array(xs)
    let b = @sorted_set.from_array(ys)
    let a0 = a.to_array()
    let b0 = b.to_array()
    let d = a.difference(b)
    let i = a.intersection(b)
    let s = a.symmetric_difference(b)
    let d0 = d.to_array()
    let i0 = i.to_array()
    let s0 = s.to_array()
    // mutating the inputs must not disturb the results
    for y in ys {
      a.add(y)
    }
    for x in xs {
      b.remove(x)
    }
    guard d.to_array() == d0 && i.to_array() == i0 && s.to_array() == s0 else {
      return false
    }
    // mutating the results must not disturb (fresh copies of) the inputs
    let a2 = @sorted_set.from_array(xs)
    let b2 = @sorted_set.from_array(ys)
    for
      result in [
        a2.difference(b2),
        a2.intersection(b2),
        a2.symmetric_difference(b2),
      ] {
      for y in ys {
        result.add(y)
      }
      for x in xs {
        result.remove(x)
      }
    }
    a2.to_array() == a0 && b2.to_array() == b0
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
