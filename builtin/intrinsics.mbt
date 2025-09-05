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
/// Evaluates an expression and discards its result. This is useful when you want
/// to execute an expression for its side effects but don't care about its return
/// value, or when you want to explicitly indicate that a value is intentionally
/// unused.
///
/// Parameters:
///
/// * `value` : The value to be ignored. Can be of any type.
///
/// Example:
///
/// ```moonbit
///   let x = 42
///   ignore(x) // Explicitly ignore the value
///   let mut sum = 0
///   ignore([1, 2, 3].iter().each((x) => { sum = sum + x })) // Ignore the Unit return value of each()
/// ```
pub fn[T] ignore(t : T) -> Unit = "%ignore"

///|
/// Tests if two values are physically equal (i.e., point to the same memory
/// location). Unlike structural equality testing (`==`), this function checks if
/// two references point to exactly the same object in memory.
///
/// Parameters:
///
/// * `first` : The first value to compare.
/// * `second` : The second value to compare.
/// * `T` : The type parameter representing the type of values being compared.
///
/// Returns `true` if both values refer to the same object in memory, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
///   let arr1 = [1, 2, 3]
///   let arr2 = arr1
///   let arr3 = [1, 2, 3]
///   inspect(physical_equal(arr1, arr2), content="true") // Same object
///   inspect(physical_equal(arr1, arr3), content="false") // Different objects with same content
/// ```
pub fn[T] physical_equal(a : T, b : T) -> Bool = "%refeq"

///|
pub fnalias @abort.abort

///|
pub fn[T] panic() -> T = "%panic"

// Bool primitive ops

///|
/// Performs logical negation on a boolean value.
///
/// Parameters:
///
/// * `value` : The boolean value to negate.
///
/// Returns the logical NOT of the input value: `true` if the input is `false`,
/// and `false` if the input is `true`.
///
/// Example:
///
/// ```moonbit
///   inspect(not(true), content="false")
///   inspect(not(false), content="true")
/// ```
pub fn not(x : Bool) -> Bool = "%bool_not"

///|
/// Compares two boolean values for equality.
///
/// Parameters:
///
/// * `self` : The first boolean value to compare.
/// * `other` : The second boolean value to compare.
///
/// Returns `true` if both boolean values are equal (either both `true` or both
/// `false`), `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   inspect(true == true, content="true")
///   inspect(false == true, content="false")
///   inspect(true == false, content="false")
///   inspect(false == false, content="true")
/// ```
pub impl Eq for Bool with equal(self : Bool, other : Bool) -> Bool = "%bool_eq"

///|
/// Compares two boolean values and returns their relative order. This is a
/// deprecated method and users should use `compare` instead.
///
/// Parameters:
///
/// * `self` : The first boolean value to compare.
/// * `other` : The second boolean value to compare against.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other` (i.e., `self` is `false`
/// and `other` is `true`)
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other` (i.e., `self` is `true`
/// and `other` is `false`)
///
/// Example:
///
/// ```moonbit
///   let t = true
///   let f = false
///   // This usage is deprecated, use compare() instead
///   inspect(t.compare(f), content="1")
///   inspect(f.compare(t), content="-1")
///   inspect(t.compare(t), content="0")
/// ```
///
#deprecated("Use `compare` instead")
#coverage.skip
pub fn Bool::op_compare(self : Bool, other : Bool) -> Int = "%bool_compare"

///|
/// Compares two boolean values and returns their relative order. The comparison
/// follows the rule that `false` is less than `true`.
///
/// Parameters:
///
/// * `self` : The first boolean value to compare.
/// * `other` : The second boolean value to compare against.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is `false` and `other` is `true`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is `true` and `other` is `false`
///
/// Example:
///
/// ```moonbit
///   inspect(true.compare(false), content="1") // true > false
///   inspect(false.compare(true), content="-1") // false < true
///   inspect(true.compare(true), content="0") // true = true
/// ```
pub impl Compare for Bool with compare(self, other) = "%bool_compare"

///|
/// Returns the default value for the `Bool` type, which is `false`.
///
/// Returns a `Bool` value that represents the default state of a boolean value.
///
/// Example:
///
/// ```moonbit
///   let b : Bool = Bool::default()
///   inspect(b, content="false")
/// ```
pub impl Default for Bool with default() = "%bool_default"

// int32 primitive ops

///|
/// Performs arithmetic negation on an integer value, returning its additive
/// inverse.
///
/// Parameters:
///
/// * `self` : The integer value to negate.
///
/// Returns the negation of the input value. For all inputs except
/// `Int::min_value()`, returns the value with opposite sign. When the input is
/// `Int::min_value()`, returns `Int::min_value()` due to two's complement
/// representation.
///
/// Example:
///
/// ```moonbit
///   inspect(-42, content="-42")
///   inspect(42, content="42")
///   inspect(--2147483647, content="2147483647") // negating near min value
/// ```
pub impl Neg for Int with neg(self) = "%i32_neg"

///|
/// Adds two 32-bit signed integers. Performs two's complement arithmetic, which
/// means the operation will wrap around if the result exceeds the range of a
/// 32-bit integer.
///
/// Parameters:
///
/// * `self` : The first integer operand.
/// * `other` : The second integer operand.
///
/// Returns a new integer that is the sum of the two operands. If the
/// mathematical sum exceeds the range of a 32-bit integer (-2,147,483,648 to
/// 2,147,483,647), the result wraps around according to two's complement rules.
///
/// Example:
///
/// ```moonbit
///   inspect(42 + 1, content="43")
///   inspect(2147483647 + 1, content="-2147483648") // Overflow wraps around to minimum value
/// ```
pub impl Add for Int with add(self, other) = "%i32_add"

///|
/// Performs subtraction between two 32-bit integers, following standard two's
/// complement arithmetic rules. When the result overflows or underflows, it
/// wraps around within the 32-bit integer range.
///
/// Parameters:
///
/// * `self` : The minuend (the number being subtracted from).
/// * `other` : The subtrahend (the number to subtract).
///
/// Returns the difference between `self` and `other`.
///
/// Example:
///
/// ```moonbit
///   let a = 42
///   let b = 10
///   inspect(a - b, content="32")
///   let max = 2147483647 // Int maximum value
///   inspect(max - -1, content="-2147483648") // Overflow case
/// ```
pub impl Sub for Int with sub(self, other) = "%i32_sub"

///|
/// Multiplies two 32-bit integers. This is the implementation of the `*`
/// operator for `Int`.
///
/// Parameters:
///
/// * `self` : The first integer operand.
/// * `other` : The second integer operand.
///
/// Returns the product of the two integers. If the result overflows the range of
/// `Int`, it wraps around according to two's complement arithmetic.
///
/// Example:
///
/// ```moonbit
///   inspect(42 * 2, content="84")
///   inspect(-10 * 3, content="-30")
///   let max = 2147483647 // Int.max_value
///   inspect(max * 2, content="-2") // Overflow wraps around
/// ```
pub impl Mul for Int with mul(self, other) = "%i32_mul"

///|
/// Performs integer division between two 32-bit integers. The result is
/// truncated towards zero (rounds down for positive numbers and up for negative
/// numbers).
///
/// Parameters:
///
/// * `dividend` : The first integer operand to be divided.
/// * `divisor` : The second integer operand that divides the dividend.
///
/// Returns the quotient of the division operation.
///
/// Throws a panic if `divisor` is zero.
///
/// Example:
///
/// ```moonbit
///   inspect(10 / 3, content="3") // truncates towards zero
///   inspect(-10 / 3, content="-3")
///   inspect(10 / -3, content="-3")
/// ```
pub impl Div for Int with div(self, other) = "%i32_div"

///|
/// Calculates the remainder of dividing one integer by another. The result
/// follows the formula `dividend - (dividend / divisor) * divisor`, maintaining
/// the same sign as the dividend.
///
/// Parameters:
///
/// * `self` : The dividend (the number being divided).
/// * `other` : The divisor (the number to divide by).
///
/// Returns the remainder of the division. If `other` is 0, the behavior is
/// undefined.
///
/// Example:
///
/// ```moonbit
///   inspect(7 % 3, content="1")
///   inspect(-7 % 3, content="-1")
///   inspect(7 % -3, content="1")
/// ```
pub impl Mod for Int with mod(self, other) = "%i32_mod"

///|
/// Performs a bitwise NOT operation on a 32-bit integer. Flips each bit in the
/// integer's binary representation (0 becomes 1 and 1 becomes 0).
///
/// Parameters:
///
/// * `value` : The 32-bit integer on which to perform the bitwise NOT operation.
///
/// Returns a new integer with all bits flipped from the input value.
///
/// Example:
///
/// ```moonbit
///   let a = -1 // All bits are 1
///   let b = 0 // All bits are 0
///   inspect(a.lnot(), content="0")
///   inspect(b.lnot(), content="-1")
/// ```
pub fn Int::lnot(self : Int) -> Int = "%i32_lnot"

///|
/// Performs a bitwise AND operation between two 32-bit integers. Each bit in the
/// result is set to 1 only if the corresponding bits in both operands are 1.
///
/// Parameters:
///
/// * `self` : The first 32-bit integer operand.
/// * `other` : The second 32-bit integer operand.
///
/// Returns the result of the bitwise AND operation. The resulting value has a
/// bit set to 1 at each position where both input integers have a bit set to 1.
///
/// Example:
///
/// ```moonbit
///   let x = 0xF0 // 11110000
///   let y = 0xAA // 10101010
///   inspect(x & y, content="160") // 10100000 = 160
/// ```
pub fn Int::land(self : Int, other : Int) -> Int = "%i32_land"

