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
/// Calculates the hyperbolic sine of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the hyperbolic sine.
///
/// Returns the hyperbolic sine of `self`.
///
/// Special cases:
///
/// * Returns `infinity` if `self` is `infinity`
/// * Returns `NaN` if `self` is `NaN`
///
/// Example:
///
/// ```moonbit
///   inspect(0.0.sinh(), content="0")
///   inspect((-0.0).sinh(), content="0")
///   inspect(1.0.sinh(), content="1.1752011936438014")
///   inspect(2.0.sinh(), content="3.626860407847019")
///   inspect(1000.0.sinh(), content="Infinity")
///   inspect((-1000.0).sinh(), content="-Infinity")
///   inspect(@double.not_a_number.sinh(), content="NaN")
///   inspect(@double.infinity.sinh(), content="Infinity")
///   inspect(@double.neg_infinity.sinh(), content="-Infinity")
/// ```
pub fn Double::sinh(self : Double) -> Double = "Math" "sinh"

///|
/// Calculates the hyperbolic cosine of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the hyperbolic cosine.
///
/// Returns the hyperbolic cosine of `self`.
///
/// Special cases:
///
/// * Returns `infinity` if `self` is `infinity`
/// * Returns `NaN` if `self` is `NaN`
///
/// Example
///
/// ```moonbit
///   inspect(0.0.cosh(), content="1")
///   inspect((-0.0).cosh(), content="1")
///   inspect(1.0.cosh(), content="1.5430806348152437")
///   inspect(2.0.cosh(), content="3.7621956910836314")
///   inspect(1000.0.cosh(), content="Infinity")
///   inspect((-1000.0).cosh(), content="Infinity")
///   inspect(@double.not_a_number.cosh(), content="NaN")
///   inspect(@double.infinity.cosh(), content="Infinity")
///   inspect(@double.neg_infinity.cosh(), content="Infinity")
/// ```
pub fn Double::cosh(self : Double) -> Double = "Math" "cosh"

///|
/// Calculates the hyperbolic tangent of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the hyperbolic tangent.
///
/// Returns the hyperbolic tangent of `self`.
///
/// Special cases:
///
/// * Returns `NaN` if `self` is `NaN`
/// * Returns `1` if `self` is `infinity`
/// * Returns `-1` if `self` is `-infinity`
///
/// Example
///
/// ```moobit
///   inspect(0.0.tanh(), content="0")
///   inspect((-0.0).tanh(), content="0")
///   inspect(1.0.tanh(), content="0.7615941559557649")
///   inspect(2.0.tanh(), content="0.9640275800758169")
///   inspect(1000.0.tanh(), content="1")
///   inspect((-1000.0).tanh(), content="-1")
///   inspect(@double.not_a_number.tanh(), content="NaN")
///   inspect(@double.infinity.tanh(), content="1")
///   inspect(@double.neg_infinity.tanh(), content="-1")
/// ```
pub fn Double::tanh(self : Double) -> Double = "Math" "tanh"

///|
/// Calculates the inverse hyperbolic sine of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the inverse hyperbolic sine.
///
/// Returns the inverse hyperbolic sine of `self`.
///
/// Special cases:
///
/// * Returns `NaN` if `self` is `NaN`
/// * Returns `infinity` if `self` is `infinity`
///
/// Example
///
/// ```moonbit
///   inspect(0.0.asinh(), content="0")
///   inspect((-0.0).asinh(), content="0")
///   inspect(1.0.asinh(), content="0.881373587019543")
///   inspect(2.0.asinh(), content="1.4436354751788103")
///   inspect(1000.0.asinh(), content="7.600902709541988")
///   inspect((-1000.0).asinh(), content="-7.600902709541988")
///   inspect(@double.not_a_number.asinh(), content="NaN")
///   inspect(@double.infinity.asinh(), content="Infinity")
///   inspect(@double.neg_infinity.asinh(), content="-Infinity")
/// ```
pub fn Double::asinh(self : Double) -> Double = "Math" "asinh"

///|
/// Calculates the inverse hyperbolic cosine of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the inverse hyperbolic cosine.
///
/// Returns the inverse hyperbolic cosine of `self`.
///
/// Special cases:
///
/// * Returns `NaN` if `self` is less than `1`.
/// * Returns `NaN` if `self` is `NaN`.
/// * Returns `0` if `self` is `1`.
/// * Returns `infinity` if `self` is `infinity` (Positive infinity).
///
/// Example
///
/// ```moonbit
///   inspect(1.0.acosh(), content="0")
///   inspect(2.0.acosh(), content="1.3169578969248166")
///   inspect(1000.0.acosh(), content="7.600902209541989")
///   inspect((-1.0).acosh(), content="NaN")
///   inspect((-2.0).acosh(), content="NaN")
///   inspect(@double.not_a_number.acosh(), content="NaN")
///   inspect(@double.infinity.acosh(), content="Infinity")
///   inspect(@double.neg_infinity.acosh(), content="NaN")
/// ```
pub fn Double::acosh(self : Double) -> Double = "Math" "acosh"

///|
/// Calculates the inverse hyperbolic tangent of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the inverse hyperbolic tangent.
///
/// Returns the inverse hyperbolic tangent of `self`.
///
/// Special cases:
///
/// * Returns `NaN` if `self` is less than `-1` or greater than `1`.
/// * Returns `infinity` if `self` is `1`.
/// * Returns `-infinity` if `self` is `-1`.
///
/// Example
///
/// ```moonbit
///   inspect(0.0.atanh(), content="0")
///   inspect((-0.0).atanh(), content="0")
///   inspect(0.5.atanh(), content="0.5493061443340548")
///   inspect((-0.5).atanh(), content="-0.5493061443340548")
///   inspect(1.0.atanh(), content="Infinity")
///   inspect((-1.0).atanh(), content="-Infinity")
///   inspect(1.5.atanh(), content="NaN")
///   inspect(@double.not_a_number.atanh(), content="NaN")
///   inspect(@double.infinity.atanh(), content="NaN")
///   inspect(@double.neg_infinity.atanh(), content="NaN")
/// ```
pub fn Double::atanh(self : Double) -> Double = "Math" "atanh"
