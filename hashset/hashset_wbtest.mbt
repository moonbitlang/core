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
  let m : HashSet[Int] = HashSet::new()
  @test.eq(m.capacity, default_init_capacity)!
  @test.eq(m.size, 0)!
}

type MyString String derive(Eq)

impl Hash for MyString with hash(self) { self.0.length() }

impl Hash for MyString with hash_combine(self, hasher) {
  hasher.combine_string(self.0)
}

impl Show for MyString with to_string(self) { self.0 }

test "set" {
  let m : HashSet[MyString] = HashSet::new()
  m.insert("a")
  m.insert("b")
  m.insert("bc")
  m.insert("abc")
  m.insert("cd")
  m.insert("c")
  m.insert("d")
  @test.eq(m.size, 7)!
  @test.eq(
    m.debug_entries(),
    "_,(0,a),(1,b),(2,c),(3,d),(3,bc),(4,cd),(4,abc),_,_,_,_,_,_,_,_",
  )!
}

test "insert" {
  let m : HashSet[String] = HashSet::new()
  m.insert("a")
  m.insert("b")
  m.insert("c")
  @test.is_true(m.contains("a"))!
  @test.is_true(m.contains("b"))!
  @test.is_true(m.contains("c"))!
  @test.is_false(m.contains("d"))!
}

test "from_array" {
  let m = of(["a", "b", "c"])
  @test.is_true(m.contains("a"))!
  @test.is_true(m.contains("b"))!
  @test.is_true(m.contains("c"))!
  @test.is_false(m.contains("d"))!
}

test "remove" {
  let m : HashSet[MyString] = HashSet::new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.insert("a" |> i)
  m.insert("ab" |> i)
  m.insert("bc" |> i)
  m.insert("cd" |> i)
  m.insert("abc" |> i)
  m.insert("abcdef" |> i)
  m.remove("ab" |> i)
  @test.eq(m.size(), 5)!
  @test.eq(m.debug_entries(), "_,(0,a),(0,bc),(1,cd),(1,abc),_,(0,abcdef),_")!
}

test "remove_unexist_key" {
  let m : HashSet[MyString] = HashSet::new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.insert("a" |> i)
  m.insert("ab" |> i)
  m.insert("abc" |> i)
  m.remove("d" |> i)
  @test.eq(m.size(), 3)!
  @test.eq(m.debug_entries(), "_,(0,a),(0,ab),(0,abc),_,_,_,_")!
}

test "size" {
  let m : HashSet[String] = HashSet::new()
  @test.eq(m.size(), 0)!
  m.insert("a")
  @test.eq(m.size(), 1)!
}

test "is_empty" {
  let m : HashSet[String] = HashSet::new()
  @test.eq(m.is_empty(), true)!
  m.insert("a")
  @test.eq(m.is_empty(), false)!
  m.remove("a")
  @test.eq(m.is_empty(), true)!
}

test "iter" {
  let m : HashSet[String] = HashSet::of(["a", "b", "c"])
  let mut sum = ""
  m.each(fn(k) { sum += k })
  inspect!(sum, content="cab")
}

test "iteri" {
  let m = of(["1", "2", "3"])
  let mut s = ""
  let mut sum = 0
  m.eachi(
    fn(i, k) {
      s += k
      sum += i
    },
  )
  inspect!(s, content="231")
  inspect!(sum, content="3")
}

test "clear" {
  let m = of(["a", "b", "c"])
  m.clear()
  @test.eq(m.size, 0)!
  @test.eq(m.capacity, 8)!
  for i = 0; i < m.capacity; i = i + 1 {
    @test.is(m.entries[i], None)!
  }
}

test "grow" {
  let m : HashSet[MyString] = HashSet::new()
  fn i(s) {
    MyString::MyString(s)
  }

  m.insert("C" |> i)
  m.insert("Go" |> i)
  m.insert("C++" |> i)
  m.insert("Java" |> i)
  m.insert("Scala" |> i)
  m.insert("Julia" |> i)
  @test.eq(m.size, 6)!
  @test.eq(m.capacity, 8)!
  m.insert("Cobol" |> i)
  @test.eq(m.size, 7)!
  @test.eq(m.capacity, 16)!
  m.insert("Python" |> i)
  m.insert("Haskell" |> i)
  m.insert("Rescript" |> i)
  @test.eq(m.size, 10)!
  @test.eq(m.capacity, 16)!
  @test.eq(
    m.debug_entries(),
    "_,(0,C),(0,Go),(0,C++),(0,Java),(0,Scala),(1,Julia),(2,Cobol),(2,Python),(2,Haskell),(2,Rescript),_,_,_,_,_",
  )!
}

