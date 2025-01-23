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
/// Calculates the sine of a number in radians. Handles special cases and edge
/// conditions according to IEEE 754 standards.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the sine.
///
/// Returns the sine of the angle `x`.
///
/// Example:
///
/// ```moonbit
/// test "sin" {
///   inspect!(0.0.sin(), content="0")
///   inspect!(1.570796326794897.sin(), content="1") // pi / 2
///   inspect!(2.0.sin(), content="0.9092974268256817")
///   inspect!(-5.0.sin(), content="0.9589242746631385")
///   inspect!(31415926535897.9323846.sin(), content="0.0012091232715481885")
///   inspect!(@double.not_a_number.sin(), content="NaN")
///   inspect!(@double.infinity.sin(), content="NaN")
///   inspect!(@double.neg_infinity.sin(), content="NaN")
/// }
/// ```
pub fn sin(self : Double) -> Double = "Math" "sin"

///|
/// Calculates the cosine of a number in radians. Handles special cases and edge
/// conditions according to IEEE 754 standards.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the cosine.
///
/// Returns the cosine of the angle `x`.
///
/// Example:
///
/// ```moonbit
/// test "cos" {
///   inspect!(0.0.cos(), content="1")
///   inspect!(2.5.cos(), content="-0.8011436155469337")
///   inspect!((-3.141592653589793).cos(), content="-1") // -pi
///   inspect!((-5.0).cos(), content="0.28366218546322625")
///   inspect!(31415926535897.9323846.cos(), content="0.9999992690101899")
///   inspect!(@double.not_a_number.cos(), content="NaN")
///   inspect!(@double.infinity.cos(), content="NaN")
///   inspect!(@double.neg_infinity.cos(), content="NaN")
/// }
/// ```
pub fn cos(self : Double) -> Double = "Math" "cos"

///|
/// Calculates the tangent of a number in radians. Handles special cases and edge
/// conditions according to IEEE 754 standards.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the tangent.
///
/// Returns the tangent of the angle `x`.
///
/// Example:
///
/// ```moonbit
/// test "tan" {
///   inspect!(0.0.tan(), content="0")
///   inspect!(0.7853981633974483.tan(), content="0.9999999999999999")
///   inspect!(4.0.tan(), content="1.1578212823495777")
///   inspect!(5.0.tan(), content="-3.380515006246586")
///   inspect!(31415926535897.9323846.tan(), content="0.0012091241554056254")
///   inspect!(@double.not_a_number.tan(), content="NaN")
///   inspect!(@double.infinity.tan(), content="NaN")
///   inspect!(@double.neg_infinity.tan(), content="NaN")
/// }
/// ```
pub fn tan(self : Double) -> Double = "Math" "tan"
