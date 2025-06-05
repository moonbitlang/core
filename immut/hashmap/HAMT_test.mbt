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
test "HAMT::size" {
  for i = 0, map = @hashmap.new(); i < 20; i = i + 1, map = map.add(i, i) {
    assert_eq(map.size(), i)
  } else {
    assert_eq(map.add(0, 0).size(), 20)
  }
}

///|
test "HAMT" {
  let map = loop 0, @hashmap.new() {
    100, map => map
    i, map => continue i + 1, map.add(i, i)
  }
  for i in 0..<100 {
    assert_eq((i, map.get(i)), (i, Some(i)))
  }
  inspect((100, map.get(100)), content="(100, None)")
  let map = map.add(100, 100)
  inspect((100, map.get(100)), content="(100, Some(100))")
  // test for replacement
  let map = loop 0, map {
    100, map => map
    i, map => continue i + 2, map.add(i, i + 1)
  }
  for i = 0; i < 100; i = i + 2 {
    assert_eq((i, map.get(i)), (i, Some(i + 1)))
    assert_eq((i + 1, map.get(i + 1)), (i + 1, Some(i + 1)))
  }
}

///|
test "HAMT::remove" {
  let map = loop 0, @hashmap.new() {
    100, map => map
    i, map => continue i + 1, map.add(i, i)
  }
  for i in 0..<100 {
    assert_eq((i, map.get(i)), (i, Some(i)))
  }
  let map = loop 0, map {
    100, map => map.remove(100) // test for removing non-existing element
    i, map => continue i + 2, map.remove(i)
  }
  for i = 0; i < 100; i = i + 2 {
    assert_eq(map.get(i), None)
    assert_eq(map.get(i + 1), Some(i + 1))
  }
}

///|
test "keys" {
  let m = @hashmap.of([(1, "one"), (2, "two")])
  let keys = m.keys()
  assert_eq(keys.contains(1), true)
  assert_eq(keys.contains(2), true)
  assert_eq(keys.contains(3), false)
}

///|
test "HAMT::values" {
  let m = @hashmap.of([(1, "one"), (2, "two")])
  let values = m.values()
  assert_eq(values.contains("one"), true)
  assert_eq(values.contains("two"), true)
  assert_eq(values.contains("three"), false)
}

///|
test "HAMT::iter" {
  let data = @hashmap.of([(0, "a"), (2, "b"), (3, "d"), (5, "e"), (11111, "f")])
  let mut s = ""
  data.iter().each(fn { (k, v) => s += " \{k},\{v}" })
  inspect(s, content=" 0,a 5,e 3,d 11111,f 2,b")
}

///|
test "HAMT::iter2" {
  let data = @hashmap.of([(0, "a"), (2, "b"), (3, "d"), (5, "e"), (11111, "f")])
  let mut s = ""
  data.iter2().each(fn { k, v => s += " \{k},\{v}" })
  inspect(s, content=" 0,a 5,e 3,d 11111,f 2,b")
}

///|
test "HAMT::to_string" {
  let map = @hashmap.new()
    .add(1, 1)
    .add(3, 3)
    .add(0x0f_ff_ff_ff, 0x0f_ff_ff_ff)
    .add(42, 42)
  inspect(
    map,
    content="@immut/hashmap.of([(3, 3), (42, 42), (1, 1), (268435455, 268435455)])",
  )
}

///|
test "HAMT::from_array" {
  let map = @hashmap.of([(1, "1"), (2, "2"), (42, "42")])
  inspect(
    (1, map.get(1)),
    content=
      #|(1, Some("1"))
    ,
  )
  inspect(
    (2, map.get(2)),
    content=
      #|(2, Some("2"))
    ,
  )
  inspect(
    (42, map.get(42)),
    content=
      #|(42, Some("42"))
    ,
  )
  inspect((43, map.get(43)), content="(43, None)")
}

