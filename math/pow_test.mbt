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

///|
test "scalbn comprehensive" {
  // Basic tests for scalbnf
  inspect(scalbnf(1.5, 2), content="6")
  inspect(scalbnf(2.0, -1), content="1")
  inspect(scalbnf(3.0, 0), content="3")

  // Test extreme exponent values
  inspect(scalbnf(1.0, 128), content="Infinity")
  inspect(scalbnf(1.0, -150), content="0")
  inspect(scalbnf(1.0, 254), content="Infinity")
  inspect(scalbnf(1.0, -199), content="0")
  inspect(scalbnf(1.0, 307), content="Infinity")
  inspect(scalbnf(1.0, -296), content="0")

  // Test with special values
  inspect(scalbnf(@float.infinity, 10), content="Infinity")
  inspect(scalbnf(@float.neg_infinity, 10), content="-Infinity")
  inspect(scalbnf(@float.not_a_number, 10), content="NaN")
  inspect(scalbnf(0.0, 10), content="0")
  inspect(scalbnf(-0.0, 10), content="0")

  // Test with different float values
  inspect(scalbnf(0.5, 1), content="1")
  inspect(scalbnf(0.25, 2), content="1")
  inspect(scalbnf(0.1, 4), content="1.600000023841858")

  // Test with negative numbers
  inspect(scalbnf(-2.0, 3), content="-16")
  inspect(scalbnf(-3.0, -1), content="-1.5")

  // Test with small numbers
  let small_number = 1.0e-20
  let small_float = small_number.to_float()
  inspect(scalbnf(small_float, 1), content="1.999999936531045e-20")
}

///|
test "pow basic" {
  // Basic tests for powf
  inspect(powf(1.0, 3.0), content="1")
  inspect(powf(-1.0, 3.0), content="-1")
  inspect(powf(2.0, 3.0), content="8")
  inspect(powf(-2.0, 3.0), content="-8")
  inspect(powf(2.0, -3.0), content="0.125")
  inspect(powf(-2.0, -3.0), content="-0.125")
  inspect(powf(2.0, -3.14), content="0.1134398877620697")
  inspect(powf(-2.0, -3.14), content="NaN")

  // Test with special values
  inspect(powf(@float.infinity, 3.0), content="Infinity")
  inspect(powf(@float.infinity, -3.0), content="0")
  inspect(powf(@float.infinity, 0.0), content="1")
  inspect(powf(@float.neg_infinity, 3.0), content="-Infinity")
  inspect(powf(@float.neg_infinity, -3.0), content="0")
  inspect(powf(@float.neg_infinity, 0.0), content="1")
  inspect(powf(@float.not_a_number, 3.0), content="NaN")
}

///|
test "pow special cases" {
  // Test x^0 for various x values
  inspect(powf(0.0, 0.0), content="1")
  inspect(powf(1.0, 0.0), content="1")
  inspect(powf(-1.0, 0.0), content="1")
  inspect(powf(@float.infinity, 0.0), content="1")
  inspect(powf(@float.neg_infinity, 0.0), content="1")
  inspect(powf(@float.not_a_number, 0.0), content="1")

  // Test 0^y for various y values
  inspect(powf(0.0, 1.0), content="0")
  inspect(powf(0.0, 2.0), content="0")
  inspect(powf(0.0, -1.0), content="Infinity")
  inspect(powf(0.0, -2.0), content="Infinity")
  inspect(powf(0.0, 0.5), content="0")
  inspect(powf(0.0, -0.5), content="Infinity")

  // Test negative base with non-integer exponent
  inspect(powf(-1.0, 0.5), content="NaN")
  inspect(powf(-2.0, 0.5), content="NaN")

  // Test 1^y for various y values
  inspect(powf(1.0, 10.0), content="1")
  inspect(powf(1.0, -10.0), content="1")
  inspect(powf(1.0, @float.infinity), content="1")
  inspect(powf(1.0, @float.neg_infinity), content="1")
  inspect(powf(1.0, @float.not_a_number), content="1")

  // Test x^NaN
  inspect(powf(2.0, @float.not_a_number), content="NaN")
  inspect(powf(-2.0, @float.not_a_number), content="NaN")

  // Test NaN^y (except for y=0, tested above)
  inspect(powf(@float.not_a_number, 1.0), content="NaN")
  inspect(powf(@float.not_a_number, -1.0), content="NaN")
}

///|
test "pow edge cases" {
  // Test cases with very large exponents
  assert_true(powf(1.2, 100.0).is_close(82818304.0))
  assert_true(powf(0.8, 100.0).is_close(2.0370390096946522e-10))

  // Test cases with very small exponents
  assert_true(powf(1.2, -100.0).is_close(1.2074625743707657e-8))
  assert_true(powf(0.8, -100.0).is_close(4909086208.0))

  // Test cases with small base
  let small_flt = 1.0e-5F
  assert_true(powf(small_flt, 2.0).is_close(9.999999439624929e-11))
  assert_true(powf(small_flt, 0.5).is_close(0.003162277629598975))

  // Test cases with large base
  let large_flt : Float = 1.0e5
  assert_true(powf(large_flt, 2.0).is_close(10000000000.0))
  assert_true(powf(large_flt, 0.5).is_close(316.2277526855469))

  // Test negative exponent with negative base (where exponent is integer)
  assert_true(powf(-2.0, -4.0).is_close(0.0625))
  assert_true(powf(-2.0, -5.0).is_close(-0.03125))

  // Test fractional exponents with positive base
  assert_true(powf(4.0, 0.5).is_close(2.0))
  assert_true(powf(9.0, 0.5).is_close(3.0))
  assert_true(powf(16.0, 0.25).is_close(2.0))

  // Test powers that should closely approximate known values
  assert_true(powf(10.0, 2.0).is_close(100.0))
  assert_true(powf(10.0, -2.0).is_close(0.009999999776482582))
}

///|
test "pow with standard functions" {
  // Compare with standard mathematical identities

  // Test simple cases of e^x
  let e_flt : Float = 2.7182817459106445
  let x_flt : Float = 2.0
  let expected_exp_flt : Float = 7.3890562
  let actual_pow_flt = powf(e_flt, x_flt)
  assert_true((actual_pow_flt - expected_exp_flt).abs() < 0.01)

  // Test sqrt(x) vs. pow(x, 0.5)
  let values_flt : Array[Float] = [4.0, 9.0, 16.0, 25.0]
  for value in values_flt {
    let expected_sqrt_flt = value.sqrt()
    let actual_pow_flt = powf(value, 0.5)
    assert_true((actual_pow_flt - expected_sqrt_flt).abs() < 0.01)
  }

  // Test pow(x, y) * pow(x, z) = pow(x, y + z)
  let x_test_flt : Float = 3.0
  let y_test_flt : Float = 2.0
  let z_test_flt : Float = 4.0
  let left_val_flt = powf(x_test_flt, y_test_flt) * powf(x_test_flt, z_test_flt)
  let right_val_flt = powf(x_test_flt, y_test_flt + z_test_flt)
  assert_true((left_val_flt - right_val_flt).abs() < 0.01)

  // Test pow(x, y)^z = pow(x, y*z)
  let left_test_flt = powf(powf(x_test_flt, y_test_flt), z_test_flt)
  let right_test_flt = powf(x_test_flt, y_test_flt * z_test_flt)
  assert_true((left_test_flt - right_test_flt).abs() < 0.01)
}
