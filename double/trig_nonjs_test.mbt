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
test "atan2 - zero with x = 0" {
  inspect!(1.0.atan2(0.0), content="1.5707963267948966")
  inspect!((-1.0).atan2(0.0), content="-1.5707963267948966")
}

///|
test "kernel_sin with iy=0" {
  // The line `x + v * (s1 + z * r)` in __kernel_sin function
  // is returned when iy == 0
  // We need to provide input x that enters this branch
  let x = 3.141592653589793 / 4.0
  inspect!(@double.sin(x), content="0.7071067811865475")
}

///|
test "asin edge case 1" {
  // Test case for x slightly less than 1 (ix >= 0x3FEF3333)
  let x = 0.999999
  inspect!(@double.asin(x), content="1.5693821131146521")
}

///|
test "atan2 quadrant case" {
  // Different quadrants
  inspect!((-1.0).atan2(1.0), content="-0.7853981633974483") // quadrant 4
  inspect!((-1.0).atan2(-1.0), content="-2.356194490192345") // quadrant 3
  inspect!(1.0.atan2(-1.0), content="2.356194490192345") // quadrant 2
}

///|
test "atan of small values" {
  let tiny = 1.0e-300 // A value small enough that ix < 0x3e200000 and huge + self > one
  let result = @double.atan(tiny)
  inspect!(result, content="1e-300")
  let very_tiny = 1.0e-500 // Another small value to ensure multiple test cases for the same branch
  let result2 = @double.atan(very_tiny)
  inspect!(result2, content="0")
}

///|
test "atan2 infinite x case" {
  let y = 1.0
  inspect!(y.atan2(@double.infinity), content="0")
  inspect!((-y).atan2(@double.infinity), content="0")
  let b = (-y).atan2(@double.neg_infinity)
  inspect!(b, content="-3.141592653589793")
}

///|
test "atan2 for zero and infinity cases" {
  let zero = 0.0
  let pos_zero = 0.0
  let neg_zero = -0.0 // this triggers special case 0 | 1
  inspect!(neg_zero.atan2(pos_zero), content="0")
  inspect!(neg_zero.atan2(-1.0), content="-3.141592653589793")
  let inf = @double.infinity
  inspect!(zero.atan2(inf), content="0")
  inspect!(zero.atan2(-inf), content="3.141592653589793")
}

///|
test "atan2_large_diff" {
  // k > 60
  let y = 1.0e100
  let x = 0.1
  inspect!(y.atan2(x), content="1.5707963267948966")
}

///|
test "atan2_negative_z" {
  // m = 1 
  let y = -1.0
  let x = 2.0
  inspect!(y.atan2(x), content="-0.4636476090008061")
}

///|
test "atan2_large_negative_x" {
  // hx < 0 && k < -60 
  let y = 0.1
  let x = -1.0e100
  inspect!(y.atan2(x), content="3.141592653589793")
}

///|
test "kernal_tan edge case" {
  let x = 1.5707963267948966
  inspect!(x.tan(), content="16331239353195370")
  let x = -1.5707963267948966
  inspect!(x.tan(), content="-16331239353195370")
}
