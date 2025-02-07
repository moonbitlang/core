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
/// Performs unary negation on a 64-bit signed integer, returning its arithmetic
/// inverse.
///
/// Parameters:
///
/// * `value` : The 64-bit signed integer to negate.
///
/// Returns the arithmetic negation of the input value. For all inputs except
/// `Int64::min_value()`, returns the value with opposite sign. When the input is
/// `Int64::min_value()`, returns `Int64::min_value()` due to two's complement
/// representation.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_neg" {
///   inspect!(-42L, content="-42")
///   inspect!(--42L, content="42")
///   inspect!(-9223372036854775808L, content="-9223372036854775808") // negating min value
/// }
/// ```
pub fn Int64::op_neg(self : Int64) -> Int64 = "%i64_neg"

///|
/// Adds two 64-bit integers together. Performs overflow checking and wrapping
/// according to two's complement arithmetic.
///
/// Parameters:
///
/// * `self` : The first 64-bit integer operand.
/// * `other` : The second 64-bit integer operand to add to the first.
///
/// Returns a new 64-bit integer representing the sum of the two operands.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_add" {
///   let a = 9223372036854775807L // Int64 maximum value
///   let b = 1L
///   inspect!(a + b, content="-9223372036854775808") // Wraps around to minimum value
///   inspect!(42L + -42L, content="0")
/// }
/// ```
pub fn Int64::op_add(self : Int64, other : Int64) -> Int64 = "%i64_add"

///|
/// Performs subtraction between two 64-bit integers.
///
/// Parameters:
///
/// * `self` : The minuend (the number being subtracted from).
/// * `other` : The subtrahend (the number to subtract).
///
/// Returns the difference between `self` and `other` as a 64-bit integer.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_sub" {
///   let a = 9223372036854775807L // Int64 maximum value
///   let b = 1L
///   inspect!(a - b, content="9223372036854775806")
///   let c = -9223372036854775808L // Int64 minimum value
///   let d = 1L
///   inspect!(c - d, content="9223372036854775807")
/// }
/// ```
pub fn Int64::op_sub(self : Int64, other : Int64) -> Int64 = "%i64_sub"

///|
/// Multiplies two 64-bit integers.
///
/// Parameters:
///
/// * `self` : The first 64-bit integer operand.
/// * `other` : The second 64-bit integer operand.
///
/// Returns the product of the two 64-bit integers. If the result overflows the
/// range of `Int64`, it will be truncated according to two's complement
/// arithmetic.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_mul" {
///   let a = 42L
///   let b = 100L
///   inspect!(a * b, content="4200")
///   let c = -42L
///   inspect!(c * b, content="-4200")
/// }
/// ```
pub fn Int64::op_mul(self : Int64, other : Int64) -> Int64 = "%i64_mul"

///|
/// Performs integer division between two 64-bit integers. Truncates the result
/// towards zero.
///
/// Parameters:
///
/// * `self` : The dividend (the number to be divided).
/// * `other` : The divisor (the number to divide by).
///
/// Returns the quotient of the division.
///
/// Throws a panic if `other` is zero.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_div" {
///   let a = 42L
///   let b = 5L
///   inspect!(a / b, content="8")
///   let c = -42L
///   let d = 5L
///   inspect!(c / d, content="-8")
/// }
///
/// test "panic Int64::op_div/division_by_zero" {
///   let a = 42L
///   ignore(a / 0L) // Division by zero
/// }
/// ```
pub fn Int64::op_div(self : Int64, other : Int64) -> Int64 = "%i64_div"

///|
/// Calculates the remainder of the division between two 64-bit integers. The
/// result follows the formula `self - (self / other) * other`, maintaining the
/// same sign as the dividend.
///
/// Parameters:
///
/// * `self` : The dividend 64-bit integer.
/// * `other` : The divisor 64-bit integer.
///
/// Returns the remainder of the division.
///
/// Throws a panic if `other` is zero.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_mod" {
///   inspect!(7L % 3L, content="1")
///   inspect!(-7L % 3L, content="-1")
///   inspect!(7L % -3L, content="1")
/// }
///
/// test "panic Int64::op_mod/division_by_zero" {
///   ignore(7L % 0L) // Panics with division by zero
/// }
/// ```
pub fn Int64::op_mod(self : Int64, other : Int64) -> Int64 = "%i64_mod"

///|
/// Performs a bitwise NOT operation on a 64-bit integer. Each bit in the input
/// value is flipped (0 becomes 1 and 1 becomes 0).
///
/// Parameters:
///
/// * `self` : The 64-bit integer on which to perform the bitwise NOT operation.
///
/// Returns a new 64-bit integer where each bit is the inverse of the
/// corresponding bit in the input value.
///
/// Example:
///
/// ```moonbit
/// test "Int64::lnot" {
///   let a = -1L // All bits are 1
///   let b = 0L // All bits are 0
///   inspect!(a.lnot(), content="0")
///   inspect!(b.lnot(), content="-1")
/// }
/// ```
pub fn Int64::lnot(self : Int64) -> Int64 = "%i64_lnot"

///|
/// Performs a bitwise AND operation between two 64-bit signed integers.
///
/// Parameters:
///
/// * `self` : The first 64-bit integer operand.
/// * `other` : The second 64-bit integer operand.
///
/// Returns a 64-bit integer where each bit is set to 1 if and only if the
/// corresponding bits in both operands are 1.
///
/// Example:
///
/// ```moonbit
/// test "Int64::land" {
///   let a = 0xFF00FF00L
///   let b = 0x0F0F0F0FL
///   inspect!(a & b, content="251662080") // 0x0F000F00
/// }
/// ```
pub fn Int64::land(self : Int64, other : Int64) -> Int64 = "%i64_land"

///|
/// Performs a bitwise OR operation between two 64-bit integers.
///
/// Parameters:
///
/// * `self` : The first 64-bit integer operand.
/// * `other` : The second 64-bit integer operand.
///
/// Returns a new 64-bit integer where each bit is set to 1 if at least one of
/// the corresponding bits in either operand is 1.
///
/// Example:
///
/// ```moonbit
/// test "Int64::lor" {
///   let a = 0xFF00L // 1111_1111_0000_0000
///   let b = 0x0FF0L // 0000_1111_1111_0000
///   inspect!(a | b, content="65520") // 1111_1111_1111_0000 = 65520
/// }
/// ```
pub fn Int64::lor(self : Int64, other : Int64) -> Int64 = "%i64_lor"

