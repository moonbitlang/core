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
/// Calculates the cube root of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the cube root.
///
/// Returns the cube root of `x`.
///
/// Special Cases:
///
/// * Return `NaN` if `x` is `NaN`.
/// * Return `±0` if `x` is `±0`.
/// * Return `Infinity` if `x` is `Infinity`.
/// * Return `-Infinity` if `x` is `-Infinity`.
///
/// Example
///
/// ```moonbit
/// test "cbrt" {
///  inspect!((0 : Float).cbrt(), content="0")
///  inspect!((1 : Float).cbrt(), content="1")
///  inspect!((8 : Float).cbrt(), content="2")
///  inspect!((-8 : Float).cbrt(), content="-2")
///  inspect!(@float.not_a_number.cbrt(), content="NaN")
///  inspect!(@float.infinity.cbrt(), content="Infinity")
///  inspect!(@float.neg_infinity.cbrt(), content="-Infinity")
/// }
/// ```
pub fn cbrt(self : Float) -> Float {
  let b1 : UInt = 709958130 // B1 = (127-127.0/3-0.03306235651)*2**23 */
  let b2 : UInt = 642849266 // B2 = (127-127.0/3-24/3-0.03306235651)*2**23 */
  let mut ui : UInt = self.reinterpret_as_uint()
  let mut hx : UInt = ui & 0x7fffffff
  if hx >= 0x7f800000 {
    // cbrt(NaN,INF) is itself
    return self + self
  }

  // rough cbrt to 5 bits
  if hx < 0x00800000 {
    // zero or subnormal?
    if hx == 0 {
      return self
    } // cbrt(+-0) is itself
    ui = (self * (0x1.0p24 : Float)).reinterpret_as_uint()
    hx = ui & 0x7fffffff
    hx = hx / 3 + b2
  } else {
    hx = hx / 3 + b1
  }
  ui = ui & 0x80000000
  ui = ui | hx

  //
  // First step Newton iteration (solving t*t-self/t == 0) to 16 bits.  In
  // double precision so that its terms can be arranged for efficiency
  // without causing overflow or underflow.
  //
  let dx = self.to_double()
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