///|
test "to_array" {
  let m = @hashmap.of([(1, "one"), (2, "two")])
  let arr = m.to_array()
  assert_eq(arr.length(), 2)
  assert_eq(arr.contains((1, "one")), true)
  assert_eq(arr.contains((2, "two")), true)
  assert_eq(arr.contains((3, "three")), false)
}

///|
test "from_iter multiple elements iter" {
  inspect(
    @hashmap.from_iter([(1, 1), (2, 2), (3, 3)].iter()),
    content="@immut/hashmap.of([(3, 3), (2, 2), (1, 1)])",
  )
}

///|
test "from_iter single element iter" {
  inspect(
    @hashmap.from_iter([(1, 1)].iter()),
    content="@immut/hashmap.of([(1, 1)])",
  )
}

///|
test "from_iter empty iter" {
  let pq : @hashmap.T[Int, Int] = @hashmap.from_iter(Iter::empty())
  inspect(pq, content="@immut/hashmap.of([])")
}

///|
test "eq for boundary cases" {
  // Test with empty maps
  let empty_map1 : @hashmap.T[Int, Int] = @hashmap.new()
  let empty_map2 : @hashmap.T[Int, Int] = @hashmap.new()
  inspect(empty_map1 == empty_map2, content="true")

  // Test with one empty map and one non-empty map
  let non_empty_map : @hashmap.T[Int, Int] = @hashmap.of([(1, 1)])
  inspect(empty_map1 == non_empty_map, content="false")
  inspect(non_empty_map == empty_map1, content="false")

  // Test with maps of different sizes
  let larger_map : @hashmap.T[Int, Int] = @hashmap.of([(1, 1), (2, 2)])
  inspect(non_empty_map == larger_map, content="false")
}

///|
test "eq for random cases" {
  // Test with maps containing different keys
  let map1 : @hashmap.T[Int, Int] = @hashmap.of([(1, 1), (2, 2)])
  let map2 : @hashmap.T[Int, Int] = @hashmap.of([(1, 1), (3, 3)])
  inspect(map1 == map2, content="false")

  // Test with maps containing same keys but different values
  let map3 : @hashmap.T[Int, Int] = @hashmap.of([(1, 1), (2, 3)])
  inspect(map1 == map3, content="false")

  // Test with maps containing same keys and values but in different order
  let map4 : @hashmap.T[Int, Int] = @hashmap.of([(2, 2), (1, 1)])
  inspect(map1 == map4, content="true")

  // Test with maps containing same keys and values but with different hash collisions
  let map5 : @hashmap.T[Int, Int] = @hashmap.of([(1, 1), (11, 11)])
  let map6 : @hashmap.T[Int, Int] = @hashmap.of([(1, 1), (11, 11)])
  inspect(map5 == map6, content="true")

  // Test with maps containing same keys and values but with different hash collisions and different order
  let map7 : @hashmap.T[Int, Int] = @hashmap.of([(11, 11), (1, 1)])
  inspect(map5 == map7, content="true")
}

///|
test "eq for random cases with different types" {
  // Test with maps containing different types
  let map8 : @hashmap.T[String, Int] = @hashmap.of([("one", 1), ("two", 2)])
  let map9 : @hashmap.T[String, Int] = @hashmap.of([("one", 1), ("two", 2)])
  inspect(map8 == map9, content="true")

  // Test with maps containing same keys but different values of different types
  let map10 : @hashmap.T[String, Int] = @hashmap.of([("one", 1), ("two", 3)])
  inspect(map8 == map10, content="false")

  // Test with maps containing different keys of different types
  let map11 : @hashmap.T[String, Int] = @hashmap.of([("one", 1), ("three", 3)])
  inspect(map8 == map11, content="false")
}

///|
test "hash" {
  let map1 = @hashmap.of([("one", 1), ("two", 2)])
  let map2 = @hashmap.of([("one", 1), ("two", 2)])
  inspect(map1.hash() == map2.hash(), content="true")
  let map3 = @hashmap.of([("two", 2), ("one", 1)])
  inspect(map1.hash() == map3.hash(), content="true")
  let map4 = @hashmap.of([("one", 1), ("two", 2), ("three", 3)])
  inspect(map1.hash() == map4.hash(), content="false")
}

