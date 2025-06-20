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
  let pi_2 = (@math.PI / 2.0).to_float()
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
  let pi_2 = (@math.PI / 2.0).to_float()
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
  let pi = @math.PI.to_float()
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
  // Testing quadrant I (x > 0, y > 0)
  assert_true(@math.atan2f(1.0, 1.0).is_close(0.7853981852531433))
  assert_true(@math.atan2f(2.0, 1.0).is_close(1.1071487665176392))

  // Testing quadrant II (x < 0, y > 0)
  assert_true(@math.atan2f(1.0, -1.0).is_close(3.9269909858703613))
  assert_true(@math.atan2f(2.0, -1.0).is_close(4.248741149902344))

  // Testing quadrant III (x < 0, y < 0)
  assert_true(@math.atan2f(-1.0, -1.0).is_close(-2.356194496154785))
  assert_true(@math.atan2f(-2.0, -1.0).is_close(-2.0344438552856445))

  // Testing quadrant IV (x > 0, y < 0)
  assert_true(@math.atan2f(-1.0, 1.0).is_close(-0.7853981852531433))
  assert_true(@math.atan2f(-2.0, 1.0).is_close(-1.1071487665176392))

  // Testing along axes
  assert_true(@math.atan2f(0.0, 1.0).is_close(0))
  assert_true(@math.atan2f(0.0, -1.0).is_close(3.1415927410125732))
  assert_true(@math.atan2f(1.0, 0.0).is_close(1.5707963705062866))
  assert_true(@math.atan2f(-1.0, 0.0).is_close(-1.5707963705062866))

  // Testing special cases with zeros
  assert_true(@math.atan2f(0.0, 0.0).is_close(0))

  // Testing with infinity
  assert_true(
    @math.atan2f(@float.infinity, @float.infinity).is_close(0.7853981852531433),
  )
  assert_true(
    @math.atan2f(@float.infinity, @float.neg_infinity).is_close(
      2.356194496154785,
    ),
  )
  assert_true(
    @math.atan2f(@float.neg_infinity, @float.infinity).is_close(
      -0.7853981852531433,
    ),
  )
  assert_true(
    @math.atan2f(@float.neg_infinity, @float.neg_infinity).is_close(
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
