// Copyright 2025 International Digital Economy Academy
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

// This module implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

///|
test "new" {
  let empty : @sorted_set.T[Int] = @sorted_set.new()
  inspect!(empty, content="@immut/sorted_set.of([])")
}

///|
test "disjoint" {
  inspect!(
    @sorted_set.of([1]).disjoint(@sorted_set.of([1, 2, 3])),
    content="false",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).disjoint(@sorted_set.of([1, 2, 3])),
    content="false",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).disjoint(@sorted_set.of([4, 5, 6])),
    content="true",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).subset(@sorted_set.of([3, 4, 5])),
    content="false",
  )
}

///|
test "subset" {
  inspect!(
    @sorted_set.of([1, 2, 3]).subset(
      @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    ),
    content="true",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).subset(@sorted_set.of([10, 11, 12, 13, 14])),
    content="false",
  )
}

///|
test "diff" {
  let empty = @sorted_set.new()
  inspect!(
    empty.difference(@sorted_set.of([1, 2, 3])),
    content="@immut/sorted_set.of([])",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).difference(empty),
    content="@immut/sorted_set.of([1, 2, 3])",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).difference(@sorted_set.of([4, 5, 1])),
    content="@immut/sorted_set.of([2, 3])",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).difference(@sorted_set.of([1, 2, 3])),
    content="@immut/sorted_set.of([])",
  )
}

///|
test "inter" {
  inspect!(
    @sorted_set.of([3, 4, 5]).intersection(@sorted_set.of([4, 5, 6])),
    content="@immut/sorted_set.of([4, 5])",
  )
  inspect!(
    @sorted_set.of([3, 4]).intersection(@sorted_set.of([5, 6])),
    content="@immut/sorted_set.of([])",
  )
}

///|
test "union" {
  let empty = @sorted_set.new()
  inspect!(
    empty.union(@sorted_set.of([4, 5, 6])),
    content="@immut/sorted_set.of([4, 5, 6])",
  )
  inspect!(
    @sorted_set.of([4, 5, 6]).union(empty),
    content="@immut/sorted_set.of([4, 5, 6])",
  )
  inspect!(
    @sorted_set.of([3]).union(@sorted_set.of([4, 5, 6])),
    content="@immut/sorted_set.of([3, 4, 5, 6])",
  )
  inspect!(
    @sorted_set.of([3, 4, 5]).union(@sorted_set.of([6])),
    content="@immut/sorted_set.of([3, 4, 5, 6])",
  )
  inspect!(
    @sorted_set.of([3, 4, 5]).union(@sorted_set.of([4, 5, 6])),
    content="@immut/sorted_set.of([3, 4, 5, 6])",
  )
  inspect!(
    @sorted_set.of([3, 4, 5]) + @sorted_set.of([4, 5, 6]),
    content="@immut/sorted_set.of([3, 4, 5, 6])",
  )
}

///|
test "map" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5]).map(fn(x) { x * 2 }),
    content="@immut/sorted_set.of([2, 4, 6, 8, 10])",
  )
}

///|
test "all" {
  inspect!(@sorted_set.of([2, 4, 6]).all(fn(v) { v % 2 == 0 }), content="true")
  inspect!(@sorted_set.of([1, 3, 5]).all(fn(v) { v % 2 == 0 }), content="false")
}

///|
test "any" {
  inspect!(@sorted_set.of([1, 4, 3]).any(fn(v) { v % 2 == 0 }), content="true")
  inspect!(@sorted_set.of([1, 5, 3]).any(fn(v) { v % 2 == 0 }), content="false")
}

///|
test "fold" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5]).fold(init=0, fn(acc, x) { acc + x }),
    content="15",
  )
}

///|
test "filter" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5, 6]).filter(fn(v) { v % 2 == 0 }),
    content="@immut/sorted_set.of([2, 4, 6])",
  )
}

///|
test "split" {
  let (left, present, right) = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(
    5,
  )
  inspect!(present, content="true")
  inspect!(left, content="@immut/sorted_set.of([1, 2, 3, 4])")
  inspect!(right, content="@immut/sorted_set.of([6, 7, 8, 9])")
  let (left, present, right) = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(
    0,
  )
  inspect!(present, content="false")
  inspect!(left, content="@immut/sorted_set.of([])")
  inspect!(right, content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 8, 9])")
}

