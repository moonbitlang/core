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
/// The largest representable `Int16` value.
///
/// # Example
/// ```mbt check
/// test "int16 max_value" {
///   inspect(@int16.max_value, content="32767")
/// }
/// ```
pub let max_value : Int16 = 32767

///|
/// The smallest representable `Int16` value.
///
/// # Example
/// ```mbt check
/// test "int16 min_value" {
///   inspect(@int16.min_value, content="-32768")
/// }
/// ```
pub let min_value : Int16 = -32768

///|
/// Adds two `Int16` values with wrapping semantics.
///
/// # Example
/// ```mbt check
/// test "int16 add" {
///   let a : Int16 = 120
///   let b : Int16 = 10
///   inspect(a + b, content="130")
/// }
/// ```
pub impl Add for Int16 with add(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() + that.to_int())
}

///|
/// Subtracts two `Int16` values with wrapping semantics.
///
/// # Example
/// ```mbt check
/// test "int16 sub" {
///   let a : Int16 = 120
///   let b : Int16 = 10
///   inspect(a - b, content="110")
/// }
/// ```
pub impl Sub for Int16 with sub(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() - that.to_int())
}

///|
/// Multiplies two `Int16` values with wrapping semantics.
///
/// # Example
/// ```mbt check
/// test "int16 mul" {
///   let a : Int16 = 12
///   let b : Int16 = 11
///   inspect(a * b, content="132")
/// }
/// ```
pub impl Mul for Int16 with mul(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() * that.to_int())
}

///|
/// Divides two `Int16` values with truncating division.
///
/// # Panics
/// Panics if `that` is `0`.
///
/// # Example
/// ```mbt check
/// test "int16 div" {
///   let a : Int16 = 120
///   let b : Int16 = 7
///   inspect(a / b, content="17")
/// }
/// ```
pub impl Div for Int16 with div(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() / that.to_int())
}

///|
/// Computes the remainder of dividing two `Int16` values.
///
/// # Panics
/// Panics if `that` is `0`.
///
/// # Example
/// ```mbt check
/// test "int16 mod" {
///   let a : Int16 = 120
///   let b : Int16 = 7
///   inspect(a % b, content="1")
/// }
/// ```
pub impl Mod for Int16 with mod(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() % that.to_int())
}

///|
/// Compares two `Int16` values for equality.
///
/// # Example
/// ```mbt check
/// test "int16 eq" {
///   let a : Int16 = 5
///   let b : Int16 = 5
///   let c : Int16 = -5
///   inspect(a == b, content="true")
///   inspect(a == c, content="false")
/// }
/// ```
pub impl Eq for Int16 with equal(self, that) {
  self.to_int() == that.to_int()
}

///|
/// Provides total ordering for `Int16`.
///
/// # Example
/// ```mbt check
/// test "int16 compare" {
///   let a : Int16 = 5
///   let b : Int16 = -5
///   inspect(a.compare(b), content="1")
///   inspect(b.compare(a), content="-1")
///   inspect(a.compare(a), content="0")
/// }
/// ```
pub impl Compare for Int16 with compare(self, that) {
  self.to_int().compare(that.to_int())
}

///|
/// Hashes an `Int16` value using its `Int` representation.
///
/// # Example
/// ```mbt check
/// test "int16 hash" {
///   let a : Int16 = 12
///   let b : Int16 = 12
///   let c : Int16 = 13
///   let ha = a.hash()
///   let hb = b.hash()
///   let hc = c.hash()
///   inspect(ha == hb, content="true")
///   inspect(ha == hc, content="false")
/// }
/// ```
pub impl Hash for Int16 with hash_combine(self, hasher) {
  hasher.combine_int(self.to_int())
}

///|
/// Shifts `Int16` bits to the left by the given amount.
///
/// # Example
/// ```mbt check
/// test "int16 shl" {
///   let a : Int16 = 3
///   inspect(a << 2, content="12")
/// }
/// ```
pub impl Shl for Int16 with shl(self : Int16, that : Int) -> Int16 {
  Int16::from_int(self.to_int() << that)
}

///|
/// Shifts `Int16` bits to the right by the given amount.
///
/// # Example
/// ```mbt check
/// test "int16 shr" {
///   let a : Int16 = 12
///   inspect(a >> 2, content="3")
/// }
/// ```
pub impl Shr for Int16 with shr(self : Int16, that : Int) -> Int16 {
  Int16::from_int(self.to_int() >> that)
}

