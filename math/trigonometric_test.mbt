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
trait Floating {
  close_to(a : Self, b : Self) -> Bool
}

///|
impl Floating for Float with close_to(a : Float, b : Float) -> Bool {
  (a - b).abs() < 1.0e-6 // low precision for float
}

///|
impl Floating for Double with close_to(a : Double, b : Double) -> Bool {
  (a - b).abs() < 1.0e-10
}

///|
test "sin function comprehensive" {
  // Basic tests for sin
  assert_true(@math.sin(0.0).close_to(0))
  assert_true(@math.sin(@math.PI / 2.0).close_to(1))
  assert_true(@math.sin(@math.PI).close_to(0))
  assert_true(@math.sin(3.0 * @math.PI / 2.0).close_to(-1))
  assert_true(@math.sin(2.0 * @math.PI).close_to(0))

  // Test various angles between 0 and 2π
  assert_true(@math.sin(@math.PI / 6.0).close_to(0.5))
  assert_true(@math.sin(@math.PI / 4.0).close_to(0.7071067811865475))
  assert_true(@math.sin(@math.PI / 3.0).close_to(0.8660254037844386))
  assert_true(@math.sin(2.0 * @math.PI / 3.0).close_to(0.8660254037844387))
  assert_true(@math.sin(3.0 * @math.PI / 4.0).close_to(0.7071067811865476))
  assert_true(@math.sin(5.0 * @math.PI / 6.0).close_to(0.5))

  // Test negative values
  assert_true(@math.sin(-@math.PI / 2.0).close_to(-1))

  // Test special values
  assert_true(@math.sin(@double.not_a_number).is_nan())
  assert_true(@math.sin(@double.infinity).is_nan())
  assert_true(@math.sin(@double.neg_infinity).is_nan())
}

///|
test "cos function comprehensive" {
  // Basic tests for cos
  assert_true(@math.cos(0.0).close_to(1))
  assert_true(@math.cos(@math.PI / 2.0).close_to(0))
  assert_true(@math.cos(@math.PI).close_to(-1))
  assert_true(@math.cos(3.0 * @math.PI / 2.0).close_to(0))
  assert_true(@math.cos(2.0 * @math.PI).close_to(1))

  // Test various angles between 0 and 2π
  assert_true(@math.cos(@math.PI / 6.0).close_to(0.8660254037844387))
  assert_true(@math.cos(@math.PI / 4.0).close_to(0.7071067811865476))
  assert_true(@math.cos(@math.PI / 3.0).close_to(0.5000000000000001))
  assert_true(@math.cos(2.0 * @math.PI / 3.0).close_to(-0.4999999999999998))
  assert_true(@math.cos(3.0 * @math.PI / 4.0).close_to(-0.7071067811865475))
  assert_true(@math.cos(5.0 * @math.PI / 6.0).close_to(-0.8660254037844387))

  // Test negative values
  assert_true(@math.cos(-@math.PI).close_to(-1))

  // Test special values
  assert_true(@math.cos(@double.not_a_number).is_nan())
  assert_true(@math.cos(@double.infinity).is_nan())
  assert_true(@math.cos(@double.neg_infinity).is_nan())
}

///|
test "tan function comprehensive" {
  // Basic tests for tan
  assert_true(@math.tan(0.0).close_to(0))
  assert_true(@math.tan(@math.PI).close_to(0))
  assert_true(@math.tan(2.0 * @math.PI).close_to(0))

  // Test various angles
  assert_true(@math.tan(@math.PI / 4.0).close_to(1))
  assert_true(@math.tan(@math.PI / 3.0).close_to(1.7320508075688767))
  assert_true(@math.tan(2.0 * @math.PI / 3.0).close_to(-1.7320508075688783))

  // Test negative values
  assert_true(@math.tan(-@math.PI / 4.0).close_to(-1))

  // Test special values
  assert_true(@math.tan(@double.not_a_number).is_nan())
  assert_true(@math.tan(@double.infinity).is_nan())
  assert_true(@math.tan(@double.neg_infinity).is_nan())
}

