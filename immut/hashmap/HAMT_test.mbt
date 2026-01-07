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
test "HAMT::size" {
  for i = 0, map = @hashmap.new(); i < 20; i = i + 1, map = map.add(i, i) {
    assert_eq(map.length(), i)
  } else {
    assert_eq(map.add(0, 0).length(), 20)
  }
}

///|
test "HAMT" {
  let map = loop (0, @hashmap.new()) {
    (100, map) => map
    (i, map) => continue (i + 1, map.add(i, i))
  }
  for i in 0..<100 {
    assert_eq((i, map.get(i)), (i, Some(i)))
  }
  inspect((100, map.get(100)), content="(100, None)")
  let map = map.add(100, 100)
  inspect((100, map.get(100)), content="(100, Some(100))")
  // test for replacement
  let map = loop (0, map) {
    (100, map) => map
    (i, map) => continue (i + 2, map.add(i, i + 1))
  }
  for i = 0; i < 100; i = i + 2 {
    assert_eq((i, map.get(i)), (i, Some(i + 1)))
    assert_eq((i + 1, map.get(i + 1)), (i + 1, Some(i + 1)))
  }
}

///|
test "HAMT::get" {
  let map = loop (0, @hashmap.new()) {
    (100, map) => map
    (i, map) => continue (i + 1, map.add(i, i))
  }
  for i in 0..<100 {
    assert_eq((i, map[i]), (i, i))
  }
}

///|
test "panic HAMT::get" {
  let map = @hashmap.new()
  map[0]
}

///|
test "HAMT::remove" {
  let map = loop (0, @hashmap.new()) {
    (100, map) => map
    (i, map) => continue (i + 1, map.add(i, i))
  }
  for i in 0..<100 {
    assert_eq((i, map.get(i)), (i, Some(i)))
  }
  let map = loop (0, map) {
    (100, map) => map.remove(100) // test for removing non-existing element
    (i, map) => continue (i + 2, map.remove(i))
  }
  for i = 0; i < 100; i = i + 2 {
    assert_eq(map.get(i), None)
    assert_eq(map.get(i + 1), Some(i + 1))
  }
}

///|
test "keys" {
  let m = @hashmap.from_array([(1, "one"), (2, "two")])
  let keys = () => m.keys()
  inspect(keys().contains(1), content="true")
  inspect(keys().contains(2), content="true")
  inspect(keys().contains(3), content="false")
}

///|
test "HAMT::values" {
  let m = @hashmap.from_array([(1, "one"), (2, "two")])
  let values = () => m.values()
  inspect(values().contains("one"), content="true")
  inspect(values().contains("two"), content="true")
  inspect(values().contains("three"), content="false")
}

///|
test "HAMT::iter" {
  let data = @hashmap.from_array([
    (0, "a"),
    (2, "b"),
    (3, "d"),
    (5, "e"),
    (11111, "f"),
  ])
  let array = data.iter().collect()
  array.sort()
  inspect(
    array,
    content=(
      #|[(0, "a"), (2, "b"), (3, "d"), (5, "e"), (11111, "f")]
    ),
  )
}

///|
test "HAMT::iter2" {
  let data = @hashmap.from_array([
    (0, "a"),
    (2, "b"),
    (3, "d"),
    (5, "e"),
    (11111, "f"),
  ])
  let array = data.iter2().to_array()
  array.sort()
  inspect(
    array,
    content=(
      #|[(0, "a"), (2, "b"), (3, "d"), (5, "e"), (11111, "f")]
    ),
  )
}

///|
test "HAMT::iter2 with early break" {
  let data = @hashmap.from_array([(1, "a"), (2, "b"), (3, "c")])
  let mut count = 0
  for _k, _v in data.iter2() {
    count += 1
    if count == 2 {
      break
    }
  }
  assert_eq(count, 2)
}

///|
test "HAMT::from_iter" {
  let iter = [(1, "one"), (2, "two"), (3, "three")].iter()
  let map = @hashmap.from_iter(iter)
  assert_eq(map.get(1), Some("one"))
  assert_eq(map.get(2), Some("two"))
  assert_eq(map.get(3), Some("three"))
}

///|
test "HAMT::from_iter empty" {
  let map : @hashmap.HashMap[Int, Int] = @hashmap.from_iter(Iter::empty())
  assert_eq(map.length(), 0)
}

