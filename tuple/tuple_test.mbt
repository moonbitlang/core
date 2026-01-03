// Copyright 2026 International Digital Economy Academy
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
test "eq" {
  inspect((1, 2) == (1, 2), content="true")
  inspect((1, 2) == (2, 1), content="false")
  inspect((1, 2, 3) == (1, 2, 3), content="true")
  inspect((1, 2, 3) == (1, 2, 4), content="false")
  inspect((1, 2, 3, 4) == (1, 2, 3, 4), content="true")
  inspect((1, 2, 3, 4) == (1, 2, 3, 5), content="false")
  inspect((1, 2, 3, 4, 5) == (1, 2, 3, 4, 5), content="true")
  inspect((1, 2, 3, 4, 5) == (1, 2, 3, 4, 6), content="false")
  inspect((1, 2, 3, 4, 5, 6) == (1, 2, 3, 4, 5, 6), content="true")
  inspect((1, 2, 3, 4, 5, 6) == (1, 2, 3, 4, 6, 7), content="false")
  inspect((1, 2, 3, 4, 5, 6, 7) == (1, 2, 3, 4, 5, 6, 7), content="true")
  inspect((1, 2, 3, 4, 5, 6, 7) == (1, 2, 3, 4, 5, 6, 8), content="false")
  inspect((1, 2, 3, 4, 5, 6, 7, 8) == (1, 2, 3, 4, 5, 6, 7, 8), content="true")
  inspect((1, 2, 3, 4, 5, 6, 7, 8) == (1, 2, 3, 4, 5, 6, 7, 9), content="false")
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9) == (1, 2, 3, 4, 5, 6, 7, 8, 9),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9) == (1, 2, 3, 4, 5, 6, 7, 8, 10),
    content="false",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 11),
    content="false",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) == (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12),
    content="false",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13),
    content="false",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14),
    content="false",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15),
    content="false",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 11, 12, 13, 14, 16),
    content="false",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16),
    content="true",
  )
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) ==
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 11, 12, 13, 14, 15, 17),
    content="false",
  )
}

///|
test "compare" {
  assert_eq((1, 2).compare((2, 1)), -1)
  assert_eq((1, 2).compare((1, 3)), -1)
  assert_eq((1, 2, 3).compare((1, 2, 5)), -1)
  assert_eq((1, 2, 3).compare((1, 3, 3)), -1)
  assert_eq((1, 2, (3, 4)).compare((1, 2, (4, 4))), -1)
  assert_eq((1, 2, (4, 6)).compare((1, 2, (4, 5))), 1)
  assert_eq((1, 2, 4).compare((1, 2, 3)), 1)
  assert_eq((1, 3, 3).compare((1, 2, 3)), 1)
}

///|
test "hash" {
  let tuple1 = (1, 2, 3, 4, 5)
  let tuple2 = (1, 2, 3, 4, 5)
  inspect(tuple1.hash() == tuple2.hash(), content="true")
  let tuple3 = (5, 4, 3, 2, 1)
  inspect(tuple1.hash() == tuple1.hash(), content="true")
  inspect(tuple2.hash() == tuple2.hash(), content="true")
  inspect(tuple3.hash() == tuple3.hash(), content="true")
  inspect(tuple1.hash() == tuple3.hash(), content="false")
}

///|
test "show" {
  let tuple2 = (1, 2)
  let tuple3 = ("a", "b", "c")
  let tuple4 = (1, 2, 3, "hello")
  let tuple5 = ([1], "2", 3, ([4] : Array[_]), 5)
  inspect(tuple2, content="(1, 2)")
  inspect(tuple3, content="(\"a\", \"b\", \"c\")")
  inspect(tuple4, content="(1, 2, 3, \"hello\")")
  inspect(
    tuple5,
    content=(
      #|([1], "2", 3, [4], 5)
    ),
  )
}

///|
test "to_string" {
  let tuple2 = (1, 2)
  let tuple3 = ("a", "b", "c")
  let tuple4 = (1, 2, 3, "hello")
  let tuple5 = ([1], "2", 3, ([4] : Array[_]), 5)
  inspect(tuple2, content="(1, 2)")
  inspect(
    tuple3,
    content=(
      #|("a", "b", "c")
    ),
  )
  inspect(
    tuple4,
    content=(
      #|(1, 2, 3, "hello")
    ),
  )
  inspect(
    tuple5,
    content=(
      #|([1], "2", 3, [4], 5)
    ),
  )
  inspect((1, 2, 3, 4, 5, 6), content="(1, 2, 3, 4, 5, 6)")
  inspect((1, 2, 3, 4, 5, 6, 7), content="(1, 2, 3, 4, 5, 6, 7)")
}

///|
test "arbitrary" {
  let t : Array[(Int, String)] = @quickcheck.samples(5)
  inspect(
    t,
    content=(
      #|[(0, ""), (0, ""), (0, ""), (-2, "=l"), (2, "m")]
    ),
  )
  let t : Array[(Int, String, UInt)] = @quickcheck.samples(5)
  inspect(
    t,
    content=(
      #|[(0, "", 0), (0, "", 0), (0, "", 1), (-2, "@>", 0), (2, "\u{1a}", 0)]
    ),
  )
  let t : Array[(Int, String, UInt, Byte)] = @quickcheck.samples(5)
  inspect(
    t,
    content=(
      #|[(0, "", 0, b'\x2A'), (0, "", 0, b'\x77'), (0, "", 1, b'\x0D'), (-2, "@>", 1, b'\x4A'), (2, "\u{1a}", 0, b'\xE5')]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char)] = @quickcheck.samples(5)
  inspect(
    t,
    content=(
      #|[(0, "", 0, b'\x89', '%'), (0, "", 0, b'\x3B', '\u{16}'), (0, "", 1, b'\x08', 'l'), (-2, "@>", 1, b'\x23', 't'), (2, "\u{1a}", 0, b'\xB7', 'q')]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char, Bool)] = @quickcheck.samples(5)
  inspect(
    t,
    content=(
      #|[(0, "", 0, b'\x89', '3', true), (0, "", 0, b'\x3B', 'x', true), (0, "", 1, b'\x08', 'P', true), (-2, "@>", 1, b'\x23', 'd', false), (2, "\u{1a}", 0, b'\xB7', '\u{1d}', true)]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char, Bool, Unit)] = @quickcheck.samples(
    5,
  )
  inspect(
    t,
    content=(
      #|[(0, "", 0, b'\x89', '3', false, ()), (0, "", 0, b'\x3B', 'x', true, ()), (0, "", 1, b'\x08', 'P', true, ()), (-2, "@>", 1, b'\x23', 'd', true, ()), (2, "\u{1a}", 0, b'\xB7', '\u{1d}', true, ())]
    ),
  )
}