///|
/// Performs a bitwise XOR operation between two 64-bit integers. Each bit of the
/// result is set to 1 if the corresponding bits of the operands are different,
/// and 0 if they are the same.
///
/// Parameters:
///
/// * `self` : The first 64-bit integer operand.
/// * `other` : The second 64-bit integer operand.
///
/// Returns a new 64-bit integer containing the result of the bitwise XOR
/// operation.
///
/// Example:
///
/// ```moonbit
/// test "Int64::lxor" {
///   let a = 0xF0F0F0F0F0F0F0F0L
///   let b = 0x0F0F0F0F0F0F0F0FL
///   inspect!(a ^ b, content="-1") // All bits set to 1
///   inspect!(a ^ a, content="0") // XOR with self gives 0
/// }
/// ```
pub fn Int64::lxor(self : Int64, other : Int64) -> Int64 = "%i64_lxor"

///|
/// Performs a left shift operation on a 64-bit signed integer. Shifts each bit
/// in the integer to the left by the specified number of positions, filling the
/// vacated bit positions with zeros.
///
/// Parameters:
///
/// * `self` : The 64-bit signed integer to be shifted.
/// * `shift` : The number of positions to shift. Must be non-negative and less
/// than 64.
///
/// Returns a new 64-bit integer with bits shifted left by the specified number
/// of positions.
///
/// Example:
///
/// ```moonbit
/// test "Int64::lsl" {
///   let x = 1L
///   inspect!(x << 2, content="4") // Binary: 1 -> 100
/// }
/// ```
///
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn Int64::lsl(self : Int64, other : Int) -> Int64 = "%i64_shl"

///|
/// Performs a left shift operation on a 64-bit integer value. Shifts the bits of
/// the integer to the left by a specified number of positions, filling the
/// rightmost positions with zeros.
///
/// Parameters:
///
/// * `self` : The 64-bit integer value to be shifted.
/// * `shift` : The number of positions to shift the bits to the left.
///
/// Returns a new 64-bit integer value after performing the left shift operation.
///
/// Example:
///
/// ```moonbit
/// test "Int64::shl" {
///   let x = 1L
///   inspect!(x << 3, content="8") // Equivalent to x << 3
/// }
/// ```
///
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn Int64::shl(self : Int64, other : Int) -> Int64 = "%i64_shl"

///|
/// **DEPRECATED:** Use `UInt64` type and infix operator `>>` instead.
///
/// Performs a logical right shift on a 64-bit integer value. In a logical right
/// shift, zeros are shifted in from the left, regardless of the sign bit.
///
/// Parameters:
///
/// * `value` : The 64-bit integer value to be shifted.
/// * `shift` : The number of positions to shift right. Must be non-negative.
///
/// Returns a new 64-bit integer value that is the result of shifting the bits of
/// `value` right by `shift` positions.
///
/// Example:
///
/// ```moonbit
/// test "Int64::lsr" {
///   let x = (-4L).reinterpret_as_uint64() // Convert to UInt64 first
///   inspect!(x >> 1, content="9223372036854775806") // Using the recommended operator
/// }
/// ```
///
/// @alert deprecated "Use UInt64 type and infix operator `>>` instead"
/// @coverage.skip
pub fn Int64::lsr(self : Int64, other : Int) -> Int64 = "%u64.shr"

///|
/// DEPRECATED: Use the infix operator `>>` instead.
///
/// Performs an arithmetic right shift operation on a 64-bit integer. In an
/// arithmetic right shift, the leftmost bit (sign bit) is copied to fill in from
/// the left. This preserves the sign of the number.
///
/// Parameters:
///
/// * `self` : The 64-bit integer to be shifted.
/// * `positions` : The number of positions to shift right. Must be non-negative.
///
/// Returns a new 64-bit integer that is the result of shifting `self` right by
/// `positions` bits, with sign extension.
///
/// Example:
///
/// ```moonbit
/// test "Int64::asr" {
///   let x = -240L // 0b1111_1111_0001_0000 in two's complement
///   inspect!(x >> 4, content="-15") // 0b1111_1111_1111_0001, using recommended syntax
/// }
/// ```
///
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn Int64::asr(self : Int64, other : Int) -> Int64 = "%i64_shr"

///|
/// Performs an arithmetic right shift operation on a 64-bit integer value,
/// shifting the bits to the right by the specified number of positions. The sign
/// bit is copied to fill the leftmost positions.
///
/// Parameters:
///
/// * `self` : The 64-bit integer value to be shifted.
/// * `shift` : The number of bit positions to shift right. Must be non-negative.
///
/// Returns a new `Int64` value representing the result of the arithmetic right
/// shift operation.
///
/// Example:
///
/// ```moonbit
/// test "Int64::shr" {
///   let n = -1024L
///   inspect!(n >> 3, content="-128") // Preserves sign bit
/// }
/// ```
///
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn Int64::shr(self : Int64, other : Int) -> Int64 = "%i64_shr"

///|
/// Performs a left shift operation on a 64-bit integer value. Shifts the bits of
/// the first operand to the left by the number of positions specified by the
/// second operand. The rightmost positions are filled with zeros.
///
/// Parameters:
///
/// * `self` : The 64-bit integer value to be shifted.
/// * `shift` : The number of positions to shift the bits to the left. Must be
/// non-negative and less than 64.
///
/// Returns a new `Int64` value representing the result of the left shift
/// operation.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_shl" {
///   let n = 1L
///   inspect!(n << 3, content="8") // 1 shifted left by 3 positions becomes 8
///   let m = -4L
///   inspect!(m << 2, content="-16") // -4 shifted left by 2 positions becomes -16
/// }
/// ```
pub fn Int64::op_shl(self : Int64, other : Int) -> Int64 = "%i64_shl"

