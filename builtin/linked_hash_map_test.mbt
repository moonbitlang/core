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
test "Map keys iter" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.keys()
  inspect(
    v,
    content=(
      #|["a", "b", "c"]
    ),
  )
  inspect(map.values(), content="[1, 2, 3]")
  inspect(({} : Map[String, Int]).keys(), content="[]")
  inspect(({} : Map[String, Int]).values(), content="[]")
}

///|
test "Map::default" {
  let m : Map[String, Int] = Default::default()
  inspect(m.length(), content="0")
}

///|
test "Map::of" {
  let arr : FixedArray[(String, Int)] = [("a", 1), ("b", 2), ("c", 3)]
  let map = Map::of(arr)
  inspect(map, content="{\"a\": 1, \"b\": 2, \"c\": 3}")
  inspect(map.length(), content="3")
  inspect(map.get("a"), content="Some(1)")
  inspect(map.get("b"), content="Some(2)")
  inspect(map.get("c"), content="Some(3)")
  let large_arr : FixedArray[(String, Int)] = [
    ("k1", 1),
    ("k2", 2),
    ("k3", 3),
    ("k4", 4),
    ("k5", 5),
    ("k6", 6),
    ("k7", 7),
    ("k8", 8),
    ("k9", 9),
    ("k10", 10),
    ("k11", 11),
    ("k12", 12),
    ("k13", 13),
    ("k14", 14),
  ]
  let large_map = Map::of(large_arr)
  inspect(large_map.length(), content="14")
  inspect(large_map.get("k1"), content="Some(1)")
  inspect(large_map.get("k14"), content="Some(14)")
}

///|
test "Map::from_iter" {
  let iter = [("a", 1), ("b", 2), ("c", 3)].iter()
  let map = Map::from_iter(iter)
  inspect(
    map,
    content=(
      #|{"a": 1, "b": 2, "c": 3}
    ),
  )
}

///|
test "Map::get_from_view" {
  let string_map : Map[String, Int] = { "alpha": 1, "beta": 2 }
  inspect(Map::get_from_string(string_map, "alp"[:]), content="None")
  inspect(Map::get_from_string(string_map, "alphx"[:]), content="None")
  inspect(Map::get_from_string(string_map, "alpha"[:]), content="Some(1)")
  let bytes_map : Map[Bytes, Int] = { b"abc": 10, b"xyz": 20 }
  inspect(Map::get_from_bytes(bytes_map, b"ab"[:]), content="None")
  inspect(Map::get_from_bytes(bytes_map, b"abd"[:]), content="None")
  inspect(Map::get_from_bytes(bytes_map, b"abc"[:]), content="Some(10)")
}

///|
test "Map::iter" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.iter()
  let mut res = ""
  while v.next() is Some((k, v)) {
    res = res + k + v.to_string()
  }
  inspect(res, content="a1b2c3")
}

///|
test "Map:: iter2" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.iter2()
  let mut res = ""
  v.each((k, v) => res = res + k + v.to_string())
  inspect(res, content="a1b2c3")
}

///|
test "map::contains_kv" {
  let map = { "a": 1, "b": 2, "c": 3 }
  // contains_kv will be used in the pattern matching
  // to avoid boxing
  inspect(map.contains_kv("a", 1), content="true")
  inspect(map.contains_kv("a", 2), content="false")
  guard map is { "a": 1, "b": 2, "c": 3, .. } else {
    fail("map is not { \"a\": 1, \"b\": 2, \"c\": 3 }")
  }
}

///|
test "Map::map" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let v = map.map((k, v) => k + v.to_string())
  inspect(
    v,
    content=(
      #|{"a": "a1", "b": "b2", "c": "c3"}
    ),
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let v = map.map((k, v) => k + v.to_string())
  inspect(
    v,
    content=(
      #|{"a": "a1", "b": "b2", "d": "d10", "e": "e20"}
    ),
  )
  let v : Map[String, String] = {}.map((k, v) => k + v)
  inspect(v, content="{}")
}

///|
test "Map::copy" {
  let map = { "a": 1, "b": 2, "c": 3 }
  let copy = map.copy()
  inspect(
    copy,
    content=(
      #|{"a": 1, "b": 2, "c": 3}
    ),
  )
  map["d"] = 10
  map["e"] = 20
  map.remove("c")
  let copy = map.copy()
  inspect(
    copy,
    content=(
      #|{"a": 1, "b": 2, "d": 10, "e": 20}
    ),
  )
  let copy : Map[String, String] = {}.copy()
  inspect(copy, content="{}")
}

