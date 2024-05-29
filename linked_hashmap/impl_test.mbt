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
  let m : LinkedHashMap[Int, Int] = LinkedHashMap::new()
  @assertion.assert_eq(m.capacity, default_init_capacity)?
  @assertion.assert_eq(m.size, 0)?
}

test "set" {
  let m : LinkedHashMap[MyString, Int] = LinkedHashMap::new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.set("a" |> i, 1)
  m.set("b" |> i, 1)
  m.set("bc" |> i, 2)
  m.set("abc" |> i, 3)
  m.set("cd" |> i, 2)
  m.set("c" |> i, 1)
  m.set("d" |> i, 1)
  @assertion.assert_eq(m.size, 7)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )?
}

test "get" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
  @assertion.assert_eq(m.get_or_default("b", 42), 2)?
  @assertion.assert_eq(m.get_or_default("c", 42), 3)?
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "op_set" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m["a"] = 1
  m["b"] = 2
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
}

test "op_get" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m["a"], Some(1))?
  @assertion.assert_eq(m["b"], Some(2))?
  @assertion.assert_eq(m["c"], None)?
}

test "set_update" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m.get("a"), Some(1))?
  m.set("a", 2)
  @assertion.assert_eq(m.get("a"), Some(2))?
}

test "contains" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  @assertion.assert_eq(m.contains("a"), true)?
  @assertion.assert_eq(m.contains("b"), false)?
}

test "from_array" {
  let m = LinkedHashMap::[("a", 1), ("b", 2), ("c", 3)]
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
}

test "remove" {
  let m : LinkedHashMap[MyString, Int] = LinkedHashMap::new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.set("a" |> i, 1)
  m.set("ab" |> i, 2)
  m.set("bc" |> i, 2)
  m.set("cd" |> i, 2)
  m.set("abc" |> i, 3)
  m.set("abcdef" |> i, 6)
  m.remove("ab" |> i)
  @assertion.assert_eq(m.size(), 5)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_",
  )?
}

test "remove_unexist_key" {
  let m : LinkedHashMap[MyString, Int] = LinkedHashMap::new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.set("a" |> i, 1)
  m.set("ab" |> i, 2)
  m.set("abc" |> i, 3)
  m.remove("d" |> i)
  @assertion.assert_eq(m.size(), 3)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_",
  )?
}

test "size" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  @assertion.assert_eq(m.size(), 0)?
  m.set("a", 1)
  @assertion.assert_eq(m.size(), 1)?
}

test "is_empty" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  @assertion.assert_eq(m.is_empty(), true)?
  m.set("a", 1)
  @assertion.assert_eq(m.is_empty(), false)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
}

test "iter" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::[
    ("a", 1),
    ("b", 2),
    ("c", 3),
  ]
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::[
    ("a", 1),
    ("b", 2),
    ("c", 3),
  ]
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
  let m : LinkedHashMap[String, Int] = LinkedHashMap::[
    ("a", 1),
    ("b", 2),
    ("c", 3),
  ]
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], Empty)?
  }
}

test "grow" {
  let m : LinkedHashMap[MyString, Int] = LinkedHashMap::new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.set("C" |> i, 1)
  m.set("Go" |> i, 2)
  m.set("C++" |> i, 3)
  m.set("Java" |> i, 4)
  m.set("Scala" |> i, 5)
  m.set("Julia" |> i, 5)
  @assertion.assert_eq(m.size(), 6)?
  @assertion.assert_eq(m.capacity(), 8)?
  m.set("Cobol" |> i, 5)
  @assertion.assert_eq(m.size(), 7)?
  @assertion.assert_eq(m.capacity(), 16)?
  m.set("Python" |> i, 6)
  m.set("Haskell" |> i, 7)
  m.set("Rescript" |> i, 8)
  @assertion.assert_eq(m.size(), 10)?
  @assertion.assert_eq(m.capacity(), 16)?
  @assertion.assert_eq(
    m.debug_entries(),
    "_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_",
  )?
}

test "as_iter" {
  let buf = Buffer::make(20)
  let map = LinkedHashMap::[(1, "one"), (2, "two"), (3, "three")]
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
  let m = LinkedHashMap::[("one", 1)]
  m["three"] = 3
  m["two"] = 2
  let buf = Buffer::make(0)
  m.iter(fn(k, v) { buf.write_string("[\(k)-\(v)]") })
  inspect(buf.to_string(), content="[one-1][three-3][two-2]")?
}

