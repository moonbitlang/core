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
/// Calculates the natural logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `self`: The input number.
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
/// ```moonbit
/// test "ln" {
///   inspect!(2.0.ln(), content="0.6931471805599453")
///   inspect!(1.0.ln(), content="0")
///   inspect!((-1.0).ln(), content="NaN")
///   inspect!(0.0.ln(), content="-Infinity")
/// }
/// ```
pub fn ln(self : Double) -> Double = "Math" "log"

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
/// ```moonbit
/// test "log2" {
///   inspect!(2.0.log2(), content="1")
///   inspect!(0.5.log2(), content="-1")
///   inspect!(3.0.log2(), content="1.584962500721156")
/// }
/// ```
pub fn log2(self : Double) -> Double = "Math" "log2"

///|
/// Calculates the base-10 logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to calculate the
/// logarithm of.
///
/// Returns a double-precision floating-point number representing the base-10
/// logarithm of the input.
///
/// Example:
///
/// ```moonbit
/// test "log10" {
///   inspect!(1.0.log10(), content="0")
///   inspect!(10.0.log10(), content="1")
///   inspect!(100.0.log10(), content="2")
/// }
/// ```
pub fn log10(self : Double) -> Double = "Math" "log10"
