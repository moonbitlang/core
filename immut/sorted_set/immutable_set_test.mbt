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
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  inspect(empty, content="ImmutableSet::[]")?
}

test "disjoint" {
  inspect(of([1]).disjoint(of([1, 2, 3])), content="false")?
  inspect(of([1, 2, 3]).disjoint(of([1, 2, 3])), content="false")?
  inspect(of([1, 2, 3]).disjoint(of([4, 5, 6])), content="true")?
  inspect(of([1, 2, 3]).subset(of([3, 4, 5])), content="false")?
}

test "subset" {
  inspect(of([1, 2, 3]).subset(of([7, 2, 9, 4, 5, 6, 3, 8, 1])), content="true")?
  inspect(of([1, 2, 3]).subset(of([10, 11, 12, 13, 14])), content="false")?
}

test "diff" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  inspect(empty.diff(of([1, 2, 3])), content="ImmutableSet::[]")?
  inspect(of([1, 2, 3]).diff(empty), content="ImmutableSet::[1, 2, 3]")?
  inspect(of([1, 2, 3]).diff(of([4, 5, 1])), content="ImmutableSet::[2, 3]")?
  inspect(of([1, 2, 3]).diff(of([1, 2, 3])), content="ImmutableSet::[]")?
}

test "inter" {
  inspect(of([3, 4, 5]).inter(of([4, 5, 6])), content="ImmutableSet::[4, 5]")?
  inspect(of([3, 4]).inter(of([5, 6])), content="ImmutableSet::[]")?
}

test "union" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  inspect(empty.union(of([4, 5, 6])), content="ImmutableSet::[4, 5, 6]")?
  inspect(of([4, 5, 6]).union(empty), content="ImmutableSet::[4, 5, 6]")?
  inspect(of([3]).union(of([4, 5, 6])), content="ImmutableSet::[3, 4, 5, 6]")?
  inspect(of([3, 4, 5]).union(of([6])), content="ImmutableSet::[3, 4, 5, 6]")?
  inspect(
    of([3, 4, 5]).union(of([4, 5, 6])),
    content="ImmutableSet::[3, 4, 5, 6]",
  )?
}

test "map" {
  inspect(
    of([1, 2, 3, 4, 5]).map(fn(x) { x * 2 }),
    content="ImmutableSet::[2, 4, 6, 8, 10]",
  )?
}

test "all" {
  inspect(of([2, 4, 6]).all(fn(v) { v % 2 == 0 }), content="true")?
  inspect(of([1, 3, 5]).all(fn(v) { v % 2 == 0 }), content="false")?
}

test "any" {
  inspect(of([1, 4, 3]).any(fn(v) { v % 2 == 0 }), content="true")?
  inspect(of([1, 5, 3]).any(fn(v) { v % 2 == 0 }), content="false")?
}

test "fold" {
  inspect(
    of([1, 2, 3, 4, 5]).fold(init=0, fn(acc, x) { acc + x }),
    content="15",
  )?
}

test "filter" {
  inspect(
    of([1, 2, 3, 4, 5, 6]).filter(fn(v) { v % 2 == 0 }),
    content="ImmutableSet::[2, 4, 6]",
  )?
}

test "split" {
  let (left, present, right) = of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(5)
  inspect(present, content="true")?
  inspect(left, content="ImmutableSet::[1, 2, 3, 4]")?
  inspect(right, content="ImmutableSet::[6, 7, 8, 9]")?
  let (left, present, right) = of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(0)
  inspect(present, content="false")?
  inspect(left, content="ImmutableSet::[]")?
  inspect(right, content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
}

test "contain" {
  inspect(of([7, 2, 9, 4, 6, 3, 8, 1]).add(5).contains(5), content="true")?
  inspect(of([7, 2, 9, 4, 6, 3, 8, 1]).contains(5), content="false")?
}

test "to_array" {
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]).to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "from_fixed_array" {
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "from_array" {
  inspect(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1], content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
}

test "remove_min" {
  inspect(of([3, 4, 5]).remove_min(), content="ImmutableSet::[4, 5]")?
}

test "add" {
  inspect(
    of([7, 2, 9, 4, 6, 3, 8, 1]).add(5),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
  inspect(of([2]).add(1), content="ImmutableSet::[1, 2]")?
  inspect(of([2]).add(3), content="ImmutableSet::[2, 3]")?
  inspect(of([2]).add(1).add(3), content="ImmutableSet::[1, 2, 3]")?
  inspect(of([1, 2]).add(1), content="ImmutableSet::[1, 2]")?
  inspect(of([2, 3]).add(3), content="ImmutableSet::[2, 3]")?
  inspect(of([1, 2, 3]).add(1), content="ImmutableSet::[1, 2, 3]")?
  inspect(of([1, 2, 3]).add(3), content="ImmutableSet::[1, 2, 3]")?
  inspect(of([1]).add(2).add(2), content="ImmutableSet::[1, 2]")?
}

test "remove" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  inspect(empty.remove(1), content="ImmutableSet::[]")?
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(1),
    content="ImmutableSet::[2, 3, 4, 5, 6, 7, 8, 9]",
  )?
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(9),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8]",
  )?
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(8),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 9]",
  )?
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(0),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]).remove(10),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "min" {
  inspect(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).min(), content="1")?
}

