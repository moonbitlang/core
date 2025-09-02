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

// TODO:
// - Add a trait for `Integer` and make `Rational` generic as `Rational[T: Integer]`. Currently, the numerator and denominator are specific to `Int64` types.
// - `to_double` method needs fix. See its comment.

///|
/// Rational number type.
///
/// Invariants:
/// - The denominator is always positive.
/// - The numerator and denominator are always coprime.
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
struct T {
  numerator : Int64
  denominator : Int64
}

///|
fn gcd(a : Int64, b : Int64) -> Int64 {
  for a = a, b = b {
    if b == 0L {
      break a
    }
    continue b, a % b
  }
}

///|
/// Creates a rational number from the given numerator and denominator.
///
/// Parameters:
///
/// * `numerator` : The numerator of the rational number.
/// * `denominator` : The denominator of the rational number.
///
/// Returns `Some(rational)` if the denominator is non-zero, where the rational
/// number is automatically reduced to its simplest form with a positive
/// denominator. Returns `None` if the denominator is zero.
///
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn new(numerator : Int64, denominator : Int64) -> T? {
  if denominator == 0L {
    None
  } else {
    let sign = if (numerator < 0L && denominator < 0L) ||
      (numerator > 0L && denominator > 0L) {
      1L
    } else {
      -1L
    }
    let numerator = numerator.abs()
    let denominator = denominator.abs()
    let gcd = gcd(numerator, denominator)
    Some({ numerator: sign * numerator / gcd, denominator: denominator / gcd })
  }
}

///|
/// Creates a rational number without enforcing invariants.
fn new_unchecked(numerator : Int64, denominator : Int64) -> T {
  let gcd = gcd(numerator.abs(), denominator)
  { numerator: numerator / gcd, denominator: denominator / gcd }
}

///|
/// NOTE: we don't check overflow here, to align with the `op_add` of `Int64`.
/// TODO: add a `checked_add` method.
#coverage.skip
pub impl Add for T with add(self : T, other : T) -> T {
  new_unchecked(
    self.numerator * other.denominator + other.numerator * self.denominator,
    self.denominator * other.denominator,
  )
}

///|
/// Subtracts one rational number from another.
///
/// Parameters:
///
/// * `self` : The minuend (rational number to subtract from).
/// * `other` : The subtrahend (rational number to subtract).
///
/// Returns the difference of the two rational numbers.
///
#coverage.skip
pub impl Sub for T with sub(self : T, other : T) -> T {
  new_unchecked(
    self.numerator * other.denominator - other.numerator * self.denominator,
    self.denominator * other.denominator,
  )
}

///|
/// Multiplies two rational numbers.
///
/// Parameters:
///
/// * `self` : The first rational number.
/// * `other` : The second rational number to multiply with.
///
/// Returns the product of the two rational numbers.
///
#coverage.skip
pub impl Mul for T with mul(self : T, other : T) -> T {
  new_unchecked(
    self.numerator * other.numerator,
    self.denominator * other.denominator,
  )
}

///|
/// Divides one rational number by another.
///
/// Parameters:
///
/// * `self` : The dividend rational number.
/// * `other` : The divisor rational number.
///
/// Returns the quotient of the division as a rational number.
///
#coverage.skip
pub impl Div for T with div(self : T, other : T) -> T {
  if other.numerator < 0L {
    new_unchecked(
      self.numerator * -other.denominator,
      self.denominator * -other.numerator,
    )
  } else {
    new_unchecked(
      self.numerator * other.denominator,
      self.denominator * other.numerator,
    )
  }
}

///|
/// Returns the multiplicative inverse of a rational number.
///
/// Parameters:
///
/// * `self` : The rational number to find the reciprocal of.
///
/// Returns a new rational number that is the reciprocal of the input.
///
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn reciprocal(self : T) -> T {
  if self.numerator < 0L {
    new_unchecked(-self.denominator, -self.numerator)
  } else {
    new_unchecked(self.denominator, self.numerator)
  }
}

///|
/// Returns the negation of a rational number.
///
/// Parameters:
///
/// * `self` : The rational number to negate.
///
/// Returns a new rational number with the opposite sign.
///
#as_free_fn
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn T::neg(self : T) -> T {
  new_unchecked(-self.numerator, self.denominator)
}

