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
test "construct, map, and flat_map" {
  let from_size = @quickcheck.Generator((size, _) => size)
  inspect(from_size.sample(size=12), content="12")
  let value = @quickcheck.pure(20)
    .map(x => x + 1)
    .flat_map(x => @quickcheck.pure(x * 2))
  inspect(value.sample(), content="42")
}

///|
test "size control" {
  let generator = @quickcheck.sized(size => @quickcheck.pure(size))
  inspect(generator.sample(size=9), content="9")
  inspect(generator.resize(3).sample(size=9), content="3")
}

///|
test "scale transforms the input size" {
  let generator = @quickcheck.Generator((size, _) => size)
  inspect(generator.scale(size => size * 2 + 1).sample(size=4), content="9")
}

///|
test "range and choices" {
  for value in @quickcheck.int_range(-4, 7).samples(count=64) {
    guard value >= -4 && value < 7 else {
      fail("int_range generated an out-of-range value")
    }
  }
  for
    value in @quickcheck.one_of([@quickcheck.pure(1), @quickcheck.pure(2)]).samples(
      count=32,
    ) {
    guard value == 1 || value == 2 else {
      fail("one_of generated a value outside its inputs")
    }
  }
  for
    value in @quickcheck.frequency([
      (1U, @quickcheck.pure("a")),
      (3U, @quickcheck.pure("b")),
    ]).samples(count=32) {
    guard value == "a" || value == "b" else {
      fail("frequency generated a value outside its inputs")
    }
  }
}

///|
test "elements selects only supplied values" {
  debug_inspect(
    @quickcheck.elements(["red", "green", "blue"]).samples(count=20),
    content=(
      #|[
      #|  "red",
      #|  "red",
      #|  "red",
      #|  "green",
      #|  "blue",
      #|  "red",
      #|  "red",
      #|  "red",
      #|  "blue",
      #|  "green",
      #|  "blue",
      #|  "blue",
      #|  "red",
      #|  "red",
      #|  "blue",
      #|  "green",
      #|  "green",
      #|  "green",
      #|  "green",
      #|  "green",
      #|]
    ),
  )
}

///|
test "fixed-size array" {
  let values = @quickcheck.pure(7).array_with_size(3).sample()
  inspect(values.length(), content="3")
  inspect(values.all(value => value == 7), content="true")
}

///|
test "char_range stays within bounds" {
  for value in @quickcheck.char_range('a', 'z').samples(count=64) {
    guard value is ('a'..='z') else {
      fail("char_range generated an out-of-range character")
    }
  }
  inspect(@quickcheck.char_range('x', 'x').sample(), content="x")
}

///|
test "panic char_range rejects surrogate bounds" {
  ignore(@quickcheck.char_range(' ', (0xD800 : Int).unsafe_to_char()))
}

///|
test "char_range skips the surrogate block" {
  let mut below = 0
  let mut above = 0
  for value in @quickcheck.char_range('\u{D000}', '\u{E800}').samples(count=64) {
    let code = value.to_int()
    guard code >= 0xD000 && code <= 0xE800 else {
      fail("char_range generated an out-of-range character")
    }
    guard !(code >= 0xD800 && code <= 0xDFFF) else {
      fail("char_range generated a surrogate code point")
    }
    if code < 0xD800 {
      below += 1
    } else {
      above += 1
    }
  }
  assert_true(below > 0 && above > 0)
}

///|
test "zip pairs two generators" {
  let pairs = @quickcheck.int_range(0, 10)
    .zip(@quickcheck.char_range('a', 'f'))
    .samples(count=4)
  debug_inspect(
    pairs,
    content=(
      #|[(0, 'f'), (2, 'b'), (5, 'b'), (6, 'b')]
    ),
  )
}

///|
test "zip_with and zip_with3 combine generator outputs" {
  let sums = @quickcheck.int_range(0, 10)
    .zip_with(@quickcheck.int_range(0, 10), (a, b) => a + b)
    .samples(count=6)
  debug_inspect(
    sums,
    content=(
      #|[9, 7, 8, 7, 10, 15]
    ),
  )
  let dates = @quickcheck.int_range(2000, 2002)
    .zip_with3(@quickcheck.int_range(1, 13), @quickcheck.int_range(1, 29), (
      year,
      month,
      day,
    ) => "\{year}-\{month}-\{day}")
    .samples(count=3)
  debug_inspect(
    dates,
    content=(
      #|["2000-7-6", "2000-10-4", "2001-5-5"]
    ),
  )
}

///|
test "spawn composes with generator combinators" {
  let entries = (@quickcheck.Generator::spawn() : @quickcheck.Generator[String])
    .zip((@quickcheck.Generator::spawn() : @quickcheck.Generator[Int]))
    .samples(count=3, size=4, seed=37)
  debug_inspect(
    entries,
    content=(
      #|[("", 3), ("Z\b", 3), ("", 0)]
    ),
  )
}
