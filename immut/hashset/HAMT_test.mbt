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
fn[T : Hash + Eq] verify_content(
  set : @hashset.HashSet[T],
  expected : Array[T],
) -> Unit raise {
  for item in expected {
    assert_true(set.contains(item))
  }
  assert_true(set.length() == expected.length())
}

///|
test "Set" {
  let map = loop (0, @hashset.new()) {
    (100, map) => map
    (i, map) => continue (i + 1, map.add(i))
  }
  for i in 0..<100 {
    assert_eq((i, map.contains(i)), (i, true))
  }
  inspect((100, map.contains(100)), content="(100, false)")
  let map = map.add(100)
  inspect((100, map.contains(100)), content="(100, true)")
}

///|
test "@hashset.size" {
  for i = 0, set = @hashset.new(); i < 20; i = i + 1, set = set.add(i) {
    assert_eq(set.length(), i)
  } else {
    assert_eq(set.add(0).length(), 20)
  }
  let set = @hashset.new()
  inspect(set.length(), content="0")
  let set = set.add(1)
  inspect(set.length(), content="1")
  let set = set.add(2)
  inspect(set.length(), content="2")
  let set = set.remove(1)
  inspect(set.length(), content="1")
}

///|
test "@hashset.remove" {
  let map = loop (0, @hashset.new()) {
    (100, map) => map
    (i, map) => continue (i + 1, map.add(i))
  }
  for i in 0..<100 {
    assert_eq((i, map.contains(i)), (i, true))
  }
  let map = loop (0, map) {
    (100, map) => map.remove(100) // test for removing non-existing element
    (i, map) => continue (i + 2, map.remove(i))
  }
  for i = 0; i < 100; i = i + 2 {
    assert_eq(map.contains(i), false)
    assert_eq(map.contains(i + 1), true)
  }
}

///|
test "@hashset.iter" {
  let data = @hashset.of(["a", "b", "d", "e", "f"])
  let array = data.iter().collect()
  array.sort()
  inspect(
    array,
    content=(
      #|["a", "b", "d", "e", "f"]
    ),
  )
}

///|
test "@hashset.iterator" {
  let data = @hashset.of(["a", "b", "d", "e", "f"])
  let array = data.iterator().collect()
  array.sort()
  inspect(
    array,
    content=(
      #|["a", "b", "d", "e", "f"]
    ),
  )
}

///|
test "@hashset.to_string" {
  let set = @hashset.new().add(1).add(3).add(0x0f_ff_ff_ff).add(42)
  let content = set.iter().collect()
  assert_eq(set.to_string(), "@immut/hashset.of(\{content})")
}

///|
test "@hashset.from_array" {
  let set = @hashset.of(["1", "2", "42"])
  inspect(set.contains("1"), content="true")
  inspect(set.contains("2"), content="true")
  inspect(set.contains("42"), content="true")
  inspect(set.contains("43"), content="false")
}

///|
test "@hashset.is_empty" {
  let set = @hashset.new()
  inspect(set.is_empty(), content="true")
  let set = set.add(1)
  inspect(set.is_empty(), content="false")
  let set = set.remove(1)
  inspect(set.is_empty(), content="true")
}

///|
test "from_iter multiple elements iter" {
  let data = [1, 2, 3]
  let set = @hashset.from_iter(data.iter())
  verify_content(set, data)
}

///|
test "from_iter single element iter" {
  inspect(@hashset.from_iter([1].iter()), content="@immut/hashset.of([1])")
}

///|
test "from_iter empty iter" {
  let pq : @hashset.HashSet[Int] = @hashset.from_iter(Iter::empty())
  inspect(pq, content="@immut/hashset.of([])")
}

///|
test "from_iterator multiple elements iter" {
  let data = [1, 2, 3]
  let set = @hashset.from_iterator(data.iterator())
  verify_content(set, data)
}

