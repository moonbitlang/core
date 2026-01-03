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
test "scalbn comprehensive" {
  // Basic tests for scalbnf
  inspect(@math.scalbnf(1.5, 2), content="6")
  inspect(@math.scalbnf(2.0, -1), content="1")
  inspect(@math.scalbnf(3.0, 0), content="3")

  // Test extreme exponent values
  inspect(@math.scalbnf(1.0, 128), content="Infinity")
  inspect(@math.scalbnf(1.0, -150), content="0")
  inspect(@math.scalbnf(1.0, 254), content="Infinity")
  inspect(@math.scalbnf(1.0, -199), content="0")
  inspect(@math.scalbnf(1.0, 307), content="Infinity")
  inspect(@math.scalbnf(1.0, -296), content="0")

  // Test with special values
  inspect(@math.scalbnf(@float.infinity, 10), content="Infinity")
  inspect(@math.scalbnf(@float.neg_infinity, 10), content="-Infinity")
  inspect(@math.scalbnf(@float.not_a_number, 10), content="NaN")
  inspect(@math.scalbnf(0.0, 10), content="0")
  inspect(@math.scalbnf(-0.0, 10), content="0")

  // Test with different float values
  inspect(@math.scalbnf(0.5, 1), content="1")
  inspect(@math.scalbnf(0.25, 2), content="1")
  inspect(@math.scalbnf(0.1, 4), content="1.600000023841858")

  // Test with negative numbers
  inspect(@math.scalbnf(-2.0, 3), content="-16")
  inspect(@math.scalbnf(-3.0, -1), content="-1.5")

  // Test with small numbers
  let small_number = 1.0e-20
  let small_float = Float::from_double(small_number)
  inspect(@math.scalbnf(small_float, 1), content="1.999999936531045e-20")
}

///|
test "pow basic" {
  // Basic tests for @math.powf
  inspect(@math.powf(1.0, 3.0), content="1")
  inspect(@math.powf(-1.0, 3.0), content="-1")
  inspect(@math.powf(2.0, 3.0), content="8")
  inspect(@math.powf(-2.0, 3.0), content="-8")
  inspect(@math.powf(2.0, -3.0), content="0.125")
  inspect(@math.powf(-2.0, -3.0), content="-0.125")
  inspect(@math.powf(2.0, -3.14), content="0.1134398877620697")
  inspect(@math.powf(-2.0, -3.14), content="NaN")

  // Test with special values
  inspect(@math.powf(@float.infinity, 3.0), content="Infinity")
  inspect(@math.powf(@float.infinity, -3.0), content="0")
  inspect(@math.powf(@float.infinity, 0.0), content="1")
  inspect(@math.powf(@float.neg_infinity, 3.0), content="-Infinity")
  inspect(@math.powf(@float.neg_infinity, -3.0), content="0")
  inspect(@math.powf(@float.neg_infinity, 0.0), content="1")
  inspect(@math.powf(@float.not_a_number, 3.0), content="NaN")
}

///|
test "pow special cases" {
  // Test x^0 for various x values
  inspect(@math.powf(0.0, 0.0), content="1")
  inspect(@math.powf(1.0, 0.0), content="1")
  inspect(@math.powf(-1.0, 0.0), content="1")
  inspect(@math.powf(@float.infinity, 0.0), content="1")
  inspect(@math.powf(@float.neg_infinity, 0.0), content="1")
  inspect(@math.powf(@float.not_a_number, 0.0), content="1")

  // Test 0^y for various y values
  inspect(@math.powf(0.0, 1.0), content="0")
  inspect(@math.powf(0.0, 2.0), content="0")
  inspect(@math.powf(0.0, -1.0), content="Infinity")
  inspect(@math.powf(0.0, -2.0), content="Infinity")
  inspect(@math.powf(0.0, 0.5), content="0")
  inspect(@math.powf(0.0, -0.5), content="Infinity")

  // Test negative base with non-integer exponent
  inspect(@math.powf(-1.0, 0.5), content="NaN")
  inspect(@math.powf(-2.0, 0.5), content="NaN")

  // Test 1^y for various y values
  inspect(@math.powf(1.0, 10.0), content="1")
  inspect(@math.powf(1.0, -10.0), content="1")
  inspect(@math.powf(1.0, @float.infinity), content="1")
  inspect(@math.powf(1.0, @float.neg_infinity), content="1")
  inspect(@math.powf(1.0, @float.not_a_number), content="1")

  // Test x^NaN
  inspect(@math.powf(2.0, @float.not_a_number), content="NaN")
  inspect(@math.powf(-2.0, @float.not_a_number), content="NaN")

  // Test NaN^y (except for y=0, tested above)
  inspect(@math.powf(@float.not_a_number, 1.0), content="NaN")
  inspect(@math.powf(@float.not_a_number, -1.0), content="NaN")
}

///|
test "pow edge cases" {
  // Test cases with very large exponents
  assert_true(@math.powf(1.2, 100.0).is_close(82818304.0))
  assert_true(@math.powf(0.8, 100.0).is_close(2.0370390096946522e-10))

  // Test cases with very small exponents
  assert_true(@math.powf(1.2, -100.0).is_close(1.2074625743707657e-8))
  assert_true(@math.powf(0.8, -100.0).is_close(4909086208.0))

  // Test cases with small base
  let small_flt = 1.0e-5F
  assert_true(@math.powf(small_flt, 2.0).is_close(9.999999439624929e-11))
  assert_true(@math.powf(small_flt, 0.5).is_close(0.003162277629598975))

  // Test cases with large base
  let large_flt : Float = 1.0e5
  assert_true(@math.powf(large_flt, 2.0).is_close(10000000000.0))
  assert_true(@math.powf(large_flt, 0.5).is_close(316.2277526855469))

  // Test negative exponent with negative base (where exponent is integer)
  assert_true(@math.powf(-2.0, -4.0).is_close(0.0625))
  assert_true(@math.powf(-2.0, -5.0).is_close(-0.03125))

  // Test fractional exponents with positive base
  assert_true(@math.powf(4.0, 0.5).is_close(2.0))
  assert_true(@math.powf(9.0, 0.5).is_close(3.0))
  assert_true(@math.powf(16.0, 0.25).is_close(2.0))

  // Test powers that should closely approximate known values
  assert_true(@math.powf(10.0, 2.0).is_close(100.0))
  assert_true(@math.powf(10.0, -2.0).is_close(0.009999999776482582))
}

///|
test "pow with standard functions" {
  // Compare with standard mathematical identities

  // Test simple cases of e^x
  let e_flt : Float = 2.7182817459106445
  let x_flt : Float = 2.0
  let expected_exp_flt : Float = 7.3890562
  let actual_pow_flt = @math.powf(e_flt, x_flt)
  assert_true((actual_pow_flt - expected_exp_flt).abs() < 0.01)

  // Test sqrt(x) vs. pow(x, 0.5)
  let values_flt : Array[Float] = [4.0, 9.0, 16.0, 25.0]
  for value in values_flt {
    let expected_sqrt_flt = value.sqrt()
    let actual_pow_flt = @math.powf(value, 0.5)
    assert_true((actual_pow_flt - expected_sqrt_flt).abs() < 0.01)
  }

  // Test pow(x, y) * pow(x, z) = pow(x, y + z)
  let x_test_flt : Float = 3.0
  let y_test_flt : Float = 2.0
  let z_test_flt : Float = 4.0
  let left_val_flt = @math.powf(x_test_flt, y_test_flt) *
    @math.powf(x_test_flt, z_test_flt)
  let right_val_flt = @math.powf(x_test_flt, y_test_flt + z_test_flt)
  assert_true((left_val_flt - right_val_flt).abs() < 0.01)

  // Test pow(x, y)^z = pow(x, y*z)
  let left_test_flt = @math.powf(@math.powf(x_test_flt, y_test_flt), z_test_flt)
  let right_test_flt = @math.powf(x_test_flt, y_test_flt * z_test_flt)
  assert_true((left_test_flt - right_test_flt).abs() < 0.01)
}

///|
test "powf" {
  inspect(@math.powf(1.0, 3.0), content="1")
  inspect(@math.powf(-1.0, 3.0), content="-1")
  inspect(@math.powf(2.0, 3.0), content="8")
  inspect(@math.powf(-2.0, 3.0), content="-8")
  inspect(@math.powf(2.0, -3.0), content="0.125")
  inspect(@math.powf(-2.0, -3.0), content="-0.125")
  inspect(@math.powf(2.0, -3.14), content="0.1134398877620697")
  inspect(@math.powf(-2.0, -3.14), content="NaN")
}

