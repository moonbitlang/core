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
  let map : T[Int, String] = new()
  inspect!(map.debug_tree(), content="_")
  inspect!(map.size(), content="0")
}

test "of" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  inspect!(map.size(), content="3")
}

test "add1" {
  let map = new()
  map.add(6, "a")
  map.add(5, "b")
  map.add(4, "c")
  map.add(3, "d")
  map.add(2, "e")
  map.add(1, "f")
  inspect!(
    map.debug_tree(),
    content="([3]3,d,([2]2,e,([1]1,f,_,_),_),([2]5,b,([1]4,c,_,_),([1]6,a,_,_)))",
  )
  inspect!(map.size(), content="6")
}

test "add2" {
  let map = new()
  map.add(1, "a")
  map.add(2, "b")
  map.add(3, "c")
  map.add(4, "d")
  map.add(5, "e")
  map.add(6, "f")
  inspect!(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]5,e,_,([1]6,f,_,_)))",
  )
  inspect!(map.size(), content="6")
}

test "add3" {
  let map = new()
  map.add(4, "a")
  map.add(1, "b")
  map.add(3, "c")
  map.add(2, "d")
  inspect!(
    map.debug_tree(),
    content="([3]3,c,([2]1,b,_,([1]2,d,_,_)),([1]4,a,_,_))",
  )
}

test "add4" {
  let map = new()
  map.add(1, "a")
  map.add(4, "b")
  map.add(2, "c")
  map.add(3, "d")
  inspect!(
    map.debug_tree(),
    content="([3]2,c,([1]1,a,_,_),([2]4,b,([1]3,d,_,_),_))",
  )
}

test "add duplicate key" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
  map.add(1, "x")
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,x,_,_),([1]3,c,_,_))")
}

test "remove" {
  let map = of(
    [
      (1, "a"),
      (2, "b"),
      (3, "c"),
      (4, "d"),
      (5, "e"),
      (6, "f"),
      (7, "g"),
      (8, "h"),
    ],
  )
  inspect!(
    map.debug_tree(),
    content="([4]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([3]6,f,([1]5,e,_,_),([2]7,g,_,([1]8,h,_,_))))",
  )
  inspect!(map.size(), content="8")
  map.remove(6)
  inspect!(
    map.debug_tree(),
    content="([3]4,d,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,([1]5,e,_,_),([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="7")
  map.remove(4)
  inspect!(
    map.debug_tree(),
    content="([3]5,e,([2]2,b,([1]1,a,_,_),([1]3,c,_,_)),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="6")
  map.remove(2)
  inspect!(
    map.debug_tree(),
    content="([3]5,e,([2]3,c,([1]1,a,_,_),_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="5")
  map.remove(3)
  inspect!(
    map.debug_tree(),
    content="([3]5,e,([1]1,a,_,_),([2]7,g,_,([1]8,h,_,_)))",
  )
  inspect!(map.size(), content="4")
  map.remove(5)
  inspect!(map.debug_tree(), content="([2]7,g,([1]1,a,_,_),([1]8,h,_,_))")
  inspect!(map.size(), content="3")
  map.remove(7)
  inspect!(map.debug_tree(), content="([2]8,h,([1]1,a,_,_),_)")
  inspect!(map.size(), content="2")
  map.remove(8)
  inspect!(map.debug_tree(), content="([1]1,a,_,_)")
  inspect!(map.size(), content="1")
  map.remove(1)
  inspect!(map.debug_tree(), content="_")
  inspect!(map.size, content="0")
}

test "remove2" {
  let map = of([(1, "a"), (2, "b")])
  inspect!(map.size, content="2")
  map.remove(1)
  inspect!(map.size, content="1")
}

test "remove3" {
  let map = of([(1, "a"), (2, "b"), (3, "c")])
  map.remove(0)
  inspect!(map.size, content="3")
  map.remove(4)
  inspect!(map.size, content="3")
}

test "remove on empty map" {
  let map : T[Int, String] = new()
  map.remove(1)
  inspect!(map.size, content="0")
}

test "get" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.get(1), content="Some(a)")
  inspect!(map.get(2), content="Some(b)")
  inspect!(map.get(3), content="Some(c)")
  inspect!(map.get(4), content="None")
}

test "contains" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.contains(1), content="true")
  inspect!(map.contains(2), content="true")
  inspect!(map.contains(3), content="true")
  inspect!(map.contains(4), content="false")
}

test "op_set" {
  let map = new()
  map[1] = "a"
  map[2] = "b"
  map[3] = "c"
  inspect!(map.debug_tree(), content="([2]2,b,([1]1,a,_,_),([1]3,c,_,_))")
}

test "op_get" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map[1], content="Some(a)")
  inspect!(map[2], content="Some(b)")
  inspect!(map[3], content="Some(c)")
  inspect!(map[4], content="None")
}

test "op_equal" {
  let a = of([(3, "c"), (2, "b"), (1, "a")])
  let b = of([(4, "d"), (5, "e"), (6, "f")])
  inspect!(a == a, content="true")
  inspect!(b == b, content="true")
  inspect!(a == b, content="false")
  inspect!(b == a, content="false")
}

test "is_empty" {
  let map : T[Int, String] = new()
  inspect!(map.is_empty(), content="true")
  map[1] = "a"
  inspect!(map.is_empty(), content="false")
}

test "size" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.size == map.size(), content="true")
}

test "clear" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  map.clear()
  inspect!(map.debug_tree(), content="_")
  inspect!(map.size, content="0")
}

test "each" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  let buf = Buffer::new()
  map.each(fn(k, v) { buf.write_string("\(k)\(v)") })
  inspect!(buf.to_string(), content="1a2b3c")
}

test "eachi" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  let buf = Buffer::new()
  map.eachi(fn(i, k, v) { buf.write_string("[\(i)]\(k)\(v)") })
  inspect!(buf.to_string(), content="[0]1a[1]2b[2]3c")
}

test "keys" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.keys(), content="[1, 2, 3]")
}

test "values" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.values(), content="[a, b, c]")
}

test "to_array" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.to_array(), content="[(1, a), (2, b), (3, c)]")
}

test "iter" {
  let map = of([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.iter().collect(), content="[(1, a), (2, b), (3, c)]")
  inspect!(map.iter().take(2).collect(), content="[(1, a), (2, b)]")
}