///|
test "contain" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 6, 3, 8, 1]).add(5).contains(5),
    content="true",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 6, 3, 8, 1]).contains(5),
    content="false",
  )
}

///|
test "to_array" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
}

///|
test "from_fixed_array" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 8, 9])",
  )
}

///|
test "from_array" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 8, 9])",
  )
}

///|
test "remove_min" {
  inspect!(
    @sorted_set.of([3, 4, 5]).remove_min(),
    content="@immut/sorted_set.of([4, 5])",
  )
}

///|
test "add" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 6, 3, 8, 1]).add(5),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 8, 9])",
  )
  inspect!(@sorted_set.of([2]).add(1), content="@immut/sorted_set.of([1, 2])")
  inspect!(@sorted_set.of([2]).add(3), content="@immut/sorted_set.of([2, 3])")
  inspect!(
    @sorted_set.of([2]).add(1).add(3),
    content="@immut/sorted_set.of([1, 2, 3])",
  )
  inspect!(
    @sorted_set.of([1, 2]).add(1),
    content="@immut/sorted_set.of([1, 2])",
  )
  inspect!(
    @sorted_set.of([2, 3]).add(3),
    content="@immut/sorted_set.of([2, 3])",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).add(1),
    content="@immut/sorted_set.of([1, 2, 3])",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).add(3),
    content="@immut/sorted_set.of([1, 2, 3])",
  )
  inspect!(
    @sorted_set.of([1]).add(2).add(2),
    content="@immut/sorted_set.of([1, 2])",
  )
}

///|
test "remove" {
  let empty = @sorted_set.new()
  inspect!(empty.remove(1), content="@immut/sorted_set.of([])")
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(1),
    content="@immut/sorted_set.of([2, 3, 4, 5, 6, 7, 8, 9])",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(9),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 8])",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(8),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 9])",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(0),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 8, 9])",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(10),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6, 7, 8, 9])",
  )
}

///|
test "min" {
  inspect!(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).min(), content="1")
}

///|
test "min_option" {
  let empty : @sorted_set.T[Int] = @sorted_set.new()
  inspect!(empty.min_option(), content="None")
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).min_option(),
    content="Some(1)",
  )
}

///|
test "max" {
  inspect!(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).max(), content="9")
}

///|
test "max_option" {
  let empty : @sorted_set.T[Int] = @sorted_set.new()
  inspect!(empty.max_option(), content="None")
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).max_option(),
    content="Some(9)",
  )
}

///|
test "is_empty" {
  inspect!((@sorted_set.of([]) : @sorted_set.T[Int]).is_empty(), content="true")
  inspect!(@sorted_set.of([1]).is_empty(), content="false")
}

///|
test "to_string" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5]),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5])",
  )
  inspect!(
    (@sorted_set.of([]) : @sorted_set.T[Int]),
    content="@immut/sorted_set.of([])",
  )
}

///|
test "op_equal" {
  let xss : Array[@sorted_set.T[Int]] = @quickcheck.samples(5)
  for xs in xss {
    for ys in xss {
      if xs.to_array() == ys.to_array() {
        assert_eq!(xs, ys)
      } else {
        assert_not_eq!(xs, ys)
      }
    }
  }
}

///|
test "compare" {
  let xss : Array[@sorted_set.T[Int]] = @quickcheck.samples(5)
  for xs in xss {
    for ys in xss {
      assert_eq!(xs.compare(ys), xs.to_array().compare(ys.to_array()))
    }
  }
}

///|
test "to_json" {
  @json.inspect!(@sorted_set.of([5, 2, 4, 3, 1]), content=[1, 2, 3, 4, 5])
  @json.inspect!((@sorted_set.of([]) : @sorted_set.T[Int]), content=[])
}

///|
test "from_json" {
  for xs in (@quickcheck.samples(20) : Array[@sorted_set.T[Int]]) {
    assert_eq!(xs, @json.from_json!(xs.to_json()))
  }
}

