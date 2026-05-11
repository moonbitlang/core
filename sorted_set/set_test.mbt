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
test "remove on empty set" {
  let set : @sorted_set.SortedSet[Int] = @sorted_set.SortedSet([])
  set.remove(0)
  inspect(set.length(), content="0")
}

///|
test "default" {
  let set : @sorted_set.SortedSet[Int] = Default::default()
  inspect(set.length(), content="0")
}

///|
test "SortedSet constructor" {
  let set = @sorted_set.SortedSet([3, 1, 2])
  assert_eq(set.to_array(), [1, 2, 3])
}

///|
test "arbitrary samples" {
  let samples = (@quickcheck.samples(3) : Array[@sorted_set.SortedSet[Int]])
  inspect(samples.length(), content="3")
}

///|
test "disjoint" {
  inspect(
    @sorted_set.from_array([1, 2, 3]).disjoint(
      @sorted_set.from_array([4, 5, 6]),
    ),
    content="true",
  )
  inspect(
    @sorted_set.from_array([1, 2, 3]).subset(@sorted_set.from_array([3, 4, 5])),
    content="false",
  )
}

///|
test "subset" {
  inspect(
    @sorted_set.from_array([1, 2, 3]).subset(
      @sorted_set.from_array([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    ),
    content="true",
  )
  inspect(
    @sorted_set.from_array([1, 2, 3]).subset(
      @sorted_set.from_array([10, 11, 12, 13, 14]),
    ),
    content="false",
  )
}

///|
test "diff" {
  debug_inspect(
    @sorted_set.from_array([1, 2, 3]).difference(
      @sorted_set.from_array([4, 5, 1]),
    ),
    content=(
      #|<SortedSet: [2, 3]>
    ),
  )
}

///|
test "intersect" {
  debug_inspect(
    @sorted_set.from_array([3, 4, 5]).intersection(
      @sorted_set.from_array([4, 5, 6]),
    ),
    content=(
      #|<SortedSet: [4, 5]>
    ),
  )
}

///|
test "each" {
  let set = @sorted_set.from_array([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let result = StringBuilder(size_hint=10)
  set.each(x => result.write_string(x.to_string()))
  inspect(result.to_string(), content="123456789")
  let set : @sorted_set.SortedSet[Int] = @sorted_set.SortedSet([])
  set.each(_x => abort("Impossible to reach"))
}

///|
test "eachi" {
  let set = @sorted_set.from_array([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let result = StringBuilder(size_hint=10)
  set.eachi((i, x) => result.write_string("[\{i}-\{x}]"))
  inspect(
    result.to_string(),
    content="[0-1][1-2][2-3][3-4][4-5][5-6][6-7][7-8][8-9]",
  )
}

///|
test "iter" {
  let set = @sorted_set.from_array([3, 2, 1])
  debug_inspect(set.iter().collect(), content="[1, 2, 3]")
  debug_inspect(set.iter().take(2).collect(), content="[1, 2]")
}

///|
test "iter early termination in left subtree" {
  // This test should trigger the uncovered line 381 in sorted_set/set.mbt
  // We need a tree structure where the iterator terminates while traversing the left subtree
  let set = @sorted_set.from_array([5, 3, 7, 1, 4, 6, 8])
  // Create an iterator that terminates when it finds value 3
  // Since the tree is sorted and 3 is in the left subtree of 5,
  // this should cause go(left) to return IterEnd, triggering line 381
  let (count, found_target) = for x in set.iter(); count = 0 {
    if x == 3 {
      break (count + 1, true) // This should propagate up and trigger the uncovered line
    }
    continue count + 1
  } nobreak {
    (count, false)
  }
  inspect(found_target, content="true")
  inspect(count, content="2") // Should visit 1, then 3 and terminate
}

///|
test "contains" {
  let set = @sorted_set.from_array([7, 2, 9, 4, 6, 3, 8, 1])
  inspect(set.contains(5), content="false")
  set.add(5)
  inspect(set.contains(5), content="true")
  inspect(
    @sorted_set.from_array([7, 2, 9, 4, 6, 3, 8, 1]).contains(5),
    content="false",
  )
  inspect(@sorted_set.from_array([]).contains(1), content="false")
}

///|
test "to_array" {
  debug_inspect(
    @sorted_set.from_array([7, 2, 9, 4, 5, 6, 3, 8, 1]).to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
  debug_inspect(
    (@sorted_set.from_array([]) : @sorted_set.SortedSet[Int]).to_array(),
    content="[]",
  )
}

///|
test "to_string" {
  debug_inspect(
    @sorted_set.from_array([1, 2, 3, 4, 5]),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5]>
    ),
  )
  debug_inspect(
    (@sorted_set.from_array([]) : @sorted_set.SortedSet[Int]),
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "from_array" {
  debug_inspect(
    @sorted_set.from_array([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
}

///|
test "is_empty" {
  inspect(
    (@sorted_set.from_array([]) : @sorted_set.SortedSet[Int]).is_empty(),
    content="true",
  )
  inspect(@sorted_set.from_array([1]).is_empty(), content="false")
}

///|
test "size" {
  inspect(@sorted_set.from_array([1, 2, 3, 4, 5]).length(), content="5")
  inspect(@sorted_set.from_array([1]).length(), content="1")
  inspect(
    (@sorted_set.from_array([]) : @sorted_set.SortedSet[Int]).length(),
    content="0",
  )
}

///|
test "singleton" {
  inspect(@sorted_set.singleton(1).length(), content="1")
  inspect(@sorted_set.singleton(1).contains(1), content="true")
  inspect(@sorted_set.singleton(1).contains(2), content="false")
}

///|
test "show" {
  let set = @sorted_set.from_array([1, 2, 3, 4, 5])
  debug_inspect(
    set,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5]>
    ),
  )
  let set : @sorted_set.SortedSet[Int] = @sorted_set.from_array([])
  debug_inspect(
    set,
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "mix_everything" {
  // test all functions together, including add, remove, union, diff, inter, subset, disjoint, size, is_empty, contains
  let set1 = @sorted_set.from_array([1, 2, 3, 4, 5])
  let set2 = @sorted_set.from_array([4, 5, 6, 7, 8])
  set1.add(6)
  debug_inspect(
    set1,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6]>
    ),
  )
  set1.remove(6)
  debug_inspect(
    set1,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5]>
    ),
  )
  let set3 = set1.union(set2)
  debug_inspect(
    set3,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8]>
    ),
  )
  let set4 = set1.difference(set2)
  debug_inspect(
    set4,
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  let set5 = set1.intersection(set2)
  debug_inspect(
    set5,
    content=(
      #|<SortedSet: [4, 5]>
    ),
  )
  inspect(set1.subset(set3), content="true")
  set3.remove(3)
  debug_inspect(
    set3,
    content=(
      #|<SortedSet: [1, 2, 4, 5, 6, 7, 8]>
    ),
  )
  inspect(set3.length(), content="7")
  inspect(set3.is_empty(), content="false")
  inspect(set3.contains(1), content="true")
  inspect(set3.contains(3), content="false")
  inspect(set3.disjoint(set1), content="false")
  let set6 = set3.union(@sorted_set.from_array([]))
  debug_inspect(
    set6,
    content=(
      #|<SortedSet: [1, 2, 4, 5, 6, 7, 8]>
    ),
  )
  let set7 = set3.union(@sorted_set.from_array([12, 13, 14, 33, 22]))
  debug_inspect(
    set7,
    content=(
      #|<SortedSet: [1, 2, 4, 5, 6, 7, 8, 12, 13, 14, 22, 33]>
    ),
  )
  for i in 1..<=5 {
    set7.remove(i)
  }
  debug_inspect(
    set7,
    content=(
      #|<SortedSet: [6, 7, 8, 12, 13, 14, 22, 33]>
    ),
  )
  for i in 6..<=33 {
    set7.remove(i)
  }
  let set = @sorted_set.from_array([
    90, 70, 13, 44, 11, 49, 39, 35, 52, 8, 80, 40, 58, 67, 84, 38, 93, 97, 54, 95,
  ])
  set.remove(70)
  debug_inspect(
    set,
    content=(
      #|<SortedSet:
      #|  [
      #|    8,
      #|    11,
      #|    13,
      #|    35,
      #|    38,
      #|    39,
      #|    40,
      #|    44,
      #|    49,
      #|    52,
      #|    54,
      #|    58,
      #|    67,
      #|    80,
      #|    84,
      #|    90,
      #|    93,
      #|    95,
      #|    97,
      #|  ]>
    ),
  )
  set.remove(52)
  debug_inspect(
    set,
    content=(
      #|<SortedSet:
      #|  [
      #|    8,
      #|    11,
      #|    13,
      #|    35,
      #|    38,
      #|    39,
      #|    40,
      #|    44,
      #|    49,
      #|    54,
      #|    58,
      #|    67,
      #|    80,
      #|    84,
      #|    90,
      #|    93,
      #|    95,
      #|    97,
      #|  ]>
    ),
  )
}

///|
test "equal" {
  let a = @sorted_set.from_array([1, 2, 3])
  let b = @sorted_set.from_array([4, 5, 6])
  inspect(a == a, content="true")
  inspect(b == b, content="true")
  inspect(a == b, content="false")
  inspect(b == a, content="false")
}

///|
test "from_iter multiple elements iter" {
  debug_inspect(
    @sorted_set.from_iter([1, 2, 3].iter()),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.from_iter([1, 1, 1].iter()),
    content=(
      #|<SortedSet: [1]>
    ),
  )
}

///|
test "from_iter single element iter" {
  debug_inspect(
    @sorted_set.from_iter([1].iter()),
    content=(
      #|<SortedSet: [1]>
    ),
  )
}

///|
test "from_iter empty iter" {
  let pq : @sorted_set.SortedSet[Int] = @sorted_set.from_iter(Iter::empty())
  debug_inspect(
    pq,
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "range" {
  let set = @sorted_set.from_array([1, 2, 3, 4, 5])
  debug_inspect(
    set.range(2, 4).to_array(),
    content=(
      #|[2, 3, 4]
    ),
  )
  debug_inspect(
    set.range(1, 1).to_array(),
    content=(
      #|[1]
    ),
  )
  debug_inspect(
    set.range(5, 5).to_array(),
    content=(
      #|[5]
    ),
  )
}

///|
test "@sorted_set.symmetric_difference/basic" {
  // Test basic functionality with disjoint sets
  let set1 = @sorted_set.from_array([1, 2, 3])
  let set2 = @sorted_set.from_array([4, 5, 6])
  let result = set1.symmetric_difference(set2)
  debug_inspect(
    result,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6]>
    ),
  )

  // Test with overlapping sets
  let set3 = @sorted_set.from_array([1, 2, 3, 4])
  let set4 = @sorted_set.from_array([3, 4, 5, 6])
  let result2 = set3.symmetric_difference(set4)
  debug_inspect(
    result2,
    content=(
      #|<SortedSet: [1, 2, 5, 6]>
    ),
  )
}

///|
test "@sorted_set.symmetric_difference/empty" {
  // Test with empty sets
  let empty1 = @sorted_set.SortedSet([])
  let empty2 = @sorted_set.SortedSet([])
  let result1 = empty1.symmetric_difference(empty2)
  debug_inspect(
    result1,
    content=(
      #|<SortedSet: []>
    ),
  )

  // Test with one empty set
  let set1 = @sorted_set.from_array([1, 2, 3])
  let result2 = set1.symmetric_difference(empty1)
  debug_inspect(
    result2,
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  let result3 = empty1.symmetric_difference(set1)
  debug_inspect(
    result3,
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
}

///|
test "@sorted_set.symmetric_difference/identical" {
  // Test with identical sets
  let set1 = @sorted_set.from_array([1, 2, 3, 4, 5])
  let set2 = @sorted_set.from_array([1, 2, 3, 4, 5])
  let result = set1.symmetric_difference(set2)
  debug_inspect(
    result,
    content=(
      #|<SortedSet: []>
    ),
  )
}
