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

// origin: FreeBSD /usr/src/lib/msun/src/e_powf.c */
//
// Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
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
///

///|
pub fn scalbn(x : Double, exp : Int) -> Double {
  let mut n = exp
  let mut y : Double = x
  if n > 1023 {
    y *= 0x1.0p1023
    n -= 1023
    if n > 1023 {
      y *= 0x1.0p1023
      n -= 1023
      if n > 1023 {
        n = 1023
      }
    }
  } else if n < -1022 {
    // make sure final n < -53 to avoid double
    // rounding in the subnormal range
    y *= 0x1.0p-1022 * 0x1.0p53
    n += 1022 - 53
    if n < -1022 {
      y *= 0x1.0p-1022 * 0x1.0p53
      n += 1022 - 53
      if n < -1022 {
        n = -1022
      }
    }
  }
  let ui = (0x3ff + n).to_uint64() << 52
  return y * ui.reinterpret_as_double()
}

///|
/// Calculcates x * 2 **n where x is a single-precision floating number and n is an integer.
///
/// Parameters:
///
/// - `y` - The floating number to be scaled.
/// - `exp` - The exponent to scale by.
///
/// Returns the scaled floating number.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.scalbnf(1.5, 2), content="6")
///   inspect(@math.scalbnf(2, -1), content="1")
///   inspect(@math.scalbnf(3, 0), content="3")
///   inspect(@math.scalbnf(1, 128), content="Infinity")
///   inspect(@math.scalbnf(1, -150), content="0")
///   inspect(@math.scalbnf(1, 254), content="Infinity")
///   inspect(@math.scalbnf(@float.not_a_number, 1), content="NaN")
///   inspect(@math.scalbnf(-2, 1), content="-4")
///   inspect(@math.scalbnf(-2, 128), content="-Infinity")
/// }
/// ```
pub fn scalbnf(y : Float, exp : Int) -> Float {
  let mut y = y
  let mut n = exp
  if n > 127 {
    y *= (0x1.0p127 : Float)
    n -= 127
    if n > 127 {
      y *= (0x1.0p127 : Float)
      n -= 127
      if n > 127 {
        n = 127
      }
    }
  } else if n < -126 {
    y *= (0x1.0p-126 : Float) * 0x1.0p24
    n += 126 - 24
    if n < -126 {
      y *= (0x1.0p-126 : Float) * 0x1.0p24
      n += 126 - 24
      if n < -126 {
        n = -126
      }
    }
  }
  let u = (0x7f + n) << 23
  return y * Float::reinterpret_from_int(u)
}

///|
test "scalbn" {
  inspect(scalbn(1.5, 2), content="6")
  inspect(scalbn(2.0, -1), content="1")
  inspect(scalbn(3.0, 0), content="3")
  inspect(scalbn(1.0, 1024), content="Infinity")
  inspect(scalbn(1.0, -1023), content="1.1125369292536007e-308")
  inspect(scalbn(1.0, 2047), content="Infinity")
  inspect(scalbn(1.0, -1992), content="0")
  inspect(scalbn(1.0, 3070), content="Infinity")
  inspect(scalbn(1.0, -2961), content="0")
  inspect(scalbn(@double.infinity, 10), content="Infinity")
  inspect(scalbn(@double.not_a_number, 10), content="NaN")
  inspect(scalbn(0.0, 10), content="0")
}
