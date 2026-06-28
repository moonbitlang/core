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

// This package implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

///|
priv struct SameRankValue {
  rank : Int
  label : String
} derive(Eq)

///|
impl Compare for SameRankValue with fn compare(self, other) {
  self.rank.compare(other.rank)
}

///|
test "new" {
  let empty : @sorted_set.SortedSet[Int] = @sorted_set.new()
  debug_inspect(
    empty,
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "default" {
  let set : @sorted_set.SortedSet[Int] = Default::default()
  debug_inspect(
    set,
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "disjoint" {
  inspect(
    @sorted_set.SortedSet([1]).disjoint(SortedSet([1, 2, 3])),
    content="false",
  )
  inspect(
    @sorted_set.SortedSet([1, 2, 3]).disjoint(SortedSet([1, 2, 3])),
    content="false",
  )
  inspect(
    @sorted_set.SortedSet([1, 2, 3]).disjoint(SortedSet([4, 5, 6])),
    content="true",
  )
  inspect(
    @sorted_set.SortedSet([1, 2, 3]).subset(SortedSet([3, 4, 5])),
    content="false",
  )
}

///|
test "disjoint same instance" {
  let set = @sorted_set.SortedSet([1, 2, 3])
  inspect(set.disjoint(set), content="false")
}

///|
test "subset" {
  inspect(
    @sorted_set.SortedSet([1, 2, 3]).subset(
      SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    ),
    content="true",
  )
  inspect(
    @sorted_set.SortedSet([1, 2, 3]).subset(SortedSet([10, 11, 12, 13, 14])),
    content="false",
  )
  // element not in other but previously missed by buggy self-reference
  inspect(
    @sorted_set.SortedSet([1, 2, 5]).subset(SortedSet([1, 2, 3, 4])),
    content="false",
  )
  inspect(
    @sorted_set.SortedSet([0, 3, 4]).subset(SortedSet([1, 2, 3, 4])),
    content="false",
  )
  // exact match
  inspect(
    @sorted_set.SortedSet([1, 2, 3]).subset(SortedSet([1, 2, 3])),
    content="true",
  )
  // empty is subset of anything
  inspect(@sorted_set.new().subset(SortedSet([1, 2, 3])), content="true")
  // nothing is subset of empty (except empty)
  inspect(@sorted_set.SortedSet([1]).subset(@sorted_set.new()), content="false")
}

///|
test "diff" {
  let empty = @sorted_set.new()
  debug_inspect(
    empty.difference(SortedSet([1, 2, 3])),
    content=(
      #|<SortedSet: []>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3]).difference(empty),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3]).difference(SortedSet([4, 5, 1])),
    content=(
      #|<SortedSet: [2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3]).difference(SortedSet([1, 2, 3])),
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "sub" {
  let set1 = @sorted_set.SortedSet([1, 2, 3])
  let set2 = @sorted_set.SortedSet([2, 4])
  debug_inspect(
    set1 - set2,
    content=(
      #|<SortedSet: [1, 3]>
    ),
  )
}

///|
test "inter" {
  debug_inspect(
    @sorted_set.SortedSet([3, 4, 5]).intersection(SortedSet([4, 5, 6])),
    content=(
      #|<SortedSet: [4, 5]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([3, 4]).intersection(SortedSet([5, 6])),
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "union" {
  let empty = @sorted_set.new()
  debug_inspect(
    empty.union(SortedSet([4, 5, 6])),
    content=(
      #|<SortedSet: [4, 5, 6]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([4, 5, 6]).union(empty),
    content=(
      #|<SortedSet: [4, 5, 6]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([3]).union(SortedSet([4, 5, 6])),
    content=(
      #|<SortedSet: [3, 4, 5, 6]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([3, 4, 5]).union(SortedSet([6])),
    content=(
      #|<SortedSet: [3, 4, 5, 6]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([3, 4, 5]).union(SortedSet([4, 5, 6])),
    content=(
      #|<SortedSet: [3, 4, 5, 6]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([3, 4, 5]) + SortedSet([4, 5, 6]),
    content=(
      #|<SortedSet: [3, 4, 5, 6]>
    ),
  )
}

///|
test "union smaller left non-singleton" {
  let left = @sorted_set.SortedSet([1, 3])
  let right = @sorted_set.SortedSet([0, 2, 4, 5])
  debug_inspect(
    left.union(right),
    content=(
      #|<SortedSet: [0, 1, 2, 3, 4, 5]>
    ),
  )
}

///|

///|
test "map" {
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3, 4, 5]).map(x => x * 2),
    content=(
      #|<SortedSet: [2, 4, 6, 8, 10]>
    ),
  )
}

///|
test "map non-monotonic" {
  let set = @sorted_set.SortedSet([1, 2, 3])
  debug_inspect(
    set.map(x => 4 - x),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
}

///|
test "all" {
  inspect(@sorted_set.SortedSet([2, 4, 6]).all(v => v % 2 == 0), content="true")
  inspect(
    @sorted_set.SortedSet([1, 3, 5]).all(v => v % 2 == 0),
    content="false",
  )
}

///|
test "any" {
  inspect(@sorted_set.SortedSet([1, 4, 3]).any(v => v % 2 == 0), content="true")
  inspect(
    @sorted_set.SortedSet([1, 5, 3]).any(v => v % 2 == 0),
    content="false",
  )
}

///|
test "fold" {
  inspect(
    @sorted_set.SortedSet([1, 2, 3, 4, 5]).fold(init=0, (acc, x) => acc + x),
    content="15",
  )
}

///|
test "filter" {
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3, 4, 5, 6]).filter(v => v % 2 == 0),
    content=(
      #|<SortedSet: [2, 4, 6]>
    ),
  )
}

///|
test "split" {
  let (left, present, right) = @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(
    5,
  )
  inspect(present, content="true")
  debug_inspect(
    left,
    content=(
      #|<SortedSet: [1, 2, 3, 4]>
    ),
  )
  debug_inspect(
    right,
    content=(
      #|<SortedSet: [6, 7, 8, 9]>
    ),
  )
  let (left, present, right) = @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(
    0,
  )
  inspect(present, content="false")
  debug_inspect(
    left,
    content=(
      #|<SortedSet: []>
    ),
  )
  debug_inspect(
    right,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
}

///|
test "contain" {
  inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 6, 3, 8, 1]).add(5).contains(5),
    content="true",
  )
  inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 6, 3, 8, 1]).contains(5),
    content="false",
  )
}

///|
test "to_array" {
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
}

///|
test "from_fixed_array" {
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
}

///|
test "SortedSet constructor" {
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
}

///|
test "SortedSet ordered inputs" {
  @test.assert_eq(@sorted_set.SortedSet([1, 2, 3]).to_array(), [1, 2, 3])
  @test.assert_eq(@sorted_set.SortedSet([3, 2, 1]).to_array(), [1, 2, 3])
}

///|
test "SortedSet ordered duplicates" {
  @test.assert_eq(@sorted_set.SortedSet([1, 1, 2, 3]).to_array(), [1, 2, 3])
}

///|
test "SortedSet ordered duplicates keep reverse insertion representative" {
  let set = @sorted_set.SortedSet([
    { rank: 1, label: "first" },
    { rank: 1, label: "second" },
    { rank: 2, label: "third" },
  ])
  @test.assert_eq(set.to_array().map(v => v.label), ["second", "third"])
}

///|
test "SortedSet large unordered duplicates keep reverse insertion representative" {
  let values = Array::makei(70, i => {
    if i == 5 {
      { rank: 10, label: "first" }
    } else if i == 50 {
      { rank: 10, label: "second" }
    } else {
      { rank: 1000 - i, label: "other-\{i}" }
    }
  })
  let set = @sorted_set.SortedSet(values)
  let matched = []
  for value in set {
    if value.rank == 10 {
      matched.push(value.label)
    }
  }
  @test.assert_eq(matched, ["second"])
}

///|
test "from_sorted_array" {
  let set = @sorted_set.from_sorted_array([1, 2, 3])
  @test.assert_eq(set.to_array(), [1, 2, 3])
  @test.assert_eq(set.contains(2), true)
}

///|
test "remove_min" {
  debug_inspect(
    @sorted_set.SortedSet([3, 4, 5]).remove_min(),
    content=(
      #|<SortedSet: [4, 5]>
    ),
  )
}

///|
test "add" {
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 6, 3, 8, 1]).add(5),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([2]).add(1),
    content=(
      #|<SortedSet: [1, 2]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([2]).add(3),
    content=(
      #|<SortedSet: [2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([2]).add(1).add(3),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([1, 2]).add(1),
    content=(
      #|<SortedSet: [1, 2]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([2, 3]).add(3),
    content=(
      #|<SortedSet: [2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3]).add(1),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3]).add(3),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([1]).add(2).add(2),
    content=(
      #|<SortedSet: [1, 2]>
    ),
  )
}

///|
test "remove" {
  let empty = @sorted_set.new()
  debug_inspect(
    empty.remove(1),
    content=(
      #|<SortedSet: []>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(1),
    content=(
      #|<SortedSet: [2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(9),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(8),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 9]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(0),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(10),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6, 7, 8, 9]>
    ),
  )
}

///|
test "merge and concat with empty right" {
  let set = @sorted_set.new().add(2).add(1)
  debug_inspect(
    set.remove(2),
    content=(
      #|<SortedSet: [1]>
    ),
  )
  let other = @sorted_set.new().add(1)
  debug_inspect(
    set.intersection(other),
    content=(
      #|<SortedSet: [1]>
    ),
  )
}

///|
test "min" {
  inspect(@sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).min(), content="1")
}

///|
test "min_option" {
  let empty : @sorted_set.SortedSet[Int] = @sorted_set.new()
  debug_inspect(empty.min_option(), content="None")
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).min_option(),
    content="Some(1)",
  )
}

///|
test "max" {
  inspect(@sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).max(), content="9")
}

///|
test "max_option" {
  let empty : @sorted_set.SortedSet[Int] = @sorted_set.new()
  debug_inspect(empty.max_option(), content="None")
  debug_inspect(
    @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).max_option(),
    content="Some(9)",
  )
}

///|
test "is_empty" {
  inspect(
    (SortedSet([]) : @sorted_set.SortedSet[Int]).is_empty(),
    content="true",
  )
  inspect(@sorted_set.SortedSet([1]).is_empty(), content="false")
}

///|
test "to_string" {
  debug_inspect(
    @sorted_set.SortedSet([1, 2, 3, 4, 5]),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5]>
    ),
  )
  debug_inspect(
    (SortedSet([]) : @sorted_set.SortedSet[Int]),
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "equal" {
  let xss : Array[@sorted_set.SortedSet[Int]] = @quickcheck.samples(5)
  for xs in xss {
    for ys in xss {
      if xs.to_array() == ys.to_array() {
        @test.assert_eq(xs, ys)
      } else {
        @test.assert_not_eq(xs, ys)
      }
    }
  }
}

///|
test "compare" {
  let xss : Array[@sorted_set.SortedSet[Int]] = @quickcheck.samples(5)
  for xs in xss {
    for ys in xss {
      @test.assert_eq(xs.compare(ys), xs.to_array().compare(ys.to_array()))
    }
  }
}

///|
test "to_json" {
  @json.json_inspect(@sorted_set.SortedSet([5, 2, 4, 3, 1]), content=[
    1, 2, 3, 4, 5,
  ])
  @json.json_inspect((SortedSet([]) : @sorted_set.SortedSet[Int]), content=[])
}

///|
test "from_json" {
  for xs in (@quickcheck.samples(20) : Array[@sorted_set.SortedSet[Int]]) {
    @test.assert_eq(xs, @json.from_json(xs.to_json()))
  }
}

///|
test "from_json free function" {
  let json : Json = [1, 2, 3]
  let set : @sorted_set.SortedSet[Int] = @sorted_set.from_json(json)
  debug_inspect(
    set,
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
}

///|
test "from_json rejects non-array" {
  let bad_json : Json = { "a": 1 }
  try (@sorted_set.from_json(bad_json) : @sorted_set.SortedSet[Int]) catch {
    _ => ()
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "iter" {
  let mut s = ""
  @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(x => {
    s += x.to_string()
  })
  inspect(s, content="123456789")
  let empty : @sorted_set.SortedSet[Int] = SortedSet([])
  s = ""
  empty.each(x => s += x.to_string())
  inspect(s, content="")
}

///|
test "iter_loop" {
  let buf = StringBuilder(size_hint=20)
  let set = [2, 7, 1, 2, 3, 4, 5] |> @sorted_set.SortedSet
  for x in set {
    buf.write_object(x)
  }
  inspect(buf, content="123457")
}

// test "of_sorted_array" {
//   inspect(
//     of_sorted_array([1, 2, 3, 4, 5, 6, 7, 8, 9]),
//     content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
//   )?
// }
//
// // Convert a sorted array into a balanced binary search tree to facilitate subsequent search, insertion, and deletion operations.
// fn of_sorted_array[T : Compare](array : Array[T]) -> ImmutableSet[T] {
//   // Recursively process the input array and build a balanced binary search tree based on the length n of the array.
//   fn sub(n : Int, xs : ArrayView[T]) -> (ImmutableSet[T], ArrayView[T]) {
//     match (n, xs) {
//       (0, xs) => (Empty, xs)
//       (1, [ value, .. asremain ]) =>
//         (Node(left=Empty, ~value, right=Empty, height=1), remain)
//       (2, [ value, value1, .. asremain ]) =>
//         (
//           Node(
//             left=Node(left=Empty, ~value, right=Empty, height=1),
//             value=value1,
//             right=Empty,
//             height=2,
//           ),
//           remain,
//         )
//       (3, [ value, value1, value2, .. asremain ]) =>
//         (
//           Node(
//             left=Node(left=Empty, ~value, right=Empty, height=1),
//             value=value1,
//             right=Node(left=Empty, value=value2, right=Empty, height=1),
//             height=2,
//           ),
//           remain,
//         )

//       // For n > 3, the function first calculates the size of the left subtree,
//       // and then recursively constructs the left subtree.
//       _ => {
//         let left_length = n / 2
//         let (left, xs) = sub(left_length, xs)
//         match xs {
//           [  ] => abort("of_sorted_array: cannot constructs the left")
//           [ mid, .. asxs ] => {
//             let (right, xs) = sub(n - left_length - 1, xs)
//             (create(left, mid, right), xs)
//           }
//         }
//       }
//     }
//   }

//   sub(array.length(), array[:]).0
// }

///|
test "split with value not in set" {
  let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
  let (left, present, right) = set.split(6)
  inspect(present, content="false")
  debug_inspect(
    left,
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5]>
    ),
  )
  debug_inspect(
    right,
    content=(
      #|<SortedSet: []>
    ),
  )
}

///|
test "remove_min on non-empty set" {
  let set = @sorted_set.SortedSet([3, 4, 5])
  let new_set = set.remove_min()
  debug_inspect(
    new_set,
    content=(
      #|<SortedSet: [4, 5]>
    ),
  )
}

///|
test "min on non-empty set" {
  let set = @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let min_value = set.min()
  inspect(min_value, content="1")
}

///|
test "max on non-empty set" {
  let set = @sorted_set.SortedSet([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let max_value = set.max()
  inspect(max_value, content="9")
}

///|
test "union with different heights" {
  let set1 = @sorted_set.SortedSet([3, 4, 5])
  let set2 = @sorted_set.SortedSet([4, 5, 6])
  let union_set = set1.union(set2)
  debug_inspect(
    union_set,
    content=(
      #|<SortedSet: [3, 4, 5, 6]>
    ),
  )
}

///|
test "disjoint with different sets" {
  let set1 = @sorted_set.SortedSet([1, 2, 3])
  let set2 = @sorted_set.SortedSet([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect(disjoint, content="true")
}

///|
test "from_iter multiple elements iter" {
  debug_inspect(
    @sorted_set.from_iter([1, 2, 3].iter()),
    content=(
      #|<SortedSet: [1, 2, 3]>
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
test "size" {
  // Empty set should have size 0
  let empty_set : @sorted_set.SortedSet[Int] = @sorted_set.new()
  inspect(empty_set.length(), content="0")

  // Single element set should have size 1
  inspect(@sorted_set.SortedSet([1]).length(), content="1")

  // Multiple elements set should have correct size
  // The order of insertion should not affect the size
  inspect(
    @sorted_set.SortedSet([3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]).length(),
    content="7",
  )
}

///|
test "@sorted_set.symmetric_difference" {
  // Empty sets
  let empty = @sorted_set.new()
  let set1 = @sorted_set.SortedSet([1, 2, 3])
  debug_inspect(
    empty.symmetric_difference(empty),
    content=(
      #|<SortedSet: []>
    ),
  )
  debug_inspect(
    set1.symmetric_difference(empty),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
  debug_inspect(
    empty.symmetric_difference(set1),
    content=(
      #|<SortedSet: [1, 2, 3]>
    ),
  )
}

///|
test "@sorted_set.symmetric_difference/disjoint" {
  // Disjoint sets should union all elements
  let set1 = @sorted_set.SortedSet([1, 3, 5])
  let set2 = @sorted_set.SortedSet([2, 4, 6])
  debug_inspect(
    set1.symmetric_difference(set2),
    content=(
      #|<SortedSet: [1, 2, 3, 4, 5, 6]>
    ),
  )
}

///|
test "@sorted_set.symmetric_difference/overlapping" {
  // Sets with overlapping elements should only include non-common elements
  let set1 = @sorted_set.SortedSet([1, 2, 3, 4])
  let set2 = @sorted_set.SortedSet([3, 4, 5, 6])
  debug_inspect(
    set1.symmetric_difference(set2),
    content=(
      #|<SortedSet: [1, 2, 5, 6]>
    ),
  )
}

///|
test "range on empty set" {
  let empty : @sorted_set.SortedSet[Int] = @sorted_set.new()
  let count = for _ in empty.range(low=1, high=5); count = 0 {
    continue count + 1
  } nobreak {
    count
  }
  inspect(count, content="0")
}

///|
test "range with no matches" {
  let set = @sorted_set.SortedSet([1, 2, 3])
  let count = for _ in set.range(low=10, high=20); count = 0 {
    continue count + 1
  } nobreak {
    count
  }
  inspect(count, content="0")
}

///|
test "range matching all elements" {
  let set = @sorted_set.SortedSet([1, 2, 3])
  let arr = []
  for v in set.range(low=0, high=10) {
    arr.push(v)
  }
  debug_inspect(arr, content="[1, 2, 3]")
}

///|
test "range partial match" {
  let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
  let arr = []
  for v in set.range(low=2, high=4) {
    arr.push(v)
  }
  debug_inspect(arr, content="[2, 3, 4]")
}

///|
test "range with single element" {
  let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
  let arr = []
  for v in set.range(low=3, high=3) {
    arr.push(v)
  }
  debug_inspect(arr, content="[3]")
}

///|
test "range at left boundary" {
  let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
  let arr = []
  for v in set.range(low=1, high=2) {
    arr.push(v)
  }
  debug_inspect(arr, content="[1, 2]")
}

///|
test "range at right boundary" {
  let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
  let arr = []
  for v in set.range(low=4, high=5) {
    arr.push(v)
  }
  debug_inspect(arr, content="[4, 5]")
}

///|
test "range with gaps in data" {
  let set = @sorted_set.SortedSet([1, 3, 5, 7, 9])
  let arr = []
  for v in set.range(low=2, high=8) {
    arr.push(v)
  }
  debug_inspect(arr, content="[3, 5, 7]")
}

///|
test "range with inverted bounds" {
  let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
  let count = for _ in set.range(low=5, high=2); count = 0 {
    continue count + 1
  } nobreak {
    count
  }
  inspect(count, content="0")
}

///|
test "range with early termination" {
  let set = @sorted_set.SortedSet([1, 2, 3, 4, 5])
  let count = for _ in set.range(low=1, high=5); count = 0 {
    let count = count + 1
    if count == 2 {
      break count
    }
    continue count
  } nobreak {
    count
  }
  inspect(count, content="2")
}

///|
test "range on large dataset" {
  let arr = Array::makei(100, fn(i) { i })
  let set = @sorted_set.SortedSet(arr)
  let count = for _ in set.range(low=25, high=75); count = 0 {
    continue count + 1
  } nobreak {
    count
  }
  inspect(count, content="51")
}

///|
test "range with non-existent boundaries" {
  let set = @sorted_set.SortedSet([2, 4, 6, 8])
  let arr = []
  for v in set.range(low=3, high=7) {
    arr.push(v)
  }
  debug_inspect(arr, content="[4, 6]")
}
