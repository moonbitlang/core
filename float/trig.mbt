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
/// Calculates the sine of a floating-point number in radians.
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
///   inspect!((0.0 : Float).sin(), content="0")
///   inspect!((2.0 : Float).sin(), content="0.9092974066734314")
///   inspect!((-5.0 : Float).sin(), content="0.9589242935180664")
///   inspect!(@float.not_a_number.sin(), content="NaN")
///   inspect!(@float.infinity.sin(), content="NaN")
///   inspect!(@float.neg_infinity.sin(), content="NaN")
/// }
/// ```
pub fn sin(self : Float) -> Float {
  self.to_double().sin().to_float()
}

///|
/// Calculates the cosine of a floating-point number in radians.
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
///   inspect!((0.0 : Float).cos(), content="1")
///   inspect!((2.0 : Float).cos(), content="-0.416146844625473")
///   inspect!((-5.0 : Float).cos(), content="0.28366219997406006")
///   inspect!(@float.not_a_number.cos(), content="NaN")
///   inspect!(@float.infinity.cos(), content="NaN")
///   inspect!(@float.neg_infinity.cos(), content="NaN")
/// }
/// ```
pub fn cos(self : Float) -> Float {
  self.to_double().cos().to_float()
}

///|
/// Calculates the tangent of a floating-point number in radians.
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
///   inspect!((0.0 : Float).tan(), content="0")
///   inspect!((2.0 : Float).tan(), content="-2.185039758682251")
///   inspect!((-5.0 : Float).tan(), content="3.3805150985717773")
///   inspect!(@float.not_a_number.tan(), content="NaN")
///   inspect!(@float.infinity.tan(), content="NaN")
///   inspect!(@float.neg_infinity.tan(), content="NaN")
/// }
/// ```
pub fn tan(self : Float) -> Float {
  self.to_double().tan().to_float()
}

///|
/// Calculates the arcsine of a floating-point number.
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
/// ```moonbit
/// test "asin" {
///   inspect!((0.0 : Float).asin(), content="0")
///   inspect!((1.0 : Float).asin(), content="1.5707963705062866")
///   inspect!((-1.0 : Float).asin(), content="-1.5707963705062866")
///   inspect!(@float.not_a_number.asin(), content="NaN")
///   inspect!(@float.infinity.asin(), content="NaN")
///   inspect!(@float.neg_infinity.asin(), content="NaN")
/// }
/// ```
pub fn asin(self : Float) -> Float {
  self.to_double().asin().to_float()
}

///|
/// Calculates the arccosine of a floating-point number.
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
/// ```moonbit
/// test "acos" {
///   inspect!((0.0 : Float).acos(), content="1.5707963705062866")
///   inspect!((1.0 : Float).acos(), content="0")
///   inspect!((-1.0 : Float).acos(), content="3.1415927410125732")
///   inspect!(@float.not_a_number.acos(), content="NaN")
///   inspect!(@float.infinity.acos(), content="NaN")
///   inspect!(@float.neg_infinity.acos(), content="NaN")
/// }
/// ```
pub fn acos(self : Float) -> Float {
  self.to_double().acos().to_float()
}

///|
/// Calculates the arctangent of a floating-point number.
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
/// ```moonbit
/// test "atan" {
///   inspect!((0.0 : Float).atan(), content="0")
///   inspect!((1.0 : Float).atan(), content="0.7853981852531433")
///   inspect!((-1.0 : Float).atan(), content="-0.7853981852531433")
///   inspect!(@float.not_a_number.atan(), content="NaN")
///   inspect!(@float.infinity.atan(), content="1.5707963705062866")
///   inspect!(@float.neg_infinity.atan(), content="-1.5707963705062866")
/// }
/// ```
pub fn atan(self : Float) -> Float {
  self.to_double().atan().to_float()
}

///|
/// Calculates the arctangent of the quotient of two floating-point numbers.
///
/// Parameters:
///
/// * `self` : The numerator of the quotient.
/// * `x` : The denominator of the quotient.
///
/// Returns the arctangent of the quotient `self / x`.
///
/// * Returns NaN if self or x is NaN.
///
/// Example:
///
/// ```moonbit
/// test "atan2" {
///   inspect!((0.0 : Float).atan2(-1.0), content="3.1415927410125732")
///   inspect!((1.0 : Float).atan2(0.0), content="1.5707963705062866")
///   inspect!((1.0 : Float).atan2(1.0), content="0.7853981852531433")
///   inspect!(@float.not_a_number.atan2(1.0), content="NaN")
///   inspect!((1.0 : Float).atan2(not_a_number), content="NaN")
///   inspect!(@float.infinity.atan2(1.0), content="1.5707963705062866")
///   inspect!((1.0 : Float).atan2(infinity), content="0")
///   inspect!(@float.neg_infinity.atan2(1.0), content="-1.5707963705062866")
///   inspect!((1.0 : Float).atan2(@float.neg_infinity), content="3.1415927410125732")
///   inspect!(@float.infinity.atan2(@float.infinity), content="0.7853981852531433")
///   inspect!(@float.neg_infinity.atan2(@float.neg_infinity), content="-2.356194496154785")
///   inspect!(@float.infinity.atan2(@float.neg_infinity), content="2.356194496154785")
///   inspect!(@float.neg_infinity.atan2(@float.infinity), content="-0.7853981852531433")
/// }
/// ```
pub fn atan2(self : Float, other : Float) -> Float {
  self.to_double().atan2(other.to_double()).to_float()
}
