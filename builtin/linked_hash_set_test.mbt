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

test "new" {
  let m : Set[Int] = Set::new()
  assert_eq!(m.capacity(), default_init_capacity)
  assert_eq!(m.size(), 0)
}

test "insert" {
  let m = Set::new()
  m.add("a")
  m.add("b")
  m.add("c")
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

test "add remove" {
  let m = Set::new()
  m.add("a")
  m.add("b")
  m.add("c")
  if m.remove_and_check("a") {
    m.add("d")
  }
  assert_true!(m.add_and_check("test"))
  assert_false!(m.add_and_check("test"))
  assert_true!(not(m.contains("a")) && m.contains("d"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_true!(m.contains("d"))
}

test "from_array" {
  let m = Set::of(["a", "b", "c"])
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

test "size" {
  let m = Set::new()
  assert_eq!(m.size(), 0)
  m.add("a")
  assert_eq!(m.size(), 1)
}

test "is_empty" {
  let m = Set::new()
  assert_eq!(m.is_empty(), true)
  m.add("a")
  assert_eq!(m.is_empty(), false)
  m.remove("a")
  assert_eq!(m.is_empty(), true)
}

test "iter" {
  let m = Set::of(["a", "b", "c"])
  let mut sum = ""
  m.each(fn(k) { sum += k })
  inspect!(sum, content="abc")
}

test "iteri" {
  let m = Set::of(["1", "2", "3"])
  let mut s = ""
  let mut sum = 0
  m.eachi(fn(i, k) {
    s += k
    sum += i
  })
  inspect!(s, content="123")
  inspect!(sum, content="3")
}

test "union" {
  let m1 = Set::of(["a", "b", "c"])
  let m2 = Set::of(["b", "c", "d"])
  let m = m1.union(m2)
  assert_eq!(m.size(), 4)
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_true!(m.contains("d"))
}

test "intersection" {
  let m1 = Set::of(["a", "b", "c"])
  let m2 = Set::of(["b", "c", "d"])
  let m = m1.intersection(m2)
  assert_eq!(m.size(), 2)
  assert_false!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

test "difference" {
  let m1 = Set::of(["a", "b", "c"])
  let m2 = Set::of(["b", "c", "d"])
  let m = m1.difference(m2)
  assert_eq!(m.size(), 1)
  assert_true!(m.contains("a"))
  assert_false!(m.contains("b"))
  assert_false!(m.contains("c"))
  assert_false!(m.contains("d"))
}

test "symmetric_difference" {
  let m1 = Set::of(["a", "b", "c"])
  let m2 = Set::of(["b", "c", "d"])
  let m = m1.symmetric_difference(m2)
  assert_eq!(m.size(), 2)
  assert_true!(m.contains("a"))
  assert_false!(m.contains("b"))
  assert_false!(m.contains("c"))
  assert_true!(m.contains("d"))
}

test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let map = Set::of(["a", "b", "c"])
  map.iter().each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[a][b][c]")
  buf.reset()
  map.iter().take(2).each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[a][b]")
}

test "from_array" {
  let arr = ["a", "b", "c"]
  let m = Set::from_array(arr)
  assert_true!(m.contains("a"))
  assert_true!(m.contains("b"))
  assert_true!(m.contains("c"))
  assert_false!(m.contains("d"))
}

test "insert_and_grow" {
  let m = Set::new()
  for i = 0; i < 10; i = i + 1 {
    m.add(i.to_string())
  }
  assert_eq!(m.size(), 10)
  assert_eq!(m.capacity(), 16)
  @json.inspect!(m, content=["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
}

test "array unique via Set" {
  let v = [1, 2, 3, 4, 5, 3, 2, 4, 5]
  let h = Set::from_iter(v.iter())
  let v = [..h]
  // @json.inspect!([..h])
  @json.inspect!(v, content=[1, 2, 3, 4, 5])
}

test "remove_and_shift_back" {
  let m = Set::new()
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

test "capacity_and_size" {
  let m = Set::new()
  assert_eq!(m.capacity(), default_init_capacity)
  assert_eq!(m.size(), 0)
  m.add("a")
  assert_eq!(m.size(), 1)
}

test "clear_and_reinsert" {
  let m = Set::new()
  m.add("a")
  m.add("b")
  m.clear()
  assert_eq!(m.size(), 0)
  m.add("c")
  assert_eq!(m.size(), 1)
  assert_true!(m.contains("c"))
}

test "insert_and_grow" {
  let m = Set::new()
  for i = 0; i < 10; i = i + 1 {
    m.add(i.to_string())
  }
  assert_eq!(m.size(), 10)
  assert_eq!(m.capacity(), 16)
}

test "remove_and_shift_back" {
  let m = Set::new()
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

test "capacity_and_size" {
  let m = Set::new()
  assert_eq!(m.capacity(), default_init_capacity)
  assert_eq!(m.size(), 0)
  m.add("a")
  assert_eq!(m.size(), 1)
}

test "clear_and_reinsert" {
  let m = Set::new()
  m.add("a")
  m.add("b")
  m.clear()
  assert_eq!(m.size(), 0)
  m.add("c")
  assert_eq!(m.size(), 1)
  assert_true!(m.contains("c"))
}

test "from_iter multiple elements iter" {
  inspect!(Set::from_iter([1, 2, 3].iter()), content="{1, 2, 3}")
}

test "from_iter single element iter" {
  inspect!(Set::from_iter([1].iter()), content="{1}")
}

test "from_iter empty iter" {
  let map : Set[Int] = Set::from_iter(Iter::empty())
  inspect!(map, content="{}")
}

test "remove item causes break when psl < i" {
  let set = Set::new()
    ..add(1)
    ..add(11) // This goes to a different bucket due to hash collision
    ..remove(21) // Key doesn't exist, will cause psl < i and break
  assert_eq!(set.size(), 2)
}

test "to_array_empty" {
  inspect!((Set::new() : Set[Int]).to_array(), content="[]")
}

test "to_array_non_empty" {
  let set = Set::new()..add(1)..add(2)..add(3)
  inspect!(set.to_array(), content="[1, 2, 3]")
}

test "op_equal: different size" {
  let set1 = Set::new()..add(1)
  let set2 = Set::new()
  inspect!(set1 == set2, content="false")
}

test "op_equal: different keys" {
  let set1 = Set::new()..add(1)
  let set2 = Set::new()..add(2)
  inspect!(set1 == set2, content="false")
}

test "op_equal: same sets" {
  let set1 = Set::new()..add(1)
  let set2 = Set::new()..add(1)
  inspect!(set1 == set2, content="true")
}

test "remove_and_check when key not found in empty slot" {
  // Try to remove from empty set
  inspect!(Set::new().remove_and_check(1), content="false")
}

test "trigger grow" {
  let set = Set::new(capacity=2)
  for i in 0..<10 {
    assert_true!(set.add_and_check(i))
  }
  inspect!(set, content="{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}")
}
