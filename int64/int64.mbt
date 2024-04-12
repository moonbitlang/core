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

let max_val = 9223372036854775807L

let min_val = -9223372036854775808L

pub fn Int64::from_int(i : Int) -> Int64 {
  i.to_int64()
}

pub fn abs(self : Int64) -> Int64 {
  if self < 0L {
    -self
  } else {
    self
  }
}

pub fn signum(self : Int64) -> Int64 {
  if self < 0L {
    -1L
  } else if self > 0L {
    1L
  } else {
    0L
  }
}

// Returns the largest positive finite value of Int64
pub fn Int64::max_value() -> Int64 {
  max_val
}

// Returns the smallest positive nonzero value of Int64
pub fn Int64::min_value() -> Int64 {
  min_val
}

/// Returns the mathematical absolute value of the Int64,
/// None if the result overflows. 
pub fn checked_abs(self : Int64) -> Option[Int64] {
  if self == min_val {
    None
  } else {
    Some(self.abs())
  }
}

/// Returns the negation of the Int64,
/// None if the result overflows. 
pub fn checked_neg(self: Int64) -> Option[Int64] {
  if self == min_val {
    None
  } else {
    Some(-self)
  }
}

/// Returns the sum of the arguments,
/// None if the result overflows. 
pub fn checked_add(self: Int64, other: Int64) -> Option[Int64] {
  let r = self + other
  // Overflow iff both arguments have the opposite sign of the result
  if self.lxor(r).land(other.lxor(r)) < 0L {
    None
  } else {
    Some(r)
  }
}

/// Returns the difference of the arguments,
/// None if the result overflows. 
pub fn checked_sub(self: Int64, other: Int64) -> Option[Int64] {
  let r = self - other
  // Overflow iff the arguments have different signs and the sign
  // of the result is different from the sign of x
  if self.lxor(other).land(self.lxor(r)) < 0L {
    None
  } else {
    Some(r)
  }
}

/// Returns the product of the arguments,
/// None if the result overflows. 
pub fn checked_mul(self: Int64, other: Int64) -> Option[Int64] {
  let r = self * other
  let abs_self = self.abs()
  let abs_other = other.abs()
  if abs_self.lor(abs_other).lsr(31) != 0L {
    // bits that greater than 2^31 might cause overflow
    if ((other != 0L) && (r / other != self)) || (self == min_val && other == -1L) {
      return None
    }
  }
  Some(r)
}

/// Returns the quotient of the arguments,
/// None if the result overflows. 
pub fn checked_div(self: Int64, other: Int64) -> Option[Int64] {
  if other == 0L || (self == min_val && other == -1L) {
    None
  } else {
    Some(self / other)
  }
}
fn test_num[T : @num.Num + Debug + Default + Eq](
  x : T,
  y : T,
  x_plus_y : T,
  x_mul_y : T,
  x_minus_y : T,
  x_div_y : T,
  x_signum : T
) -> Result[Unit, String] {
  @assertion.assert_eq(x + y, x_plus_y)?
  @assertion.assert_eq(x * y, x_mul_y)?
  @assertion.assert_eq(x - y, x_minus_y)?
  @assertion.assert_eq(x / y, x_div_y)?
  @assertion.assert_eq(x.abs(), T::default() - x)?
  @assertion.assert_eq(x.signum(), x_signum)?
  Ok(())
}

test "int64.num" {
  let x = -500L
  let y = 792L
  test_num(x, y, x + y, x * y, x - y, x / y, -1L)?
}

pub fn hash(self : Int64) -> Int {
  let lo = self.to_int()
  let hi = self.lsr(32).to_int()
  lo.lxor(hi)
}

test "checked_abs" {
  @assertion.assert_eq((1L).checked_abs(), Some(1L))?
  @assertion.assert_eq((-1L).checked_abs(), Some(1L))?
  @assertion.assert_eq(min_val.checked_abs(), None)?
  @assertion.assert_eq(max_val.checked_abs(), Some(max_val))?
}

test "checked_neg" {
  @assertion.assert_eq((1L).checked_neg(), Some(-1L))?
  @assertion.assert_eq((-1L).checked_neg(), Some(1L))?
  @assertion.assert_eq(min_val.checked_neg(), None)?
  @assertion.assert_eq(max_val.checked_neg(), Some(-max_val))?
}

test "checked_add" {
  @assertion.assert_eq((1L).checked_add(1L), Some(2L))?
  @assertion.assert_eq((-1L).checked_add(1L), Some(0L))?
  @assertion.assert_eq((-1L).checked_add(-1L), Some(-2L))?
  @assertion.assert_eq(max_val.checked_add(1L), None)?
  @assertion.assert_eq(min_val.checked_add(-1L), None)?
}

test "checked_sub" {
  @assertion.assert_eq((1L).checked_sub(1L), Some(0L))?
  @assertion.assert_eq((-1L).checked_sub(1L), Some(-2L))?
  @assertion.assert_eq((-1L).checked_sub(-1L), Some(0L))?
  @assertion.assert_eq(min_val.checked_sub(1L), None)?
  @assertion.assert_eq(max_val.checked_sub(-1L), None)?
}

test "checked_mul" {
  @assertion.assert_eq((2L).checked_mul(3L), Some(6L))?
  @assertion.assert_eq((-2L).checked_mul(3L), Some(-6L))?
  @assertion.assert_eq((-2L).checked_mul(-3L), Some(6L))?
  @assertion.assert_eq(min_val.checked_mul(2L), None)?
  @assertion.assert_eq(max_val.checked_mul(2L), None)?
}

test "checked_div" {
  @assertion.assert_eq((4L).checked_div(2L), Some(2L))?
  @assertion.assert_eq((-4L).checked_div(2L), Some(-2L))?
  @assertion.assert_eq((4L).checked_div(0L), None)?
  @assertion.assert_eq(min_val.checked_div(-1L), None)?
}