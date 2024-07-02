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

test "add to empty set" {
  let set = new()
  set.add(1)
  @test.eq(set.contains(1), true)!
  inspect(set.debug_tree(), content="([1]1,_,_)")!
}

test "add to non-empty set" {
  let set = new()
  set.add(1)
  set.add(2)
  @test.eq(set.contains(1), true)!
  @test.eq(set.contains(2), true)!
  inspect(set.debug_tree(), content="([2]1,_,([1]2,_,_))")!
}

test "add duplicate value" {
  let set = new()
  set.add(1)
  set.add(1)
  @test.eq(set.contains(1), true)!
  @test.eq(set.size(), 1L)!
  inspect(set.debug_tree(), content="([1]1,_,_)")!
}

test "add multiple values" {
  let set = new()
  set.add(1)
  set.add(2)
  set.add(3)
  @test.eq(set.contains(1), true)!
  @test.eq(set.contains(2), true)!
  @test.eq(set.contains(3), true)!
  @test.eq(set.size(), 3L)!
  inspect(set.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")!
}

test "add_and_remove" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  set.remove(8)
  inspect(set, content="{1, 2, 3, 4, 5, 6, 7, 9}")!
  inspect(
    set.debug_tree(),
    content="([4]5,([3]3,([2]2,([1]1,_,_),_),([1]4,_,_)),([2]7,([1]6,_,_),([1]9,_,_)))",
  )!
  let set = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

  // Test 1: Remove elements
  set.remove(1)
  inspect(set, content="{2, 3, 4, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]4,([2]2,_,([1]3,_,_)),([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]9,_,([1]10,_,_))))",
  )!
  set.remove(5)
  inspect(set, content="{2, 3, 4, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]4,([2]2,_,([1]3,_,_)),([3]8,([2]6,_,([1]7,_,_)),([2]9,_,([1]10,_,_))))",
  )!
  set.remove(10)
  inspect(set, content="{2, 3, 4, 6, 7, 8, 9}")!
  inspect(
    set.debug_tree(),
    content="([4]4,([2]2,_,([1]3,_,_)),([3]8,([2]6,_,([1]7,_,_)),([1]9,_,_)))",
  )!
  set.remove(4)
  inspect(set, content="{2, 3, 6, 7, 8, 9}")!
  inspect(
    set.debug_tree(),
    content="([3]6,([2]2,_,([1]3,_,_)),([2]8,([1]7,_,_),([1]9,_,_)))",
  )!

  // Test 2: Add elements
  set.add(1)
  inspect(set, content="{1, 2, 3, 6, 7, 8, 9}")!
  inspect(
    set.debug_tree(),
    content="([3]6,([2]2,([1]1,_,_),([1]3,_,_)),([2]8,([1]7,_,_),([1]9,_,_)))",
  )!
  set.add(5)
  inspect(set, content="{1, 2, 3, 5, 6, 7, 8, 9}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]3,_,([1]5,_,_))),([2]8,([1]7,_,_),([1]9,_,_)))",
  )!
  set.add(10)
  inspect(set, content="{1, 2, 3, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]3,_,([1]5,_,_))),([3]8,([1]7,_,_),([2]9,_,([1]10,_,_))))",
  )!
  set.add(4)
  inspect(set, content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]4,([1]3,_,_),([1]5,_,_))),([3]8,([1]7,_,_),([2]9,_,([1]10,_,_))))",
  )!

  // Test 3: Add and remove the same element
  set.add(11)
  inspect(set, content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]4,([1]3,_,_),([1]5,_,_))),([3]8,([1]7,_,_),([2]10,([1]9,_,_),([1]11,_,_))))",
  )!
  set.remove(11)
  inspect(set, content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([3]2,([1]1,_,_),([2]4,([1]3,_,_),([1]5,_,_))),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )!

  // Test 4: Remove an element that doesn't exist
  set.remove(12)
  inspect(set, content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}")!

  // Test 5: Add an element that already exists
  set.add(10)
  inspect(set, content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}")!

  // Test 6: Remove all elements
  set.remove(1)
  inspect(set, content="{2, 3, 4, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([3]4,([2]2,_,([1]3,_,_)),([1]5,_,_)),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )!
  set.remove(2)
  inspect(set, content="{3, 4, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([2]4,([1]3,_,_),([1]5,_,_)),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )!
  set.remove(3)
  inspect(set, content="{4, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([4]6,([2]4,_,([1]5,_,_)),([3]8,([1]7,_,_),([2]10,([1]9,_,_),_)))",
  )!
  set.remove(4)
  inspect(set, content="{5, 6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]10,([1]9,_,_),_))",
  )!
  set.remove(5)
  inspect(set, content="{6, 7, 8, 9, 10}")!
  inspect(
    set.debug_tree(),
    content="([3]8,([2]6,_,([1]7,_,_)),([2]10,([1]9,_,_),_))",
  )!
  set.remove(6)
  inspect(set, content="{7, 8, 9, 10}")!
  inspect(set.debug_tree(), content="([3]8,([1]7,_,_),([2]10,([1]9,_,_),_))")!
  set.remove(7)
  inspect(set, content="{8, 9, 10}")!
  inspect(set.debug_tree(), content="([2]9,([1]8,_,_),([1]10,_,_))")!
  set.remove(8)
  inspect(set, content="{9, 10}")!
  inspect(set.debug_tree(), content="([2]9,_,([1]10,_,_))")!
  set.remove(9)
  inspect(set, content="{10}")!
  inspect(set.debug_tree(), content="([1]10,_,_)")!
  set.remove(10)
  inspect(set, content="{}")!
  inspect(set.debug_tree(), content="_")!
  let set = of([7, 2, 9, 4, 5, 6, 3, 1])
  set.remove(3)
  inspect(set, content="{1, 2, 4, 5, 6, 7, 9}")!
  inspect(
    set.debug_tree(),
    content="([3]5,([2]2,([1]1,_,_),([1]4,_,_)),([2]7,([1]6,_,_),([1]9,_,_)))",
  )!
  set.remove(2)
  inspect(set, content="{1, 4, 5, 6, 7, 9}")!
  inspect(
    set.debug_tree(),
    content="([3]5,([2]4,([1]1,_,_),_),([2]7,([1]6,_,_),([1]9,_,_)))",
  )!
  set.remove(5)
  inspect(set, content="{1, 4, 6, 7, 9}")!
  inspect(
    set.debug_tree(),
    content="([3]6,([2]4,([1]1,_,_),_),([2]7,_,([1]9,_,_)))",
  )!
  set.remove(9)
  inspect(set, content="{1, 4, 6, 7}")!
  inspect(set.debug_tree(), content="([3]6,([2]4,([1]1,_,_),_),([1]7,_,_))")!
  set.remove(1)
  inspect(set, content="{4, 6, 7}")!
  inspect(set.debug_tree(), content="([2]6,([1]4,_,_),([1]7,_,_))")!
  set.remove(7)
  inspect(set, content="{4, 6}")!
  inspect(set.debug_tree(), content="([2]6,([1]4,_,_),_)")!
  set.remove(4)
  inspect(set, content="{6}")!
  inspect(set.debug_tree(), content="([1]6,_,_)")!
  set.remove(6)
  inspect(set, content="{}")!
  inspect(set.debug_tree(), content="_")!
}

test "remove on empty set" {
  let set : T[Int] = new()
  set.remove(0)
  inspect(set.size, content="0")!
}

test "join" {
  let l = of([13, 8, 17, 1, 11, 15, 25, 6])
  let r = of([27, 28, 40, 35, 33])
  inspect(
    join(l.root, 26, r.root),
    content="{1, 6, 8, 11, 13, 15, 17, 25, 26, 27, 28, 33, 35, 40}",
  )!
  let l = of([3, 2, 5, 1, 4])
  let r = of([7])
  inspect(join(l.root, 6, r.root), content="{1, 2, 3, 4, 5, 6, 7}")!
  let l = of([3, 2, 5, 1, 4])
  let r = of([])
  inspect(join(l.root, 6, r.root), content="{1, 2, 3, 4, 5, 6}")!
  let l = of([])
  let r = of([])
  inspect(join(l.root, 6, r.root), content="{6}")!
  let l = of([])
  let r = of([7, 8, 9, 10, 11, 12])
  inspect(join(l.root, 6, r.root), content="{6, 7, 8, 9, 10, 11, 12}")!
}

test "split" {
  let (l, r) = split(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 5)
  inspect(l, content="Some({1, 2, 3, 4})")!
  inspect(r, content="Some({6, 7, 8, 9})")!
  let (l, r) = split(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 0)
  inspect(l, content="None")!
  inspect(r, content="Some({1, 2, 3, 4, 5, 6, 7, 8, 9})")!
  let (l, r) = split(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 10)
  inspect(l, content="Some({1, 2, 3, 4, 5, 6, 7, 8, 9})")!
  inspect(r, content="None")!
  let (l, r) = split(of([7, 2, 9, 4, 5, 6, 3, 8, 1]).root, 4)
  inspect(l, content="Some({1, 2, 3})")!
  inspect(r, content="Some({5, 6, 7, 8, 9})")!
  let (l, r) = split(of([]).root, 7)
  inspect(l, content="None")!
  inspect(r, content="None")!
  let (l, r) = split(
    of(
      [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
        40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58,
        59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77,
        78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96,
        97, 98, 99, 100,
      ],
    ).root,
    50,
  )
  inspect(
    l,
    content="Some({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49})",
  )!
  inspect(
    r,
    content="Some({51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100})",
  )!
}

test "union" {
  // Test 1: Union of two sets with no common elements
  let set1 = of([1, 2, 3])
  let set2 = of([4, 5, 6])
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3, 4, 5, 6}")!
  inspect(
    set3.debug_tree(),
    content="([3]3,([2]2,([1]1,_,_),_),([2]5,([1]4,_,_),([1]6,_,_)))",
  )!

  // Test 2: Union of two sets with some common elements
  let set1 = of([1, 2, 3])
  let set2 = of([2, 3, 4])
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3, 4}")!
  inspect(set3.debug_tree(), content="([3]2,([1]1,_,_),([2]3,_,([1]4,_,_)))")!

  // Test 3: Union of two sets where one is a subset of the other
  let set1 = of([1, 2, 3])
  let set2 = of([2, 3])
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3}")!
  inspect(set3.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")!

  // Test 4: Union of two empty sets
  let set1 : T[Int] = new()
  let set2 = new()
  let set3 = set1.union(set2)
  inspect(set3, content="{}")!
  inspect(set3.debug_tree(), content="_")!

  // Test 5: Union of an empty set with a non-empty set
  let set1 = of([1, 2, 3])
  let set2 = of([])
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3}")!
  inspect(set3.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")!
  let set1 = of([])
  let set2 = of([1, 2, 3])
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3}")!
  inspect(set3.debug_tree(), content="([2]2,([1]1,_,_),([1]3,_,_))")!

  // Test 6: Union of two large sets with no common elements
  let set1 = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = of([11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
  let set3 = set1.union(set2)
  inspect(
    set3,
    content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}",
  )!
  inspect(
    set3.debug_tree(),
    content="([5]14,([4]8,([3]4,([2]2,([1]1,_,_),([1]3,_,_)),([2]6,([1]5,_,_),([1]7,_,_))),([3]12,([2]10,([1]9,_,_),([1]11,_,_)),([1]13,_,_))),([3]18,([2]16,([1]15,_,_),([1]17,_,_)),([2]19,_,([1]20,_,_))))",
  )!

  // Test 7: Union of two large sets with some common elements
  let set1 = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = of([6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}")!
  inspect(
    set3.debug_tree(),
    content="([5]11,([4]4,([2]2,([1]1,_,_),([1]3,_,_)),([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]9,_,([1]10,_,_)))),([3]13,([1]12,_,_),([2]14,_,([1]15,_,_))))",
  )!

  // Test 8: Union of two large sets where one is a subset of the other
  let set1 = of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let set2 = of([6, 7, 8, 9, 10])
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}")!
  inspect(
    set3.debug_tree(),
    content="([4]4,([2]2,([1]1,_,_),([1]3,_,_)),([3]8,([2]6,([1]5,_,_),([1]7,_,_)),([2]9,_,([1]10,_,_))))",
  )!
}