///|
/// Performs arithmetic right shift operation on a 64-bit integer value by a
/// specified number of bits. Preserves the sign bit of the original number while
/// shifting its bits right, filling the leftmost positions with copies of the
/// sign bit.
///
/// Parameters:
///
/// * `self` : The 64-bit integer value to be shifted.
/// * `shift_count` : The number of positions to shift right. Must be
/// non-negative and less than 64.
///
/// Returns a new `Int64` value that represents the result of shifting `self`
/// right by `shift_count` bits.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_shr" {
///   let n = -1024L
///   inspect!(n >> 3, content="-128") // Preserves sign bit
///   let p = 1024L
///   inspect!(p >> 3, content="128") // Regular right shift for positive numbers
/// }
/// ```
pub fn Int64::op_shr(self : Int64, other : Int) -> Int64 = "%i64_shr"

///|
/// Returns the number of trailing zero bits in a 64-bit integer. For zero input,
/// returns 64.
///
/// Parameters:
///
/// * `value` : The 64-bit integer to count trailing zeros in.
///
/// Returns the number of trailing zero bits (0 to 64).
///
/// Example:
///
/// ```moonbit
/// test "Int64::ctz" {
///   inspect!(0x8000000000000000L.ctz(), content="63") // Binary: 1000...0000
///   inspect!(0x0000000000000001L.ctz(), content="0") // Binary: ...0001
///   inspect!(0L.ctz(), content="64") // All zeros
/// }
/// ```
pub fn Int64::ctz(self : Int64) -> Int = "%i64_ctz"

///|
/// Counts the number of leading zero bits in a 64-bit signed integer, starting
/// from the most significant bit.
///
/// Parameters:
///
/// * `number` : The 64-bit signed integer whose leading zeros are to be counted.
///
/// Returns the number of leading zero bits (0 to 64).
///
/// Example:
///
/// ```moonbit
/// test "Int64::clz" {
///   let a = 0x0000_0001_0000_0000L
///   inspect!(a.clz(), content="31") // 31 leading zeros before the first 1 bit
///   let b = 0L
///   inspect!(b.clz(), content="64") // All bits are zero
/// }
/// ```
pub fn Int64::clz(self : Int64) -> Int = "%i64_clz"

///|
/// Returns the number of 1 bits ('population count') in the 64-bit integer's
/// binary representation.
///
/// Parameters:
///
/// * `value` : The 64-bit integer whose bits are to be counted.
///
/// Returns an integer representing the number of set bits (1s) in the binary
/// representation of the input.
///
/// Example:
///
/// ```moonbit
/// test "Int64::popcnt" {
///   let x = 0x7000_0001_1F00_100FL // 0111000000000000000000000001000111110000000100001111
///   inspect!(x.popcnt(), content="14")
/// }
/// ```
///
/// ```moonbit
/// test "Int64::popcnt/edge_cases" {
///   inspect!((-1L).popcnt(), content="64") // All bits set
///   inspect!(0L.popcnt(), content="0") // No bits set
/// }
/// ```
pub fn Int64::popcnt(self : Int64) -> Int = "%i64_popcnt"

///|
/// Tests if two 64-bit integers are equal.
///
/// Parameters:
///
/// * `self` : The first 64-bit integer to compare.
/// * `other` : The second 64-bit integer to compare.
///
/// Returns `true` if both integers are equal, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "Int64::op_equal" {
///   let a = 42L
///   let b = 42L
///   let c = -42L
///   inspect!(a == b, content="true")
///   inspect!(a == c, content="false")
/// }
/// ```
pub fn Int64::op_equal(self : Int64, other : Int64) -> Bool = "%i64_eq"

///|
/// Compares two 64-bit integers and returns their relative order.
///
/// Parameters:
///
/// * `self` : The first 64-bit integer to compare.
/// * `other` : The second 64-bit integer to compare against.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
/// test "Int64::compare" {
///   let a = 42L
///   let b = 24L
///   let c = -42L
///   inspect!(a.compare(b), content="1") // 42 > 24
///   inspect!(b.compare(a), content="-1") // 24 < 42
///   inspect!(c.compare(a), content="-1") // -42 < 42
///   inspect!(a.compare(a), content="0") // 42 = 42
/// }
/// ```
pub fn Int64::compare(self : Int64, other : Int64) -> Int = "%i64_compare"

///|
/// Returns the default value for `Int64` type, which is zero (0L).
///
/// Returns a 64-bit signed integer with value 0.
///
/// Example:
///
/// ```moonbit
/// test "Int64::default" {
///   inspect!(Int64::default(), content="0")
/// }
/// ```
pub fn Int64::default() -> Int64 = "%i64_default"

///|
/// Converts a 64-bit signed integer to a 32-bit signed integer by truncating
/// higher bits.
///
/// Parameters:
///
/// * `value` : The 64-bit signed integer (`Int64`) to be converted.
///
/// Returns a 32-bit signed integer (`Int`). Note that values outside the range
/// of 32-bit integers will be truncated, potentially leading to loss of
/// information.
///
/// Example:
///
/// ```moonbit
/// test "Int64::to_int" {
///   let small = 42L
///   let big = 2147483648L // 2^31
///   inspect!(small.to_int(), content="42")
///   inspect!(big.to_int(), content="-2147483648") // Truncated to Int.min_value
/// }
/// ```
pub fn Int64::to_int(self : Int64) -> Int = "%i64_to_i32"

///|
/// Converts a 64-bit signed integer to a double-precision floating-point number.
///
/// Parameters:
///
/// * `self` : The 64-bit signed integer to be converted.
///
/// Returns a double-precision floating-point number that represents the same
/// value as the input integer.
///
/// Example:
///
/// ```moonbit
/// test "Int64::to_double" {
///   let big = 9223372036854775807L // max value of Int64
///   inspect!(big.to_double(), content="9223372036854776000")
///   let neg = -42L
///   inspect!(neg.to_double(), content="-42")
/// }
/// ```
pub fn Int64::to_double(self : Int64) -> Double = "%i64_to_f64"

