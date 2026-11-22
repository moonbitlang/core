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
  for value in @quickcheck.int_range(-4, 7, inclusive=false).samples(count=64) {
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
test "int_range samples both parts of a wide signed interval without modulo bias" {
  // The first 2^32 % 3_000_000_000 offsets occupy about 43.2% of
  // this interval, but take about 60.3% of raw 32-bit draws modulo its width.
  let mut prefix = 0
  for
    x in @quickcheck.int_range(-1500000000, 1500000000, inclusive=false).samples(
      count=4096,
    ) {
    assert_true(x >= -1500000000 && x < 1500000000)
    if x < -205032704 {
      prefix += 1
    }
  }
  assert_true(prefix >= 1550 && prefix <= 1950)
}

///|
test "frequency gives equal large weights equal coverage" {
  fn check(weight : UInt32) -> Unit raise {
    let generator = @quickcheck.frequency([
      (weight, @quickcheck.pure(0)),
      (0U, @quickcheck.pure(2)),
      (weight, @quickcheck.pure(1)),
    ])
    let mut left = 0
    for x in generator.samples(count=4096) {
      assert_true(x == 0 || x == 1)
      if x == 0 {
        left += 1
      }
    }
    assert_true(left >= 1850 && left <= 2250)
  }

  check(0x80000000U) // exactly 2^32
  check(1500000000U) // a total below 2^32, with pronounced modulo bias
  check(0x90000000U) // above 2^32
}

///|
test "elements selects only supplied values" {
  debug_inspect(
    @quickcheck.elements(["red", "green", "blue"]).samples(count=20),
    content=(
      #|[
      #|  "green",
      #|  "red",
      #|  "red",
      #|  "green",
      #|  "blue",
      #|  "green",
      #|  "red",
      #|  "blue",
      #|  "green",
      #|  "green",
      #|  "blue",
      #|  "red",
      #|  "red",
      #|  "red",
      #|  "blue",
      #|  "blue",
      #|  "blue",
      #|  "blue",
      #|  "red",
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
  for
    value in @quickcheck.char_range('a', 'z', inclusive=true).samples(count=64) {
    guard value is ('a'..<='z') else {
      fail("char_range generated an out-of-range character")
    }
  }
  inspect(
    @quickcheck.char_range('x', 'x', inclusive=true).sample(),
    content="x",
  )
}

///|
test "panic char_range rejects surrogate bounds" {
  ignore(
    @quickcheck.char_range(' ', Int(0xD800).unsafe_to_char(), inclusive=true),
  )
}

///|
test "char_range skips the surrogate block" {
  let mut below = 0
  let mut above = 0
  for
    value in @quickcheck.char_range('\u{D000}', '\u{E800}', inclusive=true).samples(
      count=64,
    ) {
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
  let pairs = @quickcheck.int_range(0, 10, inclusive=false)
    .zip(@quickcheck.char_range('a', 'f', inclusive=true))
    .samples(count=4)
  debug_inspect(
    pairs,
    content=(
      #|[(4, 'd'), (9, 'e'), (9, 'a'), (8, 'b')]
    ),
  )
}

///|
test "zip_with and zip_with3 combine generator outputs" {
  let sums = @quickcheck.int_range(0, 10, inclusive=false)
    .zip_with(@quickcheck.int_range(0, 10, inclusive=false), (a, b) => a + b)
    .samples(count=6)
  debug_inspect(
    sums,
    content=(
      #|[5, 11, 15, 17, 12, 8]
    ),
  )
  let dates = @quickcheck.int_range(2000, 2002, inclusive=false)
    .zip_with3(
      @quickcheck.int_range(1, 13, inclusive=false),
      @quickcheck.int_range(1, 29, inclusive=false),
      (year, month, day) => "\{year}-\{month}-\{day}",
    )
    .samples(count=3)
  debug_inspect(
    dates,
    content=(
      #|["2001-2-26", "2001-10-25", "2001-10-16"]
    ),
  )
}

///|
test "spawn composes with generator combinators" {
  let entries = (@quickcheck.spawn() : @quickcheck.Generator[String])
    .zip((@quickcheck.spawn() : @quickcheck.Generator[Int32]))
    .samples(count=3, size=4, seed=37)
  debug_inspect(
    entries,
    content=(
      #|[
      #|  (")󈇚\u{03}", -841733569),
      #|  ("2\u{03}\b", -1019217858),
      #|  ("L9", -1240909043),
      #|]
    ),
  )
}

///|
test "int_range includes the upper endpoint when requested" {
  let max = @int.MAX_VALUE
  let closed = @quickcheck.int_range(max - 1, max, inclusive=true).samples(
    count=32,
  )
  assert_true(closed.contains(max - 1) && closed.contains(max))
  let full = @quickcheck.int_range(@int.MIN_VALUE, max, inclusive=true).samples(
    count=32,
  )
  assert_true(full.any(x => x < 0) && full.any(x => x >= 0))
  inspect(@quickcheck.int_range(7, 7, inclusive=false).sample(), content="7")
}

///|
test "char_range can exclude the first scalar after the surrogate block" {
  let chars = @quickcheck.char_range('\u{D7FF}', '\u{E000}', inclusive=false)
  assert_true(chars.samples(count=32).all(c => c == '\u{D7FF}'))
  inspect(
    @quickcheck.char_range('x', 'x', inclusive=false).sample(),
    content="x",
  )
}

///|
#warnings("-deprecated")
test "omitting inclusive preserves the old seeded samples" {
  assert_eq(
    @quickcheck.int_range(0, 10).samples(),
    @quickcheck.int_range(0, 10, inclusive=false).samples(),
  )
  assert_eq(
    @quickcheck.char_range('a', 'z').samples(),
    @quickcheck.char_range('a', 'z', inclusive=true).samples(),
  )
}
