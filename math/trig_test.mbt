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
// trait Floating {
//   is_close(a : Self, b : Self) -> Bool
// }

// ///|
// impl Floating for Float with is_close(a : Float, b : Float) -> Bool {
//   (a - b).abs() < 1.0e-6 // low precision for float
// }

// ///|
// impl Floating for Double with is_close(a : Double, b : Double) -> Bool {
//   (a - b).abs() < 1.0e-10
// }

///|
test "sinf function comprehensive" {
  // Basic test cases
  assert_true(@math.sinf(0.0).is_close(0))
  assert_true(@math.sinf(1.0).is_close(0.8414709568023682))
  assert_true(@math.sinf(-1.0).is_close(-0.8414709568023682))

  // Testing at multiples of π/2
  let pi_2 = Float::from_double(@math.PI / 2.0)
  assert_true(@math.sinf(pi_2).is_close(1))
  assert_true(@math.sinf(pi_2 * 2.0).is_close(0, absolute_tolerance=1.0e-6))
  assert_true(@math.sinf(pi_2 * 3.0).is_close(-1))
  assert_true(@math.sinf(pi_2 * 4.0).is_close(0, absolute_tolerance=1.0e-6))

  // Testing extreme values
  assert_true(@math.sinf(100.0).is_close(-0.5063656568527222))

  // Testing special values
  assert_true(@math.sinf(@float.not_a_number).is_nan())
  assert_true(@math.sinf(@float.infinity).is_nan())
  assert_true(@math.sinf(@float.neg_infinity).is_nan())
}

///|
test "cosf function comprehensive" {
  // Basic test cases
  assert_true(@math.cosf(0.0).is_close(1))
  assert_true(@math.cosf(1.0).is_close(0.5403022766113281))
  assert_true(@math.cosf(-1.0).is_close(0.5403022766113281))

  // Testing at multiples of π/2
  let pi_2 = Float::from_double(@math.PI / 2.0)
  assert_true(@math.cosf(pi_2).is_close(0, absolute_tolerance=1.0e-6))
  // this precision is pretty low
  // inspect(@math.cosf(pi_2 ), content="-4.371138828673793e-8")
  assert_true(@math.cosf(pi_2 * 2.0).is_close(-1))
  assert_true(@math.cosf(pi_2 * 3.0).is_close(0, absolute_tolerance=1.0e-6))
  assert_true(@math.cosf(pi_2 * 4.0).is_close(1))

  // Testing extreme values
  inspect(@math.cosf(100.0), content="0.8623188734054565")

  // Testing special values
  inspect(@math.cosf(@float.not_a_number), content="NaN")
  inspect(@math.cosf(@float.infinity), content="NaN")
  inspect(@math.cosf(@float.neg_infinity), content="NaN")
}

///|
test "tanf function comprehensive" {
  // Basic test cases
  assert_true(@math.tanf(0.0).is_close(0))
  assert_true(@math.tanf(1.0).is_close(1.5574077367782593))
  assert_true(@math.tanf(-1.0).is_close(-1.5574077367782593))

  // Testing at multiples of π
  let pi = Float::from_double(@math.PI)
  // inspect(@math.tanf(pi), content="8.742277657347586e-8")
  assert_true(@math.tanf(pi).is_close(0, absolute_tolerance=1.0e-6))
  // inspect(@math.tanf(2.0 * pi), content="1.7484555314695172e-7")
  assert_true(@math.tanf(2.0 * pi).is_close(0, absolute_tolerance=1.0e-6))

  // Testing values close to singularities
  let pi_2 = pi / 2.0
  let close_to_singularity = pi_2 - 0.01
  let result = @math.tanf(close_to_singularity)
  assert_true(result > 0.0)

  // Testing extreme values
  assert_true(@math.tanf(10.0).is_close(0.6483607888221741))

  // Testing special values
  assert_true(@math.tanf(@float.not_a_number).is_nan())
  assert_true(@math.tanf(@float.infinity).is_nan())
  assert_true(@math.tanf(@float.neg_infinity).is_nan())
}

