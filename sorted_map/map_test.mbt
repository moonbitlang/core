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

test "should create with entries" {
  let map = of([(1, "a"), (2, "b"), (3, "c")])
  inspect(map.debug_tree(), content="([1]2,b,([0]1,a,_,_),([0]3,c,_,_))")?
  inspect(map.size(), content="3")?
}

test "should correctly add node" {
  let map = new()
  map.add(8, "a")
  map.add(7, "b")
  map.add(6, "c")
  map.add(5, "d")
  map.add(4, "e")
  map.add(3, "f")
  map.add(2, "g")
  map.add(1, "h")
  inspect(
    map.debug_tree(),
    content="([3]5,d,([2]3,f,([1]2,g,([0]1,h,_,_),_),([0]4,e,_,_)),([1]7,b,([0]6,c,_,_),([0]8,a,_,_)))",
  )?
  inspect(map.size(), content="8")?
}

test "should correctly remove node and rebalance" {
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
  inspect(
    map.debug_tree(),
    content="([3]4,d,([1]2,b,([0]1,a,_,_),([0]3,c,_,_)),([2]6,f,([0]5,e,_,_),([1]7,g,_,([0]8,h,_,_))))",
  )?
  inspect(map.size(), content="8")?
  map.remove(6)
  inspect(
    map.debug_tree(),
    content="([2]4,d,([1]2,b,([0]1,a,_,_),([0]3,c,_,_)),([1]7,g,([0]5,e,_,_),([0]8,h,_,_)))",
  )?
  inspect(map.size(), content="7")?
  map.remove(4)
  inspect(
    map.debug_tree(),
    content="([2]5,e,([1]2,b,([0]1,a,_,_),([0]3,c,_,_)),([1]7,g,_,([0]8,h,_,_)))",
  )?
  inspect(map.size(), content="6")?
  map.remove(2)
  inspect(
    map.debug_tree(),
    content="([2]5,e,([1]3,c,([0]1,a,_,_),_),([1]7,g,_,([0]8,h,_,_)))",
  )?
  inspect(map.size(), content="5")?
  map.remove(3)
  inspect(
    map.debug_tree(),
    content="([2]5,e,([0]1,a,_,_),([1]7,g,_,([0]8,h,_,_)))",
  )?
  inspect(map.size(), content="4")?
  map.remove(5)
  inspect(map.debug_tree(), content="([1]7,g,([0]1,a,_,_),([0]8,h,_,_))")?
  inspect(map.size(), content="3")?
  map.remove(7)
  inspect(map.debug_tree(), content="([1]8,h,([0]1,a,_,_),_)")?
  inspect(map.size(), content="2")?
  map.remove(8)
  inspect(map.debug_tree(), content="([0]1,a,_,_)")?
  inspect(map.size(), content="1")?
  map.remove(1)
  inspect(map.debug_tree(), content="_")?
  inspect(map.size(), content="0")?
}
