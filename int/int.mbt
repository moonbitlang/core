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
#as_free_fn
pub fn Int::abs(self : Int) -> Int {
  if self < 0 {
    -self
  } else {
    self
  }
}

///|
/// Converts the Int to a Bytes in big-endian byte order.
pub fn to_be_bytes(self : Int) -> Bytes {
  self.reinterpret_as_uint().to_be_bytes()
}

///|
/// Converts the Int to a Bytes in little-endian byte order.
pub fn to_le_bytes(self : Int) -> Bytes {
  self.reinterpret_as_uint().to_le_bytes()
}
