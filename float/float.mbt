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
pub let not_a_number : Float = (0x7FC00000).reinterpret_as_float()

///|
pub let infinity : Float = (0x7F800000).reinterpret_as_float()

///|
pub let neg_infinity : Float = (0xFF800000).reinterpret_as_float()

///|
pub let max_value : Float = (0x7F7FFFFF).reinterpret_as_float()

///|
pub let min_value : Float = (0xFF7FFFFF).reinterpret_as_float()

///|
pub let min_positive : Float = (0x00800000).reinterpret_as_float()

///|
pub fn abs(self : Float) -> Float = "%f32.abs"

///|
pub impl Show for Float with output(self, logger) {
  logger.write_string(self.to_double().to_string())
}

///|
pub fn Float::default() -> Float {
  0.0
}

///|
pub impl Hash for Float with hash(self) {
  self.reinterpret_as_int() |> Hash::hash()
}

///|
pub impl Hash for Float with hash_combine(self, hasher) {
  hasher.combine_float(self)
}

///| Converts the Float to a Bytes in big-endian byte order.
pub fn to_be_bytes(self : Float) -> Bytes {
  self.reinterpret_as_uint().to_be_bytes()
}

///| Converts the Float to a Bytes in little-endian byte order.
pub fn to_le_bytes(self : Float) -> Bytes {
  self.reinterpret_as_uint().to_le_bytes()
}

///|
/// Determines if the floating-point number is positive or negative infinity.
///
/// Parameters:
///
/// * `self` : The floating-point number to be checked.
///
/// Returns a boolean value indicating whether the number is positive or negative
/// infinity.
///
/// Example:
///
/// ```moonbit
/// test "Float::is_inf" {
///   inspect!(@float.infinity.is_inf(), content="true")
///   inspect!(@float.neg_infinity.is_inf(), content="true")
///   inspect!((1.0 : Float).is_inf(), content="false")
/// }
/// ```
pub fn Float::is_inf(self : Float) -> Bool {
  self.is_pos_inf() || self.is_neg_inf()
}

///|
/// Determines if the floating-point number is positive infinity.
///
/// Parameters:
///
/// * `self` : The floating-point number to be checked.
///
/// Returns a boolean value indicating whether the number is positive infinity.
///
/// Example:
///
/// ```moonbit
/// test "Float::is_pos_inf" {
///   inspect!(@float.infinity.is_pos_inf(), content="true")
///   inspect!((1.0 : Float).is_pos_inf(), content="false")
///   inspect!(@float.neg_infinity.is_pos_inf(), content="false")
/// }
/// ```
pub fn Float::is_pos_inf(self : Float) -> Bool {
  self > max_value
}

///|
/// Determines if the floating-point number is negative infinity.
///
/// Parameters:
///
/// * `self` : The floating-point number to be checked.
///
/// Returns a boolean value indicating whether the number is negative infinity.
///
/// Example:
///
/// ```moonbit
/// test "Float::is_neg_inf" {
///   inspect!(@float.neg_infinity.is_neg_inf(), content="true")
///   inspect!((1.0 : Float).is_neg_inf(), content="false")
///   inspect!(@float.infinity.is_neg_inf(), content="false")
/// }
/// ```
pub fn Float::is_neg_inf(self : Float) -> Bool {
  self < min_value
}

///|
/// Determines if the floating-point number is NaN (Not a Number).
///
/// Parameters:
///
/// * `self` : The floating-point number to be checked.
///
/// Returns a boolean value indicating whether the number is NaN.
///
/// Example:
///
/// ```moonbit
/// test "Float::is_nan" {
///   inspect!(@float.not_a_number.is_nan(), content="true")
///   inspect!((1.0 : Float).is_nan(), content="false")
///   inspect!(@float.infinity.is_nan(), content="false")
/// }
/// ```
pub fn Float::is_nan(self : Float) -> Bool {
  self != self
}
