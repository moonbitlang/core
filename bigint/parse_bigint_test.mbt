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
test "parse_bigint valid" {
  inspect(@bigint.parse_bigint("12345"), content="12345")
  inspect(@bigint.parse_bigint("-12345"), content="-12345")
  inspect(@bigint.parse_bigint("101010", base=2), content="42")
  inspect(@bigint.parse_bigint("52", base=8), content="42")
  inspect(@bigint.parse_bigint("ff", base=16), content="255")
  inspect(@bigint.parse_bigint("-0"), content="0")
}

///|
test "parse_bigint StringView" {
  let input = "prefix-ffsuffix"
  inspect(
    @bigint.parse_bigint(input.view(start_offset=6, end_offset=9), base=16),
    content="-255",
  )
}

///|
test "parse_bigint empty" {
  assert_true(
    @test.expect_error(() => @bigint.parse_bigint(""))
    is Failure::Failure("invalid syntax"),
  )
}

///|
test "parse_bigint sign only" {
  assert_true(
    @test.expect_error(() => @bigint.parse_bigint("-"))
    is Failure::Failure("invalid syntax"),
  )
}

///|
test "parse_bigint invalid character" {
  assert_true(
    @test.expect_error(() => @bigint.parse_bigint("12a"))
    is Failure::Failure("invalid syntax"),
  )
}

///|
test "parse_bigint invalid digit for radix" {
  assert_true(
    @test.expect_error(() => @bigint.parse_bigint("2", base=2))
    is Failure::Failure("invalid syntax"),
  )
}

///|
test "parse_bigint invalid base" {
  assert_true(
    @test.expect_error(() => @bigint.parse_bigint("10", base=1))
    is Failure::Failure("invalid base"),
  )
}

///|
test "parse_bigint radix 16 invalid character" {
  assert_true(
    @test.expect_error(() => @bigint.parse_bigint("g", base=16))
    is Failure::Failure("invalid syntax"),
  )
}

///|
test "parse_bigint rejects prefixes and plus sign" {
  for input in ["0x10", "0o10", "0b10", "-0x10", "+10"] {
    assert_true(
      @test.expect_error(() => @bigint.parse_bigint(input))
      is Failure::Failure("invalid syntax"),
    )
  }
}

///|
test "parse_bigint rejects trailing whitespace" {
  for case in [("42 ", 10), ("10\t", 2), ("52\n", 8), ("ff ", 16)] {
    let (input, base) = case
    assert_true(
      @test.expect_error(() => @bigint.parse_bigint(input, base~))
      is Failure::Failure("invalid syntax"),
    )
  }
}