///|
test "atan function comprehensive" {
  // Basic tests for atan
  assert_true(@math.atan(0.0).close_to(0))
  assert_true(@math.atan(1.0).close_to(0.7853981633974483))
  assert_true(@math.atan(-1.0).close_to(-0.7853981633974483))

  // Test various values
  assert_true(@math.atan(0.5).close_to(0.4636476090008061))
  assert_true(@math.atan(2.0).close_to(1.1071487177940904))
  assert_true(@math.atan(10.0).close_to(1.4711276743037347))

  // Test extreme values
  assert_true(@math.atan(1000.0).close_to(1.5697963271282298))

  // Test special values
  assert_true(@math.atan(@double.not_a_number).is_nan())
  assert_true(@math.atan(@double.infinity).close_to(1.5707963267948966))
  assert_true(@math.atan(@double.neg_infinity).close_to(-1.5707963267948966))
}

///|
test "asin function comprehensive" {
  // Basic tests for asin
  assert_true(@math.asin(0.0).close_to(0))
  assert_true(@math.asin(1.0).close_to(1.5707963267948966))
  assert_true(@math.asin(-1.0).close_to(-1.5707963267948966))

  // Test values within range [-1, 1]
  assert_true(@math.asin(0.5).close_to(0.5235987755982989))
  assert_true(@math.asin(-0.5).close_to(-0.5235987755982989))
  assert_true(@math.asin(0.8660254037844386).close_to(1.0471975511965976)) // sin(π/3)

  // Test values outside valid range
  assert_true(@math.asin(1.2).is_nan())
  assert_true(@math.asin(-1.2).is_nan())

  // Test special values
  assert_true(@math.asin(@double.not_a_number).is_nan())
  assert_true(@math.asin(@double.infinity).is_nan())
  assert_true(@math.asin(@double.neg_infinity).is_nan())
}

///|
test "acos function comprehensive" {
  // Basic tests for acos
  assert_true(@math.acos(1.0).close_to(0))
  assert_true(@math.acos(0.0).close_to(1.5707963267948966))
  assert_true(@math.acos(-1.0).close_to(3.141592653589793))

  // Test values within range [-1, 1]
  assert_true(@math.acos(0.5).close_to(1.0471975511965979))
  assert_true(@math.acos(-0.5).close_to(2.0943951023931957))
  assert_true(@math.acos(0.866025403784439).close_to(0.523598775598298))

  // Test values outside valid range
  assert_true(@math.acos(1.2).is_nan())
  assert_true(@math.acos(-1.2).is_nan())

  // Test special values
  assert_true(@math.acos(@double.not_a_number).is_nan())
  assert_true(@math.acos(@double.infinity).is_nan())
  assert_true(@math.acos(@double.neg_infinity).is_nan())
}

