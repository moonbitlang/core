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

/// Rational number type.
/// 
/// Invariants:
/// - The denominator is always positive.
/// - The numerator and denominator are always coprime.
struct Rational {
  numerator : Int64
  denominator : Int64
} derive(Debug)

fn gcd(a : Int64, b : Int64) -> Int64 {
  for a = a, b = b {
    if b == 0L {
      break a
    }
    continue b, a % b
  }
}

/// Creates a rational number.
pub fn Rational::new(numerator : Int64, denominator : Int64) -> Rational? {
  if denominator == 0L {
    None
  } else {
    let sign = if (numerator < 0L && denominator < 0L) || (numerator > 0L && denominator >
    0L) {
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

/// Creates a rational number without enforcing invariants.
fn Rational::new_unchecked(numerator : Int64, denominator : Int64) -> Rational {
  let gcd = gcd(numerator.abs(), denominator).abs()
  { numerator: numerator / gcd, denominator: denominator / gcd }
}

/// NOTE: we don't check overflow here, to align with the `op_add` of `Int64`.
/// TODO: add a `checked_add` method.
pub fn op_add(self : Rational, other : Rational) -> Rational {
  new_unchecked(
    self.numerator * other.denominator + other.numerator * self.denominator,
    self.denominator * other.denominator,
  )
}

pub fn op_sub(self : Rational, other : Rational) -> Rational {
  new_unchecked(
    self.numerator * other.denominator - other.numerator * self.denominator,
    self.denominator * other.denominator,
  )
}

pub fn op_mul(self : Rational, other : Rational) -> Rational {
  new_unchecked(
    self.numerator * other.numerator,
    self.denominator * other.denominator,
  )
}

pub fn op_div(self : Rational, other : Rational) -> Rational {
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

/// Returns the reciprocal of a rational number.
pub fn reciprocal(self : Rational) -> Rational {
  if self.numerator < 0L {
    new_unchecked(-self.denominator, -self.numerator)
  } else {
    new_unchecked(self.denominator, self.numerator)
  }
}

/// Returns the negation of a rational number.
pub fn neg(self : Rational) -> Rational {
  new_unchecked(-self.numerator, self.denominator)
}

/// Returns the absolute value of a rational number.
pub fn abs(self : Rational) -> Rational {
  new_unchecked(self.numerator.abs(), self.denominator.abs())
}

/// Equal to operator for rational numbers.
pub fn op_equal(self : Rational, other : Rational) -> Bool {
  self.numerator * other.denominator == other.numerator * self.denominator
}

/// Compares two rational numbers.
pub fn compare(self : Rational, other : Rational) -> Int {
  let left = self.numerator * other.denominator
  let right = other.numerator * self.denominator
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}

/// Returns the approximate double value of a rational number.
pub fn to_double(self : Rational) -> Double {
  // TODO: complete algorithm
  self.numerator.to_double() / self.denominator.to_double()
}

let nan_error = "Rational::from_double: cannot convert NaN"

let overflow_error = "Rational::from_double: overflow"

/// Returns the approximate rational value of a double.
pub fn Rational::from_double(value : Double) -> Rational!String {
  // continued fraction algorithm
  // Ported from https://github.com/rust-num/num
  if value.is_nan() {
    raise nan_error
  }
  let sign = if value < 0.0 { -1L } else { 1L }
  let value = value.abs()
  let mut q = value
  let mut n0 = 0L
  let mut d0 = 1L
  let mut n1 = 1L
  let mut d1 = 0L
  let t_max = Int64::max_value()
  let t_max_f = t_max.to_double()
  let epsilon = 1.0 / t_max_f
  let max_iteration = 30
  let max_error = 10.0e-20

  // Overflow
  if q > t_max_f {
    raise overflow_error
  }
  for i = 0; i < max_iteration; i = i + 1 {
    if not(q >= -9223372036854775808.0 && q < 9223372036854775808.0) {
      break // overflow
    }
    let a = q.to_int64()
    let a_f = a.to_double()
    let f = q - a_f

    // Prevent overflow
    if not(a == 0L) && (n1 > t_max / a || d1 > t_max / a || a * n1 > t_max - n0 ||
    a * d1 > t_max - d0) {
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
    raise overflow_error
  }
  match Rational::new(sign * n1, d1) {
    Some(r) => r
    None => abort("Impossible to reach")
  }
}

/// Ceils a rational number towards positive infinity.
pub fn ceil(self : Rational) -> Int64 {
  let sign = if self.numerator < 0L { -1L } else { 1L }
  let quotient = self.numerator / self.denominator
  if self.numerator % self.denominator == 0L {
    quotient
  } else {
    quotient + (1L + sign) / 2L
  }
}

/// Floors a rational number towards negative infinity.
pub fn floor(self : Rational) -> Int64 {
  let sign = if self.numerator < 0L { -1L } else { 1L }
  let quotient = self.numerator / self.denominator
  if self.numerator % self.denominator == 0L {
    quotient
  } else {
    quotient + (-1L + sign) / 2L
  }
}

/// Rounds a rational number towards zero.
pub fn trunc(self : Rational) -> Int64 {
  if self.numerator < 0L {
    -(-self.numerator / self.denominator)
  } else {
    self.numerator / self.denominator
  }
}

/// Fractional part of a rational number.
/// Same as `self - self.trunc()`.
pub fn fract(self : Rational) -> Rational {
  new_unchecked(self.numerator % self.denominator, self.denominator)
}

pub fn to_string(self : Rational) -> String {
  if self.numerator == 0L {
    "0".to_string()
  } else if self.denominator == 1L {
    self.numerator.to_string()
  } else {
    self.numerator.to_string() + "/" + self.denominator.to_string()
  }
}

pub fn is_integer(self : Rational) -> Bool {
  self.denominator == 1L
}

test "op_add" {
  // 1/2 + 1/3 = 5/6
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 3L)
  let c = a + b
  @test.eq(c.numerator, 5L)!
  @test.eq(c.denominator, 6L)!

  // 1/2 + 1/2 = 1
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a + b
  @test.eq(c.numerator, 1L)!
  @test.eq(c.denominator, 1L)!

  // 1/2 + 1/6 = 2/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 6L)
  let c = a + b
  @test.eq(c.numerator, 2L)!

  // -1/2 + 1/2 = 0
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a + b
  @test.eq(c.numerator, 0L)!

  // -1/2 + -1/2 = -1
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(-1L, 2L)
  let c = a + b
  @test.eq(c.numerator, -1L)!
  @test.eq(c.denominator, 1L)!
}

test "op_sub" {
  // 1/2 - 1/3 = 1/6
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 3L)
  let c = a - b
  @test.eq(c.numerator, 1L)!
  @test.eq(c.denominator, 6L)!

  // 1/2 - 1/2 = 0
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a - b
  @test.eq(c.numerator, 0L)!

  // 1/2 - 1/6 = 1/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 6L)
  let c = a - b
  @test.eq(c.numerator, 1L)!
  @test.eq(c.denominator, 3L)!

  // -1/2 - 1/2 = -1
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a - b
  @test.eq(c.numerator, -1L)!
  @test.eq(c.denominator, 1L)!

  // -1/2 - -1/2 = 0
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(-1L, 2L)
  let c = a - b
  @test.eq(c.numerator, 0L)!
}

test "op_mul" {
  // 1/2 * 2/3 = 1/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(2L, 3L)
  let c = a * b
  @test.eq(c.numerator, 1L)!
  @test.eq(c.denominator, 3L)!

  // -4/3 * 3/4 = -1
  let a = Rational::new_unchecked(-4L, 3L)
  let b = Rational::new_unchecked(3L, 4L)
  let c = a * b
  @test.eq(c.numerator, -1L)!
  @test.eq(c.denominator, 1L)!

  // 1024/42 * 0 = 0
  let a = Rational::new_unchecked(1024L, 42L)
  let b = Rational::new_unchecked(0L, 1L)
  let c = a * b
  @test.eq(c.numerator, 0L)!
  @test.eq(c.denominator, 1L)!
}

test "op_div" {
  // 1/2 / 2/3 = 3/4
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(2L, 3L)
  let c = a / b
  @test.eq(c.numerator, 3L)!
  @test.eq(c.denominator, 4L)!

  // 1/2 / -2/3 = -3/4
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(-2L, 3L)
  let c = a / b
  @test.eq(c.numerator, -3L)!
  @test.eq(c.denominator, 4L)!

  // 0 / 1 = 0
  let a = Rational::new_unchecked(0L, 1L)
  let b = Rational::new_unchecked(1L, 1L)
  let c = a / b
  @test.eq(c.numerator, 0L)!
  @test.eq(c.denominator, 1L)!
}

test "reciprocal" {
  // 1/2 -> 2/1
  let a = Rational::new_unchecked(1L, 2L)
  let b = reciprocal(a)
  @test.eq(b.numerator, 2L)!
  @test.eq(b.denominator, 1L)!

  // -1/2 -> -2/1
  let a = Rational::new_unchecked(-1L, 2L)
  let b = reciprocal(a)
  @test.eq(b.numerator, -2L)!
  @test.eq(b.denominator, 1L)!
}

test "neg" {
  // 1/2 -> -1/2
  let a = Rational::new_unchecked(1L, 2L)
  let b = neg(a)
  @test.eq(b.numerator, -1L)!
  @test.eq(b.denominator, 2L)!

  // -1/2 -> 1/2
  let a = Rational::new_unchecked(-1L, 2L)
  let b = neg(a)
  @test.eq(b.numerator, 1L)!
  @test.eq(b.denominator, 2L)!
}

test "abs" {
  // 1/2 -> 1/2
  let a = Rational::new_unchecked(1L, 2L)
  let b = abs(a)
  @test.eq(b.numerator, 1L)!
  @test.eq(b.denominator, 2L)!

  // -1/2 -> 1/2
  let a = Rational::new_unchecked(-1L, 2L)
  let b = abs(a)
  @test.eq(b.numerator, 1L)!
  @test.eq(b.denominator, 2L)!
}

test "to_double" {
  // 1/2 -> 0.5
  let a = Rational::new_unchecked(1L, 2L)
  let b = a.to_double()
  @test.eq(b, 0.5)!

  // -1/2 -> -0.5
  let a = Rational::new_unchecked(-1L, 2L)
  let b = a.to_double()
  @test.eq(b, -0.5)!
}

test "ceil" {
  // 1/2 -> 1
  let a = Rational::new_unchecked(1L, 2L)
  let b = ceil(a)
  @test.eq(b, 1L)!

  // -1/2 -> 0
  let a = Rational::new_unchecked(-1L, 2L)
  let b = ceil(a)
  @test.eq(b, 0L)!

  // -2/2 -> -1
  let a = Rational::new_unchecked(-2L, 2L)
  let b = ceil(a)
  @test.eq(b, -1L)!

  // 2/2 -> 1
  let a = Rational::new_unchecked(2L, 2L)
  let b = ceil(a)
  @test.eq(b, 1L)!
}

test "floor" {
  // 1/2 -> 0
  let a = Rational::new_unchecked(1L, 2L)
  let b = floor(a)
  @test.eq(b, 0L)!

  // -1/2 -> -1
  let a = Rational::new_unchecked(-1L, 2L)
  let b = floor(a)
  @test.eq(b, -1L)!

  // -2/2 -> -1
  let a = Rational::new_unchecked(-2L, 2L)
  let b = floor(a)
  @test.eq(b, -1L)!

  // 2/2 -> 1
  let a = Rational::new_unchecked(2L, 2L)
  let b = floor(a)
  @test.eq(b, 1L)!
}

test "trunc" {
  // 1/2 -> 0
  let a = Rational::new_unchecked(1L, 2L)
  let b = trunc(a)
  @test.eq(b, 0L)!

  // -1/2 -> 0
  let a = Rational::new_unchecked(-1L, 2L)
  let b = trunc(a)
  @test.eq(b, 0L)!
}

test "fract" {
  // 1/2 -> 1/2
  let a = Rational::new_unchecked(1L, 2L)
  let b = fract(a)
  @test.eq(b.numerator, 1L)!
  @test.eq(b.denominator, 2L)!

  // -1/2 -> -1/2
  let a = Rational::new_unchecked(-1L, 2L)
  let b = fract(a)
  @test.eq(b.numerator, -1L)!
  @test.eq(b.denominator, 2L)!

  // 3/2 -> 1/2
  let a = Rational::new_unchecked(3L, 2L)
  let b = fract(a)
  @test.eq(b.numerator, 1L)!
  @test.eq(b.denominator, 2L)!

  // -3/2 -> -1/2
  let a = Rational::new_unchecked(-3L, 2L)
  let b = fract(a)
  @test.eq(b.numerator, -1L)!
  @test.eq(b.denominator, 2L)!
}

test "to_string" {
  // 1/2 -> "1/2"
  let a = Rational::new_unchecked(1L, 2L)
  let b = to_string(a)
  @test.eq(b, "1/2")!

  // 4/4 -> "1"
  let a = Rational::new_unchecked(4L, 4L)
  let b = to_string(a)
  @test.eq(b, "1")!

  // 0/1 -> "0"
  let a = Rational::new_unchecked(0L, 1L)
  let b = to_string(a)
  @test.eq(b, "0")!
}

test "is_integer" {
  // 1/2 is not an integer
  let a = Rational::new_unchecked(1L, 2L)
  @test.is_false(a.is_integer())!

  // 1 is an integer
  let a = Rational::new_unchecked(1L, 1L)
  @test.is_true(a.is_integer())!

  // 0 is an integer
  let a = Rational::new_unchecked(0L, 1L)
  @test.is_true(a.is_integer())!

  // -1 is an integer
  let a = Rational::new_unchecked(-1L, 1L)
  @test.is_true(a.is_integer())!
}

test "compare" {
  // 1/2 < 2/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(2L, 3L)
  @test.eq(a.compare(b), -1)!
  @test.is_true(a < b)!
  @test.is_true(a <= b)!
  @test.is_true(a != b)!

  // -1/2 > -2/3
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(-2L, 3L)
  @test.eq(a.compare(b), 1)!
  @test.is_true(a > b)!
  @test.is_true(a >= b)!
  @test.is_true(a != b)!

  // 1/2 == 1/2
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  @test.eq(a.compare(b), 0)!
  @test.is_true(a == b)!
}

test "from_double" {
  @test.eq(from_double(0.5)!!, Ok(Rational::new_unchecked(1L, 2L)))!
  @test.eq(from_double(5.0)!!, Ok(Rational::new_unchecked(5L, 1L)))!
  @test.eq(from_double(29.97)!!, Ok(Rational::new_unchecked(2997L, 100L)))!
  @test.eq(from_double(-29.97)!!, Ok(Rational::new_unchecked(-2997L, 100L)))!
  @test.eq(from_double(63.5)!!, Ok(Rational::new_unchecked(127L, 2L)))!
  @test.eq(from_double(126.5)!!, Ok(Rational::new_unchecked(253L, 2L)))!
  @test.eq(from_double(127.0)!!, Ok(Rational::new_unchecked(127L, 1L)))!
  @test.eq(from_double(127.5)!!, Ok(Rational::new_unchecked(255L, 2L)))!
  @test.eq(from_double(-63.5)!!, Ok(Rational::new_unchecked(-127L, 2L)))!
  @test.eq(from_double(-126.5)!!, Ok(Rational::new_unchecked(-253L, 2L)))!
  @test.eq(from_double(-127.0)!!, Ok(Rational::new_unchecked(-127L, 1L)))!
  @test.eq(from_double(-127.5)!!, Ok(Rational::new_unchecked(-255L, 2L)))!
  @test.eq(from_double(-10.0e200)!!, Err(overflow_error))!
  @test.eq(from_double(10.0e200)!!, Err(overflow_error))!
  @test.eq(from_double(Double::inf(1))!!, Err(overflow_error))!
  @test.eq(from_double(Double::inf(-1))!!, Err(overflow_error))!
  @test.eq(from_double(Double::nan())!!, Err(nan_error))!
  @test.eq(
    from_double(2.2204460492503131e-16)!!,
    Ok(Rational::new_unchecked(1L, 4503599627370496L)),
  )!
  @test.eq(from_double(0.0)!!, Ok(Rational::new_unchecked(0L, 1L)))!
  @test.eq(from_double(-0.0)!!, Ok(Rational::new_unchecked(0L, 1L)))!
  @test.eq(
    from_double(9_223_372_036_800_000_000.0)!!,
    Ok(Rational::new_unchecked(9_223_372_036_800_000_000L, 1L)),
  )!
  @test.eq(from_double(9_223_372_036_854_775_807.1)!!, Err(overflow_error))!
  // Unfortunately, the following test case is an overflow error because of the loss of precision in the double value,
  // while mathematically its result should be `Ok(Rational::new_unchecked(9_223_372_036_854_775_807L, 1L))`.
  @test.eq(from_double(9_223_372_036_854_775_807.0)!!, Err(overflow_error))!
}
