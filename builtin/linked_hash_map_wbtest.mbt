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

///|
type MyString String derive(Eq)

///|
impl Hash for MyString with hash(self) { self._.length() }

///|
impl Hash for MyString with hash_combine(self, hasher) {
  hasher.combine_string(self._)
}

///|
impl Show for MyString with output(self, logger) { logger.write_string(self._) }

test "new" {
  let m : Map[Int, Int] = Map::new()
  assert_eq!(m.capacity, 8)
  assert_eq!(m.size, 0)
}

test "set" {
  let m : Map[MyString, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 1)
  m.set("bc", 2)
  m.set("abc", 3)
  m.set("cd", 2)
  m.set("c", 1)
  m.set("d", 1)
  assert_eq!(m.size, 7)
  assert_eq!(
    m.debug_entries(),
    "_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )
}

test "get" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get("a"), Some(1))
  assert_eq!(m.get("b"), Some(2))
  assert_eq!(m.get("c"), Some(3))
  assert_eq!(m.get("d"), None)
}

test "get_or_default" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get_or_default("a", 42), 1)
  assert_eq!(m.get_or_default("b", 42), 2)
  assert_eq!(m.get_or_default("c", 42), 3)
  assert_eq!(m.get_or_default("d", 42), 42)
}

test "get_or_init" {
  let m : Map[String, Array[Int]] = Map::new()
  m.get_or_init("a", fn() { Array::new() }).push(1)
  m.get_or_init("b", fn() { Array::new() }).push(2)
  m.get_or_init("a", fn() { Array::new() }).push(3)
  assert_eq!(m.get("a"), Some([1, 3]))
  assert_eq!(m.get("b"), Some([2]))
}

test "get_or_init" {
  let m : Map[String, Array[Int]] = Map::new()
  m.get_or_init("a", fn() { Array::new() }).push(1)
  m.get_or_init("b", fn() { Array::new() }).push(2)
  m.get_or_init("a", fn() { Array::new() }).push(3)
  assert_eq!(m.get("a"), Some([1, 3]))
  assert_eq!(m.get("b"), Some([2]))
}

test "op_set" {
  let m : Map[String, Int] = Map::new()
  m["a"] = 1
  m["b"] = 2
  assert_eq!(m.get("a"), Some(1))
  assert_eq!(m.get("b"), Some(2))
}

test "op_get" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  assert_eq!(m["a"], Some(1))
  assert_eq!(m["b"], Some(2))
  assert_eq!(m["c"], None)
}

test "set_update" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  assert_eq!(m.get("a"), Some(1))
  m.set("a", 2)
  assert_eq!(m.get("a"), Some(2))
}

test "contains" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  assert_eq!(m.contains("a"), true)
  assert_eq!(m.contains("b"), false)
}

test "from_array" {
  let m = { "a": 1, "b": 2, "c": 3 }
  assert_eq!(m.get("a"), Some(1))
  assert_eq!(m.get("b"), Some(2))
  assert_eq!(m.get("c"), Some(3))
}

test "size" {
  let m : Map[String, Int] = Map::new()
  assert_eq!(m.size(), 0)
  m.set("a", 1)
  assert_eq!(m.size(), 1)
}

test "is_empty" {
  let m : Map[String, Int] = Map::new()
  assert_eq!(m.is_empty(), true)
  m.set("a", 1)
  assert_eq!(m.is_empty(), false)
  m.remove("a")
  assert_eq!(m.is_empty(), true)
  m.remove("a")
  assert_eq!(m.is_empty(), true)
}

test "iter" {
  let m = { "a": 1, "b": 2, "c": 3 }
  let mut sum = 0
  m.each(fn(_k, v) { sum += v })
  assert_eq!(sum, 6)
}

