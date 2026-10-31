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
priv struct FloatInfo {
  mantissa_bits : Int32
  exponent_bits : Int32
  bias : Int32
}

///|
let double_info : FloatInfo = {
  mantissa_bits: 52,
  exponent_bits: 11,
  bias: -1023,
}

///|
/// Number of explicitly stored significand bits in binary64.
let mantissa_explicit_bits = 52

///|
/// Minimum decimal exponent for the binary64 fast path.
let min_exponent_fast_path : Int64 = -22L

///|
/// Maximum decimal exponent for the binary64 fast path.
let max_exponent_fast_path : Int64 = 22L

///|
/// Maximum decimal exponent after moving digits into the binary64 mantissa.
let max_exponent_disguised_fast_path : Int64 = 37L

///|
let max_mantissa_fast_path : UInt64 = 2UL << mantissa_explicit_bits

///|
/// Parse a string into a double precision floating point number. Except for
/// the infinity and NaN spellings listed below, the string must contain at
/// least one decimal digit, in:
/// - An integer part (decimal digits), and/or
/// - A fractional part (decimal digits) after a decimal point
///
/// An optional exponent part ('e' or 'E' followed by an optional sign and
/// decimal digits) may follow those digits, but is not sufficient on its own.
///
/// The string may optionally start with a sign ('+' or '-').
/// For readability, underscores may appear between digits.
///
/// The digit-free forms "inf", "infinity" and "nan" are also accepted, in any
/// letter case and with an optional leading sign, yielding the corresponding
/// infinity or NaN value.
///
/// Examples:
/// ```mbt check
/// test {
///   inspect(@strconv.parse_double("123"), content="123")
///   inspect(@strconv.parse_double("12.34"), content="12.34")
///   inspect(@strconv.parse_double(".123"), content="0.123")
///   inspect(@strconv.parse_double("1e5"), content="100000")
///   inspect(@strconv.parse_double("1.2e-3"), content="0.0012")
///   inspect(@strconv.parse_double("1_234.5"), content="1234.5")
/// }
/// ```
///
/// An exponent value exp scales the mantissa (significand) by 10^exp.
/// For example, "1.23e2" represents 1.23 × 10² = 123.
pub fn parse_double(str : StringView) -> Double raise {
  guard !str.is_empty() else { syntax_err() }
  guard check_underscore(str) else { syntax_err() }
  // validate its a number
  match parse_number(str) {
    None => parse_inf_nan(str)
    Some(num) =>
      // Clinger's fast path (How to read floating point numbers accurately)[https://doi.org/10.1145/989393.989430]
      match num.try_fast_path() {
        Some(value) => value
        None => {
          let fast = if num.many_digits {
            @double.not_a_number
          } else {
            try_eisel_lemire64(num.mantissa, num.exponent, num.negative)
          }
          if fast.is_nan() {
            parse_decimal_priv(str).to_double_priv() // fallback to slow path
          } else {
            fast
          }
        }
      }
  }
}

///|
fn Number::is_fast_path(self : Number) -> Bool {
  min_exponent_fast_path <= self.exponent &&
  self.exponent <= max_exponent_disguised_fast_path &&
  self.mantissa <= max_mantissa_fast_path &&
  !self.many_digits
}

///|
let table : ReadOnlyArray[Double] = [
  1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0,
  1000000000.0, 10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0,
  100000000000000.0, 1000000000000000.0, 10000000000000000.0, 100000000000000000.0,
  1000000000000000000.0, 10000000000000000000.0, 100000000000000000000.0, 1000000000000000000000.0,
  10000000000000000000000.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
]

///|
fn pow10_fast_path(exponent : Int32) -> Double {
  table[exponent & 31]
}

///|
let int_pow10 : ReadOnlyArray[UInt64] = [
  1UL, 10UL, 100UL, 1000UL, 10000UL, 100000UL, 1000000UL, 10000000UL, 100000000UL,
  1000000000UL, 10000000000UL, 100000000000UL, 1000000000000UL, 10000000000000UL,
  100000000000000UL, 1000000000000000UL,
]

///|
fn Number::try_fast_path(self : Number) -> Double? {
  guard self.is_fast_path() else { return None }
  let value = if self.exponent <= max_exponent_fast_path {
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
    guard checked_mul(self.mantissa, int_pow10[shift.to_int()])
      is Some(mantissa) else {
      return None
    }
    if mantissa > max_mantissa_fast_path {
      return None
    }
    Double::convert_uint64(mantissa) *
    pow10_fast_path(max_exponent_fast_path.to_int())
  }
  Some(if self.negative { -value } else { value })
}

///|
test "parse_double_nan" {
  assert_true(parse_double("nan").is_nan())
  assert_true(parse_double("NaN").is_nan())
  assert_true(parse_double("NAN").is_nan())
}
