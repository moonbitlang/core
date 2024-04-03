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

priv struct FloatInfo {
  mantissa_bits : Int
  exponent_bits : Int
  bias : Int
}

let double_info : FloatInfo = {
  mantissa_bits: 52,
  exponent_bits: 11,
  bias: -1023,
}

/// Convert a string to a 64 bit floating point number.
pub fn parse_double(str : String) -> Result[Double, String] {
  match special_value(str) {
    Some(v) => return Ok(v)
    _ => ()
  }
  if not(check_underscore(str)) {
    return Err(syntax_err)
  }
  let hpd = parse_decimal(str)?
  hpd.to_double()
}

/// Parse the special floating point value.
fn special_value(str : String) -> Option[Double] {
  if str.length() == 0 {
    return None
  }
  let mut s = str
  // check sign
  let mut sign = 1
  if s[0] == '+' || s[0] == '-' {
    if s[0] == '-' {
      sign = -1
    }
    s = substring(s, 1, s.length() - 1)
  }
  if eq_ignore_case(s, "inf") || eq_ignore_case(s, "infinity") {
    Some(Double::inf(sign))
  } else if eq_ignore_case(s, "nan") {
    Some(Double::nan())
  } else {
    None
  }
}

fn eq_ignore_case(s1 : String, s2 : String) -> Bool {
  if s1.length() != s2.length() {
    return false
  }
  for i = 0; i < s1.length(); i = i + 1 {
    let c1 = s1[i]
    let c2 = s2[i]
    if lower(c1) != lower(c2) {
      return false
    }
  }
  true
}

fn lower(c : Char) -> Char {
  if 'A' <= c && c <= 'Z' {
    Char::from_int(c.to_int() + 'a'.to_int() - 'A'.to_int())
  } else {
    c
  }
}