///|
test "HAMT::to_string" {
  let map = @hashmap.new()
    .add(1, 1)
    .add(3, 3)
    .add(0x0f_ff_ff_ff, 0x0f_ff_ff_ff)
    .add(42, 42)
  let array = map.to_array()
  assert_eq(map.to_string(), "@immut/hashmap.from_array(\{array})")
}

///|
test "HAMT::from_array" {
  let map = @hashmap.from_array([(1, "1"), (2, "2"), (42, "42")])
  inspect(
    (1, map.get(1)),
    content=(
      #|(1, Some("1"))
    ),
  )
  inspect(
    (2, map.get(2)),
    content=(
      #|(2, Some("2"))
    ),
  )
  inspect(
    (42, map.get(42)),
    content=(
      #|(42, Some("42"))
    ),
  )
  inspect((43, map.get(43)), content="(43, None)")
}

///|
test "to_array" {
  let m = @hashmap.from_array([(1, "one"), (2, "two")])
  let arr = m.to_array()
  inspect(arr.length(), content="2")
  assert_eq(arr.contains((1, "one")), true)
  assert_eq(arr.contains((2, "two")), true)
  assert_eq(arr.contains((3, "three")), false)
}

///|
test "HAMT::iter on empty map" {
  let map : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let iter = map.iter()
  assert_eq(iter.next(), None)
}

///|
test "HAMT::iter on collision map" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let iter = map.iter()
  let results = []
  while iter.next() is Some(pair) {
    results.push(pair)
  }
  assert_eq(results.length(), 2)
}

///|
test "HAMT::iter on branch map" {
  let map = @hashmap.from_array([(1, 10), (2, 20), (3, 30), (4, 40)])
  let iter = map.iter()
  let mut count = 0
  while iter.next() is Some(_) {
    count += 1
  }
  assert_eq(count, 4)
}

///|
test "eq for boundary cases" {
  // Test with empty maps
  let empty_map1 : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let empty_map2 : @hashmap.HashMap[Int, Int] = @hashmap.new()
  inspect(empty_map1 == empty_map2, content="true")

  // Test with one empty map and one non-empty map
  let non_empty_map : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(1, 1)])
  inspect(empty_map1 == non_empty_map, content="false")
  inspect(non_empty_map == empty_map1, content="false")

  // Test with maps of different sizes
  let larger_map : @hashmap.HashMap[Int, Int] = @hashmap.from_array([
    (1, 1),
    (2, 2),
  ])
  inspect(non_empty_map == larger_map, content="false")
}

///|
test "eq for random cases" {
  // Test with maps containing different keys
  let map1 : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(1, 1), (2, 2)])
  let map2 : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(1, 1), (3, 3)])
  inspect(map1 == map2, content="false")

  // Test with maps containing same keys but different values
  let map3 : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(1, 1), (2, 3)])
  inspect(map1 == map3, content="false")

  // Test with maps containing same keys and values but in different order
  let map4 : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(2, 2), (1, 1)])
  inspect(map1 == map4, content="true")

  // Test with maps containing same keys and values but with different hash collisions
  let map5 : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(1, 1), (11, 11)])
  let map6 : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(1, 1), (11, 11)])
  inspect(map5 == map6, content="true")

  // Test with maps containing same keys and values but with different hash collisions and different order
  let map7 : @hashmap.HashMap[Int, Int] = @hashmap.from_array([(11, 11), (1, 1)])
  inspect(map5 == map7, content="true")
}

///|
test "eq for random cases with different types" {
  // Test with maps containing different types
  let map8 : @hashmap.HashMap[String, Int] = @hashmap.from_array([
    ("one", 1),
    ("two", 2),
  ])
  let map9 : @hashmap.HashMap[String, Int] = @hashmap.from_array([
    ("one", 1),
    ("two", 2),
  ])
  inspect(map8 == map9, content="true")

  // Test with maps containing same keys but different values of different types
  let map10 : @hashmap.HashMap[String, Int] = @hashmap.from_array([
    ("one", 1),
    ("two", 3),
  ])
  inspect(map8 == map10, content="false")

  // Test with maps containing different keys of different types
  let map11 : @hashmap.HashMap[String, Int] = @hashmap.from_array([
    ("one", 1),
    ("three", 3),
  ])
  inspect(map8 == map11, content="false")
}

