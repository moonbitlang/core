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
/// Maximum value of an integer.
pub let max_value = 2147483647

///|
/// Minimum value of an integer.
pub let min_value = -2147483648

///|
#deprecated("Use Int::abs instead")
pub fn abs(x : Int) -> Int {
  Int::abs(x)
}

///|
/// Converts the Int to a Bytes in big-endian byte order.
#deprecated
#doc(hidden)
pub fn Int::to_be_bytes(self : Int) -> Bytes {
  let self = self.reinterpret_as_uint()
  [
    (self >> 24).to_byte(),
    (self >> 16).to_byte(),
    (self >> 8).to_byte(),
    self.to_byte(),
  ]
}

///|
/// Converts the Int to a Bytes in little-endian byte order.
#deprecated
#doc(hidden)
pub fn Int::to_le_bytes(self : Int) -> Bytes {
  let self = self.reinterpret_as_uint()
  [
    self.to_byte(),
    (self >> 8).to_byte(),
    (self >> 16).to_byte(),
    (self >> 24).to_byte(),
  ]
}
