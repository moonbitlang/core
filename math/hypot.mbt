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

// Adapted from fdlibm e_hypot.c, with scaling from musl src/math/hypot.c.
// See NOTICE for musl's MIT license.
//
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
// Developed at SunSoft, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.

///|
/// Calculates the square root of the sum of the squares of its arguments.
///
/// Parameters:
///
/// * `x` : The number to be used as the first argument.
/// * `y` : The number to be used as the second argument.
///
/// Returns the hypotenuse of a right-angled triangle whose legs are `x` and `y`.
///
/// # Examples
///
/// ```mbt check
/// test {
///   inspect(@math.hypot(3.0, 4.0), content="5")
///   inspect(@math.hypot(99.0, 20.0), content="101")
///   inspect(@math.hypot(@double.not_a_number, 1.0), content="NaN")
///   inspect(
///     @math.hypot(@double.infinity, @double.not_a_number),
///     content="Infinity",
///   )
/// }
/// ```
pub fn hypot(x : Double, y : Double) -> Double {
  if x.is_inf() || y.is_inf() {
    return @double.infinity
  }
  if x.is_nan() || y.is_nan() {
    return @double.not_a_number
  }
  let x = x.abs()
  let y = y.abs()
  let (x, y) = if y > x { (y, x) } else { (x, y) }
  let ex = (x.reinterpret_as_uint64() >> 52).to_int()
  let ey = (y.reinterpret_as_uint64() >> 52).to_int()
  if y == 0.0 || ex - ey > 64 {
    return x
  }
  // Bound both operands before squaring, including the low split parts.
  // Powers of two preserve the significands exactly.
  let (x, y, scale) = if ex > 0x3ff + 510 {
    (x * 0x1.0p-700, y * 0x1.0p-700, 0x1.0p700)
  } else if ey < 0x3ff - 450 {
    (x * 0x1.0p700, y * 0x1.0p700, 0x1.0p-700)
  } else {
    (x, y, 1.0)
  }
  let difference = x - y
  let square_sum = if difference > y {
    // x > 2*y: split x into a 21-bit high part and its exact remainder.
    let high = (x.reinterpret_as_uint64() & 0xffffffff00000000UL).reinterpret_as_double()
    let low = x - high
    high * high - (y * -y - low * (x + high))
  } else {
    // x <= 2*y: x-y is exact, and x*x+y*y = 2*x*y + (x-y)*(x-y).
    let twice_x = x + x
    let x_high = (twice_x.reinterpret_as_uint64() & 0xffffffff00000000UL).reinterpret_as_double()
    let x_low = twice_x - x_high
    let y_high = (y.reinterpret_as_uint64() & 0xffffffff00000000UL).reinterpret_as_double()
    let y_low = y - y_high
    x_high * y_high - (difference * -difference - (x_high * y_low + x_low * y))
  }
  // Preserve the evaluation order above to keep the error below one ulp.
  scale * square_sum.sqrt()
}

///|
/// Calculates the square root of the sum of the squares of its arguments.
///
/// Parameters:
///
/// * `x` : The number to be used as the first argument.
/// * `y` : The number to be used as the second argument.
///
/// Returns the hypotenuse of a right-angled triangle whose legs are `x` and `y`.
///
/// # Examples
///
/// ```mbt check
/// test {
///   inspect(@math.hypotf(3, 4), content="5")
///   inspect(@math.hypotf(5, 12), content="13")
///   inspect(@math.hypotf(99, 20), content="101")
/// }
/// ```
pub fn hypotf(x : Float, y : Float) -> Float {
  if x.is_inf() || y.is_inf() {
    return @float.infinity
  }
  // Squaring a finite Float in Double is exact and cannot overflow or
  // underflow, so no scaling or compensated arithmetic is needed.
  let x = x.to_double()
  let y = y.to_double()
  Float::from_double((x * x + y * y).sqrt())
}