///|
test "each on empty map" {
  let empty = @hashmap.new()
  let mut sum = 0
  empty.each(fn(k : Int, v : Int) { sum = sum + k + v })
  inspect(sum, content="0")
}

///|
test "remove non-existent key with hash collision" {
  let map = @hashmap.of([("a", 1)])
  let new_map = map.remove("b")
  inspect(new_map.size(), content="1")
}

///|
test "remove all keys from collision bucket" {
  let map = @hashmap.from_array([("a", 1), ("b", 2)])
  let map1 = map.remove("a")
  let map2 = map1.remove("b")
  inspect(map2.size(), content="0")
}

///|
test "union 2 hashmaps, choose the right hand side" {
  let map1 = @hashmap.of([(1, 1), (2, 2), (3, 3)])
  let map2 = @hashmap.of([(1, 10), (2, 20), (4, 40)])
  let map3 = map1.union(map2)
  let map4 = @hashmap.of([(1, 10), (2, 20), (3, 3), (4, 40)])
  inspect(map3 == map4, content="true")
}

///|
test "union 2 hashmaps, without conflict" {
  let map1 = @hashmap.of([(1, 1), (2, 2), (3, 3)])
  let map2 = @hashmap.of([(4, 4), (5, 5), (6, 6)])
  let map3 = map1.union(map2)
  let map4 = @hashmap.of([(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6)])
  inspect(map3 == map4, content="true")
}

///|
test "HAMT::contains" {
  let map = @hashmap.of([(1, "one")])
  assert_eq(map.contains(1), true)
  assert_eq(map.contains(2), false)
  let map2 = map.add(2, "two")
  assert_eq(map2.contains(2), true)
  let map3 = map.remove(2)
  assert_eq(map3.contains(2), false)
}

///|
test "filter with simple predicate" {
  let map = @hashmap.of([(1, 1), (2, 2), (3, 3), (4, 4)])
  let only_even = map.filter(fn(v) { v % 2 == 0 })
  assert_eq(only_even.contains(1), false)
  assert_eq(only_even.contains(2), true)
  assert_eq(only_even.contains(3), false)
  assert_eq(only_even.contains(4), true)
}

///|
test "filter with all elements matching" {
  let map = @hashmap.of([(1, 1), (2, 2)])
  let filtered = map.filter(fn(v) { v > 0 })
  assert_eq(filtered.contains(1), true)
  assert_eq(filtered.contains(2), true)
}

///|
test "filter with no elements matching" {
  let map = @hashmap.of([(1, 1), (2, 2), (3, 3)])
  let filtered = map.filter(fn(v) { v > 10 })
  assert_eq(filtered.get(1), None)
  assert_eq(filtered.get(2), None)
  assert_eq(filtered.get(3), None)
  assert_eq(filtered.size(), 0)
}

///|
test "filter with collision" {
  let map = @hashmap.of([(1, 10), (2, 20)]).add(1, 30)
  let filtered = map.filter(fn(v) { v == 30 })
  assert_eq(filtered.get(1), Some(30))
  assert_eq(filtered.get(2), None)
}

///|
test "filter with branch nodes" {
  let map = loop 0, @hashmap.new() {
    10, map => map
    i, map => continue i + 1, map.add(i, i * 10)
  }
  let filtered = map.filter(fn(v) { v % 20 == 0 })
  for i = 0; i < 10; i = i + 1 {
    if i * 10 % 20 == 0 {
      assert_eq(filtered.get(i), Some(i * 10))
    } else {
      assert_eq(filtered.get(i), None)
    }
  }
}

///|
test "HAMT::fold_with_key" {
  let map = @hashmap.of([(1, "a"), (2, "b")])
  let result = map.fold_with_key(init="", fn(acc, k, v) { acc + "\{k}:\{v}, " })
  // order of elements is not guaranteed, so we check for substrings
  assert_eq(result.contains("1:a"), true)
  assert_eq(result.contains("2:b"), true)
}