///|
/// Performs a bitwise OR operation between two 32-bit integers. For each bit
/// position, the result is 1 if at least one of the corresponding bits in either
/// operand is 1.
///
/// Parameters:
///
/// * `self` : The first integer operand.
/// * `other` : The second integer operand.
///
/// Returns a new integer where each bit is set to 1 if at least one of the
/// corresponding bits in either operand is 1, and 0 otherwise.
///
/// Example:
///
/// ```moonbit
///   let x = 0xF0F0 // 1111_0000_1111_0000
///   let y = 0x0F0F // 0000_1111_0000_1111
///   inspect(x | y, content="65535") // 1111_1111_1111_1111 = 65535
/// ```
pub fn Int::lor(self : Int, other : Int) -> Int = "%i32_lor"

///|
/// Performs a bitwise XOR operation between two integers.
///
/// Parameters:
///
/// * `self` : The first integer operand.
/// * `other` : The second integer operand.
///
/// Returns a new integer where each bit is set to 1 if the corresponding bits in
/// the operands are different, and 0 if they are the same.
///
/// Example:
///
/// ```moonbit
///   let x = 0xF0F0 // 1111_0000_1111_0000
///   let y = 0x0F0F // 0000_1111_0000_1111
///   inspect(x ^ y, content="65535") // 1111_1111_1111_1111
///   inspect(x ^ x, content="0") // XOR with self gives 0
/// ```
pub fn Int::lxor(self : Int, other : Int) -> Int = "%i32_lxor"

///|
/// Performs a left shift operation on a 32-bit integer. Shifts each bit in the
/// integer to the left by the specified number of positions, filling the
/// rightmost positions with zeros.
///
/// Parameters:
///
/// * `self` : The integer value to be shifted.
/// * `shift` : The number of positions to shift. Must be a non-negative value
/// less than 32. Values outside this range will be masked with `& 31`.
///
/// Returns a new integer with bits shifted left by the specified number of
/// positions. For each position shifted, the rightmost bit is filled with 0, and
/// the leftmost bit is discarded.
///
/// Example:
///
/// ```moonbit
///   let x = 1
///   inspect(x << 3, content="8") // Binary: 1 -> 1000
///   let y = -4
///   inspect(y << 2, content="-16") // Binary: 100 -> 10000
/// ```
pub impl Shl for Int with shl(self, other) = "%i32_shl"

///|
/// Performs an arithmetic right shift operation on an integer value. Shifts the
/// bits of the first operand to the right by the number of positions specified
/// by the second operand. The sign bit is preserved and copied to the leftmost
/// positions.
///
/// Parameters:
///
/// * `self` : The integer value to be shifted.
/// * `shift` : The number of positions to shift the bits to the right. Must be
/// non-negative.
///
/// Returns an integer representing the result of the arithmetic right shift
/// operation.
///
/// Example:
///
/// ```moonbit
///   let n = -16
///   inspect(n >> 2, content="-4") // Sign bit is preserved during shift
///   let p = 16
///   inspect(p >> 2, content="4") // Regular right shift for positive numbers
/// ```
pub impl Shr for Int with shr(self, other) = "%i32_shr"

///|
/// Performs a left shift operation on a 32-bit integer. Shifts each bit in the
/// integer to the left by the specified number of positions, filling the vacated
/// bit positions with zeros.
///
/// Parameters:
///
/// * `self` : The integer value to be shifted.
/// * `shift` : The number of positions to shift the bits to the left.
///
/// Returns an integer containing the result of shifting `self` left by `shift`
/// positions.
///
/// Example:
///
/// ```moonbit
///   let x = 1
///   inspect(x << 3, content="8") // Binary: 1 -> 1000
///   let y = 42
///   inspect(y << 2, content="168") // Binary: 101010 -> 10101000
/// ```
///
#deprecated("Use infix operator `<<` instead")
#coverage.skip
pub fn Int::lsl(self : Int, other : Int) -> Int = "%i32_shl"

///|
/// Performs a left shift operation on a 32-bit integer. Shifts the bits of the
/// first operand to the left by the specified number of positions. The rightmost
/// positions are filled with zeros.
///
/// Parameters:
///
/// * `value` : The integer value to be shifted.
/// * `shift` : The number of positions to shift left. Must be non-negative and
/// less than 32.
///
/// Returns a new integer value after performing the left shift operation. The
/// value is equal to multiplying the input by 2 raised to the power of the shift
/// count.
///
/// Example:
///
/// ```moonbit
///   let x = 1
///   inspect(x << 3, content="8") // Equivalent to x << 3
/// ```
///
#deprecated("Use infix operator `<<` instead")
#coverage.skip
pub fn Int::shl(self : Int, other : Int) -> Int = "%i32_shl"

///|
/// Performs a logical right shift operation on a signed 32-bit integer. In a
/// logical right shift, zeros are shifted in from the left, regardless of the
/// sign bit. This function is DEPRECATED and users should use `UInt` type with
/// the infix operator `>>` instead.
///
/// Parameters:
///
/// * `self` : The signed 32-bit integer value to be shifted.
/// * `shift` : The number of positions to shift right. Must be non-negative.
///
/// Returns a signed 32-bit integer containing the same bits as if the input were
/// treated as an unsigned integer and shifted right logically.
///
/// Example:
///
/// ```moonbit
///   let x = -4 // Binary: 11111...11100
///   let unsigned = x.reinterpret_as_uint() // Convert to UInt first
///   inspect(unsigned >> 1, content="2147483646") // Using the recommended operator
/// ```
///
#deprecated("Use UInt type and infix operator `>>` instead")
#coverage.skip
pub fn Int::lsr(self : Int, other : Int) -> Int {
  (self.reinterpret_as_uint() >> other).reinterpret_as_int()
}

///|
/// Performs an arithmetic right shift operation on a 32-bit integer value,
/// preserving the sign bit by replicating it into the positions vacated by the
/// shift. This is a deprecated function; use the infix operator `>>` instead.
///
/// Parameters:
///
/// * `self` : The integer value to be shifted.
/// * `shift` : The number of positions to shift right. Must be non-negative.
///
/// Returns a new integer value that is the result of arithmetically shifting
/// `self` right by `shift` positions.
///
/// Example:
///
/// ```moonbit
///   let x = -16
///   inspect(x >> 2, content="-4") // Right shift preserves sign bit
/// ```
///
#deprecated("Use infix operator `>>` instead")
#coverage.skip
pub fn Int::asr(self : Int, other : Int) -> Int = "%i32_shr"

///|
/// Performs an arithmetic right shift operation on a 32-bit integer by the
/// specified number of positions. The operation preserves the sign bit,
/// replicating it into the positions vacated by the shift.
///
/// Parameters:
///
/// * `self` : The integer value to be shifted.
/// * `shift` : The number of positions to shift right.
///
/// Returns a new integer representing the result of shifting `self` right by
/// `shift` positions.
///
/// Example:
///
/// ```moonbit
///   let n = -1024
///   inspect(n >> 3, content="-128") // Preserves sign bit during right shift
/// ```
///
#deprecated("Use infix operator `>>` instead")
#coverage.skip
pub fn Int::shr(self : Int, other : Int) -> Int = "%i32_shr"

///|
/// Counts the number of consecutive zero bits at the least significant end of
/// the integer's binary representation.
///
/// Parameters:
///
/// * `self` : The integer value whose trailing zeros are to be counted.
///
/// Returns the number of trailing zero bits (0 to 32). For example, returns 0 if
/// the value is odd (least significant bit is 1), returns 32 if the value is 0
/// (all bits are zeros).
///
/// Example:
///
/// ```moonbit
///   let x = 0
///   inspect(x.ctz(), content="32") // All bits are zero
///   let y = 1
///   inspect(y.ctz(), content="0") // No trailing zeros
///   let z = 16
///   inspect(z.ctz(), content="4") // Binary: ...10000
/// ```
pub fn Int::ctz(self : Int) -> Int = "%i32_ctz"

///|
pub fn Int::clz(self : Int) -> Int = "%i32_clz"

///|
/// Counts the number of set bits (1s) in the binary representation of a 32-bit
/// integer.
///
/// Parameters:
///
/// * `self` : The 32-bit integer whose bits are to be counted.
///
/// Returns the number of bits set to 1 in the binary representation of the input
/// integer.
///
/// Example:
///
/// ```moonbit
///   let x = 0b1011 // Binary: 1011 (3 bits set)
///   inspect(x.popcnt(), content="3")
///   let y = -1 // All bits set in two's complement
///   inspect(y.popcnt(), content="32")
/// ```
pub fn Int::popcnt(self : Int) -> Int = "%i32_popcnt"

///|
/// Compares two integers for equality.
///
/// Parameters:
///
/// * `self` : The first integer to compare.
/// * `other` : The second integer to compare.
///
/// Returns `true` if both integers have the same value, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   inspect(42 == 42, content="true")
///   inspect(42 == -42, content="false")
/// ```
pub impl Eq for Int with equal(self : Int, other : Int) -> Bool = "%i32_eq"

///|
/// Compares two integers and returns their relative order.
///
/// Parameters:
///
/// * `self` : The first integer to compare.
/// * `other` : The second integer to compare against.
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
///   let a = 42
///   let b = 24
///   inspect(a.compare(b), content="1") // 42 > 24
///   inspect(b.compare(a), content="-1") // 24 < 42
///   inspect(a.compare(a), content="0") // 42 = 42
/// ```
pub impl Compare for Int with compare(self, other) = "%i32_compare"

///|
pub fn Int::is_pos(self : Int) -> Bool = "%i32_is_pos"

