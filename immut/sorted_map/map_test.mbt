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

test "from_array" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
}

test "insert" {
  let m = of([(3, "three"), (8, "eight"), (1, "one")])
  inspect(m.debug_tree(), content="(3,three,(1,one,_,_),(8,eight,_,_))")!
  let m = m.insert(5, "five").insert(2, "two").insert(0, "zero").insert(
    1, "one_updated",
  )
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one_updated,(0,zero,_,_),(2,two,_,_)),(8,eight,(5,five,_,_),_))",
  )!
}

test "remove" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let m = m.remove(1).remove(3)
  @test.eq(m.debug_tree(), "(2,two,(0,zero,_,_),(8,eight,_,_))")!
}

test "lookup" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  @test.eq(m.lookup(8), Some("eight"))!
  @test.eq(m.lookup(2), Some("two"))!
  @test.eq(m.lookup(4), None)!
}

test "contains" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  @test.eq(m.contains(8), true)!
  @test.eq(m.contains(2), true)!
  @test.eq(m.contains(4), false)!
}

test "size" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  @test.eq(m.size(), 5)!
  let m = m.remove(1).remove(3)
  @test.eq(m.size(), 3)!
}

test "is_empty" {
  let m : Map[Int, Int] = empty()
  @test.eq(m.is_empty(), true)!
  let m = m.insert(1, 1)
  @test.eq(m.is_empty(), false)!
}

test "iter" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let mut s = ""
  m.each(fn(k, v) { s = s + "(\(k),\(v))" })
  @test.eq(s, "(0,zero)(1,one)(2,two)(3,three)(8,eight)")!
}

test "iteri" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let mut s = ""
  m.eachi(fn(i, k, v) { s = s + "(\(i),\(k),\(v))" })
  @test.eq(s, "(0,0,zero)(1,1,one)(2,2,two)(3,3,three)(4,8,eight)")!
}

test "map" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let n = m.map(fn(v) { v + "X" })
  @test.eq(
    n.debug_tree(),
    "(3,threeX,(1,oneX,(0,zeroX,_,_),(2,twoX,_,_)),(8,eightX,_,_))",
  )!
}

test "map_with_key" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let n = m.map_with_key(fn(k, v) { "\(k)-\(v)" })
  @test.eq(
    n.debug_tree(),
    "(3,3-three,(1,1-one,(0,0-zero,_,_),(2,2-two,_,_)),(8,8-eight,_,_))",
  )!
}

test "fold" {
  let m = of([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
  @test.eq(m.fold(fn(acc, v) { acc + v }, init=0), 15)!
}

test "foldl_with_key" {
  let m = of([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
  @test.eq(
    m.foldl_with_key(fn(acc, k, v) { acc + k + v.to_string() }, init=""),
    "a1b2c3d4e5",
  )!
}

test "foldr_with_key" {
  let m = of([("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)])
  @test.eq(
    m.foldr_with_key(fn(acc, k, v) { acc + k + v.to_string() }, init=""),
    "e5d4c3b2a1",
  )!
}

test "filter" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter(fn(v) { v.length() > 3 })
  @test.eq(fm.debug_tree(), "(3,three,(0,zero,_,_),(8,eight,_,_))")!
}

test "filter_with_key" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter_with_key(fn(k, v) { k > 3 && v.length() > 3 })
  @test.eq(fm.debug_tree(), "(8,eight,_,_)")!
}

test "to_array" {
  let m = of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq(
    m.iter().collect(),
    [(1, "one"), (2, "two"), (3, "three")],
  )!
}

test "keys" {
  let m = of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq(m.keys(), [1, 2, 3])!
}

test "elems" {
  let m = of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq(m.elems(), ["one", "two", "three"])!
}

test "singleton" {
  let m = singleton(3, "three")
  @test.eq(m.debug_tree(), "(3,three,_,_)")!
}

test "empty" {
  let m : Map[Int, Int] = empty()
  @test.eq(m.debug_tree(), "_")!
}

test "split_max" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  @test.eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let (k, v, r) = m.split_max()
  @test.eq(k, 8)!
  @test.eq(v, "eight")!
  @test.eq(
    r.debug_tree(),
    "(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )!
}

test "split_min" {
  let m = of([(3, "three"), (8, "eight"), (2, "two"), (1, "one"), (0, "zero")])
  @test.eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let (k, v, r) = m.split_min()
  @test.eq(k, 0)!
  @test.eq(v, "zero")!
  @test.eq(
    r.debug_tree(),
    "(3,three,(1,one,_,(2,two,_,_)),(8,eight,_,_))",
  )!
}

test "glue" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  @test.eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let (l, r) = match m {
    Tree(_, l, r, ..) => (l, r)
    _ => abort("unreachable")
  }
  let m = l.glue(r)
  @test.eq(
    m.debug_tree(),
    "(2,two,(1,one,(0,zero,_,_),_),(8,eight,_,_))",
  )!
}

test "op_equal" {
  let m1 = Map::[
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ]
  let m2 = Map::[
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ]
  let m3 = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two")])
  @test.eq(m1 == m2, true)!
  @test.eq(m1 == m3, false)!
}

test "debug_write" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let buffer = Buffer::new(size_hint=0)
  m.debug_write(buffer)
  @test.eq(
    buffer.to_string(),
    "Map::[(0, \"zero\"), (1, \"one\"), (2, \"two\"), (3, \"three\"), (8, \"eight\")]",
  )!
}

test "iter" {
  let buf = Buffer::new(size_hint=20)
  let map = of([(1, "one"), (2, "two"), (3, "three")])
  map.iter().each(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\(k)-\(v)]")
    },
  )
  inspect(buf, content="[1-one][2-two][3-three]")!
  buf.reset()
  map.iter().take(2).each(
    fn(e) {
      let (k, v) = e
      buf.write_string("[\(k)-\(v)]")
    },
  )
  inspect(buf, content="[1-one][2-two]")!
}

test "insert" {
  let m = of([(3, "three"), (8, "eight"), (1, "one")])
  inspect(m.debug_tree(), content="(3,three,(1,one,_,_),(8,eight,_,_))")!
  let m = m.insert(5, "five").insert(2, "two").insert(0, "zero").insert(
    1, "one_updated",
  )
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one_updated,(0,zero,_,_),(2,two,_,_)),(8,eight,(5,five,_,_),_))",
  )!
}

test "remove" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let m = m.remove(1).remove(3)
  @test.eq(m.debug_tree(), "(2,two,(0,zero,_,_),(8,eight,_,_))")!
}

test "filter" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter(fn(v) { v.length() > 3 })
  @test.eq(fm.debug_tree(), "(3,three,(0,zero,_,_),(8,eight,_,_))")!
}

test "filter_with_key" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter_with_key(fn(k, v) { k > 3 && v.length() > 3 })
  @test.eq(fm.debug_tree(), "(8,eight,_,_)")!
}

test "to_array" {
  let m = of([(1, "one"), (2, "two"), (3, "three")])
  @test.eq(m.to_array(), [(1, "one"), (2, "two"), (3, "three")])!
}

test "op_equal" {
  let m1 = Map::[
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ]
  let m2 = Map::[
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ]
  let m3 = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two")])
  @test.eq(m1 == m2, true)!
  @test.eq(m1 == m3, false)!
}

test "split_max with non-empty tree" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let (k, v, r) = m.split_max()
  inspect(k, content="8")!
  inspect(v, content="eight")!
  inspect(
    r.debug_tree(),
    content="(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )!
}
