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
/// Computes `e` raised to the power of a given number.
///
/// Parameters:
///
/// * `self` : The exponent value to compute `e^x`.
///
/// Returns the value of `e^x`, where `e` is Euler's number (approximately
/// 2.71828).
///
/// Special cases:
///
/// * Returns `x` if `x` is `infinity` (positive infinity)
/// * Returns `0` if `x` is negative infinity
/// * Returns `NaN` if `x` is `NaN`
/// * Returns `1` if `x` is `0`
///
/// Example:
///
/// ```moonbit
///   inspect(0.0.exp(), content="1")
///   inspect(1.0.exp(), content="2.718281828459045")
///   inspect((-1.0).exp(), content="0.36787944117144233")
///   inspect(not_a_number.exp().is_nan(), content="true")
/// ```
pub fn Double::exp(self : Double) -> Double = "Math" "exp"

///|
/// Calculates exp(x) - 1 accurately even when x is close to zero.
///
/// Parameters:
///
/// * `self` : The exponent.
///
/// Returns e raised to the power of `self`, minus 1.
///
/// Special Cases:
///
/// * Returns NaN if `self` is NaN.
/// * Returns -1 if `self` is negative infinity.
/// * Returns `Infinity` if `self` is positive infinity.
///
/// Example
///
/// ```moonbit
///   inspect(0.0.expm1(), content="0")
///   inspect(1.0.expm1(), content="1.718281828459045")
///   inspect(2.0.expm1(), content="6.38905609893065")
///   inspect((-1.0).expm1(), content="-0.6321205588285577")
///   inspect((-2.0).expm1(), content="-0.8646647167633873")
///   inspect(@double.not_a_number.expm1(), content="NaN")
///   inspect(@double.infinity.expm1(), content="Infinity")
///   inspect(@double.neg_infinity.expm1(), content="-1")
/// ```
pub fn Double::expm1(self : Double) -> Double = "Math" "expm1"