test "linked list" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::[]
  inspect(m.debug_linked_list(), content="end")?
  m["one"] = 1
  m["two"] = 2
  m["three"] = 3
  m["four"] = 4
  m["five"] = 5
  inspect(
    m.debug_linked_list(),
    content=
      #|(-684895554,one,1,prev:_,next:1759431067)
      #|(1759431067,two,2,prev:-684895554,next:957279207)
      #|(957279207,three,3,prev:1759431067,next:-1028309232)
      #|(-1028309232,four,4,prev:957279207,next:-1715640224)
      #|(-1715640224,five,5,prev:-1028309232,next:_)
      #|end
    ,
  )?
  m.remove("three")
  inspect(
    m.debug_linked_list(),
    content=
      #|(-684895554,one,1,prev:_,next:1759431067)
      #|(1759431067,two,2,prev:-684895554,next:-1028309232)
      #|(-1028309232,four,4,prev:1759431067,next:-1715640224)
      #|(-1715640224,five,5,prev:-1028309232,next:_)
      #|end
    ,
  )?
  m.set("two", 20)
  inspect(
    m.debug_linked_list(),
    content=
      #|(-684895554,one,1,prev:_,next:1759431067)
      #|(1759431067,two,20,prev:-684895554,next:-1028309232)
      #|(-1028309232,four,4,prev:1759431067,next:-1715640224)
      #|(-1715640224,five,5,prev:-1028309232,next:_)
      #|end
    ,
  )?
  m.remove("one")
  inspect(
    m.debug_linked_list(),
    content=
      #|(1759431067,two,20,prev:_,next:-1028309232)
      #|(-1028309232,four,4,prev:1759431067,next:-1715640224)
      #|(-1715640224,five,5,prev:-1028309232,next:_)
      #|end
    ,
  )?
  m.remove("five")
  inspect(
    m.debug_linked_list(),
    content=
      #|(1759431067,two,20,prev:_,next:-1028309232)
      #|(-1028309232,four,4,prev:1759431067,next:_)
      #|end
    ,
  )?
  m.remove("two")
  inspect(
    m.debug_linked_list(),
    content=
      #|(-1028309232,four,4,prev:_,next:_)
      #|end
    ,
  )?
  m.remove("four")
  inspect(m.debug_linked_list(), content="end")?
}

test "to_array" {
  let map = LinkedHashMap::[(1, "one"), (2, "two"), (3, "three")]
  inspect(map.to_array(), content="[(1, one), (2, two), (3, three)]")?
}

test "set_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("a", 4)
  @assertion.assert_eq(m.size, 3)?
  @assertion.assert_eq(m.get("a"), Some(4))?
}

test "get_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
}

test "get_or_default_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "remove_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("b")
  @assertion.assert_eq(m.size(), 2)?
  @assertion.assert_eq(m.get("b"), None)?
}

test "remove_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
}

test "contains_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("b"), true)?
}

test "contains_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("d"), false)?
}

test "clear" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], Empty)?
  }
}

test "iter" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
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
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.to_array(), [("a", 1), ("b", 2), ("c", 3)])?
}

test "new" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], Empty)?
  }
}

test "get" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
  @assertion.assert_eq(m.get_or_default("b", 42), 2)?
  @assertion.assert_eq(m.get_or_default("c", 42), 3)?
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "contains" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  @assertion.assert_eq(m.contains("a"), true)?
  @assertion.assert_eq(m.contains("b"), false)?
}

test "size" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  @assertion.assert_eq(m.size, 0)?
  m.set("a", 1)
  @assertion.assert_eq(m.size, 1)?
}

test "is_empty" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  @assertion.assert_eq(m.is_empty(), true)?
  m.set("a", 1)
  @assertion.assert_eq(m.is_empty(), false)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
}

test "iter" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
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
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], Empty)?
  }
}

test "set_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("a", 4)
  @assertion.assert_eq(m.size, 3)?
  @assertion.assert_eq(m.get("a"), Some(4))?
}

test "get_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get("d"), None)?
}

test "get_or_default_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
}

test "get_or_default_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "remove_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("b")
  @assertion.assert_eq(m.size(), 2)?
  @assertion.assert_eq(m.get("b"), None)?
}

test "remove_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
}

test "contains_existing_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("b"), true)?
}

test "contains_nonexistent_key" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.contains("d"), false)?
}

test "clear" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  @assertion.assert_eq(m.head, None)?
  @assertion.assert_eq(m.tail, None)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], Empty)?
  }
}

test "iter" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
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
  let m : LinkedHashMap[String, Int] = LinkedHashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.to_array(), [("a", 1), ("b", 2), ("c", 3)])?
}
