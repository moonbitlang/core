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
/// Arbitrary-precision integer backed by JavaScript `BigInt`.
///
/// # Example
/// ```mbt check
/// test {
///   let n : BigInt = 123N
///   inspect(n, content="123")
/// }
/// ```
type BigInt

///|
let zero = 0N

///|
/// Parses a decimal string into a `BigInt`.
///
/// The input may include a leading minus sign.
///
/// # Example
/// ```mbt check
/// test {
///   let pos = @bigint.BigInt::from_string("12345")
///   let neg = @bigint.BigInt::from_string("-12345")
///   inspect(pos, content="12345")
///   inspect(neg, content="-12345")
/// }
/// ```
pub fn BigInt::from_string(str : String) -> BigInt {
  if str.length() == 0 {
    abort("empty string")
  }
  BigInt::js_from_string(str)
}

///|
/// JS binding for constructing a `BigInt` from a string.
extern "js" fn BigInt::js_from_string(str : String) -> BigInt =
  #|(x) => BigInt(x)

///|
/// Formats a `BigInt` using its decimal string representation.
///
/// # Example
/// ```mbt check
/// test {
///   let n = 12345678901234567890N
///   inspect(n, content="12345678901234567890")
/// }
/// ```
pub impl Show for BigInt with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Converts a `BigInt` to its decimal string representation.
///
/// # Example
/// ```mbt check
/// test {
///   let n = 12345678901234567890N
///   inspect(n.to_string(), content="12345678901234567890")
///   let neg = -42N
///   inspect(neg.to_string(), content="-42")
/// }
/// ```
pub extern "js" fn BigInt::to_string(self : BigInt) -> String =
  #|(x) => String(x)

///|
/// Parses a hexadecimal string into a `BigInt`.
///
/// The input may include a leading minus sign.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@bigint.BigInt::from_hex("ff"), content="255")
///   inspect(@bigint.BigInt::from_hex("-ff"), content="-255")
/// }
/// ```
pub extern "js" fn BigInt::from_hex(str : String) -> BigInt =
  #|(x) => x.startsWith('-') ? -BigInt(`0x${x.slice(1)}`) : BigInt(`0x${x}`)

///|
/// Converts a `BigInt` to a hexadecimal string without a `0x` prefix.
///
/// # Example
/// ```mbt check
/// test {
///   let pos = @bigint.BigInt::from_string("255")
///   let neg = @bigint.BigInt::from_string("-255")
///   inspect(pos.to_hex(), content="FF")
///   inspect(neg.to_hex(), content="-FF")
///   inspect(pos.to_hex(uppercase=false), content="ff")
/// }
/// ```
pub extern "js" fn BigInt::to_hex(
  self : BigInt,
  uppercase? : Bool = true,
) -> String =
  #|(x, uppercase) => {
  #|  const r = x.toString(16);
  #|  return uppercase ? r.toUpperCase() : r;
  #|}

///|
/// Formats a byte as a two-digit lowercase hex string.
extern "js" fn hex2(b : Byte) -> String =
  #|(x) => x.toString(16).padStart(2, '0')

///|
/// Converts a big-endian byte sequence to a `BigInt` with an optional sign.
///
/// # Example
/// ```mbt check
/// test {
///   let bytes = b"\x01\x02\x03"
///   let positive = @bigint.BigInt::from_octets(bytes)
///   let negative = @bigint.BigInt::from_octets(bytes, signum=-1)
///   inspect(positive, content="66051")
///   inspect(negative, content="-66051")
/// }
/// ```
pub fn BigInt::from_octets(octets : Bytes, signum? : Int = 1) -> BigInt {
  if signum < 0 {
    return -1N * BigInt::from_octets(octets, signum=1)
  }
  if signum == 0 {
    return 0N
  }
  let str = StringBuilder::new()
  str.write_string("0x")
  for octet in octets {
    str.write_string(hex2(octet))
  }
  BigInt::from_string(str.to_string())
}