test "disjoint" {
  inspect(of([1, 2, 3]).disjoint(of([4, 5, 6])), content="true")!
  inspect(of([1, 2, 3]).subset(of([3, 4, 5])), content="false")!
}

test "subset" {
  inspect(of([1, 2, 3]).subset(of([7, 2, 9, 4, 5, 6, 3, 8, 1])), content="true")!
  inspect(of([1, 2, 3]).subset(of([10, 11, 12, 13, 14])), content="false")!
}

test "diff" {
  inspect(of([1, 2, 3]).diff(of([4, 5, 1])), content="{2, 3}")!
}

test "intersect" {
  inspect(of([3, 4, 5]).intersect(of([4, 5, 6])), content="{4, 5}")!
}

test "each" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let result = Buffer::new(size_hint=10)
  set.each(fn(x) { result.write_string(x.to_string()) })
  inspect(result.to_string(), content="123456789")!
  let set : T[Int] = new()
  set.each(fn(_x) { abort("Impossible to reach") })
}

test "eachi" {
  let set = of([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let result = Buffer::new(size_hint=10)
  set.eachi(fn(i, x) { result.write_string("[\(i)-\(x)]") })
  inspect(
    result.to_string(),
    content="[0-1][1-2][2-3][3-4][4-5][5-6][6-7][7-8][8-9]",
  )!
}

test "iter" {
  let set = of([3, 2, 1])
  inspect(set.iter().collect(), content="[1, 2, 3]")!
  inspect(set.iter().take(2).collect(), content="[1, 2]")!
}

test "contains" {
  let set = of([7, 2, 9, 4, 6, 3, 8, 1])
  inspect(set.contains(5), content="false")!
  set.add(5)
  inspect(set.contains(5), content="true")!
  inspect(of([7, 2, 9, 4, 6, 3, 8, 1]).contains(5), content="false")!
  inspect(of([]).contains(1), content="false")!
}

test "to_array" {
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]).to_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )!
  inspect((of([]) : T[Int]).to_array(), content="[]")!
}

