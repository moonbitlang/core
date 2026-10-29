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
test "parse_decimal" {
  let s = "0.0000000000000000000000000000007888609052210118054117285652827862296732064351090230047702789306640625"
  @test.assert_eq(parse_decimal_priv(s).to_string(), s)
  @test.assert_eq(parse_decimal_priv("1.0e-10").to_string(), "0.0000000001")
}

///|
test "shift" {
  let tests : Array[_] = [
    (0L, 100, "0"),
    (0L, -100, "0"),
    (1L, 100, "1267650600228229401496703205376"),
    (
      1L, -100, "0.0000000000000000000000000000007888609052210118054117285652827862296732064351090230047702789306640625",
    ),
    (12345678L, 8, "3160493568"),
    (12345678L, -8, "48225.3046875"),
    (195312L, 9, "99999744"),
    (1953125L, 9, "1000000000"),
  ]
  for t in tests {
    let d = Decimal::from_int64_priv(t.0)
    d.shift_priv(t.1)
    @test.assert_eq(d.to_string(), t.2)
  }
}

///|
test "parse decimal error" {
  assert_true(
    @test.expect_error(() => parse_decimal_priv("1e"))
    is Failure("invalid syntax"),
  )
  assert_true(
    @test.expect_error(() => parse_decimal_priv("1e+"))
    is Failure("invalid syntax"),
  )
  assert_true(
    @test.expect_error(() => parse_decimal_priv("1e_"))
    is Failure("invalid syntax"),
  )
  assert_true(
    @test.expect_error(() => parse_decimal_priv("1-23"))
    is Failure("invalid syntax"),
  )
  assert_true(
    @test.expect_error(() => parse_decimal_priv("1.2.3"))
    is Failure("invalid syntax"),
  )
}

///|
test "corner cases" {
  let _ = parse_decimal_priv(".123")
  assert_true(
    @test.expect_error(() => parse_decimal_priv("."))
    is Failure("invalid syntax"),
  )
  assert_true(
    @test.expect_error(() => parse_decimal_priv("-"))
    is Failure("invalid syntax"),
  )
}