///|
test "asinf function comprehensive" {
  // Basic test cases
  inspect(@math.asinf(0.0), content="0")
  inspect(@math.asinf(1.0), content="1.5707963705062866")
  inspect(@math.asinf(-1.0), content="-1.5707963705062866")

  // Testing various values in range [-1,1]
  assert_true(@math.asinf(0.5).is_close(0.5235987901687622))
  assert_true(@math.asinf(-0.5).is_close(-0.5235987901687622))
  assert_true(@math.asinf(0.8660254).is_close(1.0471974611282349)) // ≈ sin(π/3)

  // Testing out of range
  assert_true(@math.asinf(1.5).is_nan())
  assert_true(@math.asinf(-1.5).is_nan())

  // Testing special values
  assert_true(@math.asinf(@float.not_a_number).is_nan())
  assert_true(@math.asinf(@float.infinity).is_nan())
  assert_true(@math.asinf(@float.neg_infinity).is_nan())
}

///|
test "acosf function comprehensive" {
  // Basic test cases
  inspect(@math.acosf(1.0), content="0")
  inspect(@math.acosf(0.0), content="1.570796251296997")
  inspect(@math.acosf(-1.0), content="3.141592502593994")

  // Testing various values in range [-1,1]
  assert_true(@math.acosf(0.5).is_close(1.0471975803375244))
  assert_true(@math.acosf(-0.5).is_close(2.094395160675049))
  assert_true(@math.acosf(0.8660254).is_close(0.5235987901687622)) // ≈ cos(π/3)

  // Testing out of range
  assert_true(@math.acosf(1.5).is_nan())
  assert_true(@math.acosf(-1.5).is_nan())

  // Testing special values
  assert_true(@math.acosf(@float.not_a_number).is_nan())
  assert_true(@math.acosf(@float.infinity).is_nan())
  assert_true(@math.acosf(@float.neg_infinity).is_nan())
}

///|
test "atanf function comprehensive" {
  // Basic test cases
  assert_true(@math.atanf(0.0).is_close(0))
  assert_true(@math.atanf(1.0).is_close(0.7853981852531433))
  assert_true(@math.atanf(-1.0).is_close(-0.7853981852531433))

  // Testing various values
  assert_true(@math.atanf(0.5).is_close(0.46364760398864746))
  assert_true(@math.atanf(-0.5).is_close(-0.46364760398864746))
  assert_true(@math.atanf(100.0).is_close(1.5607966184616089))

  // Testing special values
  assert_true(@math.atanf(@float.not_a_number).is_nan())
  assert_true(@math.atanf(@float.infinity).is_close(1.570796251296997))
  assert_true(@math.atanf(@float.neg_infinity).is_close(-1.570796251296997))
}