///|
test "hash" {
  let map1 = @hashmap.from_array([("one", 1), ("two", 2)])
  let map2 = @hashmap.from_array([("one", 1), ("two", 2)])
  inspect(map1.hash() == map2.hash(), content="true")
  let map3 = @hashmap.from_array([("two", 2), ("one", 1)])
  inspect(map1.hash() == map3.hash(), content="true")
  let map4 = @hashmap.from_array([("one", 1), ("two", 2), ("three", 3)])
  inspect(map1.hash() == map4.hash(), content="false")
}

///|
test "each on empty map" {
  let empty = @hashmap.new()
  let mut sum = 0
  empty.each((k : Int, v : Int) => sum = sum + k + v)
  inspect(sum, content="0")
}

///|
test "remove non-existent key with hash collision" {
  let map = @hashmap.from_array([("a", 1)])
  let new_map = map.remove("b")
  inspect(new_map.length(), content="1")
}

///|
test "remove all keys from collision bucket" {
  let map = @hashmap.from_array([("a", 1), ("b", 2)])
  let map1 = map.remove("a")
  let map2 = map1.remove("b")
  inspect(map2.length(), content="0")
}

///|
test "union 2 hashmaps, choose the right hand side" {
  let map1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let map2 = @hashmap.from_array([(1, 10), (2, 20), (4, 40)])
  let map3 = map1.union(map2)
  let map4 = @hashmap.from_array([(1, 10), (2, 20), (3, 3), (4, 40)])
  inspect(map3 == map4, content="true")
}

///|
test "union 2 hashmaps, without conflict" {
  let map1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let map2 = @hashmap.from_array([(4, 4), (5, 5), (6, 6)])
  let map3 = map1.union(map2)
  let map4 = @hashmap.from_array([
    (1, 1),
    (2, 2),
    (3, 3),
    (4, 4),
    (5, 5),
    (6, 6),
  ])
  inspect(map3 == map4, content="true")
}

///|
test "HAMT::contains" {
  let map = @hashmap.from_array([(1, "one")])
  inspect(map.contains(1), content="true")
  inspect(map.contains(2), content="false")
  let map2 = map.add(2, "two")
  inspect(map2.contains(2), content="true")
  let map3 = map.remove(2)
  inspect(map3.contains(2), content="false")
}

///|
test "filter with simple predicate" {
  let map = @hashmap.from_array([(1, 1), (2, 2), (3, 3), (4, 4)])
  let only_even = map.filter((_, v) => v % 2 == 0)
  inspect(only_even.contains(1), content="false")
  inspect(only_even.contains(2), content="true")
  inspect(only_even.contains(3), content="false")
  inspect(only_even.contains(4), content="true")
}

///|
test "filter with all elements matching" {
  let map = @hashmap.from_array([(1, 1), (2, 2)])
  let filtered = map.filter((_, v) => v > 0)
  inspect(filtered.contains(1), content="true")
  inspect(filtered.contains(2), content="true")
}

///|
test "filter with no elements matching" {
  let map = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let filtered = map.filter((_, v) => v > 10)
  assert_eq(filtered.get(1), None)
  assert_eq(filtered.get(2), None)
  assert_eq(filtered.get(3), None)
  inspect(filtered.length(), content="0")
}

///|
test "filter with collision" {
  let map = @hashmap.from_array([(1, 10), (2, 20)]).add(1, 30)
  let filtered = map.filter((_, v) => v == 30)
  assert_eq(filtered.get(1), Some(30))
  assert_eq(filtered.get(2), None)
}

///|
test "filter with branch nodes" {
  let map = loop (0, @hashmap.new()) {
    (10, map) => map
    (i, map) => continue (i + 1, map.add(i, i * 10))
  }
  let filtered = map.filter((_, v) => v % 20 == 0)
  for i in 0..<10 {
    if i * 10 % 20 == 0 {
      assert_eq(filtered.get(i), Some(i * 10))
    } else {
      assert_eq(filtered.get(i), None)
    }
  }
}

///|
test "HAMT::fold_with_key" {
  let map = @hashmap.from_array([(1, "a"), (2, "b")])
  let result = map.fold(init="", (acc, k, v) => acc + "\{k}:\{v}, ")
  // order of elements is not guaranteed, so we check for substrings
  inspect(result.contains("1:a"), content="true")
  inspect(result.contains("2:b"), content="true")
}

