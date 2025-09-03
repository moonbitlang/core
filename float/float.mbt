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
/// Represents the Not a Number (NaN) value in floating-point arithmetic. NaN is
/// used to represent undefined or unrepresentable values, such as the result of
/// 0.0/0.0.
///
/// Returns a special floating-point value that represents NaN.
///
/// Example:
///
/// ```moonbit
/// inspect(@float.not_a_number.is_nan(), content="true")
/// inspect(@float.not_a_number + 1.0, content="NaN")
/// ```
pub let not_a_number : Float = (0x7FC00000).reinterpret_as_float()

///|
/// Represents positive infinity as a floating-point value.
///
/// Returns a constant value representing positive infinity in IEEE 754
/// single-precision floating-point format (0x7F800000).
///
/// Example:
///
/// ```moonbit
/// inspect(@float.infinity.is_pos_inf(), content="true")
/// inspect(@float.infinity > 1.0, content="true")
/// ```
pub let infinity : Float = (0x7F800000).reinterpret_as_float()

///|
/// Represents negative infinity for 32-bit floating-point numbers. This constant
/// has a mathematical value of -∞ and follows the IEEE 754 standard for
/// floating-point arithmetic.
///
/// Returns a `Float` value representing negative infinity.
///
/// Example:
///
/// ```moonbit
/// inspect(@float.neg_infinity.is_neg_inf(), content="true")
/// inspect(@float.neg_infinity < (-1.0 : Float), content="true")
/// ```
pub let neg_infinity : Float = (0xFF800000).reinterpret_as_float()

///|
/// Represents the maximum finite value of a 32-bit floating-point number, which
/// is approximately 3.4028235e+38.
///
/// Example:
///
/// ```moonbit
/// inspect(@float.max_value < @float.infinity, content="true")
/// inspect(@float.max_value > 0.0, content="true")
/// ```
pub let max_value : Float = (0x7F7FFFFF).reinterpret_as_float()

///|
/// Represents the smallest finite negative Float value (-3.4028235e+38).
///
/// Example:
///
/// ```moonbit
/// inspect(@float.min_value < -1.0, content="true")
/// inspect(@float.min_value > @float.neg_infinity, content="true")
/// ```
pub let min_value : Float = (0xFF7FFFFF).reinterpret_as_float()

///|
/// Represents the smallest positive normalized floating-point number that can be
/// represented by the Float type (approximately 1.17549435e-38).
///
/// Example:
///
/// ```moonbit
/// inspect(@float.min_positive > 0.0, content="true")
/// inspect(@float.min_positive < 1.2e-38, content="true")
/// ```
pub let min_positive : Float = (0x00800000).reinterpret_as_float()

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
/// ```moonbit
///   inspect((1.5 : Float).abs(), content="1.5")
///   inspect((-1.5 : Float).abs(), content="1.5")
///   inspect((0.0 : Float).abs(), content="0")
///   inspect((-0.0 : Float).abs(), content="0")
///   inspect(@float.not_a_number.abs().is_nan(), content="true")
/// ```
#as_free_fn
pub fn Float::abs(self : Float) -> Float = "%f32.abs"

///|
/// Converts a floating-point number to its string representation.
///
/// Parameters:
///
/// * `self` : The floating-point number to be converted.
/// * `logger` : The logger to write the string representation to.
///
/// Example:
///
/// ```moonbit
///   let f : Float = 3.14
///   let s = f.to_double().to_string()
///   inspect(s, content="3.140000104904175")
/// ```
pub impl Show for Float with output(self, logger) {
  logger.write_string(self.to_double().to_string())
}

///|
/// Returns a default value for the `Float` type, which is `0.0`.
///
/// Returns a `Float` value initialized to zero.
///
/// Example:
///
/// ```moonbit
///   inspect(Float::default(), content="0")
/// ```
pub impl Default for Float with default() {
  0.0
}

///|
/// Returns the default value for `Float` type, which is `0.0`.
///
/// Returns a float value of `0.0`.
///
/// Example:
///
/// ```moonbit
///   inspect(@float.default(), content="0")
/// ```
pub fn default() -> Float {
  0.0
}

///|
/// Computes a hash value for a floating-point number by first converting it to
/// its integer representation and then applying the standard integer hashing
/// function.
///
/// Parameters:
///
/// * `value` : The floating-point number to be hashed.
///
/// Returns an integer hash value for the given floating-point number.
///
/// Example:
///
/// ```moonbit
///   let f : Float = 3.14
///   let h = Hash::hash(f)
///   inspect(h != 0, content="true")
/// ```
pub impl Hash for Float with hash(self) {
  self.reinterpret_as_int() |> Hash::hash()
}

