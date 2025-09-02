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
pub let max_value = 9223372036854775807L

///|
pub let min_value = -9223372036854775808L

///|
/// Converts a 32-bit integer (`Int`) to a 64-bit integer (`Int64`).
///
/// Parameters:
///
/// * `i` : The integer value to be converted.
///
/// Returns the converted 64-bit integer (`Int64`) value.
///
/// Example:
///
/// ```moonbit
///   inspect(@int64.from_int(42), content="42")
/// ```
pub fn Int64::from_int(i : Int) -> Int64 {
  i.to_int64()
}

///|
/// same as `Int64::from_int`
pub fn from_int(i : Int) -> Int64 {
  i.to_int64()
}

///|
/// Computes the absolute value of a 64-bit integer.
///
/// Parameters:
///
/// * `self` : The 64-bit integer whose absolute value is to be computed.
///
/// Returns the absolute value of the input integer.
///
/// Example:
///
/// ```moonbit
///   inspect(42L.abs(), content="42")
///   inspect((-42L).abs(), content="42")
///   inspect(0L.abs(), content="0")
/// ```
#as_free_fn
pub fn Int64::abs(self : Int64) -> Int64 {
  if self < 0L {
    -self
  } else {
    self
  }
}

///|
/// Converts the Int64 to a Bytes in big-endian byte order.
pub fn to_be_bytes(self : Int64) -> Bytes {
  self.reinterpret_as_uint64().to_be_bytes()
}

///|
/// Converts the Int64 to a Bytes in little-endian byte order.
pub fn to_le_bytes(self : Int64) -> Bytes {
  self.reinterpret_as_uint64().to_le_bytes()
}