///|
test "HAMT::fold" {
  let map = @hashmap.from_array([(1, 10), (2, 20), (3, 30)])
  let result = map.fold(init=0, (acc, _, v) => acc + v)
  inspect(result, content="60")
}

///|
test "HAMT::map" {
  let map = @hashmap.from_array([(1, 10), (2, 20)])
  let mapped = map.map((_, v) => v * 2)
  assert_eq(mapped.get(1), Some(20))
  assert_eq(mapped.get(2), Some(40))
  assert_eq(mapped.get(3), None)
}

///|
test "HAMT::map with overflow" {
  let max = 2147483647 // Int.max_value
  let map = @hashmap.from_array([(1, max)])
  let mapped = map.map((_, v) => v + 1)
  assert_eq(mapped.get(1), Some(-2147483648))
}

///|
test "HAMT::map_with_key empty" {
  let map : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let mapped = map.map((_k, v) => v)
  inspect(mapped.length(), content="0")
}

///|
test "HAMT::map_with_key leaf" {
  let map = @hashmap.singleton(42, 100) // Leaf
  let mapped = map.map((k, v) => k + v)
  assert_eq(mapped.get(42), Some(142))
  inspect(mapped.length(), content="1")
}

///|
test "HAMT::map_with_key collision" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)]) // Collision
  let mapped = map.map((k, v) => k.0 + ":" + v.to_string())
  assert_eq(mapped.get(MyString("a")), Some("a:1"))
  assert_eq(mapped.get(MyString("b")), Some("b:2"))
  assert_eq(mapped.get(MyString("c")), None)
}

///|
test "HAMT::map_with_key branch" {
  let map = loop (0, @hashmap.new()) {
    (10, map) => map
    (i, map) => continue (i + 1, map.add(i, i * 10))
  } // Branch
  let mapped = map.map((k, v) => k * 100 + v)
  for i in 0..<10 {
    assert_eq(mapped.get(i), Some(i * 100 + i * 10))
  }
  assert_eq(mapped.get(100), None)
}

///|
test "HAMT::singleton" {
  let map = @hashmap.singleton(1, "one")
  inspect(map.length(), content="1")
  assert_eq(map.get(1), Some("one"))
  assert_eq(map.get(2), None)
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
struct SegKey(Int, Int)

///|
impl Hash for SegKey with hash(self) {
  let SegKey(_, hash) = self
  hash
}

///|
impl Hash for SegKey with hash_combine(self, hasher) {
  let SegKey(_, hash) = self
  hasher.combine_int(hash)
}

///|
impl Eq for SegKey with equal(self, other) {
  self.0 == other.0
}

///|
test "get collision" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  assert_eq(map.get(MyString("a")), Some(1))
  assert_eq(map.get(MyString("b")), Some(2))
  assert_eq(map.get(MyString("c")), None)
}

///|
test "add_with_hash collision" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  assert_eq(map.get(MyString("a")), Some(1))
  assert_eq(map.get(MyString("b")), Some(2))
  assert_eq(map.get(MyString("c")), None)
  let map = map.add(MyString("c"), 3)
  assert_eq(map.get(MyString("c")), Some(3))
}

///|
test "HAMT join_2 last segment split" {
  let k1 = SegKey(1, 0)
  let k2 = SegKey(2, 1 << 25)
  let map = @hashmap.new().add(k1, "a").add(k2, "b")
  inspect(map.get(k1), content="Some(\"a\")")
  inspect(map.get(k2), content="Some(\"b\")")
}

///|
test "HAMT leaf bucket updates" {
  let map = @hashmap.new()
    .add(MyString("a"), 1)
    .add(MyString("b"), 2)
    .add(MyString("c"), 3)
  let map = map.add(MyString("c"), 30)
  inspect(map.get(MyString("c")), content="Some(30)")
  let map = map.add(MyString("a"), 10)
  inspect(map.get(MyString("a")), content="Some(10)")
}

///|
test "empty filtering" {
  let map : @hashmap.HashMap[Int, Int] = @hashmap.from_array([])
  let _filtered = map.filter((_, v) => v > 2)
  inspect(map.length(), content="0")
}

///|
test "filter with collision - all removed" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let filtered = map.filter((_, v) => v > 2)
  inspect(filtered.length(), content="0")
}