///|
test "from_iterator single element iter" {
  inspect(
    @hashset.from_iterator([1].iterator()),
    content="@immut/hashset.of([1])",
  )
}

///|
test "from_iterator empty iter" {
  let pq : @hashset.HashSet[Int] = @hashset.from_iterator(Iterator::empty())
  inspect(pq, content="@immut/hashset.of([])")
}

///|
test "each on empty set" {
  let s = @hashset.new()
  let mut count = 0
  s.each((_x : Int) => count = count + 1)
  inspect(count, content="0")
}

///|
test "from_array with empty array" {
  let empty_array : Array[Int] = []
  let set = @hashset.from_array(empty_array)
  inspect(set.is_empty(), content="true")
}

///|
test "from_array with non-empty array" {
  let array = [1, 2, 3]
  let set = @hashset.from_array(array)
  inspect(set.contains(1), content="true")
  inspect(set.contains(2), content="true")
  inspect(set.contains(3), content="true")
  inspect(set.length(), content="3")
}

///|
test "remove non-existent key from leaf" {
  let set = @hashset.of([1])
  let result = set.remove(2)
  inspect(result, content="@immut/hashset.of([1])")
}

///|
test "from_array - non-empty array" {
  let data = [1, 2, 3]
  let set = @hashset.from_array(data)
  verify_content(set, data)
}

///|
test "hashset equality" {
  let set1 = @hashset.of([1, 2])
  let set2 = @hashset.of([2, 1])
  inspect(set1 == set2, content="true")
  let empty1 : @hashset.HashSet[Unit] = @hashset.new()
  let empty2 : @hashset.HashSet[Unit] = @hashset.new()
  inspect(empty1 == empty2, content="true")
}

///|
test "arbitrary implementation for hashset" {
  // Use @quickcheck.gen to generate an arbitrary hashset of Int
  let set : @hashset.HashSet[Int] = @quickcheck.gen()
  // Make sure the generated set is valid by converting it to array and back
  let arr = set.iter().to_array()
  let set2 = @hashset.from_array(arr)
  assert_eq(set, set2)
}

///|
test "equal between different constructors" {
  let set1 = @hashset.of([])
  let set2 = @hashset.of(["a"])
  assert_not_eq(set1, set2)
}

///|
test "union 2 hashsets" {
  let set1 = @hashset.of([1, 2, 3])
  let set2 = @hashset.of([3, 4, 5])
  let set3 = set1.union(set2)
  let set4 = @hashset.of([1, 2, 3, 4, 5])
  inspect(set3 == set4, content="true")
}

///|
test "HAMT::union with empty" {
  let m1 = @hashset.of([1])
  let m2 = @hashset.new()
  assert_eq(m1.union(m2), m1)
  assert_eq(m2.union(m1), m1)
}

///|
test "HAMT::union with leaf" {
  let m1 = @hashset.of([1, 2])
  let m2 = @hashset.of([3])
  let m3 = @hashset.of([2])
  assert_eq(m1.union(m2), @hashset.of([1, 2, 3]))
  assert_eq(m1.union(m3), @hashset.of([1, 2]))
  assert_eq(m3.union(m1), @hashset.of([1, 2]))
}

///|
test "HAMT::union with branch" {
  let m1 = @hashset.of([1, 2, 3])
  let m2 = @hashset.of([4, 5, 6])
  let u = m1.union(m2)
  for i in 1..=6 {
    assert_eq(u.contains(i), true)
  }
}

///|
struct MyString(String)

///|
impl Hash for MyString with hash_combine(_self, hasher) {
  hasher.combine(1)
}

///|
impl Eq for MyString with equal(self, other) {
  self.0 == other.0
}

///|
impl Show for MyString with to_string(self) {
  self.0
}

///|
impl Show for MyString with output(self, logger) {
  logger.write_string(self.0)
}