///|
/// Reinterprets the bits of a 64-bit signed integer as a double-precision
/// floating-point number (IEEE 754). The bit pattern is preserved exactly, only
/// the type interpretation changes.
///
/// Parameters:
///
/// * `value` : The 64-bit signed integer whose bits are to be reinterpreted as a
/// double-precision floating-point number.
///
/// Returns a double-precision floating-point number whose bit pattern is
/// identical to the input integer.
///
/// Example:
///
/// ```moonbit
/// test "Int64::reinterpret_as_double" {
///   let n = 4607182418800017408L // Bit pattern for 1.0
///   inspect!(n.reinterpret_as_double(), content="1")
/// }
/// ```
pub fn Int64::reinterpret_as_double(self : Int64) -> Double = "%i64_to_f64_reinterpret"

///|
/// Reinterprets the bits of an unsigned 64-bit integer as a double-precision
/// floating-point number according to IEEE 754 standard. The bit pattern of the
/// input is preserved, only the type interpretation changes.
///
/// Parameters:
///
/// * `value` : The unsigned 64-bit integer whose bits are to be reinterpreted as
/// a double-precision floating-point number.
///
/// Returns a double-precision floating-point number that has the same bit
/// pattern as the input unsigned 64-bit integer.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::reinterpret_as_double" {
///   // 0x4045000000000000 represents 42.0 in IEEE 754 double format
///   let n = 4636737291354636288UL
///   inspect!(n.reinterpret_as_double(), content="100")
/// }
/// ```
pub fn UInt64::reinterpret_as_double(self : UInt64) -> Double = "%i64_to_f64_reinterpret"

///|
/// Converts a 64-bit signed integer to a byte by taking its least significant 8
/// bits. Any bits beyond the first 8 bits are truncated.
///
/// Parameters:
///
/// * `self` : The 64-bit signed integer to be converted. Only the least
/// significant 8 bits will be used.
///
/// Returns a byte containing the least significant 8 bits of the input integer.
///
/// Example:
///
/// ```moonbit
/// test "Int64::to_byte" {
///   let n = 258L // In binary: 100000010
///   inspect!(n.to_byte(), content="b'\\x02'") // Only keeps 00000010
///   let neg = -1L // In binary: all 1's
///   inspect!(neg.to_byte(), content="b'\\xFF'") // Only keeps 11111111
/// }
/// ```
pub fn Int64::to_byte(self : Int64) -> Byte = "%i64_to_byte"

///|
/// Converts a 64-bit signed integer to a 16-bit signed integer by truncating the
/// value to fit within the 16-bit range (-32768 to 32767).
///
/// Parameters:
///
/// * `value` : The 64-bit signed integer to be converted.
///
/// Returns a 16-bit signed integer representing the lower 16 bits of the input
/// value.
///
/// Example:
///
/// ```moonbit
/// test "Int64::to_int16" {
///   let big = 100000L
///   inspect!(big.to_int16(), content="-31072") // 100000 doesn't fit in Int16, gets truncated
///   let small = 42L
///   inspect!(small.to_int16(), content="42") // 42 fits in Int16, remains unchanged
/// }
/// ```
pub fn Int64::to_int16(self : Int64) -> Int16 = "%i64_to_i16"

///|
/// Converts a 64-bit signed integer to a 16-bit unsigned integer by truncating
/// the value to fit within the range of UInt16 (0 to 65535).
///
/// Parameters:
///
/// * `value` : The 64-bit signed integer to be converted to UInt16.
///
/// Returns a 16-bit unsigned integer representing the lower 16 bits of the input
/// value.
///
/// Example:
///
/// ```moonbit
/// test "Int64::to_uint16" {
///   inspect!(42L.to_uint16(), content="42")
///   inspect!((-1L).to_uint16(), content="65535") // Wraps around to maximum UInt16 value
///   inspect!(70000L.to_uint16(), content="4464") // Value is truncated
/// }
/// ```
pub fn Int64::to_uint16(self : Int64) -> UInt16 = "%i64_to_u16"

///|
/// Converts a double-precision floating-point number to an unsigned 64-bit
/// integer by truncating its decimal part. This is a raw conversion function
/// that does not handle special cases like NaN or infinity.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to be truncated and
/// converted.
///
/// Returns an unsigned 64-bit integer. The decimal part of the input is
/// discarded (truncated towards zero).
///
/// Example:
///
/// ```moonbit
/// test "UInt64::trunc_double" {
///   inspect!(UInt64::trunc_double(42.75), content="42")
/// }
/// ```
pub fn UInt64::trunc_double(val : Double) -> UInt64 = "%f64.to_u64"

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
/// ```moonbit
/// test "Int64::to_float" {
///   let n = 42L
///   let f = n.to_float()
///   // Convert to double for comparison since Float doesn't implement Show
///   inspect!(f.to_double(), content="42")
/// }
/// ```
pub fn Int64::to_float(self : Int64) -> Float = "%i64.to_f32"

///|
/// Converts an unsigned 32-bit integer to an unsigned 64-bit integer by
/// zero-extending it. The resulting value preserves the original number's
/// magnitude while using 64 bits to represent it.
///
/// Parameters:
///
/// * `value` : The unsigned 32-bit integer (`UInt`) to be converted.
///
/// Returns an unsigned 64-bit integer (`UInt64`) representing the same numerical
/// value as the input.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::extend_uint" {
///   let n = 42U
///   inspect!(UInt64::extend_uint(n), content="42")
///   let max = 4294967295U // Maximum value of UInt
///   inspect!(UInt64::extend_uint(max), content="4294967295")
/// }
/// ```
pub fn UInt64::extend_uint(val : UInt) -> UInt64 = "%u32.to_u64"

///|
/// Converts a 32-bit signed integer to a 64-bit signed integer. All 32-bit
/// integers can be represented exactly in 64-bit integer format, so the
/// conversion is lossless.
///
/// Parameters:
///
/// * `self` : The 32-bit signed integer to be converted.
///
/// Returns a 64-bit signed integer that represents the same numerical value as
/// the input.
///
/// Example:
///
/// ```moonbit
/// test "Int::to_int64" {
///   let n = 42
///   inspect!(n.to_int64(), content="42")
///   let neg = -42
///   inspect!(neg.to_int64(), content="-42")
/// }
/// ```
pub fn Int::to_int64(self : Int) -> Int64 = "%i32_to_i64"