///|
/// Converts a non-negative `BigInt` to a big-endian byte sequence.
///
/// When `length` is provided, the result is padded with leading zeros up to
/// that length.
///
/// # Example
/// ```mbt check
/// test {
///   let n = @bigint.BigInt::from_hex("abcdef")
///   inspect(n.to_octets(length=4), content="b\"\\x00\\xab\\xcd\\xef\"")
///   let zero = 0N
///   inspect(zero.to_octets(), content="b\"\\x00\"")
/// }
/// ```
pub fn BigInt::to_octets(self : BigInt, length? : Int) -> Bytes {
  if self < 0 {
    abort("negative BigInt")
  }
  if self == 0 {
    return match length {
      Some(len) => Bytes::make(len, 0)
      None => [0]
    }
  }
  let buf = []
  loop self {
    v =>
      if v > 0 {
        buf.push(v.to_byte())
        continue v >> 8
      }
  }
  let buf_len = buf.length()
  match length {
    Some(len) => {
      if len <= 0 {
        abort("negative length")
      }
      if len > buf_len {
        Bytes::makei(len, i => {
          let padding = len - buf_len
          if i < padding {
            0
          } else {
            buf[buf_len - (i - padding) - 1]
          }
        })
      } else {
        Bytes::makei(buf_len, i => buf[buf_len - i - 1])
      }
    }
    None => Bytes::makei(buf_len, i => buf[buf_len - i - 1])
  }
}

///|
/// JS comparison helper returning -1, 0, or 1.
extern "js" fn BigInt::compare(self : BigInt, other : BigInt) -> Int =
  #|(x, y) => x < y ? -1 : x > y ? 1 : 0

///|
/// Compares two `BigInt` values and returns their relative order.
///
/// # Example
/// ```mbt check
/// test {
///   let a = @bigint.BigInt::from_string("42")
///   let b = @bigint.BigInt::from_string("24")
///   inspect(a.compare(b), content="1")
///   inspect(b.compare(a), content="-1")
///   inspect(a.compare(a), content="0")
/// }
/// ```
pub impl Compare for BigInt with compare(self, other) {
  self.compare(other)
}

///|
/// JS strict equality helper for `BigInt`.
extern "js" fn BigInt::equal(self : BigInt, other : BigInt) -> Bool =
  #|(x, y) => x === y

///|
/// Tests equality between two `BigInt` values.
///
/// # Example
/// ```mbt check
/// test {
///   let a = 123N
///   let b = 123N
///   let c = -123N
///   inspect(a == b, content="true")
///   inspect(a == c, content="false")
/// }
/// ```
pub impl Eq for BigInt with equal(self, other) {
  self.equal(other)
}

///|
/// Converts a 32-bit signed integer to a `BigInt`.
///
/// # Example
/// ```mbt check
/// test {
///   let big = @bigint.BigInt::from_int(42)
///   inspect(big, content="42")
/// }
/// ```
pub extern "js" fn BigInt::from_int(x : Int) -> BigInt =
  #|(x) => BigInt(x)

///|
/// Converts a 32-bit unsigned integer to a `BigInt`.
///
/// # Example
/// ```mbt check
/// test {
///   let big = @bigint.BigInt::from_uint(42U)
///   inspect(big, content="42")
/// }
/// ```
pub extern "js" fn BigInt::from_uint(x : UInt) -> BigInt =
  #|(x) => BigInt(x >>> 0)

///|
/// Converts a 64-bit signed integer to a `BigInt`.
///
/// # Example
/// ```mbt check
/// test {
///   let big = @bigint.BigInt::from_int64(9223372036854775807L)
///   inspect(big, content="9223372036854775807")
/// }
/// ```
pub extern "js" fn BigInt::from_int64(x : Int64) -> BigInt =
  #|(x) => BigInt(x.hi) * 0x100000000n + BigInt(x.lo >>> 0)

///|
/// Converts a 64-bit unsigned integer to a `BigInt`.
///
/// # Example
/// ```mbt check
/// test {
///   let big = @bigint.BigInt::from_uint64(12345678901234567890UL)
///   inspect(big, content="12345678901234567890")
/// }
/// ```
pub extern "js" fn BigInt::from_uint64(x : UInt64) -> BigInt =
  #|(x) => BigInt(x.hi >>> 0) * 0x100000000n + BigInt(x.lo >>> 0)

