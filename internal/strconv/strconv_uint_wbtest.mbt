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
test "parse_uint64" {
  let tests : Array[(String, Result[UInt64, String])] = [
    ("", Err(syntax_err_str)),
    ("0", Ok(0UL)),
    ("-0", Err(syntax_err_str)),
    ("+0", Err(syntax_err_str)),
    ("1", Ok(1UL)),
    ("-1", Err(syntax_err_str)),
    ("12345", Ok(12345UL)),
    ("-12345", Err(syntax_err_str)),
    ("012345", Ok(12345UL)),
    ("9876543210", Ok(9876543210UL)),
    ("18446744073709551615", Ok(18446744073709551615UL)),
    ("18446744073709551616", Err(range_err_str)),
    ("1_2_3_4_5", Ok(12345UL)),
    ("_12345", Err(syntax_err_str)),
    ("1__2345", Err(syntax_err_str)),
    ("12345_", Err(syntax_err_str)),
    ("12345%", Err(syntax_err_str)),
  ]
  for t in tests {
    @test.assert_eq(
      Result::Ok(parse_uint64(t.0)) catch {
        Failure::Failure(err) => Err(err)
        err => Err(err.to_string())
      },
      t.1,
    )
  }
}

///|
test "parse_uint64_base" {
  let tests : Array[(String, Int32, Result[UInt64, String])] = [
    ("", 0, Err(syntax_err_str)),
    ("0", 0, Ok(0UL)),
    ("1", 0, Ok(1UL)),
    ("12345", 0, Ok(12345UL)),
    ("012345", 0, Ok(12345UL)),
    ("0x12345", 0, Ok(0x12345UL)),
    ("9876543210", 0, Ok(9876543210UL)),
    ("18446744073709551615", 0, Ok(UINT64_MAX)),
    ("0xffffffffffffffff", 0, Ok(UINT64_MAX)),
    ("18446744073709551616", 0, Err(range_err_str)),
    ("12345x", 0, Err(syntax_err_str)),
    ("-12345x", 0, Err(syntax_err_str)),
    // other bases
    ("h", 18, Ok(17UL)),
    ("10", 25, Ok(25UL)),
    (
      "moonbit",
      35,
      Ok(
        (
          ((((22UL * 35UL + 24UL) * 35UL + 24UL) * 35UL + 23UL) * 35UL + 11UL) *
          35UL +
          18UL
        ) *
        35UL +
        29UL,
      ),
    ),
    (
      "moonbit",
      36,
      Ok(
        (
          ((((22UL * 36UL + 24UL) * 36UL + 24UL) * 36UL + 23UL) * 36UL + 11UL) *
          36UL +
          18UL
        ) *
        36UL +
        29UL,
      ),
    ),
    // base 2
    ("0", 2, Ok(0UL)),
    ("-1", 2, Err(syntax_err_str)),
    ("1010", 2, Ok(10UL)),
    ("1000000000000000", 2, Ok(1UL << 15)),
    (
      "1111111111111111111111111111111111111111111111111111111111111111",
      2,
      Ok(UINT64_MAX),
    ),
    (
      "1000000000000000000000000000000000000000000000000000000000000000",
      2,
      Ok(1UL << 63),
    ),
    // base 8
    ("10", 8, Ok(8UL)),
    ("57635436545", 8, Ok(0o57635436545UL)),
    ("100000000", 8, Ok(1UL << 24)),
    // base 16
    ("10", 16, Ok(16UL)),
    ("ffffffffffffffff", 16, Ok(UINT64_MAX)),
    // underscores
    ("0x_1_2_3_4_5", 0, Ok(0x12345UL)),
    ("-_0x12345", 0, Err(syntax_err_str)),
    ("_-0x12345", 0, Err(syntax_err_str)),
    ("_0x12345", 0, Err(syntax_err_str)),
    ("0x__12345", 0, Err(syntax_err_str)),
    ("0x1__2345", 0, Err(syntax_err_str)),
    ("0x1234__5", 0, Err(syntax_err_str)),
    ("0x12345_", 0, Err(syntax_err_str)),
    ("0_1_2_3_4_5", 0, Ok(12345UL)),
    ("-_012345", 0, Err(syntax_err_str)),
    ("_-012345", 0, Err(syntax_err_str)),
    ("_012345", 0, Err(syntax_err_str)),
    ("0__12345", 0, Err(syntax_err_str)),
    ("01234__5", 0, Err(syntax_err_str)),
    ("012345_", 0, Err(syntax_err_str)),
    ("0xf", 0, Ok(0xfUL)),
    ("-0xf", 0, Err(syntax_err_str)),
    ("0x+f", 0, Err(syntax_err_str)),
    ("0x-f", 0, Err(syntax_err_str)),
  ]
  for t in tests {
    @test.assert_eq(
      Result::Ok(parse_uint64(t.0, base=t.1)) catch {
        Failure::Failure(err) => Err(err)
        err => Err(err.to_string())
      },
      t.2,
    )
  }
}

///|
test "parse_uint" {
  let tests : Array[(String, Result[UInt32, String])] = [
    ("", Err(syntax_err_str)),
    ("0", Ok(0)),
    ("-0", Err(syntax_err_str)),
    ("+0", Err(syntax_err_str)),
    ("1", Ok(1)),
    ("-1", Err(syntax_err_str)),
    ("12345", Ok(12345)),
    ("012345", Ok(12345)),
    ("12345x", Err(syntax_err_str)),
    ("-12345x", Err(syntax_err_str)),
    ("987654321", Ok(987654321)),
    ("4294967295", Ok(UINT_MAX)),
    ("0xffffffff", Ok(UINT_MAX)),
    ("4294967296", Err(range_err_str)),
    ("1_2_3_4_5", Ok(12345)),
    ("-_12345", Err(syntax_err_str)),
    ("_12345", Err(syntax_err_str)),
    ("1__2345", Err(syntax_err_str)),
    ("12345_", Err(syntax_err_str)),
    ("123%45", Err(syntax_err_str)),
  ]
  for t in tests {
    @test.assert_eq(
      Result::Ok(parse_uint(t.0)) catch {
        Failure::Failure(err) => Err(err)
        err => Err(err.to_string())
      },
      t.1,
    )
  }
}

///|
test "parse_uint64 uppercase hex and invalid base" {
  @test.assert_eq(parse_uint64("ABCD", base=16), 43981)
  assert_true(
    @test.expect_error(() => parse_uint64("1234", base=37))
    is Failure("invalid base"),
  )
}