///|
test "atan2f function comprehensive" {
  let pi = Float::from_double(@math.PI)
  // Testing quadrant I (x > 0, y > 0)
  assert_true(@math.atan2f(1.0, 1.0).is_close(pi / 4.0))
  assert_true(@math.atan2f(2.0, 1.0).is_close(@math.atanf(2.0)))

  // Testing quadrant II (x < 0, y > 0)
  assert_true(@math.atan2f(1.0, -1.0).is_close(pi * 3.0 / 4.0))
  assert_true(@math.atan2f(2.0, -1.0).is_close(pi - @math.atanf(2.0)))

  // Testing quadrant III (x < 0, y < 0)
  assert_true(@math.atan2f(-1.0, -1.0).is_close(-pi * 3.0 / 4.0))
  assert_true(@math.atan2f(-2.0, -1.0).is_close(@math.atanf(2.0) - pi))

  // Testing quadrant IV (x > 0, y < 0)
  assert_true(@math.atan2f(-1.0, 1.0).is_close(-pi / 4.0))
  assert_true(@math.atan2f(-2.0, 1.0).is_close(-@math.atanf(2.0)))
  assert_true(@math.atan2f(-2.0, 2.0).is_close(-pi / 4.0))

  // Testing along axes
  assert_true(@math.atan2f(0.0, 1.0).is_close(0.0))
  assert_true(@math.atan2f(0.0, -1.0).is_close(pi))
  assert_true(@math.atan2f(1.0, 0.0).is_close(pi / 2.0))
  assert_true(@math.atan2f(-1.0, 0.0).is_close(-pi / 2.0))

  // Testing special cases with zeros
  assert_true(@math.atan2f(0.0, 0.0).is_close(0.0))

  // Testing with infinity
  assert_true(@math.atan2f(@float.infinity, @float.infinity).is_close(pi / 4.0))
  assert_true(
    @math.atan2f(@float.infinity, @float.neg_infinity).is_close(pi * 3.0 / 4.0),
  )
  assert_true(
    @math.atan2f(@float.neg_infinity, @float.infinity).is_close(-pi / 4.0),
  )
  assert_true(
    @math.atan2f(@float.neg_infinity, @float.neg_infinity).is_close(
      -pi * 3.0 / 4.0,
    ),
  )

  // Testing with NaN
  assert_true(@math.atan2f(@float.not_a_number, 1.0).is_nan())
  assert_true(@math.atan2f(1.0, @float.not_a_number).is_nan())
}

///|
test "trig reduce methods simple" {
  // Test with moderate numbers to avoid type issues
  let result1 = @math.sinf(10.0)
  assert_true(result1.abs() < 1.0)

  // Test cosf
  let result2 = @math.cosf(10.0)
  assert_true(result2.abs() < 1.0)

  // Test tanf
  let result3 = @math.tanf(10.0)
  assert_false(result3.is_nan())
}

///|
test "large angle reduction for sinf" {
  // Test angles larger than SIN_SWITCHOVER (201.15625)
  // These should trigger the complex trig_reduce path
  let result1 = @math.sinf(300.0)
  assert_true(result1.abs() <= 1.0)
  let result2 = @math.sinf(500.0)
  assert_true(result2.abs() <= 1.0)
  let result3 = @math.sinf(1000.0)
  assert_true(result3.abs() <= 1.0)
  let result4 = @math.sinf(-300.0)
  assert_true(result4.abs() <= 1.0)
}

///|
test "large angle reduction for cosf" {
  // Test angles larger than COS_SWITCHOVER (142.90625)
  let result1 = @math.cosf(200.0)
  assert_true(result1.abs() <= 1.0)
  let result2 = @math.cosf(400.0)
  assert_true(result2.abs() <= 1.0)
  let result3 = @math.cosf(1000.0)
  assert_true(result3.abs() <= 1.0)
  let result4 = @math.cosf(-200.0)
  assert_true(result4.abs() <= 1.0)
}

///|
test "large angle reduction for tanf" {
  // Test angles larger than COS_SWITCHOVER used by tanf
  let result1 = @math.tanf(200.0)
  assert_false(result1.is_nan())
  let result2 = @math.tanf(400.0)
  assert_false(result2.is_nan())
  let result3 = @math.tanf(1000.0)
  assert_false(result3.is_nan())
  let result4 = @math.tanf(-200.0)
  assert_false(result4.is_nan())
}

///|
test "asinf edge cases" {
  // Test very small values that might trigger special path
  // ix is (0x00800000..=0x39800000) corresponds to very small denormal/small values
  let tiny : Float = 1.0e-20
  let result = @math.asinf(tiny)
  assert_true(result.is_close(tiny, absolute_tolerance=1.0e-20))
  // Test small normal values
  let small : Float = 1.0e-6
  assert_true(@math.asinf(small).is_close(small, absolute_tolerance=1.0e-6))
}