test "union" {
  let m1 : HashSet[String] = of(["a", "b", "c"])
  let m2 : HashSet[String] = of(["b", "c", "d"])
  let m = m1.union(m2)
  @test.eq(m.size, 4)!
  @test.is_true(m.contains("a"))!
  @test.is_true(m.contains("b"))!
  @test.is_true(m.contains("c"))!
  @test.is_true(m.contains("d"))!
}

test "intersection" {
  let m1 : HashSet[String] = of(["a", "b", "c"])
  let m2 : HashSet[String] = of(["b", "c", "d"])
  let m = m1.intersection(m2)
  @test.eq(m.size, 2)!
  @test.is_false(m.contains("a"))!
  @test.is_true(m.contains("b"))!
  @test.is_true(m.contains("c"))!
  @test.is_false(m.contains("d"))!
}

test "difference" {
  let m1 : HashSet[String] = of(["a", "b", "c"])
  let m2 : HashSet[String] = of(["b", "c", "d"])
  let m = m1.difference(m2)
  @test.eq(m.size, 1)!
  @test.is_true(m.contains("a"))!
  @test.is_false(m.contains("b"))!
  @test.is_false(m.contains("c"))!
  @test.is_false(m.contains("d"))!
}

test "symmetric_difference" {
  let m1 : HashSet[String] = of(["a", "b", "c"])
  let m2 : HashSet[String] = of(["b", "c", "d"])
  let m = m1.symmetric_difference(m2)
  @test.eq(m.size, 2)!
  @test.is_true(m.contains("a"))!
  @test.is_false(m.contains("b"))!
  @test.is_false(m.contains("c"))!
  @test.is_true(m.contains("d"))!
}

test "iter" {
  let buf = Buffer::new(size_hint=20)
  let map = of(["a", "b", "c"])
  map.iter().each(fn(e) { buf.write_string("[\(e)]") })
  inspect!(buf, content="[c][a][b]")
  buf.reset()
  map.iter().take(2).each(fn(e) { buf.write_string("[\(e)]") })
  inspect!(buf, content="[c][a]")
}

test "from_array" {
  let arr = ["a", "b", "c"]
  let m = HashSet::from_array(arr)
  @test.is_true(m.contains("a"))!
  @test.is_true(m.contains("b"))!
  @test.is_true(m.contains("c"))!
  @test.is_false(m.contains("d"))!
}

test "insert_and_grow" {
  let m : HashSet[String] = HashSet::new()
  for i = 0; i < 10; i = i + 1 {
    m.insert(i.to_string())
  }
  @test.eq(m.size, 10)!
  @test.eq(m.capacity, 16)!
}

test "remove_and_shift_back" {
  let m : HashSet[String] = HashSet::new()
  m.insert("a")
  m.insert("b")
  m.insert("c")
  m.insert("d")
  m.remove("b")
  @test.is_false(m.contains("b"))!
  @test.is_true(m.contains("a"))!
  @test.is_true(m.contains("c"))!
  @test.is_true(m.contains("d"))!
}

test "capacity_and_size" {
  let m : HashSet[String] = HashSet::new()
  @test.eq(m.capacity, default_init_capacity)!
  @test.eq(m.size, 0)!
  m.insert("a")
  @test.eq(m.size, 1)!
}

test "clear_and_reinsert" {
  let m : HashSet[String] = HashSet::new()
  m.insert("a")
  m.insert("b")
  m.clear()
  @test.eq(m.size, 0)!
  m.insert("c")
  @test.eq(m.size, 1)!
  @test.is_true(m.contains("c"))!
}

test "insert_and_grow" {
  let m : HashSet[String] = HashSet::new()
  for i = 0; i < 10; i = i + 1 {
    m.insert(i.to_string())
  }
  @test.eq(m.size, 10)!
  @test.eq(m.capacity, 16)!
}

test "remove_and_shift_back" {
  let m : HashSet[String] = HashSet::new()
  m.insert("a")
  m.insert("b")
  m.insert("c")
  m.insert("d")
  m.remove("b")
  @test.is_false(m.contains("b"))!
  @test.is_true(m.contains("a"))!
  @test.is_true(m.contains("c"))!
  @test.is_true(m.contains("d"))!
}

test "capacity_and_size" {
  let m : HashSet[String] = HashSet::new()
  @test.eq(m.capacity, default_init_capacity)!
  @test.eq(m.size, 0)!
  m.insert("a")
  @test.eq(m.size, 1)!
}

test "clear_and_reinsert" {
  let m : HashSet[String] = HashSet::new()
  m.insert("a")
  m.insert("b")
  m.clear()
  @test.eq(m.size, 0)!
  m.insert("c")
  @test.eq(m.size, 1)!
  @test.is_true(m.contains("c"))!
}