test "iteri" {
  let m = { "a": 1, "b": 2, "c": 3 }
  let mut sum = 0
  let mut s = ""
  m.eachi(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  assert_eq!(s, "012")
  assert_eq!(sum, 6)
}

test "clear" {
  let m = { "a": 1, "b": 2, "c": 3 }
  m.clear()
  assert_eq!(m.size, 0)
  assert_eq!(m.capacity, 8)
  assert_eq!(m.head, None)
  assert_eq!(m.tail, None)
  for i = 0; i < m.capacity; i = i + 1 {
    assert_eq!(m.entries[i], None)
  }
}

test "grow" {
  let m : Map[MyString, Int] = Map::new()
  m.set("C", 1)
  m.set("Go", 2)
  m.set("C++", 3)
  m.set("Java", 4)
  m.set("Scala", 5)
  m.set("Julia", 5)
  assert_eq!(m.size(), 6)
  assert_eq!(m.capacity(), 8)
  m.set("Cobol", 5)
  assert_eq!(m.size(), 7)
  assert_eq!(m.capacity(), 16)
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  assert_eq!(m.size(), 10)
  assert_eq!(m.capacity(), 16)
  assert_eq!(
    m.debug_entries(),
    "_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_",
  )
}

test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let map = { 1: "one", 2: "two", 3: "three" }
  map
  .iter()
  .each(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\{k}-\{v}]")
    },
  )
  inspect!(buf, content="[1-one][2-two][3-three]")
  buf.reset()
  map
  .iter()
  .take(2)
  .each(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\{k}-\{v}]")
    },
  )
  inspect!(buf, content="[1-one][2-two]")
}

test "iter order" {
  let m = { "one": 1 }
  m["three"] = 3
  m["two"] = 2
  let buf = StringBuilder::new(size_hint=0)
  m.each(fn(k, v) { buf.write_string("[\{k}-\{v}]") })
  inspect!(buf.to_string(), content="[one-1][three-3][two-2]")
}

test "linked list" {
  let m = {}
  inspect!(m, content="{}")
  m["one"] = 1
  m["two"] = 2
  m["three"] = 3
  m["four"] = 4
  m["five"] = 5
  inspect!(
    m,
    content=
      #|{"one": 1, "two": 2, "three": 3, "four": 4, "five": 5}
    ,
  )
  m.remove("three")
  inspect!(
    m,
    content=
      #|{"one": 1, "two": 2, "four": 4, "five": 5}
    ,
  )
  m.set("two", 20)
  inspect!(
    m,
    content=
      #|{"one": 1, "two": 20, "four": 4, "five": 5}
    ,
  )
  m.remove("one")
  inspect!(
    m,
    content=
      #|{"two": 20, "four": 4, "five": 5}
    ,
  )
  m.remove("five")
  inspect!(
    m,
    content=
      #|{"two": 20, "four": 4}
    ,
  )
  m.remove("two")
  inspect!(
    m,
    content=
      #|{"four": 4}
    ,
  )
  m.remove("four")
  inspect!(m, content="{}")
}

test "to_array" {
  let map = { 1: "one", 2: "two", 3: "three" }
  inspect!(
    map.to_array(),
    content=
      #|[(1, "one"), (2, "two"), (3, "three")]
    ,
  )
}

test "set_existing_key" {
  let m = {}
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("a", 4)
  assert_eq!(m.size, 3)
  assert_eq!(m.get("a"), Some(4))
}

test "get_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get("d"), None)
}

test "get_or_default_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get_or_default("a", 42), 1)
}

test "get_or_default_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get_or_default("d", 42), 42)
}

test "remove_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("b")
  assert_eq!(m.size(), 2)
  assert_eq!(m.get("b"), None)
}

test "remove_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("d")
  assert_eq!(m.size(), 3)
}

test "contains_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.contains("b"), true)
}

test "contains_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.contains("d"), false)
}

test "clear" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  assert_eq!(m.size, 0)
  assert_eq!(m.capacity, 8)
  assert_eq!(m.head, None)
  assert_eq!(m.tail, None)
  for i = 0; i < m.capacity; i = i + 1 {
    assert_eq!(m.entries[i], None)
  }
}

test "iter" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.each(fn(_k, v) { sum += v })
  assert_eq!(sum, 6)
}

test "iteri" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  let mut s = ""
  m.eachi(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  assert_eq!(s, "012")
  assert_eq!(sum, 6)
}

