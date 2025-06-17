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
///   inspect((0.0 : Float).sinh(), content="0")
///   inspect((-0.0 : Float).sinh(), content="0")
///   inspect((1.0 : Float).sinh(), content="1.175201177597046")
///   inspect((2.0 : Float).sinh(), content="3.6268603801727295")
///   inspect((1000.0 : Float).sinh(), content="Infinity")
///   inspect((-1000.0 : Float).sinh(), content="-Infinity")
///   inspect(@float.not_a_number.sinh(), content="NaN")
///   inspect(@float.infinity.sinh(), content="Infinity")
///   inspect(@float.neg_infinity.sinh(), content="-Infinity")
/// ```
pub fn Float::sinh(self : Float) -> Float {
  self.to_double().sinh().to_float()
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
///   inspect((0.0 : Float).cosh(), content="1")
///   inspect((-0.0).cosh(), content="1")
///   inspect((1.0 : Float).cosh(), content="1.5430806875228882")
///   inspect((2.0: Float).cosh(), content="3.762195587158203")
///   inspect((1000.0: Float).cosh(), content="Infinity")
///   inspect((-1000.0 : Float).cosh(), content="Infinity")
///   inspect(@float.not_a_number.cosh(), content="NaN")
///   inspect(@float.infinity.cosh(), content="Infinity")
///   inspect(@float.neg_infinity.cosh(), content="Infinity")
/// ```
pub fn Float::cosh(self : Float) -> Float {
  self.to_double().cosh().to_float()
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
///   inspect((0.0 : Float).tanh(), content="0")
///   inspect((-0.0 : Float).tanh(), content="0")
///   inspect((1.0 : Float).tanh(), content="0.7615941559557649")
///   inspect((2.0 : Float).tanh(), content="0.9640275800758169")
///   inspect((1000.0 : Float).tanh(), content="1")
///   inspect((-1000.0 : Float).tanh(), content="-1")
///   inspect(@float.not_a_number.tanh(), content="NaN")
///   inspect(@float.infinity.tanh(), content="1")
///   inspect(@float.neg_infinity.tanh(), content="-1")
/// ```
pub fn Float::tanh(self : Float) -> Float {
  self.to_double().tanh().to_float()
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
///   inspect((0.0 : Float).asinh(), content="0")
///   inspect((-0.0 : Float).asinh(), content="0")
///   inspect((1.0 : Float).asinh(), content="0.8813735842704773")
///   inspect((2.0 : Float).asinh(), content="1.4436354637145996")
///   inspect((1000.0 : Float).asinh(), content="7.600902557373047")
///   inspect(@float.not_a_number.asinh(), content="NaN")
///   inspect(@float.infinity.asinh(), content="Infinity")
///   inspect(@float.neg_infinity.asinh(), content="-Infinity")
/// ```
pub fn Float::asinh(self : Float) -> Float {
  self.to_double().asinh().to_float()
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
///   inspect((1.0 : Float).acosh(), content="0")
///   inspect((2.0 : Float).acosh(), content="1.316957950592041")
///   inspect((1000.0 : Float).acosh(), content="7.600902080535889")
///   inspect((-1.0 : Float).acosh(), content="NaN")
///   inspect((-2.0 : Float).acosh(), content="NaN")
///   inspect(@float.not_a_number.acosh(), content="NaN")
///   inspect(@float.infinity.acosh(), content="Infinity")
///   inspect(@float.neg_infinity.acosh(), content="NaN")
/// ```
pub fn Float::acosh(self : Float) -> Float {
  self.to_double().acosh().to_float()
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
///   inspect((0.0 : Float).atanh(), content="0")
///   inspect((-0.0 : Float).atanh(), content="0")
///   inspect((0.5 : Float).atanh(), content="0.5493061542510986")
///   inspect((-0.5 : Float).atanh(), content="-0.5493061542510986")
///   inspect((1.0 : Float).atanh(), content="Infinity")
///   inspect((-1.0 : Float).atanh(), content="-Infinity")
///   inspect((1.5 : Float).atanh(), content="NaN")
///   inspect(@float.not_a_number.atanh(), content="NaN")
///   inspect(@float.infinity.atanh(), content="NaN")
///   inspect(@float.neg_infinity.atanh(), content="NaN")
/// ```
pub fn Float::atanh(self : Float) -> Float {
  self.to_double().atanh().to_float()
}