///|
test "HAMT::fold" {
  let map = @hashmap.of([(1, 10), (2, 20), (3, 30)])
  let result = map.fold(init=0, fn(acc, v) { acc + v })
  assert_eq(result, 60)
}

///|
test "HAMT::map" {
  let map = @hashmap.of([(1, 10), (2, 20)])
  let mapped = map.map(fn(v) { v * 2 })
  assert_eq(mapped.get(1), Some(20))
  assert_eq(mapped.get(2), Some(40))
  assert_eq(mapped.get(3), None)
}

///|
test "HAMT::map with overflow" {
  let max = 2147483647 // Int.max_value
  let map = @hashmap.of([(1, max)])
  let mapped = map.map(fn(v) { v + 1 })
  assert_eq(mapped.get(1), Some(-2147483648))
}

///|
test "HAMT::map_with_key empty" {
  let map : @hashmap.T[Int, Int] = @hashmap.new()
  let mapped = map.map_with_key(fn(_k, v) { v })
  assert_eq(mapped.size(), 0)
}

///|
test "HAMT::map_with_key leaf" {
  let map = @hashmap.singleton(42, 100) // Leaf
  let mapped = map.map_with_key(fn(k, v) { k + v })
  assert_eq(mapped.get(42), Some(142))
  assert_eq(mapped.size(), 1)
}

///|
test "HAMT::map_with_key collision" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)]) // Collision
  let mapped = map.map_with_key(fn(k, v) { k._ + ":" + v.to_string() })
  assert_eq(mapped.get(MyString("a")), Some("a:1"))
  assert_eq(mapped.get(MyString("b")), Some("b:2"))
  assert_eq(mapped.get(MyString("c")), None)
}

///|
test "HAMT::map_with_key branch" {
  let map = loop 0, @hashmap.new() {
    10, map => map
    i, map => continue i + 1, map.add(i, i * 10)
  } // Branch
  let mapped = map.map_with_key(fn(k, v) { k * 100 + v })
  for i = 0; i < 10; i = i + 1 {
    assert_eq(mapped.get(i), Some(i * 100 + i * 10))
  }
  assert_eq(mapped.get(100), None)
}

///|
test "HAMT::singleton" {
  let map = @hashmap.singleton(1, "one")
  assert_eq(map.size(), 1)
  assert_eq(map.get(1), Some("one"))
  assert_eq(map.get(2), None)
}

///|
type MyString String

///|
impl Hash for MyString with hash_combine(_self, hasher) {
  hasher.combine(1)
}

///|
impl Eq for MyString with op_equal(self, other) {
  self._ == other._
}

///|
test "get collision" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  assert_eq(map.get(MyString("a")), Some(1))
  assert_eq(map.get(MyString("b")), Some(2))
  assert_eq(map.get(MyString("c")), None)
}

///|
test "add_with_hash collision" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  assert_eq(map.get(MyString("a")), Some(1))
  assert_eq(map.get(MyString("b")), Some(2))
}

///|
test "add_with_hash collision" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  assert_eq(map.get(MyString("a")), Some(1))
  assert_eq(map.get(MyString("b")), Some(2))
  assert_eq(map.get(MyString("c")), None)
  let map = map.add(MyString("c"), 3)
  assert_eq(map.get(MyString("c")), Some(3))
}

///|
test "empty filtering" {
  let map : @hashmap.T[Int, Int] = @hashmap.of([])
  let _filtered = map.filter(fn(v) { v > 2 })
  assert_eq(map.size(), 0)
}

///|
test "filter with collision - all removed" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  let filtered = map.filter(fn(v) { v > 2 })
  assert_eq(filtered.size(), 0)
}

///|
test "filter with collision - one left" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  let filtered = map.filter(fn(v) { v == 1 })
  assert_eq(filtered.size(), 1)
}

