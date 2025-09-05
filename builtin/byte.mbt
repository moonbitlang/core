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
/// Performs multiplication between two byte values. The result is truncated to
/// fit within the byte range.
///
/// Parameters:
///
/// * `self` : The first byte operand in the multiplication.
/// * `that` : The second byte operand in the multiplication.
///
/// Returns the product of the two bytes, truncated to fit within the byte range
/// (0-255).
///
/// Example:
///
/// ```moonbit
///   let a = b'\x02'
///   let b = b'\x03'
///   inspect(a * b, content="b'\\x06'") // 2 * 3 = 6
///   let c = b'\xFF'
///   inspect(c * c, content="b'\\x01'") // 255 * 255 = 65025, truncated to 1
/// ```
pub impl Mul for Byte with mul(self : Byte, that : Byte) -> Byte {
  (self.to_int() * that.to_int()).to_byte()
}

///|
/// Performs division operation between two bytes by converting them to integers,
/// performing the division, and converting the result back to a byte.
///
/// Parameters:
///
/// * `self` : The dividend byte value.
/// * `that` : The divisor byte value.
///
/// Returns the quotient of the division as a byte.
///
/// Example:
///
/// ```moonbit
///   let a = b'\xFF' // 255
///   let b = b'\x03' // 3
///   inspect(a / b, content="b'\\x55'") // 255 / 3 = 85 (0x55)
/// ```
pub impl Div for Byte with div(self : Byte, that : Byte) -> Byte {
  (self.to_int() / that.to_int()).to_byte()
}

///|
pub impl Mod for Byte with mod(self : Byte, that : Byte) -> Byte {
  (self.to_int() % that.to_int()).to_byte()
}

///|
/// Compares two `Byte` values for equality.
///
/// Parameters:
///
/// - `self` : The first `Byte` value to compare.
/// - `that` : The second `Byte` value to compare.
///
/// Returns `true` if the two `Byte` values are equal, otherwise `false`.
pub impl Eq for Byte with equal(self : Byte, that : Byte) -> Bool {
  self.to_int() == that.to_int()
}

///|
/// Adds two `Byte` values together and returns the result as a `Byte`.
///
/// Parameters:
///
/// - `byte1` : The first `Byte` value to be added.
/// - `byte2` : The second `Byte` value to be added.
///
/// Returns the sum of `byte1` and `byte2` as a `Byte`.
pub impl Add for Byte with add(self : Byte, that : Byte) -> Byte {
  (self.to_int() + that.to_int()).to_byte()
}

///|
/// Subtracts the second byte from the first byte and returns the result as a
/// byte.
///
/// Parameters:
///
/// - `self` : The byte from which the second byte will be subtracted.
/// - `that` : The byte to subtract from the first byte.
///
/// Returns the result of the subtraction as a byte.
pub impl Sub for Byte with sub(self : Byte, that : Byte) -> Byte {
  (self.to_int() - that.to_int()).to_byte()
}

///|
/// Compares two `Byte` values and returns an integer indicating their relative
/// order.
///
/// Parameters:
///
/// - `byte1` : The first `Byte` value to compare.
/// - `byte2` : The second `Byte` value to compare.
///
/// Returns an integer where:
/// - A value less than 0 indicates that `byte1` is less than `byte2`.
/// - A value of 0 indicates that `byte1` is equal to `byte2`.
/// - A value greater than 0 indicates that `byte1` is greater than `byte2`.
pub impl Compare for Byte with compare(self : Byte, that : Byte) -> Int {
  self.to_int().compare(that.to_int())
}

///|
fn alphabet(x : Int) -> String {
  match x {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "A"
    11 => "B"
    12 => "C"
    13 => "D"
    14 => "E"
    15 => "F"
    _ => abort("impossible")
  }
}

///|
/// Converts a `Byte` to its string representation in hexadecimal format.
///
/// Parameters:
///
/// - `byte` : The `Byte` value to be converted.
///
/// Returns a `String` representing the `Byte` in the format `b'\xHH'`, where
/// `HH` is the hexadecimal representation of the byte.
pub fn Byte::to_string(self : Byte) -> String {
  let i = self.to_int()
  let hi = alphabet(i / 16)
  let lo = alphabet(i % 16)
  "b'\\x\{hi}\{lo}'"
}

