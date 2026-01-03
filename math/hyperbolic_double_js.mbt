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
pub fn sinh(x : Double) -> Double = "Math" "sinh"

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
pub fn cosh(x : Double) -> Double = "Math" "cosh"

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
pub fn tanh(x : Double) -> Double = "Math" "tanh"

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
pub fn asinh(x : Double) -> Double = "Math" "asinh"

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
///   inspect(@math.acosh(-1.0), content="NaN")
///   inspect(@math.acosh(-2.0), content="NaN")
///   inspect(@math.acosh(@double.not_a_number), content="NaN")
///   inspect(@math.acosh(@double.infinity), content="Infinity")
///   inspect(@math.acosh(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn acosh(x : Double) -> Double = "Math" "acosh"

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
///   inspect(@math.atanh(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn atanh(x : Double) -> Double = "Math" "atanh"
