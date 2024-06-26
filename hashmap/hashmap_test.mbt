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

test "new" {
  let m : HashMap[Int, Int] = HashMap::new()
  inspect(m.capacity, content="8")?
  @assertion.assert_eq(m.size, 0)?
}

type MyString String derive(Eq)

impl Hash for MyString with hash(self) { self.0.length() }

impl Show for MyString with to_string(self) { self.0 }

test "set" {
  let m : HashMap[MyString, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 1)
  m.set("bc", 2)
  m.set("abc", 3)
  m.set("cd", 2)
  m.set("c", 1)
  m.set("d", 1)
  @assertion.assert_eq(m.size, 7)?
  inspect(
    m.debug_entries(),
    content="_,(0,a,1),(1,b,1),(2,c,1),(3,d,1),(3,bc,2),(4,cd,2),(4,abc,3),_,_,_,_,_,_,_,_",
  )?
}

test "get" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  inspect(m.get("a"), content="Some(1)")?
  inspect(m.get("b"), content="Some(2)")?
  inspect(m.get("c"), content="Some(3)")?
  inspect(m.get("d"), content="None")?
}

test "get_or_default" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  @assertion.assert_eq(m.get_or_default("a", 42), 1)?
  @assertion.assert_eq(m.get_or_default("b", 42), 2)?
  @assertion.assert_eq(m.get_or_default("c", 42), 3)?
  @assertion.assert_eq(m.get_or_default("d", 42), 42)?
}

test "op_set" {
  let m : HashMap[String, Int] = HashMap::new()
  m["a"] = 1
  m["b"] = 2
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
}

test "op_get" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m["a"], Some(1))?
  @assertion.assert_eq(m["b"], Some(2))?
  @assertion.assert_eq(m["c"], None)?
}

test "set_update" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  @assertion.assert_eq(m.get("a"), Some(1))?
  m.set("a", 2)
  @assertion.assert_eq(m.get("a"), Some(2))?
}

test "contains" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  @assertion.assert_eq(m.contains("a"), true)?
  @assertion.assert_eq(m.contains("b"), false)?
}

test "from_array" {
  let m = of([("a", 1), ("b", 2), ("c", 3)])
  @assertion.assert_eq(m.get("a"), Some(1))?
  @assertion.assert_eq(m.get("b"), Some(2))?
  @assertion.assert_eq(m.get("c"), Some(3))?
}

test "remove" {
  let m : HashMap[MyString, Int] = HashMap::new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("bc", 2)
  m.set("cd", 2)
  m.set("abc", 3)
  m.set("abcdef", 6)
  m.remove("ab")
  @assertion.assert_eq(m.size(), 5)?
  inspect(
    m.debug_entries(),
    content="_,(0,a,1),(0,bc,2),(1,cd,2),(1,abc,3),_,(0,abcdef,6),_,_,_,_,_,_,_,_,_",
  )?
}

test "remove_unexist_key" {
  let m : HashMap[MyString, Int] = HashMap::new()
  m.set("a", 1)
  m.set("ab", 2)
  m.set("abc", 3)
  m.remove("d")
  @assertion.assert_eq(m.size(), 3)?
  inspect(m.debug_entries(), content="_,(0,a,1),(0,ab,2),(0,abc,3),_,_,_,_")?
}

test "size" {
  let m : HashMap[String, Int] = HashMap::new()
  @assertion.assert_eq(m.size(), 0)?
  m.set("a", 1)
  @assertion.assert_eq(m.size(), 1)?
}

test "is_empty" {
  let m : HashMap[String, Int] = HashMap::new()
  @assertion.assert_eq(m.is_empty(), true)?
  m.set("a", 1)
  @assertion.assert_eq(m.is_empty(), false)?
  m.remove("a")
  @assertion.assert_eq(m.is_empty(), true)?
}

test "iter" {
  let m : HashMap[String, Int] = of([("a", 1), ("b", 2), ("c", 3)])
  let mut sum = 0
  m.iter(fn(_k, v) { sum += v })
  @assertion.assert_eq(sum, 6)?
}

test "iteri" {
  let m : HashMap[String, Int] = of([("a", 1), ("b", 2), ("c", 3)])
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
  let m : HashMap[String, Int] = of([("a", 1), ("b", 2), ("c", 3)])
  m.clear()
  @assertion.assert_eq(m.size, 0)?
  @assertion.assert_eq(m.capacity, 8)?
  for i = 0; i < m.capacity; i = i + 1 {
    @assertion.assert_is(m.entries[i], None)?
  }
}