///|
/// Returns the absolute value of a rational number.
///
/// Parameters:
///
/// * `self` : The rational number to get the absolute value of.
///
/// Returns a new rational number representing the absolute value of the input.
///
#as_free_fn
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn T::abs(self : T) -> T {
  new_unchecked(self.numerator.abs(), self.denominator)
}

///|
/// Compares two rational numbers for equality.
///
/// Parameters:
///
/// * `self` : The first rational number.
/// * `other` : The second rational number.
///
/// Returns `true` if the two rational numbers are equal, `false` otherwise.
///
#coverage.skip
pub impl Eq for T with equal(self : T, other : T) -> Bool {
  self.numerator * other.denominator == other.numerator * self.denominator
}

///|
/// Compares two rational numbers and returns their ordering.
///
/// Parameters:
///
/// * `self` : The first rational number to compare.
/// * `other` : The second rational number to compare.
///
/// Returns an integer indicating the relative order: negative if `self` is less
/// than `other`, zero if they are equal, and positive if `self` is greater than
/// `other`.
///
#coverage.skip
pub impl Compare for T with compare(self : T, other : T) -> Int {
  let left = self.numerator * other.denominator
  let right = other.numerator * self.denominator
  left.compare(right)
}

///|
/// Converts the rational number to its approximate double-precision
/// floating-point representation.
///
/// Parameters:
///
/// * `self` : The rational number to convert.
///
/// Returns the double-precision floating-point approximation of the rational
/// number.
///
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn to_double(self : T) -> Double {
  // TODO: complete algorithm
  self.numerator.to_double() / self.denominator.to_double()
}

///|
fn[T] nan_error() -> T raise RationalError {
  raise RationalError("Rational::from_double: cannot convert NaN")
}

///|
fn[T] overflow_error() -> T raise RationalError {
  raise RationalError("Rational::from_double: overflow")
}

///|
/// Error type for rational number operations.
///
/// Constructor:
///
/// * `RationalError(String)` : Error with a descriptive message.
///
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub(all) suberror RationalError String derive(Show, ToJson(style="flat"))

///|
/// Compares two `RationalError` values for equality.
///
/// Parameters:
///
/// * `self` : The first `RationalError` to compare.
/// * `other` : The second `RationalError` to compare.
///
/// Returns `true` if both `RationalError` values contain the same error message,
/// `false` otherwise.
///
#coverage.skip
pub impl Eq for RationalError with equal(
  self : RationalError,
  other : RationalError,
) -> Bool {
  match (self, other) {
    (RationalError(e1), RationalError(e2)) => e1 == e2
  }
}

///|
/// Converts a floating-point number to its rational representation using a
/// continued fraction algorithm.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to convert to a
/// rational.
///
/// Returns a rational number that approximates the input value.
///
/// Throws an error of type `RationalError` if the input is NaN or if the
/// conversion would result in integer overflow.
///
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn from_double(value : Double) -> T raise RationalError {
  // continued fraction algorithm
  // Ported from https://github.com/rust-num/num
  if value.is_nan() {
    nan_error()
  }
  let sign = if value < 0.0 { -1L } else { 1L }
  let value = value.abs()
  let mut q = value
  let mut n0 = 0L
  let mut d0 = 1L
  let mut n1 = 1L
  let mut d1 = 0L
  let t_max = @int64.max_value
  let t_max_f = t_max.to_double()
  let epsilon = 1.0 / t_max_f
  let max_iteration = 30
  let max_error = 10.0e-20

  // Overflow
  if q > t_max_f {
    overflow_error()
  }
  for i in 0..<max_iteration {
    if !(q >= -9223372036854775808.0 && q < 9223372036854775808.0) {
      break // overflow
    }
    let a = q.to_int64()
    let a_f = a.to_double()
    let f = q - a_f

    // Prevent overflow
    if !(a == 0L) &&
      (
        n1 > t_max / a ||
        d1 > t_max / a ||
        a * n1 > t_max - n0 ||
        a * d1 > t_max - d0
      ) {
      break
    }
    let n = a * n1 + n0
    let d = a * d1 + d0
    n0 = n1
    d0 = d1
    n1 = n
    d1 = d
    let g = gcd(n1, d1)
    if !(g == 0L) {
      n1 = n1 / g
      d1 = d1 / g
    }

    // Close enough?
    let (n_f, d_f) = (n.to_double(), d.to_double())
    if (n_f / d_f - value).abs() < max_error {
      break
    }

    // Prevent division by ~0
    if f < epsilon {
      break
    }
    q = 1.0 / f
  }
  // Overflow
  if d1 == 0L {
    overflow_error()
  }
  match new(sign * n1, d1) {
    Some(r) => r
    None => abort("Impossible to reach")
  }
}

