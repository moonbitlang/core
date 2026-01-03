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
/// ```mbt check
/// test {
///   inspect(@math.sin(0.0), content="0")
///   inspect(@math.sin(1.570796326794897), content="1") // pi / 2
///   inspect(@math.sin(2.0), content="0.9092974268256817")
///   inspect(@math.sin(-5.0), content="0.9589242746631385")
///   inspect(@math.sin(31415926535897.9323846), content="0.0012091232715481885")
///   inspect(@math.sin(@double.not_a_number), content="NaN")
///   inspect(@math.sin(@double.infinity), content="NaN")
///   inspect(@math.sin(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn sin(x : Double) -> Double = "Math" "sin"

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
/// ```mbt check
/// test {
///   inspect(@math.cos(0.0), content="1")
///   inspect(@math.cos(2.5), content="-0.8011436155469337")
///   inspect(@math.cos(-3.141592653589793), content="-1") // -pi
///   inspect(@math.cos(-5.0), content="0.28366218546322625")
///   inspect(@math.cos(31415926535897.9323846), content="0.9999992690101899")
///   inspect(@math.cos(@double.not_a_number), content="NaN")
///   inspect(@math.cos(@double.infinity), content="NaN")
///   inspect(@math.cos(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn cos(x : Double) -> Double = "Math" "cos"

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
/// ```mbt check
/// test {
///   inspect(@math.tan(0.0), content="0")
///   inspect(@math.tan(0.7853981633974483), content="0.9999999999999999")
///   inspect(@math.tan(4.0), content="1.1578212823495777")
///   inspect(@math.tan(5.0), content="-3.380515006246586")
///   inspect(@math.tan(31415926535897.9323846), content="0.0012091241554056254")
///   inspect(@math.tan(@double.not_a_number), content="NaN")
///   inspect(@math.tan(@double.infinity), content="NaN")
///   inspect(@math.tan(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn tan(x : Double) -> Double = "Math" "tan"

///|
/// Calculates the arcsine of a number. Handles special cases and edge conditions
/// according to IEEE 754 standards.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the arcsine.
///
/// Returns the arcsine of the number `x`.
///
/// * Returns NaN if the input is NaN.
/// * Returns NaN if the input is less than -1 or greater than 1.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.asin(0.0), content="0")
///   inspect(@math.asin(1.0), content="1.5707963267948966")
///   inspect(@math.asin(-1.0), content="-1.5707963267948966")
///   inspect(@math.asin(@double.not_a_number), content="NaN")
///   inspect(@math.asin(@double.infinity), content="NaN")
///   inspect(@math.asin(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn asin(x : Double) -> Double = "Math" "asin"

///|
/// Calculates the arccosine of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the arccosine.
///
/// Returns the arccosine of the number `x`.
///
/// * Returns NaN if the input is NaN.
/// * Returns NaN if the input is less than -1 or greater than 1.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.acos(0.0), content="1.5707963267948966")
///   inspect(@math.acos(1.0), content="0")
///   inspect(@math.acos(-1.0), content="3.141592653589793")
///   inspect(@math.acos(@double.not_a_number), content="NaN")
///   inspect(@math.acos(@double.infinity), content="NaN")
///   inspect(@math.acos(@double.neg_infinity), content="NaN")
///   inspect(@math.acos(0.0), content="1.5707963267948966")
/// }
/// ```
pub fn acos(x : Double) -> Double = "Math" "acos"

///|
/// Calculates the arctangent of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the arctangent.
///
/// Returns the arctangent of the number `x`.
///
/// Example:
///
/// * Returns NaN if the input is NaN.
///
/// ```mbt check
/// test {
///   inspect(@math.atan(0.0), content="0")
///   inspect(@math.atan(1.0), content="0.7853981633974483")
///   inspect(@math.atan(-1.0), content="-0.7853981633974483")
///   inspect(@math.atan(@double.not_a_number), content="NaN")
///   inspect(@math.atan(@double.infinity), content="1.5707963267948966")
///   inspect(@math.atan(@double.neg_infinity), content="-1.5707963267948966")
/// }
/// ```
pub fn atan(x : Double) -> Double = "Math" "atan"

///|
/// Calculates the arctangent of the quotient of two numbers.
///
/// Parameters:
///
/// * `y` : The numerator of the quotient.
/// * `x` : The denominator of the quotient.
///
/// Returns the arctangent of the quotient `y / x`.
///
/// * Returns NaN if y or x is NaN.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.atan2(0.0, -1.0), content="3.141592653589793")
///   inspect(@math.atan2(1.0, 0.0), content="1.5707963267948966")
///   inspect(@math.atan2(1.0, 1.0), content="0.7853981633974483")
///   inspect(@math.atan2(@double.not_a_number, 1.0), content="NaN")
///   inspect(@math.atan2(1.0, @double.not_a_number), content="NaN")
///   inspect(@math.atan2(@double.infinity, 1.0), content="1.5707963267948966")
///   inspect(@math.atan2(1.0, @double.infinity), content="0")
///   inspect(@math.atan2(@double.neg_infinity, 1.0), content="-1.5707963267948966")
///   inspect(@math.atan2(1.0, @double.neg_infinity), content="3.141592653589793")
///   inspect(
///     @math.atan2(@double.infinity, @double.infinity),
///     content="0.7853981633974483",
///   )
///   inspect(
///     @math.atan2(@double.neg_infinity, @double.neg_infinity),
///     content="-2.356194490192345",
///   )
///   inspect(
///     @math.atan2(@double.infinity, @double.neg_infinity),
///     content="2.356194490192345",
///   )
///   inspect(
///     @math.atan2(@double.neg_infinity, @double.infinity),
///     content="-0.7853981633974483",
///   )
/// }
/// ```
pub fn atan2(y : Double, x : Double) -> Double = "Math" "atan2"