///|
pub fn Int16::to_int64(self : Int16) -> Int64 = "%i16_to_i64"

///|
/// Converts an unsigned 16-bit integer to a signed 64-bit integer. The resulting
/// value will always be non-negative since the input is unsigned.
///
/// Parameters:
///
/// * `value` : The unsigned 16-bit integer to be converted.
///
/// Returns a 64-bit signed integer representing the same numerical value as the
/// input.
///
/// Example:
///
/// ```moonbit
/// test "UInt16::to_int64" {
///   let x = Int::to_uint16(42)
///   inspect!(x.to_int64(), content="42")
///   let max = Int::to_uint16(65535) // maximum value of UInt16
///   inspect!(max.to_int64(), content="65535")
/// }
/// ```
pub fn UInt16::to_int64(self : UInt16) -> Int64 = "%u16_to_i64"

///|
/// Reinterprets the bits of a double-precision floating-point number as a 64-bit
/// signed integer without any conversion. This is a low-level operation that
/// simply reinterprets the bit pattern of the input value.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number whose bits are to be
/// reinterpreted.
///
/// Returns a 64-bit signed integer that has the same bit pattern as the input
/// double-precision floating-point number.
///
/// Example:
///
/// ```moonbit
/// test "Double::reinterpret_as_i64" {
///   let d = 1.0
///   // 1.0 in IEEE 754 double format has the bit pattern 0x3FF0000000000000
///   inspect!(d.reinterpret_as_int64(), content="4607182418800017408")
/// }
/// ```
///
/// @alert deprecated "Use `reinterpret_as_int64` instead"
/// @coverage.skip
pub fn Double::reinterpret_as_i64(self : Double) -> Int64 = "%f64_to_i64_reinterpret"

///|
/// Reinterprets the bits of a double-precision floating-point number as a 64-bit
/// signed integer without performing any conversion. Preserves the exact bit
/// pattern of the input value.
///
/// Parameters:
///
/// * `number` : The double-precision floating-point number whose bits will be
/// reinterpreted.
///
/// Returns a 64-bit signed integer containing the same bit pattern as the input
/// floating-point number.
///
/// Example:
///
/// ```moonbit
/// test "Double::reinterpret_as_int64" {
///   let d = 1.0
///   inspect!(d.reinterpret_as_int64(), content="4607182418800017408") // IEEE 754 representation of 1.0
///   let neg = -0.0
///   inspect!(neg.reinterpret_as_int64(), content="-9223372036854775808") // Sign bit set
/// }
/// ```
pub fn Double::reinterpret_as_int64(self : Double) -> Int64 = "%f64_to_i64_reinterpret"

///|
/// Reinterprets the bits of a double-precision floating-point number as an
/// unsigned 64-bit integer. The bit pattern is preserved during the conversion,
/// with no mathematical conversion performed.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to be reinterpreted.
///
/// Returns an unsigned 64-bit integer containing the same bit pattern as the
/// input floating-point number.
///
/// Example:
///
/// ```moonbit
/// test "Double::reinterpret_as_u64" {
///   let zero = 0.0
///   let positive = 1.0
///   inspect!(zero.reinterpret_as_uint64(), content="0")
///   inspect!(positive.reinterpret_as_uint64(), content="4607182418800017408")
/// }
/// ```
///
/// @alert deprecated "Use `reinterpret_as_uint64` instead"
/// @coverage.skip
pub fn Double::reinterpret_as_u64(self : Double) -> UInt64 = "%f64_to_i64_reinterpret"

///|
/// Reinterprets the bits of a double-precision floating-point number as an
/// unsigned 64-bit integer, preserving the exact bit pattern without performing
/// any numerical conversion.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number whose bits will be
/// reinterpreted.
///
/// Returns an unsigned 64-bit integer that has the same bit pattern as the input
/// floating-point number.
///
/// Example:
///
/// ```moonbit
/// test "Double::reinterpret_as_uint64" {
///   let d = 1.0
///   inspect!(d.reinterpret_as_uint64(), content="4607182418800017408") // Binary: 0x3FF0000000000000
/// }
/// ```
pub fn Double::reinterpret_as_uint64(self : Double) -> UInt64 = "%f64_to_i64_reinterpret"

///|
/// Converts an unsigned 64-bit integer to a double-precision floating-point
/// number. The conversion is exact for integers up to 53 bits (the size of the
/// mantissa in a double-precision number), but may lose precision for larger
/// values.
///
/// Parameters:
///
/// * `value` : The unsigned 64-bit integer to be converted.
///
/// Returns a double-precision floating-point number representing the same
/// numerical value as the input.
///
/// Example:
///
/// ```moonbit
/// test "Double::convert_uint64" {
///   let n = 12345678901234567890UL
///   inspect!(Double::convert_uint64(n), content="12345678901234567000")
/// }
/// ```
pub fn Double::convert_uint64(val : UInt64) -> Double = "%u64.to_f64"

///|
/// Reinterprets a 64-bit signed integer as an unsigned 64-bit integer without
/// changing its bits. When the value is non-negative, i.e., within the range
/// \[0, 2^63-1], the value remains the same. When the value is negative, it
/// becomes a large number in the range \[2^63, 2^64-1].
///
/// Parameters:
///
/// * `value` : The 64-bit signed integer (`Int64`) to be reinterpreted.
///
/// Returns an unsigned 64-bit integer (`UInt64`) containing the same bit pattern
/// as the input.
///
/// Example:
///
/// ```moonbit
/// test "Int64::to_uint64" {
///   let pos = 42L
///   let neg = -1L
///   inspect!(pos.reinterpret_as_uint64(), content="42")
///   inspect!(neg.reinterpret_as_uint64(), content="18446744073709551615") // 2^64 - 1
/// }
/// ```
///
/// @alert deprecated "Use `reinterpret_as_uint64` instead"
/// @coverage.skip
pub fn Int64::to_uint64(self : Int64) -> UInt64 = "%i64.to_u64_reinterpret"