test "to_array" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.to_array(), [("a", 1), ("b", 2), ("c", 3)])
}

test "new" {
  let m : Map[String, Int] = Map::new()
  assert_eq!(m.size, 0)
  assert_eq!(m.capacity, 8)
  assert_eq!(m.head, None)
  assert_eq!(m.tail, None)
  for i = 0; i < m.capacity; i = i + 1 {
    assert_eq!(m.entries[i], None)
  }
}

test "get" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get("a"), Some(1))
  assert_eq!(m.get("b"), Some(2))
  assert_eq!(m.get("c"), Some(3))
  assert_eq!(m.get("d"), None)
}

test "get_or_default" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get_or_default("a", 42), 1)
  assert_eq!(m.get_or_default("b", 42), 2)
  assert_eq!(m.get_or_default("c", 42), 3)
  assert_eq!(m.get_or_default("d", 42), 42)
}

test "contains" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  assert_eq!(m.contains("a"), true)
  assert_eq!(m.contains("b"), false)
}

test "size" {
  let m : Map[String, Int] = Map::new()
  assert_eq!(m.size, 0)
  m.set("a", 1)
  assert_eq!(m.size, 1)
}

test "is_empty" {
  let m : Map[String, Int] = Map::new()
  assert_eq!(m.is_empty(), true)
  m.set("a", 1)
  assert_eq!(m.is_empty(), false)
  m.remove("a")
  assert_eq!(m.is_empty(), true)
}

test "iter" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.each(fn(_k, v) { sum += v })
  assert_eq!(sum, 6)
}

test "iteri" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  let mut s = ""
  m.eachi(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  assert_eq!(s, "012")
  assert_eq!(sum, 6)
}

test "clear" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  assert_eq!(m.size, 0)
  assert_eq!(m.capacity, 8)
  assert_eq!(m.head, None)
  assert_eq!(m.tail, None)
  for i = 0; i < m.capacity; i = i + 1 {
    assert_eq!(m.entries[i], None)
  }
}

test "set_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("a", 4)
  assert_eq!(m.size, 3)
  assert_eq!(m.get("a"), Some(4))
}

test "get_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get("d"), None)
}

test "get_or_default_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get_or_default("a", 42), 1)
}

test "get_or_default_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.get_or_default("d", 42), 42)
}

test "remove_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("b")
  assert_eq!(m.size(), 2)
  assert_eq!(m.get("b"), None)
}

test "remove_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("d")
  assert_eq!(m.size(), 3)
}

test "contains_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.contains("b"), true)
}

test "contains_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.contains("d"), false)
}

test "clear" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  assert_eq!(m.size, 0)
  assert_eq!(m.capacity, 8)
  assert_eq!(m.head, None)
  assert_eq!(m.tail, None)
  for i = 0; i < m.capacity; i = i + 1 {
    assert_eq!(m.entries[i], None)
  }
}

test "iter" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.each(fn(_k, v) { sum += v })
  assert_eq!(sum, 6)
}

test "iteri" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  let mut s = ""
  m.eachi(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  assert_eq!(s, "012")
  assert_eq!(sum, 6)
}

test "to_array" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  assert_eq!(m.to_array(), [("a", 1), ("b", 2), ("c", 3)])
}

test "op_equal_1" {
  let m1 : Map[String, Int] = Map::new()
  m1.set("a", 1)
  m1.set("b", 2)
  m1.set("c", 3)
  let m2 = { "a": 1, "b": 2, "c": 3 }
  inspect!(m1 == m2, content="true")
  inspect!({ "a": 1 } == {}, content="false")
  inspect!({ 1: 2, 2: 3 } == { 1: 3, 2: 4 }, content="false")
}

test "op_equal_2" {
  let map1 = { "a": 1, "b": 2 }
  let map2 = { "b": 2, "a": 1 }
  let map3 = { "a": 1, "b": 2 }
  inspect!(map1 == map2, content="true")
  inspect!(map1 == map3, content="true")
}

