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
/// Smallest representable `UInt64` value.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@uint64.min_value, content="0")
/// }
/// ```
pub let min_value : UInt64 = 0UL

///|
/// Largest representable `UInt64` value.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@uint64.max_value, content="18446744073709551615")
/// }
/// ```
pub let max_value : UInt64 = 18446744073709551615UL

///|
/// Converts the `UInt64` to `Bytes` in big-endian byte order.
///
/// # Example
/// ```mbt check
/// test {
///   let bytes = 0x0102030405060708UL.to_be_bytes()
///   inspect(
///     bytes,
///     content=(
///       #|b"\x01\x02\x03\x04\x05\x06\x07\x08"
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
/// Converts the `UInt64` to `Bytes` in little-endian byte order.
///
/// # Example
/// ```mbt check
/// test {
///   let bytes = 0x0102030405060708UL.to_le_bytes()
///   inspect(
///     bytes,
///     content=(
///       #|b"\x08\x07\x06\x05\x04\x03\x02\x01"
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
