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

test "remove2" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b")])
  inspect!(map.size(), content="2")
  map.remove(1)
  inspect!(map.size(), content="1")
}

test "remove3" {
  let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c")])
  map.remove(0)
  inspect!(map.size(), content="3")
  map.remove(4)
  inspect!(map.size(), content="3")
}

test "remove on empty map" {
  let map : @sorted_map.T[Int, String] = @sorted_map.new()
  map.remove(1)
  inspect!(map.size(), content="0")
}

test "get" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(
    map.get(1),
    content=
      #|Some("a")
    ,
  )
  inspect!(
    map.get(2),
    content=
      #|Some("b")
    ,
  )
  inspect!(
    map.get(3),
    content=
      #|Some("c")
    ,
  )
  inspect!(map.get(4), content="None")
}

test "contains" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.contains(1), content="true")
  inspect!(map.contains(2), content="true")
  inspect!(map.contains(3), content="true")
  inspect!(map.contains(4), content="false")
}

test "op_get" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(
    map[1],
    content=
      #|Some("a")
    ,
  )
  inspect!(
    map[2],
    content=
      #|Some("b")
    ,
  )
  inspect!(
    map[3],
    content=
      #|Some("c")
    ,
  )
  inspect!(map[4], content="None")
}

test "op_equal" {
  let a = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let b = @sorted_map.from_array([(4, "d"), (5, "e"), (6, "f")])
  inspect!(a == a, content="true")
  inspect!(b == b, content="true")
  inspect!(a == b, content="false")
  inspect!(b == a, content="false")
}

test "is_empty" {
  let map : @sorted_map.T[Int, String] = @sorted_map.new()
  inspect!(map.is_empty(), content="true")
  map[1] = "a"
  inspect!(map.is_empty(), content="false")
}

test "size" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.size() == map.size(), content="true")
}

test "each" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  map.each(fn(k, v) { buf.write_string("\{k}\{v}") })
  inspect!(buf.to_string(), content="1a2b3c")
}

test "eachi" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  map.eachi(fn(i, k, v) { buf.write_string("[\{i}]\{k}\{v}") })
  inspect!(buf.to_string(), content="[0]1a[1]2b[2]3c")
}

test "keys" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(map.keys(), content="[1, 2, 3]")
}

test "values" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(
    map.values(),
    content=
      #|["a", "b", "c"]
    ,
  )
}

test "to_array" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(
    map.to_array(),
    content=
      #|[(1, "a"), (2, "b"), (3, "c")]
    ,
  )
}

test "iter" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect!(
    map.iter().collect(),
    content=
      #|[(1, "a"), (2, "b"), (3, "c")]
    ,
  )
  inspect!(
    map.iter().take(2).collect(),
    content=
      #|[(1, "a"), (2, "b")]
    ,
  )
}

test "from_iter multiple elements iter" {
  inspect!(
    @sorted_map.from_iter([(1, 1), (2, 2), (3, 3)].iter()),
    content="@sorted_map.of([(1, 1), (2, 2), (3, 3)])",
  )
}

test "from_iter single element iter" {
  inspect!(
    @sorted_map.from_iter([(1, 1)].iter()),
    content="@sorted_map.of([(1, 1)])",
  )
}

test "from_iter empty iter" {
  let pq : @sorted_map.T[Int, Int] = @sorted_map.from_iter(Iter::empty())
  inspect!(pq, content="@sorted_map.of([])")
}

test "arbitrary" {
  let map : Array[@sorted_map.T[Int, UInt]] = @quickcheck.samples(20)
  inspect!(
    map[5:10],
    content="[@sorted_map.of([(-2, 2), (0, 1)]), @sorted_map.of([(0, 2), (1, 2)]), @sorted_map.of([(0, 0)]), @sorted_map.of([(0, 0)]), @sorted_map.of([(-2, 5), (0, 1), (2, 0), (4, 1)])]",
  )
  inspect!(
    map[11:15],
    content="[@sorted_map.of([(0, 0)]), @sorted_map.of([(-1, 2), (0, 2)]), @sorted_map.of([(-4, 1), (-3, 2), (-1, 2), (0, 2), (1, 4), (3, 2), (6, 1)]), @sorted_map.of([(0, 0)])]",
  )
}

test "iter2" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  for k, v in map {
    buf.write_string("[\{k}\{v}]")
  }
  inspect!(buf, content="[1a][2b][3c]")
}

test "iter" {
  let map = @sorted_map.from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  for kv in map {
    buf.write_string("[\{kv.0}\{kv.1}]")
  }
  inspect!(buf, content="[1a][2b][3c]")
}

test "range" {
  let map = @sorted_map.from_array([
    (1, "a"),
    (2, "b"),
    (3, "c"),
    (4, "d"),
    (5, "e"),
  ])
  let result = map.range(2, 4)
  let buf = StringBuilder::new()
  for k, v in result {
    buf.write_string("[\{k}\{v}]")
  }
  inspect!(buf, content="[2b][3c][4d]")
}
