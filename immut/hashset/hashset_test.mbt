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
priv type MyInt Int derive(Eq)

///|
impl Hash for MyInt with hash_combine(self, hasher) {
  // To create hash collisions, only use the lowest 8 bits
  (self._ & 0xff).hash_combine(hasher)
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
  assert_false(map.contains(100))
  let map = map.add(100)
  assert_true(map.contains(100))
}

///|
test "@hashset.size" {
  for i = 0, set = @hashset.new(); i < 20; i = i + 1, set = set.add(i) {
    assert_eq(set.size(), i)
  } else {
    assert_eq(set.add(0).size(), 20)
  }
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
  let empty = @hashset.new()
  assert_eq(empty.remove(1), empty)
}

///|
test "@hashset.remove when collision" {
  let set : T[MyInt] = of([0x000, 0x100, 0x200, 0x300])
  assert_eq(set.size(), 4)
  let set = set.remove(0x000)
  assert_eq(set.size(), 3)
  let set = set.remove(0x100)
  assert_eq(set.size(), 2)
  let set = set.remove(0x300)
  assert_eq(set.size(), 1)
  let set = set.remove(0x200)
  assert_eq(set.size(), 0)
}

///|
test "@hashset.iter" {
  let data = @hashset.of(["a", "b", "d", "e", "f"])
  let mut s = ""
  data.iter().each(fn { k => s += " \{k}" })
  inspect(s, content=" e f b a d")
}

///|
test "@hashset.to_string" {
  let set = @hashset.new().add(1).add(3).add(0x0f_ff_ff_ff).add(42)
  inspect(set, content="@immut/hashset.of([3, 42, 1, 268435455])")
}

///|
test "@hashset.from_array" {
  let set = @hashset.of(["1", "2", "42"])
  assert_true(set.contains("1"))
  assert_true(set.contains("2"))
  assert_true(set.contains("42"))
  assert_false(set.contains("43"))
}

///|
test "@hashset.is_empty" {
  let set = @hashset.new()
  assert_true(set.is_empty())
  let set = set.add(1)
  assert_false(set.is_empty())
}

///|
test "@hashset.size" {
  let set = @hashset.new()
  assert_eq(set.size(), 0)
  let set = set.add(1)
  assert_eq(set.size(), 1)
  let set = set.add(2)
  assert_eq(set.size(), 2)
  let set = set.remove(1)
  assert_eq(set.size(), 1)
}

///|
test "@hashset.is_empty" {
  let set = @hashset.new()
  assert_true(set.is_empty())
  let set = set.add(1)
  assert_false(set.is_empty())
  let set = set.remove(1)
  assert_true(set.is_empty())
}

///|
test "@hashset.each" {
  let set = @hashset.new().add(1).add(2).add(3)
  let result = []
  set.each(fn { x => result.push(x) })
  result.sort()
  assert_eq(result, [1, 2, 3])
}

///|
test "@hashset.iter" {
  let set = @hashset.new().add(1).add(2).add(3)
  let result = []
  set.iter().each(fn { x => result.push(x) })
  result.sort()
  assert_eq(result, [1, 2, 3])
}

///|
test "from_iter multiple elements iter" {
  inspect(
    @hashset.from_iter([1, 2, 3].iter()),
    content="@immut/hashset.of([3, 2, 1])",
  )
}

///|
test "from_iter single element iter" {
  inspect(@hashset.from_iter([1].iter()), content="@immut/hashset.of([1])")
}

///|
test "from_iter empty iter" {
  let pq : @hashset.T[Int] = @hashset.from_iter(Iter::empty())
  inspect(pq, content="@immut/hashset.of([])")
}

///|
test "each on empty set" {
  let s = @hashset.new()
  let mut count = 0
  s.each(fn(_x : Int) -> Unit { count = count + 1 })
  assert_eq(count, 0)
}

///|
test "from_array with empty array" {
  let empty_array : Array[Int] = []
  let set = @hashset.from_array(empty_array)
  assert_true(set.is_empty())
}

///|
test "from_array with non-empty array" {
  let array = [1, 2, 3]
  let set = @hashset.from_array(array)
  assert_true(set.contains(1))
  assert_true(set.contains(2))
  assert_true(set.contains(3))
  inspect(set.size(), content="3")
}

