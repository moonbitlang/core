// Copyright 2025 International Digital Economy Academy
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
priv struct FloatInfo {
  mantissa_bits : Int
  exponent_bits : Int
  bias : Int
}

///|
let double_info : FloatInfo = {
  mantissa_bits: 52,
  exponent_bits: 11,
  bias: -1023,
}

///|
/// TODO: For `f32` it is 23, but we don't have `f32` yet.
let mantissa_explicit_bits = 52

///|
/// TODO: For `f32` it is -10, but we don't have `f32` yet.
let min_exponent_fast_path : Int64 = -22L

///|
/// TODO: For `f32` it is 10, but we don't have `f32` yet.
let max_exponent_fast_path : Int64 = 22L

///|
/// TODO: For `f32` it is 17, but we don't have `f32` yet.
let max_exponent_disguised_fast_path : Int64 = 37L

///|
let max_mantissa_fast_path : UInt64 = 2UL << mantissa_explicit_bits

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
/// ```
/// inspect!(parse_double!("123"), content="123")
/// inspect!(parse_double!("12.34"), content="12.34")
/// inspect!(parse_double!(".123"), content="0.123")
/// inspect!(parse_double!("1e5"), content="100000")
/// inspect!(parse_double!("1.2e-3"), content="0.0012")
/// inspect!(parse_double!("1_234.5"), content="1234.5")
/// ```
///
/// An exponent value exp scales the mantissa (significand) by 10^exp.
/// For example, "1.23e2" represents 1.23 × 10² = 123.
pub fn parse_double(str : String) -> Double!StrConvError {
  if str.length() == 0 {
    syntax_err!()
  }
  if not(check_underscore(str)) {
    syntax_err!()
  }
  // validate its a number
  let (num, consumed) = match parse_number(str) {
    Some(r) => r
    None =>
      match parse_inf_nan(str) {
        Some((num, consumed)) =>
          if str.length() != consumed {
            syntax_err!()
          } else {
            return num
          }
        None => syntax_err!()
      }
  }
  if str.length() != consumed {
    syntax_err!()
  }
  // Clinger's fast path (How to read floating point numbers accurately)[https://doi.org/10.1145/989393.989430]
  match try_fast_path(num) {
    Some(value) => value
    None => {
      // fallback to slow path
      let ret = parse_decimal_priv!(str)
      ret.to_double_priv!()
    }
  }
}

///|
fn is_fast_path(self : Number) -> Bool {
  min_exponent_fast_path <= self.exponent &&
  self.exponent <= max_exponent_disguised_fast_path &&
  self.mantissa <= max_mantissa_fast_path &&
  not(self.many_digits)
}

///|
let table = [
  1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0,
  1000000000.0, 10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0,
  100000000000000.0, 1000000000000000.0, 10000000000000000.0, 100000000000000000.0,
  1000000000000000000.0, 10000000000000000000.0, 100000000000000000000.0, 1000000000000000000000.0,
  10000000000000000000000.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
]

///|
fn pow10_fast_path(exponent : Int) -> Double {
  table[exponent & 31]
}

///|
let int_pow10 : Array[UInt64] = [
  1UL, 10UL, 100UL, 1000UL, 10000UL, 100000UL, 1000000UL, 10000000UL, 100000000UL,
  1000000000UL, 10000000000UL, 100000000000UL, 1000000000000UL, 10000000000000UL,
  100000000000000UL, 1000000000000000UL,
]

///|
fn try_fast_path(self : Number) -> Double? {
  if self.is_fast_path() {
    let mut value = if self.exponent <= max_exponent_fast_path {
      // normal fast path
      let value = Double::convert_uint64(self.mantissa)
      if self.exponent < 0L {
        value / pow10_fast_path(-self.exponent.to_int())
      } else {
        value * pow10_fast_path(self.exponent.to_int())
      }
    } else {
      // disguised fast path
      let shift = self.exponent - max_exponent_fast_path
      let mantissa = match
        checked_mul(self.mantissa, int_pow10[shift.to_int()]) {
        Some(m) => m
        None => return None
      }
      if mantissa > max_mantissa_fast_path {
        return None
      }
      Double::convert_uint64(mantissa) *
      pow10_fast_path(max_exponent_fast_path.to_int())
    }
    if self.negative {
      value = -value
    }
    Some(value)
  } else {
    None
  }
}

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
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    assert_eq!(
      try {
        Result::Ok(parse_double!(t.0))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.1,
    )
  }
}

test "parse_double_inf" {
  assert_eq!(
    try {
      parse_double!("inf")
    } catch {
      _ => panic()
    },
    @double.infinity,
  )
  assert_eq!(
    try {
      parse_double!("+Inf")
    } catch {
      _ => panic()
    },
    @double.infinity,
  )
  assert_eq!(
    try {
      parse_double!("-Inf")
    } catch {
      _ => panic()
    },
    @double.neg_infinity,
  )
  assert_eq!(
    try {
      parse_double!("+Infinity")
    } catch {
      _ => panic()
    },
    @double.infinity,
  )
  assert_eq!(
    try {
      parse_double!("-Infinity")
    } catch {
      _ => panic()
    },
    @double.neg_infinity,
  )
  assert_eq!(
    try {
      parse_double!("+INFINITY")
    } catch {
      _ => panic()
    },
    @double.infinity,
  )
  assert_eq!(
    try {
      parse_double!("-INFINITY")
    } catch {
      _ => panic()
    },
    @double.neg_infinity,
  )
}

test "parse_double_nan" {
  let nan = try {
    parse_double!("nan")
  } catch {
    _ => panic()
  }
  assert_true!(nan.is_nan())
  let nan = try {
    parse_double!("NaN")
  } catch {
    _ => panic()
  }
  assert_true!(nan.is_nan())
  let nan = try {
    parse_double!("NAN")
  } catch {
    _ => panic()
  }
  assert_true!(nan.is_nan())
}
