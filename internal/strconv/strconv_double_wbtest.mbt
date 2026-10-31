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
test "parse_double" {
  let tests : Array[(String, Result[Double, String])] = [
    ("", Err(syntax_err_str)),
    ("1x", Err(syntax_err_str)),
    ("1.1.", Err(syntax_err_str)),
    ("1e", Err(syntax_err_str)),
    ("1e-", Err(syntax_err_str)),
    (".e-1", Err(syntax_err_str)),
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
        range_err_str,
      ),
    ),
    (
      "-1.7976931348623159e308",
      Err(
        // overflow
        range_err_str,
      ),
    ),
    ("2e308", Err(range_err_str)),
    ("1e309", Err(range_err_str)),
    ("1e310", Err(range_err_str)),
    ("1e400", Err(range_err_str)),
    ("1e40000", Err(range_err_str)),
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
    ("-_123.5e+12", Err(syntax_err_str)),
    ("+_123.5e+12", Err(syntax_err_str)),
    ("_123.5e+12", Err(syntax_err_str)),
    ("1__23.5e+12", Err(syntax_err_str)),
    ("123_.5e+12", Err(syntax_err_str)),
    ("123._5e+12", Err(syntax_err_str)),
    ("123.5_e+12", Err(syntax_err_str)),
    ("123.5__0e+12", Err(syntax_err_str)),
    ("123.5e_+12", Err(syntax_err_str)),
    ("123.5e+_12", Err(syntax_err_str)),
    ("123.5e_-12", Err(syntax_err_str)),
    ("123.5e-_12", Err(syntax_err_str)),
    ("123.5e+1__2", Err(syntax_err_str)),
    ("123.5e+12_", Err(syntax_err_str)),
  ]
  for t in tests {
    @test.assert_eq(
      Result::Ok(parse_double(t.0)) catch {
        Failure::Failure(err) => Err(err)
        err => Err(err.to_string())
      },
      t.1,
    )
  }
}

///|
test "parse_double_inf" {
  @test.assert_eq(parse_double("inf"), @double.infinity)
  @test.assert_eq(parse_double("+Inf"), @double.infinity)
  @test.assert_eq(parse_double("-Inf"), @double.neg_infinity)
  @test.assert_eq(parse_double("+Infinity"), @double.infinity)
  @test.assert_eq(parse_double("-Infinity"), @double.neg_infinity)
  @test.assert_eq(parse_double("+INFINITY"), @double.infinity)
  @test.assert_eq(parse_double("-INFINITY"), @double.neg_infinity)
}