///|
test "filter with collision - one left" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let filtered = map.filter((_, v) => v == 1)
  inspect(filtered.length(), content="1")
}

///|
test "filter with collision - more than one left" {
  let map = @hashmap.from_array([
    (MyString("a"), 1),
    (MyString("b"), 2),
    (MyString("c"), 3),
  ])
  let filtered = map.filter((_, v) => v > 1)
  inspect(filtered.length(), content="2")
}

///|
test "HAMT::fold_with_key on empty" {
  let map : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let result = map.fold(init=0, (acc, _k, _v) => acc + 1)
  inspect(result, content="0")
}

///|
test "HAMT::fold_with_key on collision" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let result = map.fold(init=0, (acc, _k, v) => acc + v)
  inspect(result, content="3")
}

///|
test "HAMT::remove_with_hash collision" {
  let map = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let map1 = map.remove(MyString("c"))
  inspect(map1.length(), content="2")
  let map2 = map.remove(MyString("a"))
  assert_eq(map2.get(MyString("a")), None)
  assert_eq(map2.get(MyString("b")), Some(2))
  inspect(map2.length(), content="1")
  let map3 = map2.remove(MyString("b"))
  inspect(map3.length(), content="0")
}

///|
test "HAMT::remove from empty map" {
  let map : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let map2 = map.remove(42)
  assert_eq(map2.length(), 0)
}

///|
test "HAMT::remove from collision bucket non-primary key" {
  let map = @hashmap.from_array([
    (MyString("a"), 1),
    (MyString("b"), 2),
    (MyString("c"), 3),
  ])
  let map2 = map.remove(MyString("b"))
  assert_eq(map2.get(MyString("a")), Some(1))
  assert_eq(map2.get(MyString("b")), None)
  assert_eq(map2.get(MyString("c")), Some(3))
  assert_eq(map2.length(), 2)
}

///|
test "HAMT::union with empty" {
  let m1 = @hashmap.from_array([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq(m1.union(m2), m1)
  assert_eq(m2.union(m1), m1)
}

///|
test "HAMT::union with leaf" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(3, 3)
  let m3 = @hashmap.singleton(2, 20)
  assert_eq(m1.union(m2).get(3), Some(3))
  assert_eq(m1.union(m3).get(2), Some(20))
  assert_eq(m3.union(m1).get(2), Some(2))
}

///|
test "HAMT::union with branch" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.from_array([(4, 4), (5, 5), (6, 6)])
  let u = m1.union(m2)
  for i in 1..=6 {
    inspect(u.contains(i), content="true")
  }
}

///|
test "HAMT::union with collision" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("b"), 20), (MyString("c"), 3)])
  let u = m1.union(m2)
  assert_eq(u.get(MyString("a")), Some(1))
  assert_eq(u.get(MyString("b")), Some(20))
  assert_eq(u.get(MyString("c")), Some(3))
}

///|
test "HAMT::union collision all keys in second" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([
    (MyString("a"), 10),
    (MyString("b"), 20),
    (MyString("c"), 3),
  ])
  let u = m1.union(m2)
  assert_eq(u.get(MyString("a")), Some(10))
  assert_eq(u.get(MyString("b")), Some(20))
  assert_eq(u.get(MyString("c")), Some(3))
  assert_eq(u.length(), 3)
}

///|
test "HAMT::union all cases" {
  let empty = @hashmap.new()
  let leaf = @hashmap.singleton(1, 1)
  let branch = @hashmap.from_array([(1, 1), (2, 2)])
  let collision = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  assert_eq(empty.union(leaf).get(1), Some(1))
  assert_eq(leaf.union(branch).get(2), Some(2))
  let u1 = branch.union(branch)
  assert_eq(u1.get(1), Some(1))
  assert_eq(u1.get(2), Some(2))
  let collision2 = @hashmap.from_array([(MyString("b"), 20), (MyString("c"), 3)])
  let u2 = collision.union(collision2)
  assert_eq(u2.get(MyString("a")), Some(1))
  assert_eq(u2.get(MyString("b")), Some(20))
  assert_eq(u2.get(MyString("c")), Some(3))
}