///|
test "Map::update" {
  // Test updating existing value
  let map = { "a": 1, "b": 2, "c": 3 }
  map.update("a", fn(v) {
    match v {
      Some(x) => Some(x + 10)
      None => Some(0)
    }
  })
  inspect(map.get("a"), content="Some(11)")
  inspect(map.length(), content="3")

  // Test inserting new value when key doesn't exist
  map.update("d", fn(v) {
    match v {
      Some(x) => Some(x)
      None => Some(4)
    }
  })
  inspect(map.get("d"), content="Some(4)")
  inspect(map.length(), content="4")
  inspect(
    map,
    content=(
      #|{"a": 11, "b": 2, "c": 3, "d": 4}
    ),
  )

  // Test removing existing value by returning None
  map.update("b", fn(_) { None })
  inspect(map.get("b"), content="None")
  inspect(map.length(), content="3")
  inspect(
    map,
    content=(
      #|{"a": 11, "c": 3, "d": 4}
    ),
  )

  // Test no-op when key doesn't exist and function returns None
  map.update("e", fn(_) { None })
  inspect(map.get("e"), content="None")
  inspect(map.length(), content="3")

  // Test incrementing a counter (common use case)
  let counter_map : Map[String, Int] = {}
  counter_map.update("clicks", fn(v) {
    match v {
      Some(count) => Some(count + 1)
      None => Some(1)
    }
  })
  inspect(counter_map.get("clicks"), content="Some(1)")
  counter_map.update("clicks", fn(v) {
    match v {
      Some(count) => Some(count + 1)
      None => Some(1)
    }
  })
  inspect(counter_map.get("clicks"), content="Some(2)")

  // Test on empty map
  let empty_map : Map[String, Int] = {}

  // Test no-op on empty map
  empty_map.update("empty", fn(_) { None })

  // Test inserting new value on empty map
  empty_map.update("new", fn(v) {
    match v {
      Some(x) => Some(x * 2)
      None => Some(42)
    }
  })
  inspect(empty_map.get("new"), content="Some(42)")
  inspect(empty_map.length(), content="1")

  // Test adding to empty map
  let empty_map : Map[String, Int] = Map::new(capacity=1)
  empty_map.update("a", _ => Some(1))
  empty_map.update("b", _ => Some(2))
  empty_map.update("c", _ => Some(3))
}

///|
test "Map::retain - keep even values" {
  let map = { "a": 1, "b": 2, "c": 3, "d": 4, "e": 5 }
  map.retain((_k, v) => v % 2 == 0)
  inspect(map.length(), content="2")
  inspect(map.get("a"), content="None")
  inspect(map.get("b"), content="Some(2)")
  inspect(map.get("c"), content="None")
  inspect(map.get("d"), content="Some(4)")
  inspect(map.get("e"), content="None")
}

///|
test "Map::retain - keep all" {
  let map = { "a": 1, "b": 2, "c": 3 }
  map.retain((_k, _v) => true)
  inspect(map.length(), content="3")
  inspect(map.get("a"), content="Some(1)")
  inspect(map.get("b"), content="Some(2)")
  inspect(map.get("c"), content="Some(3)")
}

///|
test "Map::retain - remove all" {
  let map = { "a": 1, "b": 2, "c": 3 }
  map.retain((_k, _v) => false)
  inspect(map.length(), content="0")
  inspect(map.is_empty(), content="true")
  inspect(map.get("a"), content="None")
  inspect(map.get("b"), content="None")
  inspect(map.get("c"), content="None")
}

///|
test "Map::retain - empty map" {
  let map : Map[String, Int] = {}
  map.retain((_k, _v) => true)
  inspect(map.length(), content="0")
  inspect(map.is_empty(), content="true")
}

///|
test "Map::retain - key-based filtering" {
  let map = { "apple": 5, "banana": 6, "cherry": 5, "date": 4 }
  map.retain((k, _v) => k.length() >= 6) // Keep keys with 6+ characters
  inspect(map.length(), content="2")
  inspect(map.get("apple"), content="None") // 5 chars
  inspect(map.get("banana"), content="Some(6)") // 6 chars
  inspect(map.get("cherry"), content="Some(5)") // 6 chars
  inspect(map.get("date"), content="None") // 4 chars
}

///|
test "Map::retain - preserves order" {
  let map = { "first": 1, "second": 2, "third": 3, "fourth": 4 }
  map.retain((_k, v) => v % 2 == 0)

  // Check that the order is preserved
  let result = []
  map.each((k, v) => result.push((k, v)))
  inspect(result, content="[(\"second\", 2), (\"fourth\", 4)]")
}