///|
/// Reinterprets a 64-bit signed integer as an unsigned 64-bit integer without
/// changing its bit pattern. The reinterpretation follows the standard two's
/// complement representation rules.
///
/// Parameters:
///
/// * `self` : The 64-bit signed integer to be reinterpreted.
///
/// Returns a 64-bit unsigned integer that has the same bit pattern as the input.
///
/// Example:
///
/// ```moonbit
/// test "Int64::reinterpret_as_uint64" {
///   let neg = -1L
///   inspect!(neg.reinterpret_as_uint64(), content="18446744073709551615") // All bits set to 1
///   let pos = 42L
///   inspect!(pos.reinterpret_as_uint64(), content="42") // Positive numbers remain unchanged
/// }
/// ```
pub fn Int64::reinterpret_as_uint64(self : Int64) -> UInt64 = "%i64.to_u64_reinterpret"

///|
/// Reinterprets a 64-bit unsigned integer as a 64-bit signed integer. The bits
/// of the number remain unchanged; only the interpretation of these bits
/// changes. This function is deprecated; use `reinterpret_as_int64` instead.
///
/// Parameters:
///
/// * `value` : The 64-bit unsigned integer to be reinterpreted.
///
/// Returns a 64-bit signed integer representing the same bit pattern as the
/// input.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::reinterpret_as_int64" {
///   let max = 18446744073709551615UL
///   inspect!(max.reinterpret_as_int64(), content="-1")
/// }
/// ```
///
/// @alert deprecated "Use `reinterpret_as_int64` instead"
/// @coverage.skip
pub fn UInt64::to_int64(self : UInt64) -> Int64 = "%u64.to_i64_reinterpret"

///|
/// Reinterprets the bits of an unsigned 64-bit integer as a signed 64-bit
/// integer. The bits remain the same, but their interpretation changes. This
/// operation is useful for low-level bit manipulation and type conversions where
/// you want to preserve the exact bit pattern.
///
/// Parameters:
///
/// * `value` : The unsigned 64-bit integer (`UInt64`) to be reinterpreted.
///
/// Returns a signed 64-bit integer (`Int64`) that has the same bit pattern as
/// the input value.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::reinterpret_as_int64" {
///   let max = 18446744073709551615UL // Maximum value of UInt64
///   inspect!(max.reinterpret_as_int64(), content="-1") // All bits set to 1 represents -1 in two's complement
/// }
/// ```
pub fn UInt64::reinterpret_as_int64(self : UInt64) -> Int64 = "%u64.to_i64_reinterpret"

///|
/// Converts a 64-bit unsigned integer to a 32-bit unsigned integer by truncating
/// the higher 32 bits.
///
/// Parameters:
///
/// * `self` : The 64-bit unsigned integer to be converted.
///
/// Returns a 32-bit unsigned integer containing the lower 32 bits of the input
/// value.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::to_uint" {
///   let big = 0xFFFFFFFFFFFFFFFFUL // max value of UInt64
///   inspect!(big.to_uint(), content="4294967295") // 0xFFFFFFFF, max value of UInt
///   let small = 42UL
///   inspect!(small.to_uint(), content="42")
/// }
/// ```
pub fn UInt64::to_uint(self : UInt64) -> UInt = "%u64.to_u32"

///|
/// Converts an unsigned 64-bit integer to a 32-bit signed integer. The
/// conversion truncates the value to fit within the 32-bit range, possibly
/// losing information if the input value is too large.
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer to be converted.
///
/// Returns a 32-bit signed integer representing the lower 32 bits of the input
/// value. If the input value is larger than the maximum value of a 32-bit signed
/// integer (2147483647), the result will be the truncated value interpreted as a
/// signed integer.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::to_int" {
///   let a = 42UL
///   inspect!(a.to_int(), content="42")
///   let b = 18446744073709551615UL // max value of UInt64
///   inspect!(b.to_int(), content="-1") // truncated to 32 bits
/// }
/// ```
pub fn UInt64::to_int(self : UInt64) -> Int = "%u64.to_i32"

///|
/// Converts an unsigned 64-bit integer to a double-precision floating-point
/// number.
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer (`UInt64`) to be converted.
///
/// Returns a double-precision floating-point number (`Double`) that represents
/// the same numerical value as the input. Note that due to the limited precision
/// of double-precision floating-point numbers, values larger than 2^53 may lose
/// precision during the conversion.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::to_double" {
///   let n = 12345678901234567890UL
///   inspect!(n.to_double(), content="12345678901234567000") // Note the slight precision loss
///   let small = 42UL
///   inspect!(small.to_double(), content="42")
/// }
/// ```
pub fn UInt64::to_double(self : UInt64) -> Double = "%u64.to_f64"

///|
/// Adds two 64-bit unsigned integers. This is the implementation of the `+`
/// operator for `UInt64`.
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer operand.
/// * `other` : The second unsigned 64-bit integer operand.
///
/// Returns the sum of the two unsigned 64-bit integers. If the result overflows,
/// it wraps around modulo 2^64.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_add" {
///   let a = 42UL
///   let b = 100UL
///   inspect!(a + b, content="142")
///
///   // Demonstrate overflow behavior
///   let max = 18446744073709551615UL
///   inspect!(max + 1UL, content="0")
/// }
/// ```
pub fn UInt64::op_add(self : UInt64, other : UInt64) -> UInt64 = "%u64.add"

///|
/// Performs subtraction between two unsigned 64-bit integers. When the result
/// would be negative, the function wraps around using modular arithmetic (2^64).
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer (minuend).
/// * `other` : The second unsigned 64-bit integer to subtract from the first
/// (subtrahend).
///
/// Returns the difference between the two numbers, wrapped around if necessary.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_sub" {
///   let a = 5UL
///   let b = 3UL
///   inspect!(a - b, content="2")
///   let c = 3UL
///   let d = 5UL
///   inspect!(c - d, content="18446744073709551614") // wraps around to 2^64 - 2
/// }
/// ```
pub fn UInt64::op_sub(self : UInt64, other : UInt64) -> UInt64 = "%u64.sub"

