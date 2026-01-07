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
/// Converts a floating-point number to its string representation.
///
/// Parameters:
///
/// * `self` : The floating-point number to be converted.
/// * `logger` : The logger to write the string representation to.
///
/// Example:
///
/// ```mbt check
/// test {
///   let f : Float = 3.14
///   let s = f.to_double().to_string()
///   inspect(s, content="3.140000104904175")
/// }
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
/// ```mbt check
/// test {
///   inspect(Float::default(), content="0")
/// }
/// ```
pub impl Default for Float with default() {
  0
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
/// ```mbt check
/// test {
///   let x : Float = 3.14
///   let y : Float = 3.14
///   // Same values should produce same hash combinations
///   inspect(Hash::hash(x) == Hash::hash(y), content="true")
/// }
/// ```
pub impl Hash for Float with hash_combine(self, hasher) {
  hasher.combine_uint(self.reinterpret_as_uint())
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
/// ```mbt check
/// test {
///   let x : Float = 1.0
///   inspect(
///     x.to_be_bytes(),
///     content=(
///       #|b"?\x80\x00\x00"
///     ),
///   )
/// }
/// ```
pub fn Float::to_be_bytes(self : Float) -> Bytes {
  let uint = self.reinterpret_as_uint()
  [
    (uint >> 24).to_byte(),
    (uint >> 16).to_byte(),
    (uint >> 8).to_byte(),
    uint.to_byte(),
  ]
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
/// ```mbt check
/// test {
///   let f : Float = 1.0
///   let bytes = f.to_le_bytes()
///   inspect(bytes.length(), content="4")
/// }
/// ```
pub fn Float::to_le_bytes(self : Float) -> Bytes {
  let uint = self.reinterpret_as_uint()
  [
    uint.to_byte(),
    (uint >> 8).to_byte(),
    (uint >> 16).to_byte(),
    (uint >> 24).to_byte(),
  ]
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
/// ```mbt check
/// test {
///   inspect(@float.infinity.is_inf(), content="true")
///   inspect(@float.neg_infinity.is_inf(), content="true")
///   inspect((1.0 : Float).is_inf(), content="false")
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
/// ```mbt check
/// test {
///   inspect(@float.infinity.is_pos_inf(), content="true")
///   inspect((1.0 : Float).is_pos_inf(), content="false")
///   inspect(@float.neg_infinity.is_pos_inf(), content="false")
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
/// ```mbt check
/// test {
///   inspect(@float.neg_infinity.is_neg_inf(), content="true")
///   inspect((1.0 : Float).is_neg_inf(), content="false")
///   inspect(@float.infinity.is_neg_inf(), content="false")
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
/// ```mbt check
/// test {
///   inspect(@float.not_a_number.is_nan(), content="true")
///   inspect((1.0 : Float).is_nan(), content="false")
///   inspect(@float.infinity.is_nan(), content="false")
/// }
/// ```
pub fn Float::is_nan(self : Float) -> Bool {
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
/// ```mbt check
/// test {
///   let x = 1.0
///   let y = 1.000000001
///   inspect(x.is_close(y), content="false")
///   inspect(x.is_close(y, relative_tolerance=1.0e-10), content="false")
///   inspect(@float.infinity.is_close(@float.infinity), content="true")
/// }
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

///|
/// Calculates the modulo operation between two floating-point numbers.
///
/// Parameters:
///
/// * `self` : The dividend floating-point number.
/// * `other` : The divisor floating-point number.
///
/// Returns the remainder of the division of `self` by `other`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect((5.7 : Float).mod(2.0), content="1.6999998092651367")
///   inspect((-5.7 : Float).mod(2.0), content="-1.6999998092651367")
/// }
/// ```
pub impl Mod for Float with mod(self : Float, other : Float) -> Float {
  Float::from_double(self.to_double() % other.to_double())
}

///|
/// Creates an iterator that iterates over a range of Float with default step 1.0 .
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Float from `start` to `end - 1`.
#deprecated("Use `..<` in for loop or `until` method instead")
#coverage.skip
pub fn Float::upto(
  self : Float,
  end : Float,
  inclusive? : Bool = false,
) -> Iter[Float] {
  let mut i = self
  Iter::new(() => {
    guard i < end || (inclusive && i == end) else { None }
    let result = i
    if i != end {
      i += 1
    }
    Some(result)
  })
}

///|
/// Creates an iterator that iterates over a range of Float with default step 1.0 .
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1.0).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Float from `start` to `end - 1`.
pub fn Float::until(
  self : Float,
  end : Float,
  step? : Float = 1.0,
  inclusive? : Bool = false,
) -> Iter[Float] {
  if step == 0.0 {
    return Iter::empty()
  }
  let mut curr_value = Some(self)
  Iter::new(() => {
    guard curr_value is Some(i) else { None }
    guard (step > 0.0 && i < end) ||
      (step < 0.0 && i > end) ||
      (inclusive && i == end) else {
      None
    }
    let next = i + step
    if (step > 0.0 && next >= i) || (step < 0.0 && next <= i) {
      curr_value = Some(next)
    } else {
      // overflow
      curr_value = None
    }
    Some(i)
  })
}

///|
/// Converts a 32-bit floating-point number to a double-precision (64-bit)
/// floating-point number.
///
/// Parameters:
///
/// * `self` : The 32-bit floating-point number to be converted.
///
/// Returns a double-precision floating-point number that preserves the exact
/// value of the input. Since double-precision has more bits than
/// single-precision, this conversion is always exact and never loses precision.
///
/// Example:
///
/// ```mbt check
/// test {
///   let f = Float::from_double(3.14)
///   inspect(f.to_double(), content="3.140000104904175")
/// }
/// ```
pub fn Float::to_double(self : Float) -> Double = "%f32.to_f64"

///|
pub impl ToJson for Float with to_json(self : Float) -> Json {
  Json::number(self.to_double())
}

///|
/// Calculates the square root of a floating-point number. For non-negative
/// numbers, returns the principal square root. For negative numbers or NaN,
/// returns NaN.
///
/// Parameters:
///
/// * `self` : The floating-point number whose square root is to be calculated.
///
/// Returns a 32-bit floating-point number representing the square root of the
/// input value:
///
/// * For a positive number, returns its principal square root
/// * For zero (positive or negative), returns zero with the same sign
/// * For NaN or negative numbers, returns NaN
///
/// Example:
///
/// ```mbt check
/// test {
///   let x = Float::from_double(16.0)
///   let root = x.sqrt()
///   inspect(root.to_double(), content="4")
///   let neg = Float::from_double(-4.0)
///   let neg_root = neg.sqrt()
///   inspect(neg_root.to_double(), content="NaN")
/// }
/// ```
pub fn Float::sqrt(self : Float) -> Float = "%f32.sqrt"

///|
/// Reinterprets the bits of a 32-bit floating-point number as a 32-bit signed
/// integer without performing any numeric conversion. The bit pattern is
/// preserved exactly, only the type interpretation changes.
///
/// Parameters:
///
/// * `self` : The 32-bit floating-point number whose bits are to be
/// reinterpreted.
///
/// Returns a 32-bit signed integer that has the same bit pattern as the input
/// floating-point number.
///
/// Example:
///
/// ```mbt check
/// test {
///   let f = Float::from_double(1.0)
///   // IEEE 754 representation of 1.0 is 0x3F800000
///   inspect(f.reinterpret_as_int(), content="1065353216")
/// }
/// ```
pub fn Float::reinterpret_as_int(self : Float) -> Int = "%f32.to_i32_reinterpret"

///|
/// Performs unary negation on a 32-bit floating-point number. Returns the
/// arithmetic inverse of the operand.
///
/// Parameters:
///
/// * `self` : The floating-point number to negate.
///
/// Returns a new floating-point number with the same magnitude but opposite sign
/// as the input. Special cases:
///
/// * Negating NaN returns NaN
/// * Negating +0.0 returns -0.0
/// * Negating -0.0 returns +0.0
/// * Negating +Infinity returns -Infinity
/// * Negating -Infinity returns +Infinity
///
/// Example:
///
/// ```mbt check
/// test {
///   let f = Float::from_double(3.14)
///   inspect((-f).to_double(), content="-3.140000104904175")
///   let zero = Float::from_double(0.0)
///   inspect((-zero).to_double(), content="0")
/// }
/// ```
pub impl Neg for Float with neg(self) = "%f32.neg"

///|
/// Performs addition between two single-precision floating-point numbers.
///
/// Parameters:
///
/// * `self` : The first floating-point operand.
/// * `other` : The second floating-point operand to be added to the first
/// operand.
///
/// Returns a single-precision floating-point number representing the sum of the
/// two operands.
///
/// Example:
///
/// ```mbt check
/// test {
///   let a = Float::from_double(3.14)
///   let b = Float::from_double(2.86)
///   let sum = a + b
///   inspect(sum.to_double(), content="6")
/// }
/// ```
pub impl Add for Float with add(self, other) = "%f32.add"

///|
/// Performs subtraction between two single-precision floating-point numbers.
///
/// Parameters:
///
/// * `self` : The first floating-point number (minuend).
/// * `other` : The second floating-point number (subtrahend).
///
/// Returns a new floating-point number representing the difference between
/// `self` and `other`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x = Float::from_double(3.14)
///   let y = Float::from_double(1.0)
///   let result = x - y
///   inspect(result.to_double(), content="2.140000104904175")
/// }
/// ```
pub impl Sub for Float with sub(self, other) = "%f32.sub"

///|
/// Performs multiplication between two single-precision floating-point numbers
/// according to IEEE 754 rules.
///
/// Parameters:
///
/// * `self` : The first floating-point number operand.
/// * `other` : The second floating-point number operand to multiply with the
/// first.
///
/// Returns a single-precision floating-point number that is the product of the
/// two operands.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x = Float::from_int(2)
///   let y = Float::from_int(3)
///   let z = x * y
///   inspect(z.to_double(), content="6")
/// }
/// ```
pub impl Mul for Float with mul(self, other) = "%f32.mul"

///|
/// Performs division between two 32-bit floating-point numbers according to IEEE
/// 754 rules.
///
/// Parameters:
///
/// * `self` : The dividend floating-point number.
/// * `other` : The divisor floating-point number.
///
/// Returns a new floating-point number representing the quotient of the
/// division. Special cases follow IEEE 754 rules:
///
/// * Division by zero returns infinity (with the appropriate sign)
/// * Division of zero by zero returns NaN
/// * Division of infinity by infinity returns NaN
///
/// Example:
///
/// ```mbt check
/// test {
///   let a = Float::from_double(6.0)
///   let b = Float::from_double(2.0)
///   let result = (a / b).to_double()
///   inspect(result, content="3")
///   inspect(
///     (Float::from_double(0.0) / Float::from_double(0.0)).to_double(),
///     content="NaN",
///   )
/// }
/// ```
pub impl Div for Float with div(self, other) = "%f32.div"

///|
/// Tests two floating-point numbers for equality. Follows IEEE 754 equality
/// comparison rules, where NaN values are not equal to any value, including
/// themselves.
///
/// Parameters:
///
/// * `self` : The first floating-point number to compare.
/// * `other` : The second floating-point number to compare.
///
/// Returns `true` if both numbers are equal, `false` otherwise. Note that `-0.0`
/// and `+0.0` are considered equal.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x = 3.14
///   let y = 3.14
///   let z = 0.0 / 0.0 // NaN
///   inspect(x == y, content="true")
///   inspect(z == z, content="false") // NaN is not equal to itself
/// }
/// ```
pub impl Eq for Float with equal(self : Float, other : Float) -> Bool = "%f32.eq"

///|
/// Tests two floating-point numbers for inequality. Follows IEEE 754 inequality
/// comparison rules, where NaN values are not equal to any value, including
/// themselves.
///
/// Parameters:
///
/// * `self` : The first floating-point number to compare.
/// * `other` : The second floating-point number to compare.
///
/// Returns `true` if the numbers are not equal, `false` otherwise. Note that `-0.0`
/// and `+0.0` are considered equal.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x = 3.14
///   let y = 3.14
///   let z = 0.0 / 0.0 // NaN
///   inspect(x != y, content="false")
///   inspect(z != z, content="true") // NaN is not equal to itself
/// }
/// ```
pub impl Eq for Float with not_equal(self : Float, other : Float) -> Bool = "%f32.ne"

///|
#deprecated("Use `a != b` instead")
#doc(hidden)
pub fn Float::op_neq(self : Float, other : Float) -> Bool = "%f32.ne"

///|
/// Compares two 32-bit floating-point numbers and returns their relative order.
///
/// Parameters:
///
/// * `self` : The first floating-point number to compare.
/// * `other` : The second floating-point number to compare.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```mbt check
/// test {
///   let a = 3.14
///   let b = 2.718
///   inspect(a.compare(b), content="1") // 3.14 > 2.718
///   inspect(b.compare(a), content="-1") // 2.718 < 3.14
///   inspect(a.compare(a), content="0") // 3.14 = 3.14
/// }
/// ```
pub impl Compare for Float with compare(self, other) = "%f32.compare"

///|
pub impl Compare for Float with op_lt(x, y) = "%f32.lt"

///|
pub impl Compare for Float with op_le(x, y) = "%f32.le"

///|
pub impl Compare for Float with op_gt(x, y) = "%f32.gt"

///|
pub impl Compare for Float with op_ge(x, y) = "%f32.ge"

///|
/// Reinterprets the bits of a 32-bit floating-point number as an unsigned 32-bit
/// integer without performing any numeric conversion. Preserves the exact bit
/// pattern of the input value, only changing how these bits are interpreted.
///
/// Parameters:
///
/// * `float` : The 32-bit floating-point number whose bits are to be
/// reinterpreted.
///
/// Returns an unsigned 32-bit integer (`UInt`) that has the same bit pattern as
/// the input floating-point number.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x : Float = 1.0
///   inspect(x.reinterpret_as_uint(), content="1065353216") // Decimal representation of 0x3F800000
/// }
/// ```
pub fn Float::reinterpret_as_uint(self : Float) -> UInt = "%f32.to_i32_reinterpret"

///|
/// Reinterprets the bits of a 32-bit integer as a single-precision
/// floating-point number according to IEEE 754 standard. The bit pattern of the
/// input is preserved, only the type interpretation changes.
///
/// Parameters:
///
/// * `self` : The 32-bit integer whose bits are to be reinterpreted as a
/// single-precision floating-point number.
///
/// Returns a 32-bit floating-point number (`Float`) that has the same bit
/// pattern as the input integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   // 0x3F800000 represents 1.0 in IEEE 754 single-precision format
///   let n = 1065353216 // 0x3F800000
///   inspect(Float::reinterpret_from_int(n), content="1")
/// }
/// ```
// TODO(upstream): no test entry found
pub fn Float::reinterpret_from_int(self : Int) -> Float = "%i32.to_f32_reinterpret"

///|
/// Reinterprets the bits of an unsigned 32-bit integer as a single-precision
/// floating-point number (IEEE 754). The bit pattern is preserved exactly, only
/// the type interpretation changes.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer whose bits are to be reinterpreted as
/// a single-precision floating-point number.
///
/// Returns a single-precision floating-point number (`Float`) whose bit pattern
/// is identical to the input integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = 0x3F800000U // Bit pattern for 1.0f
///   inspect(Float::reinterpret_from_uint(n), content="1")
/// }
/// ```
// TODO(upstream): no test entry found
pub fn Float::reinterpret_from_uint(self : UInt) -> Float = "%i32.to_f32_reinterpret"

///|
test "Float::reinterpret" {
  inspect(Float::reinterpret_from_int(1065353216), content="1")
  inspect(Float::reinterpret_from_uint(0x3F800000), content="1")
}

///|
/// Converts an integer to a 32-bit floating-point number. The conversion is
/// exact for small integers, but may lose precision for large integers due to
/// the limited precision of the floating-point format.
///
/// Parameters:
///
/// * `number` : The integer value to be converted to a floating-point number.
///
/// Returns a 32-bit floating-point number representing the same value as the
/// input integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = 42
///   let f = Float::from_int(n)
///   // Convert back to double for comparison since Float doesn't implement Show
///   inspect(f.to_double(), content="42")
/// }
/// ```
pub fn Float::from_int(self : Int) -> Float = "%i32.to_f32"

///|
/// Converts a byte value to a 32-bit floating-point number (IEEE 754
/// single-precision format). The byte value is treated as an unsigned 8-bit
/// integer during the conversion.
///
/// Parameters:
///
/// * `byte` : The byte value to be converted to a float.
///
/// Returns a 32-bit floating-point number representing the byte value.
///
/// Example:
///
/// ```mbt check
/// test {
///   let b = b'\xFF' // 255 in decimal
///   let f = Float::from_byte(b)
///   // Convert to double for comparison since Float doesn't implement Show
///   inspect(f.to_double(), content="255")
/// }
/// ```
pub fn Float::from_byte(self : Byte) -> Float = "%byte.to_f32"

///|
/// Converts a double-precision floating-point number to a single-precision
/// floating-point number. The conversion may result in a loss of precision due
/// to the reduced number of bits available in the single-precision format.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to be converted.
///
/// Returns a single-precision floating-point number that represents the closest
/// possible value to the input double-precision number.
///
/// Example:
///
/// ```mbt check
/// test {
///   let d = 3.14159265359
///   inspect(Float::from_double(d).to_double(), content="3.1415927410125732") // Note the loss of precision
/// }
/// ```
pub fn Float::from_double(self : Double) -> Float = "%f64.to_f32"

///|
/// Converts an unsigned 32-bit integer to a single-precision floating-point
/// number. Due to the limited precision of the 32-bit floating-point format,
/// values above 16777216 (2^24) may lose precision during conversion.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be converted.
///
/// Returns a 32-bit floating-point number that represents the same numerical
/// value as the input unsigned integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = 42U
///   inspect(Float::from_uint(n).to_double(), content="42")
///   let big = 16777216U // 2^24
///   inspect(Float::from_uint(big).to_double(), content="16777216") // Last precisely representable integer
/// }
/// ```
pub fn Float::from_uint(self : UInt) -> Float = "%u32.to_f32"

///|
/// Converts an unsigned 64-bit integer to a 32-bit floating-point number. Due to
/// floating-point precision limitations, the conversion may lose precision if
/// the integer value is too large to be represented exactly as a float.
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer to be converted.
///
/// Returns a 32-bit floating-point number that represents the input value. If
/// the input value is too large to be represented exactly, the result will be
/// rounded to the nearest representable float value.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = 42UL
///   inspect(Float::from_uint64(n).to_double(), content="42")
///   let big = 18446744073709551615UL // UInt64::max_value
///   inspect(Float::from_uint64(big).to_double(), content="18446744073709552000")
/// }
/// ```
#cfg(not(target="js"))
pub fn Float::from_uint64(self : UInt64) -> Float = "%u64.to_f32"

///|
#cfg(target="js")
pub fn Float::from_uint64(self : UInt64) -> Float {
  Float::from_double(self.to_double())
}

///|
test "Float::from_uint64" {
  let n = 42UL
  inspect(Float::from_uint64(n).to_double(), content="42")
  let big = 18446744073709551615UL // UInt64::max_value
  inspect(Float::from_uint64(big).to_double(), content="18446744073709552000")
}

///|
/// Converts a 64-bit integer to a 32-bit floating-point number. The conversion
/// may result in loss of precision due to the limited precision of the 32-bit
/// floating-point format.
///
/// Parameters:
///
/// * `self` : The 64-bit integer value to be converted.
///
/// Returns a 32-bit floating-point number that represents the input integer
/// value. Note that for values outside the range of representable 32-bit
/// floating-point numbers, the result will be rounded to the nearest
/// representable value.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = 42L
///   let f = Float::from_int64(n)
///   // Convert to double for comparison since Float doesn't implement Show
///   inspect(f.to_double(), content="42")
/// }
/// ```
#cfg(not(target="js"))
pub fn Float::from_int64(self : Int64) -> Float = "%i64.to_f32"

///|
#cfg(target="js")
pub fn Float::from_int64(self : Int64) -> Float {
  Float::from_double(self.to_double())
}

///|
test "Float::from_int64" {
  let n = 42L
  let f = Float::from_int64(n)
  inspect(f.to_double(), content="42")
}
