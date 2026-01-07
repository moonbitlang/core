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
let default_init_capacity = 8

///|
test "new_with_capacity_then_add " {
  let set : @hashset.HashSet[(String, String)] = @hashset.new(capacity=20)
  set.add(("None", "Hash"))
  inspect(
    set,
    content=(
      #|@hashset.from_array([("None", "Hash")])
    ),
  )
}

///|
test "to_array" {
  let v = @hashset.from_array([1, 2, 3, 4])
  let arr = v.to_array()
  arr.sort()
  inspect(arr, content="[1, 2, 3, 4]")
}

///|
test "add_and_check" {
  let set : @hashset.HashSet[String] = @hashset.new()
  inspect(set.add_and_check("key"), content="true") // First insertion
  inspect(set.add_and_check("key"), content="false") // Already exists
  inspect(set.length(), content="1")
}

///|
test "remove_and_check" {
  let set = @hashset.from_array(["a", "b"])
  inspect(set.remove_and_check("a"), content="true") // Successfully removed
  inspect(set.remove_and_check("a"), content="false") // Already removed
  inspect(set.length(), content="1")
}

///|
test "copy" {
  let set = @hashset.from_array(["a", "b", "c"])
  let copied = set.copy()
  inspect(copied.length(), content="3")
  inspect(copied.contains("a"), content="true")
  inspect(copied.contains("b"), content="true")
  inspect(copied.contains("c"), content="true")
  // Modify original, copy should be unaffected
  set.remove("a")
  inspect(set.length(), content="2")
  inspect(copied.length(), content="3")
}

///|
test "to_json" {
  let data = [1, 2, 3]
  let set = @hashset.from_array([1, 2, 3])
  let json = set.to_json()
  guard json is Array(array) else { fail("Expected JSON array") }
  for item in data {
    assert_true(array.contains(item.to_json()))
  }
  assert_eq(array.length(), 3)
}

///|
test "new" {
  let m : @hashset.HashSet[Int] = @hashset.new()
  assert_eq(m.capacity(), default_init_capacity)
  inspect(m.length(), content="0")
}

///|
test "new with zero capacity grows on insert" {
  let m : @hashset.HashSet[Int] = @hashset.new(capacity=0)
  m.add(1)
  assert_true(m.contains(1))
  assert_true(m.capacity() > 0)
}

///|
test "default" {
  let m : @hashset.HashSet[Int] = Default::default()
  inspect(m.length(), content="0")
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
test "of" {
  let m = @hashset.from_array(["a", "b", "c"])
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
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
test "size" {
  let m = @hashset.new()
  inspect(m.length(), content="0")
  m.add("a")
  inspect(m.length(), content="1")
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
  let m = @hashset.from_array(["a", "b", "c"]).iter().collect()
  m.sort()
  inspect(
    m,
    content=(
      #|["a", "b", "c"]
    ),
  )
}

///|
test "iteri" {
  let m = @hashset.from_array(["1", "2", "3"])
  let s = []
  let mut sum = 0
  m.eachi((i, k) => {
    sum += i
    s.push(k)
  })
  s.sort()
  inspect(
    s,
    content=(
      #|["1", "2", "3"]
    ),
  )
  inspect(sum, content="3")
}

///|
test "union" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.union(m2)
  inspect(m.length(), content="4")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "intersection" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.intersection(m2)
  inspect(m.length(), content="2")
  assert_false(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "difference" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.difference(m2)
  inspect(m.length(), content="1")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "symmetric_difference" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.symmetric_difference(m2)
  inspect(m.length(), content="2")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "is_disjoint" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  inspect(m1.is_disjoint(m2), content="false")
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["e", "f", "g"])
  inspect(m1.is_disjoint(m2), content="true")
}

///|
test "is_subset" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  inspect(m1.is_subset(m2), content="false")
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["a", "b", "c", "d"])
  inspect(m1.is_subset(m2), content="true")
}

///|
test "is_superset" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  inspect(m1.is_superset(m2), content="false")
  let m1 = @hashset.from_array(["a", "b", "c", "d"])
  let m2 = @hashset.from_array(["a", "b", "c"])
  inspect(m1.is_superset(m2), content="true")
}

///|
test "land" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 & m2
  inspect(m.length(), content="2")
  assert_false(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "lor" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 | m2
  inspect(m.length(), content="4")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "lxor" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 ^ m2
  inspect(m.length(), content="2")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "sub" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 - m2
  inspect(m.length(), content="1")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "insert_and_grow" {
  let m = @hashset.new()
  for i in 0..<10 {
    m.add(i.to_string())
  }
  inspect(m.length(), content="10")
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
  inspect(m.length(), content="0")
  m.add("a")
  inspect(m.length(), content="1")
}

///|
test "clear_and_reinsert" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.clear()
  inspect(m.length(), content="0")
  m.add("c")
  inspect(m.length(), content="1")
  assert_true(m.contains("c"))
}

///|
test "from_iter multiple elements iter" {
  let array = @hashset.from_iter([1, 2, 3].iter()).to_array()
  array.sort()
  inspect(array, content="[1, 2, 3]")
}

///|
test "from_iter single element iter" {
  inspect(@hashset.from_iter([1].iter()), content="@hashset.from_array([1])")
}

///|
test "from_iter empty iter" {
  let map : @hashset.HashSet[Int] = @hashset.from_iter(Iter::empty())
  inspect(map, content="@hashset.from_array([])")
}

///|
test "hashset arbitrary" {
  let samples : Array[@hashset.HashSet[Int]] = @quickcheck.samples(20)
  let cases = [
    @hashset.from_array([]),
    @hashset.from_array([]),
    @hashset.from_array([]),
    @hashset.from_array([0]),
    @hashset.from_array([0]),
    @hashset.from_array([]),
    @hashset.from_array([]),
    @hashset.from_array([0]),
    @hashset.from_array([0]),
    @hashset.from_array([0, 3, 1, 2]),
    @hashset.from_array([0, 1, -2]),
    @hashset.from_array([-2, 0, -1]),
    @hashset.from_array([-5, 0, 8, 4, -2]),
    @hashset.from_array([0, 2, -1]),
    @hashset.from_array([0]),
    @hashset.from_array([]),
    @hashset.from_array([-2, 0, -3, -1]),
    @hashset.from_array([-1, 0, 3, 1, -6, 2]),
    @hashset.from_array([0]),
    @hashset.from_array([-5, -1, 6, 0, 2, -2]),
  ]
  for i = 0; i < 20; i = i + 1 {
    assert_true(samples[i].symmetric_difference(cases[i]).is_empty())
  }
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
  inspect(set.to_array()..sort().to_string(), content="[1, 2, 3, 4]")
}
