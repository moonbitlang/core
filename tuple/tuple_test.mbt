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

test "pair" {
  let tuple = pair(1, 2)
  @test.eq(tuple, (1, 2))!
}

test "fst" {
  let tuple = (1, 2)
  @test.eq(fst(tuple), 1)!
}

test "snd" {
  let tuple = (1, 2)
  @test.eq(snd(tuple), 2)!
}

test "map_fst" {
  let tuple = (1, 2)
  let mapped = map_fst(fn(x : Int) -> Int { x + 1 }, tuple)
  @test.eq(mapped, (2, 2))!
}

test "map_snd" {
  let tuple = (1, 2)
  let mapped = map_snd(fn(x : Int) -> Int { x + 1 }, tuple)
  @test.eq(mapped, (1, 3))!
}

test "map_both" {
  let tuple = (1, 2)
  let mapped = map_both(
    fn(x : Int) -> Int { x + 1 },
    fn(x : Int) -> Int { x - 1 },
    tuple,
  )
  @test.eq(mapped, (2, 1))!
}

test "swap" {
  let tuple = (1, 2)
  let swapped = swap(tuple)
  let swapped_2 = swap(swapped)
  @test.eq(swapped, (2, 1))!
  @test.eq(swapped_2, tuple)!
}

test "curry" {
  let add = fn(x : Int, y : Int) -> Int { x + y }
  let curried_add = curry(add)
  @test.eq(curried_add(1)(2), add(1, 2))!
}

test "uncurry" {
  let add = fn(x : Int) -> (Int) -> Int { fn(y : Int) -> Int { x + y } }
  let uncurried_add = uncurry(add)
  @test.eq(uncurried_add(1, 2), add(1)(2))!
}

test "id_1" {
  let add = fn(x : Int, y : Int) -> Int { x + y }
  let curried_add = curry(add)
  let uncurried_add = uncurry(curried_add)
  @test.eq(uncurried_add(1, 2), add(1, 2))!
}

test "id_2" {
  let add = fn(x : Int) -> (Int) -> Int { fn(y : Int) -> Int { x + y } }
  let uncurried_add = uncurry(add)
  let curried_add = curry(uncurried_add)
  @test.eq(curried_add(1)(2), add(1)(2))!
}

test "eq" {
  inspect((1, 2) == (1, 2), content="true")!
  inspect((1, 2) == (2, 1), content="false")!
  inspect((1, 2, 3) == (1, 2, 3), content="true")!
  inspect((1, 2, 3) == (1, 2, 4), content="false")!
  inspect((1, 2, 3, 4) == (1, 2, 3, 4), content="true")!
  inspect((1, 2, 3, 4) == (1, 2, 3, 5), content="false")!
  inspect((1, 2, 3, 4, 5) == (1, 2, 3, 4, 5), content="true")!
  inspect((1, 2, 3, 4, 5) == (1, 2, 3, 4, 6), content="false")!
  inspect((1, 2, 3, 4, 5, 6) == (1, 2, 3, 4, 5, 6), content="true")!
  inspect((1, 2, 3, 4, 5, 6) == (1, 2, 3, 4, 6, 7), content="false")!
  inspect((1, 2, 3, 4, 5, 6, 7) == (1, 2, 3, 4, 5, 6, 7), content="true")!
  inspect((1, 2, 3, 4, 5, 6, 7) == (1, 2, 3, 4, 5, 6, 8), content="false")!
  inspect((1, 2, 3, 4, 5, 6, 7, 8) == (1, 2, 3, 4, 5, 6, 7, 8), content="true")!
  inspect((1, 2, 3, 4, 5, 6, 7, 8) == (1, 2, 3, 4, 5, 6, 7, 9), content="false")!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9) == (1, 2, 3, 4, 5, 6, 7, 8, 9),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9) == (1, 2, 3, 4, 5, 6, 7, 8, 10),
    content="false",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 11),
    content="false",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12),
    content="false",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13,
    ),
    content="false",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14,
    ),
    content="false",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15,
    ),
    content="false",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 11, 12, 13, 14, 16,
    ),
    content="false",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) == (
      1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 11, 12, 13, 14, 15, 17,
    ),
    content="false",
  )!
}

