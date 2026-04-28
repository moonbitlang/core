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
/// Error type for decimal parsing, exact conversion, and division.
pub(all) suberror DecimalError {
  InvalidSyntax(String)
  DivisionByZero
  NonTerminatingDivision
  InexactConversion
} derive(Eq, ToJson, @debug.Debug)

///|
pub impl Show for DecimalError with output(self, logger) {
  match self {
    InvalidSyntax(input) => {
      logger.write_string("InvalidSyntax(")
      Show::output(input, logger)
      logger.write_char(')')
    }
    DivisionByZero => logger.write_string("DivisionByZero")
    NonTerminatingDivision => logger.write_string("NonTerminatingDivision")
    InexactConversion => logger.write_string("InexactConversion")
  }
}

///|
/// Rounding modes used by `Decimal::round` and `Decimal::div_round`.
///
/// The names are directional to avoid the common ambiguity around "up" and
/// "down" for negative values.
pub(all) enum RoundingMode {
  TowardZero
  AwayFromZero
  TowardNegativeInfinity
  TowardPositiveInfinity
  HalfTowardZero
  HalfAwayFromZero
  HalfEven
} derive(Eq, @debug.Debug)

///|
pub impl Show for RoundingMode with output(self, logger) {
  logger.write_string(
    match self {
      TowardZero => "TowardZero"
      AwayFromZero => "AwayFromZero"
      TowardNegativeInfinity => "TowardNegativeInfinity"
      TowardPositiveInfinity => "TowardPositiveInfinity"
      HalfTowardZero => "HalfTowardZero"
      HalfAwayFromZero => "HalfAwayFromZero"
      HalfEven => "HalfEven"
    },
  )
}

///|
/// Arbitrary-precision finite decimal value.
///
/// A value is represented as `coefficient * 10^exponent`. All public
/// constructors keep the representation canonical by removing trailing decimal
/// zeros from the coefficient. Zero is always represented as `0 * 10^0`.
struct Decimal {
  coefficient : @bigint.BigInt
  exponent : Int
} derive(@debug.Debug)

///|
let zero_bigint : @bigint.BigInt = @bigint.BigInt::from_int(0)

///|
let one_bigint : @bigint.BigInt = @bigint.BigInt::from_int(1)

///|
let two_bigint : @bigint.BigInt = @bigint.BigInt::from_int(2)

///|
let five_bigint : @bigint.BigInt = @bigint.BigInt::from_int(5)

///|
let ten_bigint : @bigint.BigInt = @bigint.BigInt::from_int(10)

///|
let max_exponent64 = 2147483647L

///|
let min_exponent64 = -2147483648L

///|
fn exponent_from_int64(exponent : Int64) -> Int {
  guard exponent >= min_exponent64 && exponent <= max_exponent64 else {
    abort("Decimal exponent out of range")
  }
  exponent.to_int()
}

///|
fn add_exponents(a : Int, b : Int) -> Int {
  exponent_from_int64(a.to_int64() + b.to_int64())
}

///|
fn sub_exponents(a : Int, b : Int) -> Int {
  exponent_from_int64(a.to_int64() - b.to_int64())
}

///|
fn scale_to_exponent(scale : Int) -> Int {
  exponent_from_int64(-scale.to_int64())
}

///|
fn bigint_abs(value : @bigint.BigInt) -> @bigint.BigInt {
  if value < zero_bigint {
    -value
  } else {
    value
  }
}

///|
fn bigint_gcd(a : @bigint.BigInt, b : @bigint.BigInt) -> @bigint.BigInt {
  let mut x = bigint_abs(a)
  let mut y = bigint_abs(b)
  while !y.is_zero() {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
fn pow_bigint(base : @bigint.BigInt, exponent : Int) -> @bigint.BigInt {
  guard exponent >= 0 else { abort("negative exponent") }
  base.pow(@bigint.BigInt::from_int(exponent))
}

///|
fn pow10(exponent : Int) -> @bigint.BigInt {
  pow_bigint(ten_bigint, exponent)
}

///|
fn make_decimal(coefficient : @bigint.BigInt, exponent : Int) -> Decimal {
  if coefficient.is_zero() {
    return { coefficient: zero_bigint, exponent: 0 }
  }
  let mut coefficient = coefficient
  let mut exponent = exponent.to_int64()
  while coefficient % ten_bigint == zero_bigint {
    coefficient = coefficient / ten_bigint
    exponent += 1L
    guard exponent <= max_exponent64 else {
      abort("Decimal exponent out of range")
    }
  }
  { coefficient, exponent: exponent.to_int() }
}

///|
fn make_decimal_from_string(
  coefficient : @bigint.BigInt,
  exponent : Int64,
  input : StringView,
) -> Decimal raise DecimalError {
  guard exponent >= min_exponent64 && exponent <= max_exponent64 else {
    invalid_syntax(input)
  }
  if coefficient.is_zero() {
    return { coefficient: zero_bigint, exponent: 0 }
  }
  let mut coefficient = coefficient
  let mut exponent = exponent
  while coefficient % ten_bigint == zero_bigint {
    coefficient = coefficient / ten_bigint
    exponent += 1L
    guard exponent <= max_exponent64 else { invalid_syntax(input) }
  }
  { coefficient, exponent: exponent.to_int() }
}

///|
fn[T] invalid_syntax(input : StringView) -> T raise DecimalError {
  raise InvalidSyntax(input.to_owned())
}
