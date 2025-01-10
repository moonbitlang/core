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
type BigInt

///|
pub fn BigInt::from_string(str : String) -> BigInt {
  if str.length() == 0 {
    abort("empty string")
  }
  BigInt::js_from_string(str)
}

///|
extern "js" fn BigInt::js_from_string(str : String) -> BigInt =
  #|(x) => BigInt(x)

///|
pub impl Show for BigInt with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub extern "js" fn to_string(self : BigInt) -> String =
  #|(x) => String(x)

///|
pub extern "js" fn BigInt::from_hex(str : String) -> BigInt =
  #|(x) => x.startsWith('-') ? -BigInt(`0x${x.slice(1)}`) : BigInt(`0x${x}`)

///|
pub extern "js" fn to_hex(self : BigInt, uppercase~ : Bool = true) -> String =
  #|(x, uppercase) => {
  #|  const r = x.toString(16);
  #|  return uppercase ? r.toUpperCase() : r;
  #|}

///|
extern "js" fn hex2(b : Byte) -> String =
  #|(x) => x.toString(16).padStart(2, '0')

///|
pub fn BigInt::from_octets(octets : Bytes, signum~ : Int = 1) -> BigInt {
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
pub fn to_octets(self : BigInt, length? : Int) -> Bytes {
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
        Bytes::makei(len, fn(i) {
          let padding = len - buf_len
          if i < padding {
            0
          } else {
            buf[buf_len - (i - padding) - 1]
          }
        })
      } else {
        Bytes::makei(buf_len, fn(i) { buf[buf_len - i - 1] })
      }
    }
    None => Bytes::makei(buf_len, fn(i) { buf[buf_len - i - 1] })
  }
}

///|
pub extern "js" fn BigInt::compare(self : BigInt, other : BigInt) -> Int =
  #|(x, y) => x < y ? -1 : x > y ? 1 : 0

///|
pub extern "js" fn BigInt::op_equal(self : BigInt, other : BigInt) -> Bool =
  #|(x, y) => x === y

///|
pub extern "js" fn BigInt::from_int(x : Int) -> BigInt =
  #|(x) => BigInt(x)

///|
pub extern "js" fn BigInt::from_uint(x : UInt) -> BigInt =
  #|(x) => BigInt(x >>> 0)

///|
pub extern "js" fn BigInt::from_int64(x : Int64) -> BigInt =
  #|(x) => BigInt(x.hi) * 0x100000000n + BigInt(x.lo >>> 0)

///|
pub extern "js" fn BigInt::from_uint64(x : UInt64) -> BigInt =
  #|(x) => BigInt(x.hi >>> 0) * 0x100000000n + BigInt(x.lo >>> 0)

///|
pub extern "js" fn BigInt::is_zero(self : BigInt) -> Bool =
  #|(x) => x === 0n

///|
pub extern "js" fn BigInt::op_neg(self : BigInt) -> BigInt =
  #|(x) => -x

///|
pub extern "js" fn BigInt::op_add(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x + y

///|
pub extern "js" fn BigInt::op_sub(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x - y

///|
pub extern "js" fn BigInt::op_mul(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x * y

///|
pub extern "js" fn BigInt::op_div(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x / y

///|
pub extern "js" fn BigInt::op_mod(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x % y

///|
extern "js" fn modpow_ffi(
  self : BigInt,
  exponent : BigInt,
  modulus : BigInt
) -> BigInt =
  #|(x, y, z) => x ** y % z

///|
extern "js" fn pow_ffi(self : BigInt, exponent : BigInt) -> BigInt =
  #|(x, y) => x ** y

///|
pub fn BigInt::pow(
  self : BigInt,
  exponent : BigInt,
  modulus? : BigInt
) -> BigInt {
  if exponent < 0 {
    abort("negative exponent")
  }
  match modulus {
    Some(modulus) =>
      if modulus <= 0 {
        abort("non-positive modulus")
      } else {
        modpow_ffi(self, exponent, modulus)
      }
    None => pow_ffi(self, exponent)
  }
}

///|
extern "js" fn BigInt::to_byte(self : BigInt) -> Byte =
  #|(x) => Number(BigInt.asUintN(8, x)) | 0

///|
pub fn BigInt::op_shl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  self.js_shl(n)
}

///|
pub fn BigInt::op_shr(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  self.js_shr(n)
}

///|
extern "js" fn js_shl(self : BigInt, other : Int) -> BigInt =
  #|(x, y) => x << BigInt(y)

///|
extern "js" fn js_shr(self : BigInt, other : Int) -> BigInt =
  #|(x, y) => x >> BigInt(y)

///|
pub extern "js" fn land(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x & y

///|
pub extern "js" fn lor(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x | y

///|
pub extern "js" fn lxor(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x ^ y

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
/// ```moonbit
/// test "BigInt::to_uint" {
///   let n = 42N
///   inspect!(n.to_uint(), content="42")
///   let neg = -1N
///   inspect!(neg.to_uint(), content="4294967295") // 2^32 - 1
/// }
/// ```
pub extern "js" fn BigInt::to_uint(self : BigInt) -> UInt =
  #|(x) => Number(BigInt.asUintN(32, x))

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
/// ```moonbit
/// test "BigInt::to_int" {
///   let big = 2147483648N // 2^31
///   inspect!(big.to_int(), content="-2147483648") // Overflow to Int.min_value
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
/// ```moonbit
/// test "BigInt::to_uint64" {
///   let n = 12345678901234567890N
///   inspect!(n.to_uint64(), content="12345678901234567890")
///   let neg = -1N
///   inspect!(neg.to_uint64(), content="18446744073709551615") // 2^64 - 1
/// }
/// ```
pub fn BigInt::to_uint64(self : BigInt) -> UInt64 {
  let hi = (self >> 32).to_uint().reinterpret_as_int()
  let lo = self.to_uint().reinterpret_as_int()
  MyInt64::{ hi, lo }.to_uint64()
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
/// ```moonbit
/// test "BigInt::to_int64" {
///   let big = 9223372036854775807N // max value of Int64
///   inspect!(big.to_int64(), content="9223372036854775807")
///   let bigger = big + 1
///   inspect!(bigger.to_int64(), content="-9223372036854775808") // Overflow to Int64.min_value
/// }
/// ```
pub fn BigInt::to_int64(self : BigInt) -> Int64 {
  let hi = (self >> 32).to_int()
  let lo = self.to_uint().reinterpret_as_int()
  MyInt64::{ hi, lo }.to_int64()
}