///|
test "acosf edge cases" {
  // Test very small values
  // When ix < 0x3f000000 but ix > 0x32800000
  // 0x32800000 as float is about 1.0e-7, 0x3f000000 is 0.5
  let small1 : Float = 0x1.0p-7 // 2^-7 ≈ 0.0078125
  let result1 = @math.acosf(small1)
  assert_false(result1.is_nan())
  let small2 : Float = 0x1.0p-10 // 2^-10 ≈ 0.0009765625
  let result2 = @math.acosf(small2)
  assert_false(result2.is_nan())
}

///|
test "atanf edge cases" {
  // Test small values that trigger id = -1 path
  // ix < 0x3ee00000 but ix >= 0x39800000
  // 0x39800000 corresponds to very small values
  // 0x3ee00000 as float is about 0.4375
  let small : Float = 1.0e-5
  let result = @math.atanf(small)
  assert_true(result.is_close(small, absolute_tolerance=1.0e-5))
  // Another small value
  let small2 : Float = 0.01
  let result2 = @math.atanf(small2)
  assert_false(result2.is_nan())
}

///|
test "atan2f additional edge cases" {
  let pi = Float::from_double(@math.PI)
  // Test case where y = 0 and x < 0, m = 3 (both negative)
  let result1 = @math.atan2f(-0.0, -1.0)
  assert_true(result1.is_close(-pi))
  // Test case where x = infinity and y is negative finite
  let result2 = @math.atan2f(-1.0, @float.infinity)
  assert_true(
    result2.is_close(-0.0, absolute_tolerance=1.0e-6) ||
    result2.is_close(0.0, absolute_tolerance=1.0e-6),
  )
  // Test case where x = infinity and y = neg_infinity
  let result3 = @math.atan2f(@float.neg_infinity, @float.infinity)
  assert_true(result3.is_close(-pi / 4.0))
  // Test very large y compared to x (should approach ±π/2)
  let huge_y : Float = 1.0e20
  let tiny_x : Float = 1.0
  let result4 = @math.atan2f(huge_y, tiny_x)
  assert_true(result4.is_close(pi / 2.0, absolute_tolerance=1.0e-5))
  let result5 = @math.atan2f(-huge_y, tiny_x)
  assert_true(result5.is_close(-pi / 2.0, absolute_tolerance=1.0e-5))
  // Test where both y and x are 0 but with different signs
  let result6 = @math.atan2f(0.0, 0.0)
  assert_true(result6.is_close(0.0))
}

///|
/// Double precision tests for better coverage
test "asin double - small values coverage" {
  // Test values in range 0 < absx < 0.5 with ix >= 0x3e400000
  // This should trigger the polynomial approximation path (line 103)
  inspect(@math.asin(0.3), content="0.3046926540153975")
  inspect(@math.asin(0.4), content="0.41151684606748806")
  inspect(@math.asin(-0.3), content="-0.3046926540153975")
  inspect(@math.asin(-0.4), content="-0.41151684606748806")

  // Test very small values that trigger line 99-100 (huge + x > 1.0)
  let tiny = 1.0e-100
  inspect(@math.asin(tiny), content="1e-100")
  inspect(@math.asin(-tiny), content="-1e-100")

  // Test boundary around 0.5
  inspect(@math.asin(0.49), content="0.5120897529341477")
  inspect(@math.asin(0.51), content="0.5351847902755998")
}

///|
test "asin double - large values coverage" {
  // Test values close to 1 with ix >= 0x3FEF3333
  // This triggers line 116-119
  inspect(@math.asin(0.9999), content="1.5566540733173846")
  inspect(@math.asin(-0.9999), content="-1.5566540733173846")

  // Test values in range 0.5 <= absx < ~0.9375 
  // This triggers the else branch (line 121-128)
  inspect(@math.asin(0.6), content="0.6435011087932844")
  inspect(@math.asin(0.7), content="0.775397496610753")
  inspect(@math.asin(0.8), content="0.9272952180016123")
  inspect(@math.asin(0.9), content="1.1197695149986342")
}

