// Copyright 2024 International Digital Economy Academy
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

test "new" {
  let empty : @sorted_set.ImmutableSet[Int] = @sorted_set.new()
  inspect!(empty, content="ImmutableSet::[]")
}

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

test "diff" {
  let empty = @sorted_set.new()
  inspect!(empty.diff(@sorted_set.of([1, 2, 3])), content="ImmutableSet::[]")
  inspect!(
    @sorted_set.of([1, 2, 3]).diff(empty),
    content="ImmutableSet::[1, 2, 3]",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).diff(@sorted_set.of([4, 5, 1])),
    content="ImmutableSet::[2, 3]",
  )
  inspect!(
    @sorted_set.of([1, 2, 3]).diff(@sorted_set.of([1, 2, 3])),
    content="ImmutableSet::[]",
  )
}

test "inter" {
  inspect!(
    @sorted_set.of([3, 4, 5]).inter(@sorted_set.of([4, 5, 6])),
    content="ImmutableSet::[4, 5]",
  )
  inspect!(
    @sorted_set.of([3, 4]).inter(@sorted_set.of([5, 6])),
    content="ImmutableSet::[]",
  )
}

test "union" {
  let empty = @sorted_set.new()
  inspect!(
    empty.union(@sorted_set.of([4, 5, 6])),
    content="ImmutableSet::[4, 5, 6]",
  )
  inspect!(
    @sorted_set.of([4, 5, 6]).union(empty),
    content="ImmutableSet::[4, 5, 6]",
  )
  inspect!(
    @sorted_set.of([3]).union(@sorted_set.of([4, 5, 6])),
    content="ImmutableSet::[3, 4, 5, 6]",
  )
  inspect!(
    @sorted_set.of([3, 4, 5]).union(@sorted_set.of([6])),
    content="ImmutableSet::[3, 4, 5, 6]",
  )
  inspect!(
    @sorted_set.of([3, 4, 5]).union(@sorted_set.of([4, 5, 6])),
    content="ImmutableSet::[3, 4, 5, 6]",
  )
}

test "map" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5]).map(fn(x) { x * 2 }),
    content="ImmutableSet::[2, 4, 6, 8, 10]",
  )
}

test "all" {
  inspect!(@sorted_set.of([2, 4, 6]).all(fn(v) { v % 2 == 0 }), content="true")
  inspect!(@sorted_set.of([1, 3, 5]).all(fn(v) { v % 2 == 0 }), content="false")
}

test "any" {
  inspect!(@sorted_set.of([1, 4, 3]).any(fn(v) { v % 2 == 0 }), content="true")
  inspect!(@sorted_set.of([1, 5, 3]).any(fn(v) { v % 2 == 0 }), content="false")
}

test "fold" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5]).fold(init=0, fn(acc, x) { acc + x }),
    content="15",
  )
}

test "filter" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5, 6]).filter(fn(v) { v % 2 == 0 }),
    content="ImmutableSet::[2, 4, 6]",
  )
}

test "split" {
  let (left, present, right) = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(
    5,
  )
  inspect!(present, content="true")
  inspect!(left, content="ImmutableSet::[1, 2, 3, 4]")
  inspect!(right, content="ImmutableSet::[6, 7, 8, 9]")
  let (left, present, right) = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(
    0,
  )
  inspect!(present, content="false")
  inspect!(left, content="ImmutableSet::[]")
  inspect!(right, content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")
}

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

test "to_array" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
}

test "from_fixed_array" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
}

test "from_array" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
}

test "remove_min" {
  inspect!(
    @sorted_set.of([3, 4, 5]).remove_min(),
    content="ImmutableSet::[4, 5]",
  )
}

test "add" {
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 6, 3, 8, 1]).add(5),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
  inspect!(@sorted_set.of([2]).add(1), content="ImmutableSet::[1, 2]")
  inspect!(@sorted_set.of([2]).add(3), content="ImmutableSet::[2, 3]")
  inspect!(@sorted_set.of([2]).add(1).add(3), content="ImmutableSet::[1, 2, 3]")
  inspect!(@sorted_set.of([1, 2]).add(1), content="ImmutableSet::[1, 2]")
  inspect!(@sorted_set.of([2, 3]).add(3), content="ImmutableSet::[2, 3]")
  inspect!(@sorted_set.of([1, 2, 3]).add(1), content="ImmutableSet::[1, 2, 3]")
  inspect!(@sorted_set.of([1, 2, 3]).add(3), content="ImmutableSet::[1, 2, 3]")
  inspect!(@sorted_set.of([1]).add(2).add(2), content="ImmutableSet::[1, 2]")
}