///|
/// Combines the hash value of a floating-point number with an existing hasher.
///
/// Parameters:
///
/// * `self` : The floating-point number to be hashed.
/// * `hasher` : The hasher object to combine the hash value with.
///
/// Example:
///
/// ```moonbit
///   let x : Float = 3.14
///   let y : Float = 3.14
///   // Same values should produce same hash combinations
///   inspect(Hash::hash(x) == Hash::hash(y), content="true")
/// ```
pub impl Hash for Float with hash_combine(self, hasher) {
  hasher.combine_float(self)
}

///|
/// Converts a floating-point number to a sequence of bytes in big-endian byte
/// order. In big-endian order, the most significant byte is stored at the lowest
/// memory address.
///
/// Parameters:
///
/// * `float` : The floating-point number to be converted.
///
/// Returns a sequence of 4 bytes representing the floating-point number in IEEE
/// 754 single-precision format with big-endian byte order.
///
/// Example:
///
/// ```moonbit
///   let x : Float = 1.0
///   inspect(
///     x.to_be_bytes(), 
///     content=(
///       #|b"\x3f\x80\x00\x00"
///     ),
///   )
/// ```
pub fn to_be_bytes(self : Float) -> Bytes {
  self.reinterpret_as_uint().to_be_bytes()
}

///|
/// Converts a floating-point number to its binary representation in
/// little-endian byte order.
///
/// Parameters:
///
/// * `float` : The floating-point number to be converted.
///
/// Returns a sequence of bytes representing the float value in little-endian
/// order (least significant byte first).
///
/// Example:
///
/// ```moonbit
///   let f : Float = 1.0
///   let bytes = f.to_le_bytes()
///   inspect(bytes.length(), content="4")
/// ```
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
///   inspect(@float.infinity.is_inf(), content="true")
///   inspect(@float.neg_infinity.is_inf(), content="true")
///   inspect((1.0 : Float).is_inf(), content="false")
/// ```
pub fn is_inf(self : Float) -> Bool {
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
///   inspect(@float.infinity.is_pos_inf(), content="true")
///   inspect((1.0 : Float).is_pos_inf(), content="false")
///   inspect(@float.neg_infinity.is_pos_inf(), content="false")
/// ```
pub fn is_pos_inf(self : Float) -> Bool {
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
///   inspect(@float.neg_infinity.is_neg_inf(), content="true")
///   inspect((1.0 : Float).is_neg_inf(), content="false")
///   inspect(@float.infinity.is_neg_inf(), content="false")
/// ```
pub fn is_neg_inf(self : Float) -> Bool {
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
///   inspect(@float.not_a_number.is_nan(), content="true")
///   inspect((1.0 : Float).is_nan(), content="false")
///   inspect(@float.infinity.is_nan(), content="false")
/// ```
pub fn is_nan(self : Float) -> Bool {
  self != self
}

///|
/// Determines whether two floating-point numbers are approximately equal within
/// specified tolerances.
/// The implementation follows the algorithm described in PEP 485 for Python's
/// `math.isclose()`.
///
/// Parameters:
///
/// * `self` : The first floating-point number to compare.
/// * `other` : The second floating-point number to compare.
/// * `relative_tolerance` : The relative tolerance for the comparison. Must be
/// non-negative. Defaults to 1e-9.
/// * `absolute_tolerance` : The absolute tolerance for the comparison. Must be
/// non-negative. Defaults to 0.0.
///
/// Returns whether the two numbers are considered approximately equal. Returns
/// `true` if the numbers are exactly equal or if they are within either the
/// relative or absolute tolerance. Returns `false` if either number is infinite.
///
/// Example:
///
/// ```moonbit
///   let x = 1.0
///   let y = 1.000000001
///   inspect(x.is_close(y), content="false")
///   inspect(x.is_close(y, relative_tolerance=1.0e-10), content="false")
///   inspect(@float.infinity.is_close(@float.infinity), content="true")
/// ```
pub fn Float::is_close(
  self : Self,
  other : Self,
  relative_tolerance? : Self = 1.0e-09,
  absolute_tolerance? : Self = 0.0,
) -> Bool {
  if relative_tolerance < 0.0 || absolute_tolerance < 0.0 {
    abort("Tolerances must be non-negative")
  }
  if self == other {
    return true
  }
  if self.is_inf() || other.is_inf() {
    return false
  }
  let diff = (other - self).abs()
  return (
      diff <= (relative_tolerance * other).abs() ||
      diff <= (relative_tolerance * self).abs()
    ) ||
    diff <= absolute_tolerance
}
