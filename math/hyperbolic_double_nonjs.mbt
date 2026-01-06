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

//
// origin: FreeBSD /usr/src/lib/msun/src/e_sinh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_cosh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_tanh.c
// origin: FreeBSD /usr/src/lib/msun/src/s_asinh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_acosh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_atanh.c
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunSoft, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
//

///|
/// Calculates the hyperbolic sine of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the hyperbolic sine.
///
/// Returns the hyperbolic sine of `x`.
///
/// Special cases:
///
/// * Returns `infinity` if `x` is `infinity`
/// * Returns `NaN` if `x` is `NaN`
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.sinh(0.0), content="0")
///   inspect(@math.sinh(-0.0), content="0")
///   inspect(@math.sinh(1.0), content="1.1752011936438014")
///   inspect(@math.sinh(2.0), content="3.626860407847019")
///   inspect(@math.sinh(1000.0), content="Infinity")
///   inspect(@math.sinh(-1000.0), content="-Infinity")
///   inspect(@math.sinh(@double.not_a_number), content="NaN")
///   inspect(@math.sinh(@double.infinity), content="Infinity")
///   inspect(@math.sinh(@double.neg_infinity), content="-Infinity")
/// }
/// ```
pub fn sinh(x : Double) -> Double {
  if x.is_nan() || x.is_inf() {
    return x
  }
  let ix = get_high_word(x).reinterpret_as_int() & 0x7fffffff
  let abs_x = x.abs()
  let shuge = 1.0e307
  let h = if x < 0.0 { -0.5 } else { 0.5 }
  if ix < 0x40360000 {
    if ix < 0x3e300000 {
      if shuge + x > 1.0 {
        return x
      }
    }
    let t = expm1(abs_x)
    if ix < 0x3ff00000 {
      return h * (2.0 * t - t * t / (t + 1.0))
    }
    return h * (t + t / (t + 1.0))
  }
  if ix < 0x40862E42 {
    return h * exp(abs_x)
  }
  if abs_x.reinterpret_as_uint64() < 0x408633ce8fb9f87d {
    let w = exp(0.5 * abs_x)
    let t = h * w
    return t * w
  }
  x * shuge
}

///|
/// Calculates the hyperbolic cosine of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the hyperbolic cosine.
///
/// Returns the hyperbolic cosine of `x`.
///
/// Special cases:
///
/// * Returns `infinity` if `x` is `infinity`
/// * Returns `NaN` if `x` is `NaN`
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.cosh(0.0), content="1")
///   inspect(@math.cosh(-0.0), content="1")
///   inspect(@math.cosh(1.0), content="1.5430806348152437")
///   inspect(@math.cosh(2.0), content="3.7621956910836314")
///   inspect(@math.cosh(1000.0), content="Infinity")
///   inspect(@math.cosh(-1000.0), content="Infinity")
///   inspect(@math.cosh(@double.not_a_number), content="NaN")
///   inspect(@math.cosh(@double.infinity), content="Infinity")
///   inspect(@math.cosh(@double.neg_infinity), content="Infinity")
/// }
/// ```
pub fn cosh(x : Double) -> Double {
  if x.is_nan() {
    return x
  }
  if x.is_inf() {
    return @double.infinity
  }
  let ix = get_high_word(x).reinterpret_as_int() & 0x7fffffff
  if ix < 0x3fd62e43 {
    let t = expm1(x.abs())
    let w = 1.0 + t
    if ix < 0x3c800000 {
      return w
    }
    return 1.0 + t * t / (w + w)
  }
  if ix < 0x40360000 {
    let t = exp(x.abs())
    return 0.5 * t + 0.5 / t
  }
  if ix < 0x40862E42 {
    return (0.5 * x.abs()) |> exp
  }
  let lx = get_low_word(x).reinterpret_as_int()
  if ix < 0x408633ce || (ix == 0x408633ce && lx <= 0x8fb9f87d) {
    let w = exp(0.5 * x.abs())
    let t = 0.5 * w
    return t * w
  }
  @double.infinity
}

///|
/// Calculates the hyperbolic tangent of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the hyperbolic tangent.
///
/// Returns the hyperbolic tangent of `x`.
///
/// Special cases:
///
/// * Returns `NaN` if `x` is `NaN`
/// * Returns `1` if `x` is `infinity`
/// * Returns `-1` if `x` is `-infinity`
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.tanh(0.0), content="0")
///   inspect(@math.tanh(-0.0), content="0")
///   inspect(@math.tanh(1.0), content="0.7615941559557649")
///   inspect(@math.tanh(2.0), content="0.9640275800758169")
///   inspect(@math.tanh(1000.0), content="1")
///   inspect(@math.tanh(-1000.0), content="-1")
///   inspect(@math.tanh(@double.not_a_number), content="NaN")
///   inspect(@math.tanh(@double.infinity), content="1")
///   inspect(@math.tanh(@double.neg_infinity), content="-1")
/// }
/// ```
pub fn tanh(x : Double) -> Double {
  if x.is_nan() {
    return x
  }
  if x.is_pos_inf() {
    return 1.0
  }
  if x.is_neg_inf() {
    return -1.0
  }
  let ix = get_high_word(x).reinterpret_as_int() & 0x7fffffff
  let tiny = 1.0e-300
  let z = if ix < 0x40360000 {
    if ix < 0x3c800000 {
      x * (1.0 + x)
    } else if ix >= 0x3ff00000 {
      let t = (2.0 * x.abs()) |> expm1
      1.0 - 2.0 / (t + 2.0)
    } else {
      let t = (-2.0 * x.abs()) |> expm1
      -t / (t + 2.0)
    }
  } else {
    1.0 - tiny
  }
  if x >= 0.0 {
    z
  } else {
    -z
  }
}

