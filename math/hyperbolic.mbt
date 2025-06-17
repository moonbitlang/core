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
pub fnalias Double::(sinh, cosh, tanh, asinh, acosh, atanh)

///|
fn k_expo2f(x : Float) -> Float {
  let k = 235
  let k_ln2 = (0x4322e3bc).reinterpret_as_float()
  // note that k is odd and scale*scale overflows */
  let scale = ((0x7f + k / 2) << 23).reinterpret_as_float()
  // exp(x - k ln2) * 2**(k-1) */
  expf(x - k_ln2) * scale * scale
}

///|
/// Calculates the hyperbolic sine of a fp32 number.
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
/// ```moonbit
///   inspect(sinhf(0), content="0")
///   inspect(sinhf(-0), content="0")
///   inspect(sinhf(1), content="1.175201177597046")
///   inspect(sinhf(2), content="3.6268603801727295")
///   inspect(sinhf(1000), content="Infinity")
///   inspect(sinhf(-1000), content="-Infinity")
///   inspect(sinhf(@float.not_a_number), content="NaN")
///   inspect(sinhf(@float.infinity), content="Infinity")
///   inspect(sinhf(@float.neg_infinity), content="-Infinity")
/// ```
pub fn sinhf(x : Float) -> Float {
  let mut h : Float = 0.5
  let mut ix = x.reinterpret_as_uint()
  if (ix >> 31) != 0 {
    h = -h
  }
  // |x|
  ix = ix & 0x7fffffff
  let absx = ix.reinterpret_as_float()
  let w = ix

  // |self| < log(FLT_MAX)
  if w < 0x42b17217 {
    let t = expm1f(absx)
    if w < 0x3f800000 {
      if w < 0x3f800000U - (12U << 23) {
        return x
      }
      return h * ((2.0 : Float) * t - t * t / (t + 1.0))
    }
    return h * (t + t / (t + 1.0))
  }

  // |self| > logf(FLT_MAX) or nan
  h * k_expo2f(absx) * 2.0
}

///|
/// Calculates the hyperbolic cosine of a fp32 number.
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
/// ```moonbit
///   inspect(coshf(0), content="1")
///   inspect(coshf(-0), content="1")
///   inspect(coshf(1), content="1.5430805683135986")
///   inspect(coshf(2), content="3.7621958255767822")
///   inspect(coshf(1000), content="Infinity")
///   inspect(coshf(-1000), content="Infinity")
///   inspect(coshf(@float.not_a_number), content="NaN")
///   inspect(coshf(@float.infinity), content="Infinity")
///   inspect(coshf(@float.neg_infinity), content="Infinity")
/// ```
pub fn coshf(x : Float) -> Float {
  let mut x = x
  let mut ix = x.reinterpret_as_uint()
  ix = ix & 0x7fffffff
  x = ix.reinterpret_as_float()
  let w = ix

  // |x| < log(2)
  if w < 0x3f317217 {
    if w < 0x3f800000U - (12U << 23) {
      return 1.0
    }
    let t = expm1f(x)
    return (1.0 : Float) + t * t / ((2.0 : Float) * (t + 1.0))
  }

  // |x| < log(FLT_MAX)
  if w < 0x42b17217 {
    let t = expf(x)
    return (t + (1.0 : Float) / t) * 0.5
  }

  // |x| > log(FLT_MAX) or nan
  k_expo2f(x)
}

///|
/// Calculates the hyperbolic tangent of a floating number.
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
/// ```moobit
///   inspect(tanhf(0), content="0")
///   inspect(tanhf(-0), content="0")
///   inspect(tanhf(1), content="0.7615941559557649")
///   inspect(tanhf(2), content="0.9640275800758169")
///   inspect(tanhf(1000), content="1")
///   inspect(tanhf(-1000), content="-1")
///   inspect(tanhf(@float.not_a_number), content="NaN")
///   inspect(tanhf(@float.infinity), content="1")
///   inspect(tanhf(@float.neg_infinity), content="-1")
/// ```
pub fn tanhf(x : Float) -> Float {
  let mut ix = x.reinterpret_as_uint()
  let sign = (ix >> 31) != 0
  ix = ix & 0x7fffffff
  let x = ix.reinterpret_as_float()
  let w = ix
  let tt = if w > 0x3f0c9f54 {
    // |x| > log(3)/2 ~= 0.5493 or nan
    if w > 0x41200000 {
      // |x| > 10
      (1.0 : Float) + (0.0 : Float) / x
    } else {
      let t = expm1f(x * 2.0)
      (1.0 : Float) - (2.0 : Float) / (t + 2.0)
    }
  } else if w > 0x3e82c578 {
    // |x| > log(5/3)/2 ~= 0.2554
    let t = expm1f(x * 2.0)
    t / (t + 2.0)
  } else if w >= 0x00800000 {
    // |x| >= 0x1p-126
    let t = expm1f(x * -2.0)
    -t / (t + 2.0)
  } else {
    // |x| is subnormal
    x
  }
  if sign {
    -tt
  } else {
    tt
  }
}

