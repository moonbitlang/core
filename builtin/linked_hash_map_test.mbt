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

type MyString String derive(Eq)

impl Hash for MyString with hash(self) { self.0.length() }

impl Show for MyString with to_string(self) { self.0 }

test "new" {
  let m : Map[Int, Int] = Map::new()
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.size, 0)?
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
  @assertion.assert_eq(m.size, 7)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )?
}

test "get" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
  @assertion.assert_eq(m.get_or_default("b", 42), 2)?
  @assertion.assert_eq(m.get_or_default("c", 42), 3)?
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "op_set" {
  let m : Map[String, Int] = Map::new()
  m["a"] = 1
  m["b"] = 2
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
}

test "op_get" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m["a"], Some(1))?
  @assertion.assert_eq(m["b"], Some(2))?
  @assertion.assert_eq(m["c"], None)?
}

test "set_update" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m.get("a"), Some(1))?
  m.set("a", 2)
  @assertion.assert_eq(m.get("a"), Some(2))?
}

test "contains" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  @assertion.assert_eq(m.contains("a"), true)?
  @assertion.assert_eq(m.contains("b"), false)?
}

test "from_array" {
  let m = { "a": 1, "b": 2, "c": 3 }
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
}

test "size" {
  let m : Map[String, Int] = Map::new()
  @assertion.assert_eq(m.size(), 0)?
  m.set("a", 1)
  @assertion.assert_eq(m.size(), 1)?
}

test "is_empty" {
  let m : Map[String, Int] = Map::new()
  @assertion.assert_eq(m.is_empty(), true)?
  m.set("a", 1)
  @assertion.assert_eq(m.is_empty(), false)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
}

test "iter" {
  let m = { "a": 1, "b": 2, "c": 3 }
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m = { "a": 1, "b": 2, "c": 3 }
  let mut sum = 0
  let mut s = ""
  m.iteri(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  @assertion.assert_eq(s, "012")?
  @assertion.assert_eq(sum, 6)?
}

test "clear" {
  let m = { "a": 1, "b": 2, "c": 3 }
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], None)?
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
  @assertion.assert_eq(m.size(), 6)?
  @assertion.assert_eq(m.capacity(), 8)?
  m.set("Cobol", 5)
  @assertion.assert_eq(m.size(), 7)?
  @assertion.assert_eq(m.capacity(), 16)?
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  @assertion.assert_eq(m.size(), 10)?
  @assertion.assert_eq(m.capacity(), 16)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_",
  )?
}

test "as_iter" {
  let buf = Buffer::new(size_hint=20)
  let map = { 1: "one", 2: "two", 3: "three" }
  map.as_iter().iter(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\(k)-\(v)]")
    },
  )
  inspect(buf, content="[1-one][2-two][3-three]")?
  buf.reset()
  map.as_iter().take(2).iter(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\(k)-\(v)]")
    },
  )
  inspect(buf, content="[1-one][2-two]")?
}

test "iter order" {
  let m = { "one": 1 }
  m["three"] = 3
  m["two"] = 2
  let buf = Buffer::new(size_hint=0)
  m.iter(fn(k, v) { buf.write_string("[\(k)-\(v)]") })
  inspect(buf.to_string(), content="[one-1][three-3][two-2]")?
}

test "linked list" {
  let m = {  }
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(buf, content="end")?
  m["one"] = 1
  m["two"] = 2
  m["three"] = 3
  m["four"] = 4
  m["five"] = 5
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(
    buf,
    content=
      #|(-684882541,"one",1),prev:_,next:1759420741)
      #|(1759420741,"two",2),prev:-684882541,next:957272809)
      #|(957272809,"three",3),prev:1759420741,next:-1028260443)
      #|(-1028260443,"four",4),prev:957272809,next:-1715605027)
      #|(-1715605027,"five",5),prev:-1028260443,next:_)
      #|end
    ,
  )?
  m.remove("three")
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(
    buf,
    content=
      #|(-684882541,"one",1),prev:_,next:1759420741)
      #|(1759420741,"two",2),prev:-684882541,next:-1028260443)
      #|(-1028260443,"four",4),prev:1759420741,next:-1715605027)
      #|(-1715605027,"five",5),prev:-1028260443,next:_)
      #|end
    ,
  )?
  m.set("two", 20)
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(
    buf,
    content=
      #|(-684882541,"one",1),prev:_,next:1759420741)
      #|(1759420741,"two",20),prev:-684882541,next:-1028260443)
      #|(-1028260443,"four",4),prev:1759420741,next:-1715605027)
      #|(-1715605027,"five",5),prev:-1028260443,next:_)
      #|end
    ,
  )?
  m.remove("one")
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(
    buf,
    content=
      #|(1759420741,"two",20),prev:_,next:-1028260443)
      #|(-1028260443,"four",4),prev:1759420741,next:-1715605027)
      #|(-1715605027,"five",5),prev:-1028260443,next:_)
      #|end
    ,
  )?
  m.remove("five")
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(
    buf,
    content=
      #|(1759420741,"two",20),prev:_,next:-1028260443)
      #|(-1028260443,"four",4),prev:1759420741,next:_)
      #|end
    ,
  )?
  m.remove("two")
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(
    buf,
    content=
      #|(-1028260443,"four",4),prev:_,next:_)
      #|end
    ,
  )?
  m.remove("four")
  let buf = Buffer::new(size_hint=0)
  m.debug_write(buf)
  inspect(buf, content="end")?
}

