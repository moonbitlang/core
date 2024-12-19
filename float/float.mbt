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
pub let not_a_number : Float = (0x7FC00000).reinterpret_as_float()

///|
pub let infinity : Float = (0x7F800000).reinterpret_as_float()

///|
pub let neg_infinity : Float = (0xFF800000).reinterpret_as_float()

///|
pub let max_value : Float = (0x7F7FFFFF).reinterpret_as_float()

///|
pub let min_value : Float = (0xFF7FFFFF).reinterpret_as_float()

///|
pub let min_positive : Float = (0x00800000).reinterpret_as_float()

///|
pub fn abs(self : Float) -> Float = "%f32.abs"

///|
pub impl Show for Float with output(self, logger) {
  logger.write_string(self.to_double().to_string())
}

///|
pub fn Float::default() -> Float {
  0.0
}

///|
fn Float::to_unchecked_int(self : Float) -> Int = "%f32.to_i32"

///|
/// Converts a floating-point number to an integer, with proper handling of
/// special cases such as NaN and values outside the range of 32-bit integers.
///
/// Parameters:
///
/// * `self` : The floating-point number to be converted.
///
/// Returns an integer representation of the float value. Specifically:
/// * `0` for `@float.not_a_number` (NaN),
/// * `@int.max_value` (2147483647) for values greater than `@int.max_value`,
/// * `@int.min_value` (-2147483648) for values less than `@int.min_value`.
/// * truncated (towards zero) integer value for other cases.
///
/// Examples:
///
/// ```moonbit
/// test "Float::to_int/normal" {
///   inspect!((1.5 : Float).to_int(), content="1")
///   inspect!((-1.5 : Float).to_int(), content="-1")
///   inspect!(@float.not_a_number.to_int(), content="0")
///   inspect!(@float.infinity.to_int(), content="2147483647")
///   inspect!(@float.neg_infinity.to_int(), content="-2147483648")
/// }
/// ```
pub fn Float::to_int(self : Float) -> Int {
  if self != self {
    0
  } else if self >= 2147483647 {
    2147483647
  } else if self <= -2147483648 {
    -2147483648
  } else {
    self.to_unchecked_int()
  }
}

///|
pub fn to_be_bytes(self : Float) -> Bytes {
  self.reinterpret_as_uint().to_be_bytes()
}

///|
pub fn to_le_bytes(self : Float) -> Bytes {
  self.reinterpret_as_uint().to_le_bytes()
}