test "min_option" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  inspect(empty.min_option(), content="None")?
  inspect(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).min_option(), content="Some(1)")?
}

test "max" {
  inspect(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).max(), content="9")?
}

test "max_option" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  inspect(empty.max_option(), content="None")?
  inspect(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).max_option(), content="Some(9)")?
}

test "is_empty" {
  inspect((of([]) : ImmutableSet[Int]).is_empty(), content="true")?
  inspect(of([1]).is_empty(), content="false")?
}

test "to_string" {
  inspect(of([1, 2, 3, 4, 5]), content="ImmutableSet::[1, 2, 3, 4, 5]")?
  inspect((of([]) : ImmutableSet[Int]), content="ImmutableSet::[]")?
}

test "iter" {
  let mut s = ""
  of([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(fn(x) { s += x.to_string() })
  inspect(s, content="123456789")?
  let empty : ImmutableSet[Int] = of([])
  s = ""
  empty.each(fn(x) { s += x.to_string() })
  inspect(s, content="")?
}

test "split_bis" {
  inspect(of([1, 2, 3]).split_bis(1), content="Found")?
  inspect(of([1, 2, 3]).split_bis(3), content="Found")?
  inspect(of([1, 2, 3]).split_bis(0), content="NotFound")?
  inspect(of([1, 2, 3]).split_bis(4), content="NotFound")?
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

//   sub(array.length(), array[..]).0
// }

test "panic remove_min on empty set" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  empty.remove_min() |> ignore
}

test "panic min on empty set" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  empty.min() |> ignore
}

test "panic max on empty set" {
  let empty : ImmutableSet[Int] = ImmutableSet::new()
  empty.max() |> ignore
}

test "split with value not in set" {
  let set = of([1, 2, 3, 4, 5])
  let (left, present, right) = set.split(6)
  inspect(present, content="false")?
  inspect(left, content="ImmutableSet::[1, 2, 3, 4, 5]")?
  inspect(right, content="ImmutableSet::[]")?
}

test "remove_min on non-empty set" {
  let set = of([3, 4, 5])
  let new_set = set.remove_min()
  inspect(new_set, content="ImmutableSet::[4, 5]")?
}

test "min on non-empty set" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let min_value = set.min()
  inspect(min_value, content="1")?
}

test "max on non-empty set" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let max_value = set.max()
  inspect(max_value, content="9")?
}

test "union with different heights" {
  let set1 = of([3, 4, 5])
  let set2 = of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect(union_set, content="ImmutableSet::[3, 4, 5, 6]")?
}

test "disjoint with different sets" {
  let set1 = of([1, 2, 3])
  let set2 = of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect(disjoint, content="true")?
}

test "balance with left height greater" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5])
  let balanced_set = balance(left, value, right)
  inspect(balanced_set, content="ImmutableSet::[1, 2, 3, 4, 5]")?
}

test "balance with right height greater" {
  let left = of([1])
  let value = 2
  let right = of([3, 4, 5])
  let balanced_set = balance(left, value, right)
  inspect(balanced_set, content="ImmutableSet::[1, 2, 3, 4, 5]")?
}

test "join with different heights" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5, 6, 7])
  let joined_set = join(left, value, right)
  inspect(joined_set, content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7]")?
}

test "union with different heights" {
  let set1 = of([3, 4, 5])
  let set2 = of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect(union_set, content="ImmutableSet::[3, 4, 5, 6]")?
}

test "disjoint with different sets" {
  let set1 = of([1, 2, 3])
  let set2 = of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect(disjoint, content="true")?
}

test "balance with left height greater" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5])
  let balanced_set = balance(left, value, right)
  inspect(balanced_set, content="ImmutableSet::[1, 2, 3, 4, 5]")?
}

test "balance with right height greater" {
  let left = of([1])
  let value = 2
  let right = of([3, 4, 5])
  let balanced_set = balance(left, value, right)
  inspect(balanced_set, content="ImmutableSet::[1, 2, 3, 4, 5]")?
}

test "join with different heights" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5, 6, 7])
  let joined_set = join(left, value, right)
  inspect(joined_set, content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7]")?
}

test "union with different heights" {
  let set1 = of([3, 4, 5])
  let set2 = of([4, 5, 6])
  let union_set = set1.union(set2)
  inspect(union_set, content="ImmutableSet::[3, 4, 5, 6]")?
}

test "disjoint with different sets" {
  let set1 = of([1, 2, 3])
  let set2 = of([4, 5, 6])
  let disjoint = set1.disjoint(set2)
  inspect(disjoint, content="true")?
}

test "balance with left height greater" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5])
  let balanced_set = balance(left, value, right)
  inspect(balanced_set, content="ImmutableSet::[1, 2, 3, 4, 5]")?
}

test "balance with right height greater" {
  let left = of([1])
  let value = 2
  let right = of([3, 4, 5])
  let balanced_set = balance(left, value, right)
  inspect(balanced_set, content="ImmutableSet::[1, 2, 3, 4, 5]")?
}

test "join with different heights" {
  let left = of([1, 2, 3])
  let value = 4
  let right = of([5, 6, 7])
  let joined_set = join(left, value, right)
  inspect(joined_set, content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7]")?
}
