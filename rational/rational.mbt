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
/// Creates a rational number.
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
  let gcd = gcd(numerator.abs(), denominator).abs()
  { numerator: numerator / gcd, denominator: denominator / gcd }
}

///|
/// NOTE: we don't check overflow here, to align with the `op_add` of `Int64`.
/// TODO: add a `checked_add` method.
pub impl Add for T with op_add(self : T, other : T) -> T {
  new_unchecked(
    self.numerator * other.denominator + other.numerator * self.denominator,
    self.denominator * other.denominator,
  )
}

///|
pub impl Sub for T with op_sub(self : T, other : T) -> T {
  new_unchecked(
    self.numerator * other.denominator - other.numerator * self.denominator,
    self.denominator * other.denominator,
  )
}

///|
pub impl Mul for T with op_mul(self : T, other : T) -> T {
  new_unchecked(
    self.numerator * other.numerator,
    self.denominator * other.denominator,
  )
}

///|
pub impl Div for T with op_div(self : T, other : T) -> T {
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
/// Returns the reciprocal of a rational number.
pub fn reciprocal(self : T) -> T {
  if self.numerator < 0L {
    new_unchecked(-self.denominator, -self.numerator)
  } else {
    new_unchecked(self.denominator, self.numerator)
  }
}

///|
/// Returns the negation of a rational number.
pub fn neg(self : T) -> T {
  new_unchecked(-self.numerator, self.denominator)
}

///|
/// Returns the absolute value of a rational number.
pub fn abs(self : T) -> T {
  new_unchecked(self.numerator.abs(), self.denominator.abs())
}

///|
/// Equal to operator for rational numbers.
pub impl Eq for T with op_equal(self : T, other : T) -> Bool {
  self.numerator * other.denominator == other.numerator * self.denominator
}

///|
/// Compares two rational numbers.
pub impl Compare for T with compare(self : T, other : T) -> Int {
  let left = self.numerator * other.denominator
  let right = other.numerator * self.denominator
  left.compare(right)
}

///|
/// Returns the approximate double value of a rational number.
pub fn to_double(self : T) -> Double {
  // TODO: complete algorithm
  self.numerator.to_double() / self.denominator.to_double()
}

///|
fn nan_error[T]() -> T!RationalError {
  raise RationalError("Rational::from_double: cannot convert NaN")
}

///|
fn overflow_error[T]() -> T!RationalError {
  raise RationalError("Rational::from_double: overflow")
}

///|
pub(all) type! RationalError String

///|
pub impl Show for RationalError with output(self, logger) {
  match self {
    RationalError(e) => Show::output(e, logger)
  }
}

///|
pub impl Eq for RationalError with op_equal(
  self : RationalError,
  other : RationalError
) -> Bool {
  match (self, other) {
    (RationalError(e1), RationalError(e2)) => e1 == e2
  }
}

///|
/// Returns the approximate rational value of a double.
pub fn from_double(value : Double) -> T!RationalError {
  // continued fraction algorithm
  // Ported from https://github.com/rust-num/num
  if value.is_nan() {
    nan_error!()
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
    overflow_error!()
  }
  for i in 0..<max_iteration {
    if not(q >= -9223372036854775808.0 && q < 9223372036854775808.0) {
      break // overflow
    }
    let a = q.to_int64()
    let a_f = a.to_double()
    let f = q - a_f

    // Prevent overflow
    if not(a == 0L) &&
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
    if not(g == 0L) {
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
    overflow_error!()
  }
  match new(sign * n1, d1) {
    Some(r) => r
    None => abort("Impossible to reach")
  }
}

///|
/// Ceils a rational number towards positive infinity.
pub fn ceil(self : T) -> Int64 {
  let sign = if self.numerator < 0L { -1L } else { 1L }
  let quotient = self.numerator / self.denominator
  if self.numerator % self.denominator == 0L {
    quotient
  } else {
    quotient + (1L + sign) / 2L
  }
}

///|
/// Floors a rational number towards negative infinity.
pub fn floor(self : T) -> Int64 {
  let sign = if self.numerator < 0L { -1L } else { 1L }
  let quotient = self.numerator / self.denominator
  if self.numerator % self.denominator == 0L {
    quotient
  } else {
    quotient + (-1L + sign) / 2L
  }
}

///|
/// Rounds a rational number towards zero.
pub fn trunc(self : T) -> Int64 {
  if self.numerator < 0L {
    -(-self.numerator / self.denominator)
  } else {
    self.numerator / self.denominator
  }
}

///|
/// Fractional part of a rational number.
/// Same as `self - self.trunc()`.
pub fn fract(self : T) -> T {
  new_unchecked(self.numerator % self.denominator, self.denominator)
}

///|
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
pub impl @quickcheck.Arbitrary for T with arbitrary(size, rs) {
  let numerator : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
  let denominator : Int64 = {
    let d : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
    if d == 0 {
      1
    } else {
      d
    }
  }
  new_unchecked(numerator, denominator)
}

///|
pub fn is_integer(self : T) -> Bool {
  self.denominator == 1L
}

///|
test "op_add" {
  // 1/2 + 1/3 = 5/6
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(1L, 3L)
  let c = a + b
  assert_eq!(c.numerator, 5L)
  assert_eq!(c.denominator, 6L)

  // 1/2 + 1/2 = 1
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(1L, 2L)
  let c = a + b
  assert_eq!(c.numerator, 1L)
  assert_eq!(c.denominator, 1L)

  // 1/2 + 1/6 = 2/3
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(1L, 6L)
  let c = a + b
  assert_eq!(c.numerator, 2L)

  // -1/2 + 1/2 = 0
  let a = new_unchecked(-1L, 2L)
  let b = new_unchecked(1L, 2L)
  let c = a + b
  assert_eq!(c.numerator, 0L)

  // -1/2 + -1/2 = -1
  let a = new_unchecked(-1L, 2L)
  let b = new_unchecked(-1L, 2L)
  let c = a + b
  assert_eq!(c.numerator, -1L)
  assert_eq!(c.denominator, 1L)
}

///|
test "op_sub" {
  // 1/2 - 1/3 = 1/6
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(1L, 3L)
  let c = a - b
  assert_eq!(c.numerator, 1L)
  assert_eq!(c.denominator, 6L)

  // 1/2 - 1/2 = 0
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(1L, 2L)
  let c = a - b
  assert_eq!(c.numerator, 0L)

  // 1/2 - 1/6 = 1/3
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(1L, 6L)
  let c = a - b
  assert_eq!(c.numerator, 1L)
  assert_eq!(c.denominator, 3L)

  // -1/2 - 1/2 = -1
  let a = new_unchecked(-1L, 2L)
  let b = new_unchecked(1L, 2L)
  let c = a - b
  assert_eq!(c.numerator, -1L)
  assert_eq!(c.denominator, 1L)

  // -1/2 - -1/2 = 0
  let a = new_unchecked(-1L, 2L)
  let b = new_unchecked(-1L, 2L)
  let c = a - b
  assert_eq!(c.numerator, 0L)
}

///|
test "op_mul" {
  // 1/2 * 2/3 = 1/3
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(2L, 3L)
  let c = a * b
  assert_eq!(c.numerator, 1L)
  assert_eq!(c.denominator, 3L)

  // -4/3 * 3/4 = -1
  let a = new_unchecked(-4L, 3L)
  let b = new_unchecked(3L, 4L)
  let c = a * b
  assert_eq!(c.numerator, -1L)
  assert_eq!(c.denominator, 1L)

  // 1024/42 * 0 = 0
  let a = new_unchecked(1024L, 42L)
  let b = new_unchecked(0L, 1L)
  let c = a * b
  assert_eq!(c.numerator, 0L)
  assert_eq!(c.denominator, 1L)
}

///|
test "op_div" {
  // 1/2 / 2/3 = 3/4
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(2L, 3L)
  let c = a / b
  assert_eq!(c.numerator, 3L)
  assert_eq!(c.denominator, 4L)

  // 1/2 / -2/3 = -3/4
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(-2L, 3L)
  let c = a / b
  assert_eq!(c.numerator, -3L)
  assert_eq!(c.denominator, 4L)

  // 0 / 1 = 0
  let a = new_unchecked(0L, 1L)
  let b = new_unchecked(1L, 1L)
  let c = a / b
  assert_eq!(c.numerator, 0L)
  assert_eq!(c.denominator, 1L)
}

///|
test "reciprocal" {
  // 1/2 -> 2/1
  let a = new_unchecked(1L, 2L)
  let b = reciprocal(a)
  assert_eq!(b.numerator, 2L)
  assert_eq!(b.denominator, 1L)

  // -1/2 -> -2/1
  let a = new_unchecked(-1L, 2L)
  let b = reciprocal(a)
  assert_eq!(b.numerator, -2L)
  assert_eq!(b.denominator, 1L)
}

///|
test "neg" {
  // 1/2 -> -1/2
  let a = new_unchecked(1L, 2L)
  let b = neg(a)
  assert_eq!(b.numerator, -1L)
  assert_eq!(b.denominator, 2L)

  // -1/2 -> 1/2
  let a = new_unchecked(-1L, 2L)
  let b = neg(a)
  assert_eq!(b.numerator, 1L)
  assert_eq!(b.denominator, 2L)
}

///|
test "abs" {
  // 1/2 -> 1/2
  let a = new_unchecked(1L, 2L)
  let b = abs(a)
  assert_eq!(b.numerator, 1L)
  assert_eq!(b.denominator, 2L)

  // -1/2 -> 1/2
  let a = new_unchecked(-1L, 2L)
  let b = abs(a)
  assert_eq!(b.numerator, 1L)
  assert_eq!(b.denominator, 2L)
}

///|
test "to_double" {
  // 1/2 -> 0.5
  let a = new_unchecked(1L, 2L)
  let b = a.to_double()
  assert_eq!(b, 0.5)

  // -1/2 -> -0.5
  let a = new_unchecked(-1L, 2L)
  let b = a.to_double()
  assert_eq!(b, -0.5)
}

///|
test "ceil" {
  // 1/2 -> 1
  let a = new_unchecked(1L, 2L)
  let b = ceil(a)
  assert_eq!(b, 1L)

  // -1/2 -> 0
  let a = new_unchecked(-1L, 2L)
  let b = ceil(a)
  assert_eq!(b, 0L)

  // -2/2 -> -1
  let a = new_unchecked(-2L, 2L)
  let b = ceil(a)
  assert_eq!(b, -1L)

  // 2/2 -> 1
  let a = new_unchecked(2L, 2L)
  let b = ceil(a)
  assert_eq!(b, 1L)
}

///|
test "floor" {
  // 1/2 -> 0
  let a = new_unchecked(1L, 2L)
  let b = floor(a)
  assert_eq!(b, 0L)

  // -1/2 -> -1
  let a = new_unchecked(-1L, 2L)
  let b = floor(a)
  assert_eq!(b, -1L)

  // -2/2 -> -1
  let a = new_unchecked(-2L, 2L)
  let b = floor(a)
  assert_eq!(b, -1L)

  // 2/2 -> 1
  let a = new_unchecked(2L, 2L)
  let b = floor(a)
  assert_eq!(b, 1L)
}

///|
test "trunc" {
  // 1/2 -> 0
  let a = new_unchecked(1L, 2L)
  let b = trunc(a)
  assert_eq!(b, 0L)

  // -1/2 -> 0
  let a = new_unchecked(-1L, 2L)
  let b = trunc(a)
  assert_eq!(b, 0L)
}

///|
test "fract" {
  // 1/2 -> 1/2
  let a = new_unchecked(1L, 2L)
  let b = fract(a)
  assert_eq!(b.numerator, 1L)
  assert_eq!(b.denominator, 2L)

  // -1/2 -> -1/2
  let a = new_unchecked(-1L, 2L)
  let b = fract(a)
  assert_eq!(b.numerator, -1L)
  assert_eq!(b.denominator, 2L)

  // 3/2 -> 1/2
  let a = new_unchecked(3L, 2L)
  let b = fract(a)
  assert_eq!(b.numerator, 1L)
  assert_eq!(b.denominator, 2L)

  // -3/2 -> -1/2
  let a = new_unchecked(-3L, 2L)
  let b = fract(a)
  assert_eq!(b.numerator, -1L)
  assert_eq!(b.denominator, 2L)
}

///|
test "to_string" {
  // 1/2 -> "1/2"
  let a = new_unchecked(1L, 2L)
  let b = a.to_string()
  assert_eq!(b, "1/2")

  // 4/4 -> "1"
  let a = new_unchecked(4L, 4L)
  let b = a.to_string()
  assert_eq!(b, "1")

  // 0/1 -> "0"
  let a = new_unchecked(0L, 1L)
  let b = a.to_string()
  assert_eq!(b, "0")
}

///|
test "is_integer" {
  // 1/2 is not an integer
  let a = new_unchecked(1L, 2L)
  assert_false!(a.is_integer())

  // 1 is an integer
  let a = new_unchecked(1L, 1L)
  assert_true!(a.is_integer())

  // 0 is an integer
  let a = new_unchecked(0L, 1L)
  assert_true!(a.is_integer())

  // -1 is an integer
  let a = new_unchecked(-1L, 1L)
  assert_true!(a.is_integer())
}

///|
test "compare" {
  // 1/2 < 2/3
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(2L, 3L)
  assert_eq!(a.compare(b), -1)
  assert_true!(a < b)
  assert_true!(a <= b)
  assert_true!(a != b)

  // -1/2 > -2/3
  let a = new_unchecked(-1L, 2L)
  let b = new_unchecked(-2L, 3L)
  assert_eq!(a.compare(b), 1)
  assert_true!(a > b)
  assert_true!(a >= b)
  assert_true!(a != b)

  // 1/2 == 1/2
  let a = new_unchecked(1L, 2L)
  let b = new_unchecked(1L, 2L)
  assert_eq!(a.compare(b), 0)
  assert_true!(a == b)
}

///|
test "from_double normal case" {
  let result = 0.5 |> @result.wrap1(f=from_double)
  assert_eq!(result, Ok(new_unchecked(1L, 2L)))
}

///|
test "from_double edge case" {
  let result = 9_223_372_036_800_000_000.0 |> @result.wrap1(f=from_double)
  assert_eq!(result, Ok(new_unchecked(9_223_372_036_800_000_000L, 1L)))
}

///|
test "from_double normal case" {
  let result = 0.5 |> @result.wrap1(f=from_double)
  assert_eq!(result, Ok(new_unchecked(1L, 2L)))
}

///|
test "from_double edge case" {
  let result = 9_223_372_036_800_000_000.0 |> @result.wrap1(f=from_double)
  assert_eq!(result, Ok(new_unchecked(9_223_372_036_800_000_000L, 1L)))
}