///|
test "powf branch coverage" {
  let near_one = Float::reinterpret_from_int(0x3f7fffff)
  let sub = Float::reinterpret_from_int(1)
  let under = @math.powf(0.5, 1.0e10)
  assert_true(under == 0.0)
  let over = @math.powf(1.5, 1.0e10)
  assert_true(over.is_inf())
  let close = @math.powf(near_one, 1.0e10)
  assert_true(close <= 1.0)
  let sub_res = @math.powf(sub, 2.0)
  assert_true(sub_res == 0.0)
  let interval = @math.powf(1.8, 3.0)
  assert_true(interval > 0.0)
  let overflow_edge = @math.powf(2.0, 128.0)
  assert_true(overflow_edge.is_inf())
  let underflow_deep = @math.powf(2.0, -200.0)
  assert_true(underflow_deep == 0.0)
  let underflow_edge = @math.powf(2.0, -150.0)
  assert_true(underflow_edge == 0.0)
  let subnorm = @math.powf(2.0, -130.0)
  assert_true(subnorm > 0.0)
}

///|
test "pow" {
  let test_cases = [
    (1.1, 1.1, 1.1105342410545758),
    (1.1, 2.2, 1.2332863005546628),
    (1.1, 3.3, 1.3696066657894779),
    (1.1, 4.4, 1.5209950991358059),
    (1.1, 5.5, 1.6891171380665115),
    (1.1, 1.0e-5, 1.0000009531022522),
    (1.1, 2.1e-6, 1.0000002001513977),
    (1.1, 3.2e-7, 1.000000030499258),
    (1.1, 4.3e-8, 1.0000000040983377),
    (1.1, 5.4e-9, 1.000000000514675),
    (1.1, 1.2e5, @double.infinity),
    (1.1, 2.3e6, @double.infinity),
    (1.1, 3.4e7, @double.infinity),
    (1.1, 4.5e8, @double.infinity),
    (1.1, 5.6e9, @double.infinity),
    (1.1, -1.3, 0.8834653263771346),
    (1.1, -2.4, 0.795531820376998),
    (1.1, -3.5, 0.7163505554061548),
    (1.1, -4.6, 0.6450503990997164),
    (1.1, -5.7, 0.5808469250683971),
    (1.1, -1.3e-7, 0.9999999876096767),
    (1.1, -2.4e-8, 0.9999999977125557),
    (1.1, -3.5e-9, 0.9999999996664144),
    (1.1, -4.6e-10, 0.9999999999561573),
    (1.1, -5.7e-11, 0.9999999999945673),
    (1.1, -1.7e5, 0),
    (1.1, -2.8e6, 0),
    (1.1, -3.9e7, 0),
    (1.1, -4.0e8, 0),
    (1.1, -5.1e9, 0),
    (1.1, @double.infinity, @double.infinity),
    (1.1, @double.not_a_number, @double.not_a_number),
    (1.1, @double.neg_infinity, 0),
    (2.2, 1.1, 2.3804822576003546),
    (2.2, 2.2, 5.66669577875008),
    (2.2, 3.3, 13.489468760533386),
    (2.2, 4.4, 32.111441048903984),
    (2.2, 5.5, 76.44071568289563),
    (2.2, 1.0e-5, 1.000007884604687),
    (2.2, 2.1e-6, 1.0000016557618276),
    (2.2, 3.2e-7, 1.0000002523063871),
    (2.2, 4.3e-8, 1.000000033903667),
    (2.2, 5.4e-9, 1.0000000042576698),
    (2.2, 1.2e5, @double.infinity),
    (2.2, 2.3e6, @double.infinity),
    (2.2, 3.4e7, @double.infinity),
    (2.2, 4.5e8, @double.infinity),
    (2.2, 5.6e9, @double.infinity),
    (2.2, -1.3, 0.35879841422373565),
    (2.2, -2.4, 0.15072509491644878),
    (2.2, -3.5, 0.0633170419293052),
    (2.2, -4.6, 0.026598409514352772),
    (2.2, -5.7, 0.011173538231352035),
    (2.2, -1.3e-7, 0.9999998975005484),
    (2.2, -2.4e-8, 0.9999999810770235),
    (2.2, -3.5e-9, 0.9999999972403992),
    (2.2, -4.6e-10, 0.9999999996373096),
    (2.2, -5.7e-11, 0.999999999955058),
    (2.2, -1.7e5, 0),
    (2.2, -2.8e6, 0),
    (2.2, -3.9e7, 0),
    (2.2, -4.0e8, 0),
    (2.2, -5.1e9, 0),
    (2.2, @double.infinity, @double.infinity),
    (2.2, @double.not_a_number, @double.not_a_number),
    (2.2, @double.neg_infinity, 0),
    (3.3, 1.1, 3.718479005997499),
    (3.3, 2.2, 13.827086118044146),
    (3.3, 3.3, 51.415729444066585),
    (3.3, 4.4, 191.18831051580915),
    (3.3, 5.5, 710.9297188451668),
    (3.3, 1.0e-5, 1.0000119392959574),
    (3.3, 2.1e-6, 1.000002507240327),
    (3.3, 3.2e-7, 1.000000382055263),
    (3.3, 4.3e-8, 1.0000000513386675),
    (3.3, 5.4e-9, 1.0000000064471815),
    (3.3, 1.2e5, @double.infinity),
    (3.3, 2.3e6, @double.infinity),
    (3.3, 3.4e7, @double.infinity),
    (3.3, 4.5e8, @double.infinity),
    (3.3, 5.6e9, @double.infinity),
    (3.3, -1.3, 0.21180288829407456),
    (3.3, -2.4, 0.05695954930832198),
    (3.3, -3.5, 0.015317969851773392),
    (3.3, -4.6, 0.0041194181349598034),
    (3.3, -5.7, 0.0011078234214353857),
    (3.3, -1.3e-7, 0.9999998447900912),
    (3.3, -2.4e-8, 0.9999999713458612),
    (3.3, -3.5e-9, 0.9999999958212714),
    (3.3, -4.6e-10, 0.9999999994507957),
    (3.3, -5.7e-11, 0.9999999999319464),
    (3.3, -1.7e5, 0),
    (3.3, -2.8e6, 0),
    (3.3, -3.9e7, 0),
    (3.3, -4.0e8, 0),
    (3.3, -5.1e9, 0),
    (3.3, @double.infinity, @double.infinity),
    (3.3, @double.not_a_number, @double.not_a_number),
    (3.3, @double.neg_infinity, 0),
    (4.4, 1.1, 5.102675423469089),
    (4.4, 2.2, 26.037296477275444),
    (4.4, 3.3, 132.8598728281716),
    (4.4, 4.4, 677.9408078455402),
    (4.4, 5.5, 3459.3118987602156),
    (4.4, 1.0e-5, 1.0000148161551674),
    (4.4, 2.1e-6, 1.0000031113743764),
    (4.4, 3.2e-7, 1.0000004741135655),
    (4.4, 4.3e-8, 1.0000000637089972),
    (4.4, 5.4e-9, 1.0000000080006646),
    (4.4, 1.2e5, @double.infinity),
    (4.4, 2.3e6, @double.infinity),
    (4.4, 3.4e7, @double.infinity),
    (4.4, 4.5e8, @double.infinity),
    (4.4, 5.6e9, @double.infinity),
    (4.4, -1.3, 0.14571743588102323),
    (4.4, -2.4, 0.0285570654192142),
    (4.4, -3.5, 0.005596488714110584),
    (4.4, -4.6, 0.0010967753677551722),
    (4.4, -5.7, 0.00021494123704413892),
    (4.4, -1.3e-7, 0.9999998073914282),
    (4.4, -2.4e-8, 0.9999999644414916),
    (4.4, -3.5e-9, 0.9999999948143842),
    (4.4, -4.6e-10, 0.999999999318462),
    (4.4, -5.7e-11, 0.9999999999155486),
    (4.4, -1.7e5, 0),
    (4.4, -2.8e6, 0),
    (4.4, -3.9e7, 0),
    (4.4, -4.0e8, 0),
    (4.4, -5.1e9, 0),
    (4.4, @double.infinity, @double.infinity),
    (4.4, @double.not_a_number, @double.not_a_number),
    (4.4, @double.neg_infinity, 0),
    (5.5, 1.1, 6.522272782452906),
    (5.5, 2.2, 42.54004224872598),
    (5.5, 3.3, 277.457759723262),
    (5.5, 4.4, 1809.655194523391),
    (5.5, 5.5, 11803.064820864423),
    (5.5, 1.0e-5, 1.0000170476262316),
    (5.5, 2.1e-6, 1.0000035799774019),
    (5.5, 3.2e-7, 1.0000005455195382),
    (5.5, 4.3e-8, 1.0000000733041707),
    (5.5, 5.4e-9, 1.0000000092056398),
    (5.5, 1.2e5, @double.infinity),
    (5.5, 2.3e6, @double.infinity),
    (5.5, 3.4e7, @double.infinity),
    (5.5, 4.5e8, @double.infinity),
    (5.5, 5.6e9, @double.infinity),
    (5.5, -1.3, 0.10902560458273548),
    (5.5, -2.4, 0.016715891564065034),
    (5.5, -3.5, 0.002562893660172627),
    (5.5, -4.6, 0.00039294487453325625),
    (5.5, -5.7, 0.00006024661764997149),
    (5.5, -1.3e-7, 0.9999997783827725),
    (5.5, -2.4e-8, 0.9999999590860467),
    (5.5, -3.5e-9, 0.9999999940333817),
    (5.5, -4.6e-10, 0.9999999992158158),
    (5.5, -5.7e-11, 0.9999999999028294),
    (5.5, -1.7e5, 0),
    (5.5, -2.8e6, 0),
    (5.5, -3.9e7, 0),
    (5.5, -4.0e8, 0),
    (5.5, -5.1e9, 0),
    (5.5, @double.infinity, @double.infinity),
    (5.5, @double.not_a_number, @double.not_a_number),
    (5.5, @double.neg_infinity, 0),
    (1.0e-5, 1.1, 0.0000031622776601683762),
    (1.0e-5, 2.2, 9.999999999999982e-12),
    (1.0e-5, 3.3, 3.162277660168387e-17),
    (1.0e-5, 4.4, 9.999999999999963e-23),
    (1.0e-5, 5.5, 3.1622776601683807e-28),
    (1.0e-5, 1.0e-5, 0.9998848773724686),
    (1.0e-5, 2.1e-6, 0.9999758231487883),
    (1.0e-5, 3.2e-7, 0.9999963158706376),
    (1.0e-5, 4.3e-8, 0.9999995049443275),
    (1.0e-5, 5.4e-9, 0.9999999378302045),
    (1.0e-5, 1.2e5, 0),
    (1.0e-5, 2.3e6, 0),
    (1.0e-5, 3.4e7, 0),
    (1.0e-5, 4.5e8, 0),
    (1.0e-5, 5.6e9, 0),
    (1.0e-5, -1.3, 3162277.6601683805),
    (1.0e-5, -2.4, 999999999999.9988),
    (1.0e-5, -3.5, 316227766016837800),
    (1.0e-5, -4.6, 9.999999999999956e+22),
    (1.0e-5, -5.7, 3.1622776601683843e+28),
    (1.0e-5, -1.3e-7, 1.0000014966814306),
    (1.0e-5, -2.4e-8, 1.0000002763102493),
    (1.0e-5, -3.5e-9, 1.00000004029524),
    (1.0e-5, -4.6e-10, 1.0000000052959457),
    (1.0e-5, -5.7e-11, 1.0000000006562368),
    (1.0e-5, -1.7e5, @double.infinity),
    (1.0e-5, -2.8e6, @double.infinity),
    (1.0e-5, -3.9e7, @double.infinity),
    (1.0e-5, -4.0e8, @double.infinity),
    (1.0e-5, -5.1e9, @double.infinity),
    (1.0e-5, @double.infinity, 0),
    (1.0e-5, @double.not_a_number, @double.not_a_number),
    (1.0e-5, @double.neg_infinity, @double.infinity),
    (2.1e-6, 1.1, 5.68121498915637e-7),
    (2.1e-6, 2.2, 3.227620375301501e-13),
    (2.1e-6, 3.3, 1.83368052554695e-19),
    (2.1e-6, 4.4, 1.0417533287061401e-25),
    (2.1e-6, 5.5, 5.9184246260489e-32),
    (2.1e-6, 1.0e-5, 0.9998692728134111),
    (2.1e-6, 2.1e-6, 0.9999725458731237),
    (2.1e-6, 3.2e-7, 0.9999958164653228),
    (2.1e-6, 4.3e-8, 0.9999994378365098),
    (2.1e-6, 5.4e-9, 0.9999999294027071),
    (2.1e-6, 1.2e5, 0),
    (2.1e-6, 2.3e6, 0),
    (2.1e-6, 3.4e7, 0),
    (2.1e-6, 4.5e8, 0),
    (2.1e-6, 5.6e9, 0),
    (2.1e-6, -1.3, 24049990.92567991),
    (2.1e-6, -2.4, 42332478125865.01),
    (2.1e-6, -3.5, 74513071951447410000),
    (2.1e-6, -4.6, 1.3115693050459929e+26),
    (2.1e-6, -5.7, 2.3086070630126982e+32),
    (2.1e-6, -1.3e-7, 1.000001699565962),
    (2.1e-6, -2.4e-8, 1.0000003137658064),
    (2.1e-6, -3.5e-9, 1.0000000457575073),
    (2.1e-6, -4.6e-10, 1.0000000060138436),
    (2.1e-6, -5.7e-11, 1.0000000007451937),
    (2.1e-6, -1.7e5, @double.infinity),
    (2.1e-6, -2.8e6, @double.infinity),
    (2.1e-6, -3.9e7, @double.infinity),
    (2.1e-6, -4.0e8, @double.infinity),
    (2.1e-6, -5.1e9, @double.infinity),
    (2.1e-6, @double.infinity, 0),
    (2.1e-6, @double.not_a_number, @double.not_a_number),
    (2.1e-6, @double.neg_infinity, @double.infinity),
    (3.2e-7, 1.1, 7.172407832612147e-8),
    (3.2e-7, 2.2, 5.144343411731606e-15),
    (3.2e-7, 3.3, 3.6897328979950713e-22),
    (3.2e-7, 4.4, 2.646426913782639e-29),
    (3.2e-7, 5.5, 1.8981253124850313e-36),
    (3.2e-7, 1.0e-5, 0.9998504617335499),
    (3.2e-7, 2.1e-6, 0.9999685951089775),
    (3.2e-7, 3.2e-7, 0.9999952144291017),
    (3.2e-7, 4.3e-8, 0.9999993569375786),
    (3.2e-7, 5.4e-9, 0.9999999192433011),
    (3.2e-7, 1.2e5, 0),
    (3.2e-7, 2.3e6, 0),
    (3.2e-7, 3.4e7, 0),
    (3.2e-7, 4.5e8, 0),
    (3.2e-7, 5.6e9, 0),
    (3.2e-7, -1.3, 277526863.95170367),
    (3.2e-7, -2.4, 3869368145657010),
    (3.2e-7, -3.5, 5.3947966093944355e+22),
    (3.2e-7, -4.6, 7.521597677233097e+29),
    (3.2e-7, -5.7, 1.048685163026184e+37),
    (3.2e-7, -1.3e-7, 1.0000019441447192),
    (3.2e-7, -2.4e-8, 1.0000003589187405),
    (3.2e-7, -3.5e-9, 1.0000000523423083),
    (3.2e-7, -4.6e-10, 1.0000000068792747),
    (3.2e-7, -5.7e-11, 1.000000000852432),
    (3.2e-7, -1.7e5, @double.infinity),
    (3.2e-7, -2.8e6, @double.infinity),
    (3.2e-7, -3.9e7, @double.infinity),
    (3.2e-7, -4.0e8, @double.infinity),
    (3.2e-7, -5.1e9, @double.infinity),
    (3.2e-7, @double.infinity, 0),
    (3.2e-7, @double.not_a_number, @double.not_a_number),
    (3.2e-7, @double.neg_infinity, @double.infinity),
    (4.3e-8, 1.1, 7.885246986931752e-9),
    (4.3e-8, 2.2, 6.217712004491629e-17),
    (4.3e-8, 3.3, 4.902819484902738e-25),
    (4.3e-8, 4.4, 3.865994257079931e-33),
    (4.3e-8, 5.5, 3.048431956713522e-41),
    (4.3e-8, 1.0e-5, 0.9998303937275578),
    (4.3e-8, 2.1e-6, 0.9999643802963821),
    (4.3e-8, 3.2e-7, 0.9999945721537),
    (4.3e-8, 4.3e-8, 0.99999927063144),
    (4.3e-8, 5.4e-9, 0.9999999084048493),
    (4.3e-8, 1.2e5, 0),
    (4.3e-8, 2.3e6, 0),
    (4.3e-8, 3.4e7, 0),
    (4.3e-8, 4.5e8, 0),
    (4.3e-8, 5.6e9, 0),
    (4.3e-8, -1.3, 3771299362.935219),
    (4.3e-8, -2.4, 478272826353491800),
    (4.3e-8, -3.5, 6.065413387128329e+25),
    (4.3e-8, -4.6, 7.692103236817457e+33),
    (4.3e-8, -5.7, 9.755056816312366e+41),
    (4.3e-8, -1.3e-7, 1.000002205070975),
    (4.3e-8, -2.4e-8, 1.0000004070896602),
    (4.3e-8, -3.5e-9, 1.0000000593672318),
    (4.3e-8, -4.6e-10, 1.0000000078025502),
    (4.3e-8, -5.7e-11, 1.0000000009668377),
    (4.3e-8, -1.7e5, @double.infinity),
    (4.3e-8, -2.8e6, @double.infinity),
    (4.3e-8, -3.9e7, @double.infinity),
    (4.3e-8, -4.0e8, @double.infinity),
    (4.3e-8, -5.1e9, @double.infinity),
    (4.3e-8, @double.infinity, 0),
    (4.3e-8, @double.not_a_number, @double.not_a_number),
    (4.3e-8, @double.neg_infinity, @double.infinity),
    (5.4e-9, 1.1, 8.046983962849195e-10),
    (5.4e-9, 2.2, 6.475395089835214e-19),
    (5.4e-9, 3.3, 5.210740044101683e-28),
    (5.4e-9, 4.4, 4.1930741569462e-37),
    (5.4e-9, 5.5, 3.3741600495983767e-46),
    (5.4e-9, 1.0e-5, 0.9998096494501315),
    (5.4e-9, 2.1e-6, 0.9999600233786313),
    (5.4e-9, 3.2e-7, 0.9999939082211523),
    (5.4e-9, 4.3e-8, 0.9999991814150591),
    (5.4e-9, 5.4e-9, 0.9999998972009241),
    (5.4e-9, 1.2e5, 0),
    (5.4e-9, 2.3e6, 0),
    (5.4e-9, 3.4e7, 0),
    (5.4e-9, 4.5e8, 0),
    (5.4e-9, 5.6e9, 0),
    (5.4e-9, -1.3, 55961340909.73872),
    (5.4e-9, -2.4, 69543248958985440000),
    (5.4e-9, -3.5, 8.64215080830884e+28),
    (5.4e-9, -4.6, 1.0739614802523902e+38),
    (5.4e-9, -5.7, 1.3346136704268286e+47),
    (5.4e-9, -1.3e-7, 1.0000024747957572),
    (5.4e-9, -2.4e-8, 1.0000004568849097),
    (5.4e-9, -3.5e-9, 1.0000000666290363),
    (5.4e-9, -4.6e-10, 1.0000000087569587),
    (5.4e-9, -5.7e-11, 1.0000000010851013),
    (5.4e-9, -1.7e5, @double.infinity),
    (5.4e-9, -2.8e6, @double.infinity),
    (5.4e-9, -3.9e7, @double.infinity),
    (5.4e-9, -4.0e8, @double.infinity),
    (5.4e-9, -5.1e9, @double.infinity),
    (5.4e-9, @double.infinity, 0),
    (5.4e-9, @double.not_a_number, @double.not_a_number),
    (5.4e-9, @double.neg_infinity, @double.infinity),
    (1.2e5, 1.1, 386455.39155829826),
    (1.2e5, 2.2, 149347769664.47763),
    (1.2e5, 3.3, 57716250804043944),
    (1.2e5, 4.4, 2.2304756303753866e+22),
    (1.2e5, 5.5, 8.619793330979577e+27),
    (1.2e5, 1.0e-5, 1.0001169593094243),
    (1.2e5, 2.1e-6, 1.0000245603203455),
    (1.2e5, 3.2e-7, 1.00000374248605),
    (1.2e5, 4.3e-8, 1.0000005028957484),
    (1.2e5, 5.4e-9, 1.000000063154336),
    (1.2e5, 1.2e5, @double.infinity),
    (1.2e5, 2.3e6, @double.infinity),
    (1.2e5, 3.4e7, @double.infinity),
    (1.2e5, 4.5e8, @double.infinity),
    (1.2e5, 5.6e9, @double.infinity),
    (1.2e5, -1.3, 2.4949645549379676e-7),
    (1.2e5, -2.4, 6.456022116492064e-13),
    (1.2e5, -3.5, 1.6705736955718338e-18),
    (1.2e5, -4.6, 4.322811201664475e-24),
    (1.2e5, -5.7, 1.1185796073988373e-29),
    (1.2e5, -1.3e-7, 0.999998479619043),
    (1.2e5, -2.4e-8, 0.9999997193141109),
    (1.2e5, -3.5e-9, 0.9999999590666363),
    (1.2e5, -4.6e-10, 0.9999999946201864),
    (1.2e5, -5.7e-11, 0.9999999993333709),
    (1.2e5, -1.7e5, 0),
    (1.2e5, -2.8e6, 0),
    (1.2e5, -3.9e7, 0),
    (1.2e5, -4.0e8, 0),
    (1.2e5, -5.1e9, 0),
    (1.2e5, @double.infinity, @double.infinity),
    (1.2e5, @double.not_a_number, @double.not_a_number),
    (1.2e5, @double.neg_infinity, 0),
    (2.3e6, 1.1, 9951776.630147615),
    (2.3e6, 2.2, 99037858096352.22),
    (2.3e6, 3.3, 985602641703147300000),
    (2.3e6, 4.4, 9.808497336313198e+27),
    (2.3e6, 5.5, 9.761197456838618e+34),
    (2.3e6, 1.0e-5, 1.000146494926143),
    (2.3e6, 2.1e-6, 1.0000307621544753),
    (2.3e6, 3.2e-7, 1.0000046875052842),
    (2.3e6, 4.3e-8, 1.0000006298822446),
    (2.3e6, 5.4e-9, 1.0000000791014694),
    (2.3e6, 1.2e5, @double.infinity),
    (2.3e6, 2.3e6, @double.infinity),
    (2.3e6, 3.4e7, @double.infinity),
    (2.3e6, 4.5e8, @double.infinity),
    (2.3e6, 5.6e9, @double.infinity),
    (2.3e6, -1.3, 5.3672745751358e-9),
    (2.3e6, -2.4, 5.393282802265032e-16),
    (2.3e6, -3.5, 5.419417057580233e-23),
    (2.3e6, -4.6, 5.44567795177682e-30),
    (2.3e6, -5.7, 5.4720660985092965e-37),
    (2.3e6, -1.3e-7, 0.9999980957072546),
    (2.3e6, -2.4e-8, 0.9999996484379895),
    (2.3e6, -3.5e-9, 0.9999999487305324),
    (2.3e6, -4.6e-10, 0.999999993261727),
    (2.3e6, -5.7e-11, 0.9999999991650401),
    (2.3e6, -1.7e5, 0),
    (2.3e6, -2.8e6, 0),
    (2.3e6, -3.9e7, 0),
    (2.3e6, -4.0e8, 0),
    (2.3e6, -5.1e9, 0),
    (2.3e6, @double.infinity, @double.infinity),
    (2.3e6, @double.not_a_number, @double.not_a_number),
    (2.3e6, @double.neg_infinity, 0),
    (3.4e7, 1.1, 192586929.35759524),
    (3.4e7, 2.2, 37089725359387384),
    (3.4e7, 3.3, 7.142996317680891e+24),
    (3.4e7, 4.4, 1.3756477272347834e+33),
    (3.4e7, 5.5, 2.6493177166589964e+41),
    (3.4e7, 1.0e-5, 1.0001734337487198),
    (3.4e7, 2.1e-6, 1.0000364185924142),
    (3.4e7, 3.2e-7, 1.0000055494141444),
    (3.4e7, 4.3e-8, 1.0000007457007345),
    (3.4e7, 5.4e-9, 1.0000000936461082),
    (3.4e7, 1.2e5, @double.infinity),
    (3.4e7, 2.3e6, @double.infinity),
    (3.4e7, 3.4e7, @double.infinity),
    (3.4e7, 4.5e8, @double.infinity),
    (3.4e7, 5.6e9, @double.infinity),
    (3.4e7, -1.3, 1.6183684669395333e-10),
    (3.4e7, -2.4, 8.403314141504143e-19),
    (3.4e7, -3.5, 4.363387572321108e-27),
    (3.4e7, -4.6, 2.265671708290861e-35),
    (3.4e7, -5.7, 1.1764410574738154e-43),
    (3.4e7, -1.3e-7, 0.9999977455593005),
    (3.4e7, -2.4e-8, 0.9999995837951806),
    (3.4e7, -3.5e-9, 0.9999999393034531),
    (3.4e7, -4.6e-10, 0.9999999920227394),
    (3.4e7, -5.7e-11, 0.9999999990115134),
    (3.4e7, -1.7e5, 0),
    (3.4e7, -2.8e6, 0),
    (3.4e7, -3.9e7, 0),
    (3.4e7, -4.0e8, 0),
    (3.4e7, -5.1e9, 0),
    (3.4e7, @double.infinity, @double.infinity),
    (3.4e7, @double.not_a_number, @double.not_a_number),
    (3.4e7, @double.neg_infinity, 0),
    (4.5e8, 1.1, 3300150646.401208),
    (4.5e8, 2.2, 10890994288942311000),
    (4.5e8, 3.3, 3.5941921842604514e+28),
    (4.5e8, 4.4, 1.1861375660177403e+38),
    (4.5e8, 5.5, 3.914432655214167e+47),
    (4.5e8, 1.0e-5, 1.000199267432525),
    (4.5e8, 2.1e-6, 1.000041842867484),
    (4.5e8, 3.2e-7, 1.0000063759429312),
    (4.5e8, 4.3e-8, 1.000000856764967),
    (4.5e8, 5.4e-9, 1.0000001075936997),
    (4.5e8, 1.2e5, @double.infinity),
    (4.5e8, 2.3e6, @double.infinity),
    (4.5e8, 3.4e7, @double.infinity),
    (4.5e8, 4.5e8, @double.infinity),
    (4.5e8, 5.6e9, @double.infinity),
    (4.5e8, -1.3, 5.634089375820785e-12),
    (4.5e8, -2.4, 1.7072218754512757e-21),
    (4.5e8, -3.5, 5.173163465470856e-31),
    (4.5e8, -4.6, 1.5675537330734282e-40),
    (4.5e8, -5.7, 4.749945990443864e-50),
    (4.5e8, -1.3e-7, 0.9999974097847963),
    (4.5e8, -2.4e-8, 0.999999521805919),
    (4.5e8, -3.5e-9, 0.999999930263349),
    (4.5e8, -4.6e-10, 0.9999999908346113),
    (4.5e8, -5.7e-11, 0.9999999988642888),
    (4.5e8, -1.7e5, 0),
    (4.5e8, -2.8e6, 0),
    (4.5e8, -3.9e7, 0),
    (4.5e8, -4.0e8, 0),
    (4.5e8, -5.1e9, 0),
    (4.5e8, @double.infinity, @double.infinity),
    (4.5e8, @double.not_a_number, @double.not_a_number),
    (4.5e8, @double.neg_infinity, 0),
    (5.6e9, 1.1, 52845356216.05751),
    (5.6e9, 2.2, 2.792631673602008e+21),
    (5.6e9, 3.3, 1.4757761557174151e+32),
    (5.6e9, 4.4, 7.798791664405154e+42),
    (5.6e9, 5.5, 4.121299235603064e+53),
    (5.6e9, 1.0e-5, 1.0002244855174505),
    (5.6e9, 2.1e-6, 1.000047137779063),
    (5.6e9, 3.2e-7, 1.000007182756175),
    (5.6e9, 4.3e-8, 1.0000009651798605),
    (5.6e9, 5.4e-9, 1.0000001212085825),
    (5.6e9, 1.2e5, @double.infinity),
    (5.6e9, 2.3e6, @double.infinity),
    (5.6e9, 3.4e7, @double.infinity),
    (5.6e9, 4.5e8, @double.infinity),
    (5.6e9, 5.6e9, @double.infinity),
    (5.6e9, -1.3, 2.1249835131503997e-13),
    (5.6e9, -2.4, 4.021135754033797e-24),
    (5.6e9, -3.5, 7.609250919973817e-35),
    (5.6e9, -4.6, 1.4399090979467666e-45),
    (5.6e9, -5.7, 2.7247599430680413e-56),
    (5.6e9, -1.3e-7, 0.9999970820200408),
    (5.6e9, -2.4e-8, 0.9999994612953667),
    (5.6e9, -3.5e-9, 0.9999999214388896),
    (5.6e9, -4.6e-10, 0.9999999896748252),
    (5.6e9, -5.7e-11, 0.9999999987205761),
    (5.6e9, -1.7e5, 0),
    (5.6e9, -2.8e6, 0),
    (5.6e9, -3.9e7, 0),
    (5.6e9, -4.0e8, 0),
    (5.6e9, -5.1e9, 0),
    (5.6e9, @double.infinity, @double.infinity),
    (5.6e9, @double.not_a_number, @double.not_a_number),
    (5.6e9, @double.neg_infinity, 0),
    (-1.3, 1.1, @double.not_a_number),
    (-1.3, 2.2, @double.not_a_number),
    (-1.3, 3.3, @double.not_a_number),
    (-1.3, 4.4, @double.not_a_number),
    (-1.3, 5.5, @double.not_a_number),
    (-1.3, 1.0e-5, @double.not_a_number),
    (-1.3, -4.6e-10, @double.not_a_number),
    (-1.3, -5.7e-11, @double.not_a_number),
    (-1.3, -1.7e5, 0),
    (-1.3, -2.8e6, 0),
    (-1.3, -3.9e7, 0),
    (-1.3, -4.0e8, 0),
    (-1.3, -5.1e9, 0),
    (-1.3, @double.infinity, @double.infinity),
    (-1.3, @double.not_a_number, @double.not_a_number),
    (-1.3, @double.neg_infinity, 0),
    (-2.4, 1.1, @double.not_a_number),
    (-2.4, 2.2, @double.not_a_number),
    (-2.4, -1.3e-7, @double.not_a_number),
    (-2.4, -2.4e-8, @double.not_a_number),
    (-2.4, -3.5e-9, @double.not_a_number),
    (-2.4, -4.6e-10, @double.not_a_number),
    (-2.4, -5.7e-11, @double.not_a_number),
    (-2.4, -1.7e5, 0),
    (-2.4, -2.8e6, 0),
    (-2.4, -3.9e7, 0),
    (-2.4, -4.0e8, 0),
    (-2.4, -5.1e9, 0),
    (-2.4, @double.infinity, @double.infinity),
    (-2.4, @double.not_a_number, @double.not_a_number),
    (-2.4, @double.neg_infinity, 0),
    (-3.5, 1.1, @double.not_a_number),
    (-3.5, 2.2, @double.not_a_number),
    (-3.5, 3.3, @double.not_a_number),
    (-3.5, 4.4, @double.not_a_number),
    (-3.5, 5.5, @double.not_a_number),
    (-3.5, 1.0e-5, @double.not_a_number),
    (-3.5, 2.1e-6, @double.not_a_number),
    (-3.5, 3.2e-7, @double.not_a_number),
    (-3.5, 4.3e-8, @double.not_a_number),
    (-3.5, 5.4e-9, @double.not_a_number),
    (-3.5, 1.2e5, @double.infinity),
    (-3.5, -4.6e-10, @double.not_a_number),
    (-3.5, -5.7e-11, @double.not_a_number),
    (-3.5, -1.7e5, 0),
    (-3.5, -2.8e6, 0),
    (-3.5, -3.9e7, 0),
    (-3.5, -4.0e8, 0),
    (-3.5, -5.1e9, 0),
    (-3.5, @double.infinity, @double.infinity),
    (-3.5, @double.not_a_number, @double.not_a_number),
    (-3.5, @double.neg_infinity, 0),
    (-4.6, 1.1, @double.not_a_number),
    (-4.6, 2.2, @double.not_a_number),
    (-4.6, 3.3, @double.not_a_number),
    (-4.6, -4.6, @double.not_a_number),
    (-4.6, -5.7, @double.not_a_number),
    (-4.6, -1.3e-7, @double.not_a_number),
    (-4.6, -2.4e-8, @double.not_a_number),
    (-4.6, -3.5e-9, @double.not_a_number),
    (-4.6, -4.6e-10, @double.not_a_number),
    (-4.6, -5.7e-11, @double.not_a_number),
    (-4.6, -1.7e5, 0),
    (-4.6, -2.8e6, 0),
    (-4.6, -3.9e7, 0),
    (-4.6, -4.0e8, 0),
    (-4.6, -5.1e9, 0),
    (-4.6, @double.infinity, @double.infinity),
    (-4.6, @double.not_a_number, @double.not_a_number),
    (-4.6, @double.neg_infinity, 0),
    (-5.7, 1.1, @double.not_a_number),
    (-5.7, 2.2, @double.not_a_number),
    (-5.7, 3.3, @double.not_a_number),
    (-5.7, 4.4, @double.not_a_number),
    (-5.7, 5.5, @double.not_a_number),
    (-5.7, 1.0e-5, @double.not_a_number),
    (-5.7, 2.1e-6, @double.not_a_number),
    (-5.7, 3.2e-7, @double.not_a_number),
    (-5.7, 4.3e-8, @double.not_a_number),
    (-5.7, 5.4e-9, @double.not_a_number),
    (-5.7, 1.2e5, @double.infinity),
    (-5.7, 5.6e9, @double.infinity),
    (-5.7, -1.3, @double.not_a_number),
    (-5.7, -2.4, @double.not_a_number),
    (-5.7, -3.5, @double.not_a_number),
    (-5.7, -4.6e-10, @double.not_a_number),
    (-5.7, -5.7e-11, @double.not_a_number),
    (-5.7, -1.7e5, 0),
    (-5.7, -2.8e6, 0),
    (-5.7, -3.9e7, 0),
    (-5.7, -4.0e8, 0),
    (-5.7, -5.1e9, 0),
    (-5.7, @double.infinity, @double.infinity),
    (-5.7, @double.not_a_number, @double.not_a_number),
    (-5.7, @double.neg_infinity, 0),
    (-1.3e-7, 1.1, @double.not_a_number),
    (-1.3e-7, 2.2, @double.not_a_number),
    (-1.3e-7, 3.3, @double.not_a_number),
    (-1.3e-7, 4.4, @double.not_a_number),
    (-1.3e-7, 5.5, @double.not_a_number),
    (-1.3e-7, 1.0e-5, @double.not_a_number),
    (-1.3e-7, 2.1e-6, @double.not_a_number),
    (-1.3e-7, 3.2e-7, @double.not_a_number),
    (-1.3e-7, 4.3e-8, @double.not_a_number),
    (-1.3e-7, 5.4e-9, @double.not_a_number),
    (-1.3e-7, 1.2e5, 0),
    (-1.3e-7, 2.3e6, 0),
    (-1.3e-7, 3.4e7, 0),
    (-1.3e-7, 4.5e8, 0),
    (-1.3e-7, 5.6e9, 0),
    (-1.3e-7, -1.3, @double.not_a_number),
    (-1.3e-7, -2.4, @double.not_a_number),
    (-1.3e-7, -3.5, @double.not_a_number),
    (-1.3e-7, -1.3e-7, @double.not_a_number),
    (-1.3e-7, -2.4e-8, @double.not_a_number),
    (-1.3e-7, -4.6e-10, @double.not_a_number),
    (-1.3e-7, -5.7e-11, @double.not_a_number),
    (-1.3e-7, -1.7e5, @double.infinity),
    (-1.3e-7, -2.8e6, @double.infinity),
    (-1.3e-7, -3.9e7, @double.infinity),
    (-1.3e-7, -4.0e8, @double.infinity),
    (-1.3e-7, -5.1e9, @double.infinity),
    (-1.3e-7, @double.infinity, 0),
    (-1.3e-7, @double.not_a_number, @double.not_a_number),
    (-1.3e-7, @double.neg_infinity, @double.infinity),
    (-2.4e-8, 1.1, @double.not_a_number),
    (-2.4e-8, 2.2, @double.not_a_number),
    (-2.4e-8, 3.3, @double.not_a_number),
    (-2.4e-8, 4.3e-8, @double.not_a_number),
    (-2.4e-8, 5.4e-9, @double.not_a_number),
    (-2.4e-8, 1.2e5, 0),
    (-2.4e-8, 2.3e6, 0),
    (-2.4e-8, 3.4e7, 0),
    (-2.4e-8, 4.5e8, 0),
    (-2.4e-8, 5.6e9, 0),
    (-2.4e-8, -1.3, @double.not_a_number),
    (-2.4e-8, -2.4, @double.not_a_number),
    (-2.4e-8, -3.5, @double.not_a_number),
    (-2.4e-8, -4.6, @double.not_a_number),
    (-2.4e-8, -4.0e8, @double.infinity),
    (-2.4e-8, -5.1e9, @double.infinity),
    (-2.4e-8, @double.infinity, 0),
    (-2.4e-8, @double.not_a_number, @double.not_a_number),
    (-2.4e-8, @double.neg_infinity, @double.infinity),
    (-3.5e-9, 1.1, @double.not_a_number),
    (-3.5e-9, 4.3e-8, @double.not_a_number),
    (-3.5e-9, 5.4e-9, @double.not_a_number),
    (-3.5e-9, 1.2e5, 0),
    (-3.5e-9, 2.3e6, 0),
    (-3.5e-9, 3.4e7, 0),
    (-3.5e-9, 4.5e8, 0),
    (-3.5e-9, 5.6e9, 0),
    (-3.5e-9, -1.3, @double.not_a_number),
    (-3.5e-9, -2.4, @double.not_a_number),
    (-3.5e-9, -3.5, @double.not_a_number),
    (-3.5e-9, -4.6, @double.not_a_number),
    (-3.5e-9, -5.7, @double.not_a_number),
    (-3.5e-9, -1.3e-7, @double.not_a_number),
    (-3.5e-9, -2.4e-8, @double.not_a_number),
    (-3.5e-9, -3.5e-9, @double.not_a_number),
    (-3.5e-9, -4.6e-10, @double.not_a_number),
    (-3.5e-9, -5.7e-11, @double.not_a_number),
    (-3.5e-9, -1.7e5, @double.infinity),
    (-3.5e-9, -2.8e6, @double.infinity),
    (-3.5e-9, -3.9e7, @double.infinity),
    (-3.5e-9, -4.0e8, @double.infinity),
    (-3.5e-9, -5.1e9, @double.infinity),
    (-3.5e-9, @double.infinity, 0),
    (-3.5e-9, @double.not_a_number, @double.not_a_number),
    (-3.5e-9, @double.neg_infinity, @double.infinity),
    (-4.6e-10, 1.1, @double.not_a_number),
    (-4.6e-10, 2.2, @double.not_a_number),
    (-4.6e-10, 3.3, @double.not_a_number),
    (-4.6e-10, 4.4, @double.not_a_number),
    (-4.6e-10, 5.5, @double.not_a_number),
    (-4.6e-10, 1.0e-5, @double.not_a_number),
    (-4.6e-10, 2.1e-6, @double.not_a_number),
    (-4.6e-10, 3.2e-7, @double.not_a_number),
    (-4.6e-10, 4.3e-8, @double.not_a_number),
    (-4.6e-10, 5.4e-9, @double.not_a_number),
    (-4.6e-10, 1.2e5, 0),
    (-4.6e-10, 2.3e6, 0),
    (-4.6e-10, 3.4e7, 0),
    (-4.6e-10, 4.5e8, 0),
    (-4.6e-10, 5.6e9, 0),
    (-4.6e-10, -1.3, @double.not_a_number),
    (-4.6e-10, -2.4, @double.not_a_number),
    (-4.6e-10, -3.5, @double.not_a_number),
    (-4.6e-10, -4.6, @double.not_a_number),
    (-4.6e-10, -5.7, @double.not_a_number),
    (-4.6e-10, -1.3e-7, @double.not_a_number),
    (-4.6e-10, -2.4e-8, @double.not_a_number),
    (-4.6e-10, -3.5e-9, @double.not_a_number),
    (-4.6e-10, -4.6e-10, @double.not_a_number),
    (-4.6e-10, -5.7e-11, @double.not_a_number),
    (-4.6e-10, -1.7e5, @double.infinity),
    (-4.6e-10, -2.8e6, @double.infinity),
    (-4.6e-10, -3.9e7, @double.infinity),
    (-4.6e-10, -4.0e8, @double.infinity),
    (-4.6e-10, -5.1e9, @double.infinity),
    (-4.6e-10, @double.infinity, 0),
    (-4.6e-10, @double.not_a_number, @double.not_a_number),
    (-4.6e-10, @double.neg_infinity, @double.infinity),
    (-5.7e-11, 1.1, @double.not_a_number),
    (-5.7e-11, 2.2, @double.not_a_number),
    (-5.7e-11, 3.3, @double.not_a_number),
    (-5.7e-11, 4.4, @double.not_a_number),
    (-5.7e-11, 5.5, @double.not_a_number),
    (-5.7e-11, 1.0e-5, @double.not_a_number),
    (-5.7e-11, 2.1e-6, @double.not_a_number),
    (-5.7e-11, 3.2e-7, @double.not_a_number),
    (-5.7e-11, 4.3e-8, @double.not_a_number),
    (-5.7e-11, 5.4e-9, @double.not_a_number),
    (-5.7e-11, 1.2e5, 0),
    (-5.7e-11, 2.3e6, 0),
    (-5.7e-11, 3.4e7, 0),
    (-5.7e-11, 4.5e8, 0),
    (-5.7e-11, 5.6e9, 0),
    (-5.7e-11, -1.3, @double.not_a_number),
    (-5.7e-11, -2.4, @double.not_a_number),
    (-5.7e-11, -4.6e-10, @double.not_a_number),
    (-5.7e-11, -5.7e-11, @double.not_a_number),
    (-5.7e-11, -1.7e5, @double.infinity),
    (-5.7e-11, -2.8e6, @double.infinity),
    (-5.7e-11, -3.9e7, @double.infinity),
    (-5.7e-11, -4.0e8, @double.infinity),
    (-5.7e-11, -5.1e9, @double.infinity),
    (-5.7e-11, @double.infinity, 0),
    (-5.7e-11, @double.not_a_number, @double.not_a_number),
    (-5.7e-11, @double.neg_infinity, @double.infinity),
    (-1.7e5, 1.1, @double.not_a_number),
    (-1.7e5, 2.2, @double.not_a_number),
    (-1.7e5, 3.3, @double.not_a_number),
    (-1.7e5, 4.4, @double.not_a_number),
    (-1.7e5, 5.5, @double.not_a_number),
    (-1.7e5, 1.0e-5, @double.not_a_number),
    (-1.7e5, 2.1e-6, @double.not_a_number),
    (-1.7e5, 5.4e-9, @double.not_a_number),
    (-1.7e5, 1.2e5, @double.infinity),
    (-1.7e5, 4.5e8, @double.infinity),
    (-1.7e5, 5.6e9, @double.infinity),
    (-1.7e5, -1.3, @double.not_a_number),
    (-1.7e5, -2.4, @double.not_a_number),
    (-1.7e5, -2.4e-8, @double.not_a_number),
    (-1.7e5, -3.5e-9, @double.not_a_number),
    (-1.7e5, -4.6e-10, @double.not_a_number),
    (-1.7e5, -5.7e-11, @double.not_a_number),
    (-1.7e5, -1.7e5, 0),
    (-1.7e5, -2.8e6, 0),
    (-1.7e5, -3.9e7, 0),
    (-1.7e5, -4.0e8, 0),
    (-1.7e5, -5.1e9, 0),
    (-1.7e5, @double.infinity, @double.infinity),
    (-1.7e5, @double.not_a_number, @double.not_a_number),
    (-1.7e5, @double.neg_infinity, 0),
    (2.0, -1074.0, 5.0e-324),
    (-2.8e6, 1.1, @double.not_a_number),
    (-2.8e6, 2.2, @double.not_a_number),
    (-2.8e6, 3.3, @double.not_a_number),
    (-2.8e6, 1.0e-5, @double.not_a_number),
    (-2.8e6, 2.1e-6, @double.not_a_number),
    (-2.8e6, 5.4e-9, @double.not_a_number),
    (-2.8e6, 1.2e5, @double.infinity),
    (-2.8e6, 2.3e6, @double.infinity),
    (-2.8e6, 3.4e7, @double.infinity),
    (-2.8e6, 4.5e8, @double.infinity),
    (-2.8e6, 5.6e9, @double.infinity),
    (-2.8e6, -1.3, @double.not_a_number),
    (-2.8e6, -2.4, @double.not_a_number),
    (-2.8e6, -3.5, @double.not_a_number),
    (-2.8e6, -4.6, @double.not_a_number),
    (-2.8e6, -5.7, @double.not_a_number),
    (-2.8e6, -1.3e-7, @double.not_a_number),
    (-2.8e6, -2.4e-8, @double.not_a_number),
    (-2.8e6, -3.5e-9, @double.not_a_number),
    (-2.8e6, -4.6e-10, @double.not_a_number),
    (-2.8e6, -5.7e-11, @double.not_a_number),
    (-2.8e6, -1.7e5, 0),
    (-2.8e6, -2.8e6, 0),
    (-2.8e6, -3.9e7, 0),
    (-2.8e6, -4.0e8, 0),
    (-2.8e6, -5.1e9, 0),
    (-2.8e6, @double.infinity, @double.infinity),
    (-2.8e6, @double.not_a_number, @double.not_a_number),
    (-2.8e6, @double.neg_infinity, 0),
    (-3.9e7, 1.1, @double.not_a_number),
    (-3.9e7, 2.2, @double.not_a_number),
    (-3.9e7, 3.3, @double.not_a_number),
    (-3.9e7, 4.4, @double.not_a_number),
    (-3.9e7, 5.5, @double.not_a_number),
    (-3.9e7, 1.0e-5, @double.not_a_number),
    (-3.9e7, 2.1e-6, @double.not_a_number),
    (-3.9e7, 3.2e-7, @double.not_a_number),
    (-3.9e7, 4.3e-8, @double.not_a_number),
    (-3.9e7, 5.4e-9, @double.not_a_number),
    (-3.9e7, 1.2e5, @double.infinity),
    (-3.9e7, 2.3e6, @double.infinity),
    (-3.9e7, 4.5e8, @double.infinity),
    (-3.9e7, 5.6e9, @double.infinity),
    (-3.9e7, -1.3, @double.not_a_number),
    (-3.9e7, -5.7, @double.not_a_number),
    (-3.9e7, -1.3e-7, @double.not_a_number),
    (-3.9e7, -2.4e-8, @double.not_a_number),
    (-3.9e7, -3.5e-9, @double.not_a_number),
    (-3.9e7, -4.6e-10, @double.not_a_number),
    (-3.9e7, -5.7e-11, @double.not_a_number),
    (-3.9e7, -1.7e5, 0),
    (-3.9e7, -2.8e6, 0),
    (-3.9e7, -3.9e7, 0),
    (-3.9e7, -4.0e8, 0),
    (-3.9e7, -5.1e9, 0),
    (-3.9e7, @double.infinity, @double.infinity),
    (-3.9e7, @double.not_a_number, @double.not_a_number),
    (-3.9e7, @double.neg_infinity, 0),
    (-4.0e8, 1.1, @double.not_a_number),
    (-4.0e8, 2.2, @double.not_a_number),
    (-4.0e8, 3.3, @double.not_a_number),
    (-4.0e8, 4.4, @double.not_a_number),
    (-4.0e8, 5.5, @double.not_a_number),
    (-4.0e8, 1.0e-5, @double.not_a_number),
    (-4.0e8, 2.1e-6, @double.not_a_number),
    (-4.0e8, 3.2e-7, @double.not_a_number),
    (-4.0e8, 4.3e-8, @double.not_a_number),
    (-4.0e8, 5.4e-9, @double.not_a_number),
    (-4.0e8, 1.2e5, @double.infinity),
    (-4.0e8, 4.5e8, @double.infinity),
    (-4.0e8, 5.6e9, @double.infinity),
    (-4.0e8, -1.3, @double.not_a_number),
    (-4.0e8, -2.4, @double.not_a_number),
    (-4.0e8, -1.3e-7, @double.not_a_number),
    (-4.0e8, -2.4e-8, @double.not_a_number),
    (-4.0e8, -3.5e-9, @double.not_a_number),
    (-4.0e8, -4.6e-10, @double.not_a_number),
    (-4.0e8, -5.7e-11, @double.not_a_number),
    (-4.0e8, -1.7e5, 0),
    (-4.0e8, -2.8e6, 0),
    (-4.0e8, -3.9e7, 0),
    (-4.0e8, -4.0e8, 0),
    (-4.0e8, -5.1e9, 0),
    (-4.0e8, @double.infinity, @double.infinity),
    (-4.0e8, @double.not_a_number, @double.not_a_number),
    (-4.0e8, @double.neg_infinity, 0),
    (-5.1e9, 1.1, @double.not_a_number),
    (-5.1e9, 2.2, @double.not_a_number),
    (-5.1e9, 3.3, @double.not_a_number),
    (-5.1e9, 4.4, @double.not_a_number),
    (-5.1e9, 5.5, @double.not_a_number),
    (-5.1e9, 1.0e-5, @double.not_a_number),
    (-5.1e9, 2.1e-6, @double.not_a_number),
    (-5.1e9, 3.2e-7, @double.not_a_number),
    (-5.1e9, 4.3e-8, @double.not_a_number),
    (-5.1e9, 5.4e-9, @double.not_a_number),
    (-5.1e9, 1.2e5, @double.infinity),
    (-5.1e9, 2.3e6, @double.infinity),
    (-5.1e9, 3.4e7, @double.infinity),
    (-5.1e9, 4.5e8, @double.infinity),
    (-5.1e9, 5.6e9, @double.infinity),
    (-5.1e9, -1.3, @double.not_a_number),
    (-5.1e9, -2.4, @double.not_a_number),
    (-5.1e9, -3.5, @double.not_a_number),
    (-5.1e9, -4.6, @double.not_a_number),
    (-5.1e9, -5.7, @double.not_a_number),
    (-5.1e9, -1.3e-7, @double.not_a_number),
    (-5.1e9, -2.4e-8, @double.not_a_number),
    (-5.1e9, -3.5e-9, @double.not_a_number),
    (-5.1e9, -4.6e-10, @double.not_a_number),
    (-5.1e9, -5.7e-11, @double.not_a_number),
    (-5.1e9, -1.7e5, 0),
    (-5.1e9, -2.8e6, 0),
    (-5.1e9, -3.9e7, 0),
    (-5.1e9, -4.0e8, 0),
    (-5.1e9, -5.1e9, 0),
    (-5.1e9, @double.infinity, @double.infinity),
    (-5.1e9, @double.not_a_number, @double.not_a_number),
    (-5.1e9, @double.neg_infinity, 0),
    (@double.infinity, 1.1, @double.infinity),
    (@double.infinity, 2.2, @double.infinity),
    (@double.infinity, 3.3, @double.infinity),
    (@double.infinity, 4.4, @double.infinity),
    (@double.infinity, 5.5, @double.infinity),
    (@double.infinity, 1.0e-5, @double.infinity),
    (@double.infinity, 2.1e-6, @double.infinity),
    (@double.infinity, 3.2e-7, @double.infinity),
    (@double.infinity, 4.3e-8, @double.infinity),
    (@double.infinity, 5.4e-9, @double.infinity),
    (@double.infinity, 1.2e5, @double.infinity),
    (@double.infinity, 2.3e6, @double.infinity),
    (@double.infinity, 3.4e7, @double.infinity),
    (@double.infinity, 4.5e8, @double.infinity),
    (@double.infinity, 5.6e9, @double.infinity),
    (@double.infinity, -1.3, 0),
    (@double.infinity, -2.4, 0),
    (@double.infinity, -3.5, 0),
    (@double.infinity, -4.6, 0),
    (@double.infinity, -5.7, 0),
    (@double.infinity, -1.3e-7, 0),
    (@double.infinity, -2.4e-8, 0),
    (@double.infinity, -3.5e-9, 0),
    (@double.infinity, -4.6e-10, 0),
    (@double.infinity, -5.7e-11, 0),
    (@double.infinity, -1.7e5, 0),
    (@double.infinity, -2.8e6, 0),
    (@double.infinity, -3.9e7, 0),
    (@double.infinity, -4.0e8, 0),
    (@double.infinity, -5.1e9, 0),
    (@double.infinity, @double.infinity, @double.infinity),
    (@double.infinity, @double.not_a_number, @double.not_a_number),
    (@double.infinity, @double.neg_infinity, 0),
    (@double.not_a_number, 1.1, @double.not_a_number),
    (@double.not_a_number, 2.2, @double.not_a_number),
    (@double.not_a_number, 3.3, @double.not_a_number),
    (@double.not_a_number, -4.0e8, @double.not_a_number),
    (@double.not_a_number, -5.1e9, @double.not_a_number),
    (@double.not_a_number, @double.infinity, @double.not_a_number),
    (@double.not_a_number, @double.not_a_number, @double.not_a_number),
    (@double.not_a_number, @double.neg_infinity, @double.not_a_number),
    (@double.neg_infinity, 1.1, @double.infinity),
    (@double.neg_infinity, 2.3e6, @double.infinity),
    (@double.neg_infinity, 3.4e7, @double.infinity),
    (@double.neg_infinity, 4.5e8, @double.infinity),
    (@double.neg_infinity, 5.6e9, @double.infinity),
    (@double.neg_infinity, -1.3, 0),
    (@double.neg_infinity, -2.4, 0),
    (@double.neg_infinity, -3.5, 0),
    (@double.neg_infinity, -4.6, 0),
    (@double.neg_infinity, -5.7, 0),
    (@double.neg_infinity, -1.3e-7, 0),
    (@double.neg_infinity, -2.4e-8, 0),
    (@double.neg_infinity, -3.5e-9, 0),
    (@double.neg_infinity, -4.6e-10, 0),
    (@double.neg_infinity, -5.7e-11, 0),
    (@double.neg_infinity, -1.7e5, 0),
    (@double.neg_infinity, -2.8e6, 0),
    (@double.neg_infinity, -3.9e7, 0),
    (@double.neg_infinity, -4.0e8, 0),
    (@double.neg_infinity, -5.1e9, 0),
    (@double.neg_infinity, @double.infinity, @double.infinity),
    (@double.neg_infinity, @double.not_a_number, @double.not_a_number),
    (@double.neg_infinity, @double.neg_infinity, 0),
  ]
  fn is_accept(actual : Double, expect : Double) -> Bool {
    if expect.is_nan() {
      return actual.is_nan()
    }
    if expect.is_pos_inf() {
      return actual.is_pos_inf()
    }
    if expect.is_neg_inf() {
      return actual.is_neg_inf()
    }
    let actual = actual.reinterpret_as_int64()
    let expected = expect.reinterpret_as_int64()
    (actual - expected).abs() <= 2
  }

  for case in test_cases {
    let (a, b, expect) = case
    let actual = @math.pow(a, b)
    assert_true(
      is_accept(actual, expect),
      msg="Test failed: \{a} ** \{b} = \{actual}, expected \{expect}",
    )
  }
}

