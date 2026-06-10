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
  inspect(@bigint.parse_bigint("ff", base=16), content="255")
  inspect(@bigint.parse_bigint("-0"), content="0")
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
