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
/// ```mbt check
/// test {
///   inspect(Double::from_int(42), content="42")
///   inspect(Double::from_int(-1), content="-1")
/// }
/// ```
#as_free_fn(deprecated)
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
/// ```mbt check
/// test {
///   inspect((-2.5).abs(), content="2.5")
///   inspect(3.14.abs(), content="3.14")
///   inspect(0.0.abs(), content="0")
/// }
/// ```
#as_free_fn(deprecated)
pub fn Double::abs(self : Double) -> Double = "%f64.abs"

///|
/// Returns the sign of the double.
/// - If the double is positive, returns 1.0.
/// - If the double is negative, returns -1.0.
/// - Otherwise, returns the double itself (0.0, -0.0 and NaN).
pub fn Double::signum(self : Double) -> Double {
  if self < 0.0 {
    -1.0
  } else if self > 0.0 {
    1.0
  } else {
    self // handles 0.0, -0.0, NaN
  }
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
/// ```mbt check
/// test {
///   inspect(@double.not_a_number.is_nan(), content="true")
///   inspect(42.0.is_nan(), content="false")
///   inspect((0.0 / 0.0).is_nan(), content="true")
/// }
/// ```
pub fn Double::is_nan(self : Double) -> Bool {
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
/// ```mbt check
/// test {
///   inspect(@double.infinity.is_inf(), content="true")
///   inspect(@double.neg_infinity.is_inf(), content="true")
///   inspect(42.0.is_inf(), content="false")
/// }
/// ```
pub fn Double::is_inf(self : Double) -> Bool {
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
/// ```mbt check
/// test {
///   inspect(@double.infinity.is_pos_inf(), content="true")
///   inspect(@double.neg_infinity.is_pos_inf(), content="false")
///   inspect(42.0.is_pos_inf(), content="false") // TODO: better formatter
/// }
/// ```
pub fn Double::is_pos_inf(self : Double) -> Bool {
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
/// ```mbt check
/// test {
///   inspect((-1.0 / 0.0).is_neg_inf(), content="true")
///   inspect(42.0.is_neg_inf(), content="false")
///   inspect((1.0 / 0.0).is_neg_inf(), content="false") // positive infinity
/// }
/// ```
pub fn Double::is_neg_inf(self : Double) -> Bool {
  self < min_value
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
/// ```mbt check
/// test {
///   inspect(42.0.to_string(), content="42")
///   inspect(3.14159.to_string(), content="3.14159")
///   inspect((-0.0).to_string(), content="0")
///   inspect(@double.not_a_number.to_string(), content="NaN")
/// }
/// ```
///
pub fn Double::to_string(self : Double) -> String {
  @ryu.ryu_to_string(self)
}

// TODO:
// #intrinsic("%f64.to_string")
// impl Show for Double with to_string(self) -> String{
//   @ryu.ryu_to_string(self)
// }

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
/// ```mbt check
/// test {
///   let x = 1.0
///   let y = 1.000000001
///   inspect(x.is_close(y), content="false")
///   inspect(x.is_close(y, relative_tolerance=1.0e-10), content="false")
///   inspect(@double.infinity.is_close(@double.infinity), content="true")
/// }
/// ```
#as_free_fn(deprecated)
pub fn Double::is_close(
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
#deprecated
#doc(hidden)
pub fn Double::to_be_bytes(self : Double) -> Bytes {
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
#deprecated
#doc(hidden)
pub fn Double::to_le_bytes(self : Double) -> Bytes {
  self.reinterpret_as_uint64().to_le_bytes()
}