///|
/// Performs multiplication between two unsigned 64-bit integers.
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer operand.
/// * `other` : The second unsigned 64-bit integer operand.
///
/// Returns the product of the two unsigned 64-bit integers. The result wraps
/// around if it exceeds the maximum value of `UInt64`.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_mul" {
///   let a = 2UL
///   let b = 3UL
///   inspect!(a * b, content="6")
///
///   // Demonstrate wrapping behavior
///   let max = 18446744073709551615UL
///   inspect!(max * 2UL, content="18446744073709551614") // Wraps around to max - 1
/// }
/// ```
pub fn UInt64::op_mul(self : UInt64, other : UInt64) -> UInt64 = "%u64.mul"

///|
/// Performs division operation between two unsigned 64-bit integers.
///
/// Parameters:
///
/// * `self` : The dividend unsigned 64-bit integer.
/// * `other` : The divisor unsigned 64-bit integer.
///
/// Returns the quotient of dividing the dividend by the divisor.
///
/// Throws a runtime error if `other` is zero.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_div" {
///   let a = 100UL
///   let b = 20UL
///   inspect!(a / b, content="5") // Using infix operator
/// }
///
/// test "panic UInt64::op_div/division_by_zero" {
///   let a = 42UL
///   ignore(a / 0UL) // Throws runtime error: division by zero
/// }
/// ```
pub fn UInt64::op_div(self : UInt64, other : UInt64) -> UInt64 = "%u64.div"

///|
/// Calculates the remainder of dividing one unsigned 64-bit integer by another.
///
/// Parameters:
///
/// * `self` : The dividend unsigned 64-bit integer.
/// * `other` : The divisor unsigned 64-bit integer.
///
/// Returns the remainder of the division operation.
///
/// Throws a panic if the divisor is zero.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_mod" {
///   let a = 17UL
///   let b = 5UL
///   inspect!(a % b, content="2") // 17 divided by 5 gives quotient 3 and remainder 2
///   inspect!(7UL % 4UL, content="3")
/// }
///
/// test "panic UInt64::op_mod/division_by_zero" {
///   let a = 42UL
///   ignore(a % 0UL) // Panics: division by zero
/// }
/// ```
pub fn UInt64::op_mod(self : UInt64, other : UInt64) -> UInt64 = "%u64.mod"

///|
/// Compares two unsigned 64-bit integers and determines their relative order.
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer to compare.
/// * `other` : The second unsigned 64-bit integer to compare.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
/// test "UInt64::compare" {
///   let a = 42UL
///   let b = 24UL
///   inspect!(a.compare(b), content="1") // 42 > 24
///   inspect!(b.compare(a), content="-1") // 24 < 42
///   inspect!(a.compare(a), content="0") // 42 = 42
/// }
/// ```
pub fn UInt64::compare(self : UInt64, other : UInt64) -> Int = "%u64.compare"

///|
/// Compares two unsigned 64-bit integers for equality.
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer to compare.
/// * `other` : The second unsigned 64-bit integer to compare.
///
/// Returns `true` if both integers have the same value, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_equal" {
///   let a = 42UL
///   let b = 42UL
///   let c = 24UL
///   inspect!(a == b, content="true")
///   inspect!(a == c, content="false")
/// }
/// ```
pub fn UInt64::op_equal(self : UInt64, other : UInt64) -> Bool = "%u64.eq"

///|
/// Performs a bitwise AND operation between two unsigned 64-bit integers.
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer operand.
/// * `other` : The second unsigned 64-bit integer operand.
///
/// Returns the result of performing a bitwise AND operation on the two operands.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::land" {
///   let a = 0xF0F0F0F0F0F0F0F0UL
///   let b = 0xFF00FF00FF00FF00UL
///   inspect!(a & b, content="17294086455919964160") // 0xF000F000F000F000
/// }
/// ```
pub fn UInt64::land(self : UInt64, other : UInt64) -> UInt64 = "%u64.bitand"

///|
/// Performs a bitwise OR operation between two unsigned 64-bit integers.
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer operand.
/// * `other` : The second unsigned 64-bit integer operand.
///
/// Returns a new `UInt64` value with bits set to 1 where either or both operands
/// have bits set to 1, and 0 where both operands have bits set to 0.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::lor" {
///   let a = 0xF0F0F0F0UL
///   let b = 0x0F0F0F0FUL
///   inspect!(a | b, content="4294967295") // All bits set to 1
/// }
/// ```
pub fn UInt64::lor(self : UInt64, other : UInt64) -> UInt64 = "%u64.bitor"

///|
/// Performs a bitwise XOR operation between two unsigned 64-bit integers. For
/// each bit position, the result is 1 if the bits at that position in the two
/// operands are different, and 0 if they are the same.
///
/// Parameters:
///
/// * `self` : The first unsigned 64-bit integer operand.
/// * `other` : The second unsigned 64-bit integer operand.
///
/// Returns a new `UInt64` value representing the bitwise XOR of the two
/// operands.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::lxor" {
///   let a = 0xF0F0F0F0UL
///   let b = 0x0F0F0F0FUL
///   inspect!(a ^ b, content="4294967295") // 0xFFFFFFFF
/// }
/// ```
pub fn UInt64::lxor(self : UInt64, other : UInt64) -> UInt64 = "%u64.bitxor"

///|
/// Performs a bitwise NOT operation on a 64-bit unsigned integer. Flips all bits
/// in the number, changing each 0 to 1 and each 1 to 0.
///
/// Parameters:
///
/// * `self` : The 64-bit unsigned integer value on which to perform the bitwise
/// NOT operation.
///
/// Returns a new `UInt64` value with all bits flipped from the input value.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::lnot" {
///   let x = 0xFFFF_FFFF_0000_0000UL
///   inspect!(x.lnot(), content="4294967295") // 0x0000_0000_FFFF_FFFF
/// }
/// ```
pub fn UInt64::lnot(self : UInt64) -> UInt64 = "%u64.bitnot"

///|
/// Performs a left shift operation on a 64-bit unsigned integer by a specified
/// number of bits.
///
/// Parameters:
///
/// * `value` : The 64-bit unsigned integer to be shifted.
/// * `shift` : The number of positions to shift left. Only the lowest 6 bits are
/// used, effectively making the shift value wrap around at 64.
///
/// Returns a new `UInt64` value representing the result of shifting the bits
/// left by the specified number of positions. Bits shifted beyond the 64-bit
/// boundary are discarded, and zeros are shifted in from the right.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::lsl" {
///   let x = 1UL
///   inspect!(x << 4, content="16") // 1 << 4 = 16
/// }
/// ```
///
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn UInt64::lsl(self : UInt64, shift : Int) -> UInt64 = "%u64.shl"

