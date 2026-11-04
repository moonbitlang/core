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
/// The identity constructor for `UInt64`, allowing values to be written using
/// constructor syntax, e.g. `UInt64(3)`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt64(3), content="3")
/// }
/// ```
pub fn UInt64::UInt64(self : UInt64) -> UInt64 = "%identity"

///|
pub impl Default for UInt64 with fn default() {
  0
}

///|
test {
  inspect(0x7000_0001_1F00_100FUL.popcnt(), content="14")
}

///|
/// Converts the `UInt64` to a `Bytes` of 8 bytes in big-endian byte order
/// (most significant byte first).
///
/// Parameters:
///
/// * `self` : The 64-bit unsigned integer to convert.
///
/// Returns a `Bytes` of length 8 whose first element is the most significant
/// byte of `self` and whose last element is the least significant byte.
///
/// Example:
///
/// ```mbt check
/// test {
///   // 0x41..0x48 are the ASCII codes for 'A'..'H'
///   inspect(
///     0x4142_4344_4546_4748UL.to_be_bytes(),
///     content=(
///       #|b"ABCDEFGH"
///     ),
///   )
/// }
/// ```
pub fn UInt64::to_be_bytes(self : UInt64) -> Bytes {
  [
    (self >> 56).to_byte(),
    (self >> 48).to_byte(),
    (self >> 40).to_byte(),
    (self >> 32).to_byte(),
    (self >> 24).to_byte(),
    (self >> 16).to_byte(),
    (self >> 8).to_byte(),
    self.to_byte(),
  ]
}

///|
/// Converts the `UInt64` to a `Bytes` of 8 bytes in little-endian byte order
/// (least significant byte first).
///
/// Parameters:
///
/// * `self` : The 64-bit unsigned integer to convert.
///
/// Returns a `Bytes` of length 8 whose first element is the least significant
/// byte of `self` and whose last element is the most significant byte.
///
/// Example:
///
/// ```mbt check
/// test {
///   // The same value as `to_be_bytes`, with the byte order reversed
///   inspect(
///     0x4142_4344_4546_4748UL.to_le_bytes(),
///     content=(
///       #|b"HGFEDCBA"
///     ),
///   )
/// }
/// ```
pub fn UInt64::to_le_bytes(self : UInt64) -> Bytes {
  [
    self.to_byte(),
    (self >> 8).to_byte(),
    (self >> 16).to_byte(),
    (self >> 24).to_byte(),
    (self >> 32).to_byte(),
    (self >> 40).to_byte(),
    (self >> 48).to_byte(),
    (self >> 56).to_byte(),
  ]
}

///|
/// Returns the smaller of two unsigned 64-bit integers.
///
/// Parameters:
///
/// * `self` : The first integer to compare.
/// * `other` : The second integer to compare.
///
/// Returns `self` if it is not greater than `other`, `other` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt64(1).min(UInt64(2)), content="1")
///   inspect(UInt64(2).min(UInt64(1)), content="1")
///   inspect(UInt64(0).min(UInt64(0)), content="0")
/// }
/// ```
pub fn UInt64::min(self : UInt64, other : UInt64) -> UInt64 {
  if self < other {
    self
  } else {
    other
  }
}

///|
/// Returns the larger of two unsigned 64-bit integers.
///
/// Parameters:
///
/// * `self` : The first integer to compare.
/// * `other` : The second integer to compare.
///
/// Returns `self` if it is not less than `other`, `other` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt64(1).max(UInt64(2)), content="2")
///   inspect(UInt64(2).max(UInt64(1)), content="2")
///   inspect(UInt64(0).max(UInt64(0)), content="0")
/// }
/// ```
pub fn UInt64::max(self : UInt64, other : UInt64) -> UInt64 {
  if self > other {
    self
  } else {
    other
  }
}

///|
/// Clamps an unsigned 64-bit integer into the inclusive range [`min`, `max`].
///
/// Parameters:
///
/// * `self` : The value to clamp.
/// * `min` : The lower bound of the range.
/// * `max` : The upper bound of the range.
///
/// Returns `min` if `self` is less than `min`, `max` if `self` is greater
/// than `max`, and `self` otherwise. Aborts if `min` is greater than `max`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt64(5).clamp(min=UInt64(0), max=UInt64(10)), content="5")
///   inspect(UInt64(0).clamp(min=UInt64(2), max=UInt64(10)), content="2")
///   inspect(UInt64(15).clamp(min=UInt64(0), max=UInt64(10)), content="10")
/// }
/// ```
pub fn UInt64::clamp(self : UInt64, min~ : UInt64, max~ : UInt64) -> UInt64 {
  guard! min <= max
  if self < min {
    min
  } else if self > max {
    max
  } else {
    self
  }
}