///|
/// Tests whether an integer is negative.
///
/// Parameters:
///
/// * `self` : The integer to test.
///
/// Returns `true` if the integer is negative, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let neg = -42
///   let zero = 0
///   let pos = 42
///   inspect(neg.is_neg(), content="true")
///   inspect(zero.is_neg(), content="false")
///   inspect(pos.is_neg(), content="false")
/// ```
pub fn Int::is_neg(self : Int) -> Bool = "%i32_is_neg"

///|
pub fn Int::is_non_pos(self : Int) -> Bool = "%i32_is_non_pos"

///|
pub fn Int::is_non_neg(self : Int) -> Bool = "%i32_is_non_neg"

///|
/// Returns the default value for integers, which is 0.
///
/// Returns an integer value of 0.
///
/// Example:
///
/// ```moonbit
///   let x : Int = Int::default()
///   inspect(x, content="0")
/// ```
pub impl Default for Int with default() = "%i32_default"

///|
/// Converts a 32-bit integer to a double-precision floating-point number. The
/// conversion preserves the exact value since all integers in the range of `Int`
/// can be represented exactly as `Double` values.
///
/// Parameters:
///
/// * `self` : The 32-bit integer to be converted.
///
/// Returns a double-precision floating-point number that represents the same
/// numerical value as the input integer.
///
/// Example:
///
/// ```moonbit
///   let n = 42
///   inspect(n.to_double(), content="42")
///   let neg = -42
///   inspect(neg.to_double(), content="-42")
/// ```
pub fn Int::to_double(self : Int) -> Double = "%i32_to_f64"

///|
/// Converts a double-precision floating-point number to an unsigned 32-bit
/// integer by truncating the decimal part. When the input is NaN or negative,
/// returns 0. When the input exceeds the maximum value of UInt (4294967295),
/// returns 4294967295.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to be converted.
///
/// Returns an unsigned 32-bit integer representing the truncated value.
///
/// Example:
///
/// ```moonbit
///   inspect(UInt::trunc_double(42.75), content="42")
/// ```
pub fn UInt::trunc_double(val : Double) -> UInt = "%f64.to_u32"

///|
/// reinterpret the signed int as unsigned int, when the value is
/// non-negative, i.e, 0..=2^31-1, the value is the same. When the
/// value is negative, it turns into a large number,
/// for example, -1 turns into 2^32-1
pub fn Int::reinterpret_as_uint(self : Int) -> UInt = "%i32.to_u32_reinterpret"

///|
/// Reinterprets a signed 32-bit integer as an unsigned 32-bit integer. For
/// numbers within the range \[0, 2^31-1], the value remains the same. For
/// negative numbers, they are reinterpreted as large positive numbers in the
/// range \[2^31, 2^32-1].
///
/// Parameters:
///
/// * `value` : The signed 32-bit integer to be reinterpreted.
///
/// Returns an unsigned 32-bit integer that has the same bit pattern as the
/// input.
///
/// Example:
///
/// ```moonbit
///   let pos = 42
///   let neg = -1
///   inspect(pos.reinterpret_as_uint(), content="42")
///   inspect(neg.reinterpret_as_uint(), content="4294967295") // 2^32 - 1
/// ```
///
#deprecated("Use `reinterpret_as_uint` instead")
#coverage.skip
pub fn Int::to_uint(self : Int) -> UInt = "%i32.to_u32_reinterpret"
// Double primitive ops

///|
/// Converts a 32-bit signed integer to an unsigned 64-bit integer by first
/// converting it to a signed 64-bit integer and then reinterpreting the bits as
/// an unsigned value.
///
/// Parameters:
///
/// * `value` : The 32-bit signed integer to be converted.
///
/// Returns an unsigned 64-bit integer representing the same bit pattern as the
/// input value when extended to 64 bits.
///
/// Example:
///
/// ```moonbit
///   let pos = 42
///   inspect(pos.to_uint64(), content="42")
///   let neg = -1
///   inspect(neg.to_uint64(), content="18446744073709551615") // 2^64 - 1
/// ```
pub fn Int::to_uint64(self : Int) -> UInt64 {
  self.to_int64().reinterpret_as_uint64()
}

///|
/// Negates a double-precision floating-point number. For non-NaN inputs, changes
/// the sign of the number. For NaN inputs, returns NaN.
///
/// Parameters:
///
/// * `number` : The double-precision floating-point number to negate.
///
/// Returns a new double-precision floating-point number that is the negation of
/// the input number.
///
/// Example:
///
/// ```moonbit
///   inspect(-42.0, content="-42")
///   inspect(--42.0, content="42")
///   inspect(-(0.0 / 0.0), content="NaN") // Negating NaN returns NaN
/// ```
pub impl Neg for Double with neg(self) = "%f64_neg"

///|
/// Adds two double-precision floating-point numbers together following IEEE 754
/// standards.
///
/// Parameters:
///
/// * `self` : The first double-precision floating-point number.
/// * `other` : The second double-precision floating-point number to add.
///
/// Returns the sum of the two numbers. Special cases follow IEEE 754 rules:
///
/// * If either operand is NaN, returns NaN
/// * If adding +∞ and -∞, returns NaN
/// * If adding ±∞ with any finite number, returns ±∞
/// * If adding +0.0 and -0.0, returns +0.0
///
/// Example:
///
/// ```moonbit
///   inspect(2.5 + 3.7, content="6.2")
///   inspect(1.0 / 0.0 + -1.0 / 0.0, content="NaN") // Infinity + -Infinity = NaN
/// ```
pub impl Add for Double with add(self, other) = "%f64_add"

///|
/// Performs subtraction between two double-precision floating-point numbers.
///
/// Parameters:
///
/// * `self` : The first operand (minuend).
/// * `other` : The second operand (subtrahend).
///
/// Returns the difference between the two numbers according to IEEE 754
/// double-precision arithmetic rules.
///
/// Example:
///
/// ```moonbit
///   let a = 5.0
///   let b = 3.0
///   inspect(a - b, content="2")
///   inspect(0.0 / 0.0 - 1.0, content="NaN") // NaN - anything = NaN
/// ```
pub impl Sub for Double with sub(self, other) = "%f64_sub"

///|
/// Multiplies two double-precision floating-point numbers. This is the
/// implementation of the `*` operator for `Double` type.
///
/// Parameters:
///
/// * `self` : The first double-precision floating-point operand.
/// * `other` : The second double-precision floating-point operand.
///
/// Returns a new double-precision floating-point number representing the product
/// of the two operands. Special cases follow IEEE 754 standard:
///
/// * If either operand is NaN, returns NaN
/// * If one operand is infinity and the other is zero, returns NaN
/// * If one operand is infinity and the other is a non-zero finite number,
/// returns infinity with the appropriate sign
/// * If both operands are infinity, returns infinity with the appropriate sign
///
/// Example:
///
/// ```moonbit
///   inspect(2.5 * 2.0, content="5")
///   inspect(-2.0 * 3.0, content="-6")
///   let nan = 0.0 / 0.0 // NaN
///   inspect(nan * 1.0, content="NaN")
/// ```
pub impl Mul for Double with mul(self, other) = "%f64_mul"

///|
/// Performs division between two double-precision floating-point numbers.
/// Follows IEEE 754 standard for floating-point arithmetic, including handling
/// of special cases like division by zero (returns infinity) and operations
/// involving NaN.
///
/// Parameters:
///
/// * `self` : The dividend (numerator) in the division operation.
/// * `other` : The divisor (denominator) in the division operation.
///
/// Returns the result of dividing `self` by `other`. Special cases follow IEEE
/// 754:
///
/// * Division by zero returns positive or negative infinity based on the
/// dividend's sign
/// * Operations involving NaN return NaN
/// * Division of infinity by infinity returns NaN
///
/// Example:
///
/// ```moonbit
///   inspect(6.0 / 2.0, content="3")
///   inspect(-6.0 / 2.0, content="-3")
///   inspect(1.0 / 0.0, content="Infinity")
/// ```
pub impl Div for Double with div(self, other) = "%f64_div"

///|
/// Calculates the square root of a double-precision floating-point number. For
/// non-negative numbers, returns the positive square root. For negative numbers
/// or NaN, returns NaN.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number whose square root is to
/// be calculated.
///
/// Returns the square root of the input number, or NaN if the input is negative
/// or NaN.
///
/// Example:
///
/// ```moonbit
///   inspect(4.0.sqrt(), content="2")
///   inspect(0.0.sqrt(), content="0")
///   inspect((-1.0).sqrt(), content="NaN")
/// ```
pub fn Double::sqrt(self : Double) -> Double = "%f64_sqrt"

///|
/// Compares two double-precision floating-point numbers for equality following
/// IEEE 754 rules. Returns `true` if both numbers are equal, including when both
/// are `NaN`. Note that this differs from the standard IEEE 754 behavior where
/// `NaN` is not equal to any value, including itself.
///
/// Parameters:
///
/// * `self` : The first double-precision floating-point number to compare.
/// * `other` : The second double-precision floating-point number to compare.
///
/// Returns `true` if both numbers are equal, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let a = 3.14
///   let b = 3.14
///   let c = 2.718
///   inspect(a == b, content="true")
///   inspect(a == c, content="false")
///   let nan = 0.0 / 0.0 // NaN
///   inspect(nan == nan, content="false") // Note: NaN equals itself in MoonBit
/// ```
pub impl Eq for Double with equal(self : Double, other : Double) -> Bool = "%f64_eq"