///|
test "HAMT::union leaf to non-overlapping map" {
  let leaf = @hashmap.singleton(42, 100)
  let other = @hashmap.from_array([(1, 1), (2, 2)])
  let u = leaf.union(other)
  assert_eq(u.get(42), Some(100))
  assert_eq(u.get(1), Some(1))
  assert_eq(u.get(2), Some(2))
}

///|
test "HAMT::intersection with empty" {
  let m1 = @hashmap.from_array([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq(m1.intersection(m2).length(), 0)
  assert_eq(m2.intersection(m1).length(), 0)
}

///|
test "HAMT::intersection with leaf" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(2, 2)
  let m3 = @hashmap.singleton(3, 3)
  assert_eq(m1.intersection(m2).get(2), Some(2))
  assert_eq(m1.intersection(m3).get(3), None)
  assert_eq(m2.intersection(m1).get(2), Some(2))
}

///|
test "HAMT::intersection with branch" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.from_array([(2, 2), (3, 30), (4, 4)])
  let inter = m1.intersection(m2)
  assert_eq(inter.get(1), None)
  assert_eq(inter.get(2), Some(2))
  assert_eq(inter.get(3), Some(30))
  assert_eq(inter.get(4), None)
}

///|
test "HAMT::intersection singleton with non-overlapping branch" {
  let m1 = @hashmap.singleton(10, 100)
  let m2 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let inter = m1.intersection(m2)
  assert_eq(inter.length(), 0)
  assert_eq(inter.get(10), None)
}

///|
test "HAMT::intersection branch with non-overlapping branch" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.from_array([(3, 3), (4, 4)])
  let inter = m1.intersection(m2)
  assert_eq(inter.length(), 0)
}

///|
test "HAMT::intersection branch to single flat" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (100, 100)])
  let m2 = @hashmap.from_array([(1, 10), (3, 3), (200, 200)])
  let inter = m1.intersection(m2)
  assert_eq(inter.length(), 1)
  assert_eq(inter.get(1), Some(10))
  assert_eq(inter.get(2), None)
  assert_eq(inter.get(3), None)
}

///|
test "HAMT::intersection with collision" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("b"), 20), (MyString("c"), 3)])
  let inter = m1.intersection(m2)
  assert_eq(inter.get(MyString("a")), None)
  assert_eq(inter.get(MyString("b")), Some(20))
  assert_eq(inter.get(MyString("c")), None)
}

///|
test "HAMT::intersection with collision no overlap" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("c"), 3), (MyString("d"), 4)])
  let inter = m1.intersection(m2)
  assert_eq(inter.length(), 0)
}

///|
test "HAMT::intersection_with with empty" {
  let m1 = @hashmap.from_array([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq(m1.intersection_with(m2, (_k, v1, v2) => v1 + v2).length(), 0)
  assert_eq(m2.intersection_with(m1, (_k, v1, v2) => v1 + v2).length(), 0)
}

///|
test "HAMT::intersection_with with leaf" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(2, 20)
  let m3 = @hashmap.singleton(3, 30)
  assert_eq(m1.intersection_with(m2, (_k, v1, v2) => v1 + v2).get(2), Some(22))
  assert_eq(m1.intersection_with(m3, (_k, v1, v2) => v1 + v2).get(3), None)
  assert_eq(m2.intersection_with(m1, (_k, v1, v2) => v1 + v2).get(2), Some(22))
}

///|
test "HAMT::intersection_with with branch" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.from_array([(2, 20), (3, 30), (4, 4)])
  let inter = m1.intersection_with(m2, (_k, v1, v2) => v1 * v2)
  assert_eq(inter.get(1), None)
  assert_eq(inter.get(2), Some(40))
  assert_eq(inter.get(3), Some(90))
  assert_eq(inter.get(4), None)
}

///|
test "HAMT::intersection_with singleton with non-overlapping branch" {
  let m1 = @hashmap.singleton(10, 100)
  let m2 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let inter = m1.intersection_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(inter.length(), 0)
}

///|
test "HAMT::intersection_with branch returns single element" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.from_array([(2, 20), (4, 4)])
  let inter = m1.intersection_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(inter.get(1), None)
  assert_eq(inter.get(2), Some(22))
  assert_eq(inter.get(3), None)
  assert_eq(inter.get(4), None)
}

