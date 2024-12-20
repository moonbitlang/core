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

test "HAMT::size" {
  for i = 0, map = @hashmap.new(); i < 20; i = i + 1, map = map.add(i, i) {
    assert_eq!(map.size(), i)
  } else {
    assert_eq!(map.add(0, 0).size(), 20)
  }
}

test "HAMT" {
  let map = loop 0, @hashmap.new() {
    100, map => map
    i, map => continue i + 1, map.add(i, i)
  }
  for i = 0; i < 100; i = i + 1 {
    assert_eq!((i, map.find(i)), (i, Some(i)))
  }
  inspect!((100, map.find(100)), content="(100, None)")
  let map = map.add(100, 100)
  inspect!((100, map.find(100)), content="(100, Some(100))")
  // test for replacement
  let map = loop 0, map {
    100, map => map
    i, map => continue i + 2, map.add(i, i + 1)
  }
  for i = 0; i < 100; i = i + 2 {
    assert_eq!((i, map.find(i)), (i, Some(i + 1)))
    assert_eq!((i + 1, map.find(i + 1)), (i + 1, Some(i + 1)))
  }
}

test "HAMT::remove" {
  let map = loop 0, @hashmap.new() {
    100, map => map
    i, map => continue i + 1, map.add(i, i)
  }
  for i = 0; i < 100; i = i + 1 {
    assert_eq!((i, map.find(i)), (i, Some(i)))
  }
  let map = loop 0, map {
    100, map => map.remove(100) // test for removing non-existing element
    i, map => continue i + 2, map.remove(i)
  }
  for i = 0; i < 100; i = i + 2 {
    assert_eq!(map.find(i), None)
    assert_eq!(map.find(i + 1), Some(i + 1))
  }
}

test "HAMT::iter" {
  let data = @hashmap.of([(0, "a"), (2, "b"), (3, "d"), (5, "e"), (11111, "f")])
  let mut s = ""
  data.iter().each(fn { (k, v) => s += " \{k},\{v}" })
  inspect!(s, content=" 0,a 5,e 3,d 11111,f 2,b")
}

test "HAMT::to_string" {
  let map = @hashmap.new()
    .add(1, 1)
    .add(3, 3)
    .add(0x0f_ff_ff_ff, 0x0f_ff_ff_ff)
    .add(42, 42)
  inspect!(
    map,
    content="@immut/hashmap.of([(3, 3), (42, 42), (1, 1), (268435455, 268435455)])",
  )
}

test "HAMT::from_array" {
  let map = @hashmap.of([(1, "1"), (2, "2"), (42, "42")])
  inspect!(
    (1, map.find(1)),
    content=
      #|(1, Some("1"))
    ,
  )
  inspect!(
    (2, map.find(2)),
    content=
      #|(2, Some("2"))
    ,
  )
  inspect!(
    (42, map.find(42)),
    content=
      #|(42, Some("42"))
    ,
  )
  inspect!((43, map.find(43)), content="(43, None)")
}

test "from_iter multiple elements iter" {
  inspect!(
    @hashmap.T::from_iter([(1, 1), (2, 2), (3, 3)].iter()),
    content="@immut/hashmap.of([(3, 3), (2, 2), (1, 1)])",
  )
}

test "from_iter single element iter" {
  inspect!(
    @hashmap.T::from_iter([(1, 1)].iter()),
    content="@immut/hashmap.of([(1, 1)])",
  )
}

test "from_iter empty iter" {
  let pq : @hashmap.T[Int, Int] = @hashmap.T::from_iter(Iter::empty())
  inspect!(pq, content="@immut/hashmap.of([])")
}

test "eq for boundary cases" {
  // Test with empty maps
  let empty_map1 : @hashmap.T[Int, Int] = @hashmap.T::new()
  let empty_map2 : @hashmap.T[Int, Int] = @hashmap.T::new()
  inspect!(empty_map1 == empty_map2, content="true")

  // Test with one empty map and one non-empty map
  let non_empty_map : @hashmap.T[Int, Int] = @hashmap.T::of([(1, 1)])
  inspect!(empty_map1 == non_empty_map, content="false")
  inspect!(non_empty_map == empty_map1, content="false")

  // Test with maps of different sizes
  let larger_map : @hashmap.T[Int, Int] = @hashmap.T::of([(1, 1), (2, 2)])
  inspect!(non_empty_map == larger_map, content="false")
}

test "eq for random cases" {
  // Test with maps containing different keys
  let map1 : @hashmap.T[Int, Int] = @hashmap.T::of([(1, 1), (2, 2)])
  let map2 : @hashmap.T[Int, Int] = @hashmap.T::of([(1, 1), (3, 3)])
  inspect!(map1 == map2, content="false")

  // Test with maps containing same keys but different values
  let map3 : @hashmap.T[Int, Int] = @hashmap.T::of([(1, 1), (2, 3)])
  inspect!(map1 == map3, content="false")

  // Test with maps containing same keys and values but in different order
  let map4 : @hashmap.T[Int, Int] = @hashmap.T::of([(2, 2), (1, 1)])
  inspect!(map1 == map4, content="true")

  // Test with maps containing same keys and values but with different hash collisions
  let map5 : @hashmap.T[Int, Int] = @hashmap.T::of([(1, 1), (11, 11)])
  let map6 : @hashmap.T[Int, Int] = @hashmap.T::of([(1, 1), (11, 11)])
  inspect!(map5 == map6, content="true")

  // Test with maps containing same keys and values but with different hash collisions and different order
  let map7 : @hashmap.T[Int, Int] = @hashmap.T::of([(11, 11), (1, 1)])
  inspect!(map5 == map7, content="true")
}

test "eq for random cases with different types" {
  // Test with maps containing different types
  let map8 : @hashmap.T[String, Int] = @hashmap.T::of([("one", 1), ("two", 2)])
  let map9 : @hashmap.T[String, Int] = @hashmap.T::of([("one", 1), ("two", 2)])
  inspect!(map8 == map9, content="true")

  // Test with maps containing same keys but different values of different types
  let map10 : @hashmap.T[String, Int] = @hashmap.T::of([("one", 1), ("two", 3)])
  inspect!(map8 == map10, content="false")

  // Test with maps containing different keys of different types
  let map11 : @hashmap.T[String, Int] = @hashmap.T::of([
    ("one", 1),
    ("three", 3),
  ])
  inspect!(map8 == map11, content="false")
}

test "hash" {
  let map1 = @hashmap.T::of([("one", 1), ("two", 2)])
  let map2 = @hashmap.T::of([("one", 1), ("two", 2)])
  inspect!(map1.hash() == map2.hash(), content="true")
  let map3 = @hashmap.T::of([("two", 2), ("one", 1)])
  inspect!(map1.hash() == map3.hash(), content="true")
  let map4 = @hashmap.T::of([("one", 1), ("two", 2), ("three", 3)])
  inspect!(map1.hash() == map4.hash(), content="false")
}