///|
test "remove non-existent key from leaf" {
  let set = @hashset.of([1])
  let result = set.remove(2)
  inspect(result, content="@immut/hashset.of([1])")
}

///|
test "from_array - non-empty array" {
  let set = @hashset.from_array([1, 2, 3])
  inspect(set, content="@immut/hashset.of([3, 2, 1])")
}

///|
test "hashset equality" {
  let set1 = @hashset.of([1, 2])
  let set2 = @hashset.of([2, 1])
  let set3 = @hashset.of([2, 1, 3])
  assert_eq(set1, set2)
  assert_not_eq(set1, set3)
  let empty1 : @hashset.T[Unit] = @hashset.new()
  let empty2 : @hashset.T[Unit] = @hashset.new()
  assert_eq(empty1, empty2)
}

///|
test "hashset hash" {
  let set1 = @hashset.of([1, 2])
  let set2 = @hashset.of([2, 1])
  let set3 = @hashset.of([2, 1, 3])
  assert_eq(set1.hash(), set2.hash())
  assert_not_eq(set1.hash(), set3.hash())
}

///|
test "arbitrary implementation for hashset" {
  // Use @quickcheck.gen to generate an arbitrary hashset of Int
  let set : @hashset.T[Int] = @quickcheck.gen()
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
test "@hashset.intersection with disjoint sets" {
  let set1 = @hashset.of([1, 2])
  let set2 = @hashset.of([3, 4])
  let result = set1.intersection(set2)
  assert_true(result.is_empty())
}

///|
test "@hashset.intersection with subset" {
  let set1 = @hashset.of([1, 2, 3, 4])
  let set2 = @hashset.of([2, 3])
  let result = set1.intersection(set2)
  assert_eq(result, @hashset.of([2, 3]))
}

///|
fn make_test_data() -> (T[MyInt], T[MyInt]) {
  let collisions_0 = (1).until(3000, step=0x100)
  let collisions_11 = (2).until(3000, step=0x100)
  let collisions_12 = (2).until(1000, step=0x100)
  let i1 = (0).until(200) + collisions_0 + collisions_11
  let i2 = (-200).until(100) + collisions_0 + collisions_12
  let t1 = from_iter(i1.map(MyInt(_)))
  let t2 = from_iter(i2.map(MyInt(_)))
  (t1, t2)
}

///|
test "union" {
  let (a, b) = make_test_data()
  let empty = new()
  assert_true(a.union(a) == a)
  assert_true(a.union(empty) == a)
  assert_true(empty.union(a) == a)
  let c = a.union(b)
  assert_true(a.iter().all(c.contains(_)))
  assert_true(b.iter().all(c.contains(_)))
  assert_true(c.iter().all(fn(k) { a.contains(k) || b.contains(k) }))
}

///|
test "intersection" {
  let (a, b) = make_test_data()
  let empty = new()
  assert_true(a.intersection(a) == a)
  assert_true(a.intersection(empty).is_empty())
  assert_true(empty.intersection(a).is_empty())
  let c = a.intersection(b)
  assert_true(a.iter().all(fn(k) { b.contains(k) == c.contains(k) }))
  assert_true(b.iter().all(fn(k) { a.contains(k) == c.contains(k) }))
  assert_true(c.iter().all(fn(k) { a.contains(k) && b.contains(k) }))
}

///|
test "difference" {
  let (a, b) = make_test_data()
  let empty = new()
  assert_true(a.difference(a).is_empty())
  assert_true(a.difference(empty) == a)
  assert_true(empty.difference(a).is_empty())
  let adb = a.difference(b)
  assert_true(a.iter().all(fn(k) { b.contains(k) != adb.contains(k) }))
  assert_true(b.iter().all(fn(k) { not(adb.contains(k)) }))
  assert_true(adb.iter().all(fn(k) { a.contains(k) && not(b.contains(k)) }))
  let bda = b.difference(a)
  assert_true(b.iter().all(fn(k) { a.contains(k) != bda.contains(k) }))
  assert_true(a.iter().all(fn(k) { not(bda.contains(k)) }))
  assert_true(bda.iter().all(fn(k) { b.contains(k) && not(a.contains(k)) }))
}