///|
/// Tests for inequality between two double-precision floating-point numbers.
/// Takes into account special cases like NaN, where two NaN values are
/// considered not equal to each other.
///
/// Parameters:
///
/// * `self` : The first double-precision floating-point number to compare.
/// * `other` : The second double-precision floating-point number to compare.
///
/// Returns `true` if the two numbers are not equal according to IEEE 754 rules,
/// `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   inspect(1.0 != 2.0, content="true")
///   inspect(1.0 != 1.0, content="false")
///   inspect(0.0 / 0.0 != 0.0 / 0.0, content="true") // NaN != NaN
/// ```
pub fn Double::op_neq(self : Double, other : Double) -> Bool = "%f64_ne"

///|
/// Compares two double-precision floating-point numbers and returns their
/// relative order. Follows IEEE 754 rules for floating-point comparisons,
/// including handling of special values like NaN.
///
/// Parameters:
///
/// * `self` : The first double-precision floating-point number to compare.
/// * `other` : The second double-precision floating-point number to compare
/// against.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
/// * If either value is NaN, returns an implementation-defined value that is
/// consistent with total ordering
///
/// Example:
///
/// ```moonbit
///   let a = 3.14
///   let b = 2.718
///   inspect(a.compare(b), content="1") // 3.14 > 2.718
///   inspect(b.compare(a), content="-1") // 2.718 < 3.14
///   inspect(a.compare(a), content="0") // 3.14 = 3.14
/// ```
pub impl Compare for Double with compare(self, other) = "%f64_compare"

///|
/// Returns the default value for double-precision floating-point numbers (0.0).
///
/// Returns a `Double` value initialized to 0.0.
///
/// Example:
///
/// ```moonbit
///   inspect(Double::default(), content="0")
/// ```
pub impl Default for Double with default() = "%f64_default"

///|
/// Converts an unsigned 32-bit integer to a double-precision floating-point
/// number. Since the range of unsigned 32-bit integers is smaller than what can
/// be precisely represented by a double-precision floating-point number, this
/// conversion is guaranteed to be exact.
///
/// Parameters:
///
/// * `value` : The unsigned 32-bit integer to be converted.
///
/// Returns a double-precision floating-point number that exactly represents the
/// input value.
///
/// Example:
///
/// ```moonbit
///   let n = 42U
///   inspect(Double::convert_uint(n), content="42")
///   let max = 4294967295U // maximum value of UInt
///   inspect(Double::convert_uint(max), content="4294967295")
/// ```
pub fn Double::convert_uint(val : UInt) -> Double = "%u32.to_f64"

// Char primitive ops

///|
/// Converts a character to its Unicode code point value as an integer.
///
/// Parameters:
///
/// * `self` : The character to be converted.
///
/// Returns an integer representing the Unicode code point value of the
/// character.
///
/// Example:
///
/// ```moonbit
///   inspect('A'.to_int(), content="65") // ASCII value of 'A'
///   inspect('あ'.to_int(), content="12354") // Unicode code point of 'あ'
/// ```
pub fn Char::to_int(self : Char) -> Int = "%char_to_int"

///|
/// Converts a Unicode character to its unsigned 32-bit integer code point
/// representation. The character's code point value is first converted to a
/// signed integer and then reinterpreted as an unsigned integer.
///
/// Parameters:
///
/// * `character` : The Unicode character to be converted.
///
/// Returns an unsigned 32-bit integer representing the character's Unicode code
/// point.
///
/// Example:
///
/// ```moonbit
///   let c = 'A'
///   inspect(c.to_uint(), content="65") // ASCII value of 'A'
///   let emoji = '🤣'
///   inspect(emoji.to_uint(), content="129315") // Unicode code point U+1F923
/// ```
pub fn Char::to_uint(self : Char) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///|
#deprecated("Use `Int::unsafe_to_char` instead, and use `Int::to_char` for safe conversion")
pub fn Char::from_int(val : Int) -> Char = "%char_from_int"

///|
/// Compares two characters for equality.
///
/// Parameters:
///
/// * `self` : The first character to compare.
/// * `other` : The second character to compare.
///
/// Returns `true` if both characters represent the same Unicode code point,
/// `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let a = 'A'
///   let b = 'A'
///   let c = 'B'
///   inspect(a == b, content="true")
///   inspect(a == c, content="false")
/// ```
pub impl Eq for Char with equal(self : Char, other : Char) -> Bool = "%char_eq"

///|
/// Compares two characters based on their Unicode code points. Returns a
/// negative value if the first character comes before the second, zero if they
/// are equal, and a positive value if the first character comes after the
/// second.
///
/// Parameters:
///
/// * `self` : The first character to compare.
/// * `other` : The second character to compare against.
///
/// Returns an integer indicating the relative ordering:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
///   inspect('a'.compare('b'), content="-1")
///   inspect('b'.compare('a'), content="1")
///   inspect('a'.compare('a'), content="0")
/// ```
pub impl Compare for Char with compare(self, other) = "%char_compare"

///|
/// Returns the default value for the `Char` type, which is the null character
/// (`'\x00'`).
///
/// Returns a `Char` value representing the null character.
///
/// Example:
///
/// ```moonbit
///   assert_true(Char::default().to_string() == "\u0000")
/// ```
pub impl Default for Char with default() = "%char_default"

// Bytes primitive ops

///|
/// Retrieves a byte at the specified index from a byte sequence.
///
/// Parameters:
///
/// * `bytes` : The byte sequence to access.
/// * `index` : The position in the byte sequence from which to retrieve the
/// byte.
///
/// Returns a byte value from the specified position in the sequence.
///
/// Throws a panic if the index is negative or greater than or equal to the
/// length of the byte sequence.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03"
///   inspect(bytes[1], content="b'\\x02'")
/// ```
pub fn Bytes::op_get(self : Bytes, idx : Int) -> Byte = "%bytes_get"

///|
/// Retrieves a byte at the specified index from a byte sequence without
/// performing bounds checking. This is a low-level operation that should be used
/// with caution.
///
/// Parameters:
///
/// * `bytes` : The byte sequence to retrieve the byte from.
/// * `index` : The position in the byte sequence from which to retrieve the
/// byte.
///
/// Returns a single byte from the specified position in the byte sequence.
///
/// Throws a panic if the index is negative or greater than or equal to the
/// length of the byte sequence.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03"
///   inspect(bytes.unsafe_get(1), content="b'\\x02'")
/// ```
///
#internal(unsafe, "Panic if index is out of bounds")
pub fn Bytes::unsafe_get(self : Bytes, idx : Int) -> Byte = "%bytes.unsafe_get"

///|
/// Returns the number of bytes in a byte sequence.
///
/// Parameters:
///
/// * `bytes` : The byte sequence whose length is to be determined.
///
/// Returns an integer representing the length (number of bytes) of the sequence.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03"
///   inspect(bytes.length(), content="3")
///   let empty = b""
///   inspect(empty.length(), content="0")
/// ```
pub fn Bytes::length(self : Bytes) -> Int = "%bytes_length"

///|
/// Creates a new byte sequence of the specified length, where each byte is
/// initialized to the given value. Returns an empty byte sequence if the
/// length is negative.
///
/// Parameters:
///
/// * `length` : The length of the byte sequence to create. Must be non-negative.
/// * `initial_value` : The byte value used to initialize each position in the
/// sequence.
///
/// Example:
///
/// ```moonbit
///   let bytes = Bytes::make(3, b'\xFF')
///   inspect(
///     bytes, 
///     content=(
///       #|b"\xff\xff\xff"
///     ),
///   )
///   let empty = Bytes::make(0, b'\x00')
///   inspect(empty, content="b\"\"")
/// ```
pub fn Bytes::make(len : Int, init : Byte) -> Bytes {
  if len < 0 {
    return []
  }
  Bytes::unsafe_make(len, init)
}

///|
fn Bytes::unsafe_make(len : Int, init : Byte) -> Bytes = "%bytes_make"

///|
/// Creates a new byte sequence filled with zero bytes.
///
/// Parameters:
///
/// * `length` : The length of the byte sequence to create. Must be a
/// non-negative integer.
///
/// Returns a new byte sequence of the specified length, with all bytes
/// initialized to zero.
///
/// Example:
///
/// ```moonbit
///   let bytes = Bytes::new(3)
///   inspect(bytes, content="b\"\\x00\\x00\\x00\"")
///
///   let bytes = Bytes::new(0)
///   inspect(bytes, content="b\"\"")
/// ```
pub fn Bytes::new(len : Int) -> Bytes {
  Bytes::make(len, b'\x00')
}

///|
/// Converts a 32-bit signed integer to a byte by taking its least significant 8
/// bits. Any bits beyond the first 8 bits are truncated.
///
/// Parameters:
///
/// * `value` : The 32-bit signed integer to be converted. Only the least
/// significant 8 bits will be used.
///
/// Returns a byte containing the least significant 8 bits of the input integer.
///
/// Example:
///
/// ```moonbit
///   let n = 258 // In binary: 100000010
///   inspect(n.to_byte(), content="b'\\x02'") // Only keeps 00000010
///   let neg = -1 // In binary: all 1's
///   inspect(neg.to_byte(), content="b'\\xFF'") // Only keeps 11111111
/// ```
pub fn Int::to_byte(self : Int) -> Byte = "%i32_to_byte"

///|
pub fn Int::unsafe_to_char(self : Int) -> Char = "%char_from_int"

///|
pub fn Int::to_char(self : Int) -> Char? {
  if self is (0..=0xD7FF) || self is (0xE000..=0x10FFFF) {
    Some(self.unsafe_to_char())
  } else {
    None
  }
}