///|
test "pow double branch coverage" {
  let nan_res = @math.pow(-1.0, 0.5)
  assert_true(nan_res.is_nan())
  assert_eq(@math.pow(-1.0, 3.0), -1.0)
  assert_eq(@math.pow(-2.0, 3.0), -8.0)
  let tiny = @math.pow(0.5, 1.0e20)
  assert_true(tiny == 0.0)
  let huge = @math.pow(2.0, 1.0e20)
  assert_true(huge.is_inf())
  let near_one = @math.pow(0.9999999999999999, 1.0e10)
  assert_true(near_one > 0.0)
  let sub = @math.pow(1.0e-320, 2.0)
  assert_true(sub == 0.0)
  let overflow_edge = @math.pow(2.0, 1024.0)
  assert_true(overflow_edge.is_inf())
  let underflow_edge = @math.pow(2.0, -1075.0)
  assert_true(underflow_edge == 0.0)
}

///|
test "powf infinity exponent branches" {
  assert_eq(@math.powf(-1.0, @float.infinity), 1.0)
  assert_true(@math.powf(2.0, @float.infinity).is_pos_inf())
  inspect(@math.powf(0.5, @float.infinity), content="0")
  assert_true(@math.powf(0.5, @float.neg_infinity).is_pos_inf())
}

///|
test "powf huge even exponent negative base" {
  assert_true(@math.powf(-2.0, 16777216.0).is_pos_inf())
}

///|
test "pow double infinity exponent branch" {
  assert_true(@math.pow(1.0, @double.infinity).is_nan())
  assert_eq(@math.pow(2.0, 1.0), 2.0)
}

///|
test "scalbnf exponent clamp" {
  assert_true(@math.scalbnf(1.0, 500).is_pos_inf())
  inspect(@math.scalbnf(1.0, -500), content="0")
}