///|
test "HAMT::intersection_with branch to single flat" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (100, 100)])
  let m2 = @hashmap.from_array([(1, 10), (3, 3), (200, 200)])
  let inter = m1.intersection_with(m2, (_k, v1, v2) => v1 * v2)
  assert_eq(inter.length(), 1)
  assert_eq(inter.get(1), Some(10))
}

///|
test "HAMT::intersection_with with collision" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("a"), 10), (MyString("c"), 3)])
  let inter = m1.intersection_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(inter.get(MyString("a")), Some(11))
  assert_eq(inter.get(MyString("b")), None)
  assert_eq(inter.get(MyString("c")), None)
}

///|
test "HAMT::intersection_with collision no overlap" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("c"), 3), (MyString("d"), 4)])
  let inter = m1.intersection_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(inter.length(), 0)
}

///|
test "HAMT::difference with empty" {
  let m1 = @hashmap.from_array([(1, 1)])
  let m2 = @hashmap.new()
  assert_eq(m1.difference(m2), m1)
  assert_eq(m2.difference(m1).length(), 0)
}

///|
test "HAMT::difference with leaf" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(2, 2)
  let m3 = @hashmap.singleton(3, 3)
  assert_eq(m1.difference(m2).get(2), None)
  assert_eq(m1.difference(m3).get(1), Some(1))
  assert_eq(m2.difference(m1).length(), 0)
}

///|
test "HAMT::difference with branch" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.from_array([(2, 2), (3, 30), (4, 4)])
  let diff = m1.difference(m2)
  assert_eq(diff.get(1), Some(1))
  assert_eq(diff.get(2), None)
  assert_eq(diff.get(3), None)
  assert_eq(diff.get(4), None)
}

///|
test "HAMT::difference singleton with non-overlapping branch" {
  let m1 = @hashmap.singleton(10, 100)
  let m2 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let diff = m1.difference(m2)
  assert_eq(diff.get(10), Some(100))
  assert_eq(diff.length(), 1)
}

///|
test "HAMT::difference branch becomes empty" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.from_array([(1, 10), (2, 20), (3, 30)])
  let diff = m1.difference(m2)
  assert_eq(diff.length(), 0)
}

///|
test "HAMT::difference branch to single flat" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (100, 100)])
  let m2 = @hashmap.from_array([(1, 10), (3, 3), (200, 200)])
  let diff = m1.difference(m2)
  assert_eq(diff.length(), 2)
  assert_eq(diff.get(1), None)
  assert_eq(diff.get(2), Some(2))
  assert_eq(diff.get(100), Some(100))
}

///|
test "HAMT::difference with collision" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("b"), 20), (MyString("c"), 3)])
  let diff = m1.difference(m2)
  assert_eq(diff.get(MyString("a")), Some(1))
  assert_eq(diff.get(MyString("b")), None)
  assert_eq(diff.get(MyString("c")), None)
}

///|
test "HAMT::difference collision becomes empty" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("a"), 10), (MyString("b"), 20)])
  let diff = m1.difference(m2)
  assert_eq(diff.length(), 0)
}

///|
test "HAMT::each" {
  let empty = @hashmap.new()
  let mut sum = 0
  empty.each((k : Int, v : Int) => sum = sum + k + v)
  inspect(sum, content="0")
  let leaf = @hashmap.singleton(1, 10)
  let mut sum_leaf = 0
  leaf.each((k, v) => sum_leaf = sum_leaf + k + v)
  inspect(sum_leaf, content="11")
  let collision = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let mut sum_collision = 0
  collision.each((_k : MyString, v : Int) => sum_collision = sum_collision + v)
  inspect(sum_collision, content="3")
  let branch = @hashmap.from_array([(1, 1), (2, 2), (3, 3), (4, 4)])
  let mut sum_branch = 0
  branch.each((_k, v) => sum_branch = sum_branch + v)
  inspect(sum_branch, content="10")
}

///|
test "arbitrary" {
  let m : Array[@hashmap.HashMap[Int, Int]] = @quickcheck.samples(10)
  inspect(m.length(), content="10")
}

///|
test "equal imply hash equal when collision" {
  let s1 = MyString("1")
  let s2 = MyString("2")
  inspect(s1.hash() == s2.hash(), content="true") // collisions
  let ma = @hashmap.new().add(s1, 1).add(s2, 2)
  let mb = @hashmap.new().add(s2, 2).add(s1, 1)
  inspect(ma == mb, content="true")
  inspect(ma.hash() == mb.hash(), content="true")
}

