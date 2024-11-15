// Copyright 2024 International Digital Economy Academy
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
pub fn op_mul(self : Byte, that : Byte) -> Byte {
  (self.to_int() * that.to_int()).to_byte()
}

///|
pub fn op_div(self : Byte, that : Byte) -> Byte {
  (self.to_int() / that.to_int()).to_byte()
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
pub fn op_equal(self : Byte, that : Byte) -> Bool {
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
pub fn op_add(self : Byte, that : Byte) -> Byte {
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
pub fn op_sub(self : Byte, that : Byte) -> Byte {
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
pub fn compare(self : Byte, that : Byte) -> Int {
  self.to_int().compare(that.to_int())
}

///|
fn alphabet(self : Int) -> String {
  match self {
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
pub fn to_string(self : Byte) -> String {
  let i = self.to_int()
  let hi = alphabet(i / 16)
  let lo = alphabet(i % 16)
  "b'\\x\{hi}\{lo}'"
}

///|
pub impl Hash for Byte with hash(self) { self.to_int() }

///|
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
pub fn Byte::default() -> Byte {
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
pub fn Byte::land(self : Byte, that : Byte) -> Byte {
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
pub fn Byte::lor(self : Byte, that : Byte) -> Byte {
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
pub fn Byte::lxor(self : Byte, that : Byte) -> Byte {
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
pub fn Byte::op_shl(self : Byte, count : Int) -> Byte {
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
pub fn Byte::op_shr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}

///|
/// positions.
///
/// Parameters:
///
/// - `byte_value` : The `Byte` value whose bits are to be shifted.
/// - `shift_count` : The number of bit positions to shift the `byte_value` to
///   the left.
///
/// Returns the resulting `Byte` value after the bitwise left shift operation.
/// 
/// @alert deprecated "Use infix operator `<<` instead"
pub fn Byte::lsl(self : Byte, count : Int) -> Byte {
  (self.to_int() << count).to_byte()
}

///|
/// bits.
///
/// Parameters:
///
/// - `value` : The `Byte` value to be shifted.
/// - `count` : The number of bits to shift the `value` to the right.
///
/// Returns the result of the logical shift right operation as a `Byte`.
///
/// @alert deprecated "Use infix operator `>>` instead"
pub fn Byte::lsr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}