///|
/// Returns true if the `BigInt` is zero.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(0N.is_zero(), content="true")
///   inspect(1N.is_zero(), content="false")
/// }
/// ```
pub extern "js" fn BigInt::is_zero(self : BigInt) -> Bool =
  #|(x) => x === 0n

///|
/// JS negation operator binding.
extern "js" fn BigInt::op_neg_ffi(self : BigInt) -> BigInt =
  #|(x) => -x

///|
/// Negates a `BigInt`.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(-42N, content="-42")
///   inspect(-(-42N), content="42")
/// }
/// ```
pub impl Neg for BigInt with neg(self) {
  self.op_neg_ffi()
}

///|
/// JS addition operator binding.
extern "js" fn BigInt::op_add_ffi(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x + y

///|
/// Adds two `BigInt` values.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(41N + 1N, content="42")
/// }
/// ```
pub impl Add for BigInt with add(self, other) {
  self.op_add_ffi(other)
}

///|
/// JS subtraction operator binding.
extern "js" fn BigInt::op_sub_ffi(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x - y

///|
/// Subtracts one `BigInt` from another.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(10N - 3N, content="7")
/// }
/// ```
pub impl Sub for BigInt with sub(self, other) {
  self.op_sub_ffi(other)
}

///|
/// JS multiplication operator binding.
extern "js" fn BigInt::op_mul_ffi(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x * y

///|
/// Multiplies two `BigInt` values.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(6N * 7N, content="42")
/// }
/// ```
pub impl Mul for BigInt with mul(self, other) {
  self.op_mul_ffi(other)
}

///|
/// JS division operator binding.
extern "js" fn BigInt::op_div_ffi(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x / y

///|
/// Divides one `BigInt` by another.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(20N / 5N, content="4")
/// }
/// ```
pub impl Div for BigInt with div(self, other) {
  self.op_div_ffi(other)
}

///|
/// JS remainder operator binding.
extern "js" fn BigInt::op_mod_ffi(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x % y

///|
/// Computes the remainder of dividing one `BigInt` by another.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(20N % 6N, content="2")
/// }
/// ```
pub impl Mod for BigInt with mod(self, other) {
  self.op_mod_ffi(other)
}

///|
/// JS modular exponentiation helper.
extern "js" fn BigInt::modpow_ffi(
  self : BigInt,
  exponent : BigInt,
  modulus : BigInt,
) -> BigInt =
  #|(x, y, z) => {
  #|  if (z === 1n) return 0n;
  #|  let result = 1n;
  #|  x = x % z;
  #|  while (y > 0n) {
  #|    if (y & 1n) {
  #|       result = (result * x) % z;
  #|    }
  #|    y >>= 1n;
  #|    x = (x * x) % z;
  #|  }
  #|  return result;
  #|}

///|
/// JS exponentiation helper.
extern "js" fn BigInt::pow_ffi(self : BigInt, exponent : BigInt) -> BigInt =
  #|(x, y) => x ** y

///|
/// Raises a `BigInt` to a non-negative exponent with an optional modulus.
///
/// # Example
/// ```mbt check
/// test {
///   let base = 3N
///   let exp = 4N
///   inspect(base.pow(exp), content="81")
///   inspect(base.pow(exp, modulus=10N), content="1")
/// }
/// ```
pub fn BigInt::pow(
  self : BigInt,
  exponent : BigInt,
  modulus? : BigInt,
) -> BigInt {
  if exponent < 0 {
    abort("negative exponent")
  }
  match modulus {
    Some(modulus) =>
      if modulus <= 0 {
        abort("non-positive modulus")
      } else {
        self.modpow_ffi(exponent, modulus)
      }
    None => self.pow_ffi(exponent)
  }
}

///|
/// Converts a `BigInt` to an unsigned byte.
extern "js" fn BigInt::to_byte(self : BigInt) -> Byte =
  #|(x) => Number(BigInt.asUintN(8, x)) | 0

///|
/// Shifts a `BigInt` left by the specified number of bits.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(5N << 2, content="20")
/// }
/// ```
pub impl Shl for BigInt with shl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  self.js_shl(n)
}

///|
/// Shifts a `BigInt` right by the specified number of bits.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(16N >> 2, content="4")
/// }
/// ```
pub impl Shr for BigInt with shr(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  self.js_shr(n)
}

///|
/// JS left shift helper.
extern "js" fn BigInt::js_shl(self : BigInt, other : Int) -> BigInt =
  #|(x, y) => x << BigInt(y)

///|
/// JS right shift helper.
extern "js" fn BigInt::js_shr(self : BigInt, other : Int) -> BigInt =
  #|(x, y) => x >> BigInt(y)

///|
/// JS bitwise AND helper.
extern "js" fn BigInt::js_land(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x & y

///|
/// Performs a bitwise AND between two `BigInt` values.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(6N & 3N, content="2")
/// }
/// ```
pub impl BitAnd for BigInt with land(self, other) {
  self.js_land(other)
}

///|
/// JS bitwise OR helper.
extern "js" fn BigInt::js_lor(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x | y

///|
/// Performs a bitwise OR operation between two arbitrary-precision integers,
/// following two's complement representation for negative numbers.
///
/// Parameters:
///
/// * `self` : The first arbitrary-precision integer operand.
/// * `other` : The second arbitrary-precision integer operand.
///
/// Returns a new `BigInt` representing the result of the bitwise OR operation.
///
/// Example:
///
/// ```mbt check
/// test {
///   let a = @bigint.BigInt::from_string("42")
///   let b = @bigint.BigInt::from_string("-12")
///   inspect(a | b, content="-2")
///   let c = @bigint.BigInt::from_string("-8")
///   let d = @bigint.BigInt::from_string("-4")
///   inspect(c | d, content="-4")
/// }
/// ```
///
pub impl BitOr for BigInt with lor(self, other) {
  self.js_lor(other)
}

///|
/// JS bitwise XOR helper.
extern "js" fn BigInt::js_lxor(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x ^ y

///|
/// Performs a bitwise XOR (exclusive OR) operation between two
/// arbitrary-precision integers, treating them as two's complement binary
/// numbers.
///
/// The XOR operation compares each bit position of both operands and returns 1
/// if the bits are different, 0 if they are the same. For negative numbers, the
/// operation is performed using two's complement representation.
///
/// Parameters:
///
/// * `self` : The first `BigInt` operand for the XOR operation.
/// * `other` : The second `BigInt` operand for the XOR operation.
///
/// Returns a new `BigInt` value representing the bitwise XOR of the two
/// operands.
///
/// Example:
///
/// ```mbt check
/// test {
///   let a = @bigint.BigInt::from_string("42") // 0b101010
///   let b = @bigint.BigInt::from_string("25") // 0b011001
///   inspect(a ^ b, content="51") // 0b110011
///   let a = @bigint.BigInt::from_string("42")
///   let b = @bigint.BigInt::from_string("-7")
///   inspect(a ^ b, content="-45")
///   let a = @bigint.BigInt::from_string("42")
///   inspect(a ^ a, content="0") // XOR with self gives 0
/// }
/// ```
///
pub impl BitXOr for BigInt with lxor(self, other) {
  self.js_lxor(other)
}

///|
/// Converts a `BigInt` to an unsigned 32-bit integer (`UInt`).
///
/// Parameters:
///
/// * `self` : The `BigInt` value to be converted.
///
/// Returns a `UInt` value representing the lower 32 bits of the input `BigInt`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = 42N
///   inspect(n.to_uint(), content="42")
///   let neg = -1N
///   inspect(neg.to_uint(), content="4294967295") // 2^32 - 1
/// }
/// ```
pub extern "js" fn BigInt::to_uint(self : BigInt) -> UInt =
  #|(x) => Number(BigInt.asUintN(32, x)) | 0

///|
/// Converts a `BigInt` to a 32-bit signed integer (`Int`).
///
/// Parameters:
///
/// * `self` : The `BigInt` value to be converted.
///
/// Returns a 32-bit signed integer representing the lower 32 bits of the input
/// `BigInt`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let big = 2147483648N // 2^31
///   inspect(big.to_int(), content="-2147483648") // Overflow to Int.min_value
/// }
/// ```
pub extern "js" fn BigInt::to_int(self : BigInt) -> Int =
  #|(x) => Number(BigInt.asIntN(32, x))

///|
/// Converts a `BigInt` to an unsigned 64-bit integer (`UInt64`).
///
/// Parameters:
///
/// * `self` : The `BigInt` value to be converted.
///
/// Returns a `UInt64` value representing the lower 64 bits of the input
/// `BigInt`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = 12345678901234567890N
///   inspect(n.to_uint64(), content="12345678901234567890")
///   let neg = -1N
///   inspect(neg.to_uint64(), content="18446744073709551615") // 2^64 - 1
/// }
/// ```
pub fn BigInt::to_uint64(self : BigInt) -> UInt64 {
  let hi = (self >> 32).to_uint()
  let lo = self.to_uint()
  (hi.to_uint64() << 32) | lo.to_uint64()
}

///|
/// Converts a `BigInt` to a signed 64-bit integer (`Int64`).
///
/// Parameters:
///
/// * `value` : The `BigInt` value to be converted.
///
/// Returns a 64-bit signed integer (`Int64`) representing the lower 64 bits of
/// the input `BigInt`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let big = 9223372036854775807N // max value of Int64
///   inspect(big.to_int64(), content="9223372036854775807")
///   let bigger = big + 1
///   inspect(bigger.to_int64(), content="-9223372036854775808") // Overflow to Int64.min_value
/// }
/// ```
pub fn BigInt::to_int64(self : BigInt) -> Int64 {
  let hi = (self >> 32).to_uint()
  let lo = self.to_uint()
  (hi.to_int64() << 32) | lo.to_int64()
}

///|
/// Returns the number of bits required to represent a `BigInt` value in two's
/// complement format, excluding the sign bit.
///
/// Parameters:
///
/// * `self` : The `BigInt` value whose bit length is to be calculated.
///
/// Example:
///
/// ```mbt check
/// test {
///   let pos = 16N // 10000
///   inspect(pos.bit_length(), content="5")
///   let neg = -16N // 
///   inspect(neg.bit_length(), content="4")
///   let zero = 0N
///   inspect(zero.bit_length(), content="0")
/// }
/// ```
pub extern "js" fn BigInt::bit_length(self : BigInt) -> Int =
  #|(n) => {
  #|  if (n >= 0) {
  #|    return n === 0n ? 0 : n.toString(2).length;
  #|  } else {
  #|    const absN = -n;
  #|    const absMinus1 = absN - 1n;
  #|    return absMinus1 === 0n ? 0 : absMinus1.toString(2).length;
  #|  }
  #|}

///|
/// Returns the number of trailing zero bits in the binary representation of
/// the absolute value of this BigInt.
///
/// For zero, it returns 0.
///
/// Example:
/// ```mbt check
/// test {
///   inspect(8N.ctz(), content="3") // 0b1000
///   inspect(12N.ctz(), content="2") // 0b1100
///   inspect(0N.ctz(), content="0")
/// }
/// ```
pub extern "js" fn BigInt::ctz(self : BigInt) -> Int =
  #|(n) => {
  #|  if (n === 0n) return 0;
  #|  let absN = n < 0n ? -n : n;
  #|  let count = 0;
  #|  while ((absN & 1n) === 0n) {
  #|    absN >>= 1n;
  #|    count++;
  #|  }
  #|  return count;
  #|}

///|
/// Returns whether `x` fits into a 32-bit signed integer.
extern "js" fn can_convert_to_int(x : BigInt) -> Bool =
  #|(x) => x >= -(2n ** 31n) && x < 2n ** 31n

///|
/// Returns whether `x` fits into a 64-bit signed integer.
extern "js" fn can_convert_to_int64(x : BigInt) -> Bool =
  #|(x) => x >= -(2n ** 63n) && x < 2n ** 63n

///|
/// Returns true when `x` is negative.
extern "js" fn is_neg(x : BigInt) -> Bool =
  #|(x) => x < 0n

///|
/// Returns the absolute value limbs from least significant to most significant.
fn BigInt::limbs(self : Self) -> Array[UInt] {
  guard !self.is_zero() else { [0] }
  let result = []
  for n = self * BigInt::from_int(self.signum()); n > 0; n = n >> 32 {
    let limb = n.to_uint()
    result.push(limb)
  }
  result
}
