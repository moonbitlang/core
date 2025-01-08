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
pub let not_a_number : Double = 0x7FF8000000000001L.reinterpret_as_double()

///|
pub let infinity : Double = 0x7FF0000000000000L.reinterpret_as_double()

///|
pub let neg_infinity : Double = 0xFFF0000000000000L.reinterpret_as_double()

///|
pub let max_value : Double = 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
pub let min_value : Double = 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
pub let min_positive : Double = 0x0010000000000000L.reinterpret_as_double()

///|
/// Converts an integer to a double-precision floating-point number.
///
/// Parameters:
///
/// * `integer` : The integer value to be converted.
///
/// Returns a double-precision floating-point number representing the given
/// integer value.
///
/// Example:
///
/// ```moonbit
/// test "Double::from_int" {
///   inspect!(Double::from_int(42), content="42")
///   inspect!(Double::from_int(-1), content="-1")
/// }
/// ```
pub fn Double::from_int(i : Int) -> Double {
  i.to_double()
}

///|
/// Returns the absolute value of a double-precision floating-point number.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to compute the
/// absolute value of.
///
/// Returns the absolute value of the input number. For any input `x`, the result
/// is equivalent to `if x < 0.0 { -x } else { x }`.
///
/// Example:
///
/// ```moonbit
/// test "abs" {
///   inspect!((-2.5).abs(), content="2.5")
///   inspect!(3.14.abs(), content="3.14")
///   inspect!(0.0.abs(), content="0")
/// }
/// ```
pub fn abs(self : Double) -> Double = "%f64.abs"

///|
/// Returns the sign of the double.
/// - If the double is positive, returns 1.0.
/// - If the double is negative, returns -1.0.
/// - Otherwise, returns the double itself (0.0, -0.0 and NaN).
pub fn signum(self : Double) -> Double {
  if self < 0.0 {
    -1.0
  } else if self > 0.0 {
    1.0
  } else {
    self // handles 0.0, -0.0, NaN
  }
}

///|
/// \[DEPRECATED] Returns a "not-a-number" (NaN) value.
///
/// This function is deprecated. Use `@double.not_a_number` instead.
///
/// Returns a double-precision floating-point NaN value.
///
/// Example:
///
/// ```moonbit
/// test "Double::nan" {
///   let nan = @double.not_a_number
///   inspect!(nan.is_nan(), content="true")
/// }
/// ```
///
/// @alert deprecated "Use `@double.not_a_number` instead"
/// @coverage.skip
pub fn Double::nan() -> Double {
  not_a_number
}

///|
/// Returns positive infinity if sign >= 0, negative infinity if sign < 0.
/// @alert deprecated "Use `@double.infinity` and `@double.neg_infinity` instead"
/// @coverage.skip
pub fn Double::inf(sign : Int) -> Double {
  if sign >= 0 {
    infinity
  } else {
    neg_infinity
  }
}

///|
/// Returns the smallest positive normal value of a double-precision
/// floating-point number.
///
/// Returns a `Double` value that represents the smallest positive normal number
/// that can be represented by a double-precision floating-point number
/// (approximately 2.2250738585072014e-308).
///
/// Example:
///
/// ```moonbit
/// test "Double::min_normal" {
///   inspect!(@double.min_positive, content="2.2250738585072014e-308")
/// }
/// ```
///
/// @alert deprecated "Use `@double.min_positive` instead"
/// @coverage.skip
pub fn Double::min_normal() -> Double {
  min_positive
}

///|
/// Checks whether a double-precision floating-point number represents a "Not a
/// Number" (NaN) value.
///
/// Parameters:
///
/// * `number` : A double-precision floating-point value to be checked.
///
/// Returns `true` if the number is NaN, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "is_nan" {
///   inspect!(not_a_number.is_nan(), content="true")
///   inspect!(42.0.is_nan(), content="false")
///   inspect!((0.0 / 0.0).is_nan(), content="true")
/// }
/// ```
pub fn is_nan(self : Double) -> Bool {
  // only NaNs satisfy f != f.
  self != self
}

///|
/// Checks whether a double-precision floating-point number represents positive
/// or negative infinity.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to check.
///
/// Returns `true` if the value is either positive or negative infinity, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// test "is_inf" {
///   inspect!(infinity.is_inf(), content="true")
///   inspect!(neg_infinity.is_inf(), content="true")
///   inspect!(42.0.is_inf(), content="false")
/// }
/// ```
pub fn is_inf(self : Double) -> Bool {
  self > max_value || self < min_value
}

///|
/// Checks whether a double-precision floating-point number is positive infinity.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to check.
///
/// Returns `true` if the number is positive infinity, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "is_pos_inf" {
///   inspect!(infinity.is_pos_inf(), content="true")
///   inspect!(neg_infinity.is_pos_inf(), content="false")
///   inspect!(42.0.is_pos_inf(), content="false")
/// }
/// ```
pub fn is_pos_inf(self : Double) -> Bool {
  self > max_value
}