///|
test "filter with collision - more than one left" {
  let map = @hashmap.of([
    (MyString("a"), 1),
    (MyString("b"), 2),
    (MyString("c"), 3),
  ])
  let filtered = map.filter(fn(v) { v > 1 })
  assert_eq(filtered.size(), 2)
}

///|
test "HAMT::fold_with_key on empty" {
  let map : @hashmap.T[Int, Int] = @hashmap.new()
  let result = map.fold_with_key(init=0, fn(acc, _k, _v) { acc + 1 })
  assert_eq(result, 0)
}

///|
test "HAMT::fold_with_key on collision" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  let result = map.fold_with_key(init=0, fn(acc, _k, v) { acc + v })
  assert_eq(result, 3)
}

///|
test "HAMT::remove_with_hash collision" {
  let map = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  let map1 = map.remove(MyString("c"))
  assert_eq(map1.size(), 2)
  let map2 = map.remove(MyString("a"))
  assert_eq(map2.get(MyString("a")), None)
  assert_eq(map2.get(MyString("b")), Some(2))
  assert_eq(map2.size(), 1)
  let map3 = map2.remove(MyString("b"))
  assert_eq(map3.size(), 0)
}

///|
test "HAMT::union with empty" {
  let m1 = @hashmap.of([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq(m1.union(m2), m1)
  assert_eq(m2.union(m1), m1)
}

///|
test "HAMT::union with leaf" {
  let m1 = @hashmap.of([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(3, 3)
  let m3 = @hashmap.singleton(2, 20)
  assert_eq(m1.union(m2).get(3), Some(3))
  assert_eq(m1.union(m3).get(2), Some(20))
  assert_eq(m3.union(m1).get(2), Some(2))
}

///|
test "HAMT::union with branch" {
  let m1 = @hashmap.of([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.of([(4, 4), (5, 5), (6, 6)])
  let u = m1.union(m2)
  for i in 1..=6 {
    assert_eq(u.contains(i), true)
  }
}

///|
test "HAMT::union with collision" {
  let m1 = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.of([(MyString("b"), 20), (MyString("c"), 3)])
  let u = m1.union(m2)
  assert_eq(u.get(MyString("a")), Some(1))
  assert_eq(u.get(MyString("b")), Some(2))
  assert_eq(u.get(MyString("c")), Some(3))
}

///|
test "HAMT::union all cases" {
  let empty = @hashmap.new()
  let leaf = @hashmap.singleton(1, 1)
  let branch = @hashmap.of([(1, 1), (2, 2)])
  let collision = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  assert_eq(empty.union(leaf).get(1), Some(1))
  assert_eq(leaf.union(branch).get(2), Some(2))
  let u1 = branch.union(branch)
  assert_eq(u1.get(1), Some(1))
  assert_eq(u1.get(2), Some(2))
  let collision2 = @hashmap.of([(MyString("b"), 20), (MyString("c"), 3)])
  let u2 = collision.union(collision2)
  assert_eq(u2.get(MyString("a")), Some(1))
  assert_eq(u2.get(MyString("b")), Some(2))
  assert_eq(u2.get(MyString("c")), Some(3))
}

///|
test "HAMT::union leaf to non-overlapping map" {
  let leaf = @hashmap.singleton(42, 100)
  let other = @hashmap.of([(1, 1), (2, 2)])
  let u = leaf.union(other)
  assert_eq(u.get(42), Some(100))
  assert_eq(u.get(1), Some(1))
  assert_eq(u.get(2), Some(2))
}

///|
test "HAMT::intersection with empty" {
  let m1 = @hashmap.of([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq!(m1.intersection(m2).size(), 0)
  assert_eq!(m2.intersection(m1).size(), 0)
}

///|
test "HAMT::intersection with leaf" {
  let m1 = @hashmap.of([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(2, 2)
  let m3 = @hashmap.singleton(3, 3)
  assert_eq!(m1.intersection(m2).get(2), Some(2))
  assert_eq!(m1.intersection(m3).get(3), None)
  assert_eq!(m2.intersection(m1).get(2), Some(2))
}

///|
test "HAMT::intersection with branch" {
  let m1 = @hashmap.of([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.of([(2, 2), (3, 30), (4, 4)])
  let inter = m1.intersection(m2)
  assert_eq!(inter.get(1), None)
  assert_eq!(inter.get(2), Some(2))
  assert_eq!(inter.get(3), Some(3))
  assert_eq!(inter.get(4), None)
}

///|
test "HAMT::intersection_with with empty" {
  let m1 = @hashmap.of([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq!(m1.intersection_with(m2, fn(_k, v1, v2) { v1 + v2 }).size(), 0)
  assert_eq!(m2.intersection_with(m1, fn(_k, v1, v2) { v1 + v2 }).size(), 0)
}

///|
test "HAMT::intersection_with with leaf" {
  let m1 = @hashmap.of([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(2, 20)
  let m3 = @hashmap.singleton(3, 30)
  assert_eq!(
    m1.intersection_with(m2, fn(_k, v1, v2) { v1 + v2 }).get(2),
    Some(22),
  )
  assert_eq!(m1.intersection_with(m3, fn(_k, v1, v2) { v1 + v2 }).get(3), None)
  assert_eq!(
    m2.intersection_with(m1, fn(_k, v1, v2) { v1 + v2 }).get(2),
    Some(22),
  )
}

///|
test "HAMT::intersection_with with branch" {
  let m1 = @hashmap.of([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.of([(2, 20), (3, 30), (4, 4)])
  let inter = m1.intersection_with(m2, fn(_k, v1, v2) { v1 * v2 })
  assert_eq!(inter.get(1), None)
  assert_eq!(inter.get(2), Some(40))
  assert_eq!(inter.get(3), Some(90))
  assert_eq!(inter.get(4), None)
}

///|
test "HAMT::difference with empty" {
  let m1 = @hashmap.of([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq!(m1.difference(m2), m1)
  assert_eq!(m2.difference(m1).size(), 0)
}

///|
test "HAMT::difference with leaf" {
  let m1 = @hashmap.of([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(2, 2)
  let m3 = @hashmap.singleton(3, 3)
  assert_eq!(m1.difference(m2).get(2), None)
  assert_eq!(m1.difference(m3).get(1), Some(1))
  assert_eq!(m2.difference(m1).size(), 0)
}

///|
test "HAMT::difference with branch" {
  let m1 = @hashmap.of([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.of([(2, 2), (3, 30), (4, 4)])
  let diff = m1.difference(m2)
  assert_eq!(diff.get(1), Some(1))
  assert_eq!(diff.get(2), None)
  assert_eq!(diff.get(3), None)
  assert_eq!(diff.get(4), None)
}

///|
test "HAMT::each" {
  let empty = @hashmap.new()
  let mut sum = 0
  empty.each(fn(k : Int, v : Int) { sum = sum + k + v })
  assert_eq(sum, 0)
  let leaf = @hashmap.singleton(1, 10)
  let mut sum_leaf = 0
  leaf.each(fn(k, v) { sum_leaf = sum_leaf + k + v })
  assert_eq(sum_leaf, 11)
  let collision = @hashmap.of([(MyString("a"), 1), (MyString("b"), 2)])
  let mut sum_collision = 0
  collision.each(fn(_k : MyString, v : Int) {
    sum_collision = sum_collision + v
  })
  assert_eq(sum_collision, 3)
  let branch = @hashmap.of([(1, 1), (2, 2), (3, 3), (4, 4)])
  let mut sum_branch = 0
  branch.each(fn(_k, v) { sum_branch = sum_branch + v })
  assert_eq(sum_branch, 10)
}

///|
test "arbitary" {
  let m : Array[@hashmap.T[Int, Int]] = @quickcheck.samples(10)
  assert_eq(m.length(), 10)
}
