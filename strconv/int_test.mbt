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
let syntax_err = "invalid syntax"

///|
let range_err = "value out of range"

///|
let base_err = "invalid base"

///|
fn parse_int64_as_result(s : String, base? : Int = 0) -> Result[Int64, String] {
  try @strconv.parse_int64(s, base~) |> Ok catch {
    StrConvError(err) => Err(err)
  }
}

///|
fn parse_int_as_result(s : String, base? : Int = 0) -> Result[Int, String] {
  try @strconv.parse_int(s, base~) |> Ok catch {
    StrConvError(err) => Err(err)
  }
}

///|
test "parse_int64" {
  let tests : Array[(String, Int, Result[Int64, String])] = [
    // basic cases
    ("", 0, Err(syntax_err)),
    ("0", 0, Ok(0L)),
    ("-0", 0, Ok(0L)),
    ("+0", 0, Ok(0L)),
    ("1", 0, Ok(1L)),
    ("-1", 0, Ok(-1L)),
    ("+1", 0, Ok(1L)),
    ("12345", 0, Ok(12345L)),
    ("-12345", 0, Ok(-12345L)),
    ("012345", 0, Ok(12345L)),
    ("-012345", 0, Ok(-12345L)),
    ("0x12345", 0, Ok(0x12345L)),
    ("-0x12345", 0, Ok(-0x12345L)),
    ("9876543210", 0, Ok(9876543210L)),
    ("-9876543210", 0, Ok(-9876543210L)),
    // boundary values
    ("9223372036854775807", 0, Ok(9223372036854775807L)),
    ("-9223372036854775807", 0, Ok(-9223372036854775807L)),
    ("9223372036854775808", 0, Err(range_err)),
    ("-9223372036854775808", 0, Ok(-9223372036854775808L)),
    ("9223372036854775809", 0, Err(range_err)),
    ("-9223372036854775809", 0, Err(range_err)),
    ("922_3372_0368_5477_5807", 0, Ok(9223372036854775807L)),
    // invalid syntax
    ("12345x", 0, Err(syntax_err)),
    ("-12345x", 0, Err(syntax_err)),
    ("12345%", 0, Err(syntax_err)),
    (" 1", 0, Err(syntax_err)),
    ("1 ", 0, Err(syntax_err)),
    // sign only
    ("+", 0, Err(syntax_err)),
    ("-", 0, Err(syntax_err)),
    // underscore handling
    ("-1_2_3_4_5", 0, Ok(-12345L)),
    ("-_12345", 0, Err(syntax_err)),
    ("_12345", 0, Err(syntax_err)),
    ("1__2345", 0, Err(syntax_err)),
    ("12345_", 0, Err(syntax_err)),
    ("_", 0, Err(syntax_err)),
    ("+_", 0, Err(syntax_err)),
    ("-_", 0, Err(syntax_err)),
    ("-0_1_2_3_4_5", 0, Ok(-12345L)),
    ("0_1_2_3_4_5", 0, Ok(12345L)),
    ("-_012345", 0, Err(syntax_err)),
    ("_-012345", 0, Err(syntax_err)),
    ("_012345", 0, Err(syntax_err)),
    ("0__12345", 0, Err(syntax_err)),
    ("01234__5", 0, Err(syntax_err)),
    ("012345_", 0, Err(syntax_err)),
    // other bases
    ("h", 18, Ok(17L)),
    ("10", 25, Ok(25L)),
    (
      "moonbit",
      35,
      Ok(
        (
          ((((22L * 35L + 24L) * 35L + 24L) * 35L + 23L) * 35L + 11L) * 35L +
          18L
        ) *
        35L +
        29L,
      ),
    ),
    (
      "moonbit",
      36,
      Ok(
        (
          ((((22L * 36L + 24L) * 36L + 24L) * 36L + 23L) * 36L + 11L) * 36L +
          18L
        ) *
        36L +
        29L,
      ),
    ),
    ("a", 11, Ok(10L)),
    ("b", 11, Err(syntax_err)),
    ("y", 35, Ok(34L)),
    ("z", 35, Err(syntax_err)),
    ("Y", 35, Ok(34L)),
    ("Z", 35, Err(syntax_err)),
    ("z", 36, Ok(35L)),
    // base 2
    ("0", 2, Ok(0L)),
    ("-1", 2, Ok(-1L)),
    ("1010", 2, Ok(10L)),
    ("1000000000000000", 2, Ok(1L << 15)),
    (
      "111111111111111111111111111111111111111111111111111111111111111",
      2,
      Ok((1L << 63) - 1L),
    ),
    (
      "1000000000000000000000000000000000000000000000000000000000000000",
      2,
      Err(range_err),
    ),
    (
      "-1000000000000000000000000000000000000000000000000000000000000000",
      2,
      Ok(-1L << 63),
    ),
    (
      "-1000000000000000000000000000000000000000000000000000000000000001",
      2,
      Err(range_err),
    ),
    // base 8
    ("-10", 8, Ok(-8L)),
    ("57635436545", 8, Ok(0o57635436545L)),
    ("100000000", 8, Ok(1L << 24)),
    ("777", 8, Ok(511L)),
    // base 16
    ("10", 16, Ok(16L)),
    ("-123456789abcdef", 16, Ok(-0x123456789abcdefL)),
    ("7fffffffffffffff", 16, Ok((1L << 63) - 1L)),
    ("ff", 16, Ok(255L)),
    ("A", 16, Ok(10L)),
    ("a", 16, Ok(10L)),
    ("Z", 36, Ok(35L)),
    ("z", 36, Ok(35L)),
    ("G", 16, Err(syntax_err)),
    ("g", 16, Err(syntax_err)),
    ("@", 16, Err(syntax_err)),
    ("`", 16, Err(syntax_err)),
    ("[", 16, Err(syntax_err)),
    ("{", 16, Err(syntax_err)),
    // hex prefix
    ("0x", 0, Err(syntax_err)),
    ("0x_", 0, Err(syntax_err)),
    ("0x_DEADBEEF", 0, Ok(3735928559L)),
    ("-0x_1_2_3_4_5", 0, Ok(-0x12345L)),
    ("0x_1_2_3_4_5", 0, Ok(0x12345L)),
    ("-_0x12345", 0, Err(syntax_err)),
    ("_-0x12345", 0, Err(syntax_err)),
    ("_0x12345", 0, Err(syntax_err)),
    ("0x__12345", 0, Err(syntax_err)),
    ("0x1__2345", 0, Err(syntax_err)),
    ("0x1234__5", 0, Err(syntax_err)),
    ("0x12345_", 0, Err(syntax_err)),
    ("+0xf", 0, Ok(0xfL)),
    ("-0xf", 0, Ok(-0xfL)),
    ("0x+f", 0, Err(syntax_err)),
    ("0x-f", 0, Err(syntax_err)),
    ("0xFF", 0, Ok(255L)),
    ("0Xff", 0, Ok(255L)),
    ("0x_FF", 0, Ok(255L)),
    ("+0x_FF", 0, Ok(255L)),
    ("-0x_FF", 0, Ok(-255L)),
    ("+0x", 0, Err(syntax_err)),
    ("-0x", 0, Err(syntax_err)),
    ("+0x_", 0, Err(syntax_err)),
    ("0x10", 16, Ok(16L)),
    ("0x_10", 16, Ok(16L)),
    ("0x10", 8, Err(syntax_err)),
    // binary prefix
    ("0b1010", 0, Ok(10L)),
    ("0B1010", 0, Ok(10L)),
    ("0b_1010", 0, Ok(10L)),
    ("0b_1_0_1_0", 0, Ok(10L)),
    ("+0b", 0, Err(syntax_err)),
    ("-0b", 0, Err(syntax_err)),
    ("0b_", 0, Err(syntax_err)),
    ("-0b_", 0, Err(syntax_err)),
    ("0b1010", 2, Ok(10L)),
    ("0b_1010", 2, Ok(10L)),
    ("0b1010", 10, Err(syntax_err)),
    ("0b01", 16, Ok(2817L)),
    // octal prefix
    ("0o777", 0, Ok(511L)),
    ("0O77", 0, Ok(63L)),
    ("0o_77", 0, Ok(63L)),
    ("0o_7_7", 0, Ok(63L)),
    ("+0o", 0, Err(syntax_err)),
    ("-0o", 0, Err(syntax_err)),
    ("0o_", 0, Err(syntax_err)),
    ("+0o_", 0, Err(syntax_err)),
    ("0o77", 8, Ok(63L)),
    ("0o_77", 8, Ok(63L)),
    ("0o77", 16, Err(syntax_err)),
    ("0o01", 16, Err(syntax_err)),
    ("0o01", 10, Err(syntax_err)),
    ("0x01", 10, Err(syntax_err)),
    // invalid base
    ("12345", 1, Err(base_err)),
    ("12345", 37, Err(base_err)),
    ("12345", -1, Err(base_err)),
    ("12345", 100, Err(base_err)),
  ]
  for t in tests {
    assert_eq(parse_int64_as_result(t.0, base=t.1), t.2)
  }
}