test "debug_write" {
  let tuple2 = (1, 2)
  let tuple3 = ("a", "b", "c")
  let tuple4 = (1, 2, 3, "hello")
  let tuple5 = ([1], "2", 3, ([4] : Array[_]), 5)
  let buf = Buffer::new(size_hint=0)
  tuple2.debug_write(buf)
  inspect(buf, content="(1, 2)")!
  buf.reset()
  tuple3.debug_write(buf)
  inspect(buf, content="(\"a\", \"b\", \"c\")")!
  buf.reset()
  tuple4.debug_write(buf)
  inspect(buf, content="(1, 2, 3, \"hello\")")!
  buf.reset()
  tuple5.debug_write(buf)
  inspect(
    buf,
    content=
      #|([1], "2", 3, [4], 5)
    ,
  )!
}

test "to_string" {
  let tuple2 = (1, 2)
  let tuple3 = ("a", "b", "c")
  let tuple4 = (1, 2, 3, "hello")
  let tuple5 = ([1], "2", 3, ([4] : Array[_]), 5)
  inspect(tuple2, content="(1, 2)")!
  inspect(tuple3, content="(a, b, c)")!
  inspect(tuple4, content="(1, 2, 3, hello)")!
  inspect(tuple5, content="([1], 2, 3, [4], 5)")!
  inspect((1, 2, 3, 4, 5, 6), content="(1, 2, 3, 4, 5, 6)")!
  inspect((1, 2, 3, 4, 5, 6, 7), content="(1, 2, 3, 4, 5, 6, 7)")!
}

test "hash" {
  // 2
  inspect((1, 1).hash(), content="-1047340487")!
  inspect((1, 2).hash(), content="1694622033")!
  inspect((1, 1).hash() == (1, 1).hash(), content="true")!
  // 3
  inspect((1, 2, 3).hash(), content="-1965913281")!
  inspect((1, 2, 4).hash(), content="555775519")!
  inspect((1, 2, 3).hash() == (1, 2, 3).hash(), content="true")!
  // 4
  inspect((1, 2, 3, 4).hash(), content="-1412678785")!
  inspect((1, 2, 3, 5).hash(), content="-1524291054")!
  inspect((1, 2, 3, 4).hash() == (1, 2, 3, 4).hash(), content="true")!
  // 5
  inspect((1, 2, 3, 4, 5).hash(), content="-1826495378")!
  inspect((1, 2, 3, 4, 6).hash(), content="2146860651")!
  inspect((1, 2, 3, 4, 5).hash() == (1, 2, 3, 4, 5).hash(), content="true")!
  // 6
  inspect((1, 2, 3, 4, 5, 6).hash(), content="349959464")!
  inspect((1, 2, 3, 4, 5, 7).hash(), content="-1764286275")!
  inspect(
    (1, 2, 3, 4, 5, 6).hash() == (1, 2, 3, 4, 5, 6).hash(),
    content="true",
  )!
  // 7
  inspect((1, 2, 3, 4, 5, 6, 7).hash(), content="-212820648")!
  inspect((1, 2, 3, 4, 5, 6, 8).hash(), content="177419378")!
  inspect(
    (1, 2, 3, 4, 5, 6, 7).hash() == (1, 2, 3, 4, 5, 6, 7).hash(),
    content="true",
  )!
  // 8
  inspect((1, 2, 3, 4, 5, 6, 7, 8).hash(), content="-182220067")!
  inspect((1, 2, 3, 4, 5, 6, 7, 9).hash(), content="-1480149729")!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8).hash() == (1, 2, 3, 4, 5, 6, 7, 8).hash(),
    content="true",
  )!
}
