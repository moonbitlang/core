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
/// Calculates the natural logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `x`: The input number.
///
/// Returns the natural logarithm of the input number, with the following special
/// cases:
///
/// * Returns NaN if the input is NaN or negative
/// * Returns negative infinity if the input is zero
/// * Returns the input if it is positive infinity
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.ln(2.0), content="0.6931471805599453")
///   inspect(@math.ln(1.0), content="0")
///   inspect(@math.ln(-1.0), content="NaN")
///   inspect(@math.ln(0.0), content="-Infinity")
/// }
/// ```
pub fn ln(x : Double) -> Double = "Math" "log"

///|
/// Calculates the base-2 logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `x` : A double-precision floating-point number.
///
/// Returns the base-2 logarithm of the input number.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.log2(2.0), content="1")
///   inspect(@math.log2(0.5), content="-1")
///   inspect(@math.log2(3.0), content="1.584962500721156")
/// }
/// ```
pub fn log2(x : Double) -> Double = "Math" "log2"

///|
/// Calculates the base-10 logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `x` : The double-precision floating-point number to calculate the
/// logarithm of.
///
/// Returns a double-precision floating-point number representing the base-10
/// logarithm of the input.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.log10(1.0), content="0")
///   inspect(@math.log10(10.0), content="1")
///   inspect(@math.log10(100.0), content="2")
/// }
/// ```
pub fn log10(x : Double) -> Double = "Math" "log10"

///|
/// Calculates ln(1 + x) accurately even when x is close to zero.
///
/// Parameters:
///
/// * `x` : The number to which 1 is added before calculating the logarithm.
///
/// Returns the natural logarithm of 1 + `x`.
///
/// Special Cases:
///
/// * Returns NaN if `x` is NaN or less than -1.
/// * Returns -INF if `x` is -1.
/// * Returns +INF if `x` is +INF.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.ln_1p(0.0), content="0")
///   inspect(@math.ln_1p(1.0), content="0.6931471805599453")
///   inspect(@math.ln_1p(2.0), content="1.0986122886681096")
///   inspect(@math.ln_1p(@double.not_a_number), content="NaN")
///   inspect(@math.ln_1p(-1.0), content="-Infinity")
///   inspect(@math.ln_1p(-2.0), content="NaN")
///   inspect(@math.ln_1p(@double.infinity), content="Infinity")
///   inspect(@math.ln_1p(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn ln_1p(x : Double) -> Double = "Math" "log1p"