///|
test "parse_int" {
  let tests : Array[(String, Result[Int, String])] = [
    ("", Err(syntax_err)),
    ("0", Ok(0)),
    ("-0", Ok(0)),
    ("1", Ok(1)),
    ("-1", Ok(-1)),
    ("12345", Ok(12345)),
    ("-12345", Ok(-12345)),
    ("012345", Ok(12345)),
    ("-012345", Ok(-12345)),
    ("12345x", Err(syntax_err)),
    ("-12345x", Err(syntax_err)),
    ("987654321", Ok(987654321)),
    ("-987654321", Ok(-987654321)),
    ("2147483647", Ok((1 << 31) - 1)),
    ("-2147483647", Ok(-((1 << 31) - 1))),
    ("2147483648", Err(range_err)),
    ("-2147483648", Ok(-1 << 31)),
    ("2147483649", Err(range_err)),
    ("-2147483649", Err(range_err)),
    ("-1_2_3_4_5", Ok(-12345)),
    ("-_12345", Err(syntax_err)),
    ("_12345", Err(syntax_err)),
    ("1__2345", Err(syntax_err)),
    ("12345_", Err(syntax_err)),
    ("123%45", Err(syntax_err)),
  ]
  for t in tests {
    assert_eq(parse_int_as_result(t.0), t.1)
  }
}