///|
test "Map::retain - single element map" {
  let map = { "only": 42 }

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
test "Map::retain - filter by both key and value" {
  let map = { "a1": 1, "b2": 2, "c3": 3, "d4": 4, "e5": 5 }
  map.retain((k, v) => k.contains("2") || v > 3) // Keep keys containing "2" or values > 3
  inspect(map.length(), content="3")
  inspect(map.get("a1"), content="None")
  inspect(map.get("b2"), content="Some(2)") // key contains "2"
  inspect(map.get("c3"), content="None")
  inspect(map.get("d4"), content="Some(4)") // value > 3
  inspect(map.get("e5"), content="Some(5)") // value > 3
}

///|
test "Map::retain - large map performance" {
  let map : Map[String, Int] = Map::new()
  for i = 0; i < 1000; i = i + 1 {
    map.set("key" + i.to_string(), i)
  }

  // Keep only even values
  map.retain((_k, v) => v % 2 == 0)
  inspect(map.length(), content="500")

  // Verify some specific entries
  inspect(map.get("key0"), content="Some(0)")
  inspect(map.get("key2"), content="Some(2)")
  inspect(map.get("key1"), content="None")
  inspect(map.get("key3"), content="None")
}

///|
test "Map::retain - preserve map integrity after retain" {
  let map = { "x": 1, "y": 2, "z": 3 }
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

///|
test "Map::retain - complex predicate with string operations" {
  let map = {
    "apple": 5,
    "banana": 6,
    "cherry": 6,
    "date": 4,
    "elderberry": 10,
  }
  map.retain((k, v) => k.strip_prefix("a") is Some(_) ||
    k.strip_suffix("y") is Some(_) ||
    v >= 10)
  inspect(map.length(), content="3")
  inspect(map.get("apple"), content="Some(5)") // starts with "a"
  inspect(map.get("banana"), content="None") // no match
  inspect(map.get("cherry"), content="Some(6)") // ends with "y"
  inspect(map.get("date"), content="None") // no match
  inspect(map.get("elderberry"), content="Some(10)") // value >= 10
}

///|
test "Map::retain - iteration order after retain" {
  let map = { "first": 1, "second": 2, "third": 3, "fourth": 4, "fifth": 5 }
  map.retain((_k, v) => v != 3) // Remove third element

  // Check that insertion order is maintained for remaining elements
  let keys = []
  map.each((k, _v) => keys.push(k))
  inspect(keys, content="[\"first\", \"second\", \"fourth\", \"fifth\"]")
  let values = []
  map.each((_k, v) => values.push(v))
  inspect(values, content="[1, 2, 4, 5]")
}

///|
test "Map::retain - edge case with all elements removed then re-added" {
  let map = { "a": 1, "b": 2, "c": 3 }
  map.retain((_k, _v) => false) // Remove all
  inspect(map.length(), content="0")
  inspect(map.is_empty(), content="true")

  // Re-add elements
  map.set("x", 10)
  map.set("y", 20)
  inspect(map.length(), content="2")
  inspect(map.get("x"), content="Some(10)")
  inspect(map.get("y"), content="Some(20)")

  // Original keys should still be gone
  inspect(map.get("a"), content="None")
  inspect(map.get("b"), content="None")
  inspect(map.get("c"), content="None")
}

///|
test "Map::retain - with hash collisions simulation" {
  let map : Map[String, Int] = Map::new()
  // Create keys that might have similar hash values
  let keys = ["a", "aa", "aaa", "aaaa", "aaaaa", "aaaaaa"]
  for i = 0; i < keys.length(); i = i + 1 {
    map.set(keys[i], i + 1)
  }

  // Keep only keys with odd length
  map.retain((k, _v) => k.length() % 2 == 1)
  inspect(map.length(), content="3")
  inspect(map.get("a"), content="Some(1)") // length 1 (odd)
  inspect(map.get("aa"), content="None") // length 2 (even)
  inspect(map.get("aaa"), content="Some(3)") // length 3 (odd)
  inspect(map.get("aaaa"), content="None") // length 4 (even)
  inspect(map.get("aaaaa"), content="Some(5)") // length 5 (odd)
  inspect(map.get("aaaaaa"), content="None") // length 6 (even)
}

///|
test "Map::get_from_string" {
  let map = { "hello": 1, "world": 2, "test": 3 }

  // Test basic string view access
  let view1 = "hello"[:]
  inspect(map.get_from_string(view1), content="Some(1)")

  // Test string view from substring
  let full_str = "prefix_world_suffix"
  let view2 = full_str.view(start_offset=7, end_offset=12)
  inspect(map.get_from_string(view2), content="Some(2)")

  // Test non-existent key
  let view3 = "notfound"[:]
  inspect(map.get_from_string(view3), content="None")

  // Test length mismatch
  let short_view = "hell"[:]
  inspect(map.get_from_string(short_view), content="None")

  // Test content mismatch with same length
  let mismatch_view = "hella"[:]
  inspect(map.get_from_string(mismatch_view), content="None")

  // Test empty string
  let empty_map = { "": 42 }
  let empty_view = ""[:]
  inspect(empty_map.get_from_string(empty_view), content="Some(42)")

  // Test with longer string containing the key as substring
  let longer = "this is a test string"
  let test_view = longer.view(start_offset=10, end_offset=14)
  inspect(map.get_from_string(test_view), content="Some(3)")
}

///|
test "Map::get_from_bytes" {
  let map = { b"hello": 1, b"world": 2, b"test": 3 }

  // Test basic bytes view access
  let view1 = b"hello"[:]
  inspect(map.get_from_bytes(view1), content="Some(1)")

  // Test bytes view from sub-array
  let full_bytes = b"prefix_world_suffix"
  let view2 = full_bytes[7:12]
  inspect(map.get_from_bytes(view2), content="Some(2)")

  // Test non-existent key
  let view3 = b"notfound"[:]
  inspect(map.get_from_bytes(view3), content="None")

  // Test length mismatch
  let short_view = b"hell"[:]
  inspect(map.get_from_bytes(short_view), content="None")

  // Test content mismatch with same length
  let mismatch_view = b"hellx"[:]
  inspect(map.get_from_bytes(mismatch_view), content="None")

  // Test empty bytes
  let empty_map = { b"": 42 }
  let empty_view = b""[:]
  inspect(empty_map.get_from_bytes(empty_view), content="Some(42)")

  // Test with longer bytes containing the key as subbytes
  let longer = b"this is a test string"
  let test_view = longer[10:14]
  inspect(map.get_from_bytes(test_view), content="Some(3)")
}

///|
test "Map::merge" {
  let map1 : Map[String, Int] = { "a": 1, "b": 2 }
  let map2 : Map[String, Int] = { "b": 3, "c": 4 }
  let merged = map1.merge(map2)
  inspect(merged.get("a"), content="Some(1)")
  inspect(merged.get("b"), content="Some(3)")
  inspect(merged.get("c"), content="Some(4)")
  inspect(merged.length(), content="3")
  // Verify original maps are unchanged
  inspect(map1.get("b"), content="Some(2)")
  inspect(map1.length(), content="2")
}

///|
test "Map::merge empty maps" {
  let map1 : Map[String, Int] = Map::new()
  let map2 : Map[String, Int] = { "a": 1, "b": 2 }
  let merged1 = map1.merge(map2)
  inspect(merged1.length(), content="2")
  inspect(merged1.get("a"), content="Some(1)")
  let merged2 = map2.merge(map1)
  inspect(merged2.length(), content="2")
  inspect(merged2.get("b"), content="Some(2)")
  let merged3 = map1.merge(map1)
  inspect(merged3.length(), content="0")
}

///|
test "Map::merge_in_place" {
  let map1 : Map[String, Int] = { "a": 1, "b": 2 }
  let map2 : Map[String, Int] = { "b": 3, "c": 4 }
  map1.merge_in_place(map2)
  inspect(map1.get("a"), content="Some(1)")
  inspect(map1.get("b"), content="Some(3)")
  inspect(map1.get("c"), content="Some(4)")
  inspect(map1.length(), content="3")
  // Verify second map is unchanged
  inspect(map2.length(), content="2")
}

///|
test "Map::merge_in_place empty maps" {
  let map1 : Map[String, Int] = Map::new()
  let map2 : Map[String, Int] = { "a": 1, "b": 2 }
  map1.merge_in_place(map2)
  inspect(map1.length(), content="2")
  inspect(map1.get("a"), content="Some(1)")
  map1.merge_in_place(map1)
  inspect(map1.length(), content="2")
}

///|
priv struct LKey(Int, Int) derive(Eq)

///|
impl Hash for LKey with hash(self) {
  let LKey(_, hash) = self
  hash
}

///|
impl Hash for LKey with hash_combine(self, hasher) {
  let LKey(_, hash) = self
  hasher.combine_int(hash)
}

///|
test "Map collision probe paths" {
  let map : Map[LKey, Int] = {}
  let k1 = LKey::LKey(1, 1)
  let k2 = LKey::LKey(2, 2)
  map[k1] = 10
  map[k2] = 20
  let k1b = LKey::LKey(3, 1)
  map.update(k1b, fn(v) {
    match v {
      Some(_) => None
      None => Some(30)
    }
  })
  inspect(map.get(k1b), content="Some(30)")
  inspect(map[k1b], content="30")
  inspect(map.get_or_default(LKey::LKey(4, 0), 99), content="99")
  inspect(map.contains(LKey::LKey(5, 0)), content="false")
}

///|
test "Map early exit on psl" {
  let map : Map[LKey, Int] = {}
  let k1 = LKey::LKey(1, 0)
  let k2 = LKey::LKey(2, 1)
  map[k1] = 10
  map[k2] = 20
  let missing = LKey::LKey(3, 0)
  inspect(map.get_or_default(missing, 77), content="77")
  inspect(map.contains(missing), content="false")
}
