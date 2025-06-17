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

// origin: FreeBSD /usr/src/lib/msun/src/s_cbrtf.c
//
// Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
// Debugged and optimized by Bruce D. Evans.
//
//
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================

///|
/// Compares and returns the maximum of two values.
///
/// Returns the second argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt
///   assert_eq(@math.maximum(1, 2), 2)
///   assert_eq(@math.maximum(2, 2), 2)
/// ```
pub fn[T : Compare] maximum(x : T, y : T) -> T {
  if x > y {
    x
  } else {
    y
  }
}

///|
/// Compares and returns the minimum of two values.
///
/// Returns the first argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt
///   assert_eq(@math.minimum(1, 2), 1)
///   assert_eq(@math.minimum(2, 2), 2)
/// ```
pub fn[T : Compare] minimum(x : T, y : T) -> T {
  if x > y {
    y
  } else {
    x
  }
}

///|
pub fnalias Double::(cbrt, hypot)

///|
/// Calculates the cube root of a number.
///
/// # Examples
///
/// ```mbt
///   assert_eq(@math.cbrtf(1), 1)
///   assert_eq(@math.cbrtf(27), 3)
///   assert_eq(@math.cbrtf(125), 5)
///   assert_eq(@math.cbrtf(1000), 10)
/// ```
pub fn cbrtf(x : Float) -> Float {
  let b1 : UInt = 709958130 // B1 = (127-127.0/3-0.03306235651)*2**23 */
  let b2 : UInt = 642849266 // B2 = (127-127.0/3-24/3-0.03306235651)*2**23 */
  let mut ui : UInt = x.reinterpret_as_uint()
  let mut hx : UInt = ui & 0x7fffffff
  if hx >= 0x7f800000 {
    // cbrt(NaN,INF) is itx
    return x + x
  }

  // rough cbrt to 5 bits
  if hx < 0x00800000 {
    // zero or subnormal?
    if hx == 0 {
      return x
    } // cbrt(+-0) is itx
    ui = (x * (0x1.0p24 : Float)).reinterpret_as_uint()
    hx = ui & 0x7fffffff
    hx = hx / 3 + b2
  } else {
    hx = hx / 3 + b1
  }
  ui = ui & 0x80000000
  ui = ui | hx

  //
  // First step Newton iteration (solving t*t-x/t == 0) to 16 bits.  In
  // double precision so that its terms can be arranged for efficiency
  // without causing overflow or underflow.
  //
  let dx = x.to_double()
  let t = ui.reinterpret_as_float().to_double()
  let r = t * t * t
  let t = t * (dx + dx + r) / (dx + r + r)

  //
  // Second step Newton iteration to 47 bits.  In double precision for
  // efficiency and accuracy.
  //
  let r = t * t * t
  let t = t * (dx + dx + r) / (dx + r + r)

  // rounding to 24 bits is perfect in round-to-nearest mode
  t.to_float()
}

///|
/// Returns the hypotenuse of a right-angled triangle whose legs are `x` and `y`.
///
/// # Examples
///
/// ```mbt
///   assert_eq(@math.hypotf(3, 4), 5)
///   assert_eq(@math.hypotf(5, 12), 13)
///   assert_eq(@math.hypotf(8, 15), 17)
/// ```
pub fn hypotf(x : Float, y : Float) -> Float {
  let epsilon : Float = 1.1920928955078125e-7
  let x = x.abs()
  let y = y.abs()
  if x.is_inf() || y.is_inf() {
    return @float.infinity
  }
  let (x, y) = if y > x { (y, x) } else { (x, y) }
  if x * epsilon >= y {
    return x
  }
  let rat = y / x
  x * (rat * rat + 1.0).sqrt()
}