///|
test "acos double - negative values coverage" {
  // Test negative values to cover x < 0 branch (line 190-197)
  inspect(@math.acos(-0.1), content="1.6709637479564565")
  inspect(@math.acos(-0.3), content="1.8754889808102941")
  inspect(@math.acos(-0.5), content="2.0943951023931957")
  inspect(@math.acos(-0.7), content="2.34619382340565")
  inspect(@math.acos(-0.9), content="2.6905658417935308")

  // Test edge case close to -1
  inspect(@math.acos(-0.999), content="3.09686756642106")
}

///|
test "acos double - small positive values" {
  // Test small positive values in else branch (line 199-207)
  inspect(@math.acos(0.6), content="0.9272952180016123")
  inspect(@math.acos(0.7), content="0.7953988301841436")
}

///|
test "atan double - very small values coverage" {
  // Test values that trigger id = -1 path (line 265-271)
  // ix < 0x3fdc0000 corresponds to |x| < 0.4375
  let small1 = 0.1
  inspect(@math.atan(small1), content="0.09966865249116204")
  let small2 = 0.001
  inspect(@math.atan(small2), content="0.0009999996666668668")

  // Test very tiny values (ix < 0x3e200000)
  let tiny = 1.0e-50
  inspect(@math.atan(tiny), content="1e-50")

  // Test values in range for different id values
  // id = 0: 0.4375 <= |x| < 0.6875
  inspect(@math.atan(0.5), content="0.4636476090008061")
  inspect(@math.atan(0.6), content="0.5404195002705842")

  // id = 1: 0.6875 <= |x| < 1.1875  
  inspect(@math.atan(0.8), content="0.6747409422235527")
  inspect(@math.atan(1.0), content="0.7853981633974483")

  // id = 2: 1.1875 <= |x| < 2.4375
  inspect(@math.atan(1.5), content="0.982793723247329")
  inspect(@math.atan(2.0), content="1.1071487177940904")

  // id = 3: |x| >= 2.4375
  inspect(@math.atan(3.0), content="1.2490457723982544")
  inspect(@math.atan(5.0), content="1.373400766945016")
}

///|
test "atan2 double - zero and axis cases" {
  // Test y = 0 with different x values (line 358-363)
  // m = 0: y = +0, x > 0
  inspect(@math.atan2(0.0, 1.0), content="0")
  // m = 1: y = +0, x < 0 but y positive - not possible, y=-0
  // m = 2: y = +0, x < 0
  inspect(@math.atan2(0.0, -1.0), content="3.141592653589793")
  // m = 3: y = -0, x < 0
  inspect(@math.atan2(-0.0, -1.0), content="-3.141592653589793")

  // Test x = 0 cases (line 365-366)
  inspect(@math.atan2(1.0, 0.0), content="1.5707963267948966")
  inspect(@math.atan2(-1.0, 0.0), content="-1.5707963267948966")
}

///|
test "atan2 double - infinity combinations" {
  // Test x is inf, y is inf (line 369-375)
  inspect(
    @math.atan2(@double.infinity, @double.infinity),
    content="0.7853981633974483",
  )
  inspect(
    @math.atan2(@double.neg_infinity, @double.infinity),
    content="-0.7853981633974483",
  )
  inspect(
    @math.atan2(@double.infinity, @double.neg_infinity),
    content="2.356194490192345",
  )
  inspect(
    @math.atan2(@double.neg_infinity, @double.neg_infinity),
    content="-2.356194490192345",
  )

  // Test x is inf, y is finite (line 377-382)
  inspect(@math.atan2(1.0, @double.infinity), content="0")
  inspect(@math.atan2(-1.0, @double.infinity), content="0")
  inspect(@math.atan2(1.0, @double.neg_infinity), content="3.141592653589793")
  inspect(@math.atan2(-1.0, @double.neg_infinity), content="-3.141592653589793")

  // Test y is inf, x is finite (line 385-386)
  inspect(@math.atan2(@double.infinity, 1.0), content="1.5707963267948966")
  inspect(@math.atan2(@double.neg_infinity, 1.0), content="-1.5707963267948966")
}

