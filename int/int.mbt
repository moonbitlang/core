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

let max_val = 2147483647

let min_val = -2147483648

pub fn Int::from_int(i : Int) -> Int {
  i
}

pub fn abs(self : Int) -> Int {
  if self < 0 {
    -self
  } else {
    self
  }
}

pub fn signum(self : Int) -> Int {
  if self < 0 {
    -1
  } else if self > 0 {
    1
  } else {
    0
  }
}

/// Returns the largest positive finite value of Int
pub fn Int::max_value() -> Int {
  max_val
}

/// Returns the smallest positive nonzero value of Int
pub fn Int::min_value() -> Int {
  min_val
}

/// Returns the mathematical absolute value of the Int,
/// None if the result overflows. 
pub fn checked_abs(self : Int) -> Option[Int] {
  if self == min_val {
    None
  } else {
    Some(self.abs())
  }
}

/// Returns the negation of the Int,
/// None if the result overflows. 
pub fn checked_neg(self: Int) -> Option[Int] {
  if self == min_val {
    None
  } else {
    Some(-self)
  }
}

/// Returns the sum of the arguments,
/// None if the result overflows. 
pub fn checked_add(self: Int, other: Int) -> Option[Int] {
  let r = self + other
  // Overflow iff both arguments have the opposite sign of the result
  if self.lxor(r).land(other.lxor(r)) < 0 {
    None
  } else {
    Some(r)
  }
}

/// Returns the difference of the arguments,
/// None if the result overflows. 
pub fn checked_sub(self: Int, other: Int) -> Option[Int] {
  let r = self - other
  // Overflow iff the arguments have different signs and the sign
  // of the result is different from the sign of x
  if self.lxor(other).land(self.lxor(r)) < 0 {
    None
  } else {
    Some(r)
  }
}

/// Returns the product of the arguments,
/// None if the result overflows. 
pub fn checked_mul(self: Int, other: Int) -> Option[Int] {
  let r = self.to_int64() * other.to_int64()
  if r > max_val.to_int64() || r < min_val.to_int64() {
    None
  } else {
    Some(r.to_int())
  }
}

/// Returns the quotient of the arguments,
/// None if the result overflows. 
pub fn checked_div(self: Int, other: Int) -> Option[Int] {
  if other == 0 || (self == min_val && other == -1) {
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

test "int.num" {
  let x = -5
  let y = 7
  test_num(x, y, x + y, x * y, x - y, x / y, -1)?
}

pub fn hash(self : Int) -> Int {
  self
}

test "checked_abs" {
  @assertion.assert_eq((1).checked_abs(), Some(1))?
  @assertion.assert_eq((-1).checked_abs(), Some(1))?
  @assertion.assert_eq(min_val.checked_abs(), None)?
  @assertion.assert_eq(max_val.checked_abs(), Some(max_val))?
}

test "checked_neg" {
  @assertion.assert_eq((1).checked_neg(), Some(-1))?
  @assertion.assert_eq((-1).checked_neg(), Some(1))?
  @assertion.assert_eq(min_val.checked_neg(), None)?
  @assertion.assert_eq(max_val.checked_neg(), Some(-max_val))?
}

test "checked_add" {
  @assertion.assert_eq((1).checked_add(1), Some(2))?
  @assertion.assert_eq((-1).checked_add(1), Some(0))?
  @assertion.assert_eq((-1).checked_add(-1), Some(-2))?
  @assertion.assert_eq(max_val.checked_add(1), None)?
  @assertion.assert_eq(min_val.checked_add(-1), None)?
}

test "checked_sub" {
  @assertion.assert_eq((1).checked_sub(1), Some(0))?
  @assertion.assert_eq((-1).checked_sub(1), Some(-2))?
  @assertion.assert_eq((-1).checked_sub(-1), Some(0))?
  @assertion.assert_eq(min_val.checked_sub(1), None)?
  @assertion.assert_eq(max_val.checked_sub(-1), None)?
}

test "checked_mul" {
  @assertion.assert_eq((2).checked_mul(3), Some(6))?
  @assertion.assert_eq((-2).checked_mul(3), Some(-6))?
  @assertion.assert_eq((-2).checked_mul(-3), Some(6))?
  @assertion.assert_eq(min_val.checked_mul(2), None)?
  @assertion.assert_eq(max_val.checked_mul(2), None)?
}

test "checked_div" {
  @assertion.assert_eq((4).checked_div(2), Some(2))?
  @assertion.assert_eq((-4).checked_div(2), Some(-2))?
  @assertion.assert_eq((4).checked_div(0), None)?
  @assertion.assert_eq(min_val.checked_div(-1), None)?
}