///|
/// Implements the `Hash` trait for `Byte` type by converting the byte to an
/// integer and using it as the hash value.
///
/// Parameters:
///
/// * `self` : The byte value to be hashed.
///
/// Returns an integer representing the hash value of the byte.
///
/// Example:
///
/// ```moonbit
///   let b = b'\x42'
///   inspect(Hash::hash(b), content="66") // ASCII value of 'B'
/// ```
pub impl Hash for Byte with hash(self) {
  self.to_int()
}

///|
/// Implements the `Hash` trait for `Byte` type by providing a `hash_combine`
/// method that combines a byte value with a hasher.
///
/// Parameters:
///
/// * `self` : The byte value to be hashed.
/// * `hasher` : The hasher object that will be used to combine the byte value
/// into its internal state.
///
/// Example:
///
/// ```moonbit
///   let hasher = Hasher::new()
///   hasher.combine_byte(b'\xFF')
///   inspect(hasher.finalize(), content="1955036104")
/// ```
pub impl Hash for Byte with hash_combine(self, hasher) {
  hasher.combine_byte(self)
}

///|
/// Returns the default value for a `Byte`, which is `b'\x00'`.
///
/// Parameters:
///
/// - None
///
/// Returns the default `Byte` value, which is `b'\x00'`.
pub impl Default for Byte with default() {
  b'\x00'
}

///|
/// Performs a bitwise NOT operation on the given `Byte` value.
///
/// Parameters:
///
/// - `value` : The `Byte` value to apply the bitwise NOT operation on.
///
/// Returns the result of the bitwise NOT operation as a `Byte`.
pub fn Byte::lnot(self : Byte) -> Byte {
  self.to_int().lnot().to_byte()
}

///|
/// Performs a bitwise AND operation between two `Byte` values.
///
/// Parameters:
///
/// - `byte1` : The first `Byte` value to perform the bitwise AND operation with.
/// - `byte2` : The second `Byte` value to perform the bitwise AND operation
///   with.
///
/// Returns the result of the bitwise AND operation as a `Byte`.
pub impl BitAnd for Byte with land(self : Byte, that : Byte) -> Byte {
  (self.to_int() & that.to_int()).to_byte()
}

///|
/// Performs a bitwise OR operation between two `Byte` values.
///
/// Parameters:
///
/// - `self` : The first `Byte` value.
/// - `that` : The second `Byte` value.
///
/// Returns a new `Byte` value resulting from the bitwise OR operation.
pub impl BitOr for Byte with lor(self : Byte, that : Byte) -> Byte {
  (self.to_int() | that.to_int()).to_byte()
}

///|
/// Performs a bitwise XOR operation between two `Byte` values.
///
/// Parameters:
///
/// - `self` : The first `Byte` value.
/// - `that` : The second `Byte` value.
///
/// Returns the result of the bitwise XOR operation as a `Byte`.
pub impl BitXOr for Byte with lxor(self : Byte, that : Byte) -> Byte {
  (self.to_int() ^ that.to_int()).to_byte()
}

///|
/// Converts a `Byte` to a `UInt`.
///
/// Parameters:
///
/// - `byte` : The `Byte` value to be converted.
///
/// Returns the `UInt` representation of the `Byte`.
pub fn Byte::to_uint(self : Byte) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///|
/// Shifts the bits of the `Byte` value to the left by the specified number of
/// positions.
///
/// Parameters:
///
/// - `byte_value` : The `Byte` value whose bits are to be shifted.
/// - `shift_count` : The number of bit positions to shift the `byte_value` to
///   the left.
///
/// Returns the resulting `Byte` value after the shift operation.
pub impl Shl for Byte with shl(self : Byte, count : Int) -> Byte {
  (self.to_int() << count).to_byte()
}

///|
/// Shifts the bits of the `Byte` value to the right by the specified number of
/// positions.
///
/// Parameters:
///
/// - `byte` : The `Byte` value whose bits are to be shifted.
/// - `count` : The number of bit positions to shift the `byte` value to the
///   right.
///
/// Returns the resulting `Byte` value after the bitwise right shift operation.
pub impl Shr for Byte with shr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}