test "to_string" {
  let m = {}
  inspect!(m.to_string(), content="{}")
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  inspect!(
    m.to_string(),
    content=
      #|{"a": 1, "b": 2, "c": 3}
    ,
  )
  let nested_m = { "a": { "b": 2 }, "B": { "C": 3 } }
  inspect!(
    nested_m.to_string(),
    content=
      #|{"a": {"b": 2}, "B": {"C": 3}}
    ,
  )
}

test "hash collision" {
  let m : Map[MyString, Int] = Map::new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  inspect!(m["d"], content="None")
}

test "remove" {
  let m : Map[MyString, Int] = Map::new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("bc", 2)
  m.set("cd", 2)
  m.set("abc", 3)
  m.set("abcdef", 6)
  m.remove("ab")
  assert_eq!(m.size(), 5)
  assert_eq!(
    m.debug_entries(),
    "_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_",
  )
}

test "remove_unexist_key" {
  let m : Map[MyString, Int] = Map::new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  assert_eq!(m.size(), 3)
  assert_eq!(m.debug_entries(), "_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_")
}

test "insert_entry_panic" {
  let map = Map::new(capacity=1)
  map.set(1, 1)
  // This should trigger the panic in insert_entry
  map.set(2, 2)
}

test "get_entry_none" {
  let map = Map::new(capacity=1)
  map.set(1, 1)
  // This should return None as the key 2 is not in the map
  let result = map.get(2)
  assert_eq!(result, None)
}

test "remove_entry_head" {
  let map = Map::new(capacity=2)
  map.set(1, 1)
  map.set(2, 2)
  map.remove(1)
  // This should ensure the head is updated correctly
  assert_eq!(
    map.head,
    Some({ idx: 1, psl: 0, hash: Hash::hash(2), key: 2, value: 2 }),
  )
}

test "remove_entry_tail" {
  let map = Map::new(capacity=2)
  map.set(1, 1)
  map.set(2, 2)
  map.remove(2)
  // This should ensure the tail is updated correctly
  assert_eq!(
    map.tail,
    Some(Entry::{ idx: 0, psl: 0, hash: Hash::hash(1), key: 1, value: 1 }),
  )
}

test "op_equal_size_mismatch" {
  let map1 = Map::new(capacity=1)
  let map2 = Map::new(capacity=2)
  map1.set(1, 1)
  map2.set(1, 1)
  map2.set(2, 2)
  // This should return false as the sizes are different
  assert_eq!(map1 == map2, false)
}

test "op_equal_key_value_mismatch" {
  let map1 = Map::new(capacity=2)
  let map2 = Map::new(capacity=2)
  map1.set(1, 1)
  map1.set(2, 2)
  map2.set(1, 1)
  map2.set(2, 3)
  // This should return false as the values are different
  assert_eq!(map1 == map2, false)
}

test "op_equal_size_mismatch" {
  let map1 = Map::new(capacity=1)
  let map2 = Map::new(capacity=2)
  map1.set(1, 1)
  map2.set(1, 1)
  map2.set(2, 2)
  // This should return false as the sizes are different
  assert_eq!(map1 == map2, false)
}

test "op_equal_key_value_mismatch" {
  let map1 = Map::new(capacity=2)
  let map2 = Map::new(capacity=2)
  map1.set(1, 1)
  map1.set(2, 2)
  map2.set(1, 1)
  map2.set(2, 3)
  // This should return false as the values are different
  assert_eq!(map1 == map2, false)
}

test "op_equal_size_mismatch" {
  let map1 = Map::new(capacity=1)
  let map2 = Map::new(capacity=2)
  map1.set(1, 1)
  map2.set(1, 1)
  map2.set(2, 2)
  // This should return false as the sizes are different
  assert_eq!(map1 == map2, false)
}

test "op_equal_key_value_mismatch" {
  let map1 = Map::new(capacity=2)
  let map2 = Map::new(capacity=2)
  map1.set(1, 1)
  map1.set(2, 2)
  map2.set(1, 1)
  map2.set(2, 3)
  // This should return false as the values are different
  assert_eq!(map1 == map2, false)
}