test "grow" {
  let m : HashMap[MyString, Int] = HashMap::new()
  m.set("C", 1)
  m.set("Go", 2)
  m.set("C++", 3)
  m.set("Java", 4)
  m.set("Scala", 5)
  m.set("Julia", 5)
  @assertion.assert_eq(m.size, 6)?
  inspect(m.capacity, content="16")?
  m.set("Cobol", 5)
  @assertion.assert_eq(m.size, 7)?
  inspect(m.capacity, content="16")?
  m.set("Python", 6)
  m.set("Haskell", 7)
  m.set("Rescript", 8)
  @assertion.assert_eq(m.size, 10)?
  inspect(m.capacity, content="32")?
  inspect(
    m.debug_entries(),
    content="_,(0,C,1),(0,Go,2),(0,C++,3),(0,Java,4),(0,Scala,5),(1,Julia,5),(2,Cobol,5),(2,Python,6),(2,Haskell,7),(2,Rescript,8),_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_",
  )?
}

test "as_iter" {
  let buf = Buffer::new(size_hint=20)
  let map = of([(1, "one"), (2, "two"), (3, "three")])
  map.as_iter().iter(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\(k)-\(v)]")
    },
  )
  inspect(buf, content="[2-two][1-one][3-three]")?
  buf.reset()
  map.as_iter().take(2).iter(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\(k)-\(v)]")
    },
  )
  inspect(buf, content="[2-two][1-one]")?
}

test "to_array" {
  let map = of([(1, "one"), (2, "two"), (3, "three")])
  inspect(map.to_array(), content="[(2, two), (1, one), (3, three)]")?
}

test "get_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")?
}

test "remove_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  @assertion.assert_eq(m.size, 2)?
}

test "get_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")?
}

test "remove_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  @assertion.assert_eq(m.size, 2)?
}

test "get_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")?
}

test "remove_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  @assertion.assert_eq(m.size, 2)?
}

test "get_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  inspect(m.get("c"), content="None")?
}

test "remove_nonexistent_key" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.remove("c")
  @assertion.assert_eq(m.size, 2)?
}

test "get_nonexistent_key_with_psl" {
  let m : HashMap[String, Int] = HashMap::new()
  m.set("a", 1)
  m.set("b", 2)
  m.set("c", 3)
  m.set("d", 4)
  m.set("e", 5)
  m.set("f", 6)
  m.set("g", 7)
  m.set("h", 8)
  m.set("i", 9)
  m.set("j", 10)
  m.set("k", 11)
  m.set("l", 12)
  m.set("m", 13)
  m.set("n", 14)
  m.set("o", 15)
  m.set("p", 16)
  m.set("q", 17)
  m.set("r", 18)
  m.set("s", 19)
  m.set("t", 20)
  m.set("u", 21)
  m.set("v", 22)
  m.set("w", 23)
  m.set("x", 24)
  m.set("y", 25)
  m.set("z", 26)
  inspect(m.get("A"), content="None")?
  inspect(m.get("B"), content="None")?
  inspect(m.get("C"), content="None")?
  inspect(m.get("D"), content="None")?
  inspect(m.get("E"), content="None")?
  inspect(m.get("F"), content="None")?
  inspect(m.get("G"), content="None")?
  inspect(m.get("H"), content="None")?
  inspect(m.get("I"), content="None")?
  inspect(m.get("J"), content="None")?
  inspect(m.get("K"), content="None")?
  inspect(m.get("L"), content="None")?
  inspect(m.get("M"), content="None")?
  inspect(m.get("N"), content="None")?
  inspect(m.get("O"), content="None")?
  inspect(m.get("P"), content="None")?
  inspect(m.get("Q"), content="None")?
  inspect(m.get("R"), content="None")?
  inspect(m.get("S"), content="None")?
  inspect(m.get("T"), content="None")?
  inspect(m.get("U"), content="None")?
  inspect(m.get("V"), content="None")?
  inspect(m.get("W"), content="None")?
  inspect(m.get("X"), content="None")?
  inspect(m.get("Y"), content="None")?
  inspect(m.get("Z"), content="None")?
}