///|
/// Converts an unsigned 64-bit integer to a byte by truncating it to fit within
/// the byte range (0 to 255).
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer to be converted.
///
/// Returns a byte containing the least significant 8 bits of the input integer.
///
/// Example:
///
/// ```moonbit
///   let n = 258UL // In binary: 100000010
///   inspect(n.to_byte(), content="b'\\x02'") // Only keeps 00000010
/// ```
pub fn UInt64::to_byte(self : UInt64) -> Byte {
  self.to_int().to_byte()
}

// FixedArray primitive ops

///|
/// Retrieves an element at the specified index from a fixed-size array. This
/// function implements the array indexing operator `[]`.
///
/// Parameters:
///
/// * `array` : The fixed-size array to access.
/// * `index` : The position in the array from which to retrieve the element.
///
/// Returns the element at the specified index.
///
/// Throws a runtime error if the index is out of bounds (negative or greater
/// than or equal to the length of the array).
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 42)
///   inspect(arr[1], content="42")
/// ```
pub fn[T] FixedArray::op_get(self : FixedArray[T], idx : Int) -> T = "%fixedarray.get"

///|
/// Retrieves an element from a fixed-size array at the specified index without
/// performing bounds checking. This is an unsafe operation that may cause
/// undefined behavior if used incorrectly.
///
/// Parameters:
///
/// * `array` : The fixed-size array to retrieve the element from.
/// * `index` : The position in the array from which to retrieve the element.
///
/// Returns the element at the specified index in the array.
///
/// Throws a panic if the index is out of bounds (negative or greater than or
/// equal to the array's length).
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 42)
///   inspect(arr.unsafe_get(1), content="42")
/// ```
///
#internal(unsafe, "Panic if index is out of bounds")
pub fn[T] FixedArray::unsafe_get(self : FixedArray[T], idx : Int) -> T = "%fixedarray.unsafe_get"

///|
#internal(unsafe, "Panic if index is out of bounds")
pub fn[T] FixedArray::unsafe_set(
  self : FixedArray[T],
  idx : Int,
  val : T,
) -> Unit = "%fixedarray.unsafe_set"

///|
/// Sets a value at the specified index in a fixed-size array. The original value
/// at that index is overwritten.
///
/// Parameters:
///
/// * `array` : The fixed-size array to modify.
/// * `index` : The position in the array where the value will be set.
/// * `value` : The new value to assign at the specified index.
///
/// Throws a runtime error if the index is out of bounds (less than 0 or greater
/// than or equal to the length of the array).
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3]
///   arr[1] = 42
///   inspect(arr, content="[1, 42, 3]")
/// ```
///
#intrinsic("%fixedarray.set")
pub fn[T] FixedArray::op_set(self : FixedArray[T], idx : Int, val : T) -> Unit = "%fixedarray.set"

///|
/// Sets the value at the specified index in a fixed-size array.
///
/// Parameters:
///
/// * `array` : The fixed-size array to be modified.
/// * `index` : The index at which to set the value. Must be non-negative and
/// less than the array's length.
/// * `value` : The value to be set at the specified index.
///
/// Throws a runtime error if the index is out of bounds (less than 0 or greater
/// than or equal to the array's length).
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 0)
///   arr.set(1, 42)
///   inspect(arr[1], content="42")
/// ```
pub fn[T] FixedArray::set(self : FixedArray[T], idx : Int, val : T) -> Unit = "%fixedarray.set"

///|
/// Returns the number of elements in a fixed-size array.
///
/// Parameters:
///
/// * `array` : The fixed-size array whose length is to be determined.
///
/// Returns an integer representing the number of elements in the array.
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 42)
///   inspect(arr.length(), content="3")
/// ```
pub fn[T] FixedArray::length(self : FixedArray[T]) -> Int = "%fixedarray.length"

///|
/// Creates a new fixed-size array with the specified length, initializing all
/// elements with the given value.
///
/// Parameters:
///
/// * `length` : The length of the array to create. Must be non-negative.
/// * `initial_value` : The value used to initialize all elements in the array.
///
/// Returns a new fixed-size array of type `FixedArray[T]` with `length`
/// elements, where each element is initialized to `initial_value`.
///
/// Throws a panic if `length` is negative.
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 42)
///   inspect(arr[0], content="42")
///   inspect(arr.length(), content="3")
/// ```
/// 
/// WARNING: A common pitfall is creating with the same initial value, for example:
/// ```moonbit
///   let two_dimension_array = FixedArray::make(10, FixedArray::make(10, 0))
///   two_dimension_array[0][5] = 10
///   assert_eq(two_dimension_array[5][5], 10)
/// ```
/// This is because all the cells reference to the same object (the FixedArray[Int] in this case). 
/// One should use makei() instead which creates an object for each index.
pub fn[T] FixedArray::make(len : Int, init : T) -> FixedArray[T] = "%fixedarray.make"

// String primitive ops

///|
/// Returns the number of UTF-16 code units in the string. Note that this is not
/// necessarily equal to the number of Unicode characters (code points) in the
/// string, as some characters may be represented by multiple UTF-16 code units.
///
/// Parameters:
///
/// * `string` : The string whose length is to be determined.
///
/// Returns the number of UTF-16 code units in the string.
///
/// Example:
///
/// ```moonbit
///   inspect("hello".length(), content="5")
///   inspect("🤣".length(), content="2") // Emoji uses two UTF-16 code units
///   inspect("".length(), content="0") // Empty string
/// ```
#alias(charcode_length, deprecated)
pub fn String::length(self : String) -> Int = "%string_length"

///|
/// Returns the UTF-16 code unit at the given index.
///
/// Parameters:
///
/// * `string` : The string to access.
/// * `index` : The position in the string from which to retrieve the code unit.
///
/// This method has O(1) complexity.
#alias(charcode_at, deprecated)
pub fn String::op_get(self : String, idx : Int) -> Int = "%string_get"

///|
/// Returns the UTF-16 code unit at a given position in the string without
/// performing bounds checking. This is a low-level function that provides direct
/// access to the internal representation of the string.
///
/// Parameters:
///
/// * `string` : The string from which to retrieve the code unit.
/// * `index` : The position of the code unit to retrieve.
///
/// Returns the UTF-16 code unit at the specified position as an integer.
///
/// Example:
///
/// ```moonbit
///   let str = "B🤣🤣C"
///   inspect(str.unsafe_charcode_at(0), content="66") // 'B'
///   inspect(str.unsafe_charcode_at(1), content="55358") // First surrogate of 🤣
///   inspect(str.unsafe_charcode_at(2), content="56611") // Second surrogate of 🤣
///   inspect(str.unsafe_charcode_at(3), content="55358") // First surrogate of 🤣
///   inspect(str.unsafe_charcode_at(4), content="56611") // Second surrogate of 🤣
///   inspect(str.unsafe_charcode_at(5), content="67") // 'C'
/// ```
/// TODO: rename to `unsafe_get`
#internal(unsafe, "Panic if index is out of bounds.")
pub fn String::unsafe_charcode_at(self : String, idx : Int) -> Int = "%string.unsafe_get"

///|
/// Concatenates two strings, creating a new string that contains all characters
/// from the first string followed by all characters from the second string.
///
/// Parameters:
///
/// * `self` : The first string to concatenate.
/// * `other` : The second string to concatenate.
///
/// Returns a new string containing the concatenation of both input strings.
///
/// Example:
///
/// ```moonbit
///   let hello = "Hello"
///   let world = " World!"
///   inspect(hello + world, content="Hello World!")
///   inspect("" + "abc", content="abc") // concatenating with empty string
/// ```
pub impl Add for String with add(self, other) = "%string_add"

///|
/// Tests whether two strings are equal by comparing their characters.
///
/// Parameters:
///
/// * `self` : The first string to compare.
/// * `other` : The second string to compare.
///
/// Returns `true` if both strings contain exactly the same sequence of
/// characters, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let str1 = "hello"
///   let str2 = "hello"
///   let str3 = "world"
///   inspect(str1 == str2, content="true")
///   inspect(str1 == str3, content="false")
/// ```
pub impl Eq for String with equal(self : String, other : String) -> Bool = "%string_eq"

///|
/// Returns the string itself without any modifications. This method is primarily
/// used to implement the `Show` trait, which requires a `to_string` function.
///
/// Parameters:
///
/// * `string` : The string value to be returned.
///
/// Returns the same string that was passed in.
///
/// Example:
///
/// ```moonbit
///   let s = "hello"
///   inspect(s.to_string(), content="hello")
/// ```
pub fn String::to_string(self : String) -> String = "%string_to_string"

// For internal use only

///|
priv type UnsafeMaybeUninit[_]

///|
/// Converts a byte value to a 32-bit signed integer. The resulting integer will
/// have the same binary representation as the byte value, preserving the
/// numerical value in the range \[0, 255].
///
/// Parameters:
///
/// * `byte` : The byte value to be converted to an integer.
///
/// Returns a 32-bit signed integer representing the same numerical value as the
/// input byte.
///
/// Example:
///
/// ```moonbit
///   let b = b'\xFF' // byte with value 255
///   inspect(b.to_int(), content="255")
///   let zero = b'\x00'
///   inspect(zero.to_int(), content="0")
/// ```
pub fn Byte::to_int(self : Byte) -> Int = "%byte_to_int"

///|
/// Converts a byte value to a character.
///
/// Parameters:
///
/// * `byte` : The byte value to be converted.
///
/// Returns the character corresponding to the byte value.
pub fn Byte::to_char(self : Byte) -> Char {
  self.to_int().unsafe_to_char()
}