///|
/// Calculates the inverse hyperbolic sine of a floating number.
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
/// ```moonbit
///   inspect(asinhf(0), content="0")
///   inspect(asinhf(-0), content="0")
///   inspect(asinhf(1), content="0.8813735842704773")
///   inspect(asinhf(2), content="1.4436354637145996")
///   inspect(asinhf(1000), content="7.600902557373047")
///   inspect(asinhf(@float.not_a_number), content="NaN")
///   inspect(asinhf(@float.infinity), content="Infinity")
///   inspect(asinhf(@float.neg_infinity), content="-Infinity")
/// ```
pub fn asinhf(x : Float) -> Float {
  let u = x.reinterpret_as_uint()
  let i = u & 0x7fffffff
  let sign = (u >> 31) != 0
  let ln2 : Float = 0.693147180559945309417232121458176568
  let x = i.reinterpret_as_float()
  let x = if i >= 0x3f800000U + (12U << 23) {
    // |x| >= 0x1p12 or inf or nan
    lnf(x) + ln2
  } else if i >= 0x3f800000U + (1U << 23) {
    // |x| >= 2
    lnf(x * 2.0 + (1.0 : Float) / ((x * x + 1.0).sqrt() + x))
  } else if i >= 0x3f800000U - (12U << 23) {
    // |x| >= 0x1p-12, up to 1.6ulp error in [0.125,0.5]
    ln_1pf(x + x * x / ((x * x + 1.0).sqrt() + 1.0))
  } else {
    // |x| < 0x1p-12, raise inexact if x!=0
    // x + 0x1.0p120
    x
  }
  if sign {
    -x
  } else {
    x
  }
}

///|
/// Calculates the inverse hyperbolic cosine of a fp32 number.
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
/// ```moonbit
///   inspect(acoshf(1), content="0")
///   inspect(acoshf(2), content="1.316957950592041")
///   inspect(acoshf(1000), content="7.600902080535889")
///   inspect(acoshf(-1), content="NaN")
///   inspect(acoshf(-2), content="NaN")
///   inspect(acoshf(@float.not_a_number), content="NaN")
///   inspect(acoshf(@float.infinity), content="Infinity")
///   inspect(acoshf(@float.neg_infinity), content="NaN")
/// ```
pub fn acoshf(x : Float) -> Float {
  let ln2 : Float = 693147180559945309417232121458176568
  let u = x.reinterpret_as_uint()
  let a = u & 0x7fffffffU
  if a < 0x3f800000U + (1U << 23) {
    // |x| < 2, invalid if x < 1 or nan
    // up to 2ulp error in [1,1.125]
    return ln_1pf(
      x - 1.0 + ((x - 1.0) * (x - 1.0) + (2.0 : Float) * (x - 1.0)).sqrt(),
    )
  }
  if a < 0x3f800000U + (12U << 23) {
    // |x| < 0x1p12
    return lnf(x * 2.0 - (1.0 : Float) / (x + (x * x - 1.0).sqrt()))
  }
  // x >= 0x1p12
  return lnf(x) + ln2
}

///|
/// Calculates the inverse hyperbolic tangent of an fp32 number.
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
/// ```moonbit
///   inspect(atanhf(0), content="0")
///   inspect(atanhf(-0), content="0")
///   inspect(atanhf(0.5), content="0.5493061542510986")
///   inspect(atanhf(-0.5), content="-0.5493061542510986")
///   inspect(atanhf(1), content="Infinity")
///   inspect(atanhf(-1), content="-Infinity")
///   inspect(atanhf(1.5), content="NaN")
///   inspect(atanhf(@float.not_a_number), content="NaN")
///   inspect(atanhf(@float.infinity), content="NaN")
///   inspect(atanhf(@float.neg_infinity), content="NaN")
/// ```
pub fn atanhf(x : Float) -> Float {
  let u = x.reinterpret_as_uint()
  let sign = (u >> 31) != 0
  let u = u & 0x7fffffff
  let x = u.reinterpret_as_float()
  let x = if u < 0x3f800000U - (1U << 23) {
    if u < 0x3f800000U - (32U << 23) {
      x
    } else {
      // |x| < 0.5, up to 1.7ulp error
      ln_1pf(x * 2.0 + x * 2.0 * x / ((1.0 : Float) - x)) * 0.5
    }
  } else {
    // avoid overflow
    ln_1pf(x / ((1.0 : Float) - x) * 2.0) * 0.5
  }
  if sign {
    -x
  } else {
    x
  }
}
