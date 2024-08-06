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

test "lookup" {
  let m = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  @test.eq!(m.lookup(8), Some("eight"))
  @test.eq!(m.lookup(2), Some("two"))
  @test.eq!(m.lookup(4), None)
}

test "size" {
  let m = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  @test.eq!(m.size(), 5)
  let m = m.remove(1).remove(3)
  @test.eq!(m.size(), 3)
}

test "is_empty" {
  let m : @sorted_map.T[Int, Int] = @sorted_map.empty()
  @test.eq!(m.is_empty(), true)
  let m = m.insert(1, 1)
  @test.eq!(m.is_empty(), false)
}

test "iter" {
  let m = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let mut s = ""
  m.each(fn(k, v) { s = s + "(\{k},\{v})" })
  @test.eq!(s, "(0,zero)(1,one)(2,two)(3,three)(8,eight)")
}

test "iteri" {
  let m = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let mut s = ""
  m.eachi(fn(i, k, v) { s = s + "(\{i},\{k},\{v})" })
  @test.eq!(s, "(0,0,zero)(1,1,one)(2,2,two)(3,3,three)(4,8,eight)")
}

test "fold" {
  let m = @sorted_map.of([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
  @test.eq!(m.fold(fn(acc, v) { acc + v }, init=0), 15)
}

test "foldl_with_key" {
  let m = @sorted_map.of([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
  @test.eq!(
    m.foldl_with_key(fn(acc, k, v) { acc + k + v.to_string() }, init=""),
    "a1b2c3d4e5",
  )
}

test "foldr_with_key" {
  let m = @sorted_map.of([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
  @test.eq!(
    m.foldr_with_key(fn(acc, k, v) { acc + k + v.to_string() }, init=""),
    "e5d4c3b2a1",
  )
}

test "to_array" {
  let m = @sorted_map.of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq!(m.iter().collect(), [(1, "one"), (2, "two"), (3, "three")])
}

test "keys" {
  let m = @sorted_map.of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq!(m.keys(), [1, 2, 3])
}

test "elems" {
  let m = @sorted_map.of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq!(m.elems(), ["one", "two", "three"])
}

test "op_equal" {
  let m1 = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let m2 = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let m3 = @sorted_map.of([(3, "three"), (8, "eight"), (1, "one"), (2, "two")])
  @test.eq!(m1 == m2, true)
  @test.eq!(m1 == m3, false)
}

test "iter" {
  let buf = Buffer::new(size_hint=20)
  let map = @sorted_map.of([(1, "one"), (2, "two"), (3, "three")])
  map.iter().each(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\{k}-\{v}]")
    },
  )
  inspect!(buf, content="[1-one][2-two][3-three]")
  buf.reset()
  map.iter().take(2).each(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\{k}-\{v}]")
    },
  )
  inspect!(buf, content="[1-one][2-two]")
}

test "to_array" {
  let m = @sorted_map.of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq!(m.to_array(), [(1, "one"), (2, "two"), (3, "three")])
}

test "op_equal" {
  let m1 = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let m2 = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let m3 = @sorted_map.of([(3, "three"), (8, "eight"), (1, "one"), (2, "two")])
  @test.eq!(m1 == m2, true)
  @test.eq!(m1 == m3, false)
}

test "show" {
  let m = @sorted_map.of([(1, "one"), (2, "two"), (3, "three")])
  inspect!(
    m,
    content="@immut/sorted_map.of([(1, \"one\"), (2, \"two\"), (3, \"three\")])",
  )
}

test "from_iter multiple elements iter" {
  inspect!(
    @sorted_map.T::from_iter([(1, 1), (2, 2), (3, 3)].iter()),
    content="@immut/sorted_map.of([(1, 1), (2, 2), (3, 3)])",
  )
}

test "from_iter single element iter" {
  inspect!(
    @sorted_map.T::from_iter([(1, 1)].iter()),
    content="@immut/sorted_map.of([(1, 1)])",
  )
}

test "from_iter empty iter" {
  let pq : @sorted_map.T[Int, Int] = @sorted_map.T::from_iter(Iter::empty())
  inspect!(pq, content="@immut/sorted_map.of([])")
}