///|
/// Converts a byte value to a 64-bit signed integer by first converting it to a
/// 32-bit integer and then extending it to a 64-bit integer.
///
/// Parameters:
///
/// * `byte` : The byte value to be converted.
///
/// Returns a 64-bit signed integer representing the same numerical value as the
/// input byte.
///
/// Example:
///
/// ```moonbit
///   let b = b'\xFF'
///   inspect(b.to_int64(), content="255")
/// ```
pub fn Byte::to_int64(self : Byte) -> Int64 {
  self.to_int().to_int64()
}

///|
/// reinterpret the unsigned int as signed int
/// For number within the range of 0..=2^31-1,
/// the value is the same. For number within the range of 2^31..=2^32-1,
/// the value is negative
pub fn UInt::reinterpret_as_int(self : UInt) -> Int = "%u32.to_i32_reinterpret"

///|
/// Reinterprets an unsigned 32-bit integer as a signed 32-bit integer. For
/// values within the range of 0 to 2^31-1, the value remains the same. For
/// values within the range of 2^31 to 2^32-1, the value becomes negative due to
/// two's complement representation.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be reinterpreted.
///
/// Returns a signed 32-bit integer that has the same bit pattern as the input
/// unsigned integer.
///
/// Example:
///
/// ```moonbit
///   let a = 42U
///   inspect(a.reinterpret_as_int(), content="42")
///   let b = 4294967295U // maximum value of UInt (2^32 - 1)
///   inspect(b.reinterpret_as_int(), content="-1") // becomes -1 when reinterpreted as Int
/// ```
///
#deprecated("Use `reinterpret_as_int` instead")
#coverage.skip
pub fn UInt::to_int(self : UInt) -> Int = "%u32.to_i32_reinterpret"

///|
/// Performs addition between two unsigned 32-bit integers. If the result
/// overflows, it wraps around according to the rules of modular arithmetic
/// (2^32).
///
/// Parameters:
///
/// * `self` : The first unsigned 32-bit integer operand.
/// * `other` : The second unsigned 32-bit integer operand to be added.
///
/// Returns the sum of the two unsigned integers, wrapped around if necessary.
///
/// Example:
///
/// ```moonbit
///   let a = 42U
///   let b = 100U
///   inspect(a + b, content="142")
///
///   // Demonstrate overflow behavior
///   let max = 4294967295U // UInt::max_value
///   inspect(max + 1U, content="0")
/// ```
pub impl Add for UInt with add(self, other) = "%u32.add"

///|
/// Performs subtraction between two unsigned 32-bit integers. When the result
/// would be negative, the function wraps around using modular arithmetic (2^32).
///
/// Parameters:
///
/// * `self` : The first unsigned 32-bit integer (minuend).
/// * `other` : The second unsigned 32-bit integer to subtract from the first
/// (subtrahend).
///
/// Returns a new unsigned 32-bit integer representing the difference between the
/// two numbers. If the result would be negative, it wraps around to a positive
/// number by adding 2^32 repeatedly until the result is in range.
///
/// Example:
///
/// ```moonbit
///   let a = 5U
///   let b = 3U
///   inspect(a - b, content="2")
///   let c = 3U
///   let d = 5U
///   inspect(c - d, content="4294967294") // wraps around to 2^32 - 2
/// ```
pub impl Sub for UInt with sub(self, other) = "%u32.sub"

///|
/// Performs multiplication between two unsigned 32-bit integers. The result
/// wraps around if it exceeds the maximum value of `UInt`.
///
/// Parameters:
///
/// * `self` : The first unsigned integer operand.
/// * `other` : The second unsigned integer operand.
///
/// Returns the product of the two unsigned integers. If the result exceeds the
/// maximum value of `UInt` (4294967295), it wraps around to the corresponding
/// value modulo 2^32.
///
/// Example:
///
/// ```moonbit
///   let a = 3U
///   let b = 4U
///   inspect(a * b, content="12")
///   let max = 4294967295U
///   inspect(max * 2U, content="4294967294") // Wraps around to max * 2 % 2^32
/// ```
pub impl Mul for UInt with mul(self, other) = "%u32.mul"

///|
/// Performs division between two unsigned 32-bit integers. The operation follows
/// standard unsigned integer division rules, where the result is truncated
/// towards zero.
///
/// Parameters:
///
/// * `self` : The dividend (the number to be divided).
/// * `other` : The divisor (the number to divide by).
///
/// Returns an unsigned 32-bit integer representing the quotient of the division.
///
/// Example:
///
/// ```moonbit
///   let a = 42U
///   let b = 5U
///   inspect(a / b, content="8") // Using infix operator
/// ```
pub impl Div for UInt with div(self, other) = "%u32.div"

///|
/// Calculates the remainder of dividing one unsigned integer by another.
///
/// Parameters:
///
/// * `self` : The unsigned integer dividend.
/// * `other` : The unsigned integer divisor.
///
/// Returns the remainder of the division operation.
///
/// Throws a panic if `other` is zero.
///
/// Example:
///
/// ```moonbit
///   let a = 17U
///   let b = 5U
///   inspect(a % b, content="2") // 17 divided by 5 gives quotient 3 and remainder 2
///   inspect(7U % 4U, content="3")
/// ```
pub impl Mod for UInt with mod(self, other) = "%u32.mod"

///|
/// Compares two unsigned 32-bit integers for equality.
///
/// Parameters:
///
/// * `self` : The first unsigned integer operand.
/// * `other` : The second unsigned integer operand to compare with.
///
/// Returns `true` if both integers have the same value, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let a = 42U
///   let b = 42U
///   let c = 24U
///   inspect(a == b, content="true")
///   inspect(a == c, content="false")
/// ```
pub impl Eq for UInt with equal(self : UInt, other : UInt) -> Bool = "%u32.eq"

///|
/// Checks if two unsigned 32-bit integers are not equal.
///
/// Parameters:
///
/// * `self` : The first unsigned integer to compare.
/// * `other` : The second unsigned integer to compare.
///
/// Returns `true` if the two integers are not equal, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let a = 42U
///   let b = 24U
///   inspect(a != b, content="true")
///   inspect(a != a, content="false")
/// ```
pub fn UInt::op_neq(self : UInt, other : UInt) -> Bool = "%u32.ne"

///|
/// Compares two unsigned 32-bit integers and returns their relative order.
///
/// Parameters:
///
/// * `self` : The first unsigned integer to compare.
/// * `other` : The second unsigned integer to compare against.
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
///   let a = 42U
///   let b = 24U
///   inspect(a.compare(b), content="1") // 42 > 24
///   inspect(b.compare(a), content="-1") // 24 < 42
///   inspect(a.compare(a), content="0") // 42 = 42
/// ```
pub impl Compare for UInt with compare(self, other) = "%u32.compare"

///|
/// Performs a bitwise AND operation between two unsigned 32-bit integers. For
/// each bit position, the result is 1 if the bits at that position in both
/// operands are 1, and 0 otherwise.
///
/// Parameters:
///
/// * `self` : The first unsigned 32-bit integer operand.
/// * `other` : The second unsigned 32-bit integer operand.
///
/// Returns an unsigned 32-bit integer representing the result of the bitwise AND
/// operation.
///
/// Example:
///
/// ```moonbit
///   let a = 0xF0F0U // 1111_0000_1111_0000
///   let b = 0xFF00U // 1111_1111_0000_0000
///   inspect(a & b, content="61440") // 1111_0000_0000_0000 = 61440
/// ```
pub fn UInt::land(self : UInt, other : UInt) -> UInt = "%u32.bitand"

///|
/// Performs a bitwise OR operation between two unsigned 32-bit integers. For
/// each bit position, the result is 1 if at least one of the corresponding bits
/// in either operand is 1.
///
/// Parameters:
///
/// * `self` : The first unsigned 32-bit integer operand.
/// * `other` : The second unsigned 32-bit integer operand.
///
/// Returns the result of the bitwise OR operation as an unsigned 32-bit integer.
///
/// Example:
///
/// ```moonbit
///   let a = 0xF0F0U // Binary: 1111_0000_1111_0000
///   let b = 0x0F0FU // Binary: 0000_1111_0000_1111
///   inspect(a | b, content="65535") // Binary: 1111_1111_1111_1111
/// ```
pub fn UInt::lor(self : UInt, other : UInt) -> UInt = "%u32.bitor"

///|
/// Performs a bitwise XOR (exclusive OR) operation between two unsigned 32-bit
/// integers. Each bit in the result is set to 1 if the corresponding bits in the
/// operands are different, and 0 if they are the same.
///
/// Parameters:
///
/// * `self` : The first unsigned 32-bit integer operand.
/// * `other` : The second unsigned 32-bit integer operand.
///
/// Returns the result of the bitwise XOR operation.
///
/// Example:
///
/// ```moonbit
///   let a = 0xFF00U // Binary: 1111_1111_0000_0000
///   let b = 0x0F0FU // Binary: 0000_1111_0000_1111
///   inspect(a ^ b, content="61455") // Binary: 1111_0000_0000_1111
/// ```
pub fn UInt::lxor(self : UInt, other : UInt) -> UInt = "%u32.bitxor"

///|
/// Performs a bitwise NOT operation on an unsigned 32-bit integer. Flips all
/// bits in the number (changes each 0 to 1 and each 1 to 0).
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer value on which to perform the bitwise
/// NOT operation.
///
/// Returns a new unsigned 32-bit integer where each bit is inverted from the
/// input value.
///
/// Example:
///
/// ```moonbit
///   let x = 0xFF00U // Binary: 1111_1111_0000_0000
///   inspect(x.lnot(), content="4294902015") // Binary: ...0000_0000_1111_1111
/// ```
pub fn UInt::lnot(self : UInt) -> UInt = "%u32.bitnot"

