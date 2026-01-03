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
pub let max_value : Int16 = 32767

///|
pub let min_value : Int16 = -32768

///|
pub impl Add for Int16 with add(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() + that.to_int())
}

///|
pub impl Sub for Int16 with sub(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() - that.to_int())
}

///|
pub impl Mul for Int16 with mul(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() * that.to_int())
}

///|
pub impl Div for Int16 with div(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() / that.to_int())
}

///|
pub impl Mod for Int16 with mod(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() % that.to_int())
}

///|
pub impl Eq for Int16 with equal(self, that) {
  self.to_int() == that.to_int()
}

///|
pub impl Eq for Int16 with not_equal(self, that) {
  self.to_int() != that.to_int()
}

///|
pub impl Compare for Int16 with compare(self, that) {
  self.to_int().compare(that.to_int())
}

///|
pub impl Hash for Int16 with hash_combine(self, hasher) {
  hasher.combine_int(self.to_int())
}

///|
pub impl Shl for Int16 with shl(self : Int16, that : Int) -> Int16 {
  Int16::from_int(self.to_int() << that)
}

///|
pub impl Shr for Int16 with shr(self : Int16, that : Int) -> Int16 {
  Int16::from_int(self.to_int() >> that)
}

///|
pub impl BitOr for Int16 with lor(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() | that.to_int())
}

///|
pub impl BitAnd for Int16 with land(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() & that.to_int())
}

///|
pub impl BitXOr for Int16 with lxor(self : Int16, that : Int16) -> Int16 {
  Int16::from_int(self.to_int() ^ that.to_int())
}

///|
pub impl Neg for Int16 with neg(self : Int16) -> Int16 {
  Int16::from_int(-self.to_int())
}

///|
pub fn Int16::abs(self : Int16) -> Int16 {
  if self < 0 {
    -self
  } else {
    self
  }
}

///|
pub impl Default for Int16 with default() {
  0
}

///|
pub impl ToJson for Int16 with to_json(self : Int16) -> Json {
  Json::number(self.to_int().to_double())
}

///|
pub impl Show for Int16 with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// reinterpret as an unsigned integer with binary complement
pub fn Int16::reinterpret_as_uint16(self : Int16) -> UInt16 {
  self.to_int().to_uint16()
}

///|
/// reinterpret from an unsigned integer with binary complement
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
///   inspect(Int16::from_byte(b), content="255") // Sign is preserved
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
#cfg(target="js")
pub fn Int16::from_int64(self : Int64) -> Int16 {
  Int16::from_int(self.to_int())
}

///|
#cfg(target="js")
pub fn Int16::to_int64(self : Int16) -> Int64 {
  self.to_int().to_int64()
}

///|
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
/// ```mbt check
/// test {
///   let x : Int16 = 258 // In binary: 0000_0001_0000_0010
///   inspect(x.to_byte(), content="b'\\x02'") // Only keeps 0000_0010
/// }
/// ```
pub fn Int16::to_byte(self : Int16) -> Byte = "%i16_to_byte"

///|
pub fn Int16::to_string(self : Int16, radix? : Int = 10) -> String {
  self.to_int().to_string(radix~)
}