///|
test "atan2 function comprehensive" {
  // Test quadrant I (positive x, positive y)
  assert_true(@math.atan2(1.0, 1.0).close_to(0.7853981633974483)) // 45 degrees
  assert_true(@math.atan2(1.0, 3.0).close_to(0.3217505543966422)) // ~18.4 degrees

  // Test quadrant II (negative x, positive y)
  assert_true(@math.atan2(1.0, -1.0).close_to(2.356194490192345)) // 135 degrees
  assert_true(@math.atan2(3.0, -1.0).close_to(1.892546881191539)) // ~108.4 degrees

  // Test quadrant III (negative x, negative y)
  assert_true(@math.atan2(-1.0, -1.0).close_to(-2.356194490192345)) // -135 degrees
  assert_true(@math.atan2(-1.0, -3.0).close_to(-2.819842099193151)) // ~-161.6 degrees

  // Test quadrant IV (positive x, negative y)
  assert_true(@math.atan2(-1.0, 1.0).close_to(-0.7853981633974483)) // -45 degrees
  assert_true(@math.atan2(-3.0, 1.0).close_to(-1.2490457723982544)) // ~-71.6 degrees

  // Test special cases
  assert_true(@math.atan2(0.0, 1.0).close_to(0)) // 0 degrees
  assert_true(@math.atan2(1.0, 0.0).close_to(1.5707963267948966)) // 90 degrees
  assert_true(@math.atan2(0.0, -1.0).close_to(3.141592653589793)) // 180 degrees
  assert_true(@math.atan2(-1.0, 0.0).close_to(-1.5707963267948966)) // -90 degrees

  // Test with infinity
  assert_true(@math.atan2(1.0, @double.infinity).close_to(0))
  assert_true(
    @math.atan2(1.0, @double.neg_infinity).close_to(3.141592653589793),
  )
  assert_true(@math.atan2(@double.infinity, 1.0).close_to(1.5707963267948966))
  assert_true(
    @math.atan2(@double.neg_infinity, 1.0).close_to(-1.5707963267948966),
  )

  // Test special cases with infinity
  assert_true(
    @math.atan2(@double.infinity, @double.infinity).close_to(0.7853981633974483),
  )
  assert_true(
    @math.atan2(@double.infinity, @double.neg_infinity).close_to(
      2.356194490192345,
    ),
  )
  assert_true(
    @math.atan2(@double.neg_infinity, @double.infinity).close_to(
      -0.7853981633974483,
    ),
  )
  assert_true(
    @math.atan2(@double.neg_infinity, @double.neg_infinity).close_to(
      -2.356194490192345,
    ),
  )

  // Test with NaN
  assert_true(@math.atan2(@double.not_a_number, 1.0).is_nan())
  assert_true(@math.atan2(1.0, @double.not_a_number).is_nan())
}

///|
test "sinf function comprehensive" {
  // Basic test cases
  assert_true(@math.sinf(0.0).close_to(0))
  assert_true(@math.sinf(1.0).close_to(0.8414709568023682))
  assert_true(@math.sinf(-1.0).close_to(-0.8414709568023682))

  // Testing at multiples of π/2
  let pi_2 = (@math.PI / 2.0).to_float()
  assert_true(@math.sinf(pi_2).close_to(1))
  assert_true(@math.sinf(pi_2 * 2.0).close_to(0))
  assert_true(@math.sinf(pi_2 * 3.0).close_to(-1))
  assert_true(@math.sinf(pi_2 * 4.0).close_to(0))

  // Testing extreme values
  assert_true(@math.sinf(100.0).close_to(-0.5063656568527222))

  // Testing special values
  assert_true(@math.sinf(@float.not_a_number).is_nan())
  assert_true(@math.sinf(@float.infinity).is_nan())
  assert_true(@math.sinf(@float.neg_infinity).is_nan())
}

