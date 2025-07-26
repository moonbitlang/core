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
/// Maximum value of an integer.
pub let max_value = 2147483647

///|
/// Minimum value of an integer.
pub let min_value = -2147483648

///|
/// Computes the absolute value of an integer.
///
/// Parameters:
///
/// * `self` : The integer whose absolute value is to be computed.
///
/// Returns the absolute value of the integer.
///
/// Example:
///
/// ```moonbit
///   inspect(@int.abs(42), content="42")
///   inspect(@int.abs(-42), content="42")
///   inspect(@int.abs(0), content="0")
/// ```
pub fn Int::abs(self : Int) -> Int {
  if self < 0 {
    -self
  } else {
    self
  }
}

///|
pub fnalias Int::abs

///| Converts the Int to a Bytes in big-endian byte order.
pub fn to_be_bytes(self : Int) -> Bytes {
  self.reinterpret_as_uint().to_be_bytes()
}

///| Converts the Int to a Bytes in little-endian byte order.
pub fn to_le_bytes(self : Int) -> Bytes {
  self.reinterpret_as_uint().to_le_bytes()
}

///|
/// Returns the smallest power of two greater than or equal to `self`.
/// This function will panic if `self` is negative. For values greater than
/// the largest representable power of two (2^30 = 1073741824), it returns
/// the largest representable power of two.
///
/// Example:
/// ```moonbit
///   inspect((0).next_power_of_two(), content="1")
///   inspect((1).next_power_of_two(), content="1")
///   inspect((2).next_power_of_two(), content="2")
///   inspect((3).next_power_of_two(), content="4")
///   inspect((8).next_power_of_two(), content="8")
///   inspect((1073741824).next_power_of_two(), content="1073741824")
///   inspect((2000000000).next_power_of_two(), content="1073741824")
/// ```
pub fn next_power_of_two(self : Int) -> Int {
  guard self >= 0
  if self <= 1 {
    return 1
  }
  // The largest power of 2 that fits in a 32-bit signed integer is 2^30
  let max_power_of_two = 1073741824 // 2^30
  if self > max_power_of_two {
    return max_power_of_two
  }
  (max_value >> ((self - 1).clz() - 1)) + 1
}