test "to_string" {
  inspect(of([1, 2, 3, 4, 5]), content="{1, 2, 3, 4, 5}")!
  inspect((of([]) : T[Int]), content="{}")!
}

test "from_array" {
  inspect(
    of([7, 2, 9, 4, 5, 6, 3, 8, 1]),
    content="{1, 2, 3, 4, 5, 6, 7, 8, 9}",
  )!
}

test "is_empty" {
  inspect((of([]) : T[Int]).is_empty(), content="true")!
  inspect(of([1]).is_empty(), content="false")!
}

test "size" {
  inspect(of([1, 2, 3, 4, 5]).size(), content="5")!
  inspect(of([1]).size(), content="1")!
  inspect((of([]) : T[Int]).size(), content="0")!
}

test "singleton" {
  inspect(singleton(1).size(), content="1")!
  inspect(singleton(1).contains(1), content="true")!
  inspect(singleton(1).contains(2), content="false")!
}

test "deep_clone" {
  let set = of([1, 2, 3, 4, 5])
  let clone = set.deep_clone()
  inspect(clone, content="{1, 2, 3, 4, 5}")!
  inspect(set.debug_tree() == clone.debug_tree(), content="true")!
  let set : T[Int] = of([])
  let clone = set.deep_clone()
  inspect(clone, content="{}")!
  inspect(set.debug_tree() == clone.debug_tree(), content="true")!
}

