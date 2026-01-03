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
pub let max_value = 9223372036854775807L

///|
pub let min_value = -9223372036854775808L

///|
/// same as `Int64::from_int`
#deprecated("Use Int64::from_int instead")
#doc(hidden)
pub fn from_int(i : Int) -> Int64 {
  i.to_int64()
}

///|
#deprecated("Use Int64::abs instead")
#doc(hidden)
pub fn abs(x : Int64) -> Int64 {
  Int64::abs(x)
}

///|
/// Converts the Int64 to a Bytes in big-endian byte order.
#deprecated
#doc(hidden)
pub fn Int64::to_be_bytes(self : Int64) -> Bytes {
  self.reinterpret_as_uint64().to_be_bytes()
}

///|
/// Converts the Int64 to a Bytes in little-endian byte order.
#deprecated
#doc(hidden)
pub fn Int64::to_le_bytes(self : Int64) -> Bytes {
  self.reinterpret_as_uint64().to_le_bytes()
}

///|
/// Converts a 64-bit signed integer to a 16-bit signed integer by truncating the
/// value to fit within the 16-bit range (-32768 to 32767).
///
/// Parameters:
///
/// * `value` : The 64-bit signed integer to be converted.
///
/// Returns a 16-bit signed integer representing the lower 16 bits of the input
/// value.
#deprecated("Use `Int16::from_int64` instead")
pub fn Int64::to_int16(self : Int64) -> Int16 {
  Int16::from_int64(self)
}