test "to_array" {
  let map = { 1: "one", 2: "two", 3: "three" }
  inspect(map.to_array(), content="[(1, one), (2, two), (3, three)]")?
}

test "set_existing_key" {
  let m = {  }
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("a", 4)
  @assertion.assert_eq(m.size, 3)?
  @assertion.assert_eq(m.get("a"), Some(4))?
}

test "get_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
}

test "get_or_default_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "remove_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("b")
  @assertion.assert_eq(m.size(), 2)?
  @assertion.assert_eq(m.get("b"), None)?
}

test "remove_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
}

test "contains_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("b"), true)?
}

test "contains_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("d"), false)?
}

test "clear" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], None)?
  }
}

test "iter" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  let mut s = ""
  m.iteri(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  @assertion.assert_eq(s, "012")?
  @assertion.assert_eq(sum, 6)?
}

test "to_array" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.to_array(), [("a", 1), ("b", 2), ("c", 3)])?
}

test "new" {
  let m : Map[String, Int] = Map::new()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], None)?
  }
}

test "get" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
  @assertion.assert_eq(m.get_or_default("b", 42), 2)?
  @assertion.assert_eq(m.get_or_default("c", 42), 3)?
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "contains" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  @assertion.assert_eq(m.contains("a"), true)?
  @assertion.assert_eq(m.contains("b"), false)?
}

test "size" {
  let m : Map[String, Int] = Map::new()
  @assertion.assert_eq(m.size, 0)?
  m.set("a", 1)
  @assertion.assert_eq(m.size, 1)?
}

test "is_empty" {
  let m : Map[String, Int] = Map::new()
  @assertion.assert_eq(m.is_empty(), true)?
  m.set("a", 1)
  @assertion.assert_eq(m.is_empty(), false)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
}

test "iter" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  let mut s = ""
  m.iteri(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  @assertion.assert_eq(s, "012")?
  @assertion.assert_eq(sum, 6)?
}

test "clear" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], None)?
  }
}

test "set_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("a", 4)
  @assertion.assert_eq(m.size, 3)?
  @assertion.assert_eq(m.get("a"), Some(4))?
}

test "get_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
}

test "get_or_default_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "remove_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("b")
  @assertion.assert_eq(m.size(), 2)?
  @assertion.assert_eq(m.get("b"), None)?
}

test "remove_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
}

test "contains_existing_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("b"), true)?
}

test "contains_nonexistent_key" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("d"), false)?
}

test "clear" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], None)?
  }
}

test "iter" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  let mut s = ""
  m.iteri(
    fn(i, _k, v) {
      s += i.to_string()
      sum += v
    },
  )
  @assertion.assert_eq(s, "012")?
  @assertion.assert_eq(sum, 6)?
}

test "to_array" {
  let m : Map[String, Int] = Map::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.to_array(), [("a", 1), ("b", 2), ("c", 3)])?
}

test "op_equal" {
  let m1 : Map[String, Int] = Map::new()
  m1.set("a", 1)
  m1.set("b", 2)
  m1.set("c", 3)
  let m2 = { "a": 1, "b": 2, "c": 3 }
  inspect(m1 == m2, content="true")?
  inspect({ "a": 1 } == {  }, content="false")?
  inspect({ 1: 2, 2: 3 } == { 1: 3, 2: 4 }, content="false")?
}

test "to_string" {
  let m = {  }
  inspect(m.to_string(), content="{}")?
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  inspect(m.to_string(), content="{a:1, b:2, c:3}")?
}

test "hash collision" {
  let m : Map[MyString, Int] = Map::new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  inspect(m["d"], content="None")?
}

test "panic unwrap" {
  (None : Unit?).unwrap()
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
  @assertion.assert_eq(m.size(), 5)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_",
  )?
}

test "remove_unexist_key" {
  let m : Map[MyString, Int] = Map::new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_",
  )?
}