///|
/// Returns the smallest integer greater than or equal to the rational number.
///
/// Parameters:
///
/// * `self` : The rational number to ceiling.
///
/// Returns the ceiling of the rational number as an `Int64`.
///
#as_free_fn
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn T::ceil(self : T) -> Int64 {
  let sign = if self.numerator < 0L { -1L } else { 1L }
  let quotient = self.numerator / self.denominator
  if self.numerator % self.denominator == 0L {
    quotient
  } else {
    quotient + (1L + sign) / 2L
  }
}

///|
/// Computes the largest integer that is less than or equal to the rational
/// number.
///
/// Parameters:
///
/// * `self` : The rational number to floor.
///
/// Returns the largest `Int64` value that is less than or equal to `self`.
///
#as_free_fn
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn T::floor(self : T) -> Int64 {
  let sign = if self.numerator < 0L { -1L } else { 1L }
  let quotient = self.numerator / self.denominator
  if self.numerator % self.denominator == 0L {
    quotient
  } else {
    quotient + (-1L + sign) / 2L
  }
}

///|
/// Truncates a rational number towards zero, returning the integer part.
///
/// Parameters:
///
/// * `self` : The rational number to truncate.
///
/// Returns the integer part of the rational number as an `Int64`.
///
#as_free_fn
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn T::trunc(self : T) -> Int64 {
  if self.numerator < 0L {
    -(-self.numerator / self.denominator)
  } else {
    self.numerator / self.denominator
  }
}

///|
/// Returns the fractional part of a rational number, which is the remainder
/// after removing the integer part.
///
/// Parameters:
///
/// * `self` : The rational number to get the fractional part from.
///
/// Returns a new rational number representing the fractional part of `self`.
/// This is equivalent to `self - self.trunc()`.
///
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn fract(self : T) -> T {
  new_unchecked(self.numerator % self.denominator, self.denominator)
}

///|
/// Converts a rational number to its string representation.
///
/// Parameters:
///
/// * `self` : The rational number to convert.
/// * `logger` : The output logger to write the string representation to.
///
/// The string representation follows these rules:
///
/// * If the numerator is zero, outputs "0"
/// * If the denominator is 1 (i.e., the rational is an integer), outputs just
/// the numerator
/// * Otherwise, outputs in the format "numerator/denominator"
///
#coverage.skip
pub impl Show for T with output(self, logger) {
  if self.numerator == 0L {
    logger.write_char('0')
  } else if self.denominator == 1L {
    self.numerator.output(logger)
  } else {
    self.numerator.output(logger)
    logger.write_char('/')
    self.denominator.output(logger)
  }
}

///|
#coverage.skip
pub impl @quickcheck.Arbitrary for T with arbitrary(size, rs) {
  let numerator : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
  let denominator : Int64 = {
    let d : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
    if d <= 0 {
      -d + 1
    } else {
      d
    }
  }
  new_unchecked(numerator, denominator)
}

///|
/// Checks whether the rational number represents an integer value.
///
/// Parameters:
///
/// * `self` : The rational number to check.
///
/// Returns `true` if the rational number is an integer (has a denominator of 1),
/// `false` otherwise.
///
#deprecated("Use @rational in module moonbitlang/x instead. Note that you need to rename Rational to Rational64.")
#coverage.skip
pub fn is_integer(self : T) -> Bool {
  self.denominator == 1L
}

///|