test "remove" {
  let empty = @sorted_set.new()
  inspect!(empty.remove(1), content="ImmutableSet::[]")
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(1),
    content="ImmutableSet::[2, 3, 4, 5, 6, 7, 8, 9]",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(9),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8]",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(8),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 9]",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(0),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(10),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )
}

test "min" {
  inspect!(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).min(), content="1")
}

test "min_option" {
  let empty : @sorted_set.ImmutableSet[Int] = @sorted_set.new()
  inspect!(empty.min_option(), content="None")
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).min_option(),
    content="Some(1)",
  )
}

test "max" {
  inspect!(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).max(), content="9")
}

test "max_option" {
  let empty : @sorted_set.ImmutableSet[Int] = @sorted_set.new()
  inspect!(empty.max_option(), content="None")
  inspect!(
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).max_option(),
    content="Some(9)",
  )
}

test "is_empty" {
  inspect!(
    (@sorted_set.of([]) : @sorted_set.ImmutableSet[Int]).is_empty(),
    content="true",
  )
  inspect!(@sorted_set.of([1]).is_empty(), content="false")
}

test "to_string" {
  inspect!(
    @sorted_set.of([1, 2, 3, 4, 5]),
    content="ImmutableSet::[1, 2, 3, 4, 5]",
  )
  inspect!(
    (@sorted_set.of([]) : @sorted_set.ImmutableSet[Int]),
    content="ImmutableSet::[]",
  )
}

test "iter" {
  let mut s = ""
  @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(fn(x) { s += x.to_string() })
  inspect!(s, content="123456789")
  let empty : @sorted_set.ImmutableSet[Int] = @sorted_set.of([])
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

test "panic remove_min on empty set" {
  let empty : @sorted_set.ImmutableSet[Int] = @sorted_set.new()
  empty.remove_min() |> ignore
}

test "panic min on empty set" {
  let empty : @sorted_set.ImmutableSet[Int] = @sorted_set.new()
  empty.min() |> ignore
}

test "panic max on empty set" {
  let empty : @sorted_set.ImmutableSet[Int] = @sorted_set.new()
  empty.max() |> ignore
}

test "split with value not in set" {
  let set = @sorted_set.of([1, 2, 3, 4, 5])
  let (left, present, right) = set.split(6)
  inspect!(present, content="false")
  inspect!(left, content="ImmutableSet::[1, 2, 3, 4, 5]")
  inspect!(right, content="ImmutableSet::[]")
}

test "remove_min on non-empty set" {
  let set = @sorted_set.of([3, 4, 5])
  let new_set = set.remove_min()
  inspect!(new_set, content="ImmutableSet::[4, 5]")
}

test "min on non-empty set" {
  let set = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let min_value = set.min()
  inspect!(min_value, content="1")
}

test "max on non-empty set" {
  let set = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let max_value = set.max()
  inspect!(max_value, content="9")
}

test "union with different heights" {
  let set1 = @sorted_set.of([3, 4, 5])
  let set2 = @sorted_set.of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect!(union_set, content="ImmutableSet::[3, 4, 5, 6]")
}

test "disjoint with different sets" {
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect!(disjoint, content="true")
}

test "union with different heights" {
  let set1 = @sorted_set.of([3, 4, 5])
  let set2 = @sorted_set.of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect!(union_set, content="ImmutableSet::[3, 4, 5, 6]")
}

test "disjoint with different sets" {
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect!(disjoint, content="true")
}

test "union with different heights" {
  let set1 = @sorted_set.of([3, 4, 5])
  let set2 = @sorted_set.of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect!(union_set, content="ImmutableSet::[3, 4, 5, 6]")
}

test "disjoint with different sets" {
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect!(disjoint, content="true")
}
