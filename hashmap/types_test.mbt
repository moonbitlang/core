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
test "HashMap equality - identical maps" {
  let map1 = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let map2 = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  assert_eq(map1, map2)
  assert_true(map1 == map2)
}

///|
test "HashMap equality - same content different order" {
  let map1 = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  let map2 = @hashmap.from_array([(3, "three"), (1, "one"), (2, "two")])
  assert_eq(map1, map2)
  assert_true(map1 == map2)
}

///|
test "HashMap equality - empty maps" {
  let map1 : @hashmap.HashMap[Int, String] = @hashmap.new()
  let map2 : @hashmap.HashMap[Int, String] = @hashmap.new()
  assert_eq(map1, map2)
  assert_true(map1 == map2)
}

///|
test "HashMap equality - different sizes" {
  let map1 = @hashmap.from_array([(1, "one"), (2, "two")])
  let map2 = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  assert_false(map1 == map2)
  assert_false(map2 == map1)
}

///|
test "HashMap equality - same size different keys" {
  let map1 = @hashmap.from_array([(1, "one"), (2, "two")])
  let map2 = @hashmap.from_array([(1, "one"), (3, "three")])
  assert_false(map1 == map2)
  assert_false(map2 == map1)
}

///|
test "HashMap equality - same size different values" {
  let map1 = @hashmap.from_array([(1, "one"), (2, "two")])
  let map2 = @hashmap.from_array([(1, "one"), (2, "different")])
  assert_false(map1 == map2)
  assert_false(map2 == map1)
}

///|
test "HashMap equality - one empty one non-empty" {
  let empty_map : @hashmap.HashMap[Int, String] = @hashmap.new()
  let non_empty_map = @hashmap.from_array([(1, "one")])
  assert_false(empty_map == non_empty_map)
  assert_false(non_empty_map == empty_map)
}

///|
test "HashMap equality - self equality" {
  let map = @hashmap.from_array([(1, "one"), (2, "two"), (3, "three")])
  assert_eq(map, map)
  assert_true(map == map)
}

///|
test "HashMap equality - mixed types" {
  let map1 = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  let map2 = @hashmap.from_array([("c", 3), ("a", 1), ("b", 2)])
  assert_eq(map1, map2)
  assert_true(map1 == map2)
  let map3 = @hashmap.from_array([("a", 1), ("b", 2), ("d", 4)])
  assert_false(map1 == map3)
}

///|
test "HashMap equality - after modifications" {
  let map1 = @hashmap.from_array([(1, "one"), (2, "two")])
  let map2 = @hashmap.from_array([(1, "one")])

  // Initially not equal
  assert_false(map1 == map2)

  // Add element to map2
  map2.set(2, "two")
  assert_true(map1 == map2)

  // Modify value in map1
  map1.set(1, "ONE")
  assert_false(map1 == map2)

  // Make them equal again
  map2.set(1, "ONE")
  assert_true(map1 == map2)
}