///|
/// Performs a left shift operation on an unsigned 32-bit integer. Shifts each
/// bit in the number to the left by the specified number of positions, filling
/// the rightmost positions with zeros.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be shifted.
/// * `shift` : The number of positions to shift the bits. Must be non-negative
/// and less than 32. Values outside this range are wrapped to fit within it
/// (i.e., `shift & 31`).
///
/// Returns a new `UInt` value representing the result of shifting the bits left
/// by the specified number of positions. Each position shifted multiplies the
/// number by 2.
///
/// Example:
///
/// ```moonbit
///   let x = 1U
///   inspect(x << 3, content="8") // Using the recommended operator
///   let y = 8U
///   inspect(y << 1, content="16") // Using the recommended operator
/// ```
///
#deprecated("Use infix operator `<<` instead")
#coverage.skip
pub fn UInt::lsl(self : UInt, shift : Int) -> UInt = "%u32.shl"

///|
/// Performs a left shift operation on an unsigned 32-bit integer. Shifts each
/// bit in the integer to the left by the specified number of positions, filling
/// the rightmost positions with zeros.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be shifted.
/// * `shift` : The number of positions to shift left. Must be between 0 and 31
/// inclusive. Values outside this range will be masked with `& 31`.
///
/// Returns a new `UInt` value containing the result of the left shift operation.
///
/// Example:
///
/// ```moonbit
///   let x = 1U
///   inspect(x << 3, content="8") // Binary: 1 -> 1000
/// ```
///
#deprecated("Use infix operator `<<` instead")
#coverage.skip
pub fn UInt::shl(self : UInt, shift : Int) -> UInt = "%u32.shl"

///|
/// Performs a logical right shift on an unsigned 32-bit integer. Each bit in the
/// input value is shifted right by the specified number of positions, with zeros
/// shifted in from the left. DEPRECATED: Use the `>>` operator instead.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be shifted.
/// * `shift` : The number of positions to shift right. Must be non-negative.
///
/// Returns a new `UInt` value representing the result of the logical right shift
/// operation.
///
/// Example:
///
/// ```moonbit
///   let x = 0xF0000000U
///   inspect(x >> 4, content="251658240") // Using the recommended operator
/// ```
///
#deprecated("Use infix operator `>>` instead")
#coverage.skip
pub fn UInt::lsr(self : UInt, shift : Int) -> UInt = "%u32.shr"

///|
/// Performs a logical right shift operation on an unsigned 32-bit integer by a
/// specified number of positions. All bits shifted in from the left are zeros.
///
/// Parameters:
///
/// * `number` : The unsigned 32-bit integer to be shifted.
/// * `shift` : The number of positions to shift right. Must be non-negative.
///
/// Returns a new `UInt` value that represents the result of shifting all bits in
/// `number` to the right by `shift` positions.
///
/// Example:
///
/// ```moonbit
///   let x = 0xFF000000U
///   inspect(x >> 8, content="16711680") // 0x00FF0000
/// ```
///
#deprecated("Use infix operator `>>` instead")
#coverage.skip
pub fn UInt::shr(self : UInt, shift : Int) -> UInt = "%u32.shr"

///|
/// Performs a left shift operation on an unsigned 32-bit integer. Each bit in
/// the integer is shifted left by the specified number of positions, and zeros
/// are filled in from the right.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be shifted.
/// * `shift` : The number of positions to shift. Only the least significant 5
/// bits are used, effectively making the shift count always between 0 and 31.
///
/// Returns a new unsigned 32-bit integer that is the result of shifting `self`
/// left by `shift` positions.
///
/// Example:
///
/// ```moonbit
///   let x = 1U
///   inspect(x << 3, content="8") // Binary: 1 -> 1000
///   let y = 0xFFFFFFFFU
///   inspect(y << 16, content="4294901760") // All bits after position 16 are discarded
/// ```
pub impl Shl for UInt with shl(self, shift) = "%u32.shl"

///|
/// Performs a logical right shift operation on an unsigned 32-bit integer. The
/// operation shifts all bits to the right by a specified number of positions,
/// filling the leftmost positions with zeros.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be shifted.
/// * `shift` : The number of positions to shift right. If this value is
/// negative, the behavior is undefined. Values larger than 31 are masked with `&
/// 31`.
///
/// Returns a new unsigned 32-bit integer containing the result of the right
/// shift operation.
///
/// Example:
///
/// ```moonbit
///   let x = 0xFF000000U
///   inspect(x >> 8, content="16711680") // 0x00FF0000
///   inspect(x >> 24, content="255") // 0x000000FF
///
///   let x = 0xFF000000U
///   inspect(x >> 32, content="4278190080") // Same as x >> 0 due to masking
/// ```
pub impl Shr for UInt with shr(self, shift) = "%u32.shr"

///|
/// Counts the number of leading zero bits in an unsigned 32-bit integer,
/// starting from the most significant bit.
///
/// Parameters:
///
/// * `value` : The unsigned 32-bit integer whose leading zeros are to be
/// counted.
///
/// Returns the number of consecutive zeros starting from the most significant
/// bit. For a zero value, returns 32.
///
/// Example:
///
/// ```moonbit
///   inspect(0U.clz(), content="32")
///   inspect(1U.clz(), content="31")
///   inspect(0x80000000U.clz(), content="0")
/// ```
pub fn UInt::clz(self : UInt) -> Int = "%u32.clz"

///|
/// Counts the number of trailing zero bits in an unsigned 32-bit integer,
/// starting from the least significant bit. For a zero input, returns 32.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer whose trailing zeros are to be
/// counted.
///
/// Returns the number of consecutive zeros at the least significant end of the
/// binary representation. Returns 32 if the input is zero.
///
/// Example:
///
/// ```moonbit
///   let x = 24U // Binary: ...011000
///   inspect(x.ctz(), content="3") // 3 trailing zeros
///   let y = 0U
///   inspect(y.ctz(), content="32") // All bits are zero
/// ```
pub fn UInt::ctz(self : UInt) -> Int = "%u32.ctz"

///|
/// Counts the number of 1 bits (population count) in the binary representation
/// of an unsigned 32-bit integer.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer whose bits are to be counted.
///
/// Returns an integer representing the count of set bits (1s) in the binary
/// representation.
///
/// Example:
///
/// ```moonbit
///   let x = 0xF0F0U // Binary: 1111 0000 1111 0000
///   inspect(x.popcnt(), content="8") // Has 8 bits set to 1
/// ```
pub fn UInt::popcnt(self : UInt) -> Int = "%u32.popcnt"

///|
/// Converts an unsigned 32-bit integer to an unsigned 64-bit integer by
/// zero-extending it. The resulting value preserves the original number's
/// magnitude while using 64 bits to represent it.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer (`UInt`) to be converted.
///
/// Returns an unsigned 64-bit integer (`UInt64`) representing the same numerical
/// value as the input.
///
/// Example:
///
/// ```moonbit
///   let n = 42U
///   inspect(n.to_uint64(), content="42")
///   let max = 4294967295U // Maximum value of UInt
///   inspect(max.to_uint64(), content="4294967295")
/// ```
pub fn UInt::to_uint64(self : UInt) -> UInt64 {
  UInt64::extend_uint(self)
}

///|
/// Converts an unsigned 32-bit integer to a byte by taking its least significant
/// 8 bits. Any bits beyond the first 8 bits are truncated.
///
/// Parameters:
///
/// * `self` : The unsigned 32-bit integer to be converted. Only the least
/// significant 8 bits will be used.
///
/// Returns a byte containing the least significant 8 bits of the input integer.
///
/// Example:
///
/// ```moonbit
///   let n = 258U // In binary: 100000010
///   inspect(n.to_byte(), content="b'\\x02'") // Only keeps 00000010
///   let big = 4294967295U // Maximum value of UInt
///   inspect(big.to_byte(), content="b'\\xFF'") // Only keeps 11111111
/// ```
pub fn UInt::to_byte(self : UInt) -> Byte {
  self.reinterpret_as_int().to_byte()
}

///|
/// Converts an unsigned 32-bit integer to a double-precision floating-point
/// number. Since the range of unsigned 32-bit integers is smaller than what can
/// be precisely represented by a double-precision floating-point number, this
/// conversion is guaranteed to be exact.
///
/// Parameters:
///
/// * `value` : The unsigned 32-bit integer to be converted.
///
/// Returns a double-precision floating-point number that exactly represents the
/// input value.
///
/// Example:
///
/// ```moonbit
///   let n = 42U
///   inspect(n.to_double(), content="42")
///   let max = 4294967295U // maximum value of UInt
///   inspect(max.to_double(), content="4294967295")
/// ```
pub fn UInt::to_double(self : UInt) -> Double = "%u32.to_f64"

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
/// ```moonbit
///   let f = 3.14.to_float()
///   inspect((-f).to_double(), content="-3.140000104904175")
///   let zero = 0.0.to_float()
///   inspect((-zero).to_double(), content="0")
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
/// ```moonbit
///   let a = 3.14.to_float()
///   let b = 2.86.to_float()
///   let sum = a + b
///   inspect(sum.to_double(), content="6")
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
/// ```moonbit
///   let x = 3.14.to_float()
///   let y = 1.0.to_float()
///   let result = x - y
///   inspect(result.to_double(), content="2.140000104904175")
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
/// ```moonbit
///   let x = Int::to_float(2)
///   let y = Int::to_float(3)
///   let z = x * y
///   inspect(z.to_double(), content="6")
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
/// ```moonbit
///   let a = 6.0.to_float()
///   let b = 2.0.to_float()
///   let result = (a / b).to_double()
///   inspect(result, content="3")
///   inspect((0.0.to_float() / 0.0.to_float()).to_double(), content="NaN")
/// ```
pub impl Div for Float with div(self, other) = "%f32.div"

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
/// ```moonbit
///   let x = 16.0.to_float()
///   let root = x.sqrt()
///   inspect(root.to_double(), content="4")
///   let neg = (-4.0).to_float()
///   let neg_root = neg.sqrt()
///   inspect(neg_root.to_double(), content="NaN")
/// ```
pub fn Float::sqrt(self : Float) -> Float = "%f32.sqrt"

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
/// ```moonbit
///   let x = 3.14
///   let y = 3.14
///   let z = 0.0 / 0.0 // NaN
///   inspect(x == y, content="true")
///   inspect(z == z, content="false") // NaN is not equal to itself
/// ```
pub impl Eq for Float with equal(self : Float, other : Float) -> Bool = "%f32.eq"

