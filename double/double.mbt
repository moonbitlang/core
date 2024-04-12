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

let not_a_number : Double = 0x7FF8000000000001L.reinterpret_as_double()

let positive_infinity : Double = 0x7FF0000000000000L.reinterpret_as_double()

let negative_infinity : Double = 0xFFF0000000000000L.reinterpret_as_double()

let max_val : Double = 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()

let min_val : Double = 0x1L.reinterpret_as_double()

let min_norm : Double = 0x0010000000000000L.reinterpret_as_double()

pub fn Double::from_int(i : Int) -> Double {
  i.to_double()
}

pub fn abs(self : Double) -> Double {
  if self < 0.0 {
    -self
  } else {
    self
  }
}

/// Returns the sign of the double.
/// - If the double is positive, returns 1.0.
/// - If the double is negative, returns -1.0.
/// - Otherwise, returns the double itself (0.0, -0.0 and NaN).
pub fn signum(self : Double) -> Double {
  if self < 0.0 {
    -1.0
  } else if self > 0.0 {
    1.0
  } else {
    self // handles 0.0, -0.0, NaN
  }
}

// Returns a "not-a-number" value
pub fn Double::nan() -> Double {
  not_a_number
}

// Returns positive infinity if sign >= 0, negative infinity if sign < 0.
pub fn Double::inf(sign : Int) -> Double {
  if sign >= 0 {
    positive_infinity
  } else {
    negative_infinity
  }
}

// Returns the largest positive finite value of Double
pub fn Double::max_value() -> Double {
  max_val
}

// Returns the smallest positive nonzero value of Double
pub fn Double::min_value() -> Double {
  min_val
}

// Returns the smallest positive normal value of Double
pub fn Double::min_normal() -> Double {
  min_norm
}

// Check whether the double is a "not-a-number" value
pub fn is_nan(self : Double) -> Bool {
  // only NaNs satisfy f != f.
  self != self
}

// Check whether the double is infinity
pub fn is_inf(self : Double) -> Bool {
  self > max_val || self < -max_val
}

// Check whether the double is positive infinity
pub fn is_pos_inf(self : Double) -> Bool {
  self > max_val
}

// Check whether the double is negative infinity
pub fn is_neg_inf(self : Double) -> Bool {
  self < -max_val
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

test "double.num" {
  let x = -500.0
  let y = 792.0
  test_num(x, y, x + y, x * y, x - y, x / y, -1.0)?
}

test "from_int" {
  @assertion.assert_eq(Double::from_int(1), 1.0)?
  @assertion.assert_eq(Double::from_int(0), 0.0)?
  @assertion.assert_eq(Double::from_int(100000), 1.0e5)?
}

test "abs" {
  let d = -1.0
  @assertion.assert_eq(d.abs(), 1.0)?
  @assertion.assert_eq(1.0.abs(), 1.0)?
}

test "signum" {
  let d = -2.0
  @assertion.assert_eq(d.signum(), -1.0)?
  @assertion.assert_eq(1.0.signum(), 1.0)?
  @assertion.assert_eq(0.0.signum(), 0.0)?
  @assertion.assert_true(not_a_number.signum().is_nan())?
}

test "is_nan" {
  @assertion.assert_true(is_nan(not_a_number))?
  @assertion.assert_false(is_nan(0.0))?
  @assertion.assert_false(is_nan(12345.678))?
  @assertion.assert_false(is_nan(positive_infinity))?
  @assertion.assert_false(is_nan(negative_infinity))?
}

test "is_inf" {
  @assertion.assert_true(is_inf(positive_infinity))?
  @assertion.assert_true(is_inf(negative_infinity))?
  @assertion.assert_false(is_inf(0.0))?
  @assertion.assert_false(is_inf(12345.678))?
}

test "is_pos_inf" {
  @assertion.assert_true(is_pos_inf(positive_infinity))?
  @assertion.assert_false(is_pos_inf(negative_infinity))?
  @assertion.assert_false(is_pos_inf(0.0))?
  @assertion.assert_false(is_pos_inf(12345.678))?
}

test "is_neg_inf" {
  @assertion.assert_false(is_neg_inf(positive_infinity))?
  @assertion.assert_true(is_neg_inf(negative_infinity))?
  @assertion.assert_false(is_neg_inf(0.0))?
  @assertion.assert_false(is_neg_inf(12345.678))?
}

test "nan" {
  @assertion.assert_true(Double::nan().is_nan())?
}

test "inf" {
  @assertion.assert_eq(Double::inf(1), positive_infinity)?
  @assertion.assert_eq(Double::inf(0), positive_infinity)?
  @assertion.assert_eq(Double::inf(-1), negative_infinity)?
}

test "max_value" {
  @assertion.assert_eq(Double::max_value(), max_val)?
}

test "min_value" {
  @assertion.assert_eq(Double::min_value(), min_val)?
}

test "min_normal" {
  @assertion.assert_eq(Double::min_normal(), min_norm)?
}

pub fn hash(self : Double) -> Int {
  self.reinterpret_as_i64().hash()
}

/// @intrinsic %f64.to_string
pub fn to_string(self : Double) -> String {
  @ryu.double_to_string(self)
}

pub fn debug_write(self : Double, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}
