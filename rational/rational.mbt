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
}

fn gcd(a : Int64, b : Int64) -> Int64 {
  if b == 0L {
    a
  } else {
    gcd(b, a % b)
  }
}

/// Creates a rational number.
pub fn Rational::new(
  numerator : Int64,
  denominator : Int64
) -> Option[Rational] {
  if denominator == 0L {
    None
  } else {
    let sign = if numerator < 0L && denominator < 0L || numerator > 0L && denominator >
    0L {
      1L
    } else {
      -1L
    }
    let numerator = if numerator < 0L { -numerator } else { numerator }
    let denominator = if denominator < 0L { -denominator } else { denominator }
    let gcd = gcd(numerator, denominator)
    Some({ numerator: sign * numerator / gcd, denominator: denominator / gcd })
  }
}

/// Creates a rational number without enforcing invariants.
pub fn Rational::new_unchecked(
  numerator : Int64,
  denominator : Int64
) -> Rational {
  { numerator, denominator }
}

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
  new_unchecked(
    self.numerator * other.denominator,
    self.denominator * other.numerator,
  )
}

pub fn op_mod(self : Rational, other : Rational) -> Rational {
  new_unchecked(
    self.numerator * other.denominator % (self.denominator * other.numerator),
    self.denominator * other.denominator,
  )
}

/// Returns the reciprocal of a rational number.
pub fn reciprocal(self : Rational) -> Rational {
  new_unchecked(self.denominator, self.numerator)
}

/// Returns the negation of a rational number.
pub fn neg(self : Rational) -> Rational {
  new_unchecked(-self.numerator, self.denominator)
}

// /// Returns the absolute value of a rational number.
// pub fn abs(self : Rational) -> Rational {
//   new_unchecked(self.numerator.abs(), self.denominator.abs())
// }

/// Less than operator for rational numbers.
pub fn op_lt(self : Rational, other : Rational) -> Bool {
  self.numerator * other.denominator < other.numerator * self.denominator
}

/// Greater than operator for rational numbers.
pub fn op_gt(self : Rational, other : Rational) -> Bool {
  self.numerator * other.denominator > other.numerator * self.denominator
}

/// Equal to operator for rational numbers.
pub fn op_equal(self : Rational, other : Rational) -> Bool {
  self.numerator * other.denominator == other.numerator * self.denominator
}

/// Compares two rational numbers.
pub fn compare(self : Rational, other : Rational) -> Int {
  if self.numerator * other.denominator < other.numerator * self.denominator {
    -1
  } else if self.numerator * other.denominator > other.numerator * self.denominator {
    1
  } else {
    0
  }
}

/// Greater than or equal to operator for rational numbers.
pub fn op_ge(self : Rational, other : Rational) -> Bool {
  self > other || self == other
}

/// Less than or equal to operator for rational numbers.
pub fn op_le(self : Rational, other : Rational) -> Bool {
  self < other || self == other
}

/// Not equal to operator for rational numbers.
pub fn op_ne(self : Rational, other : Rational) -> Bool {
  not(self == other)
}

/// Returns the approximate double value of a rational number.
pub fn approximate_double(self : Rational) -> Double {
  // TODO: complete algorithm
  self.numerator.to_double() / self.denominator.to_double()
}

/// Returns the approximate rational value of a double.
pub fn from_double(value : Double) -> Rational {
  // continued fraction algorithm
  // TODO: add test
  let mut x = value
  let mut a = x.to_int64()
  let mut h1 = 0L
  let mut h2 = 1L
  let mut k1 = 1L
  let mut k2 = 0L
  let mut n = 1L
  while x - a.to_double() != 0.0 {
    x = 1.0 / (x - a.to_double())
    a = x.to_int64()
    let h = a * h1 + h2
    let k = a * k1 + k2
    h2 = h1
    h1 = h
    k2 = k1
    k1 = k
    n += 1L
  }
  match new(h1, k1) {
    Some(r) => r
    None => abort("Rational::from_double: invalid value")
  }
}

/// Ceils a rational number towards positive infinity.
pub fn ceil(self : Rational) -> Int64 {
  let quotient = self.numerator / self.denominator
  if self.numerator % self.denominator == 0L {
    quotient
  } else {
    quotient + 1L
  }
}