test "debug_write" {
  let buf = Buffer::new(size_hint=100)
  let set = of([1, 2, 3, 4, 5])
  set.debug_write(buf)
  inspect(buf.to_string(), content="{1, 2, 3, 4, 5}")!
  let buf = Buffer::new(size_hint=100)
  let set : T[Int] = of([])
  set.debug_write(buf)
  inspect(buf.to_string(), content="{}")!
}

test "mix_everything" {
  // test all functions together, including add, remove, union, diff, inter, subset, disjoint, size, is_empty, contains
  let set1 = of([1, 2, 3, 4, 5])
  let set2 = of([4, 5, 6, 7, 8])
  set1.add(6)
  inspect(set1, content="{1, 2, 3, 4, 5, 6}")!
  set1.remove(6)
  inspect(set1, content="{1, 2, 3, 4, 5}")!
  let set3 = set1.union(set2)
  inspect(set3, content="{1, 2, 3, 4, 5, 6, 7, 8}")!
  let set4 = set1.diff(set2)
  inspect(set4, content="{1, 2, 3}")!
  let set5 = set1.intersect(set2)
  inspect(set5, content="{4, 5}")!
  inspect(set1.subset(set3), content="true")!
  set3.remove(3)
  inspect(set3, content="{1, 2, 4, 5, 6, 7, 8}")!
  inspect(set3.size(), content="7")!
  inspect(set3.is_empty(), content="false")!
  inspect(set3.contains(1), content="true")!
  inspect(set3.contains(3), content="false")!
  inspect(set3.disjoint(set1), content="false")!
  let set6 = set3.union(of([]))
  inspect(set6, content="{1, 2, 4, 5, 6, 7, 8}")!
  let set7 = set3.union(of([12, 13, 14, 33, 22]))
  inspect(set7, content="{1, 2, 4, 5, 6, 7, 8, 12, 13, 14, 22, 33}")!
  for i = 1; i <= 5; i = i + 1 {
    set7.remove(i)
  }
  inspect(set7, content="{6, 7, 8, 12, 13, 14, 22, 33}")!
  for i = 6; i <= 33; i = i + 1 {
    set7.remove(i)
  }
  let set = of(
    [
      90, 70, 13, 44, 11, 49, 39, 35, 52, 8, 80, 40, 58, 67, 84, 38, 93, 97, 54,
      95,
    ],
  )
  set.remove(70)
  inspect(
    set,
    content="{8, 11, 13, 35, 38, 39, 40, 44, 49, 52, 54, 58, 67, 80, 84, 90, 93, 95, 97}",
  )!
  set.remove(52)
  inspect(
    set,
    content="{8, 11, 13, 35, 38, 39, 40, 44, 49, 54, 58, 67, 80, 84, 90, 93, 95, 97}",
  )!
}

test "op_equal" {
  let a = of([1, 2, 3])
  let b = of([4, 5, 6])
  inspect(a == a, content="true")!
  inspect(b == b, content="true")!
  inspect(a == b, content="false")!
  inspect(b == a, content="false")!
}