///|
test "cosf function comprehensive" {
  // Basic test cases
  assert_true(@math.cosf(0.0).close_to(1))
  assert_true(@math.cosf(1.0).close_to(0.5403022766113281))
  assert_true(@math.cosf(-1.0).close_to(0.5403022766113281))

  // Testing at multiples of π/2
  let pi_2 = (@math.PI / 2.0).to_float()
  assert_true(@math.cosf(pi_2).close_to(0))
  // this precision is pretty low
  // inspect(@math.cosf(pi_2 ), content="-4.371138828673793e-8")
  assert_true(@math.cosf(pi_2 * 2.0).close_to(-1))
  assert_true(@math.cosf(pi_2 * 3.0).close_to(0))
  assert_true(@math.cosf(pi_2 * 4.0).close_to(1))

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
  assert_true(@math.tanf(0.0).close_to(0))
  assert_true(@math.tanf(1.0).close_to(1.5574077367782593))
  assert_true(@math.tanf(-1.0).close_to(-1.5574077367782593))

  // Testing at multiples of π
  let pi = @math.PI.to_float()
  // inspect(@math.tanf(pi), content="8.742277657347586e-8")
  assert_true(@math.tanf(pi).close_to(0))
  // inspect(@math.tanf(2.0 * pi), content="1.7484555314695172e-7")
  assert_true(@math.tanf(2.0 * pi).close_to(0))

  // Testing values close to singularities
  let pi_2 = pi / 2.0
  let close_to_singularity = pi_2 - 0.01
  let result = @math.tanf(close_to_singularity)
  assert_true!(result > 0.0)

  // Testing extreme values
  assert_true(@math.tanf(10.0).close_to(0.6483607888221741))

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
  assert_true(@math.asinf(0.5).close_to(0.5235987901687622))
  assert_true(@math.asinf(-0.5).close_to(-0.5235987901687622))
  assert_true(@math.asinf(0.8660254).close_to(1.0471974611282349)) // ≈ sin(π/3)

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
  assert_true(@math.acosf(0.5).close_to(1.0471975803375244))
  assert_true(@math.acosf(-0.5).close_to(2.094395160675049))
  assert_true(@math.acosf(0.8660254).close_to(0.5235987901687622)) // ≈ cos(π/3)

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
  assert_true(@math.atanf(0.0).close_to(0))
  assert_true(@math.atanf(1.0).close_to(0.7853981852531433))
  assert_true(@math.atanf(-1.0).close_to(-0.7853981852531433))

  // Testing various values
  assert_true(@math.atanf(0.5).close_to(0.46364760398864746))
  assert_true(@math.atanf(-0.5).close_to(-0.46364760398864746))
  assert_true(@math.atanf(100.0).close_to(1.5607966184616089))

  // Testing special values
  assert_true(@math.atanf(@float.not_a_number).is_nan())
  assert_true(@math.atanf(@float.infinity).close_to(1.570796251296997))
  assert_true(@math.atanf(@float.neg_infinity).close_to(-1.570796251296997))
}

///|
test "atan2f function comprehensive" {
  // Testing quadrant I (x > 0, y > 0)
  assert_true(@math.atan2f(1.0, 1.0).close_to(0.7853981852531433))
  assert_true(@math.atan2f(2.0, 1.0).close_to(1.1071487665176392))

  // Testing quadrant II (x < 0, y > 0)
  assert_true(@math.atan2f(1.0, -1.0).close_to(3.9269909858703613))
  assert_true(@math.atan2f(2.0, -1.0).close_to(4.248741149902344))

  // Testing quadrant III (x < 0, y < 0)
  assert_true(@math.atan2f(-1.0, -1.0).close_to(-2.356194496154785))
  assert_true(@math.atan2f(-2.0, -1.0).close_to(-2.0344438552856445))

  // Testing quadrant IV (x > 0, y < 0)
  assert_true(@math.atan2f(-1.0, 1.0).close_to(-0.7853981852531433))
  assert_true(@math.atan2f(-2.0, 1.0).close_to(-1.1071487665176392))

  // Testing along axes
  assert_true(@math.atan2f(0.0, 1.0).close_to(0))
  assert_true(@math.atan2f(0.0, -1.0).close_to(3.1415927410125732))
  assert_true(@math.atan2f(1.0, 0.0).close_to(1.5707963705062866))
  assert_true(@math.atan2f(-1.0, 0.0).close_to(-1.5707963705062866))

  // Testing special cases with zeros
  assert_true(@math.atan2f(0.0, 0.0).close_to(0))

  // Testing with infinity
  assert_true(
    @math.atan2f(@float.infinity, @float.infinity).close_to(0.7853981852531433),
  )
  assert_true(
    @math.atan2f(@float.infinity, @float.neg_infinity).close_to(
      2.356194496154785,
    ),
  )
  assert_true(
    @math.atan2f(@float.neg_infinity, @float.infinity).close_to(
      -0.7853981852531433,
    ),
  )
  assert_true(
    @math.atan2f(@float.neg_infinity, @float.neg_infinity).close_to(
      -2.356194496154785,
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
