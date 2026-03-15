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
/// Represents the Not a Number (NaN) value in floating-point arithmetic. NaN is
/// used to represent undefined or unrepresentable values, such as the result of
/// 0.0/0.0.
///
/// Returns a special floating-point value that represents NaN.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@float.not_a_number.is_nan(), content="true")
///   inspect(@float.not_a_number + 1.0, content="NaN")
/// }
/// ```
pub let not_a_number : Float = Float::reinterpret_from_int(0x7FC00000)

///|
/// Represents positive infinity as a floating-point value.
///
/// Returns a constant value representing positive infinity in IEEE 754
/// single-precision floating-point format (0x7F800000).
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@float.INFINITY.is_pos_inf(), content="true")
///   inspect(@float.INFINITY > 1.0, content="true")
/// }
/// ```
pub const INFINITY : Float = 0x1.0p128

///|
/// Represents positive infinity as a floating-point value.
#deprecated("Use `INFINITY` instead")
pub let infinity : Float = Float::reinterpret_from_int(0x7F800000)

///|
/// Represents negative infinity for 32-bit floating-point numbers. This constant
/// has a mathematical value of -∞ and follows the IEEE 754 standard for
/// floating-point arithmetic.
///
/// Returns a `Float` value representing negative infinity.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@float.NEG_INFINITY.is_neg_inf(), content="true")
///   inspect(@float.NEG_INFINITY < (-1.0 : Float), content="true")
/// }
/// ```
pub const NEG_INFINITY : Float = -0x1.0p128

///|
/// Represents negative infinity for 32-bit floating-point numbers.
#deprecated("Use `NEG_INFINITY` instead")
pub let neg_infinity : Float = Float::reinterpret_from_int(0xFF800000)

///|
/// Represents the maximum finite value of a 32-bit floating-point number, which
/// is approximately 3.4028235e+38.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@float.MAX_VALUE < @float.INFINITY, content="true")
///   inspect(@float.MAX_VALUE > 0.0, content="true")
/// }
/// ```
pub const MAX_VALUE : Float = 0x1.fffffep127

///|
/// Represents the maximum finite value of a 32-bit floating-point number.
#deprecated("Use `MAX_VALUE` instead")
pub let max_value : Float = Float::reinterpret_from_int(0x7F7FFFFF)

///|
/// Represents the smallest finite negative Float value (-3.4028235e+38).
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@float.MIN_VALUE < -1.0, content="true")
///   inspect(@float.MIN_VALUE > @float.NEG_INFINITY, content="true")
/// }
/// ```
pub const MIN_VALUE : Float = -0x1.fffffep127

///|
/// Represents the smallest finite negative Float value.
#deprecated("Use `MIN_VALUE` instead")
pub let min_value : Float = Float::reinterpret_from_int(0xFF7FFFFF)

///|
/// Represents the smallest positive normalized floating-point number that can be
/// represented by the Float type (approximately 1.17549435e-38).
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@float.MIN_POSITIVE > 0.0, content="true")
///   inspect(@float.MIN_POSITIVE < 1.2e-38, content="true")
/// }
/// ```
pub const MIN_POSITIVE : Float = 0x1.0p-126

///|
/// Represents the smallest positive normalized floating-point number.
#deprecated("Use `MIN_POSITIVE` instead")
pub let min_positive : Float = Float::reinterpret_from_int(0x00800000)

///|
/// Returns the absolute value of a floating-point number.
///
/// Parameters:
///
/// * `self` : A floating-point number.
///
/// Returns the absolute value of the input number. For positive numbers and
/// zero, returns the number unchanged. For negative numbers, returns the
/// negation of the number. For NaN, returns NaN.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect((1.5 : Float).abs(), content="1.5")
///   inspect((-1.5 : Float).abs(), content="1.5")
///   inspect((0.0 : Float).abs(), content="0")
///   inspect((-0.0 : Float).abs(), content="0")
///   inspect(@float.not_a_number.abs().is_nan(), content="true")
/// }
/// ```
#as_free_fn(deprecated)
pub fn Float::abs(self : Float) -> Float = "%f32.abs"

///|
/// Returns the default value for `Float` type, which is `0.0`.
///
/// Returns a float value of `0.0`.
#deprecated
pub fn default() -> Float {
  0.0
}