///|
test "iter" {
  let mut s = ""
  @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(fn(x) { s += x.to_string() })
  inspect!(s, content="123456789")
  let empty : @sorted_set.T[Int] = @sorted_set.of([])
  s = ""
  empty.each(fn(x) { s += x.to_string() })
  inspect!(s, content="")
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
  let set = @sorted_set.of([1, 2, 3, 4, 5])
  let (left, present, right) = set.split(6)
  inspect!(present, content="false")
  inspect!(left, content="@immut/sorted_set.of([1, 2, 3, 4, 5])")
  inspect!(right, content="@immut/sorted_set.of([])")
}

///|
test "remove_min on non-empty set" {
  let set = @sorted_set.of([3, 4, 5])
  let new_set = set.remove_min()
  inspect!(new_set, content="@immut/sorted_set.of([4, 5])")
}

///|
test "min on non-empty set" {
  let set = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let min_value = set.min()
  inspect!(min_value, content="1")
}

///|
test "max on non-empty set" {
  let set = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let max_value = set.max()
  inspect!(max_value, content="9")
}

///|
test "union with different heights" {
  let set1 = @sorted_set.of([3, 4, 5])
  let set2 = @sorted_set.of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect!(union_set, content="@immut/sorted_set.of([3, 4, 5, 6])")
}

///|
test "disjoint with different sets" {
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect!(disjoint, content="true")
}

///|
test "union with different heights" {
  let set1 = @sorted_set.of([3, 4, 5])
  let set2 = @sorted_set.of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect!(union_set, content="@immut/sorted_set.of([3, 4, 5, 6])")
}

///|
test "disjoint with different sets" {
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect!(disjoint, content="true")
}

///|
test "union with different heights" {
  let set1 = @sorted_set.of([3, 4, 5])
  let set2 = @sorted_set.of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect!(union_set, content="@immut/sorted_set.of([3, 4, 5, 6])")
}

///|
test "disjoint with different sets" {
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect!(disjoint, content="true")
}

///|
test "from_iter multiple elements iter" {
  inspect!(
    @sorted_set.from_iter([1, 2, 3].iter()),
    content="@immut/sorted_set.of([1, 2, 3])",
  )
}

///|
test "from_iter single element iter" {
  inspect!(
    @sorted_set.from_iter([1].iter()),
    content="@immut/sorted_set.of([1])",
  )
}

///|
test "from_iter empty iter" {
  let pq : @sorted_set.T[Int] = @sorted_set.from_iter(Iter::empty())
  inspect!(pq, content="@immut/sorted_set.of([])")
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let set = [2, 7, 1, 2, 3, 4, 5] |> @sorted_set.of
  for x in set {
    buf.write_object(x)
  }
  inspect!(buf, content="123457")
}

///|
test "size" {
  // Empty set should have size 0
  let empty_set : @sorted_set.T[Int] = @sorted_set.new()
  inspect!(empty_set.size(), content="0")

  // Single element set should have size 1
  inspect!(@sorted_set.of([1]).size(), content="1")

  // Multiple elements set should have correct size
  // The order of insertion should not affect the size
  inspect!(
    @sorted_set.of([3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]).size(),
    content="7",
  )
}

///|
test "@sorted_set.symmetric_difference" {
  // Empty sets
  let empty = @sorted_set.new()
  let set1 = @sorted_set.of([1, 2, 3])
  inspect!(
    empty.symmetric_difference(empty),
    content="@immut/sorted_set.of([])",
  )
  inspect!(
    set1.symmetric_difference(empty),
    content="@immut/sorted_set.of([1, 2, 3])",
  )
  inspect!(
    empty.symmetric_difference(set1),
    content="@immut/sorted_set.of([1, 2, 3])",
  )
}

///|
test "@sorted_set.symmetric_difference/disjoint" {
  // Disjoint sets should union all elements
  let set1 = @sorted_set.of([1, 3, 5])
  let set2 = @sorted_set.of([2, 4, 6])
  inspect!(
    set1.symmetric_difference(set2),
    content="@immut/sorted_set.of([1, 2, 3, 4, 5, 6])",
  )
}

///|
test "@sorted_set.symmetric_difference/overlapping" {
  // Sets with overlapping elements should only include non-common elements
  let set1 = @sorted_set.of([1, 2, 3, 4])
  let set2 = @sorted_set.of([3, 4, 5, 6])
  inspect!(
    set1.symmetric_difference(set2),
    content="@immut/sorted_set.of([1, 2, 5, 6])",
  )
}
