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

test "disjoint" {
  inspect(
    ImmutableSet::[1, 2, 3].disjoint(ImmutableSet::[4, 5, 6]),
    content="true",
  )?
  inspect(
    ImmutableSet::[1, 2, 3].subset(ImmutableSet::[3, 4, 5]),
    content="false",
  )?
}

test "subset" {
  inspect(
    ImmutableSet::[1, 2, 3].subset(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="true",
  )?
  inspect(
    ImmutableSet::[1, 2, 3].subset(ImmutableSet::[10, 11, 12, 13, 14]),
    content="false",
  )?
}

test "diff" {
  inspect(
    ImmutableSet::[1, 2, 3].diff(ImmutableSet::[4, 5, 1]),
    content="ImmutableSet::[2, 3]",
  )?
}

test "inter" {
  inspect(
    ImmutableSet::[3, 4, 5].inter(ImmutableSet::[4, 5, 6]),
    content="ImmutableSet::[4, 5]",
  )?
}

test "union" {
  inspect(
    ImmutableSet::[3, 4, 5].union(ImmutableSet::[4, 5, 6]),
    content="ImmutableSet::[3, 4, 5, 6]",
  )?
}

test "map" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5].map(fn(x) { x * 2 }),
    content="ImmutableSet::[2, 4, 6, 8, 10]",
  )?
}

test "forall" {
  inspect(ImmutableSet::[2, 4, 6].forall(fn(v) { v % 2 == 0 }), content="true")?
  inspect(ImmutableSet::[1, 3, 5].forall(fn(v) { v % 2 == 0 }), content="false")?
}

test "exists" {
  inspect(ImmutableSet::[1, 4, 3].exists(fn(v) { v % 2 == 0 }), content="true")?
  inspect(ImmutableSet::[1, 5, 3].exists(fn(v) { v % 2 == 0 }), content="false")?
}

test "fold" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5].fold(init=0, fn(acc, x) { acc + x }),
    content="15",
  )?
}

test "filter" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5, 6].filter(fn(v) { v % 2 == 0 }),
    content="ImmutableSet::[2, 4, 6]",
  )?
}

test "max" {
  inspect(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].max(), content="9")?
}

test "split" {
  let (left, present, right) = ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].split(
    5,
  )
  inspect(present, content="true")?
  inspect(left, content="ImmutableSet::[1, 2, 3, 4]")?
  inspect(right, content="ImmutableSet::[6, 7, 8, 9]")?
  let (left, present, right) = ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].split(
    0,
  )
  inspect(present, content="false")?
  inspect(left, content="ImmutableSet::[]")?
  inspect(right, content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]")?
}

test "contain" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 6, 3, 8, 1].add(5).contain(5),
    content="true",
  )?
  inspect(ImmutableSet::[7, 2, 9, 4, 6, 3, 8, 1].contain(5), content="false")?
}

test "from_list" {
  inspect(ImmutableSet::from_list(List::[1]), content="ImmutableSet::[1]")?
  inspect(ImmutableSet::from_list(List::[1, 2]), content="ImmutableSet::[1, 2]")?
  inspect(
    ImmutableSet::from_list(List::[1, 2, 3]),
    content="ImmutableSet::[1, 2, 3]",
  )?
  inspect(
    ImmutableSet::from_list(List::[1, 2, 3, 4]),
    content="ImmutableSet::[1, 2, 3, 4]",
  )?
  inspect(
    ImmutableSet::from_list(List::[7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_list" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_array" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "to_vec" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_vec(),
    content="Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "from_array" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1],
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
}

test "remove_min" {
  inspect(ImmutableSet::[3, 4, 5].remove_min(), content="ImmutableSet::[4, 5]")?
}

test "add" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 6, 3, 8, 1].add(5),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
  inspect(ImmutableSet::[2].add(1), content="ImmutableSet::[1, 2]")?
  inspect(ImmutableSet::[2].add(3), content="ImmutableSet::[2, 3]")?
  inspect(ImmutableSet::[2].add(1).add(3), content="ImmutableSet::[1, 2, 3]")?
  inspect(ImmutableSet::[1, 2].add(1), content="ImmutableSet::[1, 2]")?
  inspect(ImmutableSet::[2, 3].add(3), content="ImmutableSet::[2, 3]")?
  inspect(ImmutableSet::[1, 2, 3].add(1), content="ImmutableSet::[1, 2, 3]")?
  inspect(ImmutableSet::[1, 2, 3].add(3), content="ImmutableSet::[1, 2, 3]")?
  inspect(ImmutableSet::[1].add(2).add(2), content="ImmutableSet::[1, 2]")?
}

test "remove" {
  inspect(
    ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].remove(8),
    content="ImmutableSet::[1, 2, 3, 4, 5, 6, 7, 9]",
  )?
}

test "min" {
  inspect(ImmutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].min(), content="1")?
}

test "is_empty" {
  inspect((ImmutableSet::[] : ImmutableSet[Int]).is_empty(), content="true")?
  inspect(ImmutableSet::[1].is_empty(), content="false")?
}

test "to_string" {
  inspect(
    ImmutableSet::[1, 2, 3, 4, 5],
    content="ImmutableSet::[1, 2, 3, 4, 5]",
  )?
  inspect((ImmutableSet::[] : ImmutableSet[Int]), content="ImmutableSet::[]")?
}