///|
test "atan2 double - large ratio cases" {
  // Test k > 60 case (line 389-390) - very large |y| compared to |x|
  let huge_y = 1.0e200
  let small_x = 1.0
  inspect(@math.atan2(huge_y, small_x), content="1.5707963267948966")

  // Test hx < 0 && k < -60 case (line 391-392) - very small |y| compared to |x|, x negative
  let tiny_y = 1.0e-200
  let neg_large_x = -1.0e200
  inspect(@math.atan2(tiny_y, neg_large_x), content="3.141592653589793")

  // Test the general atan(abs(y/x)) case (line 394)
  inspect(@math.atan2(3.0, 4.0), content="0.6435011087932844")
  inspect(@math.atan2(-3.0, 4.0), content="-0.6435011087932844")
  inspect(@math.atan2(3.0, -4.0), content="2.498091544796509")
  inspect(@math.atan2(-3.0, -4.0), content="-2.498091544796509")
}

///|
test "tan double - coverage for special paths" {
  // Test values within PI_OVER_4 (line 43-44)
  inspect(@math.tan(0.5), content="0.5463024898437905")
  inspect(@math.tan(0.7), content="0.8422883804630794")

  // Test negative values to trigger different branches in rem_pio2
  inspect(@math.tan(-1.5), content="-14.101419947171719")
  inspect(@math.tan(-2.0), content="2.185039863261519")
  inspect(@math.tan(-5.0), content="3.380515006246586")
}

///|
test "rem_pio2 double - negative value coverage" {
  // Create tests that will call rem_pio2 with negative values
  // This covers the hx < 0 branches (lines 430-443, 477-483, 509-515)

  // Negative value in range requiring 33+53 bit pi
  let val1 = -1.5707 // close to -pi/2
  inspect(@math.sin(val1), content="-0.9999999953605743")

  // Negative large value
  let val2 = -10.0
  inspect(@math.sin(val2), content="0.5440211108893698")

  // Very large negative value to trigger complex path
  let val3 = -1000.0
  inspect(@math.sin(val3), content="-0.8268795405320025")
}

///|
test "atan2 double branch coverage" {
  inspect(@math.atan2(0.0, 2.0), content="0")
  inspect(@math.atan2(@double.infinity, 2.0), content="1.5707963267948966")
  assert_true(
    @math.atan2(1.0e200, 2.0).is_close(
      @math.PI / 2.0,
      absolute_tolerance=1.0e-12,
    ),
  )
}

///|
test "sin and cos double edge paths" {
  inspect(@math.sin(0.5), content="0.479425538604203")
  assert_true(@math.cos(0.79).abs() <= 1.0)
  assert_true(
    @math.cos(3.0 * @math.PI / 2.0).is_close(0.0, absolute_tolerance=1.0e-12),
  )
}

///|
test "sin/cos huge arguments" {
  let values = [1.0e20, -1.0e20, 1.0e300]
  for v in values {
    let s = @math.sin(v)
    let c = @math.cos(v)
    assert_true(s.abs() <= 1.0)
    assert_true(c.abs() <= 1.0)
  }
}

///|
test "atan2f branch coverage" {
  let pi = Float::from_double(@math.PI)
  assert_true(@math.atan2f(-1.0, @float.neg_infinity).is_close(-pi))
  assert_true(
    @math.atan2f(1.0e20, 2.0).is_close(pi / 2.0, absolute_tolerance=1.0e-5),
  )
  assert_true(
    @math.atan2f(1.0, -1.0e20).is_close(pi, absolute_tolerance=1.0e-5),
  )
  assert_true(@math.atan2f(1.0, 2.0).is_close(@math.atanf(0.5)))
}