///|
test "HAMT::union_with with empty" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.new()
  let u1 = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u1.get(1), Some(1))
  assert_eq(u1.get(2), Some(2))
  let u2 = m2.union_with(m1, (_k, v1, v2) => v1 + v2)
  assert_eq(u2.get(1), Some(1))
  assert_eq(u2.get(2), Some(2))
}

///|
test "HAMT::union_with with leaf" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2)])
  let m2 = @hashmap.singleton(2, 20)
  let m3 = @hashmap.singleton(3, 30)
  let u1 = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u1.get(1), Some(1))
  assert_eq(u1.get(2), Some(22))
  let u2 = m1.union_with(m3, (_k, v1, v2) => v1 + v2)
  assert_eq(u2.get(1), Some(1))
  assert_eq(u2.get(2), Some(2))
  assert_eq(u2.get(3), Some(30))
}

///|
test "HAMT::union_with with branch" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.from_array([(2, 20), (3, 30), (4, 40)])
  let u = m1.union_with(m2, (_k, v1, v2) => v1 * v2)
  assert_eq(u.get(1), Some(1))
  assert_eq(u.get(2), Some(40))
  assert_eq(u.get(3), Some(90))
  assert_eq(u.get(4), Some(40))
}

///|
test "HAMT::union_with with collision" {
  let m1 = @hashmap.from_array([(MyString("a"), 1), (MyString("b"), 2)])
  let m2 = @hashmap.from_array([(MyString("b"), 20), (MyString("c"), 3)])
  let u = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u.get(MyString("a")), Some(1))
  assert_eq(u.get(MyString("b")), Some(22))
  assert_eq(u.get(MyString("c")), Some(3))
}

///|
test "HAMT::union_with all non-overlapping" {
  let m1 = @hashmap.from_array([(1, 10), (2, 20)])
  let m2 = @hashmap.from_array([(3, 30), (4, 40)])
  let u = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u.get(1), Some(10))
  assert_eq(u.get(2), Some(20))
  assert_eq(u.get(3), Some(30))
  assert_eq(u.get(4), Some(40))
}

///|
test "HAMT::union_with all overlapping" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.from_array([(1, 10), (2, 20), (3, 30)])
  let u = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u.get(1), Some(11))
  assert_eq(u.get(2), Some(22))
  assert_eq(u.get(3), Some(33))
}

///|
test "HAMT::union_with with custom merge function" {
  let m1 = @hashmap.from_array([(1, "a"), (2, "b")])
  let m2 = @hashmap.from_array([(2, "c"), (3, "d")])
  let u = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u.get(1), Some("a"))
  assert_eq(u.get(2), Some("bc"))
  assert_eq(u.get(3), Some("d"))
}

///|
test "HAMT::union_with singleton with branch" {
  let m1 = @hashmap.singleton(1, 10)
  let m2 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let u = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u.get(1), Some(11))
  assert_eq(u.get(2), Some(2))
  assert_eq(u.get(3), Some(3))
}

///|
test "HAMT::union_with branch with singleton" {
  let m1 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let m2 = @hashmap.singleton(1, 10)
  let u = m1.union_with(m2, (_k, v1, v2) => v1 * v2)
  assert_eq(u.get(1), Some(10))
  assert_eq(u.get(2), Some(2))
  assert_eq(u.get(3), Some(3))
}

///|
test "HAMT::union_with singleton with non-overlapping branch" {
  let m1 = @hashmap.singleton(10, 100)
  let m2 = @hashmap.from_array([(1, 1), (2, 2), (3, 3)])
  let u = m1.union_with(m2, (_k, v1, v2) => v1 + v2)
  assert_eq(u.get(1), Some(1))
  assert_eq(u.get(2), Some(2))
  assert_eq(u.get(3), Some(3))
  assert_eq(u.get(10), Some(100))
}

///|
test "HAMT::merge is alias for union" {
  let map1 = @hashmap.from_array([("a", 1), ("b", 2)])
  let map2 = @hashmap.from_array([("b", 3), ("c", 4)])
  let merged = map1.merge(map2)
  inspect(merged.get("a"), content="Some(1)")
  inspect(merged.get("b"), content="Some(3)")
  inspect(merged.get("c"), content="Some(4)")
}