test "parse_double" {
  let tests : Array[(String, Result[Double, String])] = [
    ("", Err(syntax_err)),
    ("1x", Err(syntax_err)),
    ("1.1.", Err(syntax_err)),
    ("1e", Err(syntax_err)),
    ("1e-", Err(syntax_err)),
    (".e-1", Err(syntax_err)),
    ("1", Ok(1.0)),
    ("+1", Ok(1.0)),
    ("1e23", Ok(1.0e23)),
    ("1E23", Ok(1.0e23)),
    ("100000000000000000000000", Ok(1.0e23)),
    ("1e-100", Ok(1.0e-100)),
    ("123456700", Ok(1.234567e+08)),
    ("99999999999999974834176", Ok(9.999999999999997e+22)),
    ("100000000000000000000001", Ok(1.0000000000000001e+23)),
    ("100000000000000008388608", Ok(1.0000000000000001e+23)),
    ("100000000000000016777215", Ok(1.0000000000000001e+23)),
    ("100000000000000016777216", Ok(1.0000000000000003e+23)),
    ("-1", Ok(-1.0)),
    ("-0.1", Ok(-0.1)),
    ("-0", Ok(-0.0)),
    ("1e-20", Ok(1.0e-20)),
    ("625e-3", Ok(0.625)),
    ("6.62607015e-34", Ok(6.62607015e-34)),
    ("2.2250738585072012e-308", Ok(2.2250738585072014e-308)),
    ("2.2250738585072011e-308", Ok(2.225073858507201e-308)),
    ("0", Ok(0.0)),
    ("0e0", Ok(0.0)),
    ("-0e0", Ok(-0.0)),
    ("+0e0", Ok(0.0)),
    ("0e-0", Ok(0.0)),
    ("-0e-0", Ok(-0.0)),
    ("+0e-0", Ok(0.0)),
    ("0e+0", Ok(0.0)),
    ("-0e+0", Ok(-0.0)),
    ("+0e+0", Ok(0.0)),
    ("0e+01234567890123456789", Ok(0.0)),
    ("0.00e-01234567890123456789", Ok(0.0)),
    ("-0e+01234567890123456789", Ok(-0.0)),
    ("-0.00e-01234567890123456789", Ok(-0.0)),
    ("0e292", Ok(0.0)),
    ("0e347", Ok(0.0)),
    ("0e348", Ok(0.0)),
    ("-0e291", Ok(-0.0)),
    ("-0e292", Ok(-0.0)),
    ("-0e347", Ok(-0.0)),
    ("-0e348", Ok(-0.0)),
    ("1.7976931348623157e308", Ok(1.7976931348623157e308)),
    ("-1.7976931348623157e308", Ok(-1.7976931348623157e308)),
    ("1.7976931348623158e308", Ok(1.7976931348623157e308)),
    ("-1.7976931348623158e308", Ok(-1.7976931348623157e308)),
    ("1e308", Ok(1.0e308)),
    (
      "1.7976931348623159e308",
      Err(
        // zeros
        // large double
        range_err,
      ),
    ),
    // overflow
    ("-1.7976931348623159e308", Err(range_err)),
    ("2e308", Err(range_err)),
    ("1e309", Err(range_err)),
    ("1e310", Err(range_err)),
    ("1e400", Err(range_err)),
    ("1e40000", Err(range_err)),
    // denormalized
    ("1e-305", Ok(1.0e-305)),
    ("1e-306", Ok(1.0e-306)),
    ("1e-307", Ok(1.0e-307)),
    ("1e-308", Ok(1.0e-308)),
    ("1e-309", Ok(1.0e-309)),
    ("1e-310", Ok(1.0e-310)),
    ("1e-322", Ok(1.0e-322)),
    // smallest denormal
    ("5e-324", Ok(5.0e-324)),
    ("4e-324", Ok(5.0e-324)),
    ("3e-324", Ok(5.0e-324)),
    // underflow
    ("2e-324", Ok(0.0)),
    ("1e-350", Ok(0.0)),
    ("1e-400000", Ok(0.0)),
    // underscores
    ("1_23.50_0_0e+1_2", Ok(1.235e+14)),
    ("-_123.5e+12", Err(syntax_err)),
    ("+_123.5e+12", Err(syntax_err)),
    ("_123.5e+12", Err(syntax_err)),
    ("1__23.5e+12", Err(syntax_err)),
    ("123_.5e+12", Err(syntax_err)),
    ("123._5e+12", Err(syntax_err)),
    ("123.5_e+12", Err(syntax_err)),
    ("123.5__0e+12", Err(syntax_err)),
    ("123.5e_+12", Err(syntax_err)),
    ("123.5e+_12", Err(syntax_err)),
    ("123.5e_-12", Err(syntax_err)),
    ("123.5e-_12", Err(syntax_err)),
    ("123.5e+1__2", Err(syntax_err)),
    ("123.5e+12_", Err(syntax_err)),
  ]
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    @assertion.assert_eq(parse_double(t.0), t.1)?
  }
}

test "parse_double_inf" {
  @assertion.assert_eq(parse_double("inf"), Ok(Double::inf(1)))?
  @assertion.assert_eq(parse_double("+Inf"), Ok(Double::inf(1)))?
  @assertion.assert_eq(parse_double("-Inf"), Ok(Double::inf(-1)))?
  @assertion.assert_eq(parse_double("+Infinity"), Ok(Double::inf(1)))?
  @assertion.assert_eq(parse_double("-Infinity"), Ok(Double::inf(-1)))?
  @assertion.assert_eq(parse_double("+INFINITY"), Ok(Double::inf(1)))?
  @assertion.assert_eq(parse_double("-INFINITY"), Ok(Double::inf(-1)))?
}

test "parse_double_nan" {
  @assertion.assert_true(parse_double("nan")?.is_nan())?
  @assertion.assert_true(parse_double("NaN")?.is_nan())?
  @assertion.assert_true(parse_double("NAN")?.is_nan())?
}

test "lower" {
  @assertion.assert_eq(lower('Z'), 'z')?
  @assertion.assert_eq(lower('A'), 'a')?
  @assertion.assert_eq(lower('a'), 'a')?
  @assertion.assert_eq(lower('z'), 'z')?
}

test "eq_ignore_case" {
  @assertion.assert_true(eq_ignore_case("nan", "NaN"))?
  @assertion.assert_true(eq_ignore_case("inf", "inf"))?
  @assertion.assert_true(eq_ignore_case("inf", "Inf"))?
}
