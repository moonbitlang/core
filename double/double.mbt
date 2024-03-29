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

// Returns the largest positive finite value of double
pub fn Double::max_value() -> Double {
  max_val
}

// Returns the smallest positive nonzero value of double
pub fn Double::min_value() -> Double {
  min_val
}

// Returns the smallest positive normal value of double
pub fn Double::min_normal() -> Double {
  min_norm
}

// Check whether the double is a "not-a-number" value
pub fn is_nan(self : Double) -> Bool {
  // only NaNs satisfy f != f.
  self != self
}

// Check whether the double is infinity
// if sign > 0, returns true when f is positive infinity.
// if sign < 0, returns true when f is negative infinity.
// if sign = 0, returns true when f is either.
pub fn is_inf(self : Double, sign : Int) -> Bool {
  sign >= 0 && self > max_val || sign <= 0 && self < -max_val
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
  @test.eq(x + y, x_plus_y)?
  @test.eq(x * y, x_mul_y)?
  @test.eq(x - y, x_minus_y)?
  @test.eq(x / y, x_div_y)?
  @test.eq(x.abs(), T::default() - x)?
  @test.eq(x.signum(), x_signum)?
  Ok(())
}

test "double.num" {
  let x = -500.0
  let y = 792.0
  test_num(x, y, x + y, x * y, x - y, x / y, -1.0)?
}

test "is_nan" {
  @test.is_true(is_nan(not_a_number))?
  @test.is_false(is_nan(0.0))?
  @test.is_false(is_nan(12345.678))?
  @test.is_false(is_nan(positive_infinity))?
  @test.is_false(is_nan(negative_infinity))?
}

test "is_inf" {
  @test.is_true(is_inf(positive_infinity, 1))?
  @test.is_false(is_inf(negative_infinity, 1))?
  @test.is_true(is_inf(negative_infinity, -1))?
  @test.is_false(is_inf(positive_infinity, -1))?
  @test.is_true(is_inf(positive_infinity, 0))?
  @test.is_true(is_inf(negative_infinity, 0))?
  @test.is_false(is_inf(0.0, 1))?
  @test.is_false(is_inf(12345.678, 1))?
}