///|
/// Computes the bitwise OR of two `Int16` values.
///
/// # Example
/// ```mbt check
/// test "int16 bitor" {
///   let a : Int16 = 0b1100
///   let b : Int16 = 0b1010
///   inspect(a | b, content="14")
/// }
/// ```
pub impl BitOr for Int16 with lor(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() | that.to_int())
}

///|
/// Computes the bitwise AND of two `Int16` values.
///
/// # Example
/// ```mbt check
/// test "int16 bitand" {
///   let a : Int16 = 0b1100
///   let b : Int16 = 0b1010
///   inspect(a & b, content="8")
/// }
/// ```
pub impl BitAnd for Int16 with land(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() & that.to_int())
}

///|
/// Computes the bitwise XOR of two `Int16` values.
///
/// # Example
/// ```mbt check
/// test "int16 bitxor" {
///   let a : Int16 = 0b1100
///   let b : Int16 = 0b1010
///   inspect(a ^ b, content="6")
/// }
/// ```
pub impl BitXOr for Int16 with lxor(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() ^ that.to_int())
}

///|
/// Negates an `Int16` value with wrapping semantics.
///
/// # Example
/// ```mbt check
/// test "int16 neg" {
///   let a : Int16 = 12
///   inspect(-a, content="-12")
/// }
/// ```
pub impl Neg for Int16 with neg(self : Int16) -> Int16 {
  Int16::from_int(-self.to_int())
}

///|
/// Returns the absolute value of an `Int16`.
///
/// `min_value.abs()` returns `min_value` because `32768` is out of range and
/// wraps in two's complement.
///
/// # Example
/// ```mbt check
/// test "int16 abs" {
///   let a : Int16 = -12
///   inspect(a.abs(), content="12")
///   let min = @int16.min_value
///   inspect(min.abs(), content="-32768")
/// }
/// ```
pub fn Int16::abs(self : Int16) -> Int16 {
  if self < 0 {
    -self
  } else {
    self
  }
}

///|
/// Returns the default `Int16` value, which is `0`.
///
/// # Example
/// ```mbt check
/// test "int16 default" {
///   inspect(Int16::default(), content="0")
/// }
/// ```
pub impl Default for Int16 with default() {
  0
}

///|
/// Converts an `Int16` to JSON as a number.
///
/// # Example
/// ```mbt check
/// test "int16 to_json" {
///   @json.inspect((12 : Int16).to_json(), content=12)
/// }
/// ```
pub impl ToJson for Int16 with to_json(self : Int16) -> Json {
  Json::number(self.to_int().to_double())
}

///|
/// Formats an `Int16` using its decimal string representation.
///
/// # Example
/// ```mbt check
/// test "int16 show" {
///   inspect((12 : Int16), content="12")
/// }
/// ```
pub impl Show for Int16 with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Reinterprets an `Int16` as `UInt16` using two's complement bits.
///
/// # Example
/// ```mbt check
/// test "int16 reinterpret_as_uint16" {
///   let n : Int16 = -1
///   inspect(n.reinterpret_as_uint16(), content="65535")
/// }
/// ```
pub fn Int16::reinterpret_as_uint16(self : Int16) -> UInt16 {
  self.to_int().to_uint16()
}

///|
/// Reinterprets a `UInt16` as `Int16` using two's complement bits.
///
/// # Example
/// ```mbt check
/// test "int16 reinterpret_from_uint16" {
///   let n : UInt16 = 65535
///   inspect(Int16::reinterpret_from_uint16(n), content="-1")
/// }
/// ```
pub fn Int16::reinterpret_from_uint16(self : UInt16) -> Int16 {
  Int16::from_int(self.to_int())
}

///|
/// Converts an `Int` value to a 16-bit signed integer (`Int16`).
///
/// This function performs a truncating conversion from a 32-bit signed integer
/// to a 16-bit signed integer. Values outside the valid range for Int16
/// (-32768 to 32767) will be truncated.
///
/// Parameters:
///
/// * `self` : The `Int` value to be converted.
///
/// Returns an `Int16` representing the lower 16 bits of the input value,
/// interpreted as a signed integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   let n = Int16::from_int(42)
///   inspect(n, content="42")
///   let neg = Int16::from_int(-42)
///   inspect(neg, content="-42")
/// }
/// ```
pub fn Int16::from_int(self : Int) -> Int16 = "%i32_to_i16"