///|
test "HAMT::remove_with_hash collision" {
  let set = @hashset.of([MyString("a"), MyString("b")])
  let set1 = set.remove(MyString("c"))
  inspect(set1.length(), content="2")
  let set2 = set.remove(MyString("a"))
  assert_eq(set2.contains(MyString("a")), false)
  assert_eq(set2.contains(MyString("b")), true)
  inspect(set2.length(), content="1")
  let set3 = set2.remove(MyString("b"))
  inspect(set3.length(), content="0")
}

///|
test "HAMT::union with collision" {
  let m1 = @hashset.of([MyString("a"), MyString("b")])
  let m2 = @hashset.of([MyString("b"), MyString("c")])
  let u = m1.union(m2)
  assert_eq(u.contains(MyString("a")), true)
  assert_eq(u.contains(MyString("b")), true)
  assert_eq(u.contains(MyString("c")), true)
}

///|
test "HAMT::union all cases" {
  let empty = @hashset.new()
  let leaf = @hashset.of([1])
  let branch = @hashset.of([1, 2])
  let collision = @hashset.of([MyString("a"), MyString("b")])
  assert_eq(empty.union(leaf).contains(1), true)
  assert_eq(leaf.union(branch).contains(2), true)
  let u1 = branch.union(branch)
  inspect(u1.contains(1), content="true")
  inspect(u1.contains(2), content="true")
  let collision2 = @hashset.of([MyString("b"), MyString("c")])
  let u2 = collision.union(collision2)
  assert_eq(u2.contains(MyString("a")), true)
  assert_eq(u2.contains(MyString("b")), true)
  assert_eq(u2.contains(MyString("c")), true)
}

///|
test "HAMT::union leaf to non-overlapping map" {
  let leaf = @hashset.of([42])
  let other = @hashset.of([1, 2])
  let u = leaf.union(other)
  inspect(u.contains(42), content="true")
  inspect(u.contains(1), content="true")
  inspect(u.contains(2), content="true")
}

///|
test "@hashset.difference patch" {
  let set1 = @hashset.of([1, 2, 3, 4])
  let set2 = @hashset.of([3, 4, 5, 6])
  let set3 = @hashset.of([])
  let set4 = @hashset.of([1, 2, 3, 4, 5, 6])
  let leaf = @hashset.of([1])
  verify_content(set1.difference(set2), [1, 2])
  verify_content(set1.difference(set3), [1, 2, 3, 4])
  verify_content(set3.difference(set1), [])
  verify_content(set2.difference(set4), [])
  verify_content(leaf.difference(set1), [])
  verify_content(set1.difference(leaf), [2, 3, 4])
}

///|
test "@hashset.intersection patch" {
  let set1 = @hashset.of([1, 2, 3, 4])
  let set2 = @hashset.of([3, 4, 5, 6])
  let set3 = @hashset.of([])
  let set4 = @hashset.of([1, 2, 3, 4, 5, 6])
  let set5 = @hashset.of([7, 8, 9, 10])
  let leaf = @hashset.of([1])
  verify_content(set1.intersection(set2), [3, 4])
  verify_content(set1.intersection(set3), [])
  verify_content(set3.intersection(set1), [])
  verify_content(set2.intersection(set4), [3, 4, 5, 6])
  verify_content(leaf.intersection(set1), [1])
  verify_content(set1.intersection(leaf), [1])
  verify_content(set5.intersection(set1), [])
}

///|
test "@hashset collision" {
  let a = MyString("a")
  let b = MyString("b")
  let c = MyString("c")
  let set = @hashset.new().add(a).add(b).add(c)
  inspect(set.iter().to_array(), content="[c, b, a]")
  set.each((x : MyString) => x |> ignore)
  inspect(set.length(), content="3")
}

///|
test "collision equal coverage" {
  let a = MyString("a")
  let b = MyString("b")
  let set1 = @hashset.new().add(a).add(b)
  let set2 = @hashset.new().add(b).add(a)
  assert_eq(set1, set2)
}