///|
/// Checks whether a double-precision floating-point number is negative infinity.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to check.
///
/// Returns a boolean value indicating whether the number is negative infinity.
///
/// Example:
///
/// ```moonbit
/// test "is_neg_inf" {
///   inspect!((-1.0 / 0.0).is_neg_inf(), content="true")
///   inspect!(42.0.is_neg_inf(), content="false")
///   inspect!((1.0 / 0.0).is_neg_inf(), content="false") // positive infinity
/// }
/// ```
pub fn is_neg_inf(self : Double) -> Bool {
  self < min_value
}

test "from_int" {
  assert_eq!(Double::from_int(1), 1.0)
  assert_eq!(Double::from_int(0), 0.0)
  assert_eq!(Double::from_int(100000), 1.0e5)
}

test "abs" {
  let d = -1.0
  assert_eq!(d.abs(), 1.0)
  assert_eq!(1.0.abs(), 1.0)
}

test "signum" {
  let d = -2.0
  assert_eq!(d.signum(), -1.0)
  assert_eq!(1.0.signum(), 1.0)
  assert_eq!(0.0.signum(), 0.0)
  assert_true!(not_a_number.signum().is_nan())
}

test "is_nan" {
  assert_true!(is_nan(not_a_number))
  assert_false!(is_nan(0.0))
  assert_false!(is_nan(12345.678))
  assert_false!(is_nan(infinity))
  assert_false!(is_nan(neg_infinity))
}

test "is_inf" {
  assert_true!(is_inf(infinity))
  assert_true!(is_inf(neg_infinity))
  assert_false!(is_inf(0.0))
  assert_false!(is_inf(12345.678))
}

test "is_pos_inf" {
  assert_true!(is_pos_inf(infinity))
  assert_false!(is_pos_inf(neg_infinity))
  assert_false!(is_pos_inf(0.0))
  assert_false!(is_pos_inf(12345.678))
}

test "is_neg_inf" {
  assert_false!(is_neg_inf(infinity))
  assert_true!(is_neg_inf(neg_infinity))
  assert_false!(is_neg_inf(0.0))
  assert_false!(is_neg_inf(12345.678))
}

test "min equal to neg max" {
  assert_true!(min_value == -max_value)
}

///|
pub impl Hash for Double with hash(self) {
  self.reinterpret_as_int64() |> Hash::hash()
}

///|
pub impl Hash for Double with hash_combine(self, hasher) {
  hasher.combine_double(self)
}

///|
/// Converts a double-precision floating-point number to its string
/// representation.
///
/// Parameters:
///
/// * `self`: The double-precision floating-point number to be converted.
///
/// Returns a string representation of the double-precision floating-point
/// number.
///
/// Example:
///
/// ```moonbit
/// test "Double::to_string" {
///   inspect!(42.0.to_string(), content="42")
///   inspect!(3.14159.to_string(), content="3.14159")
///   inspect!((-0.0).to_string(), content="0")
///   inspect!(not_a_number.to_string(), content="NaN")
/// }
/// ```
///
/// @intrinsic %f64.to_string
pub fn to_string(self : Double) -> String {
  @ryu.ryu_to_string(self)
}

///|
pub impl Show for Double with output(self, logger) {
  logger.write_string(self.to_string())
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
/// test "is_close" {
///   let x = 1.0
///   let y = 1.000000001
///   inspect!(x.is_close(y), content="false")
///   inspect!(x.is_close(y, relative_tolerance=1.0e-10), content="false")
///   inspect!(infinity.is_close(infinity), content="true")
/// }
/// ```
pub fn is_close(
  self : Double,
  other : Double,
  relative_tolerance~ : Double = 1.0e-09,
  absolute_tolerance~ : Double = 0.0
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

///|
/// Converts a double-precision floating-point number to a sequence of bytes in
/// big-endian byte order (most significant byte first).
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to be converted.
///
/// Returns a sequence of 8 bytes representing the double-precision
/// floating-point number in big-endian byte order.
///
/// Example:
///
/// ```moonbit
/// test "to_be_bytes" {
///   let d = 1.0
///   inspect!(d.to_be_bytes(), content=
///   #|b"\x3f\xf0\x00\x00\x00\x00\x00\x00"
/// )
/// }
/// ```
pub fn to_be_bytes(self : Double) -> Bytes {
  self.reinterpret_as_uint64().to_be_bytes()
}

///|
/// Converts a double-precision floating-point number to a sequence of bytes in
/// little-endian order (least significant byte first).
///
/// Parameters:
///
/// * `self` : A double-precision floating-point number to be converted.
///
/// Returns a sequence of 8 bytes representing the double-precision
/// floating-point number in little-endian order.
///
/// Example:
///
/// ```moonbit
/// test "to_le_bytes" {
///   let d = 1.0
///   inspect!(d.to_le_bytes(), content=
///   #|b"\x00\x00\x00\x00\x00\x00\xf0\x3f"
/// )
/// }
/// ```
pub fn to_le_bytes(self : Double) -> Bytes {
  self.reinterpret_as_uint64().to_le_bytes()
}