///|
/// Converts a `Byte` value to a 16-bit signed integer (`Int16`).
///
/// This function extends the byte value (0-255) to a 16-bit signed integer.
/// Values from 0-127 map to themselves. Values from 128-255 are treated as
/// unsigned and map to 128-255 in Int16.
///
/// Parameters:
///
/// * `self` : The byte value to be converted to an `Int16`.
///
/// Returns an `Int16` value where the byte is zero-extended to 16 bits
/// and then interpreted as a signed integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   let b = b'\xFF'
///   inspect(Int16::from_byte(b), content="255") // Byte is zero-extended
///   let p = b'\x7F'
///   inspect(Int16::from_byte(p), content="127")
/// }
/// ```
pub fn Int16::from_byte(self : Byte) -> Int16 = "%byte_to_i16"

///|
/// Converts an `Int64` value to a 16-bit signed integer (`Int16`).
///
/// This function performs a truncating conversion from a 64-bit signed integer
/// to a 16-bit signed integer, taking only the lower 16 bits of the input.
/// Values outside the valid range for Int16 will be truncated to fit.
///
/// Parameters:
///
/// * `self` : The `Int64` value to be converted.
///
/// Returns an `Int16` representing the lower 16 bits of the input value.
///
/// Example:
///
/// ```mbt check
/// test {
///   let big = 100000L
///   inspect(Int16::from_int64(big), content="-31072") // 100000 doesn't fit in Int16, gets truncated
///   let small = 42L
///   inspect(Int16::from_int64(small), content="42") // 42 fits in Int16, remains unchanged
/// }
/// ```
#cfg(not(target="js"))
pub fn Int16::from_int64(self : Int64) -> Int16 = "%i64_to_i16"

///|
/// Converts an `Int64` value to a 16-bit signed integer (`Int16`) in JS builds.
///
/// # Example
/// ```mbt check
/// test "int16 from_int64 js" {
///   let big = 100000L
///   inspect(Int16::from_int64(big), content="-31072")
/// }
/// ```
#cfg(target="js")
pub fn Int16::from_int64(self : Int64) -> Int16 {
  Int16::from_int(self.to_int())
}

///|
/// Converts an `Int16` value to `Int64` in JS builds.
///
/// # Example
/// ```mbt check
/// test "int16 to_int64 js" {
///   let n : Int16 = -12
///   inspect(n.to_int64(), content="-12")
/// }
/// ```
#cfg(target="js")
pub fn Int16::to_int64(self : Int16) -> Int64 {
  self.to_int().to_int64()
}

///|
/// Converts an `Int16` value to `Int64`.
///
/// # Example
/// ```mbt check
/// test "int16 to_int64" {
///   let n : Int16 = 12
///   inspect(n.to_int64(), content="12")
/// }
/// ```
#cfg(not(target="js"))
pub fn Int16::to_int64(self : Int16) -> Int64 = "%i16_to_i64"

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
/// ```mbt check
/// test {
///   let n = (42 : Int16)
///   inspect(n.to_int(), content="42")
///   let neg = (-42 : Int16)
///   inspect(neg.to_int(), content="-42")
/// }
/// ```
pub fn Int16::to_int(self : Int16) -> Int = "%i16_to_i32"

///|
/// Converts a 16-bit signed integer to a byte by truncating its value to fit
/// within the byte range (0 to 255). Only the least significant 8 bits of the
/// integer are retained, so negative values wrap using two's complement.
///
/// Parameters:
///
/// * `value` : The 16-bit signed integer to be converted to a byte.
///
/// Returns a byte containing the least significant 8 bits of the input value.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x : Int16 = 258 // In binary: 0000_0001_0000_0010
///   inspect(x.to_byte(), content="b'\\x02'") // Only keeps 0000_0010
/// }
/// ```
pub fn Int16::to_byte(self : Int16) -> Byte = "%i16_to_byte"

///|
/// Converts an `Int16` to a string in the given radix.
///
/// # Example
/// ```mbt check
/// test "int16 to_string" {
///   let n : Int16 = 255
///   inspect(n.to_string(), content="255")
///   inspect(n.to_string(radix=16), content="ff")
/// }
/// ```
pub fn Int16::to_string(self : Int16, radix? : Int = 10) -> String {
  self.to_int().to_string(radix~)
}