///|
/// Performs a left shift operation on an unsigned 64-bit integer value, shifting
/// bits to the left by the specified number of positions.
///
/// Parameters:
///
/// * `number` : The unsigned 64-bit integer to be shifted.
/// * `shift` : The number of positions to shift the bits left. Must be
/// non-negative.
///
/// Returns an unsigned 64-bit integer representing the result of the left shift
/// operation.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::shl" {
///   let x = 1UL
///   inspect!(x << 2, content="4") // 1 << 2 = 4
/// }
/// ```
///
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn UInt64::shl(self : UInt64, shift : Int) -> UInt64 = "%u64.shl"

///|
/// Performs a logical right shift on an unsigned 64-bit integer by a specified
/// number of bit positions. All bits shifted in from the left are zeros.
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer to be shifted.
/// * `shift` : The number of positions to shift right.
///
/// Returns the result of shifting the bits in `self` right by `shift` positions.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::shr" {
///   let x = 0xFF00000000000000UL
///   inspect!(x >> 8, content="71776119061217280")
/// }
/// ```
///
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn UInt64::shr(self : UInt64, shift : Int) -> UInt64 = "%u64.shr"

///|
/// Performs a logical right shift operation on a 64-bit unsigned integer. Moves
/// all bits to the right by a specified number of positions, filling the
/// leftmost bits with zeros.
///
/// Parameters:
///
/// * `self` : The 64-bit unsigned integer to be shifted.
/// * `shift` : The number of positions to shift right. If this value is negative
/// or greater than 63, the behavior is undefined.
///
/// Returns a new `UInt64` value containing the result of the right shift
/// operation.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::lsr" {
///   let x = 0xF000000000000000UL
///   inspect!(x >> 4, content="1080863910568919040") // 0x0F00000000000000
/// }
/// ```
///
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn UInt64::lsr(self : UInt64, shift : Int) -> UInt64 = "%u64.shr"

///|
/// Performs a bitwise left shift operation on an unsigned 64-bit integer.
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer to be shifted.
/// * `shift` : The number of positions to shift the bits to the left. Must be
/// between 0 and 63 inclusive, values outside this range will be masked with `&
/// 63`.
///
/// Returns the result of shifting `self` left by `shift` positions. For each
/// position shifted, the rightmost bit is filled with 0, and the leftmost bit is
/// discarded.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_shl" {
///   let x = 1UL
///   inspect!(x << 3, content="8") // 1 shifted left by 3 positions becomes 8
///   inspect!(x << 63, content="9223372036854775808") // 1 shifted left by 63 positions
/// }
/// ```
pub fn UInt64::op_shl(self : UInt64, shift : Int) -> UInt64 = "%u64.shl"

///|
/// Performs a logical right shift operation on a 64-bit unsigned integer by a
/// specified number of bits. All bits shifted beyond the least significant bit
/// are discarded, and zeros are shifted in from the most significant bit.
///
/// Parameters:
///
/// * `self` : The 64-bit unsigned integer to be shifted.
/// * `shift` : The number of positions to shift right. Only the least
/// significant 6 bits of this value are used, effectively making the shift count
/// always between 0 and 63.
///
/// Returns a new `UInt64` value representing the result of the right shift
/// operation.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::op_shr" {
///   let x = 0xFF00FF00FF00FF00UL
///   inspect!(x >> 8, content="71777214294589695") // Shifted right by 8 bits
///   inspect!(x >> 64, content="18374966859414961920") // Equivalent to x >> 0 due to masking
/// }
/// ```
pub fn UInt64::op_shr(self : UInt64, shift : Int) -> UInt64 = "%u64.shr"

///|
/// Counts the number of leading zero bits in a 64-bit unsigned integer, starting
/// from the most significant bit.
///
/// Parameters:
///
/// * `value` : The 64-bit unsigned integer to count leading zeros in.
///
/// Returns the number of consecutive zeros starting from the most significant
/// bit. For a zero value, returns 64.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::clz" {
///   inspect!(0UL.clz(), content="64")
///   inspect!(1UL.clz(), content="63")
///   inspect!(0x8000_0000_0000_0000UL.clz(), content="0")
/// }
/// ```
pub fn UInt64::clz(self : UInt64) -> Int = "%u64.clz"

///|
/// Counts the number of trailing zero bits in a 64-bit unsigned integer. The
/// trailing zeros are the contiguous zeros at the least significant end of the
/// binary representation.
///
/// Parameters:
///
/// * `value` : The 64-bit unsigned integer to count trailing zeros in.
///
/// Returns the number of trailing zero bits in the input value. If the input is
/// 0, returns 64.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::ctz" {
///   let x = 0x8000000000000000UL // Binary: 1000...0000 (63 trailing zeros)
///   inspect!(x.ctz(), content="63")
///   let y = 0UL
///   inspect!(y.ctz(), content="64")
/// }
/// ```
pub fn UInt64::ctz(self : UInt64) -> Int = "%u64.ctz"

///|
/// Counts the number of bits set to 1 in the binary representation of an
/// unsigned 64-bit integer.
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer whose bits are to be counted.
///
/// Returns an integer representing the number of 1 bits (population count) in
/// the binary representation of the input.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::popcnt" {
///   let n = 0x7000_0001_1F00_100FUL // Binary: 0111 0000 ... 0001 1111 0000 0000 0001 0000 0000 1111
///   inspect!(n.popcnt(), content="14") // Has 14 bits set to 1
/// }
/// ```
pub fn UInt64::popcnt(self : UInt64) -> Int = "%u64.popcnt"

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
/// ```moonbit
/// test "UInt64::to_float" {
///   let n = 42UL
///   inspect!(n.to_float().to_double(), content="42")
///   let big = 18446744073709551615UL // UInt64::max_value
///   inspect!(big.to_float().to_double(), content="18446744073709552000")
/// }
/// ```
pub fn UInt64::to_float(self : UInt64) -> Float = "%u64.to_f32"
