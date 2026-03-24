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
/// Parse a string into a double precision floating point number. The string
/// must contain at least one of:
/// - An integer part (decimal digits)
/// - A decimal point followed by a fractional part (decimal digits)
/// - An exponent part ('e' or 'E' followed by an optional sign and decimal digits)
///
/// The string may optionally start with a sign ('+' or '-').
/// For readability, underscores may appear between digits.
///
/// Examples:
/// ```mbt check
/// test {
///   inspect(@string.parse_double("123"), content="123")
///   inspect(@string.parse_double("12.34"), content="12.34")
///   inspect(@string.parse_double(".123"), content="0.123")
///   inspect(@string.parse_double("1e5"), content="100000")
///   inspect(@string.parse_double("1.2e-3"), content="0.0012")
///   inspect(@string.parse_double("1_234.5"), content="1234.5")
/// }
/// ```
///
/// An exponent value exp scales the mantissa (significand) by 10^exp.
/// For example, "1.23e2" represents 1.23 × 10² = 123.
pub fn parse_double(str : StringView) -> Double raise {
  @internal/strconv.parse_double(str)
}

///|
test "parse_double_inf" {
  assert_eq(parse_double("inf"), @double.infinity)
  assert_eq(parse_double("+Inf"), @double.infinity)
  assert_eq(parse_double("-Inf"), @double.neg_infinity)
  assert_eq(parse_double("+Infinity"), @double.infinity)
  assert_eq(parse_double("-Infinity"), @double.neg_infinity)
  assert_eq(parse_double("+INFINITY"), @double.infinity)
  assert_eq(parse_double("-INFINITY"), @double.neg_infinity)
}

///|
test "parse_double_nan" {
  assert_true(parse_double("nan").is_nan())
  assert_true(parse_double("NaN").is_nan())
  assert_true(parse_double("NAN").is_nan())
}
