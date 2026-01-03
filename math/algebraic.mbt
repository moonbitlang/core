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

// origin: boost_1_81_0/boost/math/special_functions/hypot.hpp
//
// This implementation is inspired by the hypot function from the Boost C++ Libraries.
// Original Boost implementation (C) Copyright John Maddock 2005-2006.
// Boost Software License, Version 1.0. (See accompanying file
// LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
// The algorithm has been adapted and implemented independently in this code.

///|
/// Calculates the cube root of a number.
///
/// # Examples
///
/// ```mbt check
/// test {
///   inspect(@math.cbrtf(1), content="1")
///   inspect(@math.cbrtf(27), content="3")
///   inspect(@math.cbrtf(125), content="5")
///   inspect(@math.cbrtf(1000), content="10")
/// }
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
  let t = Float::reinterpret_from_uint(ui).to_double()
  let r = t * t * t
  let t = t * (dx + dx + r) / (dx + r + r)

  //
  // Second step Newton iteration to 47 bits.  In double precision for
  // efficiency and accuracy.
  //
  let r = t * t * t
  let t = t * (dx + dx + r) / (dx + r + r)

  // rounding to 24 bits is perfect in round-to-nearest mode
  Float::from_double(t)
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
///   inspect(@math.hypotf(8, 15), content="17")
/// }
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
