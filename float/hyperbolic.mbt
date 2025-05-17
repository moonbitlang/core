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
fn k_expo2f(x : Float) -> Float {
  let k = 235
  let k_ln2 = (0x4322e3bc).reinterpret_as_float()
  // note that k is odd and scale*scale overflows */
  let scale = ((0x7f + k / 2) << 23).reinterpret_as_float()
  // exp(x - k ln2) * 2**(k-1) */
  (x - k_ln2).exp() * scale * scale
}

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
/// ```moonbit
/// test "sinh" {
///   inspect!((0.0 : Float).sinh(), content="0")
///   inspect!((-0.0 : Float).sinh(), content="0")
///   inspect!((1.0 : Float).sinh(), content="1.175201177597046")
///   inspect!((2.0 : Float).sinh(), content="3.6268603801727295")
///   inspect!((1000.0 : Float).sinh(), content="Infinity")
///   inspect!((-1000.0 : Float).sinh(), content="-Infinity")
///   inspect!(@float.not_a_number.sinh(), content="NaN")
///   inspect!(@float.infinity.sinh(), content="Infinity")
///   inspect!(@float.neg_infinity.sinh(), content="-Infinity")
/// }
/// ```
pub fn sinh(self : Float) -> Float {
  let mut h : Float = 0.5
  let mut ix = self.reinterpret_as_uint()
  if (ix >> 31) != 0 {
    h = -h
  }
  // |self|
  ix = ix & 0x7fffffff
  let absx = ix.reinterpret_as_float()
  let w = ix

  // |self| < log(FLT_MAX)
  if w < 0x42b17217 {
    let t = absx.expm1()
    if w < 0x3f800000 {
      if w < 0x3f800000U - (12U << 23) {
        return self
      }
      return h * ((2.0 : Float) * t - t * t / (t + 1.0))
    }
    return h * (t + t / (t + 1.0))
  }

  // |self| > logf(FLT_MAX) or nan
  h * k_expo2f(absx) * 2.0
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
/// ```moonbit
/// test "cosh" {
///   inspect!((0.0 : Float).cosh(), content="1")
///   inspect!((-0.0).cosh(), content="1")
///   inspect!((1.0 : Float).cosh(), content="1.5430805683135986")
///   inspect!((2.0: Float).cosh(), content="3.7621958255767822")
///   inspect!((1000.0: Float).cosh(), content="Infinity")
///   inspect!((-1000.0 : Float).cosh(), content="Infinity")
///   inspect!(@float.not_a_number.cosh(), content="NaN")
///   inspect!(@float.infinity.cosh(), content="Infinity")
///   inspect!(@float.neg_infinity.cosh(), content="Infinity")
/// }
/// ```
pub fn cosh(self : Float) -> Float {
  let mut x = self
  let mut ix = x.reinterpret_as_uint()
  ix = ix & 0x7fffffff
  x = ix.reinterpret_as_float()
  let w = ix

  // |x| < log(2)
  if w < 0x3f317217 {
    if w < 0x3f800000U - (12U << 23) {
      return 1.0
    }
    let t = x.expm1()
    return (1.0 : Float) + t * t / ((2.0 : Float) * (t + 1.0))
  }

  // |x| < log(FLT_MAX)
  if w < 0x42b17217 {
    let t = x.exp()
    return (t + (1.0 : Float) / t) * 0.5
  }

  // |x| > log(FLT_MAX) or nan
  k_expo2f(x)
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
/// ```moobit
/// test "tanh" {
///   inspect!((0.0 : Float).tanh(), content="0")
///   inspect!((-0.0 : Float).tanh(), content="0")
///   inspect!((1.0 : Float).tanh(), content="0.7615941559557649")
///   inspect!((2.0 : Float).tanh(), content="0.9640275800758169")
///   inspect!((1000.0 : Float).tanh(), content="1")
///   inspect!((-1000.0 : Float).tanh(), content="-1")
///   inspect!(@float.not_a_number.tanh(), content="NaN")
///   inspect!(@float.infinity.tanh(), content="1")
///   inspect!(@float.neg_infinity.tanh(), content="-1")
/// }
/// ```
pub fn tanh(self : Float) -> Float {
  let mut ix = self.reinterpret_as_uint()
  let sign = (ix >> 31) != 0
  ix = ix & 0x7fffffff
  let x = ix.reinterpret_as_float()
  let w = ix
  let tt = if w > 0x3f0c9f54 {
    // |x| > log(3)/2 ~= 0.5493 or nan
    if w > 0x41200000 {
      // |x| > 10 */
      (1.0 : Float) + (0.0 : Float) / x
    } else {
      let t = (x * 2.0).expm1()
      (1.0 : Float) - (2.0 : Float) / (t + 2.0)
    }
  } else if w > 0x3e82c578 {
    // |x| > log(5/3)/2 ~= 0.2554
    let t = (x * 2.0).expm1()
    t / (t + 2.0)
  } else if w >= 0x00800000 {
    // |x| >= 0x1p-126
    let t = (x * -2.0).expm1()
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
/// ```moonbit
/// test "asinh" {
///   inspect!((0.0 : Float).asinh(), content="0")
///   inspect!((-0.0 : Float).asinh(), content="0")
///   inspect!((1.0 : Float).asinh(), content="0.8813735842704773")
///   inspect!((2.0 : Float).asinh(), content="1.4436354637145996")
///   inspect!((1000.0 : Float).asinh(), content="7.600902557373047")
///   inspect!(@float.not_a_number.asinh(), content="NaN")
///   inspect!(@float.infinity.asinh(), content="Infinity")
///   inspect!(@float.neg_infinity.asinh(), content="-Infinity")
/// }
/// ```
pub fn asinh(self : Float) -> Float {
  let u = self.reinterpret_as_uint()
  let i = u & 0x7fffffff
  let sign = (u >> 31) != 0
  let ln2 : Float = 0.693147180559945309417232121458176568
  let x = i.reinterpret_as_float()
  let x = if i >= 0x3f800000U + (12U << 23) {
    // |x| >= 0x1p12 or inf or nan
    x.ln() + ln2
  } else if i >= 0x3f800000U + (1U << 23) {
    // |x| >= 2
    (x * 2.0 + (1.0 : Float) / ((x * x + 1.0).sqrt() + x)).ln()
  } else if i >= 0x3f800000U - (12U << 23) {
    // |x| >= 0x1p-12, up to 1.6ulp error in [0.125,0.5]
    (x + x * x / ((x * x + 1.0).sqrt() + 1.0)).ln_1p()
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
/// ```moonbit
/// test "acosh" {
///   inspect!((1.0 : Float).acosh(), content="0")
///   inspect!((2.0 : Float).acosh(), content="1.316957950592041")
///   inspect!((1000.0 : Float).acosh(), content="7.600902080535889")
///   inspect!((-1.0 : Float).acosh(), content="NaN")
///   inspect!((-2.0 : Float).acosh(), content="NaN")
///   inspect!(@float.not_a_number.acosh(), content="NaN")
///   inspect!(@float.infinity.acosh(), content="Infinity")
///   inspect!(@float.neg_infinity.acosh(), content="NaN")
/// }
/// ```
pub fn acosh(self : Float) -> Float {
  let x = self
  let ln2 : Float = 693147180559945309417232121458176568
  let u = x.reinterpret_as_uint()
  let a = u & 0x7fffffffU
  if a < 0x3f800000U + (1U << 23) {
    // |x| < 2, invalid if x < 1 or nan */
    // up to 2ulp error in [1,1.125] */
    return (x - 1.0 + ((x - 1.0) * (x - 1.0) + (2.0 : Float) * (x - 1.0)).sqrt()).ln_1p()
  }
  if a < 0x3f800000U + (12U << 23) {
    // |x| < 0x1p12 */
    return (x * 2.0 - (1.0 : Float) / (x + (x * x - 1.0).sqrt())).ln()
  }
  // x >= 0x1p12 */
  return x.ln() + ln2
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
/// ```moonbit
/// test "atanh" {
///   inspect!((0.0 : Float).atanh(), content="0")
///   inspect!((-0.0 : Float).atanh(), content="0")
///   inspect!((0.5 : Float).atanh(), content="0.5493061542510986")
///   inspect!((-0.5 : Float).atanh(), content="-0.5493061542510986")
///   inspect!((1.0 : Float).atanh(), content="Infinity")
///   inspect!((-1.0 : Float).atanh(), content="-Infinity")
///   inspect!((1.5 : Float).atanh(), content="NaN")
///   inspect!(@float.not_a_number.atanh(), content="NaN")
///   inspect!(@float.infinity.atanh(), content="NaN")
///   inspect!(@float.neg_infinity.atanh(), content="NaN")
/// }
/// ```
pub fn atanh(self : Float) -> Float {
  let x = self
  let u = x.reinterpret_as_uint()
  let sign = (u >> 31) != 0
  let u = u & 0x7fffffff
  let x = u.reinterpret_as_float()
  let x = if u < 0x3f800000U - (1U << 23) {
    if u < 0x3f800000U - (32U << 23) {
      x
    } else {
      // |x| < 0.5, up to 1.7ulp error
      (x * 2.0 + x * 2.0 * x / ((1.0 : Float) - x)).ln_1p() * 0.5
    }
  } else {
    // avoid overflow
    (x / ((1.0 : Float) - x) * 2.0).ln_1p() * 0.5
  }
  if sign {
    -x
  } else {
    x
  }
}
