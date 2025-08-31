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

///|
let default_init_capacity = 8

///|
test "new_with_capacity_then_add " {
  let set : @hashset.HashSet[(String, String)] = @hashset.new(capacity=20)
  set.add(("None", "Hash"))
  inspect(
    set,
    content=(
      #|@hashset.of([("None", "Hash")])
    ),
  )
}

///|
test "to_array" {
  let v = @hashset.of([1, 2, 3, 4])
  let arr = v.to_array()
  arr.sort()
  inspect(arr, content="[1, 2, 3, 4]")
}

///|
test "add_and_check" {
  let set : @hashset.HashSet[String] = @hashset.new()
  inspect(set.add_and_check("key"), content="true") // First insertion
  inspect(set.add_and_check("key"), content="false") // Already exists
  inspect(set.size(), content="1")
}

///|
test "remove_and_check" {
  let set = @hashset.of(["a", "b"])
  inspect(set.remove_and_check("a"), content="true") // Successfully removed
  inspect(set.remove_and_check("a"), content="false") // Already removed
  inspect(set.size(), content="1")
}

///|
test "copy" {
  let set = @hashset.of(["a", "b", "c"])
  let copied = set.copy()
  inspect(copied.size(), content="3")
  inspect(copied.contains("a"), content="true")
  inspect(copied.contains("b"), content="true")
  inspect(copied.contains("c"), content="true")
  // Modify original, copy should be unaffected
  set.remove("a")
  inspect(set.size(), content="2")
  inspect(copied.size(), content="3")
}

///|
test "to_json" {
  let set = @hashset.of([1, 2, 3])
  @json.inspect(set, content=[3, 1, 2])
}

///|
test "new" {
  let m : @hashset.HashSet[Int] = @hashset.new()
  assert_eq(m.capacity(), default_init_capacity)
  inspect(m.size(), content="0")
}

///|
test "insert" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.add("c")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "from_array" {
  let m = @hashset.of(["a", "b", "c"])
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "size" {
  let m = @hashset.new()
  inspect(m.size(), content="0")
  m.add("a")
  inspect(m.size(), content="1")
}

///|
test "is_empty" {
  let m = @hashset.new()
  inspect(m.is_empty(), content="true")
  m.add("a")
  inspect(m.is_empty(), content="false")
  m.remove("a")
  inspect(m.is_empty(), content="true")
}

///|
test "iter" {
  let m = @hashset.of(["a", "b", "c"])
  let mut sum = ""
  m.each(k => sum += k)
  inspect(sum, content="cab")
}

///|
test "iteri" {
  let m = @hashset.of(["1", "2", "3"])
  let mut s = ""
  let mut sum = 0
  m.eachi((i, k) => {
    s += k
    sum += i
  })
  inspect(s, content="231")
  inspect(sum, content="3")
}

///|
test "union" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.union(m2)
  inspect(m.size(), content="4")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "intersection" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.intersection(m2)
  inspect(m.size(), content="2")
  assert_false(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "difference" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.difference(m2)
  inspect(m.size(), content="1")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "symmetric_difference" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.symmetric_difference(m2)
  inspect(m.size(), content="2")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "is_disjoint" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  inspect(m1.is_disjoint(m2), content="false")
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["e", "f", "g"])
  inspect(m1.is_disjoint(m2), content="true")
}

///|
test "is_subset" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  inspect(m1.is_subset(m2), content="false")
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["a", "b", "c", "d"])
  inspect(m1.is_subset(m2), content="true")
}

///|
test "is_superset" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  inspect(m1.is_superset(m2), content="false")
  let m1 = @hashset.of(["a", "b", "c", "d"])
  let m2 = @hashset.of(["a", "b", "c"])
  inspect(m1.is_superset(m2), content="true")
}

///|
test "land" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1 & m2
  inspect(m.size(), content="2")
  assert_false(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "lor" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1 | m2
  inspect(m.size(), content="4")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "lxor" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1 ^ m2
  inspect(m.size(), content="2")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "op_sub" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1 - m2
  inspect(m.size(), content="1")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let map = @hashset.of(["a", "b", "c"])
  map.iter().each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[c][a][b]")
  buf.reset()
  map.iter().take(2).each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[c][a]")
}

///|
test "from_array" {
  let arr = ["a", "b", "c"]
  let m = @hashset.from_array(arr)
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "insert_and_grow" {
  let m = @hashset.new()
  for i in 0..<10 {
    m.add(i.to_string())
  }
  inspect(m.size(), content="10")
  inspect(m.capacity(), content="16")
}

///|
test "remove_and_shift_back" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.add("c")
  m.add("d")
  m.remove("b")
  assert_false(m.contains("b"))
  assert_true(m.contains("a"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "capacity_and_size" {
  let m = @hashset.new()
  assert_eq(m.capacity(), default_init_capacity)
  inspect(m.size(), content="0")
  m.add("a")
  inspect(m.size(), content="1")
}

///|
test "clear_and_reinsert" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.clear()
  inspect(m.size(), content="0")
  m.add("c")
  inspect(m.size(), content="1")
  assert_true(m.contains("c"))
}

///|
test "insert_and_grow" {
  let m = @hashset.new()
  for i in 0..<10 {
    m.add(i.to_string())
  }
  inspect(m.size(), content="10")
  inspect(m.capacity(), content="16")
}

///|
test "remove_and_shift_back" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.add("c")
  m.add("d")
  m.remove("b")
  assert_false(m.contains("b"))
  assert_true(m.contains("a"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "capacity_and_size" {
  let m = @hashset.new()
  assert_eq(m.capacity(), default_init_capacity)
  inspect(m.size(), content="0")
  m.add("a")
  inspect(m.size(), content="1")
}

///|
test "clear_and_reinsert" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.clear()
  inspect(m.size(), content="0")
  m.add("c")
  inspect(m.size(), content="1")
  assert_true(m.contains("c"))
}

///|
test "from_iter multiple elements iter" {
  inspect(
    @hashset.from_iter([1, 2, 3].iter()),
    content="@hashset.of([3, 1, 2])",
  )
}

///|
test "from_iter single element iter" {
  inspect(@hashset.from_iter([1].iter()), content="@hashset.of([1])")
}

///|
test "from_iter empty iter" {
  let map : @hashset.HashSet[Int] = @hashset.from_iter(Iter::empty())
  inspect(map, content="@hashset.of([])")
}

///|
test "hashset arbitrary" {
  let samples : Array[@hashset.HashSet[Int]] = @quickcheck.samples(20)
  inspect(
    samples[5:10],
    content="[@hashset.of([]), @hashset.of([]), @hashset.of([0]), @hashset.of([0]), @hashset.of([0, 3, 1, 2])]",
  )
  inspect(
    samples[11:15],
    content="[@hashset.of([0, -2, -1]), @hashset.of([0, 4, -5, -2, 8]), @hashset.of([2, 0, -1]), @hashset.of([0])]",
  )
}

///|
test "@hashset.to_array/empty" {
  let set : @hashset.HashSet[Int] = @hashset.new()
  inspect(set.to_array(), content="[]")
}

///|
test "@hashset.to_array/single" {
  let set = @hashset.new()
  set.add(42)
  inspect(set.to_array(), content="[42]")
}

///|
test "@hashset.to_array/multiple" {
  let set = @hashset.new()
  set.add(1)
  set.add(2)
  set.add(3)
  set.add(4)
  inspect(set.to_array(), content="[3, 4, 1, 2]")
}
