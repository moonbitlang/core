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
test "capacity" {
  let m = @hashmap.new()
  inspect(m.capacity(), content="8")
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("d", 4)
  m.set("e", 5)
  m.set("f", 6)
  m.set("g", 7)
  m.set("h", 8)
  inspect(m.capacity(), content="16")
}

///|
test "T::retain - keep even values" {
  let map = @hashmap.from_array([
    ("a", 1),
    ("b", 2),
    ("c", 3),
    ("d", 4),
    ("e", 5),
  ])
  map.retain((_k, v) => v % 2 == 0)
  inspect(map.length(), content="2")
  inspect(map.get("a"), content="None")
  inspect(map.get("b"), content="Some(2)")
  inspect(map.get("c"), content="None")
  inspect(map.get("d"), content="Some(4)")
  inspect(map.get("e"), content="None")
}

///|
test "T::retain - keep all" {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  map.retain((_k, _v) => true)
  inspect(map.length(), content="3")
  inspect(map.get("a"), content="Some(1)")
  inspect(map.get("b"), content="Some(2)")
  inspect(map.get("c"), content="Some(3)")
}

///|
test "T::retain - remove all" {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  map.retain((_k, _v) => false)
  inspect(map.length(), content="0")
  inspect(map.is_empty(), content="true")
  inspect(map.get("a"), content="None")
  inspect(map.get("b"), content="None")
  inspect(map.get("c"), content="None")
}

///|
test "T::retain - empty map" {
  let map : @hashmap.HashMap[String, Int] = @hashmap.new()
  map.retain((_k, _v) => true)
  inspect(map.length(), content="0")
  inspect(map.is_empty(), content="true")
}

///|
test "T::retain - key-based filtering" {
  let map = @hashmap.from_array([
    ("apple", 5),
    ("banana", 6),
    ("cherry", 5),
    ("date", 4),
  ])
  map.retain((k, _v) => k.length() >= 6) // Keep keys with 6+ characters
  inspect(map.length(), content="2")
  inspect(map.get("apple"), content="None") // 5 chars
  inspect(map.get("banana"), content="Some(6)") // 6 chars
  inspect(map.get("cherry"), content="Some(5)") // 6 chars
  inspect(map.get("date"), content="None") // 4 chars
}

///|
test "T::retain - filter by both key and value" {
  let map = @hashmap.from_array([
    ("a1", 1),
    ("b2", 2),
    ("c3", 3),
    ("d4", 4),
    ("e5", 5),
  ])
  map.retain((k, v) => k.contains("2") || v > 3) // Keep keys containing "2" or values > 3
  inspect(map.length(), content="3")
  inspect(map.get("a1"), content="None")
  inspect(map.get("b2"), content="Some(2)") // key contains "2"
  inspect(map.get("c3"), content="None")
  inspect(map.get("d4"), content="Some(4)") // value > 3
  inspect(map.get("e5"), content="Some(5)") // value > 3
}

///|
test "T::retain - single element map" {
  let map = @hashmap.from_array([("only", 42)])

  // Test keeping the element
  map.retain((_k, v) => v > 30)
  inspect(map.length(), content="1")
  inspect(map.get("only"), content="Some(42)")

  // Test removing the element
  map.retain((_k, v) => v < 30)
  inspect(map.length(), content="0")
  inspect(map.is_empty(), content="true")
}

///|
test "T::retain - large map with complex predicate" {
  let map = @hashmap.new()
  for i = 0; i < 100; i = i + 1 {
    map.set("key" + i.to_string(), i)
  }

  // Keep only elements where value is divisible by 6 (both divisible by 2 and 3)
  map.retain((_k, v) => v % 6 == 0)
  inspect(map.length(), content="17") // 0, 6, 12, 18, ..., 96 (17 numbers)
  inspect(map.get("key0"), content="Some(0)")
  inspect(map.get("key6"), content="Some(6)")
  inspect(map.get("key12"), content="Some(12)")
  inspect(map.get("key1"), content="None")
  inspect(map.get("key2"), content="None")
  inspect(map.get("key3"), content="None")
}

///|
test "T::retain - with collisions" {
  // Create keys that likely hash to same buckets
  let map = @hashmap.new()
  let keys = ["a", "aa", "aaa", "aaaa", "aaaaa"]
  for i = 0; i < keys.length(); i = i + 1 {
    map.set(keys[i], i)
  }

  // Keep only keys with odd length
  map.retain((k, _v) => k.length() % 2 == 1)
  inspect(map.length(), content="3")
  inspect(map.get("a"), content="Some(0)") // length 1 (odd)
  inspect(map.get("aa"), content="None") // length 2 (even)
  inspect(map.get("aaa"), content="Some(2)") // length 3 (odd)
  inspect(map.get("aaaa"), content="None") // length 4 (even)
  inspect(map.get("aaaaa"), content="Some(4)") // length 5 (odd)
}

///|
test "T::retain - preserve map integrity after retain" {
  let map = @hashmap.from_array([("x", 1), ("y", 2), ("z", 3)])
  map.retain((_k, v) => v != 2) // Remove middle element

  // Test that map operations still work correctly
  map.set("w", 4)
  inspect(map.get("w"), content="Some(4)")
  inspect(map.length(), content="3")
  map.remove("x")
  inspect(map.get("x"), content="None")
  inspect(map.length(), content="2")
  map.clear()
  inspect(map.length(), content="0")
  inspect(map.is_empty(), content="true")
}
