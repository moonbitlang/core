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
/// Computes `e` raised to the power of a given number.
///
/// Parameters:
///
/// * `x` : The exponent value to compute `e^x`.
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
/// ```mbt check
/// test {
///   inspect(@math.exp(0.0), content="1")
///   inspect(@math.exp(1.0), content="2.718281828459045")
///   inspect(@math.exp(-1.0), content="0.36787944117144233")
///   inspect(@math.exp(@double.not_a_number), content="NaN")
/// }
/// ```
pub fn exp(x : Double) -> Double = "Math" "exp"

///|
/// Calculates exp(x) - 1 accurately even when x is close to zero.
///
/// Parameters:
///
/// * `x` : The exponent.
///
/// Returns e raised to the power of `x`, minus 1.
///
/// Special Cases:
///
/// * Returns NaN if `x` is NaN.
/// * Returns -1 if `x` is negative infinity.
/// * Returns `Infinity` if `x` is positive infinity.
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.expm1(0.0), content="0")
///   inspect(@math.expm1(1.0), content="1.718281828459045")
///   inspect(@math.expm1(2.0), content="6.38905609893065")
///   inspect(@math.expm1(-1.0), content="-0.6321205588285577")
///   inspect(@math.expm1(-2.0), content="-0.8646647167633873")
///   inspect(@math.expm1(@double.not_a_number), content="NaN")
///   inspect(@math.expm1(@double.infinity), content="Infinity")
///   inspect(@math.expm1(@double.neg_infinity), content="-1")
/// }
/// ```
pub fn expm1(x : Double) -> Double = "Math" "expm1"
