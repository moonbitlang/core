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
/// Converts the UInt64 to a Bytes in big-endian byte order.
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
/// Converts the UInt64 to a Bytes in little-endian byte order.
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
