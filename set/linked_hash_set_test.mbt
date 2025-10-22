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
test "new" {
  let m : @set.Set[Int] = @set.Set::new()
  assert_eq(m.capacity(), default_init_capacity)
  assert_eq(m.length(), 0)
}

///|
test "insert" {
  let m = @set.Set::new()
  m.add("a")
  m.add("b")
  m.add("c")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "add remove" {
  let m = @set.Set::new()
  m.add("a")
  m.add("b")
  m.add("c")
  if m.remove_and_check("a") {
    m.add("d")
  }
  assert_true(m.add_and_check("test"))
  assert_false(m.add_and_check("test"))
  assert_true(!m.contains("a") && m.contains("d"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "of" {
  let m = @set.Set::of(["a", "b", "c"])
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "from_array" {
  let arr = ["a", "b", "c"]
  let m = @set.Set::from_array(arr)
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "size" {
  let m = @set.Set::new()
  assert_eq(m.length(), 0)
  m.add("a")
  assert_eq(m.length(), 1)
}

///|
test "is_empty" {
  let m = @set.Set::new()
  assert_eq(m.is_empty(), true)
  m.add("a")
  assert_eq(m.is_empty(), false)
  m.remove("a")
  assert_eq(m.is_empty(), true)
}

///|
test "each" {
  let m = @set.Set::of(["a", "b", "c"])
  let mut sum = ""
  m.each(k => sum += k)
  inspect(sum, content="abc")
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let map = @set.Set::of(["a", "b", "c"])
  map.iter().each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[a][b][c]")
  buf.reset()
  map.iter().take(2).each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[a][b]")
}

///|
test "iteri" {
  let m = @set.Set::of(["1", "2", "3"])
  let mut s = ""
  let mut sum = 0
  m.eachi((i, k) => {
    s += k
    sum += i
  })
  inspect(s, content="123")
  inspect(sum, content="3")
}

///|
test "union" {
  let m1 = @set.Set::of(["a", "b", "c"])
  let m2 = @set.Set::of(["b", "c", "d"])
  let m = m1.union(m2)
  assert_eq(m.length(), 4)
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "intersection" {
  let m1 = @set.Set::of(["a", "b", "c"])
  let m2 = @set.Set::of(["b", "c", "d"])
  let m = m1.intersection(m2)
  assert_eq(m.length(), 2)
  assert_false(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "difference" {
  let m1 = @set.Set::of(["a", "b", "c"])
  let m2 = @set.Set::of(["b", "c", "d"])
  let m = m1.difference(m2)
  assert_eq(m.length(), 1)
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "symmetric_difference" {
  let m1 = @set.Set::of(["a", "b", "c"])
  let m2 = @set.Set::of(["b", "c", "d"])
  let m = m1.symmetric_difference(m2)
  assert_eq(m.length(), 2)
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "iterator" {
  let buf = StringBuilder::new(size_hint=20)
  let map = @set.Set::of(["a", "b", "c"])
  map.iterator().each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[a][b][c]")
  buf.reset()
  map.iterator().take(2).each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[a][b]")
}

///|
test "insert_and_grow" {
  let m = @set.Set::new()
  for i in 0..<10 {
    m.add(i.to_string())
  }
  assert_eq(m.length(), 10)
  assert_eq(m.capacity(), 16)
  @json.inspect(m, content=["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
}

///|
test "array unique via Set" {
  let v = [1, 2, 3, 4, 5, 3, 2, 4, 5]
  let h = @set.Set::from_iter(v.iter())
  let v = [..h]
  @json.inspect([..h], content=[1, 2, 3, 4, 5])
  @json.inspect(v, content=[1, 2, 3, 4, 5])
}

///|
test "remove_and_shift_back" {
  let m = @set.Set::new()
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
  let m = @set.Set::new()
  assert_eq(m.capacity(), default_init_capacity)
  assert_eq(m.length(), 0)
  m.add("a")
  assert_eq(m.length(), 1)
}

///|
test "clear_and_reinsert" {
  let m = @set.Set::new()
  m.add("a")
  m.add("b")
  m.clear()
  assert_eq(m.length(), 0)
  m.add("c")
  assert_eq(m.length(), 1)
  assert_true(m.contains("c"))
}

///|
test "from_iter multiple elements iter" {
  inspect(@set.Set::from_iter([1, 2, 3].iter()), content="{1, 2, 3}")
}

///|
test "from_iter single element iter" {
  inspect(@set.Set::from_iter([1].iter()), content="{1}")
}

///|
test "from_iter empty iter" {
  let map : @set.Set[Int] = @set.Set::from_iter(Iter::empty())
  inspect(map, content="{}")
}

///|
test "from_iterator multiple elements iter" {
  inspect(@set.Set::from_iterator([1, 2, 3].iterator()), content="{1, 2, 3}")
}

///|
test "from_iterator single element iter" {
  inspect(@set.Set::from_iterator([1].iterator()), content="{1}")
}

///|
test "from_iterator empty iter" {
  let map : @set.Set[Int] = @set.Set::from_iterator(Iterator::empty())
  inspect(map, content="{}")
}

///|
test "remove item causes break when psl < i" {
  let set = @set.Set::new()
  set
  ..add(1)
  ..add(11) // This goes to a different bucket due to hash collision
  ..remove(21) // Key doesn't exist, will cause psl < i and break
  assert_eq(set.length(), 2)
}

///|
test "to_array_empty" {
  inspect((@set.Set::new() : @set.Set[Int]).to_array(), content="[]")
}

///|
test "to_array_non_empty" {
  let set = @set.Set::new()
  set..add(1)..add(2)..add(3)
  inspect(set.to_array(), content="[1, 2, 3]")
}

///|
test "equal: different size" {
  let set1 = @set.Set::new()
  set1.add(1)
  let set2 = @set.Set::new()
  inspect(set1 == set2, content="false")
}

///|
test "equal: different keys" {
  let set1 = @set.Set::new()
  set1.add(1)
  let set2 = @set.Set::new()
  set2.add(2)
  inspect(set1 == set2, content="false")
}

///|
test "equal: same sets" {
  let set1 = @set.Set::new()
  set1.add(1)
  let set2 = @set.Set::new()
  set2.add(1)
  inspect(set1 == set2, content="true")
}

///|
test "equal: empty sets" {
  let set1 : @set.Set[Int] = @set.Set::new()
  let set2 : @set.Set[Int] = @set.Set::new()
  inspect(set1 == set2, content="true")
}

///|
test "equal: same elements different order" {
  let set1 = @set.Set::new()
  set1..add(1)..add(2)..add(3)
  let set2 = @set.Set::new()
  set2..add(3)..add(2)..add(1)
  inspect(set1 == set2, content="true")
}

///|
test "equal: subset" {
  let set1 = @set.Set::new()
  set1..add(1)..add(2)..add(3)
  let set2 = @set.Set::new()
  set2..add(1)..add(2)
  inspect(set1 == set2, content="false")
  inspect(set2 == set1, content="false")
}

///|
test "equal: large sets" {
  let set1 = @set.Set::new()
  let set2 = @set.Set::new()
  for i in 0..<100 {
    set1.add(i)
    set2.add(i)
  }
  inspect(set1 == set2, content="true")
}

///|
test "equal: large sets with one difference" {
  let set1 = @set.Set::new()
  let set2 = @set.Set::new()
  for i in 0..<100 {
    set1.add(i)
    if i != 50 {
      set2.add(i)
    } else {
      set2.add(100) // Different element
    }
  }
  inspect(set1 == set2, content="false")
}

///|
test "equal: after removal" {
  let set1 = @set.Set::new()
  set1..add(1)..add(2)..add(3)
  let set2 = @set.Set::new()
  set2..add(1)..add(2)..add(3)
  set1.remove(2)
  inspect(set1 == set2, content="false")
  set2.remove(2)
  inspect(set1 == set2, content="true")
}

///|
test "equal: after clear" {
  let set1 = @set.Set::new()
  set1..add(1)..add(2)..add(3)
  let set2 = @set.Set::new()
  inspect(set1 == set2, content="false")
  set1.clear()
  inspect(set1 == set2, content="true")
}

///|
test "equal: with string elements" {
  let set1 = @set.Set::new()
  set1..add("apple")..add("banana")..add("cherry")
  let set2 = @set.Set::new()
  set2..add("apple")..add("banana")..add("cherry")
  inspect(set1 == set2, content="true")
  set1.remove("banana")
  inspect(set1 == set2, content="false")
}

///|
test "equal: reflexivity" {
  let set = @set.Set::new()
  set..add(1)..add(2)..add(3)
  inspect(set == set, content="true")
}

///|
test "remove_and_check when key not found in empty slot" {
  // Try to remove from empty set
  inspect(@set.Set::new().remove_and_check(1), content="false")
}

///|
test "trigger grow" {
  let set = @set.Set::new(capacity=2)
  for i in 0..<10 {
    assert_true(set.add_and_check(i))
  }
  inspect(set, content="{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}")
}

///|
test "is_disjoint" {
  let set1 = @set.Set::of(["a", "b"])
  let set2 = @set.Set::of(["c", "d"])
  let set3 = @set.Set::of(["b", "c"])
  inspect(set1.is_disjoint(set2), content="true")
  inspect(set1.is_disjoint(set3), content="false")
}

///|
test "is_subset" {
  let set1 = @set.Set::of(["a", "b"])
  let set2 = @set.Set::of(["a", "b", "c"])
  let set3 = @set.Set::of(["a", "d"])
  inspect(set1.is_subset(set2), content="true")
  inspect(set1.is_subset(set3), content="false")
  inspect(set2.is_subset(set1), content="false")
}

///|
test "is_superset" {
  let set1 = @set.Set::of(["a", "b", "c"])
  let set2 = @set.Set::of(["a", "b"])
  let set3 = @set.Set::of(["a", "d"])
  inspect(set1.is_superset(set2), content="true")
  inspect(set1.is_superset(set3), content="false")
  inspect(set2.is_superset(set1), content="false")
}

///|
test "bitwise_operations" {
  let set1 = @set.Set::of(["a", "b", "c"])
  let set2 = @set.Set::of(["b", "c", "d"])

  // Intersection (&)
  let intersection = set1 & set2
  inspect(intersection.length(), content="2")
  inspect(intersection.contains("b"), content="true")
  inspect(intersection.contains("c"), content="true")

  // Union (|)
  let union = set1 | set2
  inspect(union.length(), content="4")
  inspect(union.contains("a"), content="true")
  inspect(union.contains("d"), content="true")

  // Difference (-)
  let diff = set1 - set2
  inspect(diff.length(), content="1")
  inspect(diff.contains("a"), content="true")

  // Symmetric difference (^)
  let sym_diff = set1 ^ set2
  inspect(sym_diff.length(), content="2")
  inspect(sym_diff.contains("a"), content="true")
  inspect(sym_diff.contains("d"), content="true")
}
