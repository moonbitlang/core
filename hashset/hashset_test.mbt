// Copyright 2025 International Digital Economy Academy
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
let default_init_capacity = 8

///|
test "doc" {
  let set = @hashset.of([3, 8, 1])
  set.add(3)
  set.add(4)
  inspect!(set, content="@hashset.of([3, 4, 1, 8])")
}

///|
test "new" {
  let m : @hashset.T[Int] = @hashset.new()
  assert_eq!(m.capacity(), default_init_capacity)
  assert_eq!(m.size(), 0)
}

///|
test "insert" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.add("c")
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

///|
test "from_array" {
  let m = @hashset.of(["a", "b", "c"])
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

///|
test "size" {
  let m = @hashset.new()
  assert_eq!(m.size(), 0)
  m.add("a")
  assert_eq!(m.size(), 1)
}

///|
test "is_empty" {
  let m = @hashset.new()
  assert_eq!(m.is_empty(), true)
  m.add("a")
  assert_eq!(m.is_empty(), false)
  m.remove("a")
  assert_eq!(m.is_empty(), true)
}

///|
test "iter" {
  let m = @hashset.of(["a", "b", "c"])
  let mut sum = ""
  m.each(fn(k) { sum += k })
  inspect!(sum, content="cab")
}

///|
test "iteri" {
  let m = @hashset.of(["1", "2", "3"])
  let mut s = ""
  let mut sum = 0
  m.eachi(fn(i, k) {
    s += k
    sum += i
  })
  inspect!(s, content="231")
  inspect!(sum, content="3")
}

///|
test "union" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.union(m2)
  assert_eq!(m.size(), 4)
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_true!(m.contains("d"))
}

///|
test "intersection" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.intersection(m2)
  assert_eq!(m.size(), 2)
  assert_false!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

///|
test "difference" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.difference(m2)
  assert_eq!(m.size(), 1)
  assert_true!(m.contains("a"))
  assert_false!(m.contains("b"))
  assert_false!(m.contains("c"))
  assert_false!(m.contains("d"))
}

///|
test "symmetric_difference" {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  let m = m1.symmetric_difference(m2)
  assert_eq!(m.size(), 2)
  assert_true!(m.contains("a"))
  assert_false!(m.contains("b"))
  assert_false!(m.contains("c"))
  assert_true!(m.contains("d"))
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let map = @hashset.of(["a", "b", "c"])
  map.iter().each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[c][a][b]")
  buf.reset()
  map.iter().take(2).each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[c][a]")
}

///|
test "from_array" {
  let arr = ["a", "b", "c"]
  let m = @hashset.from_array(arr)
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

///|
test "insert_and_grow" {
  let m = @hashset.new()
  for i = 0; i < 10; i = i + 1 {
    m.add(i.to_string())
  }
  assert_eq!(m.size(), 10)
  assert_eq!(m.capacity(), 16)
}

///|
test "remove_and_shift_back" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.add("c")
  m.add("d")
  m.remove("b")
  assert_false!(m.contains("b"))
  assert_true!(m.contains("a"))
  assert_true!(m.contains("c"))
  assert_true!(m.contains("d"))
}

///|
test "capacity_and_size" {
  let m = @hashset.new()
  assert_eq!(m.capacity(), default_init_capacity)
  assert_eq!(m.size(), 0)
  m.add("a")
  assert_eq!(m.size(), 1)
}

///|
test "clear_and_reinsert" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.clear()
  assert_eq!(m.size(), 0)
  m.add("c")
  assert_eq!(m.size(), 1)
  assert_true!(m.contains("c"))
}

///|
test "insert_and_grow" {
  let m = @hashset.new()
  for i = 0; i < 10; i = i + 1 {
    m.add(i.to_string())
  }
  assert_eq!(m.size(), 10)
  assert_eq!(m.capacity(), 16)
}

///|
test "remove_and_shift_back" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.add("c")
  m.add("d")
  m.remove("b")
  assert_false!(m.contains("b"))
  assert_true!(m.contains("a"))
  assert_true!(m.contains("c"))
  assert_true!(m.contains("d"))
}

///|
test "capacity_and_size" {
  let m = @hashset.new()
  assert_eq!(m.capacity(), default_init_capacity)
  assert_eq!(m.size(), 0)
  m.add("a")
  assert_eq!(m.size(), 1)
}

///|
test "clear_and_reinsert" {
  let m = @hashset.new()
  m.add("a")
  m.add("b")
  m.clear()
  assert_eq!(m.size(), 0)
  m.add("c")
  assert_eq!(m.size(), 1)
  assert_true!(m.contains("c"))
}

///|
test "from_iter multiple elements iter" {
  inspect!(
    @hashset.from_iter([1, 2, 3].iter()),
    content="@hashset.of([3, 1, 2])",
  )
}

///|
test "from_iter single element iter" {
  inspect!(@hashset.from_iter([1].iter()), content="@hashset.of([1])")
}

///|
test "from_iter empty iter" {
  let map : @hashset.T[Int] = @hashset.from_iter(Iter::empty())
  inspect!(map, content="@hashset.of([])")
}

///|
test "hashset arbitrary" {
  let samples : Array[@hashset.T[Int]] = @quickcheck.samples(20)
  inspect!(
    samples[5:10],
    content="[@hashset.of([0]), @hashset.of([0]), @hashset.of([0]), @hashset.of([0]), @hashset.of([0, 3])]",
  )
  inspect!(
    samples[11:15],
    content="[@hashset.of([0, 1]), @hashset.of([0, 4, -1]), @hashset.of([0]), @hashset.of([2, 0, -1])]",
  )
}