/// Floors a rational number towards negative infinity.
pub fn floor(self : Rational) -> Int64 {
  self.numerator / self.denominator
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
  if self.denominator == 1L {
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
  @assertion.assert_eq(c.numerator, 5L)?
  @assertion.assert_eq(c.denominator, 6L)?

  // 1/2 + 1/2 = 1
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a + b
  println(c.numerator)
  println(c.denominator)

  @assertion.assert_eq(c.numerator, 1L)?
  @assertion.assert_eq(c.denominator, 1L)?

  // 1/2 + 1/6 = 2/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 6L)
  let c = a + b
  @assertion.assert_eq(c.numerator, 2L)?

  // -1/2 + 1/2 = 0
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a + b
  @assertion.assert_eq(c.numerator, 0L)?

  // -1/2 + -1/2 = -1
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(-1L, 2L)
  let c = a + b
  @assertion.assert_eq(c.numerator, -1L)?
  @assertion.assert_eq(c.denominator, 1L)?
}

test "op_sub" {
  // 1/2 - 1/3 = 1/6
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 3L)
  let c = a - b
  @assertion.assert_eq(c.numerator, 1L)?
  @assertion.assert_eq(c.denominator, 6L)?

  // 1/2 - 1/2 = 0
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a - b
  @assertion.assert_eq(c.numerator, 0L)?

  // 1/2 - 1/6 = 1/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 6L)
  let c = a - b
  @assertion.assert_eq(c.numerator, 1L)?
  @assertion.assert_eq(c.denominator, 3L)?

  // -1/2 - 1/2 = -1
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  let c = a - b
  @assertion.assert_eq(c.numerator, -1L)?
  @assertion.assert_eq(c.denominator, 1L)?

  // -1/2 - -1/2 = 0
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(-1L, 2L)
  let c = a - b
  @assertion.assert_eq(c.numerator, 0L)?
}

test "op_mul" {
  // 1/2 * 2/3 = 1/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(2L, 3L)
  let c = a * b
  @assertion.assert_eq(c.numerator, 1L)?
  @assertion.assert_eq(c.denominator, 3L)?

  // -4/3 * 3/4 = -1
  let a = Rational::new_unchecked(-4L, 3L)
  let b = Rational::new_unchecked(3L, 4L)
  let c = a * b
  @assertion.assert_eq(c.numerator, -1L)?
  @assertion.assert_eq(c.denominator, 1L)?

  // 1024/42 * 0 = 0
  let a = Rational::new_unchecked(1024L, 42L)
  let b = Rational::new_unchecked(0L, 1L)
  let c = a * b
  @assertion.assert_eq(c.numerator, 0L)?
  @assertion.assert_eq(c.denominator, 1L)?
}

test "op_div" {
  // 1/2 / 2/3 = 3/4
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(2L, 3L)
  let c = a / b
  @assertion.assert_eq(c.numerator, 3L)?
  @assertion.assert_eq(c.denominator, 4L)?

  // -3/2 / 3/2 = -1
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(2L, 3L)
  let c = a / b
  @assertion.assert_eq(c.numerator, -3L)?
  @assertion.assert_eq(c.denominator, 4L)?

  // 0 / 1 = 0
  let a = Rational::new_unchecked(0L, 1L)
  let b = Rational::new_unchecked(1L, 1L)
  let c = a / b
  @assertion.assert_eq(c.numerator, 0L)?
  @assertion.assert_eq(c.denominator, 1L)?
}

test "compare" {
  // 1/2 < 2/3
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(2L, 3L)
  @assertion.assert_eq(a.compare(b), -1)?
  @assertion.assert_true(a < b)?

  // -1/2 > -2/3
  let a = Rational::new_unchecked(-1L, 2L)
  let b = Rational::new_unchecked(-2L, 3L)
  // println(a.compare(b))
  // println(a.numerator)
  // println(a.denominator)
  // println(b.numerator)
  // println(b.denominator)
  @assertion.assert_eq(a.compare(b), 1)?
  @assertion.assert_true(a > b)?

  // 1/2 == 1/2
  let a = Rational::new_unchecked(1L, 2L)
  let b = Rational::new_unchecked(1L, 2L)
  @assertion.assert_eq(a.compare(b), 0)?
  @assertion.assert_true(a == b)?
}