///|
/// Calculates the inverse hyperbolic sine of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the inverse hyperbolic sine.
///
/// Returns the inverse hyperbolic sine of `x`.
///
/// Special cases:
///
/// * Returns `NaN` if `x` is `NaN`
/// * Returns `infinity` if `x` is `infinity`
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.asinh(0.0), content="0")
///   inspect(@math.asinh(-0.0), content="0")
///   inspect(@math.asinh(1.0), content="0.881373587019543")
///   inspect(@math.asinh(2.0), content="1.4436354751788103")
///   inspect(@math.asinh(1000.0), content="7.600902709541988")
///   inspect(@math.asinh(-1000.0), content="-7.600902709541988")
///   inspect(@math.asinh(@double.not_a_number), content="NaN")
///   inspect(@math.asinh(@double.infinity), content="Infinity")
///   inspect(@math.asinh(@double.neg_infinity), content="-Infinity")
/// }
/// ```
pub fn asinh(x : Double) -> Double {
  if x.is_nan() || x.is_inf() {
    return x
  }
  let one : Double = 1.0
  let ln2 : Double = 6.93147180559945286227e-01
  let huge : Double = 1.0e300
  let hx = get_high_word(x).reinterpret_as_int()
  let ix = hx & 0x7fffffff
  if ix < 0x3e300000 {
    if huge + x > one {
      return x
    }
  }
  let w : Double = if ix > 0x41b00000 {
    ln(x.abs()) + ln2
  } else if ix > 0x40000000 {
    let t = x.abs()
    (2.0 * t + one / ((x * x + one).sqrt() + t)) |> ln
  } else {
    let t = x * x
    (x.abs() + t / (one + (one + t).sqrt())) |> ln_1p
  }
  if hx > 0 {
    w
  } else {
    -w
  }
}

///|
/// Calculates the inverse hyperbolic cosine of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the inverse hyperbolic cosine.
///
/// Returns the inverse hyperbolic cosine of `x`.
///
/// Special cases:
///
/// * Returns `NaN` if `x` is less than `1`.
/// * Returns `NaN` if `x` is `NaN`.
/// * Returns `0` if `x` is `1`.
/// * Returns `infinity` if `x` is `infinity` (Positive infinity).
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.acosh(1.0), content="0")
///   inspect(@math.acosh(2.0), content="1.3169578969248166")
///   inspect(@math.acosh(1000.0), content="7.600902209541989")
///   inspect(@math.acosh(@double.not_a_number), content="NaN")
///   inspect(@math.acosh(@double.infinity), content="Infinity")
///   inspect(@math.acosh(-1.0), content="NaN")
///   inspect(@math.acosh(-2.0), content="NaN")
///   inspect(@math.acosh(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn acosh(x : Double) -> Double {
  let one = 1.0
  let hx = get_high_word(x).reinterpret_as_int()
  if x < 1.0 || x.is_nan() {
    return @double.not_a_number
  } else if x == 1.0 {
    return 0.0
  } else if x.is_pos_inf() {
    return @double.infinity
  } else if hx >= 0x41b00000 {
    return ln(x) + LN2
  } else if hx > 0x40000000 {
    let t = x * x
    return (2.0 * x - one / (x + (t - one).sqrt())) |> ln
  } else {
    let t = x - one
    return (t + (2.0 * t + t * t).sqrt()) |> ln_1p
  }
}

///|
/// Calculates the inverse hyperbolic tangent of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the inverse hyperbolic tangent.
///
/// Returns the inverse hyperbolic tangent of `x`.
///
/// Special cases:
///
/// * Returns `NaN` if `x` is less than `-1` or greater than `1`.
/// * Returns `infinity` if `x` is `1`.
/// * Returns `-infinity` if `x` is `-1`.
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.atanh(0.0), content="0")
///   inspect(@math.atanh(-0.0), content="0")
///   inspect(@math.atanh(0.5), content="0.5493061443340548")
///   inspect(@math.atanh(-0.5), content="-0.5493061443340548")
///   inspect(@math.atanh(1.0), content="Infinity")
///   inspect(@math.atanh(-1.0), content="-Infinity")
///   inspect(@math.atanh(1.5), content="NaN")
///   inspect(@math.atanh(@double.not_a_number), content="NaN")
///   inspect(@math.atanh(@double.infinity), content="NaN")
/// }
/// ```
pub fn atanh(x : Double) -> Double {
  let hx : Int = get_high_word(x).reinterpret_as_int()
  let ix = hx & 0x7fffffff
  if x.abs() > 1.0 {
    return @double.not_a_number
  }
  if x == 1.0 {
    return @double.infinity
  }
  if x == -1.0 {
    return @double.neg_infinity
  }
  if ix < 0x3e300000 && 1.0e300 + x > 0.0 {
    return x
  }
  let x = x.abs()
  let t = if x <= 0.5 {
    let t = x + x
    0.5 * ln_1p(t + t * x / (1.0 - x))
  } else {
    0.5 * ln_1p((x + x) / (1.0 - x))
  }
  if hx >= 0 {
    t
  } else {
    -t
  }
}