///|
/// Tests if two single-precision floating-point numbers are not equal. This
/// operation follows IEEE 754 rules for floating-point comparison, including
/// special handling of NaN values.
///
/// Parameters:
///
/// * `self` : The first floating-point number to compare.
/// * `other` : The second floating-point number to compare.
///
/// Returns `true` if the two floating-point numbers are not equal, `false` if
/// they are equal. Note that if either operand is NaN, the result is `true`.
///
/// Example:
///
/// ```moonbit
///   let x = 1.0.to_float()
///   let y = 2.0.to_float()
///   let nan = (0.0 / 0.0).to_float()
///   inspect(x != y, content="true")
///   inspect(x != x, content="false")
///   inspect(nan != nan, content="true") // NaN is not equal to itself
/// ```
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
/// ```moonbit
///   let a = 3.14
///   let b = 2.718
///   inspect(a.compare(b), content="1") // 3.14 > 2.718
///   inspect(b.compare(a), content="-1") // 2.718 < 3.14
///   inspect(a.compare(a), content="0") // 3.14 = 3.14
/// ```
pub impl Compare for Float with compare(self, other) = "%f32.compare"

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
/// ```moonbit
///   let f = 3.14.to_float()
///   inspect(f.to_double(), content="3.140000104904175")
/// ```
pub fn Float::to_double(self : Float) -> Double = "%f32.to_f64"

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
/// ```moonbit
///   let f = 1.0.to_float()
///   // IEEE 754 representation of 1.0 is 0x3F800000
///   inspect(f.reinterpret_as_int(), content="1065353216")
/// ```
pub fn Float::reinterpret_as_int(self : Float) -> Int = "%f32.to_i32_reinterpret"

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
/// ```moonbit
///   let x : Float = 1.0
///   inspect(x.reinterpret_as_uint(), content="1065353216") // Decimal representation of 0x3F800000
/// ```
pub fn Float::reinterpret_as_uint(self : Float) -> UInt = "%f32.to_i32_reinterpret"

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
/// ```moonbit
///   let n = 42
///   let f = n.to_float()
///   // Convert back to double for comparison since Float doesn't implement Show
///   inspect(f.to_double(), content="42")
/// ```
pub fn Int::to_float(self : Int) -> Float = "%i32.to_f32"

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
/// ```moonbit
///   // 0x3F800000 represents 1.0 in IEEE 754 single-precision format
///   let n = 1065353216 // 0x3F800000
///   inspect(n.reinterpret_as_float().to_double(), content="1")
/// ```
pub fn Int::reinterpret_as_float(self : Int) -> Float = "%i32.to_f32_reinterpret"

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
/// ```moonbit
///   let n = 0x3F800000U // Bit pattern for 1.0f
///   inspect(n.reinterpret_as_float().to_double(), content="1")
/// ```
pub fn UInt::reinterpret_as_float(self : UInt) -> Float = "%i32.to_f32_reinterpret"

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
/// ```moonbit
///   let b = b'\xFF' // 255 in decimal
///   let f = b.to_float()
///   // Convert to double for comparison since Float doesn't implement Show
///   inspect(f.to_double(), content="255")
/// ```
pub fn Byte::to_float(self : Byte) -> Float = "%byte.to_f32"

///|
/// TODO: use intrinsics implement this
pub fn Byte::to_double(self : Byte) -> Double {
  self.to_int().to_double()
}

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
/// ```moonbit
///   let d = 3.14159265359
///   inspect(d.to_float().to_double(), content="3.1415927410125732") // Note the loss of precision
/// ```
pub fn Double::to_float(self : Double) -> Float = "%f64.to_f32"

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
/// ```moonbit
///   let n = 42U
///   inspect(n.to_float().to_double(), content="42")
///   let big = 16777216U // 2^24
///   inspect(big.to_float().to_double(), content="16777216") // Last precisely representable integer
/// ```
pub fn UInt::to_float(self : UInt) -> Float = "%u32.to_f32"

///|
/// Converts a 16-bit signed integer to a 32-bit signed integer by sign
/// extension.
///
/// Parameters:
///
/// * `value` : The 16-bit signed integer to be converted.
///
/// Returns a 32-bit signed integer that has the same value as the input.
///
/// Example:
///
/// ```moonbit
///   let n = Int::to_int16(42)
///   inspect(n.to_int(), content="42")
///   let neg = Int::to_int16(-42)
///   inspect(neg.to_int(), content="-42")
/// ```
pub fn Int16::to_int(self : Int16) -> Int = "%i16_to_i32"

///|
/// Converts a 16-bit signed integer to a byte by truncating its value to fit
/// within the byte range (0 to 255). Only the least significant 8 bits of the
/// integer are retained.
///
/// Parameters:
///
/// * `value` : The 16-bit signed integer to be converted to a byte.
///
/// Returns a byte containing the least significant 8 bits of the input value.
///
/// Example:
///
/// ```moonbit
///   let x = Int::to_int16(258) // In binary: 0000_0001_0000_0010
///   inspect(x.to_byte(), content="b'\\x02'") // Only keeps 0000_0010
/// ```
pub fn Int16::to_byte(self : Int16) -> Byte = "%i16_to_byte"

///|
pub fn Int::to_int16(self : Int) -> Int16 = "%i32_to_i16"

///|
/// Converts a byte value to a 16-bit signed integer. The byte value is
/// sign-extended to 16 bits during the conversion.
///
/// Parameters:
///
/// * `byte` : The byte value to be converted to an `Int16`.
///
/// Returns a 16-bit signed integer representing the same value as the input
/// byte.
///
/// Example:
///
/// ```moonbit
///   let b = b'\xFF' // -1 as a signed byte
///   inspect(b.to_int16(), content="255") // Sign is preserved
///   let p = b'\x7F' // 127 as a signed byte
///   inspect(p.to_int16(), content="127")
/// ```
pub fn Byte::to_int16(self : Byte) -> Int16 = "%byte_to_i16"

///|
/// Converts an unsigned 16-bit integer to a 32-bit signed integer. The value is
/// zero-extended to fill the higher bits.
///
/// Parameters:
///
/// * `value` : The unsigned 16-bit integer to be converted.
///
/// Returns a 32-bit signed integer. Since the input value is always non-negative
/// and less than 65536, the conversion never results in overflow.
///
/// Example:
///
/// ```moonbit
///   let x = Int::to_uint16(42)
///   inspect(x.to_int(), content="42")
///   let max = Int::to_uint16(65535) // maximum value of UInt16
///   inspect(max.to_int(), content="65535")
/// ```
pub fn UInt16::to_int(self : UInt16) -> Int = "%u16_to_i32"

///|
/// Converts a 16-bit unsigned integer to an 8-bit byte by truncating the higher
/// bits.
///
/// Parameters:
///
/// * `value` : The 16-bit unsigned integer to be converted.
///
/// Returns a byte containing the least significant 8 bits of the input value.
///
/// Example:
///
/// ```moonbit
///   let x = Int::to_uint16(258) // Binary: 0000_0001_0000_0010
///   inspect(x.to_byte(), content="b'\\x02'") // Only keeps 0000_0010
/// ```
pub fn UInt16::to_byte(self : UInt16) -> Byte = "%u16_to_byte"

///|
/// Converts a 32-bit signed integer to a 16-bit unsigned integer by truncating
/// its value to fit within the range of 0 to 65535.
///
/// Parameters:
///
/// * `integer` : The 32-bit signed integer to be converted. Values outside the
/// range of UInt16 will be truncated to fit.
///
/// Returns a 16-bit unsigned integer containing the lower 16 bits of the input
/// value.
///
/// Example:
///
/// ```moonbit
///   let n = 42
///   inspect(n.to_uint16(), content="42")
///   let neg = -1
///   inspect(neg.to_uint16(), content="65535") // -1 becomes max value of UInt16
///   let large = 65536
///   inspect(large.to_uint16(), content="0") // Values wrap around
/// ```
pub fn Int::to_uint16(self : Int) -> UInt16 = "%i32_to_u16"

///|
/// Converts a byte value to a 16-bit unsigned integer by zero-extending it.
///
/// Parameters:
///
/// * `byte` : The byte value to be converted.
///
/// Returns a 16-bit unsigned integer (`UInt16`) representing the same value as
/// the input byte.
///
/// Example:
///
/// ```moonbit
///   let b = b'\xFF' // byte with value 255
///   inspect(b.to_uint16(), content="255")
///   let zero = b'\x00'
///   inspect(zero.to_uint16(), content="0")
/// ```
pub fn Byte::to_uint16(self : Byte) -> UInt16 = "%byte_to_u16"
